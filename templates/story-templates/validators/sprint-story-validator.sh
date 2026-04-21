#!/usr/bin/env bash
# Sprint Story Validator
# Checks completeness and execution readiness of sprint story
# Non-blocking - returns warnings, not errors

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

validate_sprint_story() {
  local _orig=$1
  local strict=${2:-false}
  local story_file=$_orig

  if [[ ! -f "$_orig" ]]; then
    echo -e "${RED}✗ Story file not found: $_orig${NC}"
    return 1
  fi

  local _tmp="${TMPDIR:-/tmp}/sprint-val-$$.md"
  tr -d '\r' < "$_orig" > "$_tmp" 2>/dev/null || true
  if [[ -s "$_tmp" ]]; then story_file="$_tmp"; trap 'rm -f "$_tmp"' RETURN; fi

  local warnings=0
  local passes=0

  echo "Validating sprint story: $_orig"
  echo "---"

  # Check for parent master story link
  if grep -q "Parent Master Story:" "$story_file"; then
    echo -e "${GREEN}✓${NC} Parent Master Story linked"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Should link to parent Master Story"
    warnings=$((warnings + 1))
  fi

  # Check for core sections (see sprint-story-template.md)
  local sections=(
    "🎯 What We're Building"
    "🔍 Context"
    "⚡ Scope"
    "📎 PRD / Master lift"
    "🏗️ Technical Approach"
    "🧾 Acceptance Criteria"
    "🎨 UI & design"
    "🔗 Dependencies"
    "📊 How We'll Measure It"
    "🚀 Definition of Done"
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

  # Check for IN/OUT scope
  if grep -q "✅ Included" "$story_file" && grep -q "🚫 Excluded" "$story_file"; then
    echo -e "${GREEN}✓${NC} Scope has both IN and OUT"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Scope should clearly define IN (included) and OUT (excluded)"
    warnings=$((warnings + 1))
  fi

  # Check for acceptance criteria checkboxes
  # Portable: "- [ ]" / "- [x]" or numbered "1. [ ]" / "2. [x]" (use -- so leading - is not parsed as an option)
  if grep -qE -- '- \[[ xX]\]|^[[:space:]]*[0-9]+\.[[:space:]]+\[[ xX]\]' "$story_file"; then
    echo -e "${GREEN}✓${NC} Acceptance criteria use checkboxes"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Acceptance criteria should use checkboxes (- [ ] or 1. [ ])"
    warnings=$((warnings + 1))
  fi

  # Check for effort estimate
  if grep -qE "Estimated effort|[0-9]+(h|d|days)" "$story_file"; then
    echo -e "${GREEN}✓${NC} Effort estimate present"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Should include effort estimate (e.g., 5d, 10h)"
    warnings=$((warnings + 1))
  fi

  # Check for team assignment
  if grep -q "Assignee:" "$story_file"; then
    echo -e "${GREEN}✓${NC} Assignee mentioned"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Should assign to team member or mark as TBD"
    warnings=$((warnings + 1))
  fi

  # PRD artifact IDs without lift section (skip blockquote — first ~22 lines)
  if tail -n +22 "$story_file" | grep -qE '\bN[0-9]+\b|Notification[[:space:]]+[Nn]?[0-9]+|PRD[[:space:]]*§' 2>/dev/null; then
    if ! grep -q "## 📎 PRD / Master lift" "$story_file" 2>/dev/null; then
      echo -e "${YELLOW}⚠${NC} PRD refs in story body — add **📎 PRD / Master lift** with full text or pointer to Master + row"
      warnings=$((warnings + 1))
    fi
  fi

  # UI & design placeholders
  if grep -q "## 🎨 UI & design" "$story_file"; then
    if grep -A50 "## 🎨 UI & design" "$story_file" | grep -qE '\[URL\]|\[name\]|\[date\]'; then
      echo -e "${YELLOW}⚠${NC} UI & design: replace [URL]/[name]/[date] or mark N/A"
      warnings=$((warnings + 1))
    else
      echo -e "${GREEN}✓${NC} UI & design: no obvious template placeholders"
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

  validate_sprint_story "$story_file" "$strict"
fi
