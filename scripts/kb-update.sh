#!/usr/bin/env bash
# Module Knowledgebase Updater — kb-update.sh
set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

KB_DIR="$REPO_PATH/.sdlc/module-kb"

if [[ ! -d "$KB_DIR" ]]; then
  log_warn "Module KB not found at: $KB_DIR"
  log_info "Run 'sdlc kb init' to initialize"
  exit 0
fi

LAST_SCAN_FILE="$KB_DIR/last-scan.json"
if [[ ! -f "$LAST_SCAN_FILE" ]]; then
  log_warn "last-scan.json not found — running full scan"
  bash "$(dirname "$0")/kb-init.sh" "$REPO_PATH"
  exit 0
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CURRENT_COMMIT=$(cd "$REPO_PATH" && git rev-parse HEAD 2>/dev/null || echo "unknown")
LAST_COMMIT=$(grep -o '"commit": "[^"]*"' "$LAST_SCAN_FILE" | cut -d'"' -f4)

log_info "Updating Module Knowledgebase"
log_info "Last scan: $LAST_COMMIT"
log_info "Current: ${CURRENT_COMMIT:0:8}"
echo ""

if [[ "$LAST_COMMIT" == "$CURRENT_COMMIT" ]]; then
  log_info "No changes since last scan"
  exit 0
fi

log_warn "Detected changes — running full update"
bash "$(dirname "$0")/kb-init.sh" "$REPO_PATH"

log_success "Module Knowledgebase updated"
