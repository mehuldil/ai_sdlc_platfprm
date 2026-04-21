#!/usr/bin/env bash
# Module Intelligence System (MIS) — Pre-Merge Validation
# Comprehensive validation before allowing merge
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
VALIDATION_REPORT="$CONTRACT_DIR/validation-report.json"

# Track validation results
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

log_section "MIS Pre-Merge Validation: $MODULE_NAME"

# ============================================================================
# 1. CONTRACT SYNTAX VALIDATION
# ============================================================================

validate_contract_syntax() {
  log_section "1. CONTRACT SYNTAX VALIDATION"

  local contracts=()
  contracts+=("$CONTRACT_DIR/api-contract.yaml")
  contracts+=("$CONTRACT_DIR/data-contract.yaml")
  contracts+=("$CONTRACT_DIR/event-contract.yaml")
  contracts+=("$CONTRACT_DIR/dependencies.yaml")

  for contract in "${contracts[@]}"; do
    if [[ ! -f "$contract" ]]; then
      log_error "Missing contract: $contract"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    else
      # Basic YAML syntax check (check for mismatched quotes, colons)
      if grep -q "^[^#].*:.*:.*:" "$contract" 2>/dev/null; then
        log_warn "Potential YAML syntax issue in: $(basename "$contract")"
        WARN_COUNT=$((WARN_COUNT + 1))
      else
        log_success "$(basename "$contract"): Valid"
        PASS_COUNT=$((PASS_COUNT + 1))
      fi
    fi
  done
}

# ============================================================================
# 2. MODULE METADATA VALIDATION
# ============================================================================

validate_module_metadata() {
  log_section "2. MODULE METADATA VALIDATION"

  # Check api-contract.yaml has module name
  if grep -q "^module:" "$CONTRACT_DIR/api-contract.yaml" 2>/dev/null; then
    local module_name=$(grep "^module:" "$CONTRACT_DIR/api-contract.yaml" | cut -d: -f2 | xargs)
    if [[ "$module_name" != "MODULE_NAME_HERE" ]]; then
      log_success "API contract module name defined: $module_name"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      log_warn "API contract module name not customized (still default)"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  fi

  # Check data-contract.yaml has database type
  if grep -q "^database:" "$CONTRACT_DIR/data-contract.yaml" 2>/dev/null; then
    log_success "Data contract database type defined"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi

  # Check event-contract.yaml has broker type
  if grep -q "^broker:" "$CONTRACT_DIR/event-contract.yaml" 2>/dev/null; then
    log_success "Event contract broker type defined"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
}

# ============================================================================
# 3. CONTENT VALIDATION
# ============================================================================

