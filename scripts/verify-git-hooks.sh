#!/usr/bin/env bash
# verify-git-hooks.sh — Verify SDLC git hooks are installed (post-clone / setup)
# Usage: verify-git-hooks.sh [repo-root] [--warn-only]
# Exit 0 if hooks OK, 1 if not (--warn-only: print status but exit 0)

set -euo pipefail

REPO="."
WARN_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --warn-only) WARN_ONLY=1 ;;
    *) REPO="$1" ;;
  esac
  shift
done

cd "$REPO" || {
  echo "verify-git-hooks: cannot cd to $REPO"
  exit 1
}

# CI agents clone without running local setup — hooks are not installed there
if [[ -n "${CI:-}" || -n "${TF_BUILD:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  echo "verify-git-hooks: OK (skipped in CI — hooks installed by ./setup.sh locally)"
  exit 0
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "verify-git-hooks: not a git repository: $REPO"
  [[ "$WARN_ONLY" -eq 1 ]] && exit 0
  exit 1
fi

TOP="$(git rev-parse --show-toplevel)"
cd "$TOP"

HOOKS_PATH="$(git config core.hooksPath 2>/dev/null || echo "")"
if [[ -n "$HOOKS_PATH" ]]; then
  # Resolve relative hooksPath from repo root
  if [[ -d "$TOP/$HOOKS_PATH" ]]; then
    if [[ -f "$TOP/$HOOKS_PATH/pre-commit.sh" ]] || [[ -f "$TOP/$HOOKS_PATH/pre-commit" ]]; then
      echo "verify-git-hooks: OK (core.hooksPath=$HOOKS_PATH)"
      exit 0
    fi
  fi
fi

if [[ -x ".git/hooks/pre-commit" ]]; then
  echo "verify-git-hooks: OK (.git/hooks/pre-commit)"
  if [[ -f ".git/hooks/post-merge" ]] && grep -q "sdlc-auto-sync" ".git/hooks/post-merge" 2>/dev/null; then
    echo "verify-git-hooks: OK (.git/hooks/post-merge — SDLC auto-sync)"
  else
    echo "verify-git-hooks: WARN — re-run ./setup.sh to install post-merge/post-checkout (fetch parity)"
  fi
  exit 0
fi

echo "verify-git-hooks: FAIL — no pre-commit hook found."
echo "  Fix: run ./setup.sh from ai-sdlc-platform, or: sdlc setup (installs hooks), or ./setup-documentation.sh"
if [[ "$WARN_ONLY" -eq 1 ]]; then
  exit 0
fi
exit 1

