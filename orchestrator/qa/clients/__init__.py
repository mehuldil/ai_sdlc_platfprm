"""Clients for external services (Claude AI, Azure DevOps)."""

from .claude_client import ClaudeClient
from .ado_client import ADOClient

__all__ = ["ClaudeClient", "ADOClient"]
