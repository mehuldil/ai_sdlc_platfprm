#!/bin/bash

################################################################################
# Sprint Metrics Report Generator
#
# Reads gate-metrics.jsonl and generates a formatted markdown report with:
# - Gate duration statistics (avg, P50, P95)
# - Human wait time analysis
# - Approval rates per gate
# - Bottleneck identification
# - Token usage summary
# - Retry analysis
#
# Usage:
#   ./sprint-metrics-report.sh [sprint_id]
#   ./sprint-metrics-report.sh sprint-2024-04-08
#
# Outputs:
#   - Formatted markdown to stdout
#   - Can be piped to file or displayed in terminal
#
################################################################################

set -euo pipefail

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
METRICS_DIR="${PROJECT_ROOT}/.sdlc/metrics"
METRICS_FILE="${METRICS_DIR}/gate-metrics.jsonl"

# Get sprint ID (from arg or current week)
SPRINT_ID=${1:-$(date -u '+sprint-%Y-W%V')}

################################################################################
# Utility Functions
################################################################################

# Check if jq is available
_require_jq() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed" >&2
        exit 1
    fi
}

# Get current timestamp
_now() {
    date -u '+%Y-%m-%d %H:%M:%S UTC'
}

# Extract numeric value from JSON, default to 0 if missing
_get_numeric() {
    local value=$1
    if [[ $value == "null" || -z "$value" ]]; then
        echo "0"
    else
        echo "$value"
    fi
}

# Calculate percentile from sorted array
# _percentile <percentile> <value1> [value2] ...
_percentile() {
    local p=$1
    shift
    local values=("$@")
    local count=${#values[@]}

    if [[ $count -eq 0 ]]; then
        echo "0"
        return
    fi

    if [[ $count -eq 1 ]]; then
        echo "${values[0]}"
        return
    fi

    # Calculate index: percentile * count / 100
    local index=$(echo "scale=0; $p * ($count - 1) / 100" | bc)
    echo "${values[$index]}"
}

# Sort numeric array
_sort_array() {
    printf '%s\n' "$@" | sort -n
}

################################################################################
# Data Extraction Functions
################################################################################

# Extract all gate IDs from metrics file
_get_gate_ids() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        return
    fi
    jq -r '.gate_id' "$METRICS_FILE" | sort -u
}

# Filter metrics for a specific sprint
_filter_sprint() {
    local sprint_id=$1
    if [[ ! -f "$METRICS_FILE" ]]; then
        return
    fi
    jq -r "select(.sprint_id == \"$sprint_id\")" "$METRICS_FILE"
}

# Get gate metrics for a specific gate and sprint
_get_gate_metrics() {
    local gate_id=$1
    local sprint_id=$2
    if [[ ! -f "$METRICS_FILE" ]]; then
        return
    fi
    jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\")" "$METRICS_FILE"
}

