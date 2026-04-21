#!/bin/bash

################################################################################
# Gate Metrics Tracker
#
# Tracks gate performance metrics including:
# - Gate start/end times and duration
# - Human wait time (findings presented -> user responded)
# - User decision (APPROVED/SKIP/REJECTED/PAUSED)
# - Criteria pass/fail counts
# - Token usage
# - Retry counts
#
# Metrics are written to .sdlc/metrics/gate-metrics.jsonl (one JSON per line)
#
# Usage:
#   source gate-metrics-tracker.sh
#   gate_start G1
#   gate_present G1
#   gate_decide G1 APPROVED
#   gate_report
#
################################################################################

# Note: We avoid 'set -e' to prevent errors from atomic_write calls from halting script execution
# (errors are logged but shouldn't prevent function execution)
set -uo pipefail

# Define base paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
METRICS_DIR="${PROJECT_ROOT}/.sdlc/metrics"
METRICS_FILE="${METRICS_DIR}/gate-metrics.jsonl"
GATE_STATE_FILE="${METRICS_DIR}/.gate-active.json"

# Create metrics directory if it doesn't exist
mkdir -p "$METRICS_DIR"

# Load atomic I/O library for multi-user safety
if [ -f "$SCRIPT_DIR/lib/atomic-io.sh" ]; then
    source "$SCRIPT_DIR/lib/atomic-io.sh"
    USE_ATOMIC=true
else
    echo "[gate-metrics-tracker] WARN: atomic-io.sh not found, running without file locking" >&2
    USE_ATOMIC=false
fi

# In-memory tracking of gate state during current session
declare -A gate_start_times
declare -A gate_findings_times
declare -A gate_response_times
declare -A gate_end_times
declare -A gate_decisions
declare -A gate_criteria_met
declare -A gate_criteria_total
declare -A gate_tokens
declare -A gate_retries
declare -A gate_stage_names

# Get current timestamp in ISO 8601 format
_now() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Get current timestamp in seconds since epoch
_now_epoch() {
    date +%s
}

# Convert seconds to decimal minutes
_seconds_to_minutes() {
    local seconds=$1
    echo "scale=2; $seconds / 60" | bc
}

# Get sprint ID (based on date or from environment)
_get_sprint_id() {
    if [[ -n "${SPRINT_ID:-}" ]]; then
        echo "$SPRINT_ID"
    else
        # Format: sprint-YYYY-WW (week-based)
        date -u '+sprint-%Y-W%V'
    fi
}

# Get user ID (from environment or git)
_get_user_id() {
    if [[ -n "${USER_ID:-}" ]]; then
        echo "$USER_ID"
    elif [[ -n "${GITHUB_USER:-}" ]]; then
        echo "$GITHUB_USER"
    else
        git config user.email 2>/dev/null || echo "unknown@example.com"
    fi
}

# Get workflow run ID (from environment or generate)
_get_workflow_run_id() {
    if [[ -n "${WORKFLOW_RUN_ID:-}" ]]; then
        echo "$WORKFLOW_RUN_ID"
    else
        echo "run-$(date +%Y-%m-%d-%H%M%S)-$$"
    fi
}

# Resolve gate ID from stage name if not explicitly provided
# Maps stage names (requirement-intake, planning, design, etc.) to gate IDs (G1-G10)
resolve_gate_id() {
    local stage="$1"
    case "$stage" in
        *01*|*requirement*|*intake*)            echo "G1" ;;
        *02*|*pre-grooming*|*pregrooming*)      echo "G2" ;;
        *03*|*grooming*)                        echo "G3" ;;
        *04*|*tech-design*|*design*)            echo "G4" ;;
        *05*|*sprint-ready*|*sprint*)           echo "G5" ;;
        *06*|*dev*|*implementation*)            echo "G6" ;;
        *07*|*sit*|*integration*)               echo "G7" ;;
        *08*|*pp*|*pre-prod*)                   echo "G8" ;;
        *09*|*perf*|*performance*)              echo "G9" ;;
        *10*|*release*|*summary*)               echo "G10" ;;
        *)                                      echo "G0" ;;  # Unknown stage
    esac
}

################################################################################
# Persistent State Management Functions
################################################################################

