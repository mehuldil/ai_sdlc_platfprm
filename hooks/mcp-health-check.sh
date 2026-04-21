#!/bin/bash

################################################################################
# MCP Health Check Script
#
# Purpose: Validate connectivity to all configured MCP servers (Azure DevOps,
#          WikiJS, Elasticsearch) and update health status tracking.
#
# Exit Code: Always 0 (non-blocking) — health status is logged, not enforced
#
# Output: Updates .sdlc/mcp-health.json with current server status
#
# Usage:
#   ./hooks/mcp-health-check.sh                    # Standard health check
#   ./hooks/mcp-health-check.sh --verbose          # Include detailed logs
#   MCP_MOCK_FAILURE=true ./hooks/mcp-health-check.sh  # Simulate failure
#
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDLC_DIR="${PROJECT_ROOT}/.sdlc"
HEALTH_FILE="${SDLC_DIR}/mcp-health.json"
LOG_FILE="${SDLC_DIR}/mcp-warnings.log"
VERBOSE=${VERBOSE:-false}

# MCP Configuration (from environment or defaults)
ADO_ENDPOINT="${ADO_ENDPOINT:-https://dev.azure.com}"
WIKIJS_ENDPOINT="${WIKIJS_ENDPOINT:-http://localhost:3000}"
ELASTICSEARCH_ENDPOINT="${ELASTICSEARCH_ENDPOINT:-http://localhost:9200}"

# Timeout values (seconds)
ADO_TIMEOUT=30
WIKIJS_TIMEOUT=20
ELASTICSEARCH_TIMEOUT=15

# Mock failure for testing
MOCK_FAILURE=${MCP_MOCK_FAILURE:-false}

################################################################################
# Utility Functions
################################################################################

# Log a message to both stdout and .sdlc/mcp-warnings.log
log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ "$VERBOSE" == "true" ]]; then
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
      *)
        echo "[${timestamp}] ${message}"
        ;;
    esac
  fi

  # Always log to file
  echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# Initialize .sdlc directory if needed
init_sdlc_dir() {
  if [[ ! -d "$SDLC_DIR" ]]; then
    mkdir -p "$SDLC_DIR"
    mkdir -p "${SDLC_DIR}/mcp-queue"
    mkdir -p "${SDLC_DIR}/mcp-cache"
  fi

  if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
  fi
}

# Load current health status from file (if exists)
load_health_status() {
  if [[ -f "$HEALTH_FILE" ]]; then
    cat "$HEALTH_FILE"
  else
    # Initialize with healthy defaults
    cat <<EOF
{
  "checked_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "servers": {
    "AzureDevOps": {
      "status": "healthy",
      "last_success": null,
      "consecutive_failures": 0
    },
    "wikijs": {
      "status": "healthy",
      "last_success": null,
      "consecutive_failures": 0
    },
    "elasticsearch": {
      "status": "healthy",
      "last_success": null,
      "consecutive_failures": 0
    }
  }
}
EOF
  fi
}

# Test connectivity to Azure DevOps
check_ado_health() {
  local endpoint="$ADO_ENDPOINT"
  local timeout=$ADO_TIMEOUT

  if [[ "$MOCK_FAILURE" == "true" ]]; then
    log_message "WARN" "ADO health check: MOCK FAILURE simulated"
    echo "down"
    return
  fi

  if timeout $timeout curl -s --max-time $timeout \
    -H "User-Agent: ai-sdlc-health-check" \
    "${endpoint}/_apis/projects?api-version=6.0" > /dev/null 2>&1; then
    echo "healthy"
  else
    log_message "ERROR" "ADO health check failed: unable to reach ${endpoint}"
    echo "down"
  fi
}

# Test connectivity to WikiJS
check_wikijs_health() {
  local endpoint="$WIKIJS_ENDPOINT"
  local timeout=$WIKIJS_TIMEOUT

  if [[ "$MOCK_FAILURE" == "true" ]]; then
    log_message "WARN" "WikiJS health check: MOCK FAILURE simulated"
    echo "down"
    return
  fi

  if timeout $timeout curl -s --max-time $timeout \
    -H "User-Agent: ai-sdlc-health-check" \
    "${endpoint}/graphql" > /dev/null 2>&1; then
    echo "healthy"
  else
    log_message "ERROR" "WikiJS health check failed: unable to reach ${endpoint}"
    echo "down"
  fi
}

# Test connectivity to Elasticsearch
check_elasticsearch_health() {
  local endpoint="$ELASTICSEARCH_ENDPOINT"
  local timeout=$ELASTICSEARCH_TIMEOUT

  if [[ "$MOCK_FAILURE" == "true" ]]; then
    log_message "WARN" "Elasticsearch health check: MOCK FAILURE simulated"
    echo "down"
    return
  fi

  if timeout $timeout curl -s --max-time $timeout \
    -H "User-Agent: ai-sdlc-health-check" \
    "${endpoint}/_cluster/health" > /dev/null 2>&1; then
    echo "healthy"
  else
    log_message "ERROR" "Elasticsearch health check failed: unable to reach ${endpoint}"
    echo "down"
  fi
}

# Update health status in memory, respecting circuit breaker logic
update_health_status() {
  local server_name="$1"
  local current_status="$2"
  local previous_status="$3"
  local prev_consecutive_failures="$4"
  local new_consecutive_failures

  # Update consecutive failure count
  if [[ "$current_status" == "down" ]]; then
    new_consecutive_failures=$((prev_consecutive_failures + 1))
  else
    new_consecutive_failures=0
  fi

  # Trigger circuit breaker if 3 consecutive failures
  if [[ $new_consecutive_failures -ge 3 ]]; then
    current_status="degraded"
    log_message "WARN" "Circuit breaker triggered for ${server_name}: ${new_consecutive_failures} consecutive failures"
  fi

  # Log status change
  if [[ "$previous_status" != "$current_status" ]]; then
    log_message "INFO" "${server_name} status changed: ${previous_status} -> ${current_status}"
  fi

  echo "$current_status|$new_consecutive_failures"
}

