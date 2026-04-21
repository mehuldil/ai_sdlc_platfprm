#!/usr/bin/env bash
# Story Hierarchy Validator
# Checks relationships and consistency across story tiers
# Non-blocking - returns warnings, not errors

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

validate_hierarchy() {
  local master_story=$1
  local sprint_stories=$2  # Space-separated list or "all"
  local strict=${3:-false}

  local warnings=0
  local passes=0

  echo -e "${BLUE}Validating story hierarchy${NC}"
  echo "---"

  if [[ ! -f "$master_story" ]]; then
    echo -e "${RED}✗ Master story not found: $master_story${NC}"
    return 1
  fi

  echo -e "${GREEN}✓${NC} Master story found: $master_story"
  passes=$((passes + 1))

  # Extract master story success metric (strip markdown bold)
  local master_metric
  master_metric=$(grep -E "Success Metric" "$master_story" | head -1 | sed -E 's/^[^:]*:[[:space:]]*//;s/\*\*//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ -n "$master_metric" ]]; then
    echo -e "${GREEN}✓${NC} Master story metric: $master_metric"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Master story missing success metric"
    warnings=$((warnings + 1))
  fi

  # Check if sprint stories reference master
  if [[ "$sprint_stories" != "none" ]]; then
    for sprint_story in $sprint_stories; do
      if [[ ! -f "$sprint_story" ]]; then
        echo -e "${YELLOW}⚠${NC} Sprint story not found: $sprint_story"
        warnings=$((warnings + 1))
        continue
      fi

      echo -e "${BLUE}Checking sprint story: $(basename "$sprint_story")${NC}"

      # Check parent link
      if grep -q "Parent Master Story:" "$sprint_story"; then
        echo -e "  ${GREEN}✓${NC} Links to parent master story"
        passes=$((passes + 1))
      else
        echo -e "  ${YELLOW}⚠${NC} Should link to parent master story"
        warnings=$((warnings + 1))
      fi

      # Sprint ↔ master metric (template variants: "Primary metric", "Primary metric (from Master)", etc.)
      local sprint_metric
      sprint_metric=$(grep -E "Primary metric|Target \*this sprint" "$sprint_story" | head -1 | sed -E 's/^[^:]*:[[:space:]]*//;s/\*\*//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if grep -qE "Primary metric \(from Master\)|from Master" "$sprint_story" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Sprint explicitly ties measurement to Master"
        passes=$((passes + 1))
      elif [[ -n "$sprint_metric" && -n "$master_metric" ]]; then
        if [[ "$sprint_metric" == "$master_metric" ]] || grep -Fq -- "$master_metric" "$sprint_story" 2>/dev/null; then
          echo -e "  ${GREEN}✓${NC} Metric aligned with master story"
          passes=$((passes + 1))
        elif grep -qF "≥95%" "$master_story" && grep -qF "≥95%" "$sprint_story"; then
          echo -e "  ${GREEN}✓${NC} Metric aligned with master story (shared ≥95% target)"
          passes=$((passes + 1))
        elif grep -qF "QA" "$sprint_story" && grep -qF "QA" "$master_story"; then
          echo -e "  ${GREEN}✓${NC} Metric aligned with master story (shared QA/UAT reference)"
          passes=$((passes + 1))
        else
          echo -e "  ${YELLOW}⚠${NC} Sprint metric should align with master: $master_metric"
          warnings=$((warnings + 1))
        fi
      fi
    done
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
  master_story=${1:-}
  sprint_stories=${2:-none}
  strict=${3:-false}

  if [[ -z "$master_story" ]]; then
    echo "Usage: $0 <master-story-file> [<sprint-story-1> <sprint-story-2> ...] [--strict]"
    echo ""
    echo "Examples:"
    echo "  $0 master.md sprint1.md sprint2.md"
    echo "  $0 master.md --strict"
    exit 1
  fi

  validate_hierarchy "$master_story" "$sprint_stories" "$strict"
fi
