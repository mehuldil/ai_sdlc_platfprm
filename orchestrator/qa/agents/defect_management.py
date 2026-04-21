"""Defect Management Agent - Files bugs in Azure DevOps."""

import logging
from ..app_config import AppConfig
from ..clients import ADOClient
from ..context_store import ContextStore

logger = logging.getLogger(__name__)


class DefectManagementAgent:
    """Files ADO bugs for test failures."""

    def __init__(self, config: AppConfig):
        self.config = config
        self.ado = ADOClient(config)
        self.store = ContextStore(config)

    async def run(self, run_id: str, story_id: str) -> dict:
        """File bugs in ADO for test failures."""
        try:
            logger.info(f"Starting defect management for run {run_id}")

            report = self.store.get_kb(run_id, "reports")
            if not report:
                raise RuntimeError("Report not analyzed")

            # TODO: Iterate failures from report
            # TODO: Create Bug work items in ADO
            # TODO: Link each bug to parent story
            # TODO: Attach screenshots and logs
            # TODO: Set severity based on classification

            kb_data = {
                "story_id": story_id,
                "bugs_filed": 0,
                "ado_links": [],
                "status": "COMPLETED",
            }

            self.store.set_kb(run_id, "defects", kb_data)
            return {"status": "COMPLETED", "run_id": run_id}

        except Exception as e:
            logger.error(f"Defect management failed: {e}")
            return {"status": "FAILED", "run_id": run_id, "error": str(e)}

    async def close(self):
        await self.ado.close()
