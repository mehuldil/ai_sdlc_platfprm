#!/usr/bin/env bash
################################################################################
# AI-SDLC Platform Doctor — Comprehensive System Health Check
# Orchestrates all validation scripts for platform consistency
#
# This is a standalone health check that can run independently
# Call from cli/sdlc.sh doctor command
#
# Exit codes: 0 = all green, 1 = warnings/failures found
################################################################################

PLATFORM_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}⚠${NC}  $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_info() {
  echo -e "${BLUE}→${NC} $1"
}

log_section() {
  echo ""
  echo -e "${BLUE}=== $1 ===${NC}"
  echo ""
}

# Initialize counters
PASS=0
WARN=0
FAIL=0

# ============================================================================
# ENVIRONMENT CHECK
# ============================================================================

log_section "1. Environment & Dependencies"

# Check bash version
log_info "Bash: ${BASH_VERSION}"

# Check required tools
tools=(curl jq git node npm npx)
for tool in "${tools[@]}"; do
  if command -v "$tool" &>/dev/null; then
    log_success "$tool installed"
    PASS=$((PASS + 1))
  else
    log_warn "$tool: not found (some features may be limited)"
    WARN=$((WARN + 1))
  fi
done

# Python 3 (semantic memory CLI)
py_cmd=""
py_arg=""
for candidate in python3 python; do
  if command -v "$candidate" &>/dev/null && "$candidate" -V >/dev/null 2>&1; then
    py_cmd="$candidate"
    break
  fi
done
if [[ -z "$py_cmd" ]] && command -v py &>/dev/null && py -3 -V >/dev/null 2>&1; then
  py_cmd="py"
  py_arg="-3"
fi
if [[ -n "$py_cmd" ]]; then
  if [[ -n "$py_arg" ]]; then
    log_success "Python: $($py_cmd $py_arg -V 2>&1)"
  else
    log_success "Python: $($py_cmd -V 2>&1)"
  fi
  PASS=$((PASS + 1))
else
  log_warn "Python 3 not found (optional: semantic memory)"
  WARN=$((WARN + 1))
fi

if command -v docker &>/dev/null; then
  log_success "docker (optional QA stack)"
  PASS=$((PASS + 1))
else
  log_info "docker: not installed (optional — QA orchestrator stack)"
fi

# Check platform directory
if [[ -d "$PLATFORM_DIR" ]]; then
  log_success "Platform dir: $PLATFORM_DIR"
  PASS=$((PASS + 1))
else
  log_error "Platform dir not found: $PLATFORM_DIR"
  FAIL=$((FAIL + 1))
fi

# ============================================================================
# RULE VALIDATION
# ============================================================================

log_section "2. Rule Validation (validate-rules.sh)"

if [[ -f "${SCRIPT_DIR}/validate-rules.sh" ]]; then
  if bash "${SCRIPT_DIR}/validate-rules.sh" "$PLATFORM_DIR" >/dev/null 2>&1; then
    log_success "Rule bypass detection PASSED"
    PASS=$((PASS + 1))
  else
    log_warn "Rule validation found issues"
    WARN=$((WARN + 1))
  fi
else
  log_warn "validate-rules.sh not found"
  WARN=$((WARN + 1))
fi

# ============================================================================
# COMMAND CONSISTENCY
# ============================================================================

log_section "3. Command Consistency (validate-commands.sh)"

if [[ -f "${SCRIPT_DIR}/validate-commands.sh" ]]; then
  if bash "${SCRIPT_DIR}/validate-commands.sh" "$PLATFORM_DIR" >/dev/null 2>&1; then
    log_success "Command consistency check PASSED"
    PASS=$((PASS + 1))
  else
    log_warn "Command consistency check found issues"
    WARN=$((WARN + 1))
  fi
else
  log_warn "validate-commands.sh not found"
  WARN=$((WARN + 1))
fi

# ============================================================================
# DOCUMENTATION DRIFT
# ============================================================================

log_section "4. Documentation (drift + generated registries)"

if [[ -f "${SCRIPT_DIR}/detect-doc-drift.sh" ]]; then
  if bash "${SCRIPT_DIR}/detect-doc-drift.sh" "$PLATFORM_DIR" >/dev/null 2>&1; then
    log_success "Documentation drift check PASSED"
    PASS=$((PASS + 1))
  else
    log_warn "Documentation drift detected"
    WARN=$((WARN + 1))
  fi
