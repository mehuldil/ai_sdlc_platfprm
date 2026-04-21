#!/bin/bash

################################################################################
# Pre-Commit Hook: Documentation Change Validation
#
# Enforces the Documentation Architecture governance:
# - If agents/skills/rules/commands/stages change, docs MUST be updated
# - Prevents documentation drift
# - Blocks commit if doc updates missing
#
# Install: ln -s ../../hooks/doc-change-check.sh .git/hooks/pre-commit
# Or: git config core.hooksPath hooks
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Doc-Change-Check]${NC} Validating documentation updates..."

ERROR_COUNT=0

# ============================================================================
# RULE 1: If agents changed → CAPABILITY_MATRIX.md must be updated
# ============================================================================
AGENT_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^agents/" | grep -v "CAPABILITY_MATRIX" || true)

if [ -n "$AGENT_CHANGES" ]; then
    echo -e "${YELLOW}→${NC} Agents directory changed:"
    echo "$AGENT_CHANGES" | head -3 | sed 's/^/   /'
    [ $(echo "$AGENT_CHANGES" | wc -l) -gt 3 ] && echo "   ... and $(( $(echo "$AGENT_CHANGES" | wc -l) - 3 )) more"

    if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "agents/CAPABILITY_MATRIX.md"; then
        echo -e "${GREEN}✓${NC} agents/CAPABILITY_MATRIX.md updated"
    else
        echo -e "${RED}✗${NC} agents/CAPABILITY_MATRIX.md NOT updated"
        echo -e "   ${RED}→${NC} Agents changed, but capability matrix not regenerated"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "User_Manual/Agents_Skills_Rules.md"; then
        echo -e "${GREEN}✓${NC} User_Manual/Agents_Skills_Rules.md updated"
    else
        echo -e "${RED}✗${NC} User_Manual/Agents_Skills_Rules.md NOT updated"
        echo -e "   ${RED}→${NC} Agent count may have changed"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
fi

# ============================================================================
# RULE 2: If skills changed → SKILL.md registry must be updated
# ============================================================================
SKILL_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^skills/" | grep -v "SKILL.md" || true)

if [ -n "$SKILL_CHANGES" ]; then
    echo -e "${YELLOW}→${NC} Skills directory changed:"
    echo "$SKILL_CHANGES" | head -3 | sed 's/^/   /'
    [ $(echo "$SKILL_CHANGES" | wc -l) -gt 3 ] && echo "   ... and $(( $(echo "$SKILL_CHANGES" | wc -l) - 3 )) more"

    if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "skills/SKILL.md"; then
        echo -e "${GREEN}✓${NC} skills/SKILL.md updated"
    else
        echo -e "${RED}✗${NC} skills/SKILL.md NOT updated"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "User_Manual/Agents_Skills_Rules.md"; then
        echo -e "${GREEN}✓${NC} User_Manual/Agents_Skills_Rules.md updated"
    else
        echo -e "${RED}⚠${NC} User_Manual/Agents_Skills_Rules.md may need update"
    fi
fi

# ============================================================================
# RULE 3: If commands changed → Commands.md must be updated
# ============================================================================
COMMAND_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^\\.claude/commands/" || true)

if [ -n "$COMMAND_CHANGES" ]; then
    echo -e "${YELLOW}→${NC} IDE commands changed:"
    echo "$COMMAND_CHANGES" | head -3 | sed 's/^/   /'
    [ $(echo "$COMMAND_CHANGES" | wc -l) -gt 3 ] && echo "   ... and $(( $(echo "$COMMAND_CHANGES" | wc -l) - 3 )) more"

    if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "User_Manual/Commands.md"; then
        echo -e "${GREEN}✓${NC} User_Manual/Commands.md updated"
    else
        echo -e "${RED}✗${NC} User_Manual/Commands.md NOT updated"
        echo -e "   ${RED}→${NC} New/changed commands must be documented"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
fi

# ============================================================================
# RULE 4: If rules changed → check if User_Manual affected
# ============================================================================
RULE_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^rules/" || true)

