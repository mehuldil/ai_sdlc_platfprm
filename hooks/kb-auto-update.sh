#!/usr/bin/env bash
# Post-commit Hook: Auto-update Module Knowledgebase
set -eo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

if [[ ! -d "$REPO_ROOT/.sdlc/module-kb" ]]; then
  exit 0
fi

# Find platform directory
PLATFORM_DIR=""
for dir in "$REPO_ROOT"/../*; do
  if [[ -f "$dir/scripts/kb-update.sh" ]]; then
    PLATFORM_DIR="$dir"
    break
  fi
done

if [[ -z "$PLATFORM_DIR" ]]; then
  PLATFORM_DIR="$REPO_ROOT/../ai-sdlc-platform"
fi

if [[ ! -f "$PLATFORM_DIR/scripts/kb-update.sh" ]]; then
  exit 0
fi

# Run KB update in background
bash "$PLATFORM_DIR/scripts/kb-update.sh" "$REPO_ROOT" &

exit 0
