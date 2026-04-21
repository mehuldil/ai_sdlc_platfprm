#!/bin/bash
################################################################################
# Command Consistency Validator (R2)
# Ensures every CLI command (sdlc run XXX) has matching IDE slash command
# and vice versa. Reports mismatches and provides suggestions.
#
# Philosophy: CLI commands are foundational operations. IDE /project:* commands
# are interactive workflows that delegate to CLI operations. Most /project:*
# commands don't need direct CLI equivalents (they use sdlc run, sdlc flow, etc).
# This script validates structural consistency within each domain.
################################################################################

set -e

PLATFORM_DIR="${1:-.}"
CLI_FILE="${PLATFORM_DIR}/cli/sdlc.sh"
COMMANDS_DIR="${PLATFORM_DIR}/.claude/commands"
REGISTRY_FILE="${COMMANDS_DIR}/COMMANDS_REGISTRY.md"

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
# STEP 1: Extract CLI Commands
# ============================================================================

log_section "CLI Commands (Foundational Operations)"

if [[ ! -f "$CLI_FILE" ]]; then
  log_error "CLI file not found: $CLI_FILE"
  exit 1
fi

# Extract main commands from case statement in main() function.
# Tracks case/esac nesting so nested dispatchers (e.g. `repos) case ... esac`)
# do not leak their sub-branches as top-level commands.
# Note: case/esac keywords may appear mid-line (e.g. `repos)  case "$1" in`),
# so we count occurrences of the whole-word keywords on each line.
cli_commands=()
in_main=0
case_depth=0
while IFS= read -r line; do
  if [[ $line =~ ^main\(\) ]]; then
    in_main=1
    case_depth=0
    continue
  fi

  [[ $in_main -eq 1 ]] || continue

  # Depth increase happens AFTER branch-capture so the branch line itself
  # (e.g. `repos)  case "$1" in`) still registers as a depth=1 arm.
  before_line_depth=$case_depth

  # Branch capture: only at depth == 1 (the outer case arms).
  if [[ $before_line_depth -eq 1 ]] && [[ $line =~ ^[[:space:]]+([a-z][a-z_-]*)\) ]]; then
    cmd="${BASH_REMATCH[1]}"
    if [[ ! "$cmd" =~ ^(help|version|doctor|--help|-h)$ ]]; then
      cli_commands+=("$cmd")
    fi
  fi

  # Count whole-word `case` / `esac` on this line to update nesting.
  # `grep -o` enumerates matches; `wc -l` counts them.
  opens=$(printf '%s\n' "$line" | grep -oE '(^|[^[:alnum:]_])case([^[:alnum:]_]|$)' | wc -l)
  closes=$(printf '%s\n' "$line" | grep -oE '(^|[^[:alnum:]_])esac([^[:alnum:]_]|$)' | wc -l)
  case_depth=$((case_depth + opens - closes))
  if [[ $case_depth -le 0 ]] && [[ $before_line_depth -ge 1 ]]; then
    in_main=0
  fi
done < "$CLI_FILE"

log_info "Found ${#cli_commands[@]} CLI commands:"
printf '%s\n' "${cli_commands[@]}" | sort -u | sed 's/^/  sdlc /'

# ============================================================================
# STEP 2: Extract IDE Slash Commands
# ============================================================================

log_section "IDE Slash Commands (/project:* Interactive Workflows)"

SKIP_IDE_COMMANDS=0
if [[ ! -d "$COMMANDS_DIR" ]]; then
  if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" || -n "${TF_BUILD:-}" ]]; then
    log_warn "Commands directory not found: $COMMANDS_DIR (CI — no .claude/commands; run ./setup.sh locally or commit that tree)"
    SKIP_IDE_COMMANDS=1
  else
    log_error "Commands directory not found: $COMMANDS_DIR"
    exit 1
  fi
fi

