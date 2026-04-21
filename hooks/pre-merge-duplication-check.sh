#!/bin/bash

# pre-merge-duplication-check hook: Detects duplicate skill names across files
# Exact duplicate names → exit 1 (set SDLC_DEDUP_SOFT=1 to warn only)
# Similar names → warnings only
# Make executable: chmod +x hooks/pre-merge-duplication-check.sh

set -e

# Color codes for output
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Ensure .sdlc/logs directory exists
mkdir -p .sdlc/logs

LOG_FILE=".sdlc/logs/duplication-check.log"

# Function to log duplication checks
log_check() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# Get list of changed files (compare with base branch)
if [ -n "$GITHUB_BASE_REF" ]; then
    # GitHub Actions context
    BASE_REF="$GITHUB_BASE_REF"
    CURRENT_REF="HEAD"
elif [ -n "$GITHUB_TARGET_BRANCH" ]; then
    BASE_REF="$GITHUB_TARGET_BRANCH"
    CURRENT_REF="HEAD"
else
    # Local git context - compare with develop or main
    if git rev-parse --verify develop > /dev/null 2>&1; then
        BASE_REF="develop"
    else
        BASE_REF="main"
    fi
    CURRENT_REF="HEAD"
fi

# Get changed skill/agent files
CHANGED_SKILL_FILES=$(git diff --name-only "$BASE_REF...$CURRENT_REF" 2>/dev/null | grep -E "^skills/.*SKILL\.md$|^agents/.*SKILL\.md$" || echo "")

# If no skill/agent files changed, exit cleanly
if [ -z "$CHANGED_SKILL_FILES" ]; then
    exit 0
fi

echo ""
echo -e "${BLUE}Checking for duplicate skills and agents...${NC}"
echo ""

DUPLICATES_FOUND=0
WARNINGS_ISSUED=0

# Parse skill names from changed files
declare -A NEW_SKILL_NAMES
declare -A NEW_SKILL_PATHS

for skill_file in $CHANGED_SKILL_FILES; do
    if [ -f "$skill_file" ]; then
        # Extract skill name from frontmatter: name: skill-name
        SKILL_NAME=$(grep -m1 "^name:" "$skill_file" | cut -d':' -f2- | xargs 2>/dev/null || echo "")

        if [ -z "$SKILL_NAME" ]; then
            echo -e "${YELLOW}⚠ Could not extract skill name from: $skill_file${NC}"
            continue
        fi

        NEW_SKILL_NAMES["$SKILL_NAME"]="$skill_file"
        NEW_SKILL_PATHS["$skill_file"]="$SKILL_NAME"
    fi
done

# Get all existing skill files (excluding the ones being changed)
EXISTING_SKILL_FILES=$(find skills agents -name "SKILL.md" -type f 2>/dev/null | grep -v "$BASE_REF" || echo "")

declare -A EXISTING_SKILL_NAMES

# Parse existing skill names
for skill_file in $EXISTING_SKILL_FILES; do
    if [ -f "$skill_file" ]; then
        SKILL_NAME=$(grep -m1 "^name:" "$skill_file" | cut -d':' -f2- | xargs 2>/dev/null || echo "")
        if [ -n "$SKILL_NAME" ]; then
            EXISTING_SKILL_NAMES["$SKILL_NAME"]="$skill_file"
        fi
    fi
done

# Check for exact duplicates (same skill name in two different files)
for new_skill in "${!NEW_SKILL_NAMES[@]}"; do
    if [ -n "${EXISTING_SKILL_NAMES[$new_skill]}" ]; then
        EXISTING_PATH="${EXISTING_SKILL_NAMES[$new_skill]}"
        NEW_PATH="${NEW_SKILL_NAMES[$new_skill]}"
        # Editing the same file: not a duplicate
        if [ "$EXISTING_PATH" == "$NEW_PATH" ]; then
            continue
        fi
        DUPLICATES_FOUND=$((DUPLICATES_FOUND + 1))

        echo -e "${PURPLE}🔄 EXACT DUPLICATE FOUND${NC}"
        echo ""
        echo -e "${BLUE}Skill Name:${NC} $new_skill"
        echo -e "${YELLOW}Existing:${NC} $EXISTING_PATH"
        echo -e "${YELLOW}New:${NC} $NEW_PATH"
        echo ""
        echo -e "${BLUE}Resolution options:${NC}"
        echo "  1. Use different name (e.g., add version suffix)"
        echo "  2. Update the existing skill instead of creating new one"
        echo "  3. Confirm intentional override (requires code review)"
        echo ""

        log_check "DUPLICATE" "Exact duplicate: $new_skill in $NEW_PATH (existing: $EXISTING_PATH)"
    fi
