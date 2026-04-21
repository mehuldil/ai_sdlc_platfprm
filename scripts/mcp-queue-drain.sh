#!/bin/bash

################################################################################
# MCP Queue Drain Script
#
# Purpose: Process pending MCP operations queued during previous failures.
#          Attempts to retry queued operations for Azure DevOps and WikiJS.
#
# Exit Code: 0 on success, non-zero only on critical errors
#
# Usage:
#   ./scripts/mcp-queue-drain.sh                    # Drain all queues
#   ./scripts/mcp-queue-drain.sh --ado              # Drain ADO queue only
#   ./scripts/mcp-queue-drain.sh --wiki             # Drain WikiJS queue only
#   ./scripts/mcp-queue-drain.sh --dry-run          # Show what would run
#   ./scripts/mcp-queue-drain.sh --force-retry ado  # Force retry ADO queue
#   ./scripts/mcp-queue-drain.sh --clear ado        # Clear ADO queue
#
# Called From:
#   - pre-stage.sh (automatic drain at stage entry)
#   - post-stage.sh (cleanup and final drain)
#   - Manual operator invocation for recovery
#
################################################################################

set -e

# Load atomic I/O library for multi-user safety
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/atomic-io.sh" ]; then
    source "$SCRIPT_DIR/lib/atomic-io.sh"
    USE_ATOMIC=true
else
    echo "[mcp-queue-drain] WARN: atomic-io.sh not found, running without file locking" >&2
    USE_ATOMIC=false
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDLC_DIR="${PROJECT_ROOT}/.sdlc"
MCP_QUEUE_DIR="${SDLC_DIR}/mcp-queue"
HEALTH_FILE="${SDLC_DIR}/mcp-health.json"
LOG_FILE="${SDLC_DIR}/mcp-warnings.log"

ADO_PENDING="${MCP_QUEUE_DIR}/ado-pending.json"
ADO_FAILED="${MCP_QUEUE_DIR}/ado-failed.json"
WIKI_PENDING="${MCP_QUEUE_DIR}/wiki-pending.json"
WIKI_FAILED="${MCP_QUEUE_DIR}/wiki-failed.json"

# MCP Configuration
ADO_ENDPOINT="${ADO_ENDPOINT:-https://dev.azure.com}"
ADO_TIMEOUT=30
RETRY_BACKOFF_BASE=1  # Base delay for retry backoff (seconds)

# Options
DRY_RUN=false
FORCE_RETRY=false
CLEAR_QUEUE=false
TARGET_MCP=""

################################################################################
# Utility Functions
################################################################################

log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  case "$level" in
    "ERROR")
      echo -e "${RED}[${timestamp}] [ERROR] ${message}${NC}"
      ;;
    "WARN")
      echo -e "${YELLOW}[${timestamp}] [WARN] ${message}${NC}"
      ;;
    "INFO")
      echo -e "${GREEN}[${timestamp}] [INFO] ${message}${NC}"
      ;;
    "DEBUG")
      echo -e "${BLUE}[${timestamp}] [DEBUG] ${message}${NC}"
      ;;
    *)
      echo "[${timestamp}] ${message}"
      ;;
  esac

  # Log to file
  echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# Initialize queue directories
init_queue_dir() {
  if [[ ! -d "$MCP_QUEUE_DIR" ]]; then
    mkdir -p "$MCP_QUEUE_DIR"
  fi
}

# Load health status to determine if MCP is available
get_mcp_status() {
  local mcp_name="$1"

  if [[ ! -f "$HEALTH_FILE" ]]; then
    # If health file doesn't exist, assume healthy
    echo "healthy"
    return
  fi

  local status
  if [[ "$USE_ATOMIC" == "true" ]]; then
    status=$(locked_read "$HEALTH_FILE" jq -r ".servers.\"${mcp_name}\".status // \"healthy\"" 2>/dev/null || echo "healthy")
  else
    status=$(jq -r ".servers.\"${mcp_name}\".status // \"healthy\"" "$HEALTH_FILE" 2>/dev/null || echo "healthy")
  fi
  echo "$status"
}

