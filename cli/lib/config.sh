#!/usr/bin/env bash
# cli/lib/config.sh — Configuration, validation, constants, and symlink setup
# Part of AI SDLC Platform v2.0.0
# Depends on: logging.sh
# -----------------------------------------------------------

# ============================================================================
# CONSTANTS
# ============================================================================

SDLC_VERSION="2.0.0"
CONFIG_DIR="${HOME}/.sdlc"

# Roles (8)
ROLES=(product backend frontend qa performance ui tpm boss)

# Stages (15) — MUST match directory names under ${PLATFORM_DIR}/stages/ (see STAGE.md per folder)
STAGES=(
  01-requirement-intake
  02-prd-review
  03-pre-grooming
  04-grooming
  05-system-design
  06-design-review
  07-task-breakdown
  08-implementation
  09-code-review
  10-test-design
  11-test-execution
  12-commit-push
  13-documentation
  14-release-signoff
  15-summary-close
)

# Tech stacks (6)
STACKS=(java kotlin-android swift-ios react-native jmeter figma-design)

# Stack → variant filename mapping
declare -A STACK_VARIANT_MAP=(
  [java]="java-backend"
  [kotlin-android]="kotlin-android"
  [swift-ios]="swift-ios"
  [react-native]="react-native"
  [jmeter]="jmeter-perf"
  [figma-design]="figma-design"
)

# ============================================================================
# PATH RESOLUTION
# ============================================================================

# Resolve the real directory of the sdlc installation (follows symlinks)
_resolve_source() {
  local source="$1"
  while [[ -L "$source" ]]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}

# ============================================================================
# SUBSYSTEM LOADERS
# ============================================================================

# Load state management (sdlc-state.sh) if available
_load_state_management() {
  local state_script="${PLATFORM_DIR}/cli/sdlc-state.sh"
  if [[ -f "$state_script" ]]; then
    # shellcheck source=/dev/null
    source "$state_script"
  fi
}

# Load token enforcement (token-blocker.sh) if available
_load_token_enforcement() {
  local token_script="${PLATFORM_DIR}/scripts/token-blocker.sh"
  if [[ -f "$token_script" ]]; then
    # shellcheck source=/dev/null
    source "$token_script"
  fi
}

# ============================================================================
# CONFIG FILE I/O
# ============================================================================

load_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ -f "$CONFIG_DIR/config" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_DIR/config"
  fi
}

save_config() {
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_DIR/config" <<EOF
SDLC_ROLE="${SDLC_ROLE:-}"
SDLC_STACK="${SDLC_STACK:-}"
SDLC_STAGE="${SDLC_STAGE:-}"
SDLC_PROJECT_DIR="${SDLC_PROJECT_DIR:-}"
SDLC_PLATFORM_DIR="${SDLC_PLATFORM_DIR:-$PLATFORM_DIR}"
EOF
}

# Apply KEY=VAL lines from a file; only non-empty values are exported (last file wins for each key).
_merge_env_file() {
  local f="$1"
  [[ -n "$f" && -f "$f" ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue
    [[ "$line" != *=* ]] && continue
    key="${line%%=*}"
    key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
    val="${line#*=}"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
    [[ -z "$val" ]] && continue
    export "${key}=${val}"
  done <"$f"
}

# Load Azure DevOps and MCP-related variables.
# Later files win per key (only non-empty assignments are applied — empty lines do not clear earlier values).
# Order:
#   1) SDL_AZURE_DEVOPS_ENV_FILE — optional explicit path (any filename)
#   2) ~/.sdlc/ado.env — one PAT for all service repos (recommended)
#   3) ${PLATFORM_DIR}/env/.env — platform checkout (team or personal)
#   4) ${SDLC_PLATFORM_DIR}/env/.env — when ~/.sdlc/config points at another checkout
#   5) ${SDLC_PROJECT_DIR:-$PWD}/env/.env — current app repo overrides
_load_env() {
  mkdir -p "$CONFIG_DIR"
  _merge_env_file "${SDL_AZURE_DEVOPS_ENV_FILE:-}"
  _merge_env_file "${CONFIG_DIR}/ado.env"
  _merge_env_file "${PLATFORM_DIR}/env/.env"
  # ~/.sdlc/config may point SDLC_PLATFORM_DIR at a different checkout; merge if set
  if [[ -n "${SDLC_PLATFORM_DIR:-}" && "${SDLC_PLATFORM_DIR}" != "${PLATFORM_DIR}" ]]; then
    _merge_env_file "${SDLC_PLATFORM_DIR}/env/.env"
  fi
  local proj_root="${SDLC_PROJECT_DIR:-$PWD}"
  _merge_env_file "${proj_root}/env/.env"
}

# ============================================================================
# VALIDATORS
# ============================================================================

validate_role() {
  local role="$1"
  for r in "${ROLES[@]}"; do
    if [[ "$r" == "$role" ]]; then
      return 0
    fi
  done
  return 1
}

validate_stage() {
  local stage="$1"
  for s in "${STAGES[@]}"; do
    if [[ "$s" == "$stage" ]]; then
      # Deterministic: stage id must map to stages/<id>/STAGE.md when PLATFORM_DIR is set
      if [[ -n "${PLATFORM_DIR:-}" && ! -f "${PLATFORM_DIR}/stages/${stage}/STAGE.md" ]]; then
        return 1
      fi
      return 0
    fi
  done
  return 1
}

validate_stack() {
  local stack="$1"
  if [[ -z "$stack" ]]; then
    return 0 # Stack is optional
  fi
  for s in "${STACKS[@]}"; do
    if [[ "$s" == "$stack" ]]; then
      return 0
    fi
  done
  return 1
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize all subsystems
_init_systems() {
  _load_state_management
  _load_token_enforcement
  load_config
  _load_env
}

# ============================================================================
# SYMLINK SETUP
# ============================================================================

# Create IDE symlinks (.claude/, .cursor/) pointing to platform content
_setup_symlinks() {
  local role="${1:-product}"
  local project_dir="${SDLC_PROJECT_DIR:-$PWD}"

  # Claude symlinks
  mkdir -p "${project_dir}/.claude"
  ln -sfn "${PLATFORM_DIR}" "${project_dir}/.claude/platform" 2>/dev/null || true
  ln -sfn "${PLATFORM_DIR}/.claude/commands" "${project_dir}/.claude/commands" 2>/dev/null || true
  ln -sfn "${PLATFORM_DIR}/agents" "${project_dir}/.claude/agents" 2>/dev/null || true
  ln -sfn "${PLATFORM_DIR}/templates" "${project_dir}/.claude/templates" 2>/dev/null || true
  ln -sfn "${PLATFORM_DIR}/.claude/rules" "${project_dir}/.claude/rules" 2>/dev/null || true
  ln -sfn "${PLATFORM_DIR}/.claude/skills" "${project_dir}/.claude/skills" 2>/dev/null || true

  # Cursor symlinks (rules from .cursor/rules/ which has symlinks to canonical rules/)
  mkdir -p "${project_dir}/.cursor"
  ln -sfn "${PLATFORM_DIR}/.claude/commands" "${project_dir}/.cursor/commands" 2>/dev/null || true
  ln -sfn "${PLATFORM_DIR}/.cursor/rules" "${project_dir}/.cursor/rules" 2>/dev/null || true
}
