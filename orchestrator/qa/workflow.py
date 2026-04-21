"""LangGraph state machine for QA orchestration."""

import logging
from typing import Literal, TypedDict

from langgraph.graph import END, StateGraph

from .app_config import AppConfig
from .context_store import ContextStore
from .governance import GovernanceDecision, GovernanceGate, GovernanceManager

logger = logging.getLogger(__name__)


class QAState(TypedDict):
    """State for QA orchestration workflow."""

    run_id: str
    story_id: str
    status: Literal[
        "STARTED", "RUNNING", "PAUSED", "COMPLETED", "REJECTED", "FAILED"
    ]
    current_agent: str
    governance_status: dict  # {requirements: APPROVED/PENDING, risk: ..., testDesign: ..., automation: ...}
    kb_keys: dict  # {requirements: "kb:requirements:{runId}", ...}
    error: str | None
    audit_log: list  # [{timestamp, agent, action, decision}]


class QAWorkflowOrchestrator:
    """LangGraph-based QA workflow orchestrator."""

    def __init__(self, config: AppConfig):
        """Initialize orchestrator with config and state management."""
        self.config = config
        self.context_store = ContextStore(config)
        self.governance = GovernanceManager(config)
        self.workflow = self._build_workflow()

    def _build_workflow(self) -> StateGraph:
        """Build the LangGraph state machine."""
        graph = StateGraph(QAState)

        # Add nodes for each agent and gate
        graph.add_node("requirement_analysis", self._requirement_analysis_node)
        graph.add_node("gate_requirements", self._governance_gate_node("requirements"))
        graph.add_node("risk_analysis", self._risk_analysis_node)
        graph.add_node("gate_risk", self._governance_gate_node("risk"))
        graph.add_node("test_case_design", self._test_case_design_node)
        graph.add_node("gate_test_design", self._governance_gate_node("testDesign"))
        graph.add_node("test_automation", self._test_automation_node)
        graph.add_node("gate_automation", self._governance_gate_node("automation"))
        graph.add_node("test_environment", self._test_environment_node)
        graph.add_node("test_execution", self._test_execution_node)
        graph.add_node("report_analysis", self._report_analysis_node)
        graph.add_node("defect_management", self._defect_management_node)

        # Set entry point
        graph.set_entry_point("requirement_analysis")

        # Define edges: requirement_analysis -> gate_requirements
        graph.add_edge("requirement_analysis", "gate_requirements")

        # Conditional edges from governance gates
        graph.add_conditional_edges(
            "gate_requirements",
            self._gate_router("requirements"),
            {
                "approved": "risk_analysis",
                "rejected": END,
                "refine": "requirement_analysis",
                "pending": "gate_requirements",
            },
        )

        graph.add_edge("risk_analysis", "gate_risk")
        graph.add_conditional_edges(
            "gate_risk",
            self._gate_router("risk"),
            {
                "approved": "test_case_design",
                "rejected": END,
                "refine": "risk_analysis",
                "pending": "gate_risk",
            },
        )

        graph.add_edge("test_case_design", "gate_test_design")
        graph.add_conditional_edges(
            "gate_test_design",
            self._gate_router("testDesign"),
            {
                "approved": "test_automation",
                "rejected": END,
                "refine": "test_case_design",
                "pending": "gate_test_design",
            },
        )

        graph.add_edge("test_automation", "gate_automation")
        graph.add_conditional_edges(
            "gate_automation",
            self._gate_router("automation"),
            {
                "approved": "test_environment",
                "rejected": END,
                "refine": "test_automation",
                "pending": "gate_automation",
            },
        )

        # Sequential edges for remaining agents
        graph.add_edge("test_environment", "test_execution")
        graph.add_edge("test_execution", "report_analysis")
        graph.add_edge("report_analysis", "defect_management")
        graph.add_edge("defect_management", END)

        return graph.compile()

    def _gate_router(self, gate_name: str):
        """Create a router function for a governance gate."""

        def router(state: QAState) -> Literal["approved", "rejected", "refine", "pending"]:
            gate_map = {
                "requirements": GovernanceGate.REQUIREMENTS,
                "risk": GovernanceGate.RISK,
                "testDesign": GovernanceGate.TEST_DESIGN,
                "automation": GovernanceGate.AUTOMATION,
            }
            gate = gate_map[gate_name]

            checkpoint = self.governance.get_checkpoint(state["run_id"], gate)
            if checkpoint is None:
                return "pending"

            decision_value = checkpoint.status.value.lower()
            if decision_value == "refine":
                return "refine"
            return decision_value

        return router

    def _governance_gate_node(self, gate_name: str):
        """Create a node function for a governance gate."""

        async def gate_node(state: QAState) -> QAState:
            gate_map = {
                "requirements": GovernanceGate.REQUIREMENTS,
                "risk": GovernanceGate.RISK,
                "testDesign": GovernanceGate.TEST_DESIGN,
                "automation": GovernanceGate.AUTOMATION,
            }
            gate = gate_map[gate_name]

            # Create checkpoint if not exists
            checkpoint = self.governance.get_checkpoint(state["run_id"], gate)
            if checkpoint is None:
                self.governance.create_checkpoint(state["run_id"], gate)

            # Check timeout and auto-approve if enabled
            self.governance.auto_approve_if_enabled(state["run_id"], gate)

            # Update state
            state["status"] = "PAUSED"
            state["current_agent"] = f"gate_{gate_name}"
            state["governance_status"].update(
                {gate_name: self.governance.get_checkpoint(state["run_id"], gate).to_dict()}
            )

            logger.info(f"Governance gate paused: {gate_name} for run {state['run_id']}")
            return state

        return gate_node

    async def _requirement_analysis_node(self, state: QAState) -> QAState:
        """Requirement analysis agent node."""
        state["current_agent"] = "requirement_analysis"
        state["status"] = "RUNNING"

        try:
            # TODO: Implement requirement analysis with Claude
            self.context_store.set_kb(
                state["run_id"],
                "requirements",
                {
                    "story_id": state["story_id"],
                    "requirements": [],
                    "scope": {},
                },
            )
            logger.info(f"Requirement analysis completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Requirement analysis failed: {e}")

        return state

    async def _risk_analysis_node(self, state: QAState) -> QAState:
        """Risk analysis agent node."""
        state["current_agent"] = "risk_analysis"

        try:
            # TODO: Implement risk analysis with Claude
            self.context_store.set_kb(
                state["run_id"],
                "risk_map",
                {
                    "risk_score": 0,
                    "test_estimate": 0,
                    "risk_factors": [],
                },
            )
            logger.info(f"Risk analysis completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Risk analysis failed: {e}")

        return state

    async def _test_case_design_node(self, state: QAState) -> QAState:
        """Test case design agent node."""
        state["current_agent"] = "test_case_design"

        try:
            # TODO: Implement test case design with Claude
            self.context_store.set_kb(
                state["run_id"],
                "test_cases",
                {
                    "test_cases": [],
                    "self_review": {},
                    "excel_path": None,
                    "ado_sync_status": "pending",
                },
            )
            logger.info(f"Test case design completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Test case design failed: {e}")

        return state

    async def _test_automation_node(self, state: QAState) -> QAState:
        """Test automation agent node."""
        state["current_agent"] = "test_automation"

        try:
            # TODO: Implement test automation (Java/TestNG generation) with Claude
            self.context_store.set_kb(
                state["run_id"],
                "automation",
                {
                    "pom_xml": None,
                    "testng_classes": [],
                    "compilation_status": "pending",
                },
            )
            logger.info(f"Test automation completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Test automation failed: {e}")

        return state

    async def _test_environment_node(self, state: QAState) -> QAState:
        """Test environment setup agent node."""
        state["current_agent"] = "test_environment"

        try:
            # TODO: Implement environment checks (adb, APK, Appium)
            self.context_store.set_kb(
                state["run_id"],
                "environment",
                {
                    "device_status": "unknown",
                    "apk_status": "unknown",
                    "appium_status": "unknown",
                },
            )
            logger.info(f"Test environment setup completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Test environment setup failed: {e}")

        return state

    async def _test_execution_node(self, state: QAState) -> QAState:
        """Test execution agent node."""
        state["current_agent"] = "test_execution"

        try:
            # TODO: Implement test execution with Appium and Surefire result parsing
            self.context_store.set_kb(
                state["run_id"],
                "execution",
                {
                    "test_run_id": None,
                    "execution_status": "pending",
                    "results": {},
                },
            )
            logger.info(f"Test execution completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Test execution failed: {e}")

        return state

    async def _report_analysis_node(self, state: QAState) -> QAState:
        """Report analysis agent node."""
        state["current_agent"] = "report_analysis"

        try:
            # TODO: Implement failure classification with Claude
            self.context_store.set_kb(
                state["run_id"],
                "reports",
                {
                    "pass_count": 0,
                    "fail_count": 0,
                    "failure_analysis": [],
                },
            )
            logger.info(f"Report analysis completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Report analysis failed: {e}")

        return state

    async def _defect_management_node(self, state: QAState) -> QAState:
        """Defect management agent node."""
        state["current_agent"] = "defect_management"

        try:
            # TODO: Implement ADO bug filing with parent links
            self.context_store.set_kb(
                state["run_id"],
                "defects",
                {
                    "bugs_filed": [],
                    "ado_links": [],
                },
            )
            logger.info(f"Defect management completed for run {state['run_id']}")
        except Exception as e:
            state["status"] = "FAILED"
            state["error"] = str(e)
            logger.error(f"Defect management failed: {e}")

        state["status"] = "COMPLETED"
        return state

    async def execute(self, run_id: str, story_id: str) -> dict:
        """Execute the workflow for a given run and story."""
        initial_state: QAState = {
            "run_id": run_id,
            "story_id": story_id,
            "status": "STARTED",
            "current_agent": "initialize",
            "governance_status": {},
            "kb_keys": self.context_store.KB_STORES,
            "error": None,
            "audit_log": [],
        }

        logger.info(f"Starting QA workflow for run {run_id}, story {story_id}")
        final_state = await self.workflow.ainvoke(initial_state)

        return {
            "run_id": run_id,
            "status": final_state["status"],
            "final_state": final_state,
            "context": self.context_store.get_full_context(run_id),
        }


def create_workflow(config: AppConfig) -> QAWorkflowOrchestrator:
    """Factory function to create and return workflow orchestrator."""
    return QAWorkflowOrchestrator(config)
