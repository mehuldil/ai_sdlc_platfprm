#!/usr/bin/env bash
################################################################################
# Documentation Drift Detection (R3)
# Validates User_Manual/ docs, root README/ROLES/COMMANDS/QUICKSTART, and
# User_Manual/Commands.md against actual platform state.
#
# Exit codes: 0 = clean, 1 = drift found
################################################################################

set -eo pipefail

PLATFORM_DIR="${1:-.}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() { echo -e "${RED}✗${NC} $1" >&2; }
log_warn()  { echo -e "${YELLOW}⚠${NC}  $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_info()  { echo -e "${BLUE}→${NC} $1"; }
log_section() { echo ""; echo -e "${BLUE}=== $1 ===${NC}"; echo ""; }

DRIFT_ISSUES=0

# ============================================================================
# 1. ROLES — root ROLES.md or User_Manual references
# ============================================================================

log_section "Roles Drift Check"

ROLES_FILE="${PLATFORM_DIR}/ROLES.md"
[[ ! -f "$ROLES_FILE" ]] && ROLES_FILE="${PLATFORM_DIR}/User_Manual/Agents_Skills_Rules.md"

if [[ ! -f "$ROLES_FILE" ]]; then
  log_warn "Neither ROLES.md nor User_Manual/Agents_Skills_Rules.md found; skipping role drift"
else
  REFERENCED_ROLE_FILES=$(grep -oE 'roles/[a-z0-9_-]+\.md' "$ROLES_FILE" 2>/dev/null | sort -u || true)
  if [[ -n "$REFERENCED_ROLE_FILES" ]]; then
    while IFS= read -r role_file; do
      if [[ ! -f "${PLATFORM_DIR}/${role_file}" ]]; then
        log_warn "$ROLES_FILE references missing: $role_file"
        DRIFT_ISSUES=$((DRIFT_ISSUES + 1))
      fi
    done <<< "$REFERENCED_ROLE_FILES"
  fi
  log_success "Role drift check complete"
fi

# ============================================================================
# 2. User_Manual/Commands.md vs cli/sdlc.sh handlers (R7)
# ============================================================================

log_section "User_Manual/Commands.md Drift Check"

UM_COMMANDS="${PLATFORM_DIR}/User_Manual/Commands.md"
CLI_FILE="${PLATFORM_DIR}/cli/sdlc.sh"

if [[ ! -f "$UM_COMMANDS" ]]; then
  log_warn "User_Manual/Commands.md not found; skipping"
elif [[ ! -f "$CLI_FILE" ]]; then
  log_warn "cli/sdlc.sh not found; skipping"
else
  DOCUMENTED_CMDS=$(grep -oE 'sdlc [a-z][a-z-]*' "$UM_COMMANDS" 2>/dev/null | awk '{print $2}' | sort -u || true)
  MISSING_HANDLERS=0

  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    func_name="cmd_${cmd//-/_}"
    found=0
    grep -qE "^${func_name}\(\)|${func_name} " "$CLI_FILE" 2>/dev/null && found=1
    [[ $found -eq 0 ]] && grep -qE "\"?${cmd}\"?\)" "$CLI_FILE" 2>/dev/null && found=1
    if [[ $found -eq 0 && -d "${PLATFORM_DIR}/cli/lib" ]]; then
      grep -rqE "^${func_name}\(\)" "${PLATFORM_DIR}/cli/lib" 2>/dev/null && found=1
    fi
    if [[ $found -eq 0 ]]; then
      log_warn "User_Manual/Commands.md documents 'sdlc $cmd' but no handler found"
      MISSING_HANDLERS=$((MISSING_HANDLERS + 1))
      DRIFT_ISSUES=$((DRIFT_ISSUES + 1))
    fi
  done <<< "$DOCUMENTED_CMDS"

  if [[ $MISSING_HANDLERS -eq 0 && -n "$DOCUMENTED_CMDS" ]]; then
    log_success "All User_Manual/Commands.md entries have handlers"
  fi
fi

# Also check root COMMANDS.md if it exists
if [[ -f "${PLATFORM_DIR}/COMMANDS.md" ]]; then
  log_info "Root COMMANDS.md also found — checking..."
  ROOT_CMDS=$(grep -oE 'sdlc [a-z][a-z-]*' "${PLATFORM_DIR}/COMMANDS.md" 2>/dev/null | awk '{print $2}' | sort -u || true)
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    func_name="cmd_${cmd//-/_}"
    found=0
    grep -qE "^${func_name}\(\)|\"?${cmd}\"?\)" "$CLI_FILE" 2>/dev/null && found=1
    if [[ $found -eq 0 && -d "${PLATFORM_DIR}/cli/lib" ]]; then
      grep -rqE "^${func_name}\(\)" "${PLATFORM_DIR}/cli/lib" 2>/dev/null && found=1
    fi
    if [[ $found -eq 0 ]]; then
      log_warn "Root COMMANDS.md documents 'sdlc $cmd' but no handler found"
      DRIFT_ISSUES=$((DRIFT_ISSUES + 1))
    fi
  done <<< "$ROOT_CMDS"
fi

# ============================================================================
# 3. Stage references in QUICKSTART / User_Manual/SDLC_Flows
# ============================================================================

log_section "Stage Reference Drift Check"

for check_file in "${PLATFORM_DIR}/QUICKSTART.md" "${PLATFORM_DIR}/User_Manual/SDLC_Flows.md"; do
  [[ ! -f "$check_file" ]] && continue
  fname="$(basename "$check_file")"
  REFERENCED_STAGES=$(grep -oE '[0-9]{2}-[a-z-]+' "$check_file" 2>/dev/null | sort -u || true)
  if [[ -n "$REFERENCED_STAGES" ]]; then
    MISSING_STAGES=0
    while IFS= read -r stage; do
      if [[ ! -d "${PLATFORM_DIR}/stages/${stage}" ]]; then
        log_warn "$fname references missing stage dir: stages/$stage"
        MISSING_STAGES=$((MISSING_STAGES + 1))
        DRIFT_ISSUES=$((DRIFT_ISSUES + 1))
      fi
    done <<< "$REFERENCED_STAGES"
    if [[ $MISSING_STAGES -eq 0 ]]; then
      log_success "$fname — all referenced stages exist"
    fi
  fi
done

# ============================================================================
# 4. README.md feature claims
# ============================================================================

log_section "README.md Feature Claims Check"

README_FILE="${PLATFORM_DIR}/README.md"

if [[ ! -f "$README_FILE" ]]; then
  log_warn "README.md not found; skipping"
else
  if grep -qi "15-stage workflow" "$README_FILE"; then
    stage_count=$(find "$PLATFORM_DIR/stages" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]*' 2>/dev/null | wc -l)
    if [[ $stage_count -lt 15 ]]; then
      log_warn "README claims 15-stage workflow but only $stage_count stages found"
      DRIFT_ISSUES=$((DRIFT_ISSUES + 1))
    else
      log_success "15-stage workflow verified ($stage_count stages)"
    fi
  fi
fi

# ============================================================================
# 5. User_Manual/README.md — verify all linked docs exist
# ============================================================================

log_section "User Manual Links Check"

UM_INDEX="${PLATFORM_DIR}/User_Manual/README.md"

if [[ -f "$UM_INDEX" ]]; then
  LINKED_DOCS=$(grep -oE '\([A-Za-z_]+\.md\)' "$UM_INDEX" 2>/dev/null | tr -d '()' | sort -u || true)
  if [[ -n "$LINKED_DOCS" ]]; then
    MISSING_DOCS=0
    while IFS= read -r doc; do
      if [[ ! -f "${PLATFORM_DIR}/User_Manual/${doc}" ]]; then
        log_warn "User_Manual/README.md links to ${doc} but file not found"
        MISSING_DOCS=$((MISSING_DOCS + 1))
        DRIFT_ISSUES=$((DRIFT_ISSUES + 1))
      fi
    done <<< "$LINKED_DOCS"
    if [[ $MISSING_DOCS -eq 0 ]]; then
      log_success "All User_Manual/README.md links resolve"
    fi
  fi
else
  log_warn "User_Manual/README.md not found"
fi

# ============================================================================
# Summary
# ============================================================================

log_section "Documentation Drift Summary"

if [[ $DRIFT_ISSUES -eq 0 ]]; then
  log_success "No documentation drift detected ✓"
  echo "All documentation is in sync with platform state."
  exit 0
else
  log_warn "Found $DRIFT_ISSUES documentation drift issues"
  echo ""
  echo "Review: User_Manual/Commands.md, User_Manual/SDLC_Flows.md, README.md"
  exit 1
fi