# Build updated health JSON
build_health_json() {
  local ado_status="$1"
  local ado_failures="$2"
  local wiki_status="$3"
  local wiki_failures="$4"
  local es_status="$5"
  local es_failures="$6"

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local last_success

  # For this implementation, update last_success if status is healthy
  # In a real scenario, track actual success timestamps
  if [[ "$ado_status" == "healthy" ]]; then
    last_success="$timestamp"
  else
    last_success="null"
  fi

  cat <<EOF
{
  "checked_at": "${timestamp}",
  "servers": {
    "AzureDevOps": {
      "status": "${ado_status}",
      "last_success": ${last_success},
      "consecutive_failures": ${ado_failures}
    },
    "wikijs": {
      "status": "${wiki_status}",
      "last_success": $(if [[ "$wiki_status" == "healthy" ]]; then echo "\"${timestamp}\""; else echo "null"; fi),
      "consecutive_failures": ${wiki_failures}
    },
    "elasticsearch": {
      "status": "${es_status}",
      "last_success": $(if [[ "$es_status" == "healthy" ]]; then echo "\"${timestamp}\""; else echo "null"; fi),
      "consecutive_failures": ${es_failures}
    }
  }
}
EOF
}

################################################################################
# Main Execution
################################################################################

main() {
  init_sdlc_dir

  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "${GREEN}=== MCP Health Check ===${NC}"
    echo "Checking endpoints:"
    echo "  ADO: $ADO_ENDPOINT"
    echo "  WikiJS: $WIKIJS_ENDPOINT"
    echo "  Elasticsearch: $ELASTICSEARCH_ENDPOINT"
    echo ""
  fi

  # Load previous health status
  local prev_health=$(load_health_status)
  local ado_prev_status=$(echo "$prev_health" | grep -o '"AzureDevOps".*"status": "[^"]*"' | sed 's/.*"status": "\([^"]*\)".*/\1/')
  local wiki_prev_status=$(echo "$prev_health" | grep -o '"wikijs".*"status": "[^"]*"' | sed 's/.*"status": "\([^"]*\)".*/\1/')
  local es_prev_status=$(echo "$prev_health" | grep -o '"elasticsearch".*"status": "[^"]*"' | sed 's/.*"status": "\([^"]*\)".*/\1/')

  local ado_prev_failures=$(echo "$prev_health" | grep -A1 '"AzureDevOps"' | grep 'consecutive_failures' | sed 's/.*: \([0-9]*\).*/\1/')
  local wiki_prev_failures=$(echo "$prev_health" | grep -A1 '"wikijs"' | grep 'consecutive_failures' | sed 's/.*: \([0-9]*\).*/\1/')
  local es_prev_failures=$(echo "$prev_health" | grep -A1 '"elasticsearch"' | grep 'consecutive_failures' | sed 's/.*: \([0-9]*\).*/\1/')

  # Default to 0 if not found
  ado_prev_failures=${ado_prev_failures:-0}
  wiki_prev_failures=${wiki_prev_failures:-0}
  es_prev_failures=${es_prev_failures:-0}

  # Check each MCP server
  if [[ "$VERBOSE" == "true" ]]; then
    echo "Checking Azure DevOps..."
  fi
  local ado_current=$(check_ado_health)
  local ado_updated=$(update_health_status "AzureDevOps" "$ado_current" "$ado_prev_status" "$ado_prev_failures")
  local ado_status=$(echo "$ado_updated" | cut -d'|' -f1)
  local ado_failures=$(echo "$ado_updated" | cut -d'|' -f2)

  if [[ "$VERBOSE" == "true" ]]; then
    echo "Checking WikiJS..."
  fi
  local wiki_current=$(check_wikijs_health)
  local wiki_updated=$(update_health_status "wikijs" "$wiki_current" "$wiki_prev_status" "$wiki_prev_failures")
  local wiki_status=$(echo "$wiki_updated" | cut -d'|' -f1)
  local wiki_failures=$(echo "$wiki_updated" | cut -d'|' -f2)

  if [[ "$VERBOSE" == "true" ]]; then
    echo "Checking Elasticsearch..."
  fi
  local es_current=$(check_elasticsearch_health)
  local es_updated=$(update_health_status "elasticsearch" "$es_current" "$es_prev_status" "$es_prev_failures")
  local es_status=$(echo "$es_updated" | cut -d'|' -f1)
  local es_failures=$(echo "$es_updated" | cut -d'|' -f2)

  # Build and write health status file
  local health_json=$(build_health_json "$ado_status" "$ado_failures" "$wiki_status" "$wiki_failures" "$es_status" "$es_failures")
  echo "$health_json" > "$HEALTH_FILE"

  if [[ "$VERBOSE" == "true" ]]; then
    echo ""
    echo "Health Status Summary:"
    echo -e "  AzureDevOps:  ${GREEN}${ado_status}${NC} (failures: $ado_failures)"
    echo -e "  WikiJS:       ${GREEN}${wiki_status}${NC} (failures: $wiki_failures)"
    echo -e "  Elasticsearch: ${GREEN}${es_status}${NC} (failures: $es_failures)"
    echo ""
    echo "Health status written to: $HEALTH_FILE"
  fi

  # Always return 0 — health checks are non-blocking
  return 0
}

# Run main function
main "$@"
exit 0
