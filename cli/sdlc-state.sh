#!/bin/bash

################################################################################
# AI-SDLC SDLC State Management
# Single JSON source of truth: .sdlc/state.json
# Handles role, stack, stage context persistence across shell sessions
################################################################################

set -e

# ============================================================================
# STATE HELPERS
# ============================================================================

# Get state file path (use project dir or current dir)
_state_file() {
  local project_dir="${SDLC_PROJECT_DIR:-.}"
  echo "${project_dir}/.sdlc/state.json"
}

# Initialize state if missing
init_state() {
  local state_file="$(_state_file)"
  mkdir -p "$(dirname "$state_file")"

  if [[ ! -f "$state_file" ]]; then
    cat > "$state_file" << 'JSON'
{
  "version": "2.0.0",
  "created": "TIMESTAMP",
  "updated": "TIMESTAMP",
  "context": {
    "role": null,
    "stack": null,
    "stage": null,
    "project_dir": null,
    "platform_dir": null
  },
  "history": [],
  "gate_acknowledgments": [],
  "token_spent": {},
  "memory_synced_at": null
}
JSON
    # Fix timestamps
    local iso_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    sed -i "s/TIMESTAMP/$iso_ts/g" "$state_file"
  fi
}

# Save context to state file (atomic)
save_context() {
  local role="${1:-}" stack="${2:-}" stage="${3:-}"

  init_state

  local state_file="$(_state_file)"
  local tmp_state="${state_file}.tmp.$$"
  local iso_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if ! command -v jq &> /dev/null; then
    # Fallback: simple sed-based update (jq preferred but not required)
    log_warn "jq not found — using simple text updates"
    cp "$state_file" "$tmp_state"
    # Very basic: just update the JSON values (not perfectly safe but functional)
    sed -i "s/\"role\": null/\"role\": \"$role\"/g" "$tmp_state"
    sed -i "s/\"stack\": null/\"stack\": \"$stack\"/g" "$tmp_state"
    sed -i "s/\"stage\": null/\"stage\": \"$stage\"/g" "$tmp_state"
    sed -i "s/\"updated\": \"[^\"]*\"/\"updated\": \"$iso_ts\"/g" "$tmp_state"
    mv "$tmp_state" "$state_file"
    return 0
  fi

  # jq atomic update
  jq \
    --arg role "$role" \
    --arg stack "$stack" \
    --arg stage "$stage" \
    --arg ts "$iso_ts" \
    --arg proj_dir "${SDLC_PROJECT_DIR}" \
    --arg plat_dir "${SDLC_PLATFORM_DIR}" \
    '.context |= {
      role: (if $role == "" then .role else $role end),
      stack: (if $stack == "" then .stack else $stack end),
      stage: (if $stage == "" then .stage else $stage end),
      project_dir: (if $proj_dir == "" then .project_dir else $proj_dir end),
      platform_dir: (if $plat_dir == "" then .platform_dir else $plat_dir end)
    } |
    .updated = $ts |
    if .history | index({role: $role, stack: $stack, stage: $stage, timestamp: $ts}) == null then
      .history += [{role: $role, stack: $stack, stage: $stage, timestamp: $ts}]
    else . end' \
    "$state_file" > "$tmp_state" && mv "$tmp_state" "$state_file"
}

# Load context from state file
load_context() {
  local state_file="$(_state_file)"
  init_state

  if ! command -v jq &> /dev/null; then
    log_warn "jq not found — context may be incomplete"
    return 0
  fi

  if [[ -f "$state_file" ]]; then
    local role=$(jq -r '.context.role // empty' "$state_file" 2>/dev/null || echo "")
    local stack=$(jq -r '.context.stack // empty' "$state_file" 2>/dev/null || echo "")
    local stage=$(jq -r '.context.stage // empty' "$state_file" 2>/dev/null || echo "")

    # Export to env
    [[ -n "$role" ]] && SDLC_ROLE="$role"
    [[ -n "$stack" ]] && SDLC_STACK="$stack"
    [[ -n "$stage" ]] && SDLC_STAGE="$stage"
  fi
}

# Get specific context value
get_context_value() {
  local key="$1"
  local state_file="$(_state_file)"
  init_state

  if command -v jq &> /dev/null; then
    jq -r ".context.${key} // empty" "$state_file" 2>/dev/null || echo ""
  else
    return 1
  fi
}

# Record gate acknowledgment
record_gate_ack() {
  local gate_id="$1" ado_id="$2" reason="${3:-User acknowledged}"
  local state_file="$(_state_file)"

  init_state

  if ! command -v jq &> /dev/null; then
    log_warn "Cannot record gate without jq"
    return 0
  fi

  local tmp_state="${state_file}.tmp.$$"
  local iso_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  jq \
    --arg gate "$gate_id" \
    --arg ado "$ado_id" \
    --arg reason "$reason" \
    --arg ts "$iso_ts" \
    '.gate_acknowledgments += [{"gate": $gate, "ado_id": $ado, "reason": $reason, "timestamp": $ts}]' \
    "$state_file" > "$tmp_state" && mv "$tmp_state" "$state_file"
}

# Record token spend
record_token_spend() {
  local stage="$1" role="$2" model="$3" tokens="$4"
  local state_file="$(_state_file)"

  init_state

  if ! command -v jq &> /dev/null; then
    log_warn "Cannot record tokens without jq"
    return 0
  fi

  local tmp_state="${state_file}.tmp.$$"
  local key="${stage}:${role}:${model}"

  jq \
    --arg key "$key" \
    --arg tokens "$tokens" \
    '.token_spent[$key] = ((.token_spent[$key] // 0) + ($tokens | tonumber))' \
    "$state_file" > "$tmp_state" && mv "$tmp_state" "$state_file"
}

# Get total token spend for stage
get_token_spend() {
  local stage="$1"
  local role="${2:-}"
  local state_file="$(_state_file)"

  init_state

  if ! command -v jq &> /dev/null; then
    return 1
  fi

  if [[ -z "$role" ]]; then
    # Sum all for stage
    jq \
      --arg stage "$stage" \
      '[.token_spent | to_entries[] | select(.key | startswith($stage)) | .value] | add // 0' \
      "$state_file" 2>/dev/null || echo "0"
  else
    # Sum for stage + role
    jq \
      --arg key "${stage}:${role}" \
      '.token_spent[$key] // 0' \
      "$state_file" 2>/dev/null || echo "0"
  fi
}

# Show full state
show_state() {
  local state_file="$(_state_file)"
  init_state

  if command -v jq &> /dev/null; then
    jq '.' "$state_file" 2>/dev/null || cat "$state_file"
  else
    cat "$state_file"
  fi
}

# Reset state (for testing/cleanup)
reset_state() {
  local state_file="$(_state_file)"
  rm -f "$state_file"
  init_state
  echo "State reset"
}

# ============================================================================
# COMMAND EXPORTS (for use by cli/sdlc.sh)
# ============================================================================

# If called directly, process command
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cmd="${1:-show}"
  case "$cmd" in
    init)     init_state ;;
    load)     load_context ;;
    save)     save_context "$2" "$3" "$4" ;;
    get)      get_context_value "$2" ;;
    ack)      record_gate_ack "$2" "$3" "$4" ;;
    token)    record_token_spend "$2" "$3" "$4" "$5" ;;
    spend)    get_token_spend "$2" "$3" ;;
    show)     show_state ;;
    reset)    reset_state ;;
    *)        echo "Unknown command: $cmd"; exit 1 ;;
  esac
fi