validate_contract_content() {
  log_section "3. CONTRACT CONTENT VALIDATION"

  # API contract endpoints
  local api_endpoint_count=$(grep -c "^  - path:" "$CONTRACT_DIR/api-contract.yaml" 2>/dev/null || echo "0")
  if [[ $api_endpoint_count -gt 0 ]]; then
    log_success "API contract has $api_endpoint_count endpoints defined"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "API contract has no endpoints defined yet"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # Data contract tables
  local table_count=$(grep -c "^  [a-z_]*:" "$CONTRACT_DIR/data-contract.yaml" 2>/dev/null | head -1 || echo "0")
  if [[ $table_count -gt 0 ]]; then
    log_success "Data contract has tables defined"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "Data contract has no tables defined yet"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # Event contract
  local event_produced=$(grep -c "^  - name:" "$CONTRACT_DIR/event-contract.yaml" 2>/dev/null || echo "0")
  if [[ $event_produced -gt 0 ]]; then
    log_success "Event contract has events defined"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "Event contract has no events defined yet"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # Dependencies
  local deps_count=$(grep -c "^  - " "$CONTRACT_DIR/dependencies.yaml" 2>/dev/null || echo "0")
  if [[ $deps_count -gt 0 ]]; then
    log_success "Dependencies contract has $deps_count dependencies listed"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "Dependencies contract has no dependencies listed yet"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ============================================================================
# 4. BREAKING CHANGES DOCUMENTATION
# ============================================================================

validate_breaking_changes() {
  log_section "4. BREAKING CHANGES DOCUMENTATION"

  if [[ ! -f "$CONTRACT_DIR/breaking-changes.md" ]]; then
    log_error "Missing breaking-changes.md"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    # Check if policy is documented
    if grep -q "## What is a Breaking Change?" "$CONTRACT_DIR/breaking-changes.md" 2>/dev/null; then
      log_success "Breaking change policy documented"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      log_warn "Breaking change policy not fully documented"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi

    # Check if approval workflow is documented
    if grep -q "## Approval Workflow" "$CONTRACT_DIR/breaking-changes.md" 2>/dev/null; then
      log_success "Approval workflow documented"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      log_warn "Approval workflow not documented"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi

    # Check if migration guides are referenced
    if grep -q "migration\|Migration\|MIGRATION" "$CONTRACT_DIR/breaking-changes.md" 2>/dev/null; then
      log_success "Migration guidance referenced"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      log_warn "No migration guidance found"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  fi
}

# ============================================================================
# 5. GIT REPOSITORY STATE
# ============================================================================

validate_git_state() {
  log_section "5. GIT REPOSITORY STATE"

  cd "$REPO_PATH"

  # Check for uncommitted changes
  if git diff-index --quiet HEAD -- 2>/dev/null; then
    log_success "Working directory clean (all changes committed)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "Uncommitted changes detected — stage before merge"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # Check branch name follows convention
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ "$current_branch" =~ ^feature/|^bugfix/|^hotfix/|^release/ ]]; then
    log_success "Branch naming convention followed: $current_branch"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "Branch name doesn't follow convention: $current_branch"
    log_warn "  Expected: feature/*, bugfix/*, hotfix/*, release/*"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  # Check for commits
  local commit_count=$(git log main.."$current_branch" --oneline 2>/dev/null | wc -l)
  if [[ $commit_count -gt 0 ]]; then
    log_success "Branch has $commit_count commits"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "No commits on this branch"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ============================================================================
# 6. CHANGE ANALYSIS
# ============================================================================

