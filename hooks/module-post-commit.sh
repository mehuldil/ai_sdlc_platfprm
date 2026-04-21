#!/usr/bin/env bash
################################################################################
# Unified Module System — Post-Commit Hook
# Auto-updates module knowledge after commit (runs async)
################################################################################

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODULE_DIR="$REPO_ROOT/.sdlc/module"

# Skip if module system not initialized
[[ ! -d "$MODULE_DIR" ]] && exit 0

# Find update script
SCRIPT_DIR=""
for dir in "$REPO_ROOT/ai-sdlc-platform/scripts" "$REPO_ROOT/scripts" "$(dirname "${BASH_SOURCE[0]}")/../scripts"; do
  if [[ -f "$dir/module-update.sh" ]]; then
    SCRIPT_DIR="$dir"
    break
  fi
done

if [[ -n "$SCRIPT_DIR" ]]; then
  # Run async — don't slow down commit
  nohup bash "$SCRIPT_DIR/module-update.sh" "$REPO_ROOT" > /dev/null 2>&1 &
fi

exit 0
