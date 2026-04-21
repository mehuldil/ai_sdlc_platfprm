#!/bin/bash

# commit-msg hook: Validates commit messages against conventional commits format
# Reference: rules/commit-conventions.md
# Make executable: chmod +x hooks/commit-msg.sh
# Install in .git/hooks/commit-msg

set -e

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Extract first line
FIRST_LINE=$(echo "$COMMIT_MSG" | head -n 1)

# Validation rules
VALID_TYPES="feat|fix|refactor|test|docs|chore|perf|ci"
# Pattern: <type>(<scope>): <description> AB#<id>
# Or for infra: <type>: <description> [no-ref]
CONVENTIONAL_PATTERN="^(${VALID_TYPES})(\(.+\))?: .+ (AB#[0-9]+|\\[no-ref\\])$"

# Check max length (72 chars for first line)
FIRST_LINE_LENGTH=${#FIRST_LINE}
if [ "$FIRST_LINE_LENGTH" -gt 72 ]; then
    echo -e "${RED}ERROR: Commit message first line exceeds 72 characters${NC}"
    echo -e "${RED}Current length: $FIRST_LINE_LENGTH characters${NC}"
    echo ""
    echo -e "${YELLOW}Expected format:${NC}"
    echo "<type>(<scope>): <description> AB#<id>"
    echo ""
    echo -e "${YELLOW}Valid types:${NC} feat, fix, refactor, test, docs, chore, perf, ci"
    echo -e "${YELLOW}Examples:${NC}"
    echo "  feat(auth): add JWT token validation AB#123"
    echo "  fix(database): resolve connection pool leak AB#456"
    echo "  docs: update API documentation AB#789"
    echo "  chore: update dependencies [no-ref]"
    exit 1
fi

# Validate against conventional commits pattern
if ! echo "$FIRST_LINE" | grep -qE "$CONVENTIONAL_PATTERN"; then
    echo -e "${RED}ERROR: Commit message does not follow conventional commits format${NC}"
    echo ""
    echo -e "${RED}Your message:${NC}"
    echo "  $FIRST_LINE"
    echo ""
    echo -e "${YELLOW}Expected format:${NC}"
    echo "<type>(<scope>): <description> AB#<id>"
    echo ""
    echo -e "${YELLOW}Valid types:${NC} feat, fix, refactor, test, docs, chore, perf, ci"
    echo ""
    echo -e "${YELLOW}Rules:${NC}"
    echo "  • First line must start with a valid type"
    echo "  • Type may include optional scope in parentheses: feat(scope)"
    echo "  • Description after colon and space"
    echo "  • Must end with AB#<id> (e.g., AB#123)"
    echo "  • Infrastructure commits may use [no-ref] instead of AB#<id>"
    echo "  • Maximum 72 characters on first line"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  feat(auth): add JWT token validation AB#123"
    echo "  fix(database): resolve connection pool leak AB#456"
    echo "  refactor(api): extract validation logic AB#789"
    echo "  test: add unit tests for auth service AB#101"
    echo "  docs: update API documentation AB#102"
    echo "  chore: update dependencies [no-ref]"
    echo "  perf(cache): optimize query performance AB#103"
    echo "  ci: add GitHub Actions workflow AB#104"
    exit 1
fi

# Verify AB# reference exists (unless [no-ref])
if ! echo "$FIRST_LINE" | grep -qE "(AB#[0-9]+|\\[no-ref\\])"; then
    echo -e "${RED}ERROR: Commit message must include AB# reference or [no-ref]${NC}"
    echo ""
    echo -e "${RED}Your message:${NC}"
    echo "  $FIRST_LINE"
    echo ""
    echo -e "${YELLOW}Add a tracking ID to the end:${NC}"
    echo "  feat(scope): description AB#<ticket-id>"
    echo ""
    echo -e "${YELLOW}For infrastructure changes without a ticket:${NC}"
    echo "  chore: description [no-ref]"
    exit 1
fi

echo -e "${GREEN}✓ Commit message valid${NC}"
exit 0
