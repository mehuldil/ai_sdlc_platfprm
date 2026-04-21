"""
ADO Event Observer - 2-way integration with Azure DevOps.

Watches ADO for changes and triggers platform actions.
Supports webhooks (preferred) or polling (fallback).
"""

import asyncio
import hashlib
import hmac
import json
import logging
import os
from datetime import datetime, timedelta
from enum import Enum
from typing import Callable, Dict, List, Optional, Any
from dataclasses import dataclass, field

import httpx
from fastapi import FastAPI, HTTPException, Request, Header
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


class ADOEventType(Enum):
    """Supported ADO event types."""
    WORKITEM_UPDATED = "workitem.updated"
    WORKITEM_COMMENTED = "workitem.commented"
    WORKITEM_STATE_CHANGED = "workitem.statechanged"
    BUILD_COMPLETED = "build.completed"
    PULL_REQUEST_CREATED = "git.pullrequest.created"
    PULL_REQUEST_UPDATED = "git.pullrequest.updated"


@dataclass
class ADOEvent:
    """Normalized ADO event."""
    event_type: ADOEventType
    work_item_id: Optional[int]
    project_id: str
    organization: str
    timestamp: datetime
    payload: Dict[str, Any]
    raw_event: Dict[str, Any]
    webhook_signature: Optional[str] = None


@dataclass
class TriggerRule:
    """Rule for triggering actions based on events."""
    name: str
    event_type: ADOEventType
    condition: Callable[[ADOEvent], bool]
    action: Callable[[ADOEvent], asyncio.Coroutine]
    enabled: bool = True
    cooldown_seconds: int = 60
    last_triggered: Optional[datetime] = field(default=None)


# -----------------------------------------------------------------------------
# Event → Stage mapping (canonical table)
#
# Governs which SDLC stage is invoked when an ADO state transition is observed.
# Keys are "<from_state>:<to_state>" (canonical lowercase). "*" matches any.
# Values are stage IDs under `stages/` (e.g., "02-pre-grooming").
#
# TODO(mehul): Fill in the definitive transitions per your ADO state model.
# This stub is intentionally minimal so the observer loads without assuming
# intent. Missing mappings are logged and skipped — nothing auto-executes.
# -----------------------------------------------------------------------------
EVENT_STAGE_MAP: Dict[str, str] = {
    # "new:active":         "02-pre-grooming",
    # "active:resolved":    "09-code-review",
    # "resolved:closed":    "14-release-signoff",
    # "*:*":                "",  # catch-all (leave empty to no-op)
}


def resolve_stage_for_transition(from_state: Optional[str], to_state: Optional[str]) -> Optional[str]:
    """Look up the target stage for a state transition. Returns None if unmapped."""
    f = (from_state or "").strip().lower()
    t = (to_state or "").strip().lower()
    for key in (f"{f}:{t}", f"*:{t}", f"{f}:*", "*:*"):
        if key in EVENT_STAGE_MAP and EVENT_STAGE_MAP[key]:
            return EVENT_STAGE_MAP[key]
    return None


