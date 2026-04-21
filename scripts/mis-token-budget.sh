#!/usr/bin/env bash
################################################################################
# Module Intelligence System — Token Budget Tracking
# Monitors token spend per stage and warns when approaching limits
################################################################################

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

declare -A STAGE_BUDGET=(
  ["01"]=2000   ["02"]=3000   ["03"]=3000   ["04"]=4000
  ["05"]=8000   ["06"]=3000   ["07"]=3000   ["08"]=6000
  ["09"]=5000   ["10"]=6000   ["11"]=4000   ["12"]=2000
  ["13"]=2000   ["14"]=2000   ["15"]=2000
)

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

if [[ ! -d "$REPO_PATH/.sdlc" ]]; then
  log_error ".sdlc directory not found: $REPO_PATH"
  exit 1
fi

SDLC_DIR="$REPO_PATH/.sdlc"
MEMORY_DIR="$SDLC_DIR/memory"
mkdir -p "$MEMORY_DIR"

get_current_stage() {
  if [[ -f "$SDLC_DIR/stage" ]]; then
    cat "$SDLC_DIR/stage" | tr -d '[:space:]'
  else
    echo "08"
  fi
}

main() {
  log_info "Module Intelligence System — Token Budget Tracker"
  echo ""

  local stage=$(get_current_stage)
  local budget="${STAGE_BUDGET[$stage]:-5000}"

  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}TOKEN BUDGET CHECK — Stage $stage${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  echo "Stage: $stage"
  echo "Budget: $(printf '%,d' "$budget") tokens"
  echo ""
  echo "Recommended KB sections for Stage $stage:"
  echo "  - Smart KB load (api/data/events/logic): 2-3K tokens"
  echo "  - Module contracts: 1K tokens"
  echo "  - ADO issue linking: 1K tokens"
  echo "  - Work tokens available: ~1.5-3K tokens"
  echo ""
  echo -e "${CYAN}Use smart KB loading to optimize token spend:${NC}"
  echo "  sdlc mis load <change-type>"
  echo ""

  log_success "Budget check complete"
}

main "$@"
