#!/bin/bash
################################################################################
# Memory Freshness Validator (R5)
# Checks if local memory files are stale compared to git history.
# Warns user if memory may be outdated and suggests running sdlc memory sync.
################################################################################

set -e

PLATFORM_DIR="${SDLC_PROJECT_DIR:-.}"
MEMORY_DIR="${PLATFORM_DIR}/.sdlc/memory"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}⚠${NC}  $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_info() {
  echo -e "${BLUE}→${NC} $1"
}

log_section() {
  echo ""
  echo -e "${BLUE}=== $1 ===${NC}"
  echo ""
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

verify_fresh=0
verbose=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify-fresh) verify_fresh=1 ;;
    --verbose) verbose=1 ;;
    -h|--help)
      cat <<'HELP'
Memory Freshness Checker (R5)

Usage:
  scripts/memory-freshness.sh [--verify-fresh] [--verbose]

Options:
  --verify-fresh    Return error if any memory is stale (fail-on-stale mode)
  --verbose         Show detailed freshness report
  -h, --help        Show this help

Description:
  Checks if local memory files (.sdlc/memory/*.md) are up-to-date with git history.
  Compares file mtime against git last-modified timestamp.

  If file is stale:
    - Local copy is older than git version
    - Suggests running: sdlc memory sync

Exit Codes:
  0   All memory files are fresh
  1   One or more memory files are stale

HELP
      exit 0
      ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# ============================================================================
# VALIDATION
# ============================================================================

if [[ ! -d "$PLATFORM_DIR" ]]; then
  log_error "Platform directory not found: $PLATFORM_DIR"
  exit 1
fi

if [[ ! -d "${PLATFORM_DIR}/.git" ]]; then
  log_info "Not a git repository — skipping freshness check"
  exit 0
fi

if [[ ! -d "$MEMORY_DIR" ]]; then
  log_info "No memory directory found — nothing to check"
  exit 0
fi

# ============================================================================
# CHECK FRESHNESS OF EACH MEMORY FILE
# ============================================================================

log_section "Memory Freshness Check"

cd "$PLATFORM_DIR" || exit 1

stale_files=()
fresh_files=()
total_checked=0

for mem_file in "$MEMORY_DIR"/*.md; do
  [[ -f "$mem_file" ]] || continue

  total_checked=$((total_checked + 1))
  rel_path="${mem_file#$PLATFORM_DIR/}"

  # Get local file modification time
  local_mtime=$(stat -f "%m" "$mem_file" 2>/dev/null || stat -c "%Y" "$mem_file" 2>/dev/null || date +%s)

  # Get git last-modified time for this file
  # If file is not in git (untracked), treat as "fresh" (local file)
  if git ls-files --error-unmatch "$rel_path" &>/dev/null 2>&1; then
    # File is in git — check last commit time
    git_mtime=$(git log -1 --format="%ct" -- "$rel_path" 2>/dev/null || echo "0")

    if [[ -z "$git_mtime" || "$git_mtime" == "0" ]]; then
      git_mtime=$local_mtime
    fi
  else
    # File not in git — treat as fresh (local-only file)
    git_mtime=$local_mtime
  fi

  # Compare times
  if [[ $local_mtime -lt $git_mtime ]]; then
    # Local file is OLDER than git version
    stale_files+=("$mem_file")
    status="STALE"
  else
    # Local file is up-to-date or newer
    fresh_files+=("$mem_file")
    status="FRESH"
  fi

  if [[ $verbose -eq 1 ]]; then
    # Convert to readable format
    local_readable=$(date -f "%s" -r "$local_mtime" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || \
                     date -d @"$local_mtime" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || \
                     echo "unknown")
    git_readable=$(date -f "%s" -r "$git_mtime" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || \
                   date -d @"$git_mtime" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || \
                   echo "unknown")

    printf '  %-8s  %-40s  (local: %s, git: %s)\n' "$status" "$(basename "$mem_file")" "$local_readable" "$git_readable"
  else
    echo "  $status  $(basename "$mem_file")"
  fi
done

# ============================================================================
# REPORT RESULTS
# ============================================================================

log_section "Results"

log_info "Checked $total_checked memory file(s)"
echo ""
log_success "${#fresh_files[@]} file(s) are fresh"

if [[ ${#stale_files[@]} -gt 0 ]]; then
  log_warn "${#stale_files[@]} file(s) are stale:"
  for file in "${stale_files[@]}"; do
    echo "  $(basename "$file")"
  done
  echo ""
  log_warn "These files are outdated (local copy is older than git)"
  log_info "To update stale files, run:"
  echo "  sdlc memory sync"
  echo ""
fi

# ============================================================================
# VERDICT
# ============================================================================

if [[ ${#stale_files[@]} -eq 0 ]]; then
  log_section "Verdict"
  log_success "All memory files are fresh ✓"
  exit 0
else
  log_section "Verdict"
  log_warn "Memory freshness check FAILED"
  echo ""

  if [[ $verify_fresh -eq 1 ]]; then
    log_error "Execution blocked: stale memory detected (--verify-fresh flag set)"
    echo ""
    echo "Options:"
    echo "  1. Run: sdlc memory sync"
    echo "  2. Or skip check: unset SDLC_VERIFY_FRESH"
    exit 1
  else
    log_info "Memory will be used as-is (consider running 'sdlc memory sync')"
    exit 0
  fi
fi