else
  log_warn "detect-doc-drift.sh not found"
  WARN=$((WARN + 1))
fi

if [[ -f "${PLATFORM_DIR}/scripts/regenerate-registries.sh" ]]; then
  if (cd "$PLATFORM_DIR" && bash scripts/regenerate-registries.sh --check) >/dev/null 2>&1; then
    log_success "Generated registries current"
    PASS=$((PASS + 1))
  else
    log_warn "Registries need regeneration (bash scripts/regenerate-registries.sh --update)"
    WARN=$((WARN + 1))
  fi
else
  log_warn "regenerate-registries.sh not found"
  WARN=$((WARN + 1))
fi

# ============================================================================
# MEMORY FRESHNESS
# ============================================================================

log_section "5. Memory Freshness (memory-freshness.sh)"

if [[ -f "${SCRIPT_DIR}/memory-freshness.sh" ]]; then
  if bash "${SCRIPT_DIR}/memory-freshness.sh" --check >/dev/null 2>&1; then
    log_success "Memory freshness check PASSED"
    PASS=$((PASS + 1))
  else
    log_warn "Memory freshness check found stale files"
    WARN=$((WARN + 1))
  fi
else
  log_warn "memory-freshness.sh not found (optional)"
  # Don't count as failure
fi

# ============================================================================
# SYMLINK VALIDATION
# ============================================================================

log_section "6. Symlink Integrity"

broken_symlinks=0
while IFS= read -r symlink; do
  if [[ ! -L "$symlink" ]]; then
    continue
  fi
  target=$(readlink "$symlink")
  if [[ ! -e "$symlink" ]]; then
    broken_symlinks=$((broken_symlinks + 1))
    log_warn "Broken symlink: $symlink → $target"
  fi
done < <(find "$PLATFORM_DIR" -type l 2>/dev/null || true)

if [[ $broken_symlinks -eq 0 ]]; then
  log_success "No broken symlinks"
  PASS=$((PASS + 1))
else
  log_error "Found $broken_symlinks broken symlinks"
  FAIL=$((FAIL + 1))
fi

# ============================================================================
# PLATFORM STRUCTURE
# ============================================================================

log_section "7. Platform Structure"

critical_dirs=(".claude" "scripts" "cli" "stages" "agents")
for dir in "${critical_dirs[@]}"; do
  if [[ -d "$PLATFORM_DIR/$dir" ]]; then
    log_success "Directory: $dir"
    PASS=$((PASS + 1))
  else
    log_warn "Directory missing: $dir"
    WARN=$((WARN + 1))
  fi
done

# ============================================================================
# CONFIGURATION FILES
# ============================================================================

log_section "8. Configuration Files"

config_files=(README.md COMMANDS.md ROLES.md QUICKSTART.md)
for file in "${config_files[@]}"; do
  if [[ -f "$PLATFORM_DIR/$file" ]]; then
    log_success "$file present"
    PASS=$((PASS + 1))
  else
    log_warn "$file missing"
    WARN=$((WARN + 1))
  fi
done

# ============================================================================
# FINAL REPORT
# ============================================================================

echo ""
log_section "Health Report Summary"

total=$((PASS + WARN + FAIL))
health_percent=$((PASS * 100 / total))

echo "PASS:  $PASS ✓"
echo "WARN:  $WARN ⚠"
echo "FAIL:  $FAIL ✗"
echo ""
echo "Health: $health_percent%"
echo ""

if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
  log_success "System Health: EXCELLENT"
  echo ""
  echo "Your SDLC platform is in great shape!"
  exit 0
elif [[ $FAIL -eq 0 ]]; then
  log_warn "System Health: GOOD"
  echo ""
  echo "Minor warnings detected. Review above for details."
  exit 0
else
  log_error "System Health: NEEDS ATTENTION"
  echo ""
  echo "Critical issues found. Review above for details."
  echo ""
  echo "Run individual validators with details:"
  echo "  bash scripts/validate-rules.sh . --verbose"
  echo "  bash scripts/validate-commands.sh . --verbose"
  echo "  bash scripts/detect-doc-drift.sh . --verbose"
  exit 1
fi
