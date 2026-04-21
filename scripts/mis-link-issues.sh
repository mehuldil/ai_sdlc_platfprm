#!/usr/bin/env bash
################################################################################
# Module Intelligence System — ADO Issue Linking
# Finds related ADO work items based on code changes
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

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Not a git repository: $REPO_PATH"
  exit 1
fi

SDLC_DIR="$REPO_PATH/.sdlc"
MEMORY_DIR="$SDLC_DIR/memory"
mkdir -p "$MEMORY_DIR"

extract_ado_refs() {
  local files_to_scan
  files_to_scan=$(cd "$REPO_PATH" && git diff --name-only 2>/dev/null || echo "")

  if [[ -z "$files_to_scan" ]]; then
    files_to_scan=$(cd "$REPO_PATH" && git diff --cached --name-only 2>/dev/null || echo "")
  fi

  local ado_refs=()

  while IFS= read -r file; do
    if [[ -f "$REPO_PATH/$file" ]]; then
      while IFS= read -r ref; do
        if [[ -n "$ref" ]]; then
          ado_refs+=("$ref")
        fi
      done < <(grep -o 'AB#[0-9]\+' "$REPO_PATH/$file" 2>/dev/null || true)
    fi
  done <<< "$files_to_scan"

  printf '%s\n' "${ado_refs[@]}" | sort -u
}

get_story_id() {
  local branch_name
  branch_name=$(cd "$REPO_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  if [[ "$branch_name" =~ (US|AB|PBI)-[0-9]+ ]]; then
    echo "${BASH_REMATCH[0]}"
  else
    echo "unknown"
  fi
}

main() {
  log_info "Module Intelligence System — ADO Issue Linking"
  echo ""

  log_info "Scanning changed files for ADO references..."
  local directly_linked
  directly_linked=$(extract_ado_refs)

  local -a issue_array=()
  while IFS= read -r issue; do
    if [[ -n "$issue" ]]; then
      issue_array+=("$issue")
    fi
  done <<< "$directly_linked"

  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}ADO ISSUE LINKING SUMMARY${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo ""

  if [[ ${#issue_array[@]} -gt 0 ]]; then
    echo -e "${GREEN}Found ${#issue_array[@]} directly linked issue(s):${NC}"
    for issue in "${issue_array[@]}"; do
      echo "  - $issue"
    done
  else
    log_warn "No directly linked issues found (AB#XXXXX format)"
  fi

  echo ""
  log_success "ADO issue linking complete"

  local story_id=$(get_story_id)
  echo ""
  echo "Next: Update commit message with issue references"
  echo "  Example: 'Fix user validation (Fixes AB#12345)'"
}

main "$@"
