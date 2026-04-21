# MCP Resilience Layer

## Overview

This document defines resilience patterns for Managed Connector Platforms (MCPs) in the AI SDLC platform. These patterns ensure that temporary service disruptions don't block the entire pipeline and enable graceful degradation with automatic recovery.

## MCP Health Check Protocol

### Connectivity Validation

Before any stage that uses ADO (Azure DevOps), WikiJS, or Elasticsearch MCPs, the pipeline must validate connectivity to each configured MCP server.

**Validation Timing:**
- Automatic: Every stage entry via `pre-stage.sh` hook
- Manual: Via `./scripts/mcp-health-check.sh`

**Health Check Execution:**
```bash
./hooks/mcp-health-check.sh
```

**Health Status Tracking:**
Health status is recorded in `.sdlc/mcp-health.json`:
- `healthy`: MCP server is operational
- `degraded`: MCP server has failed consecutive requests but circuit breaker not yet triggered
- `down`: MCP server is unreachable or circuit breaker has triggered (DEGRADED state)

**Impact on Pipeline:**
- Stage execution is NOT blocked by MCP health status
- Stage behavior adapts based on health status (see Fallback Behavior)
- Critical operations queue for later retry

## Retry Policy

### Standard Retry Behavior

All MCP operations follow exponential backoff with 3 retry attempts:

| Attempt | Delay | Cumulative |
|---------|-------|-----------|
| 1 (Initial) | — | —s |
| 2 (Retry 1) | 1s | 1s |
| 3 (Retry 2) | 2s | 3s |
| 4 (Retry 3) | 4s | 7s |

### Retryable Error Conditions

Retry on transient errors:
- HTTP 5xx (500, 502, 503, 504)
- Connection timeouts
- Temporary network failures
- Service temporarily unavailable (429, 503)

### Non-Retryable Error Conditions

Do NOT retry on:
- HTTP 4xx (400, 401, 403, 404) — configuration or auth errors
- Invalid request format
- Authentication failures
- Resource not found

## Fallback Behavior by MCP

### Azure DevOps (ADO)

**Primary Operations:** Create work items, update iteration status, assign developers

**Fallback Mode:**
1. On MCP failure after 3 retries, queue the operation to `.sdlc/mcp-queue/ado-pending.json`
2. Log operation metadata: timestamp, operation type, work item ID, target state
3. Continue pipeline execution
4. Stage completion status: `degraded` (not failed)

**Queue File Format:**
```json
{
  "pending_operations": [
    {
      "id": "uuid",
      "timestamp": "2026-04-11T10:30:00Z",
      "retry_count": 0,
      "max_retries": 5,
      "operation": "create_work_item",
      "project": "project-name",
      "payload": {
        "title": "...",
        "type": "Task"
      },
      "last_error": "Connection timeout"
    }
  ]
}
```

**Recovery:** Next stage entry attempts to drain queue via `./scripts/mcp-queue-drain.sh`

### WikiJS

**Primary Operations:** Document sync, wiki page creation, content updates

**Fallback Mode:**
1. On MCP failure after 3 retries, queue the operation to `.sdlc/mcp-queue/wiki-pending.json`
2. Do NOT block pipeline — wiki sync is non-critical
3. Log to `.sdlc/wiki-sync-required.txt`: "Manual wiki sync required — see wiki-pending.json"
4. Stage completion status: `degraded`

**Queue File Format:**
```json
{
  "pending_syncs": [
    {
      "id": "uuid",
      "timestamp": "2026-04-11T10:30:00Z",
      "retry_count": 0,
      "max_retries": 3,
      "operation": "sync_page",
      "wiki_path": "/project/docs/architecture",
      "source_file": "docs/architecture.md",
      "last_error": "WikiJS server unreachable"
    }
  ]
}
```

**Recovery:** Next stage entry attempts to drain queue; operator can manually trigger `./scripts/mcp-queue-drain.sh`

### Elasticsearch

**Primary Operations:** Log indexing, log retrieval, analytics queries

**Fallback Mode:**
1. On MCP failure, skip log write operations (non-blocking)
2. Attempt to use cached logs from `.sdlc/mcp-cache/logs.json` if available
3. If no cache, skip silently — logging is best-effort
4. Log warning to `.sdlc/mcp-warnings.log`: "Elasticsearch unavailable — using cache or skipping logs"
5. Stage completion status: `degraded`

