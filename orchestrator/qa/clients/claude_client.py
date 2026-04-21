"""Anthropic Claude API client with temperature cap enforcement."""

import json
import logging
from typing import Any, Optional

import httpx

from ..app_config import AppConfig

logger = logging.getLogger(__name__)


class ClaudeClient:
    """Wrapper for Anthropic Claude API with temperature enforcement."""

    def __init__(self, config: AppConfig):
        """Initialize Claude client with config."""
        self.config = config
        self.api_key = config.anthropic_api_key
        self.model = config.claude_model
        self.max_temperature = config.max_temperature
        self.base_url = "https://api.anthropic.com/v1"
        self.client = httpx.AsyncClient(timeout=30.0)

    async def ask_claude(
        self,
        prompt: str,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> str:
        """
        Call Claude with temperature cap enforcement.

        Args:
            prompt: The prompt to send to Claude
            temperature: Desired temperature (will be capped at max_temperature)
            max_tokens: Maximum tokens in response

        Returns:
            Claude's text response
        """
        # Enforce temperature cap
        actual_temp = min(temperature, self.max_temperature)

        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }

        body = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": actual_temp,
            "messages": [
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
        }

        try:
            response = await self.client.post(
                f"{self.base_url}/messages",
                headers=headers,
                json=body,
            )

            if response.status_code != 200:
                logger.error(
                    f"Claude API error: {response.status_code} - {response.text}"
                )
                raise RuntimeError(
                    f"Claude API returned {response.status_code}: {response.text}"
                )

            result = response.json()
            return result["content"][0]["text"]

        except httpx.RequestError as e:
            logger.error(f"Request error calling Claude: {e}")
            raise

    async def ask_claude_json(
        self,
        prompt: str,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> dict:
        """
        Call Claude and parse JSON response.

        Args:
            prompt: The prompt to send to Claude
            temperature: Desired temperature (will be capped)
            max_tokens: Maximum tokens in response

        Returns:
            Parsed JSON response from Claude
        """
        text = await self.ask_claude(prompt, temperature, max_tokens)

        try:
            # Try to extract JSON from the response
            # Claude might include markdown code blocks
            if "```json" in text:
                json_str = text.split("```json")[1].split("```")[0].strip()
            elif "```" in text:
                json_str = text.split("```")[1].split("```")[0].strip()
            else:
                json_str = text

            return json.loads(json_str)

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Claude JSON response: {e}")
            logger.debug(f"Response text: {text}")
            raise

    async def close(self):
        """Close HTTP client."""
        await self.client.aclose()

    async def __aenter__(self):
        """Async context manager entry."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()
