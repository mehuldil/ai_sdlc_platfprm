"""Azure DevOps REST API client."""

import base64
import json
import logging
from typing import Any, Optional

import httpx

from ..app_config import AppConfig

logger = logging.getLogger(__name__)


class ADOClient:
    """Azure DevOps REST API wrapper."""

    def __init__(self, config: AppConfig):
        """Initialize ADO client."""
        self.config = config
        self.org = config.ado_org
        self.project = config.ado_project
        self.pat = config.ado_pat
        self.base_url = f"https://dev.azure.com/{self.org}/{self.project}"
        self.client = httpx.AsyncClient(timeout=30.0)
        self._setup_auth()

    def _setup_auth(self):
        """Set up Basic auth header."""
        credentials = base64.b64encode(f":{self.pat}".encode()).decode()
        self.auth_header = f"Basic {credentials}"

    async def get_work_item(self, item_id: int) -> dict:
        """Get work item by ID."""
        url = f"{self.base_url}/_apis/wit/workitems/{item_id}?api-version=7.0"

        try:
            response = await self.client.get(
                url,
                headers={"Authorization": self.auth_header},
            )

            if response.status_code != 200:
                logger.error(f"Failed to get work item {item_id}: {response.text}")
                return {}

            return response.json()

        except httpx.RequestError as e:
            logger.error(f"Request error getting work item: {e}")
            return {}

    async def create_work_item(
        self,
        work_item_type: str,
        fields: dict,
    ) -> Optional[dict]:
        """
        Create a new work item.

        Args:
            work_item_type: Type of work item (User Story, Bug, Task, etc.)
            fields: Work item fields (title, description, assigned_to, etc.)

        Returns:
            Created work item or None on error
        """
        url = (
            f"{self.base_url}/_apis/wit/workitems/${work_item_type}?api-version=7.0"
        )

        # Prepare patch body
        patch_body = [
            {
                "op": "add",
                "path": f"/fields/{key}",
                "value": value,
            }
            for key, value in fields.items()
        ]

        try:
            response = await self.client.patch(
                url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json-patch+json",
                },
                json=patch_body,
            )

            if response.status_code not in [200, 201]:
                logger.error(f"Failed to create work item: {response.text}")
                return None

            return response.json()

        except httpx.RequestError as e:
            logger.error(f"Request error creating work item: {e}")
            return None

    async def update_work_item(
        self,
        item_id: int,
        fields: dict,
        comment: Optional[str] = None,
    ) -> bool:
        """
        Update a work item.

        Args:
            item_id: Work item ID
            fields: Fields to update
            comment: Optional comment to add

        Returns:
            True if successful, False otherwise
        """
        url = (
            f"{self.base_url}/_apis/wit/workitems/{item_id}?api-version=7.0"
        )

        # Prepare patch body
        patch_body = [
            {
                "op": "add",
                "path": f"/fields/{key}",
                "value": value,
            }
            for key, value in fields.items()
        ]

        # Add comment if provided
        if comment:
            patch_body.append({
                "op": "add",
                "path": "/fields/System.History",
                "value": comment,
            })

        try:
            response = await self.client.patch(
                url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json-patch+json",
                },
                json=patch_body,
            )

            if response.status_code not in [200, 201]:
                logger.error(f"Failed to update work item {item_id}: {response.text}")
                return False

            logger.info(f"Updated work item {item_id}")
            return True

        except httpx.RequestError as e:
            logger.error(f"Request error updating work item: {e}")
            return False

    async def create_bug_with_parent(
        self,
        fields: dict,
        parent_id: int,
    ) -> Optional[dict]:
        """
        Create a bug work item with parent link.

        Args:
            fields: Bug fields (title, description, severity, etc.)
            parent_id: Parent work item ID

        Returns:
            Created bug or None on error
        """
        # Create bug
        bug = await self.create_work_item("Bug", fields)

        if bug is None:
            return None

        bug_id = bug["id"]

        # Add parent link
        link_url = (
            f"{self.base_url}/_apis/wit/workitems/{bug_id}/relations"
            f"?api-version=7.0-preview.1"
        )

        link_body = {
            "rel": "System.LinkTypes.Hierarchy-Reverse",
            "url": f"https://dev.azure.com/{self.org}/_apis/wit/workitems/{parent_id}",
        }

        try:
            response = await self.client.post(
                link_url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json",
                },
                json=link_body,
            )

            if response.status_code not in [200, 201]:
                logger.warning(f"Failed to link bug {bug_id} to parent: {response.text}")
            else:
                logger.info(f"Linked bug {bug_id} to parent {parent_id}")

        except httpx.RequestError as e:
            logger.warning(f"Request error linking bug: {e}")

        return bug

    async def add_attachment(
        self,
        work_item_id: int,
        file_path: str,
        file_name: Optional[str] = None,
    ) -> bool:
        """
        Add file attachment to work item.

        Args:
            work_item_id: Work item ID
            file_path: Path to file to attach
            file_name: Optional override for file name

        Returns:
            True if successful, False otherwise
        """
        if file_name is None:
            file_name = file_path.split("/")[-1]

        # Upload attachment
        upload_url = f"{self.base_url}/_apis/wit/attachments?api-version=7.0"

        try:
            with open(file_path, "rb") as f:
                file_content = f.read()

            response = await self.client.post(
                upload_url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/octet-stream",
                    "X-VSS-Content-Type": "application/json",
                },
                content=file_content,
            )

            if response.status_code != 201:
                logger.error(f"Failed to upload attachment: {response.text}")
                return False

            attachment = response.json()
            attachment_url = attachment["url"]

            # Link attachment to work item
            link_url = (
                f"{self.base_url}/_apis/wit/workitems/{work_item_id}"
                f"?api-version=7.0"
            )

            patch_body = [
                {
                    "op": "add",
                    "path": "/relations/-",
                    "value": {
                        "rel": "AttachedFile",
                        "url": attachment_url,
                        "attributes": {
                            "name": file_name,
                        },
                    },
                }
            ]

            response = await self.client.patch(
                link_url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json-patch+json",
                },
                json=patch_body,
            )

            if response.status_code != 200:
                logger.error(f"Failed to link attachment: {response.text}")
                return False

            logger.info(f"Attached {file_name} to work item {work_item_id}")
            return True

        except Exception as e:
            logger.error(f"Error attaching file: {e}")
            return False

    async def create_test_run(
        self,
        plan_id: int,
        run_name: str,
    ) -> Optional[int]:
        """
        Create a test run.

        Args:
            plan_id: Test plan ID
            run_name: Name for the test run

        Returns:
            Test run ID or None on error
        """
        url = (
            f"{self.base_url}/_apis/test/runs?api-version=7.0"
        )

        body = {
            "name": run_name,
            "plan": {
                "id": plan_id,
            },
            "automated": True,
        }

        try:
            response = await self.client.post(
                url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json",
                },
                json=body,
            )

            if response.status_code != 200:
                logger.error(f"Failed to create test run: {response.text}")
                return None

            result = response.json()
            return result.get("id")

        except httpx.RequestError as e:
            logger.error(f"Request error creating test run: {e}")
            return None

    async def record_test_results(
        self,
        run_id: int,
        results: list[dict],
    ) -> bool:
        """
        Record test results for a run.

        Args:
            run_id: Test run ID
            results: List of test results

        Returns:
            True if successful, False otherwise
        """
        url = (
            f"{self.base_url}/_apis/test/runs/{run_id}/results?api-version=7.0"
        )

        try:
            response = await self.client.post(
                url,
                headers={
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json",
                },
                json={"value": results},
            )

            if response.status_code != 200:
                logger.error(f"Failed to record test results: {response.text}")
                return False

            logger.info(f"Recorded {len(results)} test results for run {run_id}")
            return True

        except httpx.RequestError as e:
            logger.error(f"Request error recording test results: {e}")
            return False

    async def close(self):
        """Close HTTP client."""
        await self.client.aclose()

    async def __aenter__(self):
        """Async context manager entry."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()