**No Queue:** Logs are not queued (ephemeral data) — operator should review pipeline execution manually if logs are needed

**Recovery:** Logs are automatically re-indexed on next successful Elasticsearch connection

## Circuit Breaker Pattern

### Trigger Condition

If an MCP server fails 3 consecutive operations in a single pipeline run:
1. Mark MCP as DEGRADED in `.sdlc/mcp-health.json`
2. `consecutive_failures` field reaches 3

### Behavior When DEGRADED

- **Critical operations:** Queued for retry
- **Non-critical operations:** Skipped
- **Pipeline:** Continues execution
- **User notification:** Log entry in `.sdlc/stage-log.json`: `"mcp_status": "degraded", "mcp_name": "azure-devops"`

### Definition of Critical vs. Non-Critical

**Critical (Queue for Retry):**
- Create/update work items (blocks iteration tracking)
- Assign developers (blocks capability planning)
- Update build definitions (blocks deployment)

**Non-Critical (Skip):**
- Log analytics queries
- Generate wiki documentation
- Update dashboard metrics

### Reset Condition

Circuit breaker resets on next successful MCP operation:
- `consecutive_failures` decrements to 0
- Status changes back to `healthy`

## Recovery Process

### Queue Drain Timing

Queue drain is attempted at:
1. **Stage entry:** `pre-stage.sh` calls `./scripts/mcp-queue-drain.sh`
2. **Manual trigger:** `./scripts/mcp-queue-drain.sh` can be invoked by operator
3. **Post-run:** Final stage cleanup

### Queue Processing Logic

For each pending operation in queue:
1. Check current MCP health status
2. If `healthy`, attempt operation
3. On success, remove from queue
4. On failure, increment `retry_count`
5. If `retry_count >= max_retries`, move to `.sdlc/mcp-queue/ado-failed.json` and alert
6. If `retry_count < max_retries`, keep in pending queue

### Queue Timeout

- ADO operations: Max 5 retries (retain for up to 24 hours)
- WikiJS operations: Max 3 retries (retain for up to 48 hours)
- After timeout, move to failed queue and log alert

### Operator Actions

If queue drains fail repeatedly:
1. **Verify MCP server status:** Check Azure DevOps/WikiJS uptime
2. **Retry failed queue:** `./scripts/mcp-queue-drain.sh --force-retry ado`
3. **Clear queue manually:** `./scripts/mcp-queue-drain.sh --clear ado`

## Monitoring and Alerts

### Health Check Logs

- Location: `.sdlc/mcp-health.json`
- Updated every stage entry
- Retention: 30 days

### Failure Logs

- Location: `.sdlc/mcp-warnings.log`
- Format: `[timestamp] [MCP_NAME] [ERROR] message`
- Example: `[2026-04-11T10:30:00Z] [AzureDevOps] [ERROR] Failed to create work item after 3 retries — queued for later`

### Degraded Status Alerts

When MCP status changes to DEGRADED:
1. Log alert in `.sdlc/stage-log.json`
2. Include MCP name, failure count, last error
3. Recommend operator review pending queue

## Configuration Reference

### MCP Server Timeouts

- ADO: 30s per request
- WikiJS: 20s per request
- Elasticsearch: 15s per request

### Retry Configuration

- All MCPs: 3 retries, exponential backoff (1s, 2s, 4s)
- Backoff multiplier: 2x
- Max delay: 4s

### Circuit Breaker Settings

- Failure threshold: 3 consecutive failures
- Reset on first success
- State: healthy | degraded | down

## Testing Resilience

### Health Check Test

```bash
./hooks/mcp-health-check.sh
cat .sdlc/mcp-health.json
```

### Simulate MCP Failure

Set `MCP_MOCK_FAILURE=true` environment variable:
```bash
MCP_MOCK_FAILURE=true ./hooks/mcp-health-check.sh
```

### Queue Drain Test

```bash
./scripts/mcp-queue-drain.sh --dry-run
```

## Related Files

- `.sdlc/mcp-health.json` — Health status
- `.sdlc/mcp-queue/ado-pending.json` — Pending ADO operations
- `.sdlc/mcp-queue/wiki-pending.json` — Pending WikiJS operations
- `.sdlc/mcp-warnings.log` — Failure logs
- `hooks/mcp-health-check.sh` — Health check script
- `scripts/mcp-queue-drain.sh` — Queue drain script
