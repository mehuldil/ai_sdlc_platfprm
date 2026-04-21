#!/usr/bin/env bash
# cli/lib/logging.sh — Colors, icons, and logging helpers
# Part of AI SDLC Platform v2.0.0
# -----------------------------------------------------------

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons (emoji-based; fall back gracefully on dumb terms)
ROLE_ICON="🎭"
STACK_ICON="📚"
STAGE_ICON="🔄"
MEMORY_ICON="🧠"
WORKFLOW_ICON="⚡"

# --------------- Logging functions ---------------

log_info() {
  echo -e "${BLUE}ℹ${NC}  $*"
}

log_success() {
  echo -e "${GREEN}✓${NC}  $*"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC}  $*" >&2
}

log_error() {
  echo -e "${RED}✗${NC}  $*" >&2
}

# Optional hint line (cyan arrow) — use after log_error for one concrete next step
log_hint() {
  echo -e "${CYAN}→${NC}  $*" >&2
}

# Standard footer after recoverable errors: copy-paste next steps (IDE agents have no TTY)
log_recovery_footer() {
  echo "" >&2
  echo -e "${CYAN}── Next steps ──${NC}" >&2
  echo -e "  ${GREEN}sdlc context${NC}   Show role, stack, stage, project" >&2
  echo -e "  ${GREEN}sdlc doctor${NC}  Diagnose env, hooks, tools, registries" >&2
  echo -e "  ${CYAN}Docs:${NC} User_Manual/Guided_Execution_and_Recovery.md" >&2
}

# log_error + optional single hint + recovery footer (use for user-facing failures)
log_error_recovery() {
  log_error "$1"
  if [[ -n "${2:-}" ]]; then
    log_hint "$2"
  fi
  log_recovery_footer
}

log_section() {
  echo ""
  echo -e "${CYAN}━━━ $* ━━━${NC}"
  echo ""
}
