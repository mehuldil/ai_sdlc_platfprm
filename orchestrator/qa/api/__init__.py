"""FastAPI endpoints for QA Orchestrator."""

from fastapi import FastAPI


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    from .main import app
    return app