done

# Check for similar names (potential naming conflicts)
for new_skill in "${!NEW_SKILL_NAMES[@]}"; do
    for existing_skill in "${!EXISTING_SKILL_NAMES[@]}"; do
        # Skip exact matches (already checked above)
        if [ "$new_skill" == "$existing_skill" ]; then
            continue
        fi

        # Simple similarity check: if one is substring of other or very similar
        # Convert to lowercase for comparison
        NEW_LOWER=$(echo "$new_skill" | tr '[:upper:]' '[:lower:]')
        EXISTING_LOWER=$(echo "$existing_skill" | tr '[:upper:]' '[:lower:]')

        # Check if skills are similar (share > 70% of words)
        NEW_WORDS=$(echo "$NEW_LOWER" | tr '-' '\n' | sort)
        EXISTING_WORDS=$(echo "$EXISTING_LOWER" | tr '-' '\n' | sort)

        # Count matching words
        COMMON_WORDS=$(comm -12 <(echo "$NEW_WORDS") <(echo "$EXISTING_WORDS") | wc -l)
        NEW_WORD_COUNT=$(echo "$NEW_WORDS" | wc -l)
        EXISTING_WORD_COUNT=$(echo "$EXISTING_WORDS" | wc -l)

        MIN_WORDS=$(( NEW_WORD_COUNT < EXISTING_WORD_COUNT ? NEW_WORD_COUNT : EXISTING_WORD_COUNT ))

        if [ "$MIN_WORDS" -gt 0 ] && [ "$COMMON_WORDS" -ge "$MIN_WORDS" ]; then
            WARNINGS_ISSUED=$((WARNINGS_ISSUED + 1))
            EXISTING_PATH="${EXISTING_SKILL_NAMES[$existing_skill]}"
            NEW_PATH="${NEW_SKILL_NAMES[$new_skill]}"

            echo -e "${YELLOW}⚠ SIMILAR NAME DETECTED${NC}"
            echo ""
            echo -e "${BLUE}Similar skills found:${NC}"
            echo "  Existing: $existing_skill (in $EXISTING_PATH)"
            echo "  New: $new_skill (in $NEW_PATH)"
            echo ""
            echo -e "${BLUE}Recommendation:${NC}"
            echo "  • Review if these skills serve different purposes"
            echo "  • Consider merging if overlapping functionality"
            echo "  • Use more descriptive naming to distinguish"
            echo ""

            log_check "WARNING" "Similar names detected: $new_skill vs $existing_skill"
        fi
    done
done

# Summary
echo ""
if [ "$DUPLICATES_FOUND" -eq 0 ] && [ "$WARNINGS_ISSUED" -eq 0 ]; then
    echo -e "${GREEN}✓ No duplicate or similar skill names detected${NC}"
    log_check "INFO" "Pre-merge duplication check passed - no conflicts found"
else
    if [ "$DUPLICATES_FOUND" -gt 0 ]; then
        echo -e "${PURPLE}Found $DUPLICATES_FOUND exact duplicate(s)${NC}"
        log_check "ALERT" "Exact duplicates found: $DUPLICATES_FOUND"
    fi

    if [ "$WARNINGS_ISSUED" -gt 0 ]; then
        echo -e "${YELLOW}Found $WARNINGS_ISSUED similar name warning(s)${NC}"
        log_check "WARNING" "Similar names detected: $WARNINGS_ISSUED"
    fi

    echo ""
    echo -e "${BLUE}Note: This is a warning only.${NC}"
    echo -e "${BLUE}Code review required to resolve naming conflicts.${NC}"
fi

echo ""
echo -e "${BLUE}Full check logged to: $LOG_FILE${NC}"
echo ""

# Hard block on exact duplicate skill names across files (unless soft mode)
if [ "$DUPLICATES_FOUND" -gt 0 ]; then
    if [ "${SDLC_DEDUP_SOFT:-0}" != "1" ]; then
        echo -e "${RED}BLOCKED: duplicate skill/agent name — fix or set SDLC_DEDUP_SOFT=1 for advisory only.${NC}"
        exit 1
    fi
fi

exit 0
