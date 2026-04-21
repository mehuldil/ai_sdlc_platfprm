#!/usr/bin/env bash
# Master Story Validator
# Checks completeness and quality of master story
# Non-blocking - returns warnings, not errors

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

validate_master_story() {
  local _orig=$1
  local strict=${2:-false}
  local story_file=$_orig

  if [[ ! -f "$_orig" ]]; then
    echo -e "${RED}✗ Story file not found: $_orig${NC}"
    return 1
  fi

  local _tmp="${TMPDIR:-/tmp}/master-val-$$.md"
  tr -d '\r' < "$_orig" > "$_tmp" 2>/dev/null || true
  if [[ -s "$_tmp" ]]; then story_file="$_tmp"; trap 'rm -f "$_tmp"' RETURN; fi

  local warnings=0
  local passes=0

  echo "Validating master story: $_orig"
  echo "---"

  # Check for core sections (see templates/story-templates/master-story-template.md)
  local sections=(
    "🎯 Outcome"
    "🔍 Problem Definition"
    "👤 Target User & Context"
    "⚡ Job To Be Done"
    "💡 Solution Hypothesis"
    "🧩 Capability Definition"
    "📎 PRD-sourced specifics"
    "🎯 Experience Intent"
    "🎨 UI & design"
    "🧾 Acceptance Criteria"
    "📊 Measurement & Signals"
    "🧪 Validation Plan"
    "⚠️ Risks & Unknowns"
    "🔗 Dependencies"
    "🚫 Explicit Non-Goals"
    "📅 Priority & Rollout Strategy"
  )

  for section in "${sections[@]}"; do
    if grep -q "## $section" "$story_file"; then
      echo -e "${GREEN}✓${NC} Section present: $section"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Section missing: $section"
      warnings=$((warnings + 1))
    fi
  done

  # Check for quantified success metric
  if grep -q "Success Metric:" "$story_file"; then
    if grep "Success Metric:" "$story_file" | grep -qE "[0-9]+(%|ms|s|ops|users)"; then
      echo -e "${GREEN}✓${NC} Success metric appears quantified"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Success metric should include numbers (%, ms, ops, etc)"
      warnings=$((warnings + 1))
    fi
  fi

  # Check for specific dependencies
  if grep -q "Cross-POD blockers:" "$story_file"; then
    if ! grep "Cross-POD blockers:" "$story_file" | grep -qE "[A-Z]+-[0-9]+|POD-"; then
      echo -e "${YELLOW}⚠${NC} Cross-POD blockers should name specific PODs"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}✓${NC} Cross-POD blockers named"
      passes=$((passes + 1))
    fi
  fi

  # Check for acceptance criteria format
  if grep -q "Given" "$story_file" && grep -q "When" "$story_file" && grep -q "Then" "$story_file"; then
    echo -e "${GREEN}✓${NC} Acceptance criteria use Given/When/Then format"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Consider using Given/When/Then format for acceptance criteria"
    warnings=$((warnings + 1))
  fi

  # Advisory: PRD artifact IDs in body (skip template header — first ~22 lines)
  if tail -n +22 "$story_file" | grep -qE '\bN[0-9]+\b|Notification[[:space:]]+[Nn]?[0-9]+|PRD[[:space:]]*§' 2>/dev/null; then
    if ! grep -q "## 📎 PRD-sourced specifics" "$story_file" 2>/dev/null; then
      echo -e "${YELLOW}⚠${NC} PRD artifact IDs or § refs in story body — add **📎 PRD-sourced specifics** with full lifted text (ADO self-contained)"
      warnings=$((warnings + 1))
    fi
  fi

  # UI & design: flag unfilled template placeholders
  if grep -q "## 🎨 UI & design" "$story_file"; then
    if grep -A45 "## 🎨 UI & design" "$story_file" | grep -qE '\[URL\]|\[name\]|\[date\]'; then
      echo -e "${YELLOW}⚠${NC} UI & design: replace template placeholders ([URL], [name], [date]) or set N/A / USER_INPUT_REQUIRED"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}✓${NC} UI & design: no obvious [URL]/[name]/[date] placeholders in section"
      passes=$((passes + 1))
    fi
  fi

  echo "---"
  echo -e "Validation complete: ${GREEN}$passes passes${NC}, ${YELLOW}$warnings warnings${NC}"

  if [[ "$strict" == "true" && $warnings -gt 0 ]]; then
    echo -e "${YELLOW}In strict mode, $warnings warnings found${NC}"
    return 1
  fi

  return 0
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  story_file=${1:-}
  strict=${2:-false}

  if [[ -z "$story_file" ]]; then
    echo "Usage: $0 <story-file> [--strict]"
    exit 1
  fi

  validate_master_story "$story_file" "$strict"
fi