class ADOObserver:
    """
    Observes ADO for events and triggers handlers.
    
    Supports two modes:
    1. Webhook mode: ADO Service Hooks push events
    2. Polling mode: Periodic polling (fallback)
    """
    
    def __init__(
        self,
        org: str,
        project: str,
        pat: str,
        webhook_secret: Optional[str] = None,
        polling_interval: int = 60,
        mode: str = "auto"  # "webhook", "polling", "auto"
    ):
        self.org = org
        self.project = project
        self.pat = pat
        self.webhook_secret = webhook_secret
        self.polling_interval = polling_interval
        self.mode = mode
        
        self.base_url = f"https://dev.azure.com/{org}/{project}"
        self.trigger_rules: List[TriggerRule] = []
        self.event_history: List[ADOEvent] = []
        self.last_poll_time = datetime.utcnow() - timedelta(minutes=5)

        # Idempotency cache — dedup of (work_item_id, rev, event_type) within a
        # bounded window. Prevents double-execution on webhook retries or
        # poll/webhook overlap. Stored as dict for O(1) lookup with TTL pruning.
        # Key: "<work_item_id>:<rev>:<event_type>" → timestamp.
        self._idempotency_cache: Dict[str, datetime] = {}
        self._idempotency_ttl_seconds = 3600  # 1 hour
        
        # HTTP client for ADO API
        self.client = httpx.AsyncClient(timeout=30.0)
        self._setup_auth()
        
        # Polling task
        self._polling_task: Optional[asyncio.Task] = None
        
    def _setup_auth(self):
        """Set up Basic auth header."""
        import base64
        credentials = base64.b64encode(f":{self.pat}".encode()).decode()
        self.auth_header = f"Basic {credentials}"
        
    def register_trigger(
        self,
        name: str,
        event_type: ADOEventType,
        condition: Callable[[ADOEvent], bool],
        action: Callable[[ADOEvent], asyncio.Coroutine],
        cooldown_seconds: int = 60,
        enabled: bool = True
    ):
        """Register a trigger rule."""
        rule = TriggerRule(
            name=name,
            event_type=event_type,
            condition=condition,
            action=action,
            enabled=enabled,
            cooldown_seconds=cooldown_seconds
        )
        self.trigger_rules.append(rule)
        logger.info(f"Registered trigger: {name} for {event_type.value}")
        
    async def start(self):
        """Start the observer."""
        if self.mode in ["polling", "auto"]:
            self._polling_task = asyncio.create_task(self._polling_loop())
            logger.info("Started ADO polling observer")
            
    async def stop(self):
        """Stop the observer."""
        if self._polling_task:
            self._polling_task.cancel()
            try:
                await self._polling_task
            except asyncio.CancelledError:
                pass
        await self.client.aclose()
        logger.info("Stopped ADO observer")
        
    async def _polling_loop(self):
        """Main polling loop."""
        while True:
            try:
                await self._poll_changes()
            except Exception as e:
                logger.error(f"Polling error: {e}")
                
            await asyncio.sleep(self.polling_interval)
            
    async def _poll_changes(self):
        """Poll ADO for recent changes."""
        # Query work items modified since last check
        since = self.last_poll_time.isoformat()
        
        wiql = f"""
        SELECT [System.Id], [System.Title], [System.State], [System.ChangedDate], [System.WorkItemType]
        FROM workitems
        WHERE [System.ChangedDate] >= '{since}'
        AND [System.TeamProject] = '{self.project}'
        ORDER BY [System.ChangedDate] DESC
        """
        
        try:
            response = await self.client.post(
                f"{self.base_url}/_apis/wit/wiql?api-version=7.0",
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json"
                },
                json={"query": wiql}
            )
            
            if response.status_code != 200:
                logger.error(f"WIQL query failed: {response.text}")
                return
                
            result = response.json()
            work_items = result.get("workItems", [])
            
            logger.debug(f"Found {len(work_items)} changed work items")
            
            for wi in work_items:
                await self._process_work_item(wi["id"])
                
            self.last_poll_time = datetime.utcnow()
            
        except httpx.RequestError as e:
            logger.error(f"Request error polling ADO: {e}")
            
    def _is_duplicate_event(self, work_item_id: int, rev: Any, event_type: ADOEventType) -> bool:
        """Idempotency check — return True if (work_item, rev, event) was already processed.

        Prunes expired entries (> TTL) on each call to keep the cache bounded.
        """
        now = datetime.utcnow()
        cutoff = now - timedelta(seconds=self._idempotency_ttl_seconds)
        # Prune expired
        expired = [k for k, ts in self._idempotency_cache.items() if ts < cutoff]
        for k in expired:
            del self._idempotency_cache[k]

        key = f"{work_item_id}:{rev}:{event_type.value}"
        if key in self._idempotency_cache:
            logger.debug(f"Idempotency hit — skipping duplicate event {key}")
            return True
        self._idempotency_cache[key] = now
        return False

    async def _process_work_item(self, work_item_id: int):
        """Process a single work item change."""
        try:
            # Fetch full work item
            response = await self.client.get(
                f"{self.base_url}/_apis/wit/workitems/{work_item_id}?api-version=7.0",
                headers={"Authorization": self.auth_header}
            )

            if response.status_code != 200:
                return

            work_item = response.json()

            # Fetch recent comments
            comments = await self._get_comments(work_item_id)

            # Determine event type
            event_type = self._determine_event_type(work_item, comments)

            # Idempotency — skip if we've already processed this rev/event pair
            rev = work_item.get("rev") or work_item.get("fields", {}).get("System.Rev")
            if self._is_duplicate_event(work_item_id, rev, event_type):
                return
            
            # Create normalized event
            event = ADOEvent(
                event_type=event_type,
                work_item_id=work_item_id,
                project_id=self.project,
                organization=self.org,
                timestamp=datetime.utcnow(),
                payload={
                    "work_item": work_item,
                    "comments": comments
                },
                raw_event=work_item
            )
            
            self.event_history.append(event)
            
            # Route to triggers
            await self._route_event(event)
            
        except Exception as e:
            logger.error(f"Error processing work item {work_item_id}: {e}")
            
    async def _get_comments(self, work_item_id: int) -> List[Dict]:
        """Get recent comments for a work item."""
        try:
            response = await self.client.get(
                f"{self.base_url}/_apis/wit/workitems/{work_item_id}/comments?api-version=7.0",
                headers={"Authorization": self.auth_header}
            )
            
            if response.status_code == 200:
                result = response.json()
                comments = result.get("comments", [])
                # Filter to recent comments only
                cutoff = datetime.utcnow() - timedelta(minutes=self.polling_interval + 1)
                return [
                    c for c in comments
                    if datetime.fromisoformat(c["createdDate"].replace('Z', '+00:00')) > cutoff
                ]
            return []
            
        except Exception as e:
            logger.warning(f"Failed to get comments for {work_item_id}: {e}")
            return []
            
    def _determine_event_type(
        self,
        work_item: Dict,
        recent_comments: List[Dict]
    ) -> ADOEventType:
        """Determine event type from work item and comments."""
        fields = work_item.get("fields", {})
        
        # Check for new comments first (highest priority)
        if recent_comments:
            return ADOEventType.WORKITEM_COMMENTED
            
        # Check for state change
        # In practice, we'd need to compare with previous state
        # For now, assume any update could be a state change
        if "System.State" in fields:
            return ADOEventType.WORKITEM_STATE_CHANGED
            
        return ADOEventType.WORKITEM_UPDATED
        
    async def _route_event(self, event: ADOEvent):
        """Route event to matching trigger rules."""
        for rule in self.trigger_rules:
            # Check if rule applies
            if not rule.enabled:
                continue
                
            if rule.event_type != event.event_type:
                continue
                
            # Check cooldown
            if rule.last_triggered:
                cooldown_end = rule.last_triggered + timedelta(seconds=rule.cooldown_seconds)
                if datetime.utcnow() < cooldown_end:
                    logger.debug(f"Trigger {rule.name} in cooldown")
                    continue
                    
            # Check condition
            try:
                if not rule.condition(event):
                    continue
            except Exception as e:
                logger.error(f"Condition check failed for {rule.name}: {e}")
                continue
                
            # Execute action
            logger.info(f"Triggering: {rule.name}")
            try:
                await rule.action(event)
                rule.last_triggered = datetime.utcnow()
            except Exception as e:
                logger.error(f"Action failed for {rule.name}: {e}")
                
    async def handle_webhook(self, request: Request) -> Dict:
        """Handle incoming ADO webhook."""
        # Verify signature if secret is configured
        if self.webhook_secret:
            signature = request.headers.get("X-ADO-Signature")
            if not self._verify_signature(await request.body(), signature):
                raise HTTPException(status_code=401, detail="Invalid signature")
                
        # Parse event
        payload = await request.json()
        event_type = self._webhook_event_type(payload)

        # Create event
        work_item_id = self._extract_work_item_id(payload)

        # Idempotency — ADO webhooks can retry. Dedup on eventId (stable GUID per
        # delivery) falling back to (work_item_id, rev, event_type).
        ado_event_id = payload.get("id") or payload.get("eventId")
        if ado_event_id:
            key = f"webhook:{ado_event_id}"
            now = datetime.utcnow()
            if key in self._idempotency_cache:
                logger.info(f"Webhook idempotency — duplicate eventId {ado_event_id} ignored")
                return {"status": "duplicate", "event_id": ado_event_id}
            self._idempotency_cache[key] = now
        else:
            rev = payload.get("resource", {}).get("rev")
            if work_item_id and self._is_duplicate_event(work_item_id, rev, event_type):
                return {"status": "duplicate", "work_item_id": work_item_id}

        event = ADOEvent(
            event_type=event_type,
            work_item_id=work_item_id,
            project_id=self.project,
            organization=self.org,
            timestamp=datetime.utcnow(),
            payload=payload,
            raw_event=payload,
            webhook_signature=signature if self.webhook_secret else None
        )

        self.event_history.append(event)
        await self._route_event(event)

        return {"status": "processed", "event_type": event_type.value}
        
    def _verify_signature(self, body: bytes, signature: Optional[str]) -> bool:
        """Verify webhook signature."""
        if not signature:
            return False
            
        expected = hmac.new(
            self.webhook_secret.encode(),
            body,
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(f"sha256={expected}", signature)
        
    def _webhook_event_type(self, payload: Dict) -> ADOEventType:
        """Map webhook payload to event type."""
        event_type = payload.get("eventType", "").lower()
        
        if "comment" in event_type:
            return ADOEventType.WORKITEM_COMMENTED
        elif "state" in event_type:
            return ADOEventType.WORKITEM_STATE_CHANGED
        elif "build" in event_type:
            return ADOEventType.BUILD_COMPLETED
        elif "pullrequest" in event_type:
            return ADOEventType.PULL_REQUEST_UPDATED
        else:
            return ADOEventType.WORKITEM_UPDATED
            
    def _extract_work_item_id(self, payload: Dict) -> Optional[int]:
        """Extract work item ID from webhook payload."""
        resource = payload.get("resource", {})
        return resource.get("id")
        
    async def add_comment(self, work_item_id: int, text: str) -> bool:
        """Add comment to ADO work item."""
        try:
            url = f"{self.base_url}/_apis/wit/workitems/{work_item_id}/comments?api-version=7.0"
            
            response = await self.client.post(
                url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json"
                },
                json={"text": text}
            )
            
            if response.status_code in [200, 201]:
                logger.info(f"Added comment to work item {work_item_id}")
                return True
            else:
                logger.error(f"Failed to add comment: {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error adding comment: {e}")
            return False
            
    async def update_work_item_state(self, work_item_id: int, state: str) -> bool:
        """Update work item state."""
        try:
            url = f"{self.base_url}/_apis/wit/workitems/{work_item_id}?api-version=7.0"
            
            patch = [
                {
                    "op": "add",
                    "path": "/fields/System.State",
                    "value": state
                }
            ]
            
            response = await self.client.patch(
                url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json-patch+json"
                },
                json=patch
            )
            
            if response.status_code in [200, 201]:
                logger.info(f"Updated work item {work_item_id} to state {state}")
                return True
            else:
                logger.error(f"Failed to update state: {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error updating state: {e}")
            return False


