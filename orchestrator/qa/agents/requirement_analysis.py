"""Requirement Analysis Agent - Extracts and validates requirements from ADO stories."""

import json
import logging
from typing import Any, Optional

from ..app_config import AppConfig
from ..clients import ADOClient, ClaudeClient
from ..context_store import ContextStore

logger = logging.getLogger(__name__)


class RequirementAnalysisAgent:
    """
    Analyzes ADO work items and extracts structured requirements.

    Responsibilities:
    1. Fetch ADO story by ID
    2. Extract requirements using Claude AI
    3. Identify scope and acceptance criteria
    4. Write structured output to KB
    """

    def __init__(self, config: AppConfig):
        """Initialize agent."""
        self.config = config
        self.claude = ClaudeClient(config)
        self.ado = ADOClient(config)
        self.store = ContextStore(config)

    async def run(self, run_id: str, story_id: str) -> dict:
        """
        Execute requirement analysis.

        Args:
            run_id: Unique run identifier
            story_id: ADO work item ID (e.g., US-12345)

        Returns:
            Analysis results with status and KB keys
        """
        try:
            logger.info(f"Starting requirement analysis for story {story_id}")

            # Step 1: Fetch story from ADO
            work_item = await self.ado.get_work_item(int(story_id.split("-")[1]))
            if not work_item:
                raise RuntimeError(f"Failed to fetch story {story_id} from ADO")

            logger.debug(f"Fetched work item: {work_item.get('id')}")

            # Step 2: Extract requirements with Claude
            requirements = await self._extract_requirements(work_item)

            # Step 3: Validate requirements
            validation = await self._validate_requirements(requirements)

            # Step 4: Store in KB
            kb_data = {
                "story_id": story_id,
                "work_item_id": work_item.get("id"),
                "title": work_item.get("fields", {}).get("System.Title", ""),
                "description": work_item.get("fields", {}).get("System.Description", ""),
                "requirements": requirements.get("extracted_requirements", []),
                "scope": requirements.get("scope", {}),
                "acceptance_criteria": requirements.get("acceptance_criteria", []),
                "validation_result": validation,
                "status": "COMPLETED",
            }

            self.store.set_kb(run_id, "requirements", kb_data)

            logger.info(f"Requirement analysis completed: {len(kb_data['requirements'])} requirements extracted")

            return {
                "status": "COMPLETED",
                "run_id": run_id,
                "story_id": story_id,
                "requirements_count": len(kb_data["requirements"]),
                "validation_passed": validation.get("passed", False),
                "kb_key": f"kb:requirements:{run_id}",
            }

        except Exception as e:
            logger.error(f"Requirement analysis failed: {e}")
            return {
                "status": "FAILED",
                "run_id": run_id,
                "error": str(e),
            }

    async def _extract_requirements(self, work_item: dict) -> dict:
        """Use Claude to extract requirements from work item."""
        prompt = f"""
        Analyze this Azure DevOps work item and extract structured requirements.

        Work Item:
        Title: {work_item.get('fields', {}).get('System.Title')}
        Description: {work_item.get('fields', {}).get('System.Description')}
        Acceptance Criteria: {work_item.get('fields', {}).get('Microsoft.VSTS.Common.AcceptanceCriteria')}

        Extract:
        1. List of functional requirements (numbered)
        2. Scope definition (what is included/excluded)
        3. Acceptance criteria (if not already provided)
        4. Key stakeholders or domains affected

        Return JSON:
        {{
            "extracted_requirements": [
                {{"id": "REQ-001", "text": "...", "type": "functional|non-functional"}},
                ...
            ],
            "scope": {{
                "in_scope": ["..."],
                "out_of_scope": ["..."]
            }},
            "acceptance_criteria": [
                {{"id": "AC-01", "gherkin": "GIVEN ... WHEN ... THEN ..."}},
                ...
            ]
        }}
        """

        try:
            response = await self.claude.ask_claude_json(prompt, temperature=0.2)
            return response
        except Exception as e:
            logger.error(f"Claude extraction failed: {e}")
            return {
                "extracted_requirements": [],
                "scope": {},
                "acceptance_criteria": [],
            }

    async def _validate_requirements(self, requirements: dict) -> dict:
        """Validate extracted requirements for completeness and clarity."""
        validation_prompt = f"""
        Validate these requirements for QA readiness.

        Requirements:
        {json.dumps(requirements, indent=2)}

        Check:
        1. All requirements are clear and testable
        2. Acceptance criteria cover happy path AND error cases
        3. No ambiguous or vague language
        4. Dependencies on other features are identified

        Return JSON:
        {{
            "passed": true|false,
            "issues": ["..."],
            "warnings": ["..."],
            "recommendations": ["..."]
        }}
        """

        try:
            response = await self.claude.ask_claude_json(
                validation_prompt, temperature=0.1
            )
            return response
        except Exception as e:
            logger.error(f"Validation failed: {e}")
            return {
                "passed": False,
                "issues": [str(e)],
                "warnings": [],
                "recommendations": [],
            }

    async def close(self):
        """Cleanup resources."""
        await self.claude.close()
        await self.ado.close()
