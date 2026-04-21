#!/usr/bin/env bash
# Module Intelligence System (MIS) — Change Analysis Engine
# Analyzes commits/branches against contracts and detects breaking changes
set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_section() { echo -e "\n${MAGENTA}========== $* ==========${NC}\n"; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

# Detect reference (branch, commit, or current HEAD)
REF="${2:-HEAD}"
if [[ "$REF" == "HEAD" ]]; then
  COMPARE_BASE="$(cd "$REPO_PATH" && git merge-base HEAD origin/main 2>/dev/null || echo main)"
else
  COMPARE_BASE="$(cd "$REPO_PATH" && git merge-base "$REF" main 2>/dev/null || echo main)"
fi

if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Not a git repository: $REPO_PATH"
  exit 1
fi

CONTRACT_DIR="$REPO_PATH/.sdlc/module-contracts"
if [[ ! -d "$CONTRACT_DIR" ]]; then
  log_error "No module contracts found. Run: sdlc mis init $REPO_PATH"
  exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MODULE_NAME=$(basename "$REPO_PATH")

log_section "MIS Change Analysis: $MODULE_NAME"
log_info "Comparing: $COMPARE_BASE → $REF"
log_info "Repository: $REPO_PATH"
echo ""

# ============================================================================
# GET CHANGED FILES
# ============================================================================

cd "$REPO_PATH"
CHANGED_FILES=$(git diff --name-only "$COMPARE_BASE"..."$REF" 2>/dev/null || echo "")

log_section "CHANGED FILES"
if [[ -z "$CHANGED_FILES" ]]; then
  log_info "No files changed"
  exit 0
fi

echo "$CHANGED_FILES" | while read -r file; do
  echo "  $file"
done

# ============================================================================
# DETECT CHANGE TYPE
# ============================================================================

log_section "CHANGE TYPE DETECTION"

API_CHANGES=0
DATA_CHANGES=0
EVENT_CHANGES=0
LOGIC_CHANGES=0

echo "$CHANGED_FILES" | while read -r file; do
  if [[ "$file" =~ Controller\.java ]]; then
    API_CHANGES=$((API_CHANGES + 1))
    log_info "API change detected: $file"
  elif [[ "$file" =~ migrations?/.*\.sql ]]; then
    DATA_CHANGES=$((DATA_CHANGES + 1))
    log_info "Database schema change detected: $file"
  elif [[ "$file" =~ kafka|event.*\.java || "$file" =~ application.*\.(yml|properties) ]]; then
    EVENT_CHANGES=$((EVENT_CHANGES + 1))
    log_info "Event/Kafka change detected: $file"
  else
    LOGIC_CHANGES=$((LOGIC_CHANGES + 1))
    log_info "Business logic change detected: $file"
  fi
done

# ============================================================================
# ANALYZE FOR BREAKING CHANGES
# ============================================================================

log_section "BREAKING CHANGE ANALYSIS"

BREAKING_COUNT=0

# Check for database breaking changes
if [[ $DATA_CHANGES -gt 0 ]]; then
  while IFS= read -r file; do
    [[ "$file" =~ migrations?/.*\.sql ]] || continue

    log_info "Scanning migration: $file"

    # Check for breaking patterns in git diff
    git diff "$COMPARE_BASE"..."$REF" -- "$file" 2>/dev/null | {
      while IFS= read -r line; do
        if [[ "$line" =~ ^- && "$line" =~ DROP\ TABLE|ALTER\ TABLE.*DROP|RENAME\ COLUMN ]]; then
          log_warn "  ✗ BREAKING: Column/Table removal detected"
          BREAKING_COUNT=$((BREAKING_COUNT + 1))
        elif [[ "$line" =~ ^[+-] && "$line" =~ ALTER\ TABLE.*ADD.*NOT\ NULL ]]; then
          log_warn "  ✗ BREAKING: Added NOT NULL constraint to existing column"
          BREAKING_COUNT=$((BREAKING_COUNT + 1))
        elif [[ "$line" =~ ^[+-] && "$line" =~ CREATE\ TABLE ]]; then
          log_success "  ✓ Safe: New table created"
        fi
      done
    }
  done <<< "$CHANGED_FILES"
fi

# Check for API breaking changes
if [[ $API_CHANGES -gt 0 ]]; then
  while IFS= read -r file; do
    [[ "$file" =~ Controller\.java ]] || continue

    log_info "Scanning API: $file"

    git diff "$COMPARE_BASE"..."$REF" -- "$file" 2>/dev/null | {
      while IFS= read -r line; do
        if [[ "$line" =~ ^-.*@(Request|GetMapping|PostMapping) ]]; then
          log_warn "  ✗ BREAKING: Endpoint removed or renamed"
          BREAKING_COUNT=$((BREAKING_COUNT + 1))
        elif [[ "$line" =~ ^[+-].*required\ =\ true ]]; then
          log_warn "  ✗ BREAKING: Required field added"
          BREAKING_COUNT=$((BREAKING_COUNT + 1))
        elif [[ "$line" =~ ^[+-].*@(GetMapping|PostMapping) ]]; then
          log_success "  ✓ Endpoint added/modified"
        fi
      done
    }
  done <<< "$CHANGED_FILES"
fi

# ============================================================================
# LINK TO ADO ISSUES
# ============================================================================

log_section "LINKED ADO ISSUES"

cd "$REPO_PATH"
COMMIT_MESSAGE=$(git log -1 --pretty=%B "$REF" 2>/dev/null || echo "")

if [[ -z "$COMMIT_MESSAGE" ]]; then
  log_info "No commit message found"
else
  # Extract AB# references
  AB_REFS=$(echo "$COMMIT_MESSAGE" | grep -oE 'AB#[0-9]+' | sort -u || echo "")

  if [[ -n "$AB_REFS" ]]; then
    log_success "Found ADO references:"
    echo "$AB_REFS" | while read -r ref; do
      echo "  $ref"
    done
  else
    log_warn "No ADO references found in commit message"
    log_info "Recommendation: Include AB#XXXXX in commit messages for traceability"
  fi
fi

# ============================================================================
# RISK ASSESSMENT
# ============================================================================

log_section "RISK ASSESSMENT"

if [[ $BREAKING_COUNT -eq 0 ]]; then
  log_success "✓ No breaking changes detected"
  echo "Risk Level: LOW"
else
  log_error "✗ BREAKING CHANGES DETECTED: $BREAKING_COUNT"
  echo "Risk Level: HIGH"
  log_warn "Recommendation: Review breaking changes and update contracts"
fi

log_section "ANALYSIS COMPLETE"
log_info "Summary: $API_CHANGES API, $DATA_CHANGES DB, $EVENT_CHANGES Event, $LOGIC_CHANGES Logic changes"
log_info "Breaking Changes: $BREAKING_COUNT"
log_info "Timestamp: $TIMESTAMP"

exit 0