# ============================================================================
# TRIGGER HANDLERS
# ============================================================================

async def on_risk_accepted(observer: ADOObserver, event: ADOEvent):
    """
    Handler: User accepts risk in ADO comment.
    Pattern: Comment contains "accept risk" or "proceed with risk"
    Action: Resume workflow at risk gate
    """
    payload = event.payload
    comments = payload.get("comments", [])
    
    for comment in comments:
        text = comment.get("text", "").lower()
        
        # Match patterns
        patterns = [
            r"accept\s+risk",
            r"proceed\s+with\s+risk",
            r"approved?\s*:?\s*accept\s+risk",
            r"risk\s+accepted"
        ]
        
        import re
        for pattern in patterns:
            if re.search(pattern, text, re.IGNORECASE):
                # Extract run_id from work item tags or description
                work_item = payload.get("work_item", {})
                fields = work_item.get("fields", {})
                description = fields.get("System.Description", "")
                
                # Look for run_id pattern: run-12345 or run_id:12345
                run_id_match = re.search(r'run[_-]?(?:id:?)?\s*(\w+)', description, re.IGNORECASE)
                run_id = run_id_match.group(1) if run_id_match else None
                
                if run_id:
                    logger.info(f"Risk accepted for run {run_id}")
                    
                    # Post acknowledgment
                    await observer.add_comment(
                        event.work_item_id,
                        "✅ **AI-SDLC**: Risk accepted. Resuming workflow at risk gate..."
                    )
                    
                    # TODO: Resume workflow via orchestrator API
                    # await resume_workflow(run_id, "risk", "APPROVED")
                    
                return