# Check if an operation should be retried based on health and retry count
should_retry_operation() {
  local mcp_name="$1"
  local retry_count="$2"
  local max_retries="$3"
  local mcp_status=$(get_mcp_status "$mcp_name")

  # Don't retry if MCP is down and we're not forcing
  if [[ "$mcp_status" == "down" ]] && [[ "$FORCE_RETRY" != "true" ]]; then
    return 1
  fi

  # Don't retry if max retries exceeded
  if [[ $retry_count -ge $max_retries ]]; then
    return 1
  fi

  return 0
}

# Process a single ADO operation
process_ado_operation() {
  local operation_id="$1"
  local operation_json="$2"

  local operation_type=$(echo "$operation_json" | jq -r '.operation')
  local retry_count=$(echo "$operation_json" | jq -r '.retry_count // 0')
  local max_retries=$(echo "$operation_json" | jq -r '.max_retries // 5')
  local timestamp=$(echo "$operation_json" | jq -r '.timestamp')

  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  ${BLUE}[DRY-RUN]${NC} ADO operation: $operation_type (retry: $retry_count/$max_retries)"
    return 0
  fi

  # Check if we should retry
  if ! should_retry_operation "AzureDevOps" "$retry_count" "$max_retries"; then
    log_message "WARN" "ADO operation $operation_id: max retries ($max_retries) exceeded, moving to failed queue"
    echo "$operation_json" | jq --arg retry_count "$retry_count" '.retry_count = ($retry_count | tonumber)' >> "$ADO_FAILED"
    return 1
  fi

  # Simulate operation retry (in production, this would call the actual ADO API)
  # For now, we'll use a basic health check
  local mcp_status=$(get_mcp_status "AzureDevOps")

  if [[ "$mcp_status" != "healthy" ]] && [[ "$FORCE_RETRY" != "true" ]]; then
    log_message "WARN" "ADO operation $operation_id: MCP status is $mcp_status, skipping retry"
    return 1
  fi

  log_message "INFO" "ADO operation $operation_id: retrying $operation_type (attempt $((retry_count + 1))/$max_retries)"

  # Simulate a call to ADO API (in production, replace with actual API call)
  # This is a placeholder that would be replaced by actual ADO integration
  if timeout $ADO_TIMEOUT curl -s --max-time $ADO_TIMEOUT \
    -X POST "${ADO_ENDPOINT}/_apis/projects" \
    -H "User-Agent: ai-sdlc-queue-drain" \
    > /dev/null 2>&1; then
    log_message "INFO" "ADO operation $operation_id: successfully retried"
    return 0
  else
    log_message "WARN" "ADO operation $operation_id: retry failed, will retry later"
    return 1
  fi
}

# Process a single WikiJS operation
process_wiki_operation() {
  local operation_id="$1"
  local operation_json="$2"

  local operation_type=$(echo "$operation_json" | jq -r '.operation')
  local retry_count=$(echo "$operation_json" | jq -r '.retry_count // 0')
  local max_retries=$(echo "$operation_json" | jq -r '.max_retries // 3')
  local wiki_path=$(echo "$operation_json" | jq -r '.wiki_path')

  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "  ${BLUE}[DRY-RUN]${NC} WikiJS operation: $operation_type on $wiki_path (retry: $retry_count/$max_retries)"
    return 0
  fi

  # Check if we should retry
  if ! should_retry_operation "wikijs" "$retry_count" "$max_retries"; then
    log_message "WARN" "WikiJS operation $operation_id: max retries ($max_retries) exceeded, moving to failed queue"
    echo "$operation_json" | jq --arg retry_count "$retry_count" '.retry_count = ($retry_count | tonumber)' >> "$WIKI_FAILED"
    return 1
  fi

  # Check MCP status
  local mcp_status=$(get_mcp_status "wikijs")

  if [[ "$mcp_status" != "healthy" ]] && [[ "$FORCE_RETRY" != "true" ]]; then
    log_message "WARN" "WikiJS operation $operation_id: MCP status is $mcp_status, skipping retry"
    return 1
  fi

  log_message "INFO" "WikiJS operation $operation_id: retrying $operation_type (attempt $((retry_count + 1))/$max_retries)"

  # Placeholder for WikiJS API call (replace with actual implementation)
  # In production, this would call the WikiJS GraphQL API
  log_message "INFO" "WikiJS operation $operation_id: wiki sync queued for later processing"

  return 1  # Placeholder: assume wiki operations need manual intervention
}