# _load_gate_state <gate_id>
# Loads gate state from persistent JSON file if it exists
_load_gate_state() {
    local gate_id=$1

    if [[ ! -f "$GATE_STATE_FILE" ]]; then
        return 0
    fi

    if [[ "$USE_ATOMIC" == "true" ]]; then
        local content
        content=$(locked_read "$GATE_STATE_FILE" 2>/dev/null || echo "{}")
    else
        local content
        content=$(cat "$GATE_STATE_FILE" 2>/dev/null || echo "{}")
    fi

    # Parse JSON and populate in-memory arrays
    if command -v jq &>/dev/null; then
        local start_time findings_time response_time end_time decision criteria_met criteria_total tokens retries stage_name

        start_time=$(echo "$content" | jq -r ".[\"$gate_id\"].start_time // empty" 2>/dev/null || echo "")
        findings_time=$(echo "$content" | jq -r ".[\"$gate_id\"].findings_time // empty" 2>/dev/null || echo "")
        response_time=$(echo "$content" | jq -r ".[\"$gate_id\"].response_time // empty" 2>/dev/null || echo "")
        end_time=$(echo "$content" | jq -r ".[\"$gate_id\"].end_time // empty" 2>/dev/null || echo "")
        decision=$(echo "$content" | jq -r ".[\"$gate_id\"].decision // empty" 2>/dev/null || echo "")
        criteria_met=$(echo "$content" | jq -r ".[\"$gate_id\"].criteria_met // empty" 2>/dev/null || echo "")
        criteria_total=$(echo "$content" | jq -r ".[\"$gate_id\"].criteria_total // empty" 2>/dev/null || echo "")
        tokens=$(echo "$content" | jq -r ".[\"$gate_id\"].tokens // empty" 2>/dev/null || echo "")
        retries=$(echo "$content" | jq -r ".[\"$gate_id\"].retries // empty" 2>/dev/null || echo "")
        stage_name=$(echo "$content" | jq -r ".[\"$gate_id\"].stage_name // empty" 2>/dev/null || echo "")

        [[ -n "$start_time" ]] && gate_start_times["$gate_id"]=$start_time
        [[ -n "$findings_time" ]] && gate_findings_times["$gate_id"]=$findings_time
        [[ -n "$response_time" ]] && gate_response_times["$gate_id"]=$response_time
        [[ -n "$end_time" ]] && gate_end_times["$gate_id"]=$end_time
        [[ -n "$decision" ]] && gate_decisions["$gate_id"]=$decision
        [[ -n "$criteria_met" ]] && gate_criteria_met["$gate_id"]=$criteria_met
        [[ -n "$criteria_total" ]] && gate_criteria_total["$gate_id"]=$criteria_total
        [[ -n "$tokens" ]] && gate_tokens["$gate_id"]=$tokens
        [[ -n "$retries" ]] && gate_retries["$gate_id"]=$retries
        [[ -n "$stage_name" ]] && gate_stage_names["$gate_id"]=$stage_name
    fi
}

# _save_gate_state <gate_id>
# Saves gate state to persistent JSON file for cross-invocation access
_save_gate_state() {
    local gate_id=$1

    # Build JSON object for this gate
    local gate_json=$(cat <<EOF
{
  "start_time": "${gate_start_times[$gate_id]:-}",
  "findings_time": "${gate_findings_times[$gate_id]:-}",
  "response_time": "${gate_response_times[$gate_id]:-}",
  "end_time": "${gate_end_times[$gate_id]:-}",
  "decision": "${gate_decisions[$gate_id]:-}",
  "criteria_met": ${gate_criteria_met[$gate_id]:-0},
  "criteria_total": ${gate_criteria_total[$gate_id]:-0},
  "tokens": ${gate_tokens[$gate_id]:-0},
  "retries": ${gate_retries[$gate_id]:-0},
  "stage_name": "${gate_stage_names[$gate_id]:-}"
}
EOF
)

    if [[ "$USE_ATOMIC" == "true" ]]; then
        # Read existing state, update gate entry, write back atomically
        if [[ -f "$GATE_STATE_FILE" ]]; then
            local updated_state
            updated_state=$(locked_read "$GATE_STATE_FILE" 2>/dev/null | jq ".\"$gate_id\" = $gate_json" 2>/dev/null) || updated_state="{\"$gate_id\": $gate_json}"
            atomic_write "$GATE_STATE_FILE" "$updated_state" 2>/dev/null || true
        else
            # Create new state file with this gate
            local initial_state="{\"$gate_id\": $gate_json}"
            atomic_write "$GATE_STATE_FILE" "$initial_state" 2>/dev/null || true
        fi
    else
        # Fallback: non-atomic write
        if [[ -f "$GATE_STATE_FILE" ]]; then
            local temp_file="${GATE_STATE_FILE}.tmp.$$"
            if cat "$GATE_STATE_FILE" | jq ".\"$gate_id\" = $gate_json" > "$temp_file" 2>/dev/null; then
                mv "$temp_file" "$GATE_STATE_FILE"
            fi
        else
            echo "{\"$gate_id\": $gate_json}" > "$GATE_STATE_FILE"
        fi
    fi

    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: Saved gate state for $gate_id to $GATE_STATE_FILE" >&2
    fi
}

