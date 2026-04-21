@echo off
REM DEPRECATED — do not use for production merges.
REM This script previously deleted paths and pushed directly to main, which violates rules/branch-strategy.md.
REM Use a feature branch, open a PR, and run CI (including PR traceability checks).

echo.
echo This batch file is intentionally disabled.
echo Use: git checkout -b feature/your-change
echo      git push -u origin HEAD
echo      Open a Pull Request on your remote (Azure Repos / GitHub).
echo.
echo See REPO_LAYOUT.md and rules/branch-strategy.md
exit /b 1
