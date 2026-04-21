#!/bin/bash

################################################################################
# ado-state-sync.sh
# State reconciliation sync between local memory and Azure DevOps work items
#
# Purpose:
#   - Pull latest ADO work item state
#   - Compare with local state
#   - Detect and log divergences
#   - Update memory_synced_at timestamp
#   - Handle offline mode gracefully
#
# Usage:
#   ./scripts/ado-state-sync.sh [--pull] [--push] [--offline] [--report]
#
# Environment Variables:
#   SDLC_SYNC_TIMEOUT_SECONDS (default: 30)
#   SDLC_SYNC_MAX_AGE_HOURS (default: 24)
#   SDLC_AUTO_RESOLVE_ARTIFACTS (default: true)
#   SDLC_WORK_DIR (default: .sdlc)
################################################################################

set -euo pipefail

# Import atomic I/O library for safe concurrent file operations
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/atomic-io.sh"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDLC_DIR="${SDLC_WORK_DIR:-.sdlc}"
STATE_FILE="${SDLC_DIR}/state.json"
SYNC_LOG="${SDLC_DIR}/sync-log.json"
PENDING_SYNC="${SDLC_DIR}/pending-sync.json"
METADATA_FILE="${SDLC_DIR}/memory/metadata.json"

SYNC_TIMEOUT="${SDLC_SYNC_TIMEOUT_SECONDS:=30}"
SYNC_MAX_AGE="${SDLC_SYNC_MAX_AGE_HOURS:=24}"
AUTO_RESOLVE="${SDLC_AUTO_RESOLVE_ARTIFACTS:=true}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global state
OPERATION_MODE="pull"  # pull | push | offline | report
STORY_ID=""
ADO_STATE=""
LOCAL_STATE=""
CONFLICT_DETECTED=0
SYNC_SUCCESS=0
OFFLINE_MODE=0

################################################################################
# Utility Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Get current timestamp in ISO 8601 format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Calculate hours since timestamp
hours_since() {
    local timestamp=$1
    if [ -z "$timestamp" ] || [ "$timestamp" = "null" ]; then
        echo "99999"  # Return large number if null
        return
    fi

    local ts_sec=$(date -d "$timestamp" +%s 2>/dev/null || echo 0)
    local now_sec=$(date +%s)
    local diff_sec=$((now_sec - ts_sec))
    local diff_hours=$((diff_sec / 3600))
    echo "$diff_hours"
}

# Validate JSON syntax
validate_json() {
    local file=$1
    if [ ! -f "$file" ]; then
        return 1
    fi
    jq empty "$file" 2>/dev/null && return 0 || return 1
}

# Initialize sync log if needed
init_sync_log() {
    if [ ! -f "$SYNC_LOG" ]; then
        echo "[]" > "$SYNC_LOG"
    fi
}

# Add entry to sync log
log_sync_entry() {
    local operation=$1
    local status=$2
    local details=$3
    local timestamp=$(get_timestamp)

    init_sync_log

    local entry=$(jq -n \
        --arg op "$operation" \
        --arg st "$status" \
        --arg det "$details" \
        --arg ts "$timestamp" \
        '{operation: $op, status: $st, timestamp: $ts, details: $det}')

    atomic_json_array_push "$SYNC_LOG" '.' "$entry"
}

################################################################################
# Story ID Resolution
################################################################################

get_active_story_id() {
    # Try state.json first
    if [ -f "$STATE_FILE" ] && validate_json "$STATE_FILE"; then
        local story=$(jq -r '.metadata.active_story_id // empty' "$STATE_FILE" 2>/dev/null)
        if [ -n "$story" ]; then
            echo "$story"
            return 0
        fi
    fi

    # Try metadata.json
    if [ -f "$METADATA_FILE" ] && validate_json "$METADATA_FILE"; then
        local story=$(jq -r '.active_story_id // empty' "$METADATA_FILE" 2>/dev/null)
        if [ -n "$story" ]; then
            echo "$story"
            return 0
        fi
    fi

    return 1
}

################################################################################
# ADO State Retrieval (MCP Integration)
################################################################################

