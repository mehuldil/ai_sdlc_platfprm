#!/usr/bin/env bash
# Task Validator — atomic task; traceability to Sprint/Master/PRD; regression
# Non-blocking - returns warnings, not errors

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

validate_task() {
  local _orig=$1
  local strict=${2:-false}
  local task_file=$_orig

  if [[ ! -f "$_orig" ]]; then
    echo -e "${RED}✗ Task file not found: $_orig${NC}"
    return 1
  fi

  local warnings=0
  local passes=0
  local _tmp="${TMPDIR:-/tmp}/task-val-$$.md"
  tr -d '\r' < "$_orig" > "$_tmp" 2>/dev/null || true
  if [[ -s "$_tmp" ]]; then task_file="$_tmp"; trap 'rm -f "$_tmp"' RETURN; fi

  echo "Validating task: $_orig"
  echo "---"

  _has_rx() { grep -qE "^## .*$1" "$task_file"; }

  for label in "What's the Task?" "Repo anchors" "Acceptance Criteria" "Traceability"; do
    if _has_rx "$label"; then
      echo -e "${GREEN}✓${NC} Section present: $label"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Section missing: $label"
      warnings=$((warnings + 1))
    fi
  done

  if grep -qE '^## .*Traceability' "$task_file"; then
    _tr=$(grep -A30 -E '^## .*Traceability' "$task_file")
    if echo "$_tr" | grep -qF 'Sprint Story' && echo "$_tr" | grep -qF 'PRD section'; then
      echo -e "${GREEN}✓${NC} Traceability includes Sprint + PRD"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Traceability table: add Sprint Story + PRD section IDs"
      warnings=$((warnings + 1))
    fi
    if echo "$_tr" | grep -qF 'Master Story'; then
      echo -e "${GREEN}✓${NC} Master Story row in traceability"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Add Master Story to traceability when available"
      warnings=$((warnings + 1))
    fi
  fi

  if grep -qE 'Regression:|regression' "$task_file"; then
    echo -e "${GREEN}✓${NC} Regression called out in acceptance/repo section"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Name regression tests or command under acceptance (or justify N/A)"
    warnings=$((warnings + 1))
  fi

  if grep -qE -- '- \[[ xX]\]|^[[:space:]]*[0-9]+\.[[:space:]]+\[[ xX]\]' "$task_file"; then
    echo -e "${GREEN}✓${NC} Acceptance criteria use checkboxes"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Acceptance criteria should use checkboxes"
    warnings=$((warnings + 1))
  fi

  if grep -qE "[0-9]+(h|d)" "$task_file"; then
    echo -e "${GREEN}✓${NC} Effort hint present (h/d)"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Add effort estimate (e.g. 4h, 1d)"
    warnings=$((warnings + 1))
  fi

  echo "---"
  echo -e "Validation complete: ${GREEN}$passes passes${NC}, ${YELLOW}$warnings warnings${NC}"

  if [[ "$strict" == "true" && $warnings -gt 0 ]]; then
    echo -e "${YELLOW}In strict mode, $warnings warnings found${NC}"
    return 1
  fi

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  task_file=${1:-}
  strict=${2:-false}
  if [[ -z "$task_file" ]]; then
    echo "Usage: $0 <task-file> [--strict]"
    exit 1
  fi
  validate_task "$task_file" "$strict"
fi
