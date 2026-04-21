#!/usr/bin/env bash
################################################################################
# Module Intelligence System — Pre-Commit Hook
# Validates contracts and warns about breaking changes before commit
################################################################################

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDLC_DIR="$REPO_ROOT/.sdlc"
MEMORY_DIR="$SDLC_DIR/memory"

mkdir -p "$MEMORY_DIR"

if [[ ! -d "$SDLC_DIR/module-contracts" ]]; then
  log_warn "MIS not initialized (skipping pre-commit validation)"
  exit 0
fi

analyze_changes() {
  local changed_files
  changed_files=$(git diff --cached --name-only)

  local api_ok=true
  local data_ok=true

  echo "Checking API changes..."
  while IFS= read -r file; do
    if [[ "$file" == *.java ]] || [[ "$file" == *.kt ]]; then
      local deleted_endpoints
      deleted_endpoints=$(git diff --cached -p "$file" 2>/dev/null | grep -E "^-\s*@(RequestMapping|GetMapping|PostMapping)" || true)
      if [[ -n "$deleted_endpoints" ]]; then
        api_ok=false
        log_warn "Detected removed API endpoint in: $file"
      fi
    fi
  done <<< "$changed_files"

  echo "Checking data schema changes..."
  while IFS= read -r file; do
    if [[ "$file" == *.sql ]]; then
      local dropped_cols
      dropped_cols=$(git diff --cached -p "$file" 2>/dev/null | grep -i "DROP COLUMN" || true)
      if [[ -n "$dropped_cols" ]]; then
        data_ok=false
        log_warn "Detected column drop (breaking change) in: $file"
      fi
    fi
  done <<< "$changed_files"

  echo ""
  if [[ "$api_ok" != true ]] || [[ "$data_ok" != true ]]; then
    echo -e "${YELLOW}WARNING: Breaking changes detected${NC}"
    echo "Review and fix before committing, or use: git commit --no-verify"
    echo ""
    exit 0
  else
    log_success "All validations passed"
    echo ""
    exit 0
  fi
}

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}MODULE INTELLIGENCE SYSTEM — PRE-COMMIT VALIDATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

analyze_changes
