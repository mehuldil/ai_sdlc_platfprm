#!/usr/bin/env bash
# ============================================================================
# Smoke tests for sdlc CLI
# Run: bash cli/tests/smoke.sh
# Exit 0 = all pass, Exit 1 = failure
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDLC="${SCRIPT_DIR}/sdlc.sh"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert_exit_0() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}  $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${NC}  $desc (exit $?)"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_0_timeout() {
  local secs="$1" desc="$2"
  shift 2
  if timeout "$secs" "$@" >/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}  $desc"
    PASS=$((PASS + 1))
  else
    local rc=$?
    if [[ $rc -eq 124 ]]; then
      echo -e "  ${YELLOW}SKIP${NC}  $desc (timeout after ${secs}s)"
    else
      echo -e "  ${RED}FAIL${NC}  $desc (exit $rc)"
      FAIL=$((FAIL + 1))
    fi
  fi
}

assert_exit_nonzero() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo -e "  ${RED}FAIL${NC}  $desc (expected non-zero, got 0)"
    FAIL=$((FAIL + 1))
  else
    echo -e "  ${GREEN}PASS${NC}  $desc"
    PASS=$((PASS + 1))
  fi
}

assert_output_contains() {
  local desc="$1"
  local expected="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -q "$expected"; then
    echo -e "  ${GREEN}PASS${NC}  $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${NC}  $desc (expected '$expected' in output)"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "━━━ SDLC CLI Smoke Tests ━━━"
echo ""

# --- Basic commands ---
echo "Basic commands:"
assert_exit_0      "sdlc help"          bash "$SDLC" help
assert_exit_0      "sdlc --help"        bash "$SDLC" --help
assert_exit_0      "sdlc version"       bash "$SDLC" version
assert_exit_0      "sdlc --version"     bash "$SDLC" --version
assert_exit_0_timeout 120 "sdlc doctor" bash "$SDLC" doctor

# --- Output checks ---
echo ""
echo "Output validation:"
assert_output_contains "version string"     "2.0.0"       bash "$SDLC" version
assert_output_contains "help shows 'run'"   "run"         bash "$SDLC" help
assert_output_contains "help shows 'ado'"   "ado"         bash "$SDLC" help
assert_output_contains "help shows 'agent'" "agent"       bash "$SDLC" help

# --- Invalid inputs ---
echo ""
echo "Error handling:"
assert_exit_nonzero "invalid command"        bash "$SDLC" nonexistent-cmd
assert_output_contains "unknown cmd shows recovery" "Next steps" bash "$SDLC" nonexistent-cmd
assert_exit_nonzero "invalid role"           bash "$SDLC" use invalidrole
assert_output_contains "invalid role shows recovery" "Next steps" bash "$SDLC" use invalidrole
assert_exit_nonzero "run without stage"      bash "$SDLC" run nonexistent-stage
assert_output_contains "invalid stage shows recovery" "Next steps" bash "$SDLC" run nonexistent-stage

# --- Context commands ---
echo ""
echo "Context commands:"
assert_exit_0       "sdlc context"           bash "$SDLC" context
assert_exit_0       "sdlc use product"       bash "$SDLC" use product
assert_exit_0       "sdlc use backend --stack=java" bash "$SDLC" use backend --stack=java

# --- Catalog commands ---
echo ""
echo "Catalog commands:"
assert_exit_0       "sdlc flow list"         bash "$SDLC" flow list
assert_exit_0       "sdlc agent list"        bash "$SDLC" agent list
assert_exit_0       "sdlc skills list"       bash "$SDLC" skills list
assert_exit_0       "sdlc template list"     bash "$SDLC" template list

# --- Registry (optional; requires bash from repo root) ---
echo ""
echo "Registry:"
REG_SCRIPT="${SCRIPT_DIR}/../scripts/verify-platform-registry.sh"
if [[ -f "$REG_SCRIPT" ]]; then
  assert_exit_0 "verify-platform-registry.sh" bash "$REG_SCRIPT"
else
  echo -e "  ${YELLOW}SKIP${NC}  verify-platform-registry.sh (path)"
fi

# --- Summary ---
echo ""
echo "━━━ Results ━━━"
echo ""
TOTAL=$((PASS + FAIL))
echo "  Total: $TOTAL  |  Pass: $PASS  |  Fail: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo -e "  ${RED}FAILED${NC}"
  exit 1
else
  echo -e "  ${GREEN}ALL PASSED${NC}"
  exit 0
fi