################################################################################
# Public API Functions
################################################################################

# gate_start <gate_id> [stage_name]
# Records the start of gate validation
# Args:
#   gate_id: Gate identifier (G1-G10) or stage name to resolve
#   stage_name: (optional) Name of stage containing gate
gate_start() {
    local gate_id=$1
    local stage_name=${2:-"unknown"}
    local now=$(_now)

    # If gate_id looks like a stage name (not G1-G10), resolve it
    if [[ ! "$gate_id" =~ ^G[0-9]+$ ]]; then
        stage_name="$gate_id"
        gate_id=$(resolve_gate_id "$stage_name")
    fi

    # Load any existing state for this gate
    _load_gate_state "$gate_id"

    gate_start_times["$gate_id"]=$now
    gate_stage_names["$gate_id"]=$stage_name

    # Persist state immediately
    _save_gate_state "$gate_id"

    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: gate_start $gate_id at $now (stage: $stage_name)" >&2
    fi
}

# gate_present <gate_id>
# Records when findings were presented to the user
# Args:
#   gate_id: Gate identifier (G1-G10)
gate_present() {
    local gate_id=$1
    local now=$(_now)

    # Load existing state for this gate
    _load_gate_state "$gate_id"

    gate_findings_times["$gate_id"]=$now

    # Persist state immediately
    _save_gate_state "$gate_id"

    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: gate_present $gate_id at $now" >&2
    fi
}

# gate_decide <gate_id> <decision> [criteria_met] [criteria_total] [token_spent] [retry_count]
# Records user decision and computes gate durations
# Args:
#   gate_id: Gate identifier (G1-G10)
#   decision: APPROVED | SKIP | REJECTED | PAUSED | ERROR
#   criteria_met: (optional) Number of criteria that passed (default: 0)
#   criteria_total: (optional) Total criteria evaluated (default: 0)
#   token_spent: (optional) Tokens consumed (default: 0)
#   retry_count: (optional) Number of retries (default: 0)
gate_decide() {
    local gate_id=$1
    local decision=$2
    local criteria_met=${3:-0}
    local criteria_total=${4:-0}
    local token_spent=${5:-0}
    local retry_count=${6:-0}
    local now=$(_now)
    local now_epoch=$(_now_epoch)

    # Validate decision value
    case "$decision" in
        APPROVED|SKIP|REJECTED|PAUSED|ERROR) ;;
        *)
            echo "ERROR: Invalid decision '$decision'. Must be APPROVED|SKIP|REJECTED|PAUSED|ERROR" >&2
            return 1
            ;;
    esac

    # Load existing state for this gate (from persistent storage)
    _load_gate_state "$gate_id"

    # Store decision and criteria
    gate_decisions["$gate_id"]=$decision
    gate_criteria_met["$gate_id"]=$criteria_met
    gate_criteria_total["$gate_id"]=$criteria_total
    gate_tokens["$gate_id"]=$token_spent
    gate_retries["$gate_id"]=$retry_count
    gate_response_times["$gate_id"]=$now
    gate_end_times["$gate_id"]=$now

    # Persist state immediately
    _save_gate_state "$gate_id"

    # Write metrics to file (using atomic append if available)
    _write_gate_metric "$gate_id"

    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: gate_decide $gate_id = $decision at $now" >&2
    fi
}

