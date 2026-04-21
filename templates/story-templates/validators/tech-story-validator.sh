#!/usr/bin/env bash
# Tech Story Validator
# Grounded implementation spec — system design + stories + non-regression
# Non-blocking - returns warnings, not errors

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

validate_tech_story() {
  local story_file=$1
  local strict=${2:-false}

  if [[ ! -f "$story_file" ]]; then
    echo -e "${RED}✗ Story file not found: $story_file${NC}"
    return 1
  fi

  local warnings=0
  local passes=0
  local _tmp
  _tmp="${TMPDIR:-/tmp}/tech-story-val-$$.md"
  tr -d '\r' < "$story_file" > "$_tmp" 2>/dev/null || true
  if [[ ! -s "$_tmp" ]]; then _tmp="$story_file"; else story_file="$_tmp"; trap 'rm -f "$_tmp"' RETURN; fi

  echo "Validating tech story: $1"
  echo "---"

  # Match headings after "## " (emoji-safe: anchor on text fragment)
  _has_rx() { grep -qE "^## .*$1" "$story_file"; }

  declare -a required_rx=(
    'Inputs & source of truth'
    'Baseline: existing system'
    'Technical goal & delta'
    'Alignment with system design'
    'Change impact & blast radius'
    'Non-regression, compatibility'
    'Architecture & implementation approach'
    'Testing strategy'
    'Acceptance criteria'
    'Rollout & rollback plan'
  )

  for pat in "${required_rx[@]}"; do
    if _has_rx "$pat"; then
      echo -e "${GREEN}✓${NC} Section present: $pat"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Section missing: $pat"
      warnings=$((warnings + 1))
    fi
  done

  for optional in 'Performance & scalability' 'Reliability & resilience' 'Security & compliance' 'Observability'; do
    if _has_rx "$optional"; then
      echo -e "${GREEN}✓${NC} Optional section present: $optional"
      passes=$((passes + 1))
    fi
  done

  # Traceability table (emoji-safe heading match)
  if grep -qE '^## .*Traceability' "$story_file"; then
    local _tr
    _tr=$(grep -A25 -E '^## .*Traceability' "$story_file")
    if echo "$_tr" | grep -qF 'System design' && echo "$_tr" | grep -qF 'Master Story' && echo "$_tr" | grep -qF 'Sprint Story'; then
      echo -e "${GREEN}✓${NC} Traceability table includes design / master / sprint rows"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} Traceability: add System design, Master Story, Sprint Story rows"
      warnings=$((warnings + 1))
    fi
  else
    echo -e "${YELLOW}⚠${NC} Missing Traceability section"
    warnings=$((warnings + 1))
  fi

  # Non-regression substance (slice until Architecture section — emoji-safe)
  if sed -n '/^## .*Non-regression/,/^## .*Architecture & implementation/p' "$story_file" | grep -qE 'invariant|backward|regression|contract|must remain|do not break'; then
    echo -e "${GREEN}✓${NC} Non-regression section mentions invariants / compatibility / regression"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Non-regression: spell out invariants, backward compatibility, or regression checks"
    warnings=$((warnings + 1))
  fi

  # Baseline has repo anchor table
  if sed -n '/^## .*Baseline: existing system/,/^## .*Technical goal/p' "$story_file" | grep -q '|'; then
    echo -e "${GREEN}✓${NC} Baseline includes structured content (e.g. table)"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Baseline: add repo anchors table and as-is behavior"
    warnings=$((warnings + 1))
  fi

  # Performance targets if stated
  if grep -qE 'Performance|latency|throughput|P95|SLA' "$story_file"; then
    if grep -qE '[0-9]+[[:space:]]*(ms|s|req|ops|%|rpm)' "$story_file"; then
      echo -e "${GREEN}✓${NC} Quantified target or number present (performance/SLO context)"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} If claiming performance, add measurable targets (ms, %, ops/s) or USER_INPUT_REQUIRED"
      warnings=$((warnings + 1))
    fi
  fi

  # Rollback
  if grep -qiE 'rollback[[:space:]]+trigger|rollback:|kill switch' "$story_file"; then
    echo -e "${GREEN}✓${NC} Rollback or kill-switch discussed"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Define rollback trigger or flag/kill-switch behavior"
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
  story_file=${1:-}
  strict=${2:-false}

  if [[ -z "$story_file" ]]; then
    echo "Usage: $0 <story-file> [--strict]"
    exit 1
  fi

  validate_tech_story "$story_file" "$strict"
fi