# Drain ADO pending queue
drain_ado_queue() {
  if [[ ! -f "$ADO_PENDING" ]]; then
    return 0
  fi

  log_message "INFO" "Draining ADO pending queue..."

  # Check if file is empty or valid JSON
  local check_valid
  if [[ "$USE_ATOMIC" == "true" ]]; then
    check_valid=$(locked_read "$ADO_PENDING" jq empty 2>/dev/null)
  else
    check_valid=$(jq empty "$ADO_PENDING" 2>/dev/null)
  fi

  if [[ -z "$check_valid" ]]; then
    log_message "ERROR" "ADO pending queue is corrupted, moving to failed"
    mv "$ADO_PENDING" "${ADO_PENDING}.corrupted"
    return 1
  fi

  local pending_count
  if [[ "$USE_ATOMIC" == "true" ]]; then
    pending_count=$(locked_read "$ADO_PENDING" jq '.pending_operations | length')
  else
    pending_count=$(jq '.pending_operations | length' "$ADO_PENDING")
  fi
  echo "  Processing $pending_count pending ADO operations..."

  # Process each pending operation
  local succeeded=0
  local failed=0
  local temp_file="${ADO_PENDING}.tmp"

  if [[ "$USE_ATOMIC" == "true" ]]; then
    atomic_write "$temp_file" '{"pending_operations": []}'
  else
    echo '{"pending_operations": []}' > "$temp_file"
  fi

  local ado_operations
  if [[ "$USE_ATOMIC" == "true" ]]; then
    ado_operations=$(locked_read "$ADO_PENDING" jq -c '.pending_operations[]')
  else
    ado_operations=$(jq -c '.pending_operations[]' "$ADO_PENDING")
  fi

  echo "$ado_operations" | while read -r operation_json; do
    local operation_id=$(echo "$operation_json" | jq -r '.id')
    local retry_count=$(echo "$operation_json" | jq -r '.retry_count // 0')

    if process_ado_operation "$operation_id" "$operation_json"; then
      succeeded=$((succeeded + 1))
      echo "  ${GREEN}✓${NC} Succeeded: $operation_id"
    else
      failed=$((failed + 1))
      # Add back to queue with incremented retry count
      local new_retry_count=$((retry_count + 1))
      local updated_op=$(echo "$operation_json" | jq --arg retry_count "$new_retry_count" \
        ".retry_count = (\$retry_count | tonumber) | .last_error = \"Retry in progress\"")
      if [[ "$USE_ATOMIC" == "true" ]]; then
        atomic_json_array_push "$temp_file" "pending_operations" "$updated_op"
      else
        echo "$updated_op" >> "$temp_file"
      fi
      echo "  ${YELLOW}✗${NC} Will retry: $operation_id"
    fi
  done

  # Replace pending queue with remaining operations
  if [[ -f "$temp_file" ]]; then
    if [[ "$USE_ATOMIC" == "true" ]]; then
      atomic_move "$temp_file" "$ADO_PENDING"
    else
      mv "$temp_file" "$ADO_PENDING"
    fi
  fi

  log_message "INFO" "ADO queue drain complete: $succeeded succeeded, $failed will retry"
}

