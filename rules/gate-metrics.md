# Gate Metrics Tracking Rules

## Overview
This document defines the metrics collected for each gate (G1-G10) throughout the AI SDLC workflow to enable performance monitoring, bottleneck identification, and SLO tracking.

## Per-Gate Metrics

Each gate execution captures the following metrics:

### Timing Metrics
- **`gate_start_time`**: ISO 8601 timestamp when gate validation began (e.g., `2024-04-11T14:30:00Z`)
- **`gate_end_time`**: ISO 8601 timestamp when user made final decision (e.g., `2024-04-11T14:35:00Z`)
- **`gate_duration_minutes`**: Computed duration from start to end in decimal minutes (e.g., `5.3`)
- **`human_wait_minutes`**: Time from when findings were presented to user until user responded, in decimal minutes
- **`findings_presented_time`**: ISO 8601 timestamp when findings were shown to user
- **`user_responded_time`**: ISO 8601 timestamp when user submitted decision

### Decision Metrics
- **`decision`**: User's decision on gate - one of:
  - `APPROVED`: Gate passed, proceed to next stage
  - `SKIP`: User skipped gate validation (bypass scenario)
  - `REJECTED`: Gate failed, halt workflow
  - `PAUSED`: Gate temporarily paused, will resume later
  - `ERROR`: Gate encountered technical error
  
### Quality Metrics
- **`criteria_met`**: Count of criteria that passed validation (integer, e.g., `8`)
- **`criteria_total`**: Total number of criteria evaluated (integer, e.g., `10`)
- **`criteria_met_percent`**: Percentage of criteria met (e.g., `80`)
- **`token_spent`**: Tokens consumed during gate validation (integer, e.g., `2847`)
- **`retry_count`**: Number of times gate validation was re-run before passing (integer, e.g., `2`)

### Context Metrics
- **`gate_id`**: Gate identifier (G1 through G10, e.g., `G1`)
- **`sprint_id`**: Sprint context (e.g., `sprint-2024-04-08`)
- **`stage_name`**: Name of the stage containing this gate (e.g., `planning`, `implementation`, `testing`)
- **`user_id`**: Identifier of user who made the decision
- **`workflow_run_id`**: Unique identifier for this workflow execution
- **`timestamp_recorded`**: When this metric was recorded to storage (ISO 8601)

## Storage Format

All gate metrics are stored in JSONL format (one JSON object per line):
- **Location**: `.sdlc/metrics/gate-metrics.jsonl`
- **Format**: UTF-8 encoded text, one complete JSON object per line
- **Atomicity**: Each line is a complete, self-contained record
- **Append-only**: New metrics are appended; old records are never modified

### Example Record
```json
{
  "gate_id": "G3",
  "sprint_id": "sprint-2024-04-08",
  "stage_name": "implementation",
  "gate_start_time": "2024-04-11T14:30:00Z",
  "findings_presented_time": "2024-04-11T14:32:15Z",
  "user_responded_time": "2024-04-11T14:35:45Z",
  "gate_end_time": "2024-04-11T14:35:50Z",
  "gate_duration_minutes": 5.83,
  "human_wait_minutes": 3.5,
  "decision": "APPROVED",
  "criteria_met": 8,
  "criteria_total": 10,
  "criteria_met_percent": 80,
  "token_spent": 2847,
  "retry_count": 1,
  "user_id": "alice@example.com",
  "workflow_run_id": "run-2024-04-11-001",
  "timestamp_recorded": "2024-04-11T14:35:51Z"
}
```

## Aggregation & Reporting

### Per-Sprint Dashboard
The sprint metrics report aggregates gate-metrics.jsonl to compute:
- **Gate Duration Stats**: P50 (median), P95 (95th percentile), average, max
- **Human Wait Time Stats**: P50, P95, average across all gates requiring human decision
- **Approval Rate**: Percentage of `APPROVED` decisions vs. total decisions per gate
- **Bottleneck Gates**: Gates with duration > P95 or approval rate < 70%
- **Retry Analysis**: Average retry count per gate, gates with highest retry rates
- **Token Efficiency**: Total tokens spent, average per gate, cost drivers

### Example Report Sections
```
GATE PERFORMANCE SUMMARY
========================
Gate | Avg Duration | P50 Duration | P95 Duration | Approval Rate | Retries
G1   | 2.1 min      | 1.8 min      | 4.2 min      | 95%           | 0.1
G3   | 8.5 min      | 7.2 min      | 15.3 min     | 78%           | 2.3
G5   | 12.1 min     | 11.0 min     | 22.4 min     | 65%           | 3.8

WAIT TIME ANALYSIS
==================
Total Human Wait Time (Sprint): 156.3 minutes
Average Wait Per Gate: 4.2 minutes
P95 Wait Time: 12.5 minutes
```

## SLO Targets

### Gate Wait Time SLO
- **Target**: Human wait time < 4 hours (240 minutes)
- **Alert Threshold**: When any single gate's wait time exceeds 4 hours
- **Definition**: Time from "findings presented" to "user responded"
- **Exception**: SLA applies only to gates where user action is required

### Gate Validation Duration SLO
- **Target**: Gate validation and decision process < 10 minutes (600 seconds)
- **Alert Threshold**: When P95 duration exceeds 10 minutes for any gate
- **Definition**: Time from gate_start_time to gate_end_time
- **Rationale**: Prevents gates from becoming workflow bottlenecks

### Approval Rate Target
- **Target**: >= 85% approval rate on critical gates (G1, G3, G5, G7)
- **Alert Threshold**: When any critical gate approval rate drops below 80%
- **Definition**: (APPROVED decisions / total decisions) * 100

## Recording Frequency

- **When**: Each time a gate completes (user makes a decision or gate times out)
- **Frequency**: Per-gate, per-workflow-run
- **Cardinality**: One record per gate per workflow execution
- **Retention**: Metrics retained for at least 90 days for trending

## Integration Points

### From gate-metrics-tracker.sh
- `gate_start <gate_id>` - Marks gate validation start
- `gate_present <gate_id>` - Marks when findings presented to user
- `gate_decide <gate_id> <decision>` - Records user decision and computes durations

### To sprint-metrics-report.sh
- Reads `.sdlc/metrics/gate-metrics.jsonl`
- Computes aggregates and generates markdown report
- Called via `./scripts/sprint-metrics-report.sh`

## Monitoring & Alerts

### Dashboard Display
Metrics are displayed in:
- Daily gate performance report
- Sprint retrospective metrics
- Post-workflow execution summary

### Alert Conditions
1. **Long Wait Time**: Single gate wait > 4 hours
2. **High Duration**: P95 gate duration > 10 minutes
3. **Low Approval Rate**: Critical gate approval < 80%
4. **High Retry Rate**: Any gate avg retries > 3
5. **High Token Usage**: Tokens per gate exceeding 5000

## Metrics Evolution

Future enhancements may include:
- Gate performance per user (personalized SLOs)
- Time-of-day analysis (gate duration by time)
- Criteria-level performance (which criteria cause rejections)
- Integration with cost tracking (token cost SLOs)
- Historical trending (week-over-week comparison)
