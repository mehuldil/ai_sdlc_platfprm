#!/usr/bin/env bash
# sdlc-auto-sync.sh — Refresh module KB + semantic team JSONL (git-tracked) + local SQLite import
# Usage:
#   sdlc-auto-sync.sh pre-commit     # before commit: module update, export JSONL, git add tracked paths
#   sdlc-auto-sync.sh post-merge     # after pull/merge: module update, import JSONL → SQLite
#   sdlc-auto-sync.sh post-checkout  # after branch checkout (flag=1): same as post-merge
#   sdlc-auto-sync.sh post-commit    # optional async backup if commit used --no-verify
#
# Env:
#   SDL_AUTO_SYNC=0       — skip all
#   SDL_AUTO_SYNC_MODULE=0 — skip module-update
#   SDL_AUTO_SYNC_SEMANTIC=0 — skip semantic export/import
#   sdlc-auto-sync.sh ci-verify   — syntax check (no git required; used by CI)

set -euo pipefail

MODE="${1:-help}"

if [[ "$MODE" == "ci-verify" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PLAT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  bash -n "$SCRIPT_DIR/sdlc-auto-sync.sh"
  for f in module-update.sh module-init.sh bootstrap-sdlc-features.sh; do
    bash -n "$PLAT_ROOT/scripts/$f"
  done
  bash -n "$PLAT_ROOT/hooks/pre-commit.sh"
  echo "[sdlc-auto-sync] ci-verify OK"
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "[sdlc-auto-sync] not in a git repository — skip"
  exit 0
fi
cd "$REPO_ROOT"

if [[ "${SDL_AUTO_SYNC:-1}" == "0" ]]; then
  exit 0
fi

_find_platform() {
  local d
  for d in "$REPO_ROOT/ai-sdlc-platform" "$REPO_ROOT/../ai-sdlc-platform" "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; do
    if [[ -f "$d/scripts/module-update.sh" && -f "$d/scripts/semantic-memory.py" ]]; then
      echo "$d"
      return 0
    fi
  done
  return 1
}

PLAT="$(_find_platform || true)"
if [[ -z "$PLAT" ]]; then
  echo "[sdlc-auto-sync] ai-sdlc-platform not found — skip"
  exit 0
fi

MODULE_UPDATE="$PLAT/scripts/module-update.sh"
SEMANTIC_PY="$PLAT/scripts/semantic-memory.py"
TEAM_JSONL="$REPO_ROOT/.sdlc/memory/semantic-memory-team.jsonl"
MODULE_DIR="$REPO_ROOT/.sdlc/module"

_run_python() {
  if command -v python3 &>/dev/null && python3 -V &>/dev/null; then
    (cd "$REPO_ROOT" && python3 "$SEMANTIC_PY" "$@")
    return $?
  fi
  if command -v python &>/dev/null && python -V &>/dev/null; then
    (cd "$REPO_ROOT" && python "$SEMANTIC_PY" "$@")
    return $?
  fi
  if command -v py &>/dev/null && py -3 -V &>/dev/null; then
    (cd "$REPO_ROOT" && py -3 "$SEMANTIC_PY" "$@")
    return $?
  fi
  echo "[sdlc-auto-sync] Python not found — semantic sync skipped"
  return 1
}

_run_module_update() {
  if [[ "${SDL_AUTO_SYNC_MODULE:-1}" == "0" ]]; then
    return 0
  fi
  if [[ ! -d "$MODULE_DIR" ]]; then
    return 0
  fi
  bash "$MODULE_UPDATE" "$REPO_ROOT" || true
}

_run_semantic_export() {
  if [[ "${SDL_AUTO_SYNC_SEMANTIC:-1}" == "0" ]]; then
    return 0
  fi
  mkdir -p "$REPO_ROOT/.sdlc/memory"
  _run_python export --output "$TEAM_JSONL" || true
}

_run_semantic_import() {
  if [[ "${SDL_AUTO_SYNC_SEMANTIC:-1}" == "0" ]]; then
    return 0
  fi
  if [[ ! -f "$TEAM_JSONL" ]]; then
    return 0
  fi
  _run_python import --input "$TEAM_JSONL" --conflict-strategy last_write_wins || true
}

_git_add_tracked() {
  if [[ -d "$REPO_ROOT/.sdlc/module" ]]; then
    git add "$REPO_ROOT/.sdlc/module" 2>/dev/null || true
  fi
  if [[ -f "$TEAM_JSONL" ]]; then
    git add -f "$TEAM_JSONL" 2>/dev/null || git add "$TEAM_JSONL" 2>/dev/null || true
  fi
}

case "$MODE" in
  pre-commit)
    _run_module_update
    _run_semantic_export
    _git_add_tracked
    ;;
  post-merge|post-checkout)
    _run_module_update
    _run_semantic_import
    ;;
  post-commit)
    # Fire-and-forget safety net when pre-commit was skipped (--no-verify)
    SELF="${BASH_SOURCE[0]}"
    if command -v nohup &>/dev/null; then
      nohup bash "$SELF" internal-post-commit-run </dev/null >/dev/null 2>&1 &
    else
      bash "$SELF" internal-post-commit-run &
    fi
    ;;
  internal-post-commit-run)
    _run_module_update
    _run_semantic_export
    ;;
  help|*)
    echo "Usage: sdlc-auto-sync.sh pre-commit|post-merge|post-checkout|post-commit|ci-verify"
    exit 0
    ;;
esac

exit 0