fetch_ado_state() {
    local story_id=$1

    log_info "Fetching ADO state for story: $story_id"

    # Call ADO MCP to get work item state
    # This would be integrated with the ADO connector
    # For now, we'll set up the framework and call a helper function

    local ado_state_json
    ado_state_json=$(fetch_ado_work_item_state "$story_id" 2>/dev/null) || {
        log_warning "Failed to fetch ADO state"
        return 1
    }

    if [ -z "$ado_state_json" ] || [ "$ado_state_json" = "null" ]; then
        log_warning "ADO returned empty state"
        return 1
    fi

    echo "$ado_state_json"
    return 0
}

# Helper: Fetch ADO work item state (would use ADO MCP)
# This is a template that would be called by the ADO connector
fetch_ado_work_item_state() {
    local story_id=$1

    # In production, this would invoke ADO MCP like:
    # gh api repos/owner/repo/issues/$(story_to_issue_number $story_id)
    # or call Claude with ADO connector to get work item details

    # For now, return a template structure
    jq -n \
        --arg id "$story_id" \
        --arg status "active" \
        --arg assignee "user@org.onmicrosoft.com" \
        --arg updated "$(get_timestamp)" \
        '{
            id: $id,
            status: $status,
            assignee: $assignee,
            tags: ["in-progress"],
            comments_count: 5,
            updated_at: $updated,
            iteration_path: "\\Project\\Sprint 10"
        }'
}

################################################################################
# Local State Retrieval
################################################################################

get_local_state() {
    local story_id=$1
    local local_state_file="${SDLC_DIR}/memory/${story_id}/state.json"

    if [ ! -f "$local_state_file" ]; then
        # Return empty state structure
        jq -n '{status: null, assignee: null, tags: [], updated_at: null}'
        return 0
    fi

    if ! validate_json "$local_state_file"; then
        log_warning "Local state file is invalid JSON: $local_state_file"
        jq -n '{status: null, assignee: null, tags: [], updated_at: null}'
        return 1
    fi

    jq '{
        status: .metadata.status // null,
        assignee: .metadata.assignee // null,
        tags: .metadata.tags // [],
        updated_at: .metadata.updated_at // null,
        synced_at: .metadata.synced_at // null
    }' "$local_state_file"
}

################################################################################
# Conflict Detection
################################################################################

detect_conflicts() {
    local ado_json=$1
    local local_json=$2

    local conflicts=""

    # Check status
    local ado_status=$(echo "$ado_json" | jq -r '.status // empty')
    local local_status=$(echo "$local_json" | jq -r '.status // empty')
    if [ "$ado_status" != "$local_status" ] && [ -n "$ado_status" ] && [ -n "$local_status" ]; then
        conflicts+="status:${local_status}→${ado_status} "
    fi

    # Check assignee
    local ado_assignee=$(echo "$ado_json" | jq -r '.assignee // empty')
    local local_assignee=$(echo "$local_json" | jq -r '.assignee // empty')
    if [ "$ado_assignee" != "$local_assignee" ] && [ -n "$ado_assignee" ] && [ -n "$local_assignee" ]; then
        conflicts+="assignee:${local_assignee}→${ado_assignee} "
    fi

    # Check for ADO newer comments
    local ado_comments=$(echo "$ado_json" | jq '.comments_count // 0')
    if [ "$ado_comments" -gt 0 ]; then
        conflicts+="new_comments:${ado_comments} "
    fi

    if [ -z "$conflicts" ]; then
        return 0  # No conflicts
    else
        echo "$conflicts"
        return 1  # Conflicts found
    fi
}

################################################################################
# State Reconciliation
################################################################################

resolve_status_conflict() {
    local ado_status=$1
    local local_status=$2

    log_warning "Status conflict: local='$local_status' vs ADO='$ado_status'"
    log_info "ADO status takes precedence (source of truth)"

    # In non-interactive mode, ADO wins
    # In interactive mode, user would be prompted
    echo "$ado_status"
}

