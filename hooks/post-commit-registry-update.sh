#!/bin/bash

################################################################################
# Post-Commit Hook: Registry Auto-Generation
#
# Automatically regenerates registries after commits that modify:
# - agents/ directory → regenerate CAPABILITY_MATRIX.md
# - skills/ directory → regenerate SKILL.md
# - .claude/commands/ directory → regenerate COMMANDS_REGISTRY.md
#
# Install: ln -s ../../hooks/post-commit-registry-update.sh .git/hooks/post-commit
# Or: git config core.hooksPath hooks
#
# This runs AFTER a commit is made, so it's non-blocking.
# It stages any registry updates automatically.
################################################################################

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if registry regeneration script exists
REGEN_SCRIPT="scripts/regenerate-registries.sh"

if [ ! -f "$REGEN_SCRIPT" ]; then
    exit 0  # Script not found, skip silently
fi

# Get files changed in the last commit
CHANGED_FILES=$(git diff --name-only HEAD~1..HEAD 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
    exit 0  # No files changed, nothing to do
fi

# Check what changed
AGENTS_CHANGED=$(echo "$CHANGED_FILES" | grep -c "^agents/" || true)
SKILLS_CHANGED=$(echo "$CHANGED_FILES" | grep -c "^skills/" || true)
COMMANDS_CHANGED=$(echo "$CHANGED_FILES" | grep -c "^\\.claude/commands/" || true)

# If nothing relevant changed, exit early
if [ "$AGENTS_CHANGED" -eq 0 ] && [ "$SKILLS_CHANGED" -eq 0 ] && [ "$COMMANDS_CHANGED" -eq 0 ]; then
    exit 0
fi

echo -e "${BLUE}[Post-Commit Registry Update]${NC} Checking registries..."

# Run registry regeneration in check mode
if bash "$REGEN_SCRIPT" --check 2>/dev/null; then
    # All registries are current
    exit 0
else
    # Registries need updating
    echo -e "${YELLOW}→${NC} Registries out of date, regenerating..."

    # Regenerate registries
    bash "$REGEN_SCRIPT" --update 2>/dev/null

    # Stage registry updates
    UPDATES_MADE=0

    if echo "$AGENTS_CHANGED" | grep -q "^agents/"; then
        if git diff --quiet agents/CAPABILITY_MATRIX.md 2>/dev/null; then
            # File changed, stage it
            git add agents/CAPABILITY_MATRIX.md
            echo -e "${GREEN}✓${NC} Staged agents/CAPABILITY_MATRIX.md"
            UPDATES_MADE=$((UPDATES_MADE + 1))
        fi
    fi

    if echo "$SKILLS_CHANGED" | grep -q "^skills/"; then
        if ! git diff --quiet skills/SKILL.md 2>/dev/null; then
            git add skills/SKILL.md
            echo -e "${GREEN}✓${NC} Staged skills/SKILL.md"
            UPDATES_MADE=$((UPDATES_MADE + 1))
        fi
    fi

    if echo "$COMMANDS_CHANGED" | grep -q "^\\.claude/commands/"; then
        if ! git diff --quiet .claude/commands/COMMANDS_REGISTRY.md 2>/dev/null; then
            git add .claude/commands/COMMANDS_REGISTRY.md
            echo -e "${GREEN}✓${NC} Staged .claude/commands/COMMANDS_REGISTRY.md"
            UPDATES_MADE=$((UPDATES_MADE + 1))
        fi
    fi

    if [ $UPDATES_MADE -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}ℹ${NC} Registry files staged. Amend your commit:"
        echo -e "   ${BLUE}git commit --amend --no-edit${NC}"
        echo ""
    fi
fi

exit 0
