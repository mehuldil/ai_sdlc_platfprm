"""Global configuration for QA Orchestrator."""

import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class AppConfig:
    """Application configuration with sensible defaults."""

    # Redis configuration
    redis_host: str = os.getenv("REDIS_HOST", "localhost")
    redis_port: int = int(os.getenv("REDIS_PORT", "6379"))
    redis_db: int = int(os.getenv("REDIS_DB", "0"))
    redis_password: Optional[str] = os.getenv("REDIS_PASSWORD")

    # API configuration
    api_host: str = os.getenv("API_HOST", "0.0.0.0")
    api_port: int = int(os.getenv("API_PORT", "8000"))
    api_debug: bool = os.getenv("API_DEBUG", "false").lower() == "true"

    # Claude AI configuration
    anthropic_api_key: str = os.getenv("ANTHROPIC_API_KEY", "")
    claude_model: str = os.getenv("CLAUDE_MODEL", "claude-sonnet-4-6")
    max_temperature: float = 0.3  # Hard cap on temperature for consistency
    default_temperature: float = 0.2

    # Azure DevOps configuration
    ado_org: str = os.getenv("ADO_ORG", "your-ado-org")
    ado_project: str = os.getenv("ADO_PROJECT", "YourAzureProject")
    ado_pat: str = os.getenv("ADO_PAT", "")
    ado_base_url: str = f"https://dev.azure.com/{os.getenv('ADO_ORG', 'your-ado-org')}"

    # Knowledge base configuration
    kb_ttl_hours: int = int(os.getenv("KB_TTL_HOURS", "24"))
    kb_archive_dir: str = os.getenv("KB_ARCHIVE_DIR", "data/kb_archive")
    enable_unified_semantic_memory: bool = (
        os.getenv("ENABLE_UNIFIED_SEMANTIC_MEMORY", "true").lower() == "true"
    )
    semantic_memory_db_path: str = os.getenv(
        "SEMANTIC_MEMORY_DB_PATH",
        ".sdlc/memory/semantic-memory.sqlite3",
    )

    # Governance configuration
    governance_timeout_hours: int = int(os.getenv("GOVERNANCE_TIMEOUT_HOURS", "24"))
    auto_approve: bool = os.getenv("AUTO_APPROVE", "false").lower() == "true"

    # Test environment configuration
    test_device_id: Optional[str] = os.getenv("TEST_DEVICE_ID")
    test_apk_path: Optional[str] = os.getenv("TEST_APK_PATH")
    appium_server_url: str = os.getenv("APPIUM_SERVER_URL", "http://localhost:4723")

    # Logging configuration
    log_level: str = os.getenv("LOG_LEVEL", "INFO")
    log_format: str = "json"  # "json" or "text"

    # Feature flags
    enable_webhook_notifications: bool = (
        os.getenv("ENABLE_WEBHOOK_NOTIFICATIONS", "true").lower() == "true"
    )
    enable_metrics_collection: bool = (
        os.getenv("ENABLE_METRICS_COLLECTION", "true").lower() == "true"
    )
    enable_parallel_execution: bool = (
        os.getenv("ENABLE_PARALLEL_EXECUTION", "false").lower() == "true"
    )
    enable_refine_gates: bool = os.getenv("ENABLE_REFINE_GATES", "true").lower() == "true"

    def validate(self) -> tuple[bool, list[str]]:
        """Validate configuration and return (is_valid, error_messages)."""
        errors = []

        if not self.anthropic_api_key:
            errors.append("ANTHROPIC_API_KEY is required")

        if not self.ado_pat:
            errors.append("ADO_PAT is required for Azure DevOps integration")

        if self.max_temperature < 0 or self.max_temperature > 2:
            errors.append("max_temperature must be between 0 and 2")

        if self.default_temperature > self.max_temperature:
            errors.append(
                f"default_temperature ({self.default_temperature}) cannot exceed "
                f"max_temperature ({self.max_temperature})"
            )

        if not self.semantic_memory_db_path:
            errors.append("SEMANTIC_MEMORY_DB_PATH must not be empty")

        return len(errors) == 0, errors

    @staticmethod
    def load_from_env() -> "AppConfig":
        """Load configuration from environment variables."""
        return AppConfig()
