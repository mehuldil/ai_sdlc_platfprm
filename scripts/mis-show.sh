#!/usr/bin/env bash
# Module Intelligence System (MIS) — Show Contracts
# Display contract information in readable format
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
CONTRACT_TYPE="${2:-summary}"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Not a git repository: $REPO_PATH"
  exit 1
fi

CONTRACT_DIR="$REPO_PATH/.sdlc/module-contracts"
if [[ ! -d "$CONTRACT_DIR" ]]; then
  log_error "No module contracts found. Run: sdlc mis init $REPO_PATH"
  exit 1
fi

MODULE_NAME=$(basename "$REPO_PATH")

# ============================================================================
# EXTRACT YAML VALUES (simple regex-based, no external tools)
# ============================================================================

get_yaml_value() {
  local file="$1"
  local key="$2"
  grep "^${key}:" "$file" 2>/dev/null | cut -d: -f2- | xargs || echo ""
}

get_yaml_list() {
  local file="$1"
  local key="$2"
  awk "/^${key}:$/,/^[a-z]/" "$file" 2>/dev/null | grep "^  - " | cut -c5- || echo ""
}

# ============================================================================
# SHOW SUMMARY
# ============================================================================

show_summary() {
  log_section "Module Contract Summary: $MODULE_NAME"

  echo "Contracts in: $CONTRACT_DIR"
  echo ""

  # Count items in each contract
  local api_endpoints=$(grep -c "^  - path:" "$CONTRACT_DIR/api-contract.yaml" 2>/dev/null || echo "0")
  local data_tables=$(grep "^  [a-z_]*:" "$CONTRACT_DIR/data-contract.yaml" 2>/dev/null | wc -l || echo "0")
  local events=$(grep -c "^  - name:" "$CONTRACT_DIR/event-contract.yaml" 2>/dev/null || echo "0")
  local deps=$(grep "^  - " "$CONTRACT_DIR/dependencies.yaml" 2>/dev/null | wc -l || echo "0")

  echo "API Contract:"
  echo "  Endpoints: $api_endpoints"
  echo "  Module: $(get_yaml_value "$CONTRACT_DIR/api-contract.yaml" "module")"
  echo "  Base path: $(get_yaml_value "$CONTRACT_DIR/api-contract.yaml" "base_path")"
  echo ""

  echo "Data Contract:"
  echo "  Database: $(get_yaml_value "$CONTRACT_DIR/data-contract.yaml" "database")"
  echo "  Tables: $data_tables"
  echo ""

  echo "Event Contract:"
  echo "  Broker: $(get_yaml_value "$CONTRACT_DIR/event-contract.yaml" "broker")"
  echo "  Namespace: $(get_yaml_value "$CONTRACT_DIR/event-contract.yaml" "namespace")"
  echo "  Events: $events"
  echo ""

  echo "Dependencies:"
  echo "  Total items: $deps"
  echo ""

  # Show recent analysis if available
  if [[ -f "$CONTRACT_DIR/last-change-analysis.json" ]]; then
    echo "Last Change Analysis:"
    local breaking=$(grep '"total_breaking"' "$CONTRACT_DIR/last-change-analysis.json" | cut -d':' -f2 | tr -d ' ,')
    local risk=$(grep '"risk_level"' "$CONTRACT_DIR/last-change-analysis.json" | cut -d'"' -f4)
    echo "  Breaking changes: $breaking"
    echo "  Risk level: $risk"
    echo ""
  fi

  # Show validation if available
  if [[ -f "$CONTRACT_DIR/validation-report.json" ]]; then
    echo "Last Validation:"
    local passed=$(grep '"passed"' "$CONTRACT_DIR/validation-report.json" | head -1 | cut -d':' -f2 | tr -d ' ,')
    local warnings=$(grep '"warnings"' "$CONTRACT_DIR/validation-report.json" | head -1 | cut -d':' -f2 | tr -d ' ,')
    local failed=$(grep '"failed"' "$CONTRACT_DIR/validation-report.json" | head -1 | cut -d':' -f2 | tr -d ' ,')
    echo "  Passed: $passed | Warnings: $warnings | Failed: $failed"
    echo ""
  fi
}

