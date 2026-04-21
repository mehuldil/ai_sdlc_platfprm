#!/usr/bin/env bash
################################################################################
# Unified Module System — Incremental Updater
# Re-scans only if codebase changed since last scan
################################################################################

set -eo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
MODULE_DIR="$REPO_PATH/.sdlc/module"
META_FILE="$MODULE_DIR/meta.json"

if [[ ! -d "$MODULE_DIR" ]]; then
  log_warn "Module system not initialized"
  log_info "Run: sdlc module init"
  exit 0
fi

if [[ ! -f "$META_FILE" ]]; then
  log_warn "meta.json missing — running full init"
  bash "$(dirname "$0")/module-init.sh" "$REPO_PATH"
  exit 0
fi

CURRENT_COMMIT=$(cd "$REPO_PATH" && git rev-parse HEAD 2>/dev/null || echo "unknown")
LAST_COMMIT=$(grep -o '"commit": "[^"]*"' "$META_FILE" 2>/dev/null | cut -d'"' -f4 || echo "none")

log_info "Last scan: ${LAST_COMMIT:0:8} | Current: ${CURRENT_COMMIT:0:8}"

if [[ "$LAST_COMMIT" == "$CURRENT_COMMIT" ]]; then
  log_success "No changes since last scan — skipping"
  exit 0
fi

log_warn "Changes detected — running full update"
bash "$(dirname "$0")/module-init.sh" "$REPO_PATH"

log_success "Module system updated"
