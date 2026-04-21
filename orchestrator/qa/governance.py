"""Governance gate implementation for QA workflow."""

import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Optional

from .app_config import AppConfig

logger = logging.getLogger(__name__)


class GovernanceDecision(Enum):
    """Possible governance decisions at each gate."""

    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    REFINE = "REFINE"  # Only available for testDesign gate
    PENDING = "PENDING"


class GovernanceGate(Enum):
    """Governance checkpoints in QA workflow."""

    REQUIREMENTS = "requirements"
    RISK = "risk"
    TEST_DESIGN = "testDesign"
    AUTOMATION = "automation"


@dataclass
class GovernanceCheckpoint:
    """State of a governance gate."""

    gate: GovernanceGate
    status: GovernanceDecision = GovernanceDecision.PENDING
    created_at: datetime = field(default_factory=datetime.utcnow)
    decided_at: Optional[datetime] = None
    decided_by: Optional[str] = None
    reason: Optional[str] = None

    def to_dict(self) -> dict:
        """Convert to dictionary representation."""
        return {
            "gate": self.gate.value,
            "status": self.status.value,
            "created_at": self.created_at.isoformat(),
            "decided_at": self.decided_at.isoformat() if self.decided_at else None,
            "decided_by": self.decided_by,
            "reason": self.reason,
        }


class GovernanceManager:
    """Manages governance gates and decisions."""

    # Gate requirements (what must be ready)
    GATE_REQUIREMENTS = {
        GovernanceGate.REQUIREMENTS: {
            "description": "Requirement analysis gate",
            "checks": ["requirements_extracted", "scope_confirmed"],
            "allows_refine": False,
        },
        GovernanceGate.RISK: {
            "description": "Risk analysis gate",
            "checks": ["risk_scored", "test_estimate_provided"],
            "allows_refine": False,
        },
        GovernanceGate.TEST_DESIGN: {
            "description": "Test case design gate",
            "checks": ["test_cases_generated", "self_review_passed"],
            "allows_refine": True,  # Can request refinement of test cases
        },
        GovernanceGate.AUTOMATION: {
            "description": "Test automation gate",
            "checks": ["automation_code_ready", "compilation_successful"],
            "allows_refine": False,
        },
    }

    def __init__(self, config: AppConfig):
        """Initialize governance manager."""
        self.config = config
        self.checkpoints = {}
        self.decision_log = []

    def create_checkpoint(self, run_id: str, gate: GovernanceGate) -> GovernanceCheckpoint:
        """Create a new governance checkpoint."""
        if run_id not in self.checkpoints:
            self.checkpoints[run_id] = {}

        checkpoint = GovernanceCheckpoint(gate=gate)
        self.checkpoints[run_id][gate.value] = checkpoint
        logger.info(f"Created governance checkpoint: {gate.value} for run {run_id}")
        return checkpoint

    def get_checkpoint(
        self, run_id: str, gate: GovernanceGate
    ) -> Optional[GovernanceCheckpoint]:
        """Retrieve checkpoint status."""
        if run_id not in self.checkpoints:
            return None
        return self.checkpoints[run_id].get(gate.value)

    def decide(
        self,
        run_id: str,
        gate: GovernanceGate,
        decision: GovernanceDecision,
        decided_by: str,
        reason: Optional[str] = None,
    ) -> bool:
        """
        Record governance decision.

        Returns True if decision is valid, False otherwise.
        """
        checkpoint = self.get_checkpoint(run_id, gate)
        if checkpoint is None:
            logger.error(f"No checkpoint for gate {gate.value}")
            return False

        # Validate decision type
        if decision == GovernanceDecision.REFINE:
            if not self.GATE_REQUIREMENTS[gate]["allows_refine"]:
                logger.error(f"Gate {gate.value} does not allow REFINE decision")
                return False

        checkpoint.status = decision
        checkpoint.decided_at = datetime.utcnow()
        checkpoint.decided_by = decided_by
        checkpoint.reason = reason

        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "run_id": run_id,
            "gate": gate.value,
            "decision": decision.value,
            "decided_by": decided_by,
            "reason": reason,
        }
        self.decision_log.append(log_entry)

        logger.info(f"Governance decision recorded: {gate.value} = {decision.value}")
        return True

    def is_gate_ready(self, run_id: str, gate: GovernanceGate) -> bool:
        """Check if gate is approved and ready to proceed."""
        checkpoint = self.get_checkpoint(run_id, gate)
        if checkpoint is None:
            return False
        return checkpoint.status == GovernanceDecision.APPROVED

    def is_gate_blocked(self, run_id: str, gate: GovernanceGate) -> bool:
        """Check if gate is rejected."""
        checkpoint = self.get_checkpoint(run_id, gate)
        if checkpoint is None:
            return False
        return checkpoint.status == GovernanceDecision.REJECTED

    def get_all_checkpoints(self, run_id: str) -> dict:
        """Get all checkpoints for a run."""
        if run_id not in self.checkpoints:
            return {}
        return {
            gate: cp.to_dict() for gate, cp in self.checkpoints[run_id].items()
        }

    def check_timeout(self, run_id: str, gate: GovernanceGate) -> bool:
        """
        Check if gate has exceeded timeout waiting for decision.

        Returns True if timeout exceeded, False otherwise.
        """
        checkpoint = self.get_checkpoint(run_id, gate)
        if checkpoint is None or checkpoint.status != GovernanceDecision.PENDING:
            return False

        timeout_delta = timedelta(hours=self.config.governance_timeout_hours)
        if datetime.utcnow() - checkpoint.created_at > timeout_delta:
            logger.warning(
                f"Gate {gate.value} for run {run_id} exceeded timeout "
                f"({self.config.governance_timeout_hours} hours)"
            )
            return True

        return False

    def auto_approve_if_enabled(self, run_id: str, gate: GovernanceGate) -> bool:
        """
        Auto-approve gate if enabled and timeout exceeded.

        Returns True if auto-approved, False otherwise.
        """
        if not self.config.auto_approve:
            return False

        if not self.check_timeout(run_id, gate):
            return False

        return self.decide(
            run_id,
            gate,
            GovernanceDecision.APPROVED,
            "system",
            "Auto-approved after timeout",
        )

    def get_gate_requirements(self, gate: GovernanceGate) -> dict:
        """Get requirements for a gate."""
        return self.GATE_REQUIREMENTS.get(gate, {})