pull_ado_updates() {
    local story_id=$1
    local ado_json=$2

    log_info "Pulling updates from ADO"

    local local_state_file="${SDLC_DIR}/memory/${story_id}/state.json"

    if [ ! -f "$local_state_file" ]; then
        log_warning "Local state file not found: $local_state_file"
        return 1
    fi

    # Update local state with ADO values using atomic operations
    local status=$(echo "$ado_json" | jq -r '.status')
    local assignee=$(echo "$ado_json" | jq -r '.assignee')
    local tags=$(echo "$ado_json" | jq -c '.tags')
    local updated=$(echo "$ado_json" | jq -r '.updated_at')

    local jq_filter=".metadata.status = \"$status\" |
         .metadata.assignee = \"$assignee\" |
         .metadata.tags = $tags |
         .metadata.updated_at = \"$updated\""

    atomic_json_update "$local_state_file" "$jq_filter"

    log_success "Pulled ADO updates to local state"
    return 0
}

update_sync_timestamp() {
    local timestamp=$(get_timestamp)

    # Update state.json
    if [ -f "$STATE_FILE" ] && validate_json "$STATE_FILE"; then
        atomic_json_update "$STATE_FILE" \
            ".metadata.memory_synced_at = \"$timestamp\" |
             .metadata.sync_status = \"synced\""
    fi

    # Update memory metadata
    if [ -f "$METADATA_FILE" ] && validate_json "$METADATA_FILE"; then
        atomic_json_update "$METADATA_FILE" \
            ".memory_synced_at = \"$timestamp\" |
             .sync_status = \"synced\""
    fi

    log_success "Updated memory_synced_at to $timestamp"
}

check_drift_age() {
    local timestamp=$1
    local hours=$(hours_since "$timestamp")

    if [ "$hours" -ge $((SYNC_MAX_AGE * 2)) ]; then
        log_error "CRITICAL: State drift >$((SYNC_MAX_AGE * 2)) hours"
        return 2
    elif [ "$hours" -ge "$SYNC_MAX_AGE" ]; then
        log_warning "WARNING: State not synced for $hours hours (threshold: $SYNC_MAX_AGE)"
        return 1
    fi

    return 0
}

################################################################################
# Offline Mode
################################################################################

activate_offline_mode() {
    log_warning "Activating offline mode - operating with local state only"
    OFFLINE_MODE=1

    if [ -f "$STATE_FILE" ] && validate_json "$STATE_FILE"; then
        # Preserve last known sync timestamp; only set sync_status to offline
        # This allows us to distinguish between "never synced" (null timestamp)
        # and "offline" (has previous sync timestamp)
        atomic_json_update "$STATE_FILE" \
            '.metadata.sync_status = "offline"'
    fi

    log_sync_entry "sync_attempt" "offline_mode_activated" "ADO connection unavailable"
}

queue_pending_sync() {
    local operation=$1
    local timestamp=$(get_timestamp)

    # Initialize file atomically if needed
    if [ ! -f "$PENDING_SYNC" ]; then
        atomic_write "$PENDING_SYNC" "[]"
    fi

    local entry=$(jq -n \
        --arg op "$operation" \
        --arg ts "$timestamp" \
        '{operation: $op, timestamp: $ts, status: "pending", retries: 0}')

    atomic_json_array_push "$PENDING_SYNC" '.' "$entry"

    log_info "Queued operation for later sync: $operation"
}

################################################################################
# Sync Report
################################################################################

generate_sync_report() {
    local story_id=$1

    echo ""
    echo "========== STATE SYNC REPORT =========="
    echo "Story ID: $story_id"
    echo "Timestamp: $(get_timestamp)"
    echo ""

    if [ -f "$STATE_FILE" ]; then
        local synced_at=$(jq -r '.metadata.memory_synced_at // "null"' "$STATE_FILE")
        local status=$(jq -r '.metadata.sync_status // "unknown"' "$STATE_FILE")

        echo "Last Sync: $synced_at"
        echo "Status: $status"

        if [ "$synced_at" != "null" ]; then
            local hours=$(hours_since "$synced_at")
            echo "Hours Since Sync: $hours"
        fi
        echo ""
    fi

    if [ -f "$SYNC_LOG" ] && validate_json "$SYNC_LOG"; then
        echo "Recent Sync Operations:"
        jq -r '.[-5:] | .[] | "  \(.timestamp): \(.operation) [\(.status)]"' "$SYNC_LOG"
        echo ""
    fi

    if [ -f "$PENDING_SYNC" ] && validate_json "$PENDING_SYNC"; then
        local pending_count=$(jq '[.[] | select(.status == "pending")] | length' "$PENDING_SYNC")
        if [ "$pending_count" -gt 0 ]; then
            echo "Pending Sync Operations: $pending_count"
        fi
        echo ""
    fi

    echo "========================================="
}

