#!/usr/bin/env bash
################################################################################
# Repair .claude/ mirrors for local platform development
#
# Replaces stale or nested copies under .claude/agents, .claude/skills,
# .claude/templates with single symlinks to canonical agents/, skills/, templates/.
#
# Use when: nested paths like .claude/skills/skills/ or .claude/agents/agents/
# appear (often from legacy per-entry symlinks on Windows/OneDrive).
#
# Requires: run from repo root OR pass platform root as first argument.
# Safe: only touches .claude/{agents,skills,templates}; does not delete canonical dirs.
################################################################################

set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
CLAUDE="${ROOT}/.claude"

_relative_path() {
  local source_dir="$1"
  local target="$2"
  if command -v realpath &>/dev/null && realpath --relative-to="$source_dir" "$target" 2>/dev/null; then
    return 0
  fi
  if command -v python3 &>/dev/null; then
    python3 -c "import os.path; print(os.path.relpath('$target', '$source_dir'))" 2>/dev/null && return 0
  fi
  echo "$target"
}

mkdir -p "$CLAUDE"

for pair in "agents:${ROOT}/agents" "skills:${ROOT}/skills" "templates:${ROOT}/templates"; do
  name="${pair%%:*}"
  target="${pair##*:}"
  if [[ ! -d "$target" ]]; then
    echo "Skip ${name}: missing $target"
    continue
  fi
  dest="${CLAUDE}/${name}"
  rm -rf "$dest" 2>/dev/null || true
  rel="$(_relative_path "$CLAUDE" "$target")"
  ln -sfn "$rel" "$dest"
  echo "OK: ${dest} -> ${rel}"
done

echo "Done. Re-run: bash scripts/validate-cross-tool.sh --verbose"