async def on_gate_approval_comment(observer: ADOObserver, event: ADOEvent):
    """
    Handler: Gate approval via comment.
    Pattern: "approve gate-G6" or "G6 approved"
    Action: Approve specific gate and resume workflow
    """
    payload = event.payload
    comments = payload.get("comments", [])
    
    import re
    
    for comment in comments:
        text = comment.get("text", "")
        
        # Match gate approval patterns
        patterns = [
            r'(?:approve\s+)?gate-?(G\d+)',
            r'^(G\d+)\s+(?:approved?|passed?|LGTM)',
            r'(?:approve|pass)\s+(?:gate\s+)?(G\d+)',
        ]
        
        gate = None
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                gate = match.group(1)
                break
                
        if gate:
            logger.info(f"Gate {gate} approved via comment")
            
            await observer.add_comment(
                event.work_item_id,
                f"✅ **AI-SDLC**: Gate {gate} approved via comment. Proceeding..."
            )
            
            # TODO: Resume workflow at specific gate
            return


async def on_state_change_to_done(observer: ADOObserver, event: ADOEvent):
    """
    Handler: Work item moved to Done.
    Action: Check if parent story is complete, trigger next stage
    """
    payload = event.payload
    work_item = payload.get("work_item", {})
    fields = work_item.get("fields", {})
    
    state = fields.get("System.State", "")
    work_item_type = fields.get("System.WorkItemType", "")
    
    if state == "Done" and work_item_type == "Task":
        # Get parent
        relations = work_item.get("relations", [])
        parent_id = None
        
        for rel in relations:
            if rel.get("rel") == "System.LinkTypes.Hierarchy-Reverse":
                parent_url = rel.get("url", "")
                parent_id = parent_url.split("/")[-1]
                break
                
        if parent_id:
            logger.info(f"Task {event.work_item_id} done, checking parent {parent_id}")
            
            # TODO: Check if all sibling tasks are done
            # If yes, trigger test execution stage
            
            await observer.add_comment(
                int(parent_id),
                f"🚀 **AI-SDLC**: Task completed. Checking story readiness..."
            )


