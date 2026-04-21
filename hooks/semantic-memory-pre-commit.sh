#!/bin/bash
################################################################################
# Pre-Commit Hook: Semantic Memory Export
# Exports active semantic memory to JSONL for team sync before commit
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Semantic Memory Pre-Commit]${NC} Exporting team memory..."

# Find project root (look for .git)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${YELLOW}⚠${NC} Not in a git repository, skipping semantic memory export"
    exit 0
fi

# Check if semantic memory exists
SEMANTIC_DB="$PROJECT_ROOT/.sdlc/memory/semantic-memory.sqlite3"
SEMANTIC_JSONL="$PROJECT_ROOT/.sdlc/memory/semantic-memory-team.jsonl"
SEMANTIC_PY="$PLATFORM_DIR/scripts/semantic-memory.py"

if [[ ! -f "$SEMANTIC_PY" ]]; then
    echo -e "${YELLOW}⚠${NC} semantic-memory.py not found, skipping export"
    exit 0
fi

if [[ ! -f "$SEMANTIC_DB" ]]; then
    echo -e "${YELLOW}→${NC} No semantic memory database found (this is OK for new projects)"
    exit 0
fi

# Export to JSONL
if command -v python3 &>/dev/null; then
    echo -e "${BLUE}→${NC} Exporting semantic memory to team JSONL..."
    if python3 "$SEMANTIC_PY" export --output "$SEMANTIC_JSONL" 2>/dev/null; then
        # Stage the JSONL file if it changed
        if [[ -f "$SEMANTIC_JSONL" ]]; then
            git add "$SEMANTIC_JSONL" 2>/dev/null || true
            echo -e "${GREEN}✓${NC} Semantic memory exported and staged"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Semantic memory export failed (non-critical)"
    fi
elif command -v python &>/dev/null; then
    echo -e "${BLUE}→${NC} Exporting semantic memory to team JSONL..."
    if python "$SEMANTIC_PY" export --output "$SEMANTIC_JSONL" 2>/dev/null; then
        if [[ -f "$SEMANTIC_JSONL" ]]; then
            git add "$SEMANTIC_JSONL" 2>/dev/null || true
            echo -e "${GREEN}✓${NC} Semantic memory exported and staged"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Semantic memory export failed (non-critical)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Python not found, skipping semantic memory export"
fi

exit 0