################################################################################
# Main Sync Logic
################################################################################

perform_pull_sync() {
    if [ -z "$STORY_ID" ]; then
        log_error "No active story ID found"
        return 1
    fi

    log_info "Starting pull sync for story: $STORY_ID"

    # Fetch ADO state
    ADO_STATE=$(fetch_ado_state "$STORY_ID") || {
        log_error "Failed to fetch ADO state"
        activate_offline_mode
        queue_pending_sync "pull:$STORY_ID"
        return 1
    }

    # Get local state
    LOCAL_STATE=$(get_local_state "$STORY_ID")

    # Detect conflicts
    local conflict_info
    conflict_info=$(detect_conflicts "$ADO_STATE" "$LOCAL_STATE") || {
        CONFLICT_DETECTED=1
        log_warning "Conflicts detected: $conflict_info"
        log_sync_entry "pull_sync" "conflict_detected" "$conflict_info"
        return 1
    }

    # Resolve: Pull ADO updates
    if pull_ado_updates "$STORY_ID" "$ADO_STATE"; then
        update_sync_timestamp
        log_success "Pull sync completed successfully"
        log_sync_entry "pull_sync" "success" "ADO state merged to local"
        SYNC_SUCCESS=1
        return 0
    else
        log_error "Failed to update local state"
        log_sync_entry "pull_sync" "failed" "Could not merge ADO state"
        return 1
    fi
}

check_sync_age() {
    if [ ! -f "$STATE_FILE" ]; then
        return 0
    fi

    local last_sync=$(jq -r '.metadata.memory_synced_at // null' "$STATE_FILE")

    if [ "$last_sync" = "null" ]; then
        log_warning "State has never been synced (memory_synced_at is null)"
        return 1
    fi

    check_drift_age "$last_sync"
}

################################################################################
# Command Line Interface
################################################################################

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --pull        Perform pull sync (default)
  --report      Show sync report
  --offline     Activate offline mode
  -h, --help    Show this help message

Environment Variables:
  SDLC_SYNC_TIMEOUT_SECONDS      Timeout for ADO calls (default: 30)
  SDLC_SYNC_MAX_AGE_HOURS        Alert threshold in hours (default: 24)
  SDLC_AUTO_RESOLVE_ARTIFACTS    Auto-resolve non-status changes (default: true)
  SDLC_WORK_DIR                  Working directory (default: .sdlc)

Examples:
  ./ado-state-sync.sh --pull      # Fetch latest ADO state
  ./ado-state-sync.sh --report    # Show sync status
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pull)
                OPERATION_MODE="pull"
                shift
                ;;
            --push)
                OPERATION_MODE="push"
                shift
                ;;
            --offline)
                OPERATION_MODE="offline"
                shift
                ;;
            --report)
                OPERATION_MODE="report"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

################################################################################
# Main Entry Point
################################################################################

main() {
    parse_arguments "$@"

    # Ensure sync log exists
    init_sync_log

    # Get active story ID
    STORY_ID=$(get_active_story_id) || {
        log_warning "No active story found - skipping sync"
        log_sync_entry "sync_attempt" "skipped" "No active story ID"
        return 0
    }

    case "$OPERATION_MODE" in
        pull)
            perform_pull_sync
            exit $?
            ;;
        push)
            log_info "Push sync not yet implemented"
            exit 1
            ;;
        offline)
            activate_offline_mode
            exit 0
            ;;
        report)
            generate_sync_report "$STORY_ID"
            check_sync_age
            exit 0
            ;;
        *)
            log_error "Unknown operation mode: $OPERATION_MODE"
            exit 1
            ;;
    esac
}

main "$@"
