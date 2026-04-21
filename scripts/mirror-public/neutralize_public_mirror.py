#!/usr/bin/env python3
"""
Brand-neutral text pass for a public distribution tree. Faster than shell find+sed on Windows.
Usage: python3 scripts/mirror-public/neutralize_public_mirror.py /path/to/checkout
Env: PUBLIC_MIRROR_GITHUB_CLONE (default https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git)
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

SKIP_DIRS = {".git", "node_modules", ".docs", ".cursor", ".claude"}
TEXT_SUFFIXES = {
    ".md",
    ".html",
    ".htm",
    ".sh",
    ".bash",
    ".js",
    ".mjs",
    ".cjs",
    ".json",
    ".yml",
    ".yaml",
    ".mdc",
    ".xml",
    ".txt",
    ".ps1",
    ".py",
    ".toml",
    ".properties",
    ".gradle",
    ".kt",
    ".swift",
    ".java",
    ".template",
}
NAMES = {"dockerfile", "makefile"}


def should_process(p: Path) -> bool:
    if p.name == "manual.html":
        return False
    n = p.name.lower()
    if n.endswith(".env") or ".env." in n or n.endswith(".env.example") or n.endswith(".env.local"):
        return True
    if p.suffix.lower() in TEXT_SUFFIXES:
        return True
    return n in NAMES


def neutralize_text(s: str, gh_clone: str) -> str:
    s = s.replace("AI-SDLC contributors", "AI-SDLC contributors")
    s = s.replace("mobile subscriber", "mobile subscriber")
    s = s.replace("carrier identity", "carrier identity")
    s = s.replace("enter my mobile number", "enter my mobile number")
    s = s.replace("their existing mobile number", "their existing mobile number")
    s = s.replace("use my existing mobile number", "use my existing mobile number")
    s = s.replace("existing mobile number", "existing mobile number")
    s = s.replace("mobile number", "mobile number")
    s = s.replace("example process template", "example process template")
    s = s.replace("when project rules require Custom.* fields", "when project rules require Custom.* fields")
    s = s.replace("in your Azure DevOps project require", "in your Azure DevOps project require")
    s = s.replace("(your process template uses", "(your process template uses")
    s = s.replace(
        "https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git",
        gh_clone,
    )
    s = s.replace(
        "https://dev.azure.com/your-ado-org/YourAzureProject",
        "https://dev.azure.com/your-ado-org/YourAzureProject",
    )
    s = s.replace(
        "https://dev.azure.com/your-ado-org/_usersSettings",
        "https://dev.azure.com/your-ado-org/_usersSettings",
    )
    s = s.replace("AI-SDLC", "AI-SDLC")
    s = s.replace("ExampleApp", "ExampleApp")
    s = s.replace("Custom.ApplicationPlatform", "Custom.ApplicationPlatform")
    s = s.replace("Custom.", "Custom.")
    s = s.replace("YourAzureProject", "YourAzureProject")
    s = re.sub(r"(?i)example-app", "example-app", s)
    s = s.replace("Application platform", "Application platform")
    s = s.replace("YourAzureProject", "YourAzureProject")
    s = s.replace(
        "**Governed By**: AI-SDLC Platform",
        "**Governed By**: AI-SDLC Platform",
    )
    s = s.replace(
        "**Governed By:** AI-SDLC Platform",
        "**Governed By:** AI-SDLC Platform",
    )
    s = s.replace(
        "**Governance:** AI-SDLC Platform v2.0+",
        "**Governance:** AI-SDLC Platform v2.0+",
    )
    s = s.replace("your-ado-org", "your-ado-org")
    s = s.replace("YourAzureProjectCursor", "workspace")
    s = s.replace("ExampleIdentity", "ExampleIdentity")
    s = s.replace("https://github.com/YOUR_GITHUB_USER/", "https://github.com/YOUR_GITHUB_USER/")
    s = s.replace("YOUR_GITHUB_USER/ai_sdlc_platform", "YOUR_GITHUB_USER/ai_sdlc_platform")
    s = s.replace("${HOME}/YourAzureProject", "${HOME}/projects/your-app")
    # Sample URLs and placeholders in memory/ and docs (generic examples)
    s = s.replace("github.com/example-org/", "github.com/example-org/")
    s = s.replace("github.com/example-org", "github.com/example-org")
    s = s.replace("https://api.example.invalid", "https://api.example.invalid")
    s = s.replace("https://staging-api.example.invalid", "https://staging-api.example.invalid")
    s = s.replace("https://cdn.example.invalid", "https://cdn.example.invalid")
    s = s.replace("https://storybook.example.invalid", "https://storybook.example.invalid")
    s = s.replace("infrastructure/wiki/", "infrastructure/wiki/")
    s = s.replace("com.example.app.", "com.example.app.")
    s = re.sub(r"(?i)example-org", "example-org", s)
    s = re.sub(r"(?i)\bneutral\s+mirror\b", "public repository", s)
    s = re.sub(r"(?i)public\s+github\s+mirror", "public GitHub distribution", s)
    return s


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: neutralize_public_mirror.py /path/to/mirror", file=sys.stderr)
        return 1
    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 1
    gh = os.environ.get(
        "PUBLIC_MIRROR_GITHUB_CLONE",
        "https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git",
    )
    n = 0
    for dirpath, dirnames, filenames in os.walk(root, topdown=True):
        # Do not use "skip all dot dirs" — Azure DevOps paths may live under .claude-plugin/, etc.
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            p = Path(dirpath) / name
            if not should_process(p):
                continue
            try:
                data = p.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                continue
            new = neutralize_text(data, gh)
            if new != data:
                p.write_text(new, encoding="utf-8", newline="\n")
                n += 1
    print(f"Neutralize pass done. Updated {n} files under {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
