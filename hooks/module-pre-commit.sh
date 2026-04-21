#!/usr/bin/env bash
################################################################################
# Unified Module System — Pre-Commit Hook
# Validates contracts + flags breaking changes before commit
# Advisory-only: warns but NEVER blocks
################################################################################

set -eo pipefail

BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

# Find repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODULE_DIR="$REPO_ROOT/.sdlc/module"

# Skip if module system not initialized
if [[ ! -d "$MODULE_DIR/contracts" ]]; then
  exit 0
fi

echo ""
echo -e "${CYAN}[Module System] Pre-commit validation...${NC}"

# Find the validation script
SCRIPT_DIR=""
for dir in "$REPO_ROOT/ai-sdlc-platform/scripts" "$REPO_ROOT/scripts" "$(dirname "${BASH_SOURCE[0]}")/../scripts"; do
  if [[ -f "$dir/module-validate.sh" ]]; then
    SCRIPT_DIR="$dir"
    break
  fi
done

if [[ -n "$SCRIPT_DIR" ]]; then
  bash "$SCRIPT_DIR/module-validate.sh" "$REPO_ROOT"
else
  echo -e "${BLUE}[INFO]${NC} module-validate.sh not found (skipping)"
fi

# Always exit 0 — advisory only, never block
exit 0
