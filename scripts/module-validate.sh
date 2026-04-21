#!/usr/bin/env bash
################################################################################
# Unified Module System — Contract Validation
# Pre-merge: checks code against contracts, flags breaking changes
# Advisory-only: warns but never blocks
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
MODULE_DIR="$REPO_PATH/.sdlc/module"

if [[ ! -d "$MODULE_DIR/contracts" ]]; then
  log_warn "Module system not initialized (skipping validation)"
  log_info "Run: sdlc module init"
  exit 0
fi

STACK=$(grep -o '"stack": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
WARNINGS=0
ERRORS=0

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}MODULE SYSTEM — CONTRACT VALIDATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

################################################################################
# GET CHANGED FILES
################################################################################

CHANGED_FILES=$(cd "$REPO_PATH" && git diff --cached --name-only 2>/dev/null || git diff --name-only 2>/dev/null || echo "")

if [[ -z "$CHANGED_FILES" ]]; then
  log_info "No changed files detected"
  exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
log_info "Validating $FILE_COUNT changed file(s)..."
echo ""

################################################################################
# CHECK 1: API Breaking Changes
################################################################################

check_api_breaking() {
  log_info "[1/5] Checking API breaking changes..."

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local full_path="$REPO_PATH/$file"
    [[ ! -f "$full_path" ]] && continue

    # Removed endpoints (Java/Kotlin)
    if [[ "$file" == *.java || "$file" == *.kt ]]; then
      local removed
      removed=$(cd "$REPO_PATH" && git diff --cached -p "$file" 2>/dev/null | grep -E "^-\s*@(RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|GET|POST|PUT|DELETE)" || true)
      if [[ -n "$removed" ]]; then
        log_warn "BREAKING: Removed API endpoint in $file"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi

    # Removed routes (Node)
    if [[ "$file" == *.js || "$file" == *.ts ]]; then
      local removed
      removed=$(cd "$REPO_PATH" && git diff --cached -p "$file" 2>/dev/null | grep -E "^-\s*(router|app)\.(get|post|put|delete)" || true)
      if [[ -n "$removed" ]]; then
        log_warn "BREAKING: Removed route in $file"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi
  done <<< "$CHANGED_FILES"

  [[ $WARNINGS -eq 0 ]] && log_success "No API breaking changes"
}

################################################################################
# CHECK 2: Data Schema Breaking Changes
################################################################################

check_data_breaking() {
  log_info "[2/5] Checking data schema changes..."

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # SQL drops
    if [[ "$file" == *.sql ]]; then
      local drops
      drops=$(cd "$REPO_PATH" && git diff --cached -p "$file" 2>/dev/null | grep -iE "DROP (COLUMN|TABLE|INDEX)" || true)
      if [[ -n "$drops" ]]; then
        log_warn "BREAKING: Schema drop detected in $file"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi

    # Room migration (Kotlin)
    if [[ "$file" == *Migration*.kt || "$file" == *migration*.kt ]]; then
      log_warn "Room migration changed: $file (verify backward compatibility)"
      WARNINGS=$((WARNINGS + 1))
    fi

    # CoreData model (Swift)
    if [[ "$file" == *.xcdatamodeld* ]]; then
      log_warn "CoreData model changed: $file (verify migration)"
      WARNINGS=$((WARNINGS + 1))
    fi
  done <<< "$CHANGED_FILES"

  local prev_warns=$WARNINGS
  [[ $WARNINGS -eq $prev_warns ]] && log_success "No data breaking changes"
}

################################################################################
# CHECK 3: Event Contract Changes
################################################################################

check_event_breaking() {
  log_info "[3/5] Checking event contract changes..."
  local prev_warns=$WARNINGS

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local full_path="$REPO_PATH/$file"
    [[ ! -f "$full_path" ]] && continue

    # Removed Kafka topics/listeners
    local removed_events
    removed_events=$(cd "$REPO_PATH" && git diff --cached -p "$file" 2>/dev/null | grep -E "^-.*(@KafkaListener|KafkaTemplate|ProducerRecord|EventBus|NotificationCenter|PassthroughSubject)" || true)
    if [[ -n "$removed_events" ]]; then
      log_warn "Event producer/consumer removed in $file"
      WARNINGS=$((WARNINGS + 1))
    fi
  done <<< "$CHANGED_FILES"

  [[ $WARNINGS -eq $prev_warns ]] && log_success "No event breaking changes"
}

################################################################################
# CHECK 4: Cross-Pod Dependency Changes
################################################################################

check_cross_pod() {
  log_info "[4/5] Checking cross-pod dependencies..."
  local prev_warns=$WARNINGS

  # Check if dependencies.yaml changed
  if echo "$CHANGED_FILES" | grep -q "dependencies.yaml"; then
    log_warn "Dependencies contract changed — verify with consuming pods"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check if public interfaces changed
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    # Public interface files (varies by stack)
    case "$file" in
      *Interface.java|*Interface.kt|*Protocol.swift|*index.js|*index.ts)
        local removed_methods
        removed_methods=$(cd "$REPO_PATH" && git diff --cached -p "$file" 2>/dev/null | grep -E "^-\s*(public|func|export)" || true)
        if [[ -n "$removed_methods" ]]; then
          log_warn "Public interface changed in $file — check consumers"
          WARNINGS=$((WARNINGS + 1))
        fi
        ;;
    esac
  done <<< "$CHANGED_FILES"

  [[ $WARNINGS -eq $prev_warns ]] && log_success "No cross-pod breaking changes"
}

################################################################################
# CHECK 5: Contract Freshness
################################################################################

check_contract_freshness() {
  log_info "[5/5] Checking contract freshness..."

  local meta_commit=$(grep -o '"commit": "[^"]*"' "$MODULE_DIR/meta.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
  local current_commit=$(cd "$REPO_PATH" && git rev-parse HEAD 2>/dev/null | cut -c1-8)

  if [[ "${meta_commit:0:8}" != "$current_commit" ]]; then
    log_warn "Contracts may be stale (last scan: ${meta_commit:0:8}, current: $current_commit)"
    log_info "Run: sdlc module update"
    WARNINGS=$((WARNINGS + 1))
  else
    log_success "Contracts are up to date"
  fi
}

################################################################################
# SUMMARY
################################################################################

check_api_breaking
check_data_breaking
check_event_breaking
check_cross_pod
check_contract_freshness

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
if [[ $WARNINGS -gt 0 ]]; then
  echo -e "${YELLOW}RESULT: $WARNINGS warning(s) detected${NC}"
  echo -e "${YELLOW}These are advisory — you decide whether to proceed.${NC}"
  echo -e "${YELLOW}Override: git commit --no-verify${NC}"
else
  echo -e "${GREEN}RESULT: All validations passed — no breaking changes${NC}"
fi
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
