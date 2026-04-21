"""FastAPI REST endpoints for QA orchestrator."""

import logging
import uuid
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

from ..app_config import AppConfig
from ..context_store import ContextStore
from ..governance import GovernanceDecision, GovernanceManager
from ..workflow import QAWorkflowOrchestrator

logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="QA Runtime Orchestration Engine",
    description="LangGraph-based QA orchestration with governance gates",
    version="1.0.0",
)

# Initialize services
config = AppConfig.load_from_env()
is_valid, errors = config.validate()
if not is_valid:
    logger.error(f"Configuration validation failed: {errors}")
    raise RuntimeError(f"Invalid configuration: {errors}")

context_store = ContextStore(config)
governance_manager = GovernanceManager(config)
workflow = QAWorkflowOrchestrator(config)

logger.info("QA Orchestrator API initialized")


# ===== Pydantic Models =====


class TriggerRequest(BaseModel):
    """Request to trigger QA pipeline."""

    story_id: str
    priority: Optional[str] = "medium"
    tags: Optional[list[str]] = None


class ApprovalRequest(BaseModel):
    """Governance approval request."""

    checkpoint: str
    decision: str  # APPROVED, REJECTED, REFINE
    reason: Optional[str] = None


class HealthResponse(BaseModel):
    """Health check response."""

    status: str
    redis: dict
    config_valid: bool
    errors: list[str]


# ===== Endpoints =====


@app.post("/trigger")
async def trigger_pipeline(request: TriggerRequest) -> dict:
    """
    Start QA orchestration pipeline for a story.

    Returns:
        - run_id: Unique run identifier
        - status: Initial status (STARTED)
        - story_id: Reference to the story
    """
    run_id = str(uuid.uuid4())

    # Initialize context
    context_store.set_context(run_id, "story_id", request.story_id)
    context_store.set_context(run_id, "priority", request.priority)
    context_store.set_context(run_id, "tags", request.tags or [])
    context_store.set_context(run_id, "triggered_at", str(__import__("datetime").datetime.utcnow().isoformat()))

    logger.info(f"Pipeline triggered: run_id={run_id}, story_id={request.story_id}")

    return {
        "run_id": run_id,
        "status": "STARTED",
        "story_id": request.story_id,
        "message": "QA pipeline initiated. Monitoring governance gates.",
    }


@app.get("/status/{run_id}")
async def get_status(run_id: str) -> dict:
    """
    Get workflow status and governance state for a run.

    Returns:
        - run_id: The run identifier
        - status: Current workflow status
        - current_agent: Agent currently executing
        - governance_status: State of all governance gates
        - context: Current workflow context
    """
    context = context_store.get_context(run_id, "story_id")
    if context is None:
        raise HTTPException(status_code=404, detail=f"Run {run_id} not found")

    checkpoints = governance_manager.get_all_checkpoints(run_id)

    return {
        "run_id": run_id,
        "story_id": context,
        "governance_gates": checkpoints,
        "context": context_store.get_full_context(run_id),
    }


@app.post("/approve")
async def approve_gate(run_id: str, request: ApprovalRequest) -> dict:
    """
    Submit governance decision for a checkpoint.

    Parameters:
        - run_id: Run identifier (query param)
        - request: ApprovalRequest with checkpoint, decision, reason

    Returns:
        - run_id: The run identifier
        - checkpoint: Gate that was approved
        - decision: Decision made
        - message: Confirmation message
    """
    from ..governance import GovernanceGate

    checkpoint_map = {
        "requirements": GovernanceGate.REQUIREMENTS,
        "risk": GovernanceGate.RISK,
        "testDesign": GovernanceGate.TEST_DESIGN,
        "automation": GovernanceGate.AUTOMATION,
    }

    if request.checkpoint not in checkpoint_map:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid checkpoint: {request.checkpoint}",
        )

    gate = checkpoint_map[request.checkpoint]

    # Validate decision
    decision_map = {
        "APPROVED": GovernanceDecision.APPROVED,
        "REJECTED": GovernanceDecision.REJECTED,
        "REFINE": GovernanceDecision.REFINE,
    }

    if request.decision not in decision_map:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid decision: {request.decision}",
        )

    decision = decision_map[request.decision]

    # Record decision
    success = governance_manager.decide(
        run_id,
        gate,
        decision,
        "api-user",
        request.reason,
    )

    if not success:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to record decision for {request.checkpoint}",
        )

    logger.info(f"Governance decision recorded: {run_id} / {request.checkpoint} = {request.decision}")

    return {
        "run_id": run_id,
        "checkpoint": request.checkpoint,
        "decision": request.decision,
        "message": f"Decision recorded: {request.decision}",
    }


@app.get("/kb/{run_id}")
async def get_kb(run_id: str) -> dict:
    """Get all KB stores for a run."""
    context = context_store.get_context(run_id, "story_id")
    if context is None:
        raise HTTPException(status_code=404, detail=f"Run {run_id} not found")

    return {
        "run_id": run_id,
        "kb_stores": context_store.get_full_context(run_id).get("kb", {}),
    }


@app.get("/kb/{run_id}/summary")
async def get_kb_summary(run_id: str) -> dict:
    """Get structured summary of KB stores for a run."""
    context = context_store.get_context(run_id, "story_id")
    if context is None:
        raise HTTPException(status_code=404, detail=f"Run {run_id} not found")

    full_context = context_store.get_full_context(run_id)
    kb = full_context.get("kb", {})

    return {
        "run_id": run_id,
        "summary": {
            "requirements_ready": bool(kb.get("requirements")),
            "risk_scored": bool(kb.get("risk_map")),
            "test_cases_count": len(kb.get("test_cases", {}).get("test_cases", [])),
            "automation_ready": bool(kb.get("automation")),
            "execution_completed": bool(kb.get("execution", {}).get("test_run_id")),
            "defects_filed": len(kb.get("defects", {}).get("bugs_filed", [])),
        },
    }


