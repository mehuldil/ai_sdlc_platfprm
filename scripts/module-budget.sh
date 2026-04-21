#!/usr/bin/env bash
################################################################################
# Unified Module System — Token Budget Tracker
# Per-stage, per-role budget tracking with warnings
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

declare -A STAGE_BUDGET=(
  ["01"]=2000   ["02"]=3000   ["03"]=3000   ["04"]=4000
  ["05"]=8000   ["06"]=3000   ["07"]=3000   ["08"]=6000
  ["09"]=5000   ["10"]=6000   ["11"]=4000   ["12"]=2000
  ["13"]=2000   ["14"]=2000   ["15"]=2000
)

declare -A STAGE_NAME=(
  ["01"]="Requirement Intake" ["02"]="Grooming" ["03"]="Architecture"
  ["04"]="Detailed Design" ["05"]="System Design" ["06"]="Design Review"
  ["07"]="Task Breakdown" ["08"]="Implementation" ["09"]="Code Review"
  ["10"]="Test Design" ["11"]="Test Execution" ["12"]="Commit & Push"
  ["13"]="Documentation" ["14"]="Release Signoff" ["15"]="Summary & Close"
)

declare -A ROLE_DAILY=(
  ["product"]=8000 ["backend"]=6000 ["frontend"]=6000
  ["qa"]=4000 ["devops"]=5000 ["performance"]=5000
  ["ui"]=4000 ["tpm"]=3000 ["boss"]=5000
)

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
SDLC_DIR="$REPO_PATH/.sdlc"

get_current_stage() {
  if [[ -f "$SDLC_DIR/stage" ]]; then
    cat "$SDLC_DIR/stage" | tr -d '[:space:]'
  else
    echo "08"
  fi
}

get_current_role() {
  if [[ -f "$SDLC_DIR/role" ]]; then
    cat "$SDLC_DIR/role" | tr -d '[:space:]'
  else
    echo "backend"
  fi
}

main() {
  local stage=$(get_current_stage)
  local role=$(get_current_role)
  local stage_budget="${STAGE_BUDGET[$stage]:-5000}"
  local stage_name="${STAGE_NAME[$stage]:-Unknown}"
  local role_daily="${ROLE_DAILY[$role]:-5000}"

  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}MODULE SYSTEM — TOKEN BUDGET${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "  Stage:  $stage — $stage_name"
  echo "  Role:   $role"
  echo ""
  echo -e "${BLUE}Stage Budget:${NC}   $(echo -n "$stage_budget") tokens"
  echo -e "${BLUE}Daily Budget:${NC}   $(echo -n "$role_daily") tokens"
  echo ""
  echo -e "${CYAN}Token Allocation:${NC}"
  echo "  Smart KB load:     2-3K tokens (auto-detected)"
  echo "  Contracts:         ~1K tokens"
  echo "  ADO linking:       ~500 tokens"
  echo "  Available for work: ~$(( stage_budget - 3500 )) tokens"
  echo ""
  echo -e "${CYAN}Optimization Tips:${NC}"
  echo "  sdlc module load          — Auto-detect (2-3K vs 12K)"
  echo "  sdlc module load api      — API changes only (~1.5K)"
  echo "  sdlc module load logic    — Logic changes only (~1K)"
  echo ""

  # Token tier recommendation
  if [[ $stage_budget -ge 6000 ]]; then
    echo -e "${GREEN}Model: Sonnet (generation) — within budget${NC}"
  elif [[ $stage_budget -ge 3000 ]]; then
    echo -e "${YELLOW}Model: Sonnet (lean) — watch budget${NC}"
  else
    echo -e "${YELLOW}Model: Haiku (validation only) — tight budget${NC}"
  fi
  echo ""

  log_success "Budget check complete"
}

main "$@"