# gate_report
# Prints summary of all gate metrics collected in current session
gate_report() {
    local total_gates=0
    local approved_gates=0
    local total_wait_time=0

    echo ""
    echo "================== GATE METRICS SUMMARY =================="
    echo "Report generated: $(_now)"
    echo "Sprint: $(_get_sprint_id)"
    echo ""

    if [[ ${#gate_decisions[@]} -eq 0 ]]; then
        echo "No gate decisions recorded."
        echo ""
        return 0
    fi

    echo "GATE DECISIONS:"
    echo "Gate | Stage | Decision  | Duration | Wait Time | Criteria | Tokens | Retries"
    echo "     |       |           | (min)    | (min)     | Met/Tot  |        |"
    echo "-----+-------+-----------+----------+-----------+----------+--------+---------"

    for gate_id in $(printf '%s\n' "${!gate_decisions[@]}" | sort); do
        local decision=${gate_decisions[$gate_id]}
        local stage=${gate_stage_names[$gate_id]:-unknown}
        local criteria_met=${gate_criteria_met[$gate_id]:-0}
        local criteria_total=${gate_criteria_total[$gate_id]:-0}
        local tokens=${gate_tokens[$gate_id]:-0}
        local retries=${gate_retries[$gate_id]:-0}

        # Calculate durations
        local duration_min="-"
        local wait_min="-"

        if [[ -n "${gate_start_times[$gate_id]:-}" && -n "${gate_end_times[$gate_id]:-}" ]]; then
            local start_epoch=$(date -d "${gate_start_times[$gate_id]}" +%s 2>/dev/null || echo 0)
            local end_epoch=$(date -d "${gate_end_times[$gate_id]}" +%s 2>/dev/null || echo 0)
            if [[ $start_epoch -gt 0 && $end_epoch -gt 0 ]]; then
                local duration=$((end_epoch - start_epoch))
                duration_min=$(echo "scale=1; $duration / 60" | bc)
            fi
        fi

        if [[ -n "${gate_findings_times[$gate_id]:-}" && -n "${gate_response_times[$gate_id]:-}" ]]; then
            local findings_epoch=$(date -d "${gate_findings_times[$gate_id]}" +%s 2>/dev/null || echo 0)
            local response_epoch=$(date -d "${gate_response_times[$gate_id]}" +%s 2>/dev/null || echo 0)
            if [[ $findings_epoch -gt 0 && $response_epoch -gt 0 ]]; then
                local wait=$((response_epoch - findings_epoch))
                wait_min=$(echo "scale=1; $wait / 60" | bc)
                total_wait_time=$(echo "$total_wait_time + $wait" | bc)
            fi
        fi

        local criteria_str="${criteria_met}/${criteria_total}"

        printf "%-4s | %-5s | %-9s | %8s | %9s | %8s | %6s | %7s\n" \
            "$gate_id" "$stage" "$decision" "$duration_min" "$wait_min" "$criteria_str" "$tokens" "$retries"

        total_gates=$((total_gates + 1))
        if [[ "$decision" == "APPROVED" ]]; then
            approved_gates=$((approved_gates + 1))
        fi
    done

    echo ""
    echo "SUMMARY:"
    echo "Total gates: $total_gates"
    echo "Approved gates: $approved_gates"
    if [[ $total_gates -gt 0 ]]; then
        local approval_rate=$((approved_gates * 100 / total_gates))
        echo "Approval rate: ${approval_rate}%"
    fi

    if [[ $(echo "$total_wait_time > 0" | bc) -eq 1 ]]; then
        local avg_wait=$(echo "scale=1; $total_wait_time / 60 / $total_gates" | bc)
        echo "Total human wait time: $(echo "scale=1; $total_wait_time / 60" | bc) minutes"
        echo "Average wait per gate: $avg_wait minutes"
    fi

    echo "==========================================================="
    echo ""
}

################################################################################
# Internal Functions
################################################################################

# _write_gate_metric <gate_id>
# Writes a single gate metric record to the JSONL file
_write_gate_metric() {
    local gate_id=$1

    # Get all values with defaults
    local start_time=${gate_start_times[$gate_id]:-$(_now)}
    local findings_time=${gate_findings_times[$gate_id]:-""}
    local response_time=${gate_response_times[$gate_id]:-$(_now)}
    local end_time=${gate_end_times[$gate_id]:-$(_now)}
    local decision=${gate_decisions[$gate_id]:-"ERROR"}
    local criteria_met=${gate_criteria_met[$gate_id]:-0}
    local criteria_total=${gate_criteria_total[$gate_id]:-0}
    local token_spent=${gate_tokens[$gate_id]:-0}
    local retry_count=${gate_retries[$gate_id]:-0}
    local stage_name=${gate_stage_names[$gate_id]:-"unknown"}

    # Calculate durations in seconds
    local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo 0)
    local end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo 0)
    local gate_duration_sec=0
    if [[ $start_epoch -gt 0 && $end_epoch -gt 0 ]]; then
        gate_duration_sec=$((end_epoch - start_epoch))
    fi

    # Calculate human wait time (findings -> response)
    local human_wait_sec=0
    if [[ -n "$findings_time" ]]; then
        local findings_epoch=$(date -d "$findings_time" +%s 2>/dev/null || echo 0)
        local response_epoch=$(date -d "$response_time" +%s 2>/dev/null || echo 0)
        if [[ $findings_epoch -gt 0 && $response_epoch -gt 0 ]]; then
            human_wait_sec=$((response_epoch - findings_epoch))
        fi
    fi

    # Convert to decimal minutes
    local gate_duration_min=$(echo "scale=2; $gate_duration_sec / 60" | bc)
    local human_wait_min=$(echo "scale=2; $human_wait_sec / 60" | bc)

    # Calculate criteria percentage
    local criteria_percent=0
    if [[ $criteria_total -gt 0 ]]; then
        criteria_percent=$((criteria_met * 100 / criteria_total))
    fi

    # Build compact JSON object (single-line for JSONL format)
    # Using jq to ensure proper JSON escaping and compactness
    local json
    json=$(echo "null" | jq -c \
        --arg gate_id "$gate_id" \
        --arg sprint_id "$(_get_sprint_id)" \
        --arg stage_name "$stage_name" \
        --arg gate_start_time "$start_time" \
        --arg findings_presented_time "$findings_time" \
        --arg user_responded_time "$response_time" \
        --arg gate_end_time "$end_time" \
        --arg gate_duration_minutes "${gate_duration_min:-0}" \
        --arg human_wait_minutes "${human_wait_min:-0}" \
        --arg decision "$decision" \
        --arg criteria_met "${criteria_met:-0}" \
        --arg criteria_total "${criteria_total:-0}" \
        --arg criteria_met_percent "${criteria_percent:-0}" \
        --arg token_spent "${token_spent:-0}" \
        --arg retry_count "${retry_count:-0}" \
        --arg user_id "$(_get_user_id)" \
        --arg workflow_run_id "$(_get_workflow_run_id)" \
        --arg timestamp_recorded "$(_now)" \
        '{
            gate_id: $gate_id,
            sprint_id: $sprint_id,
            stage_name: $stage_name,
            gate_start_time: $gate_start_time,
            findings_presented_time: $findings_presented_time,
            user_responded_time: $user_responded_time,
            gate_end_time: $gate_end_time,
            gate_duration_minutes: ($gate_duration_minutes | tonumber),
            human_wait_minutes: ($human_wait_minutes | tonumber),
            decision: $decision,
            criteria_met: ($criteria_met | tonumber),
            criteria_total: ($criteria_total | tonumber),
            criteria_met_percent: ($criteria_met_percent | tonumber),
            token_spent: ($token_spent | tonumber),
            retry_count: ($retry_count | tonumber),
            user_id: $user_id,
            workflow_run_id: $workflow_run_id,
            timestamp_recorded: $timestamp_recorded
        }')

    # Append to JSONL file with atomic safety if available
    if [[ "$USE_ATOMIC" == "true" ]]; then
        atomic_append "$METRICS_FILE" "$json"
    else
        echo "$json" >> "$METRICS_FILE"
    fi

    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: Wrote metric for $gate_id to $METRICS_FILE" >&2
    fi
}

# Export functions for use in other scripts
export -f gate_start gate_present gate_decide gate_report resolve_gate_id
export METRICS_FILE METRICS_DIR GATE_STATE_FILE

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly, show usage
    echo "Gate Metrics Tracker"
    echo ""
    echo "Usage: source gate-metrics-tracker.sh"
    echo ""
    echo "Functions available:"
    echo "  gate_start <gate_id> [stage_name]"
    echo "  gate_present <gate_id>"
    echo "  gate_decide <gate_id> <decision> [criteria_met] [criteria_total] [token_spent] [retry_count]"
    echo "  gate_report"
    echo ""
    echo "Example:"
    echo "  source gate-metrics-tracker.sh"
    echo "  gate_start G1 planning"
    echo "  gate_present G1"
    echo "  gate_decide G1 APPROVED 8 10 2847 0"
    echo "  gate_report"
fi