if [ -n "$RULE_CHANGES" ]; then
    echo -e "${YELLOW}→${NC} Rules directory changed:"

    # Check if system-critical rules changed
    CRITICAL_RULES=$(echo "$RULE_CHANGES" | grep -E "(ask-first|gate-enforcement|rpi-workflow|token-optimization)" || true)

    if [ -n "$CRITICAL_RULES" ]; then
        echo -e "   Critical rules affected:"
        echo "$CRITICAL_RULES" | sed 's/^/     /'

        if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "User_Manual/"; then
            echo -e "${GREEN}✓${NC} User_Manual file(s) updated"
        else
            echo -e "${YELLOW}⚠${NC} Critical rule changed but no User_Manual updates found"
            echo -e "   Verify: ask-first-protocol, gate-enforcement, token budgets still accurate"
        fi
    fi
fi

# ============================================================================
# RULE 5: If stages changed → SDLC_Flows.md must be updated
# ============================================================================
STAGE_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^stages/" | grep -v "ROUTING.md" || true)

if [ -n "$STAGE_CHANGES" ]; then
    echo -e "${YELLOW}→${NC} Stages directory changed:"
    echo "$STAGE_CHANGES" | head -3 | sed 's/^/   /'
    [ $(echo "$STAGE_CHANGES" | wc -l) -gt 3 ] && echo "   ... and $(( $(echo "$STAGE_CHANGES" | wc -l) - 3 )) more"

    if git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -q "User_Manual/SDLC_Flows.md"; then
        echo -e "${GREEN}✓${NC} User_Manual/SDLC_Flows.md updated"
    else
        echo -e "${RED}✗${NC} User_Manual/SDLC_Flows.md NOT updated"
        echo -e "   ${RED}→${NC} Stage changes require pipeline documentation update"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
fi

# ============================================================================
# RULE 6: User_Manual changes should NOT also modify implementation docs
# (unless rebuilding registries)
# ============================================================================
USER_MANUAL_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "^User_Manual/" || true)

if [ -n "$USER_MANUAL_CHANGES" ]; then
    echo -e "${BLUE}→${NC} User_Manual updated:"
    echo "$USER_MANUAL_CHANGES" | sed 's/^/   /'

    # This is fine - docs can be updated independently
    echo -e "${GREEN}✓${NC} Public API documentation updated"
fi

# ============================================================================
# RULE 7: Check for documentation file quality
# ============================================================================
DOC_CHANGES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E "\\.(md|txt)$" || true)

if [ -n "$DOC_CHANGES" ]; then
    BLANK_FILES=$(for f in $DOC_CHANGES; do
        if [ -f "$f" ]; then
            lines=$(wc -l < "$f" 2>/dev/null || echo 0)
            if [ "$lines" -lt 3 ]; then
                echo "$f"
            fi
        fi
    done || true)

    if [ -n "$BLANK_FILES" ]; then
        echo -e "${YELLOW}⚠${NC} Files appear to be mostly empty (< 3 lines):"
        echo "$BLANK_FILES" | sed 's/^/   /'
    fi
fi

# ============================================================================
# Summary & Decision
# ============================================================================
echo ""
echo -e "${BLUE}[Doc-Change-Check]${NC} Summary:"

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All documentation requirements satisfied"
    exit 0
else
    echo -e "${RED}✗${NC} $ERROR_COUNT documentation issue(s) found"
    echo ""
    echo -e "${RED}COMMIT BLOCKED${NC}"
    echo ""
    echo "Documentation governance requires:"
    echo "  - If agents change → Update agents/CAPABILITY_MATRIX.md + User_Manual/Agents_Skills_Rules.md"
    echo "  - If skills change → Update skills/SKILL.md + User_Manual/Agents_Skills_Rules.md"
    echo "  - If commands change → Update User_Manual/Commands.md"
    echo "  - If rules change → Verify User_Manual relevance"
    echo "  - If stages change → Update User_Manual/SDLC_Flows.md"
    echo ""
    echo "See DOCUMENTATION_ARCHITECTURE.md for details."
    echo ""
    echo "To commit anyway: git commit --no-verify"
    exit 1
fi