# ============================================================================
# SHOW API CONTRACT
# ============================================================================

show_api_contract() {
  log_section "API Contract: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/api-contract.yaml" ]]; then
    log_error "API contract not found"
    return 1
  fi

  local module=$(get_yaml_value "$CONTRACT_DIR/api-contract.yaml" "module")
  local base_path=$(get_yaml_value "$CONTRACT_DIR/api-contract.yaml" "base_path")
  local version=$(get_yaml_value "$CONTRACT_DIR/api-contract.yaml" "version")

  echo "Module: $module"
  echo "Version: $version"
  echo "Base Path: $base_path"
  echo ""

  echo "Endpoints:"
  awk '/^endpoints:/,/^[a-z]/ {print}' "$CONTRACT_DIR/api-contract.yaml" | head -50
  echo ""

  echo "Schemas:"
  awk '/^schemas:/,/^[a-z]/ {print}' "$CONTRACT_DIR/api-contract.yaml" | head -50
  echo ""

  if grep -q "deprecations:" "$CONTRACT_DIR/api-contract.yaml" 2>/dev/null; then
    echo "Deprecations:"
    awk '/^deprecations:/,/^[a-z]/ {print}' "$CONTRACT_DIR/api-contract.yaml"
    echo ""
  fi
}

# ============================================================================
# SHOW DATA CONTRACT
# ============================================================================

show_data_contract() {
  log_section "Data Contract: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/data-contract.yaml" ]]; then
    log_error "Data contract not found"
    return 1
  fi

  local database=$(get_yaml_value "$CONTRACT_DIR/data-contract.yaml" "database")
  local version=$(get_yaml_value "$CONTRACT_DIR/data-contract.yaml" "version")

  echo "Version: $version"
  echo "Database: $database"
  echo ""

  echo "Tables:"
  awk '/^tables:/,/^[a-z]/ {print}' "$CONTRACT_DIR/data-contract.yaml" | head -80
  echo ""

  if grep -q "migrations:" "$CONTRACT_DIR/data-contract.yaml" 2>/dev/null; then
    echo "Migrations:"
    awk '/^migrations:/,/^[a-z]/ {print}' "$CONTRACT_DIR/data-contract.yaml" | head -30
    echo ""
  fi

  if grep -q "readonly_columns:" "$CONTRACT_DIR/data-contract.yaml" 2>/dev/null; then
    echo "Column Immutability:"
    echo "Readonly:"
    awk '/^readonly_columns:/,/^[a-z]/ {print}' "$CONTRACT_DIR/data-contract.yaml"
    echo ""
  fi
}

# ============================================================================
# SHOW EVENT CONTRACT
# ============================================================================

show_event_contract() {
  log_section "Event Contract: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/event-contract.yaml" ]]; then
    log_error "Event contract not found"
    return 1
  fi

  local broker=$(get_yaml_value "$CONTRACT_DIR/event-contract.yaml" "broker")
  local namespace=$(get_yaml_value "$CONTRACT_DIR/event-contract.yaml" "namespace")
  local version=$(get_yaml_value "$CONTRACT_DIR/event-contract.yaml" "version")

  echo "Version: $version"
  echo "Broker: $broker"
  echo "Namespace: $namespace"
  echo ""

  echo "Events Produced:"
  awk '/^events_produced:/,/^events_consumed:/ {print}' "$CONTRACT_DIR/event-contract.yaml" | head -60
  echo ""

  echo "Events Consumed:"
  awk '/^events_consumed:/,/^[a-z]/ {print}' "$CONTRACT_DIR/event-contract.yaml" | head -30
  echo ""

  if grep -q "breaking_changes:" "$CONTRACT_DIR/event-contract.yaml" 2>/dev/null; then
    echo "Breaking Changes:"
    awk '/^breaking_changes:/,/^[a-z]/ {print}' "$CONTRACT_DIR/event-contract.yaml"
    echo ""
  fi
}