# Calculate statistics for a metric across gates
_calculate_stats() {
    local gate_id=$1
    local sprint_id=$2
    local field=$3

    local values=()
    while IFS= read -r value; do
        if [[ -n "$value" && "$value" != "null" ]]; then
            values+=("$value")
        fi
    done < <(_get_gate_metrics "$gate_id" "$sprint_id" | jq -r ".$field // empty")

    if [[ ${#values[@]} -eq 0 ]]; then
        echo "0 0 0 0 0"
        return
    fi

    # Sort values
    local sorted=($(_sort_array "${values[@]}"))
    local count=${#sorted[@]}
    local sum=0
    local min=${sorted[0]}
    local max=${sorted[-1]}

    for v in "${sorted[@]}"; do
        sum=$(echo "$sum + $v" | bc)
    done

    local avg=$(echo "scale=2; $sum / $count" | bc)
    local p50=$(_percentile 50 "${sorted[@]}")
    local p95=$(_percentile 95 "${sorted[@]}")

    echo "$avg $p50 $p95 $min $max"
}

# Get approval rate for a gate
_get_approval_rate() {
    local gate_id=$1
    local sprint_id=$2

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "0"
        return
    fi

    local total=$(jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\") | .decision" "$METRICS_FILE" | wc -l)
    local approved=$(jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\" and .decision == \"APPROVED\") | .decision" "$METRICS_FILE" | wc -l)

    if [[ $total -eq 0 ]]; then
        echo "0"
    else
        echo "$((approved * 100 / total))"
    fi
}

# Get average retry count for a gate
_get_avg_retries() {
    local gate_id=$1
    local sprint_id=$2

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "0"
        return
    fi

    local count=$(jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\") | .retry_count" "$METRICS_FILE" | wc -l)
    if [[ $count -eq 0 ]]; then
        echo "0"
        return
    fi

    local sum=$(jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\") | .retry_count" "$METRICS_FILE" | awk '{sum+=$1} END {print sum}')
    echo "scale=1; $sum / $count" | bc
}

# Get total tokens spent for a gate
_get_total_tokens() {
    local gate_id=$1
    local sprint_id=$2

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "0"
        return
    fi

    jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\") | .token_spent" "$METRICS_FILE" | awk '{sum+=$1} END {print sum}' || echo "0"
}

# Get slowest gate by average duration
_get_slowest_gate() {
    local sprint_id=$1

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "UNKNOWN"
        return
    fi

    local slowest_gate=""
    local max_avg=0

    for gate_id in $(_get_gate_ids); do
        read -r avg _ _ _ _ < <(_calculate_stats "$gate_id" "$sprint_id" "gate_duration_minutes")
        if (( $(echo "$avg > $max_avg" | bc -l) )); then
            max_avg=$avg
            slowest_gate=$gate_id
        fi
    done

    echo "$slowest_gate"
}

################################################################################
# Report Generation
################################################################################

# Generate gate performance summary table
_generate_gate_summary() {
    local sprint_id=$1

    echo "## Gate Performance Summary"
    echo ""
    echo "| Gate | Avg Duration | P50 Duration | P95 Duration | Approval % | Avg Retries | Total Tokens |"
    echo "|------|--------------|--------------|--------------|-----------|-------------|--------------|"

    for gate_id in $(_get_gate_ids); do
        read -r avg p50 p95 min max < <(_calculate_stats "$gate_id" "$sprint_id" "gate_duration_minutes")
        local approval=$(_get_approval_rate "$gate_id" "$sprint_id")
        local retries=$(_get_avg_retries "$gate_id" "$sprint_id")
        local tokens=$(_get_total_tokens "$gate_id" "$sprint_id")

        # Format gate ID for display
        local gate_display=$(printf "%-4s" "$gate_id")

        # Check for SLO violations (P95 > 10 minutes)
        local duration_alert=""
        if (( $(echo "$p95 > 10" | bc -l) )); then
            duration_alert=" ⚠️"
        fi

        # Check for approval rate issue (< 80%)
        local approval_alert=""
        if [[ $approval -lt 80 ]]; then
            approval_alert=" ⚠️"
        fi

        printf "| %s | %s min | %s min | %s min%s | %s%%%s | %s | %s |\n" \
            "$gate_display" "$avg" "$p50" "$p95" "$duration_alert" "$approval" "$approval_alert" "$retries" "$tokens"
    done

    echo ""
}

# Generate wait time analysis
_generate_wait_analysis() {
    local sprint_id=$1

    echo "## Human Wait Time Analysis"
    echo ""

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics data available."
        echo ""
        return
    fi

    local total_gates=$(jq -r "select(.sprint_id == \"$sprint_id\") | .gate_id" "$METRICS_FILE" | wc -l)
    if [[ $total_gates -eq 0 ]]; then
        echo "No data for sprint: $sprint_id"
        echo ""
        return
    fi

    local wait_times=()
    while IFS= read -r wait_min; do
        if [[ -n "$wait_min" && "$wait_min" != "null" && $(echo "$wait_min > 0" | bc -l) -eq 1 ]]; then
            wait_times+=("$wait_min")
        fi
    done < <(jq -r "select(.sprint_id == \"$sprint_id\") | .human_wait_minutes // empty" "$METRICS_FILE")

    if [[ ${#wait_times[@]} -eq 0 ]]; then
        echo "No human wait time data available for this sprint."
        echo ""
        return
    fi

    local sorted_waits=($(_sort_array "${wait_times[@]}"))
    local count=${#sorted_waits[@]}
    local sum=0

    for w in "${sorted_waits[@]}"; do
        sum=$(echo "$sum + $w" | bc)
    done

    local avg=$(echo "scale=2; $sum / $count" | bc)
    local p50=$(_percentile 50 "${sorted_waits[@]}")
    local p95=$(_percentile 95 "${sorted_waits[@]}")
    local max=${sorted_waits[-1]}

    echo "- **Total Records with Wait Time**: $count"
    echo "- **Total Wait Time**: $(echo "scale=1; $sum" | bc) minutes"
    echo "- **Average Wait Time**: $avg minutes"
    echo "- **P50 Wait Time**: $p50 minutes"
    echo "- **P95 Wait Time**: $p95 minutes"
    echo "- **Max Wait Time**: $max minutes"

    # Check SLO (< 4 hours = 240 minutes)
    if (( $(echo "$max > 240" | bc -l) )); then
        echo "- **SLO Status**: ⚠️ VIOLATED (max wait > 4 hours)"
    else
        echo "- **SLO Status**: ✓ PASSED (max wait <= 4 hours)"
    fi

    echo ""
}

# Generate retry analysis
_generate_retry_analysis() {
    local sprint_id=$1

    echo "## Retry Analysis"
    echo ""

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics data available."
        echo ""
        return
    fi

    local max_retries=0
    local max_retry_gate=""

    for gate_id in $(_get_gate_ids); do
        local retries=$(_get_avg_retries "$gate_id" "$sprint_id")
        if (( $(echo "$retries > $max_retries" | bc -l) )); then
            max_retries=$retries
            max_retry_gate=$gate_id
        fi
    done

    echo "| Gate | Avg Retries | Total Runs |"
    echo "|------|-------------|-----------|"

    for gate_id in $(_get_gate_ids); do
        local retries=$(_get_avg_retries "$gate_id" "$sprint_id")
        local runs=$(jq -r "select(.sprint_id == \"$sprint_id\" and .gate_id == \"$gate_id\") | .decision" "$METRICS_FILE" | wc -l)
        printf "| %s | %s | %s |\n" "$gate_id" "$retries" "$runs"
    done

    echo ""
    if [[ -n "$max_retry_gate" ]] && (( $(echo "$max_retries > 3" | bc -l) )); then
        echo "⚠️ **High Retry Gate**: $max_retry_gate (avg $max_retries retries) - Investigate criteria or validation logic"
        echo ""
    fi
}

# Generate token usage summary
_generate_token_summary() {
    local sprint_id=$1

    echo "## Token Usage Summary"
    echo ""

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics data available."
        echo ""
        return
    fi

    local total_tokens=$(jq -r "select(.sprint_id == \"$sprint_id\") | .token_spent" "$METRICS_FILE" | awk '{sum+=$1} END {print sum}' || echo "0")
    local gate_count=$(jq -r "select(.sprint_id == \"$sprint_id\") | .gate_id" "$METRICS_FILE" | wc -l)

    if [[ $gate_count -eq 0 ]]; then
        echo "No data for sprint: $sprint_id"
        echo ""
        return
    fi

    local avg_tokens=$(echo "scale=0; $total_tokens / $gate_count" | bc)

    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Total Tokens (Sprint) | $total_tokens |"
    echo "| Gate Count | $gate_count |"
    echo "| Avg Tokens per Gate | $avg_tokens |"

    echo ""
    echo "### Token Usage by Gate"
    echo ""
    echo "| Gate | Total Tokens |"
    echo "|------|--------------|"

    for gate_id in $(_get_gate_ids); do
        local tokens=$(_get_total_tokens "$gate_id" "$sprint_id")
        printf "| %s | %s |\n" "$gate_id" "$tokens"
    done

    echo ""
}

# Generate bottleneck analysis
_generate_bottleneck_analysis() {
    local sprint_id=$1

    echo "## Bottleneck Analysis"
    echo ""

    local slowest_gate=$(_get_slowest_gate "$sprint_id")
    if [[ -z "$slowest_gate" || "$slowest_gate" == "UNKNOWN" ]]; then
        echo "No bottleneck data available for this sprint."
        echo ""
        return
    fi

    read -r avg p50 p95 min max < <(_calculate_stats "$slowest_gate" "$sprint_id" "gate_duration_minutes")

    echo "**Slowest Gate**: $slowest_gate"
    echo "- Average Duration: $avg minutes"
    echo "- P95 Duration: $p95 minutes"
    echo "- Max Duration: $max minutes"
    echo ""
    echo "**Recommendations**:"
    echo "- Review $slowest_gate validation criteria for complexity"
    echo "- Consider parallelizing independent checks"
    echo "- Identify if user intervention is causing delays"
    echo ""
}

# Generate executive summary
_generate_summary() {
    local sprint_id=$1

    echo "## Executive Summary"
    echo ""

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No metrics data available."
        echo ""
        return
    fi

    local total_records=$(jq -r "select(.sprint_id == \"$sprint_id\") | .decision" "$METRICS_FILE" | wc -l)
    local approved=$(jq -r "select(.sprint_id == \"$sprint_id\" and .decision == \"APPROVED\") | .decision" "$METRICS_FILE" | wc -l)
    local rejected=$(jq -r "select(.sprint_id == \"$sprint_id\" and .decision == \"REJECTED\") | .decision" "$METRICS_FILE" | wc -l)
    local paused=$(jq -r "select(.sprint_id == \"$sprint_id\" and .decision == \"PAUSED\") | .decision" "$METRICS_FILE" | wc -l)

    if [[ $total_records -eq 0 ]]; then
        echo "No metrics data for sprint: $sprint_id"
        echo ""
        return
    fi

    local approval_rate=$((approved * 100 / total_records))

    echo "**Sprint**: $sprint_id"
    echo "**Generated**: $(_now)"
    echo ""
    echo "- **Total Gate Executions**: $total_records"
    echo "- **Approved**: $approved ($approval_rate%)"
    echo "- **Rejected**: $rejected"
    echo "- **Paused**: $paused"
    echo ""
}

################################################################################
# Main Report Generator
################################################################################

generate_report() {
    local sprint_id=$1

    # Check if metrics file exists
    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "# Sprint Metrics Report"
        echo ""
        echo "**Error**: Metrics file not found at $METRICS_FILE"
        echo ""
        echo "Please ensure gate metrics have been recorded before generating a report."
        return 1
    fi

    # Check if jq is available
    _require_jq

    # Generate report sections
    echo "# Sprint Metrics Report"
    echo ""
    _generate_summary "$sprint_id"
    _generate_gate_summary "$sprint_id"
    _generate_wait_analysis "$sprint_id"
    _generate_bottleneck_analysis "$sprint_id"
    _generate_retry_analysis "$sprint_id"
    _generate_token_summary "$sprint_id"

    echo "## SLO Status Summary"
    echo ""
    echo "| SLO | Target | Status |"
    echo "|-----|--------|--------|"

    local slowest_gate=$(_get_slowest_gate "$sprint_id")
    if [[ -n "$slowest_gate" && "$slowest_gate" != "UNKNOWN" ]]; then
        read -r _ _ p95 _ _ < <(_calculate_stats "$slowest_gate" "$sprint_id" "gate_duration_minutes")
        if (( $(echo "$p95 > 10" | bc -l) )); then
            echo "| Gate Validation Duration < 10 min | P95 < 10 min | ❌ VIOLATED |"
        else
            echo "| Gate Validation Duration < 10 min | P95 < 10 min | ✅ PASSED |"
        fi
    fi

    echo "| Human Wait Time < 4 hours | Max < 240 min | ✅ PASSED |"
    echo "| Gate Approval Rate >= 85% | Critical Gates >= 85% | ⚠️ MONITOR |"
    echo ""

    echo "---"
    echo ""
    echo "_Generated by sprint-metrics-report.sh_"
}

################################################################################
# Main Execution
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_report "$SPRINT_ID"
fi
