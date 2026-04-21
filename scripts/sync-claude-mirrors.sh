#!/usr/bin/env bash
################################################################################
# sync-claude-mirrors.sh — Cross-platform (Mac + Windows) mirror sync
#
# Regenerates .claude/{agents,skills,templates} as byte-identical copies of the
# canonical trees at the repo root. Use this in place of symlinks when the team
# mixes Mac and Windows (Windows symlinks require core.symlinks=true + dev mode
# and silently degrade to text files otherwise).
#
# Usage:
#   bash scripts/sync-claude-mirrors.sh          # regenerate all mirrors
#   bash scripts/sync-claude-mirrors.sh --check  # diff-only, exit 1 on drift
#
# Canonical source of truth stays under agents/, skills/, templates/ — edits
# belong there. Run this script (or rely on pre-commit hook) before committing
# so .claude/ always matches.
################################################################################

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE="${ROOT}/.claude"
MODE="sync"

if [[ "${1:-}" == "--check" ]]; then
  MODE="check"
fi

mkdir -p "$CLAUDE"

DRIFT=0
for name in agents skills templates; do
  canonical="${ROOT}/${name}"
  mirror="${CLAUDE}/${name}"
  if [[ ! -d "$canonical" ]]; then
    echo "[skip] canonical ${name}/ missing"
    continue
  fi

  if [[ "$MODE" == "check" ]]; then
    if [[ ! -d "$mirror" ]]; then
      echo "[drift] mirror .claude/${name} missing"
      DRIFT=1
      continue
    fi
    if ! diff -rq "$canonical" "$mirror" > /dev/null 2>&1; then
      echo "[drift] .claude/${name} differs from ${name}/"
      DRIFT=1
    else
      echo "[ok] .claude/${name} in sync"
    fi
    continue
  fi

  # Sync mode: regenerate mirror as byte-identical copy.
  # Remove existing mirror (could be symlink, directory, or stale file).
  if [[ -L "$mirror" ]]; then
    rm -f "$mirror"
  elif [[ -d "$mirror" ]]; then
    rm -rf "$mirror"
  elif [[ -e "$mirror" ]]; then
    rm -f "$mirror"
  fi

  # Prefer rsync when available (respects file times); fall back to cp -R.
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${canonical}/" "${mirror}/"
  else
    cp -R "${canonical}" "${mirror}"
  fi
  echo "[synced] .claude/${name} ← ${name}/"
done

if [[ "$MODE" == "check" && "$DRIFT" -ne 0 ]]; then
  echo ""
  echo "ERROR: .claude/ mirror drift detected. Run: bash scripts/sync-claude-mirrors.sh"
  exit 1
fi

echo "sync-claude-mirrors: DONE (mode=$MODE)"
