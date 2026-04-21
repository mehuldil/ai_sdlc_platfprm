#!/bin/bash

# branch-name-check hook: Validates branch names against branch strategy
# Reference: rules/branch-strategy.md
# Make executable: chmod +x hooks/branch-name-check.sh
# Install in .git/hooks/pre-push

set -e

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Branches that don't require validation
PROTECTED_BRANCHES="main|master|develop"

# Check if branch is protected (allowed without validation)
if echo "$BRANCH_NAME" | grep -qE "^(${PROTECTED_BRANCHES})$"; then
    echo -e "${GREEN}✓ Protected branch: $BRANCH_NAME${NC}"
    exit 0
fi

# Valid branch patterns:
# feature/AB#<id>-<description>
# bugfix/AB#<id>-<description>
# hotfix/AB#<id>-<description>
# release/<version>
VALID_PATTERN="^(feature|bugfix|hotfix)/AB#[0-9]+-[a-z0-9._-]+$|^release/[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?$"

# Validate branch name
if ! echo "$BRANCH_NAME" | grep -qiE "$VALID_PATTERN"; then
    echo -e "${RED}ERROR: Invalid branch name: $BRANCH_NAME${NC}"
    echo ""
    echo -e "${YELLOW}Valid branch patterns:${NC}"
    echo "  feature/AB#<id>-<description>"
    echo "  bugfix/AB#<id>-<description>"
    echo "  hotfix/AB#<id>-<description>"
    echo "  release/<version>"
    echo ""
    echo -e "${YELLOW}Protected branches (no validation needed):${NC}"
    echo "  main, master, develop"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  feature/AB#123-user-authentication"
    echo "  bugfix/AB#456-fix-database-leak"
    echo "  hotfix/AB#789-security-patch"
    echo "  release/1.2.0"
    echo "  release/2.0.0-rc1"
    echo ""
    echo -e "${YELLOW}Branch naming rules:${NC}"
    echo "  • Use lowercase letters, numbers, hyphens, underscores, and dots"
    echo "  • No spaces or special characters"
    echo "  • Feature/bugfix/hotfix must include AB# ticket ID"
    echo "  • Ticket ID format: AB#<number>"
    echo "  • Description must be hyphen-separated"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Branch name valid: $BRANCH_NAME${NC}"
exit 0