# Drain WikiJS pending queue
drain_wiki_queue() {
  if [[ ! -f "$WIKI_PENDING" ]]; then
    return 0
  fi

  log_message "INFO" "Draining WikiJS pending queue..."

  # Check if file is empty or valid JSON
  local check_valid
  if [[ "$USE_ATOMIC" == "true" ]]; then
    check_valid=$(locked_read "$WIKI_PENDING" jq empty 2>/dev/null)
  else
    check_valid=$(jq empty "$WIKI_PENDING" 2>/dev/null)
  fi

  if [[ -z "$check_valid" ]]; then
    log_message "ERROR" "WikiJS pending queue is corrupted, moving to failed"
    mv "$WIKI_PENDING" "${WIKI_PENDING}.corrupted"
    return 1
  fi

  local pending_count
  if [[ "$USE_ATOMIC" == "true" ]]; then
    pending_count=$(locked_read "$WIKI_PENDING" jq '.pending_syncs | length')
  else
    pending_count=$(jq '.pending_syncs | length' "$WIKI_PENDING")
  fi
  echo "  Processing $pending_count pending WikiJS syncs..."

  # Process each pending operation
  local succeeded=0
  local failed=0
  local temp_file="${WIKI_PENDING}.tmp"

  if [[ "$USE_ATOMIC" == "true" ]]; then
    atomic_write "$temp_file" '{"pending_syncs": []}'
  else
    echo '{"pending_syncs": []}' > "$temp_file"
  fi

  local wiki_operations
  if [[ "$USE_ATOMIC" == "true" ]]; then
    wiki_operations=$(locked_read "$WIKI_PENDING" jq -c '.pending_syncs[]')
  else
    wiki_operations=$(jq -c '.pending_syncs[]' "$WIKI_PENDING")
  fi

  echo "$wiki_operations" | while read -r operation_json; do
    local operation_id=$(echo "$operation_json" | jq -r '.id')
    local retry_count=$(echo "$operation_json" | jq -r '.retry_count // 0')

    if process_wiki_operation "$operation_id" "$operation_json"; then
      succeeded=$((succeeded + 1))
      echo "  ${GREEN}✓${NC} Succeeded: $operation_id"
    else
      failed=$((failed + 1))
      # Add back to queue with incremented retry count
      local new_retry_count=$((retry_count + 1))
      local updated_op=$(echo "$operation_json" | jq --arg retry_count "$new_retry_count" \
        ".retry_count = (\$retry_count | tonumber) | .last_error = \"Retry in progress\"")
      if [[ "$USE_ATOMIC" == "true" ]]; then
        atomic_json_array_push "$temp_file" "pending_syncs" "$updated_op"
      else
        echo "$updated_op" >> "$temp_file"
      fi
      echo "  ${YELLOW}✗${NC} Will retry: $operation_id"
    fi
  done

  # Replace pending queue with remaining operations
  if [[ -f "$temp_file" ]]; then
    if [[ "$USE_ATOMIC" == "true" ]]; then
      atomic_move "$temp_file" "$WIKI_PENDING"
    else
      mv "$temp_file" "$WIKI_PENDING"
    fi
  fi

  log_message "INFO" "WikiJS queue drain complete: $succeeded succeeded, $failed will retry"
}

# Clear a specific queue
clear_mcp_queue() {
  local mcp_type="$1"

  case "$mcp_type" in
    "ado" | "azure" | "devops")
      log_message "WARN" "Clearing ADO pending queue..."
      if [[ -f "$ADO_PENDING" ]]; then
        mv "$ADO_PENDING" "${ADO_PENDING}.cleared.$(date +%s)"
        echo "  Queue cleared, archive saved"
      fi
      ;;
    "wiki" | "wikijs")
      log_message "WARN" "Clearing WikiJS pending queue..."
      if [[ -f "$WIKI_PENDING" ]]; then
        mv "$WIKI_PENDING" "${WIKI_PENDING}.cleared.$(date +%s)"
        echo "  Queue cleared, archive saved"
      fi
      ;;
    *)
      echo "Unknown MCP type: $mcp_type"
      return 1
      ;;
  esac
}

