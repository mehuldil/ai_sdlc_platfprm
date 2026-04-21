#!/usr/bin/env bash
# ============================================================================
# CI Gate — Shell validation pipeline
# Run: bash cli/tests/ci-gate.sh
# Checks: bash -n (syntax), shellcheck (lint), smoke tests
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
WARN=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}━━━ AI SDLC CLI — CI Gate ━━━${NC}"
echo ""

# ============================================================================
# Phase 1: Syntax validation (bash -n)
# ============================================================================

echo -e "${CYAN}Phase 1: Syntax Check (bash -n)${NC}"
echo ""

SHELL_FILES=(
  "${SCRIPT_DIR}/sdlc.sh"
  "${SCRIPT_DIR}/lib/logging.sh"
  "${SCRIPT_DIR}/lib/config.sh"
  "${SCRIPT_DIR}/lib/guards.sh"
  "${SCRIPT_DIR}/lib/executor.sh"
  "${SCRIPT_DIR}/lib/ado.sh"
  "${SCRIPT_DIR}/sdlc-state.sh"
)

for file in "${SHELL_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo -e "  ${YELLOW}SKIP${NC}  $(basename "$file") (not found)"
    WARN=$((WARN + 1))
    continue
  fi
  if bash -n "$file" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  $(basename "$file")"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${NC}  $(basename "$file")"
    bash -n "$file" 2>&1 | head -5 | sed 's/^/         /'
    FAIL=$((FAIL + 1))
  fi
done

# ============================================================================
# Phase 2: ShellCheck (if available)
# ============================================================================

echo ""
echo -e "${CYAN}Phase 2: ShellCheck Lint${NC}"
echo ""

if command -v shellcheck &>/dev/null; then
  for file in "${SHELL_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then continue; fi
    # SC1090=can't follow source, SC1091=not specified, SC2034=unused var (exports)
    if shellcheck -e SC1090,SC1091,SC2034,SC2155 -S warning "$file" 2>/dev/null; then
      echo -e "  ${GREEN}PASS${NC}  $(basename "$file")"
      PASS=$((PASS + 1))
    else
      echo -e "  ${YELLOW}WARN${NC}  $(basename "$file") (has warnings)"
      shellcheck -e SC1090,SC1091,SC2034,SC2155 -S warning "$file" 2>&1 | head -10 | sed 's/^/         /'
      WARN=$((WARN + 1))
    fi
  done
else
  echo -e "  ${YELLOW}SKIP${NC}  shellcheck not installed (install: apt install shellcheck)"
  WARN=$((WARN + 1))
fi

# ============================================================================
# Phase 3: Smoke tests
# ============================================================================

echo ""
echo -e "${CYAN}Phase 3: Smoke Tests${NC}"
echo ""

SMOKE_SCRIPT="${SCRIPT_DIR}/tests/smoke.sh"
if [[ -f "$SMOKE_SCRIPT" ]]; then
  if bash "$SMOKE_SCRIPT"; then
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${NC}  Smoke tests failed"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "  ${YELLOW}SKIP${NC}  smoke.sh not found"
  WARN=$((WARN + 1))
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${CYAN}━━━ CI Gate Summary ━━━${NC}"
echo ""
echo "  Pass: $PASS  |  Warn: $WARN  |  Fail: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo -e "  ${RED}GATE FAILED — fix errors before merge${NC}"
  exit 1
else
  echo -e "  ${GREEN}GATE PASSED${NC}"
  exit 0
fi