# ============================================================================
# SHOW DEPENDENCIES
# ============================================================================

show_dependencies() {
  log_section "Dependencies Contract: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/dependencies.yaml" ]]; then
    log_error "Dependencies contract not found"
    return 1
  fi

  local module=$(get_yaml_value "$CONTRACT_DIR/dependencies.yaml" "module")
  local version=$(get_yaml_value "$CONTRACT_DIR/dependencies.yaml" "version")

  echo "Module: $module"
  echo "Version: $version"
  echo ""

  if grep -q "external_services:" "$CONTRACT_DIR/dependencies.yaml" 2>/dev/null; then
    echo "External Services:"
    awk '/^external_services:/,/^internal_modules:/ {print}' "$CONTRACT_DIR/dependencies.yaml" | head -50
    echo ""
  fi

  if grep -q "internal_modules:" "$CONTRACT_DIR/dependencies.yaml" 2>/dev/null; then
    echo "Internal Modules:"
    awk '/^internal_modules:/,/^libraries:/ {print}' "$CONTRACT_DIR/dependencies.yaml" | head -30
    echo ""
  fi

  if grep -q "libraries:" "$CONTRACT_DIR/dependencies.yaml" 2>/dev/null; then
    echo "Libraries:"
    awk '/^libraries:/,/^[a-z]/ {print}' "$CONTRACT_DIR/dependencies.yaml" | head -50
    echo ""
  fi
}

# ============================================================================
# SHOW BREAKING CHANGES POLICY
# ============================================================================

show_breaking_changes() {
  log_section "Breaking Changes Policy: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/breaking-changes.md" ]]; then
    log_error "Breaking changes policy not found"
    return 1
  fi

  # Show key sections
  echo "Policy Overview:"
  sed -n '/## What is a Breaking Change?/,/## Approval Workflow/p' "$CONTRACT_DIR/breaking-changes.md" | head -30
  echo ""

  echo "Current Status:"
  sed -n '/## Current Breaking Changes/,/## Planned Breaking Changes/p' "$CONTRACT_DIR/breaking-changes.md" | head -10
  echo ""

  echo "See full policy in: $CONTRACT_DIR/breaking-changes.md"
}

# ============================================================================
# SHOW ANALYSIS RESULTS
# ============================================================================

show_analysis() {
  log_section "Last Change Analysis: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/last-change-analysis.json" ]]; then
    log_warn "No change analysis found"
    return 1
  fi

  # Pretty print JSON if jq is available
  if command -v jq &>/dev/null; then
    cat "$CONTRACT_DIR/last-change-analysis.json" | jq .
  else
    # Fallback to simple formatting
    cat "$CONTRACT_DIR/last-change-analysis.json" | sed 's/,/,\n  /g'
  fi
}

# ============================================================================
# SHOW VALIDATION RESULTS
# ============================================================================

show_validation() {
  log_section "Last Validation Report: $MODULE_NAME"

  if [[ ! -f "$CONTRACT_DIR/validation-report.json" ]]; then
    log_warn "No validation report found"
    return 1
  fi

  # Pretty print JSON if jq is available
  if command -v jq &>/dev/null; then
    cat "$CONTRACT_DIR/validation-report.json" | jq .
  else
    # Fallback to simple formatting
    cat "$CONTRACT_DIR/validation-report.json" | sed 's/,/,\n  /g'
  fi
}

# ============================================================================
# MAIN
# ============================================================================

case "$CONTRACT_TYPE" in
  api|API)
    show_api_contract
    ;;
  data|database|db|schema)
    show_data_contract
    ;;
  event|events|kafka)
    show_event_contract
    ;;
  deps|dependencies|services)
    show_dependencies
    ;;
  breaking|breaks)
    show_breaking_changes
    ;;
  analysis|analyze)
    show_analysis
    ;;
  validation|validate)
    show_validation
    ;;
  summary|all|*)
    show_summary
    ;;
esac

log_success "Done"