ide_commands=()
if [[ "$SKIP_IDE_COMMANDS" -eq 0 ]]; then
for cmd_file in "$COMMANDS_DIR"/*.md; do
  [[ ! -f "$cmd_file" ]] && continue
  [[ "$(basename "$cmd_file")" == "COMMANDS_REGISTRY.md" ]] && continue

  cmd_name=$(basename "$cmd_file" .md)

  # Skip project-prefixed variants (they're duplicates)
  if [[ $cmd_name =~ ^project- ]]; then
    continue
  fi

  # Skip CLI-centric commands (use, context, init, etc. - these are CLI-only)
  if [[ "$cmd_name" =~ ^(use|context|init|setup|sync|publish|memory|ado|tokens|cost|skip-tests|show-test-skips|clear-test-skips|flow|route|agent|skills|template|doctor|version|help)$ ]]; then
    continue
  fi

  ide_commands+=("$cmd_name")
done
fi

if [[ "$SKIP_IDE_COMMANDS" -eq 1 ]]; then
  log_info "IDE workflows: (skipped — no $COMMANDS_DIR)"
else
  log_info "Found ${#ide_commands[@]} IDE interactive workflows:"
  printf '%s\n' "${ide_commands[@]}" | sort -u | sed 's/^/  \/project:/'
fi

# ============================================================================
# STEP 3: Validate CLI Internal Consistency
# ============================================================================

log_section "CLI Internal Consistency Check"

# Check that each CLI command has a corresponding cmd_* in sdlc.sh, executor.sh, or
# other cli/lib modules sourced by sdlc.sh (setup, ado, etc.).
EXECUTOR_FILE="${PLATFORM_DIR}/cli/lib/executor.sh"
SETUP_FILE="${PLATFORM_DIR}/cli/lib/setup.sh"
ADO_FILE="${PLATFORM_DIR}/cli/lib/ado.sh"
HANDLER_GREP_FILES=( "$CLI_FILE" "$EXECUTOR_FILE" "$SETUP_FILE" "$ADO_FILE" )
for _hf in "${PLATFORM_DIR}/cli/commands"/*.sh; do
  [[ -f "$_hf" ]] && HANDLER_GREP_FILES+=( "$_hf" )
done
unset _hf
missing_handlers=()

for cmd in "${cli_commands[@]}"; do
  # Convert hyphenated names to underscore for function names.
  func_name="cmd_${cmd//-/_}"

  # A command is considered handled if any of:
  #   1. A top-level `cmd_<name>() {` exists in one of the handler files, OR
  #   2. The main() dispatcher routes this command into an inline `case ... esac`
  #      block (e.g. `repos) case "${1:-help}" in ...`), OR
  #   3. A prefix-family of subcommand handlers exists (cmd_<name>_*()) —
  #      covers dispatchers like `repos` → `cmd_repos_setup`, `cmd_repos_check`.
  if grep -q "^${func_name}()" "${HANDLER_GREP_FILES[@]}" 2>/dev/null; then
    continue
  fi
  if grep -qE "^[[:space:]]+${cmd}\)[[:space:]]*case[[:space:]]" "$CLI_FILE" 2>/dev/null; then
    continue
  fi
  if grep -qE "^${func_name}_[a-z_]+\(\)" "${HANDLER_GREP_FILES[@]}" 2>/dev/null; then
    continue
  fi
  missing_handlers+=("$cmd")
done

if [[ ${#missing_handlers[@]} -eq 0 ]]; then
  log_success "All CLI commands have handler functions"
else
  log_warn "CLI commands without handler functions (${#missing_handlers[@]}):"
  printf '%s\n' "${missing_handlers[@]}" | sed 's/^/  - sdlc /'
fi

# ============================================================================
# STEP 4: Validate IDE Command Files Have Proper Headers
# ============================================================================

log_section "IDE Command File Validation"

missing_headers=()
if [[ "$SKIP_IDE_COMMANDS" -eq 1 ]]; then
  log_info "IDE command file checks skipped (no .claude/commands in CI)."
else
for cmd in "${ide_commands[@]}"; do
  cmd_file="${COMMANDS_DIR}/${cmd}.md"

  if [[ ! -f "$cmd_file" ]]; then
    missing_headers+=("$cmd")
    continue
  fi

  # Check if file starts with # /project:command-name
  if ! head -1 "$cmd_file" | grep -q "^# /project:"; then
    log_warn "Missing proper header in ${cmd}.md (should start with '# /project:${cmd}')"
  fi
done
fi

if [[ "$SKIP_IDE_COMMANDS" -eq 1 ]]; then
  :
elif [[ ${#missing_headers[@]} -eq 0 ]]; then
  log_success "All IDE commands have proper file headers"
else
  log_warn "IDE command files missing (${#missing_headers[@]}):"
  printf '%s\n' "${missing_headers[@]}" | sed 's/^/  - \/project:/'
fi

# ============================================================================
# STEP 5: Check Command Registry is Up to Date
# ============================================================================

log_section "Command Registry Validation"

if [[ "$SKIP_IDE_COMMANDS" -eq 1 ]]; then
  log_warn "Command registry check skipped (no .claude/commands)."
elif [[ ! -f "$REGISTRY_FILE" ]]; then
  log_warn "COMMANDS_REGISTRY.md not found"
else
  # Check if registry mentions key commands
  registry_mentions=0
  for cmd in "${ide_commands[@]:0:5}"; do
    if grep -q "$cmd" "$REGISTRY_FILE"; then
      registry_mentions=$((registry_mentions + 1))
    fi
  done

  if [[ $registry_mentions -gt 0 ]]; then
    log_success "COMMANDS_REGISTRY.md appears to be populated"
  else
    log_warn "COMMANDS_REGISTRY.md may need updating with current commands"
  fi
fi

# ============================================================================
# STEP 6: Final Report
# ============================================================================

log_section "Summary"

total_issues=$((${#missing_handlers[@]} + ${#missing_headers[@]}))

if [[ "$SKIP_IDE_COMMANDS" -eq 1 && ${#missing_handlers[@]} -eq 0 ]]; then
  log_success "Command consistency check PASSED ✓ (CLI only — IDE checks skipped in CI)"
  echo ""
  exit 0
fi

if [[ $total_issues -eq 0 ]]; then
  log_success "Command consistency check PASSED ✓"
  echo ""
  echo "CLI commands ($(/bin/bash -c "echo ${#cli_commands[@]}")) and IDE commands ($(/bin/bash -c "echo ${#ide_commands[@]}")) are properly structured."
  echo ""
  exit 0
else
  log_warn "Found $total_issues command consistency issues"
  echo ""
  echo "Run with verbose mode to see detailed recommendations:"
  echo "  bash scripts/validate-commands.sh ${PLATFORM_DIR} --verbose"
  echo ""
  exit 1
fi
