#!/usr/bin/env bash
# validate-system-change.sh — Meta-layer checks for skills/agents/rules/commands changes
# Usage: validate-system-change.sh [platform-root]
# Exits non-zero if validate-rules or validate-commands fails.
# Full pipeline (includes smoke): scripts/ci-sdlc-platform.sh  |  CI skips hook verify when CI/TF_BUILD/GITHUB_ACTIONS is set.
# Note: Exact skill-name duplication is enforced by hooks/pre-merge-duplication-check.sh on merge/CI.

set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT" || exit 1

FAIL=0

if [[ -f scripts/validate-rules.sh ]]; then
  if bash scripts/validate-rules.sh "$ROOT"; then
    echo "[ok] validate-rules.sh"
  else
    echo "[fail] validate-rules.sh"
    FAIL=1
  fi
else
  echo "[skip] validate-rules.sh not found"
fi

if [[ -f scripts/validate-commands.sh ]]; then
  if bash scripts/validate-commands.sh "$ROOT"; then
    echo "[ok] validate-commands.sh"
  else
    echo "[fail] validate-commands.sh"
    FAIL=1
  fi
else
  echo "[skip] validate-commands.sh not found"
fi

if [[ -f scripts/verify-git-hooks.sh ]]; then
  if bash scripts/verify-git-hooks.sh "$ROOT"; then
    echo "[ok] verify-git-hooks.sh"
  else
    echo "[warn] verify-git-hooks.sh — install hooks via ./setup.sh or sdlc setup"
    FAIL=1
  fi
fi

if [[ -f scripts/regenerate-registries.sh ]]; then
  if bash scripts/regenerate-registries.sh --check; then
    echo "[ok] regenerate-registries.sh --check"
  else
    echo "[fail] registry drift — run: bash scripts/regenerate-registries.sh --update"
    FAIL=1
  fi
else
  echo "[skip] regenerate-registries.sh not found"
fi

if [[ -f scripts/validate-stage-variants.sh ]]; then
  if bash scripts/validate-stage-variants.sh "$ROOT"; then
    echo "[ok] validate-stage-variants.sh"
  else
    echo "[fail] validate-stage-variants.sh"
    FAIL=1
  fi
else
  echo "[skip] validate-stage-variants.sh not found"
fi

if [[ -f scripts/verify-claude-ssot-ci.sh ]]; then
  if bash scripts/verify-claude-ssot-ci.sh "$ROOT"; then
    echo "[ok] verify-claude-ssot-ci.sh"
  else
    echo "[fail] verify-claude-ssot-ci.sh — ensure .claude/agents|skills|templates mirror agents/|skills|templates/"
    FAIL=1
  fi
else
  echo "[skip] verify-claude-ssot-ci.sh not found"
fi

if [[ $FAIL -ne 0 ]]; then
  echo ""
  echo "validate-system-change: FAILED — fix issues before merging platform changes."
  exit 1
fi
echo ""
echo "validate-system-change: PASSED."
exit 0