# Show queue status
show_queue_status() {
  echo ""
  echo "Queue Status:"
  echo "============="

  if [[ -f "$ADO_PENDING" ]]; then
    local ado_count
    if [[ "$USE_ATOMIC" == "true" ]]; then
      ado_count=$(locked_read "$ADO_PENDING" jq '.pending_operations | length' 2>/dev/null || echo "0")
    else
      ado_count=$(jq '.pending_operations | length' "$ADO_PENDING" 2>/dev/null || echo "0")
    fi
    echo "  ADO pending: $ado_count operations"
  else
    echo "  ADO pending: (empty)"
  fi

  if [[ -f "$ADO_FAILED" ]]; then
    local ado_failed
    if [[ "$USE_ATOMIC" == "true" ]]; then
      ado_failed=$(locked_read "$ADO_FAILED" jq '.pending_operations | length' 2>/dev/null || echo "0")
    else
      ado_failed=$(jq '.pending_operations | length' "$ADO_FAILED" 2>/dev/null || echo "0")
    fi
    echo "  ADO failed: $ado_failed operations"
  else
    echo "  ADO failed: (empty)"
  fi

  if [[ -f "$WIKI_PENDING" ]]; then
    local wiki_count
    if [[ "$USE_ATOMIC" == "true" ]]; then
      wiki_count=$(locked_read "$WIKI_PENDING" jq '.pending_syncs | length' 2>/dev/null || echo "0")
    else
      wiki_count=$(jq '.pending_syncs | length' "$WIKI_PENDING" 2>/dev/null || echo "0")
    fi
    echo "  WikiJS pending: $wiki_count syncs"
  else
    echo "  WikiJS pending: (empty)"
  fi

  if [[ -f "$WIKI_FAILED" ]]; then
    local wiki_failed
    if [[ "$USE_ATOMIC" == "true" ]]; then
      wiki_failed=$(locked_read "$WIKI_FAILED" jq '.pending_syncs | length' 2>/dev/null || echo "0")
    else
      wiki_failed=$(jq '.pending_syncs | length' "$WIKI_FAILED" 2>/dev/null || echo "0")
    fi
    echo "  WikiJS failed: $wiki_failed syncs"
  else
    echo "  WikiJS failed: (empty)"
  fi

  echo ""
}

################################################################################
# Parse Arguments
################################################################################

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force-retry)
      FORCE_RETRY=true
      TARGET_MCP="$2"
      shift 2
      ;;
    --clear)
      CLEAR_QUEUE=true
      TARGET_MCP="$2"
      shift 2
      ;;
    --ado | --azure | --devops)
      TARGET_MCP="ado"
      shift
      ;;
    --wiki | --wikijs)
      TARGET_MCP="wiki"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--force-retry MCP] [--clear MCP] [--ado|--wiki]"
      exit 1
      ;;
  esac
done

################################################################################
# Main Execution
################################################################################

main() {
  # Clean orphaned temp files from prior crashes
  cleanup_temp_files ".sdlc/mcp-queue" 2>/dev/null || true

  init_queue_dir
  show_queue_status

  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}DRY-RUN MODE${NC} - No operations will be executed"
    echo ""
  fi

  # Handle clear queue operation
  if [[ "$CLEAR_QUEUE" == "true" ]]; then
    clear_mcp_queue "$TARGET_MCP"
    show_queue_status
    return 0
  fi

  # Handle force retry
  if [[ "$FORCE_RETRY" == "true" ]]; then
    log_message "INFO" "Force retry requested for: $TARGET_MCP"
  fi

  # Drain queues based on target
  if [[ -z "$TARGET_MCP" ]] || [[ "$TARGET_MCP" == "ado" ]]; then
    drain_ado_queue
  fi

  if [[ -z "$TARGET_MCP" ]] || [[ "$TARGET_MCP" == "wiki" ]]; then
    drain_wiki_queue
  fi

  show_queue_status
  log_message "INFO" "Queue drain complete"

  return 0
}

# Run main function
main "$@"
