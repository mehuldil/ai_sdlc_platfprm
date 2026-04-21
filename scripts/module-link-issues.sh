#!/usr/bin/env bash
################################################################################
# Unified Module System — ADO Issue Linking
# Finds AB#XXXXX references in changed files + branch name
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  echo -e "${RED}[ERROR]${NC} Not a git repo: $REPO_PATH"
  exit 1
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}MODULE SYSTEM — ADO ISSUE LINKING${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""

# Get branch story ID
BRANCH=$(cd "$REPO_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
STORY_ID="none"
if [[ "$BRANCH" =~ (US|AB|PBI|BUG)-[0-9]+ ]]; then
  STORY_ID="${BASH_REMATCH[0]}"
fi

log_info "Branch: $BRANCH"
[[ "$STORY_ID" != "none" ]] && log_success "Story ID: $STORY_ID"
echo ""

# Scan changed files for ADO refs
CHANGED=$(cd "$REPO_PATH" && git diff --name-only 2>/dev/null || echo "")
[[ -z "$CHANGED" ]] && CHANGED=$(cd "$REPO_PATH" && git diff --cached --name-only 2>/dev/null || echo "")

ADO_REFS=""
while IFS= read -r file; do
  [[ -z "$file" || ! -f "$REPO_PATH/$file" ]] && continue
  refs=$(grep -o 'AB#[0-9]\+' "$REPO_PATH/$file" 2>/dev/null || true)
  [[ -n "$refs" ]] && ADO_REFS="${ADO_REFS}${refs}\n"
done <<< "$CHANGED"

# Also scan recent commits
COMMIT_REFS=$(cd "$REPO_PATH" && git log --oneline -10 2>/dev/null | grep -o 'AB#[0-9]\+' || true)
[[ -n "$COMMIT_REFS" ]] && ADO_REFS="${ADO_REFS}${COMMIT_REFS}\n"

# Deduplicate and display
UNIQUE_REFS=$(echo -e "$ADO_REFS" | sort -u | grep -v '^$' || true)

if [[ -n "$UNIQUE_REFS" ]]; then
  REF_COUNT=$(echo "$UNIQUE_REFS" | wc -l | tr -d ' ')
  log_success "Found $REF_COUNT linked issue(s):"
  echo ""
  echo "$UNIQUE_REFS" | while read -r ref; do
    echo "  - $ref"
  done
else
  log_warn "No ADO references found (AB#XXXXX format)"
fi

echo ""
echo -e "${CYAN}Tip:${NC} Reference issues in commits:"
echo "  git commit -m \"Fix validation (Fixes AB#12345)\""
echo ""