validate_change_analysis() {
  log_section "6. CHANGE ANALYSIS RESULTS"

  if [[ -f "$CONTRACT_DIR/last-change-analysis.json" ]]; then
    # Extract risk level from analysis
    local risk_level=$(grep '"risk_level"' "$CONTRACT_DIR/last-change-analysis.json" | cut -d'"' -f4)
    local breaking=$(grep '"total_breaking"' "$CONTRACT_DIR/last-change-analysis.json" | cut -d':' -f2 | tr -d ' ,')

    echo "Last Analysis Results:"
    echo "  Breaking changes: $breaking"
    echo "  Risk level: $risk_level"

    if [[ "$risk_level" == "LOW" || "$risk_level" == "MEDIUM" ]]; then
      log_success "Risk level acceptable for merge"
      PASS_COUNT=$((PASS_COUNT + 1))
    elif [[ "$breaking" -gt 0 ]]; then
      log_warn "Breaking changes detected — ensure approval obtained"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi

    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "No change analysis found — run: sdlc mis analyze-change"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ============================================================================
# 7. ADO ISSUE LINKAGE
# ============================================================================

validate_ado_linkage() {
  log_section "7. ADO ISSUE LINKAGE"

  cd "$REPO_PATH"

  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  local main_branch=$(git rev-parse --abbrev-ref main 2>/dev/null || echo "main")

  # Find ADO issues in commits on this branch
  local ado_issues=$(git log "$main_branch".."$current_branch" --oneline 2>/dev/null | grep -oE "AB#[0-9]+" | sort -u || echo "")

  if [[ -n "$ado_issues" ]]; then
    log_success "ADO issues linked in commits:"
    echo "$ado_issues" | while read -r issue; do
      echo "    - $issue"
    done
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "No ADO issues linked (add AB#XXXXX to commit messages)"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ============================================================================
# 8. TEST COVERAGE
# ============================================================================

validate_test_coverage() {
  log_section "8. TEST COVERAGE CHECK"

  cd "$REPO_PATH"

  # Check for test files
  local test_count=0
  [[ -d "src/test" ]] && test_count=$(find src/test -name "*.java" 2>/dev/null | wc -l || echo "0")
  [[ -d "test" ]] && test_count=$(find test -name "*.test.js" -o -name "*.spec.ts" 2>/dev/null | wc -l || echo "0")

  if [[ $test_count -gt 0 ]]; then
    log_success "Test files found: $test_count"
    PASS_COUNT=$((PASS_COUNT + 1))

    # Check for test configuration
    local has_test_config=0
    [[ -f "pom.xml" ]] && grep -q "<surefire>\|<maven-failsafe>" pom.xml 2>/dev/null && has_test_config=1
    [[ -f "jest.config.js" || -f "vitest.config.ts" ]] && has_test_config=1

    if [[ $has_test_config -eq 1 ]]; then
      log_success "Test configuration found"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      log_warn "Test configuration not detected"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  else
    log_warn "No test files found"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ============================================================================
# 9. DOCUMENTATION CHECK
# ============================================================================

validate_documentation() {
  log_section "9. DOCUMENTATION CHECK"

  cd "$REPO_PATH"

  local doc_files=()
  [[ -f "README.md" ]] && doc_files+=("README.md")
  [[ -f "docs/API.md" ]] && doc_files+=("docs/API.md")
  [[ -f "docs/ARCHITECTURE.md" ]] && doc_files+=("docs/ARCHITECTURE.md")
  [[ -f "CONTRIBUTING.md" ]] && doc_files+=("CONTRIBUTING.md")

  if [[ ${#doc_files[@]} -gt 0 ]]; then
    log_success "Documentation found:"
    for doc in "${doc_files[@]}"; do
      echo "    - $doc"
    done
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    log_warn "Minimal documentation found"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
}

# ============================================================================
# 10. MIGRATION ROLLBACK TEST
# ============================================================================

validate_migration_rollback() {
  log_section "10. MIGRATION ROLLBACK CAPABILITY"

  cd "$REPO_PATH"

  # Find new migrations
  local new_migrations=$(git log main..HEAD --name-only --pretty=format: 2>/dev/null | grep -E "\.sql|migration" | wc -l || echo "0")

  if [[ $new_migrations -gt 0 ]]; then
    log_warn "New database migrations detected: $new_migrations"
    echo "  Critical: Test rollback before merging"
    echo "  Command: ./mvnw liquibase:rollback -Dliquibase.rollback.count=1"
    WARN_COUNT=$((WARN_COUNT + 1))
  else
    log_success "No database migrations to test"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
}

# ============================================================================
# GENERATE VALIDATION REPORT
# ============================================================================

generate_validation_report() {
  log_section "VALIDATION SUMMARY"

  local total=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))

  echo "Results:"
  echo "  ✓ Passed: $PASS_COUNT"
  echo "  ⚠ Warnings: $WARN_COUNT"
  echo "  ✗ Failed: $FAIL_COUNT"
  echo ""

  if [[ $FAIL_COUNT -eq 0 ]]; then
    if [[ $WARN_COUNT -eq 0 ]]; then
      log_success "ALL VALIDATIONS PASSED - Ready to merge"
      local merge_safe="true"
    else
      log_warn "VALIDATION PASSED WITH WARNINGS - Review before merge"
      local merge_safe="true"
    fi
  else
    log_error "VALIDATION FAILED - Fix issues before merge"
    local merge_safe="false"
  fi

  # Generate JSON report
  cat > "$VALIDATION_REPORT" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "module": "$MODULE_NAME",
  "results": {
    "passed": $PASS_COUNT,
    "warnings": $WARN_COUNT,
    "failed": $FAIL_COUNT,
    "total": $total
  },
  "safe_to_merge": $merge_safe,
  "checks": {
    "contract_syntax": "completed",
    "module_metadata": "completed",
    "contract_content": "completed",
    "breaking_changes": "completed",
    "git_state": "completed",
    "change_analysis": "completed",
    "ado_linkage": "completed",
    "test_coverage": "completed",
    "documentation": "completed",
    "migration_rollback": "completed"
  }
}
EOF

  log_success "Validation report saved to: $VALIDATION_REPORT"
  echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

validate_contract_syntax
validate_module_metadata
validate_contract_content
validate_breaking_changes
validate_git_state
validate_change_analysis
validate_ado_linkage
validate_test_coverage
validate_documentation
validate_migration_rollback

generate_validation_report

# Exit with appropriate code
if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
elif [[ $WARN_COUNT -gt 0 ]]; then
  exit 0  # Warnings are non-blocking
else
  exit 0  # All passed
fi