async def on_reject_stop(observer: ADOObserver, event: ADOEvent):
    """
    Handler: Reject or stop workflow.
    Pattern: "reject", "stop", "hold", "do not proceed"
    Action: Pause workflow
    """
    payload = event.payload
    comments = payload.get("comments", [])
    
    import re
    
    patterns = [
        r'reject',
        r'stop\s+(?:workflow|here)',
        r'hold\s+(?:on|off)',
        r'do\s+not\s+proceed',
        r'(?:needs?\s+)?more\s+work',
    ]
    
    for comment in comments:
        text = comment.get("text", "").lower()
        
        for pattern in patterns:
            if re.search(pattern, text):
                logger.info(f"Workflow paused via comment on {event.work_item_id}")
                
                await observer.add_comment(
                    event.work_item_id,
                    "⏸️ **AI-SDLC**: Workflow paused. Awaiting further instructions."
                )
                
                # TODO: Pause workflow
                return


# ============================================================================
# FASTAPI APP FOR WEBHOOKS
# ============================================================================

def create_webhook_app(observer: ADOObserver) -> FastAPI:
    """Create FastAPI app for ADO webhooks."""
    app = FastAPI(title="ADO Webhook Receiver")
    
    @app.post("/webhook/ado")
    async def receive_webhook(request: Request):
        """Receive ADO webhook."""
        result = await observer.handle_webhook(request)
        return JSONResponse(content=result)
        
    @app.get("/health")
    async def health():
        """Health check."""
        return {"status": "healthy", "observer": "running"}
        
    @app.get("/events")
    async def list_events(limit: int = 10):
        """List recent events."""
        events = observer.event_history[-limit:]
        return {
            "events": [
                {
                    "type": e.event_type.value,
                    "work_item_id": e.work_item_id,
                    "timestamp": e.timestamp.isoformat()
                }
                for e in events
            ]
        }
        
    return app


