"""Redis-backed knowledge base store for QA workflow context."""

import json
import logging
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Optional

import redis

from .app_config import AppConfig

logger = logging.getLogger(__name__)

# Enable imports from ai-sdlc-platform root for shared memory package.
ROOT_DIR = Path(__file__).resolve().parents[2]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))
from orchestrator.shared.semantic_memory import UnifiedSemanticMemory  # noqa: E402


class ContextStore:
    """
    Redis-backed knowledge base with disk archival.

    Manages:
    - KB stores: requirements, risk_map, test_cases, automation, environment, execution, reports, defects
    - Context variables: general key-value storage
    - Audit log: append-only record of all KB writes
    - Archival: 24-hour TTL in Redis, permanent storage on disk
    """

    # KB store namespaces
    KB_STORES = {
        "requirements": "kb:requirements",
        "risk_map": "kb:risk_map",
        "test_cases": "kb:test_cases",
        "automation": "kb:automation",
        "environment": "kb:environment",
        "execution": "kb:execution",
        "reports": "kb:reports",
        "defects": "kb:defects",
    }

    def __init__(self, config: AppConfig):
        """Initialize Redis connection and archival directory."""
        self.config = config
        self.redis_client = redis.Redis(
            host=config.redis_host,
            port=config.redis_port,
            db=config.redis_db,
            password=config.redis_password,
            decode_responses=True,
            socket_connect_timeout=5,
        )
        self.archive_dir = Path(config.kb_archive_dir)
        self.archive_dir.mkdir(parents=True, exist_ok=True)
        self.semantic_memory: Optional[UnifiedSemanticMemory] = None

        if config.enable_unified_semantic_memory:
            self.semantic_memory = UnifiedSemanticMemory(config.semantic_memory_db_path)
            logger.info("Unified semantic memory enabled: %s", config.semantic_memory_db_path)

        # Test Redis connection
        try:
            self.redis_client.ping()
            logger.info("Redis connection established")
        except redis.ConnectionError as e:
            logger.error(f"Failed to connect to Redis: {e}")
            raise

    def _get_kb_key(self, run_id: str, store: str) -> str:
        """Build Redis key for KB store."""
        return f"{self.KB_STORES[store]}:{run_id}"

    def _get_context_key(self, run_id: str, key: str) -> str:
        """Build Redis key for context variable."""
        return f"ctx:{run_id}:{key}"

    def _get_audit_key(self, run_id: str) -> str:
        """Build Redis key for audit log."""
        return f"audit:{run_id}"

    def set_kb(self, run_id: str, store: str, data: dict) -> None:
        """Write to KB store with TTL and audit logging."""
        if store not in self.KB_STORES:
            raise ValueError(f"Unknown KB store: {store}")

        key = self._get_kb_key(run_id, store)
        ttl_seconds = self.config.kb_ttl_hours * 3600

        # Serialize and store
        serialized = json.dumps(data, default=str)
        self.redis_client.setex(key, ttl_seconds, serialized)

        # Audit log entry
        self._audit_log(run_id, "WRITE", store, data)
        self._sync_to_semantic_memory(
            namespace=store,
            memory_key=run_id,
            content=json.dumps(data, default=str, indent=2),
            metadata={"run_id": run_id, "source": "qa.context_store.set_kb", "store": store},
        )
        logger.debug(f"KB write: {store} for run {run_id}")

    def get_kb(self, run_id: str, store: str) -> Optional[dict]:
        """Read from KB store."""
        if store not in self.KB_STORES:
            raise ValueError(f"Unknown KB store: {store}")

        key = self._get_kb_key(run_id, store)
        value = self.redis_client.get(key)

        if value is None:
            logger.debug(f"KB miss: {store} for run {run_id}")
            return None

        try:
            return json.loads(value)
        except json.JSONDecodeError:
            logger.error(f"Failed to deserialize KB {store} for run {run_id}")
            return None

    def set_context(self, run_id: str, key: str, value: Any) -> None:
        """Set a context variable."""
        redis_key = self._get_context_key(run_id, key)
        ttl_seconds = self.config.kb_ttl_hours * 3600

        serialized = json.dumps(value, default=str)
        self.redis_client.setex(redis_key, ttl_seconds, serialized)
        self._sync_to_semantic_memory(
            namespace="context",
            memory_key=f"{run_id}:{key}",
            content=serialized,
            metadata={"run_id": run_id, "context_key": key, "source": "qa.context_store.set_context"},
        )
        logger.debug(f"Context set: {key} = {value} for run {run_id}")

    def get_context(self, run_id: str, key: str) -> Optional[Any]:
        """Get a context variable."""
        redis_key = self._get_context_key(run_id, key)
        value = self.redis_client.get(redis_key)

        if value is None:
            return None

        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value  # Return as-is if not JSON

    def get_full_context(self, run_id: str) -> dict:
        """Retrieve all KB stores and context for a run."""
        context = {"run_id": run_id, "kb": {}, "context": {}, "audit": []}

        # Load all KB stores
        for store_name in self.KB_STORES.keys():
            data = self.get_kb(run_id, store_name)
            if data:
                context["kb"][store_name] = data

        # Load context variables
        pattern = self._get_context_key(run_id, "*")
        for key in self.redis_client.keys(pattern):
            context_key = key.split(":")[-1]
            context["context"][context_key] = self.get_context(run_id, context_key)

        # Load audit log
        context["audit"] = self._get_audit_log(run_id)

        return context

    def _audit_log(self, run_id: str, action: str, store: str, data: dict) -> None:
        """Append entry to audit log."""
        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "action": action,
            "store": store,
            "data_size_bytes": len(json.dumps(data)),
        }

        key = self._get_audit_key(run_id)
        self.redis_client.rpush(key, json.dumps(entry))

        # Set TTL on audit log
        ttl_seconds = self.config.kb_ttl_hours * 3600
        self.redis_client.expire(key, ttl_seconds)

    def _get_audit_log(self, run_id: str) -> list:
        """Retrieve audit log for a run."""
        key = self._get_audit_key(run_id)
        entries = self.redis_client.lrange(key, 0, -1)

        return [json.loads(entry) for entry in entries]

    def archive_run(self, run_id: str) -> str:
        """Archive run to disk and return path."""
        archive_data = self.get_full_context(run_id)

        archive_file = self.archive_dir / f"{run_id}.json"
        archive_data["archived_at"] = datetime.utcnow().isoformat()

        with open(archive_file, "w") as f:
            json.dump(archive_data, f, indent=2, default=str)

        logger.info(f"Run {run_id} archived to {archive_file}")
        return str(archive_file)

    def delete_run(self, run_id: str) -> None:
        """Delete run from Redis (typically before archival)."""
        for store_name in self.KB_STORES.keys():
            key = self._get_kb_key(run_id, store_name)
            self.redis_client.delete(key)

        # Delete context keys
        pattern = self._get_context_key(run_id, "*")
        for key in self.redis_client.keys(pattern):
            self.redis_client.delete(key)

        # Delete audit log
        audit_key = self._get_audit_key(run_id)
        self.redis_client.delete(audit_key)

        logger.info(f"Run {run_id} deleted from Redis")

    def _sync_to_semantic_memory(
        self,
        *,
        namespace: str,
        memory_key: str,
        content: str,
        metadata: dict[str, Any],
    ) -> None:
        """Mirror QA artifacts into unified semantic memory."""
        if not self.semantic_memory:
            return
        try:
            self.semantic_memory.upsert(
                orchestrator="qa",
                namespace=namespace,
                memory_key=memory_key,
                content=content,
                metadata=metadata,
                conflict_strategy="last_write_wins",
            )
        except Exception as exc:  # pragma: no cover - defensive logging only
            logger.warning("Semantic memory sync failed for %s/%s: %s", namespace, memory_key, exc)

    def health_check(self) -> dict:
        """Return Redis connectivity status."""
        try:
            ping = self.redis_client.ping()
            info = self.redis_client.info()
            return {
                "status": "healthy" if ping else "unhealthy",
                "redis_version": info.get("redis_version"),
                "used_memory_human": info.get("used_memory_human"),
                "connected_clients": info.get("connected_clients"),
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
            }