@app.get("/kb/{run_id}/{store}")
async def get_kb_store(run_id: str, store: str) -> dict:
    """Get single KB store for a run."""
    valid_stores = list(context_store.KB_STORES.keys())

    if store not in valid_stores:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid store: {store}. Valid stores: {valid_stores}",
        )

    data = context_store.get_kb(run_id, store)
    if data is None:
        raise HTTPException(
            status_code=404,
            detail=f"Store {store} not found for run {run_id}",
        )

    return {
        "run_id": run_id,
        "store": store,
        "data": data,
    }


@app.post("/archive/{run_id}")
async def archive_run(run_id: str) -> dict:
    """Archive run context to disk and optionally delete Redis keys."""
    context = context_store.get_context(run_id, "story_id")
    if context is None:
        raise HTTPException(status_code=404, detail=f"Run {run_id} not found")

    archive_path = context_store.archive_run(run_id)
    context_store.delete_run(run_id)
    return {
        "run_id": run_id,
        "status": "archived",
        "archive_path": archive_path,
    }


@app.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Health check endpoint."""
    redis_status = context_store.health_check()
    is_valid, errors = config.validate()

    return HealthResponse(
        status="healthy" if is_valid and redis_status["status"] == "healthy" else "unhealthy",
        redis=redis_status,
        config_valid=is_valid,
        errors=errors,
    )


@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard() -> str:
    """Simple dashboard for monitoring."""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>QA Orchestrator Dashboard</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                margin: 0;
                padding: 20px;
                background: #f5f5f5;
            }
            .container {
                max-width: 1200px;
                margin: 0 auto;
            }
            h1 {
                color: #333;
                margin-top: 0;
            }
            .card {
                background: white;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .status {
                font-size: 14px;
                padding: 8px 12px;
                border-radius: 4px;
                display: inline-block;
                font-weight: bold;
            }
            .status.healthy {
                background: #d4edda;
                color: #155724;
            }
            .status.unhealthy {
                background: #f8d7da;
                color: #721c24;
            }
            .endpoint {
                background: #f8f9fa;
                padding: 10px;
                margin: 10px 0;
                border-left: 4px solid #007bff;
                font-family: monospace;
            }
            code {
                background: #f4f4f4;
                padding: 2px 6px;
                border-radius: 3px;
                font-family: monospace;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>QA Orchestrator Dashboard</h1>

            <div class="card">
                <h2>System Status</h2>
                <div id="health-status">Loading...</div>
            </div>

            <div class="card">
                <h2>API Endpoints</h2>

                <h3>Start Pipeline</h3>
                <div class="endpoint">POST /trigger</div>
                <p>Start QA orchestration for a story.</p>

                <h3>Get Status</h3>
                <div class="endpoint">GET /status/{run_id}</div>
                <p>Get workflow status and governance state.</p>

                <h3>Approve Gate</h3>
                <div class="endpoint">POST /approve?run_id={run_id}</div>
                <p>Submit governance decision for a checkpoint.</p>

                <h3>Get Knowledge Base</h3>
                <div class="endpoint">GET /kb/{run_id}</div>
                <p>Get all KB stores for a run.</p>

                <h3>Get KB Summary</h3>
                <div class="endpoint">GET /kb/{run_id}/summary</div>
                <p>Get structured summary of KB stores.</p>

                <h3>Get Specific KB Store</h3>
                <div class="endpoint">GET /kb/{run_id}/{store}</div>
                <p>Valid stores: requirements, risk_map, test_cases, automation,
                   environment, execution, reports, defects</p>

                <h3>Health Check</h3>
                <div class="endpoint">GET /health</div>
                <p>Check system and Redis connectivity.</p>
            </div>

            <div class="card">
                <h2>Documentation</h2>
                <p><code>/docs</code> - OpenAPI/Swagger documentation</p>
                <p><code>/redoc</code> - ReDoc documentation</p>
            </div>
        </div>

        <script>
            async function loadHealth() {
                try {
                    const response = await fetch('/health');
                    const data = await response.json();
                    const statusClass = data.status === 'healthy' ? 'healthy' : 'unhealthy';
                    document.getElementById('health-status').innerHTML = `
                        <p>
                            <span class="status ${statusClass}">${data.status.toUpperCase()}</span>
                        </p>
                        <p><strong>Redis:</strong> ${data.redis.status}</p>
                        <p><strong>Configuration Valid:</strong> ${data.config_valid}</p>
                        ${data.errors.length > 0 ? '<p><strong>Errors:</strong> ' + data.errors.join(', ') + '</p>' : ''}
                    `;
                } catch (error) {
                    document.getElementById('health-status').innerHTML = `<p style="color: red;">Error loading health status</p>`;
                }
            }

            loadHealth();
            setInterval(loadHealth, 10000);  // Refresh every 10 seconds
        </script>
    </body>
    </html>
    """


@app.on_event("startup")
async def startup_event():
    """Initialize on startup."""
    logger.info("QA Orchestrator API starting up")
    health = context_store.health_check()
    logger.info(f"Redis status: {health}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    logger.info("QA Orchestrator API shutting down")