# ============================================================================
# MAIN
# ============================================================================

async def main():
    """Main entry point."""
    # Configuration from environment
    org = os.getenv("ADO_ORG", "JPL-Limited")
    project = os.getenv("ADO_PROJECT", "JioCloud")
    pat = os.getenv("ADO_PAT")
    webhook_secret = os.getenv("ADO_WEBHOOK_SECRET")
    mode = os.getenv("ADO_OBSERVER_MODE", "polling")
    
    if not pat:
        logger.error("ADO_PAT not set")
        return
        
    # Create observer
    observer = ADOObserver(
        org=org,
        project=project,
        pat=pat,
        webhook_secret=webhook_secret,
        mode=mode
    )
    
    # Register triggers
    observer.register_trigger(
        name="risk-accepted",
        event_type=ADOEventType.WORKITEM_COMMENTED,
        condition=lambda e: True,  # Always check in handler
        action=lambda e: on_risk_accepted(observer, e),
        cooldown_seconds=30
    )
    
    observer.register_trigger(
        name="gate-approval",
        event_type=ADOEventType.WORKITEM_COMMENTED,
        condition=lambda e: True,
        action=lambda e: on_gate_approval_comment(observer, e),
        cooldown_seconds=30
    )
    
    observer.register_trigger(
        name="state-change-done",
        event_type=ADOEventType.WORKITEM_STATE_CHANGED,
        condition=lambda e: True,
        action=lambda e: on_state_change_to_done(observer, e),
        cooldown_seconds=60
    )
    
    observer.register_trigger(
        name="reject-stop",
        event_type=ADOEventType.WORKITEM_COMMENTED,
        condition=lambda e: True,
        action=lambda e: on_reject_stop(observer, e),
        cooldown_seconds=10
    )
    
    # Start observer
    await observer.start()
    
    # Create webhook app if in webhook mode
    if mode == "webhook":
        from uvicorn import Config, Server
        
        app = create_webhook_app(observer)
        config = Config(app=app, host="0.0.0.0", port=8000, log_level="info")
        server = Server(config)
        
        logger.info("Starting webhook server on port 8000")
        await server.serve()
    else:
        # Keep polling
        while True:
            await asyncio.sleep(1)


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    asyncio.run(main())
