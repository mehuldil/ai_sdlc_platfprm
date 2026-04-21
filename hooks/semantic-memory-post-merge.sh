#!/bin/bash
################################################################################
# Post-Merge/Post-Pull Hook: Semantic Memory Import
# Imports team semantic memory from JSONL after pull/merge
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Semantic Memory Post-Merge]${NC} Importing team memory..."

# Find project root
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${YELLOW}⚠${NC} Not in a git repository, skipping import"
    exit 0
fi

SEMANTIC_JSONL="$PROJECT_ROOT/.sdlc/memory/semantic-memory-team.jsonl"
SEMANTIC_PY="$PLATFORM_DIR/scripts/semantic-memory.py"

if [[ ! -f "$SEMANTIC_PY" ]]; then
    echo -e "${YELLOW}⚠${NC} semantic-memory.py not found, skipping import"
    exit 0
fi

if [[ ! -f "$SEMANTIC_JSONL" ]]; then
    echo -e "${YELLOW}→${NC} No team memory JSONL found (this is OK)"
    exit 0
fi

# Import from JSONL
if command -v python3 &>/dev/null; then
    echo -e "${BLUE}→${NC} Importing team semantic memory..."
    if python3 "$SEMANTIC_PY" import --input "$SEMANTIC_JSONL" --conflict-strategy=last_write_wins 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Team semantic memory imported"
    else
        echo -e "${YELLOW}⚠${NC} Import had issues (may be empty or conflicts)"
    fi
elif command -v python &>/dev/null; then
    echo -e "${BLUE}→${NC} Importing team semantic memory..."
    if python "$SEMANTIC_PY" import --input "$SEMANTIC_JSONL" --conflict-strategy=last_write_wins 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Team semantic memory imported"
    else
        echo -e "${YELLOW}⚠${NC} Import had issues (may be empty or conflicts)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Python not found, skipping import"
fi

exit 0
