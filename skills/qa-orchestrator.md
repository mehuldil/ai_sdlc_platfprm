# QA Orchestrator Skill

Start and manage AI-driven QA orchestration pipelines from ADO stories.

## Overview

The QA Orchestrator drives end-to-end testing from story ticket to filed defects. It uses Claude AI to analyze requirements, design tests, generate automation code, execute tests, and file bugs in ADO — all with governance gates for human approval at critical checkpoints.

## Installation

The QA Orchestrator is integrated into the SDLC platform. No additional installation required.

To verify:
```bash
cd orchestrator/qa
python -m pytest --co  # List tests
```

## Commands

### Start QA Pipeline

```bash
sdlc qa start <story-id> [--priority=<level>] [--tags=<tag1>,<tag2>]
```

**Parameters:**
- `story-id` (required): ADO story ID, e.g., `US-12345`
- `--priority` (optional): Priority level (low, medium, high, critical). Default: medium
- `--tags` (optional): Comma-separated tags for categorization

**Example:**
```bash
sdlc qa start US-12345 --priority=high --tags=regression,critical

Output:
Run ID: 550e8400-e29b-41d4-a716-446655440000
Status: STARTED
Story: US-12345
Message: QA pipeline initiated. Monitoring governance gates.
```

### Get Pipeline Status

```bash
sdlc qa status <run-id>
```

**Parameters:**
- `run-id` (required): Run ID from `sdlc qa start`

**Output:**
- Current agent executing
- Governance gate status (APPROVED/PENDING/REJECTED/REFINE)
- KB stores loaded
- Audit log

**Example:**
```bash
sdlc qa status 550e8400-e29b-41d4-a716-446655440000

Output:
Run ID: 550e8400-e29b-41d4-a716-446655440000
Status: PAUSED (waiting at: Gate Requirements)
Story: US-12345
Governance Gates:
  requirements: PENDING (created 2026-04-11 10:00:00)
  risk: (not yet reached)
  testDesign: (not yet reached)
  automation: (not yet reached)
KB Loaded:
  requirements: (empty, waiting for agent)
  risk_map: (empty)
  test_cases: (empty)
  ...
```

### Approve Governance Gate

```bash
sdlc qa approve <run-id> <checkpoint> <decision> [--reason=<reason>]
```

**Parameters:**
- `run-id` (required): Run ID
- `checkpoint` (required): Gate to approve (requirements, risk, testDesign, automation)
- `decision` (required): APPROVED | REJECTED | REFINE
- `--reason` (optional): Human-readable justification

**Decisions:**
- `APPROVED`: Proceed to next stage
- `REJECTED`: Stop workflow (go to END state)
- `REFINE`: Request rework of previous agent and re-enter

**Example - Approve:**
```bash
sdlc qa approve 550e8400-e29b-41d4-a716-446655440000 requirements APPROVED \
  --reason="Requirements verified by PM"

Output:
Run ID: 550e8400-e29b-41d4-a716-446655440000
Checkpoint: requirements
Decision: APPROVED
Message: Proceeding to risk_analysis agent
```

**Example - Request Refinement:**
```bash
sdlc qa approve 550e8400-e29b-41d4-a716-446655440000 testDesign REFINE \
  --reason="Test cases need better edge case coverage"

Output:
Run ID: 550e8400-e29b-41d4-a716-446655440000
Checkpoint: testDesign
Decision: REFINE
Message: Re-entering test_case_design agent for refinement
```

### Get Knowledge Base

```bash
sdlc qa kb <run-id> [--store=<store>] [--format=json|summary]
```

**Parameters:**
- `run-id` (required): Run ID
- `--store` (optional): Specific store to retrieve (requirements, risk_map, test_cases, automation, environment, execution, reports, defects)
- `--format` (optional): json (full store) or summary (key metrics)

**Example - Summary View:**
```bash
sdlc qa kb 550e8400-e29b-41d4-a716-446655440000 --format=summary

Output:
Requirements Ready: YES
Risk Scored: YES (score: 7/10, test estimate: 45 tests)
Test Cases: 42 cases designed
Test Automation: Java/TestNG code ready
Execution: Completed (38 pass, 4 fail)
Defects Filed: 4 bugs in ADO
```

**Example - Full Store:**
```bash
sdlc qa kb 550e8400-e29b-41d4-a716-446655440000 --store=test_cases

Output:
[Full JSON of test cases with self-review results]
```

### Archive Run

```bash
sdlc qa archive <run-id>
```

Dump run to disk and clean up Redis. Useful after run completes.

```bash
sdlc qa archive 550e8400-e29b-41d4-a716-446655440000

Output:
Run archived to: data/kb_archive/550e8400-e29b-41d4-a716-446655440000.json
Deleted from Redis
```

### Health Check

```bash
sdlc qa health
```

Check orchestrator and Redis connectivity.

```bash
Output:
QA Orchestrator Status: HEALTHY
Redis: CONNECTED (v7.0.0, 10.5M used)
Config Valid: YES
Claude API: REACHABLE
```

## Workflow States

```
STARTED → RUNNING → PAUSED (at gate) → RUNNING → ... → COMPLETED
                                    ↓
                                 REJECTED (gate rejection)
                                    ↓
                                   END

Or:

STARTED → FAILED (agent error) → END
```

## Governance Gates

### Gate: Requirements

**Checks:**
- Requirements extracted from ADO ticket
- Scope confirmed (no ambiguity)

**Decision needed before:** Risk Analysis

### Gate: Risk

**Checks:**
- Risk scored (1-10 scale)
- Test count estimated

**Decision needed before:** Test Case Design

### Gate: Test Design

**Checks:**
- Test cases generated (minimum 20)
- Self-review passed (no gaps detected)
- Excel export ready

**Decisions:**
- APPROVED: Move to Test Automation
- REFINED: Request better edge case coverage, re-enter agent
- REJECTED: Manual intervention needed

### Gate: Automation

**Checks:**
- Java/TestNG code generated
- POM configured correctly
- Compilation successful

**Decision needed before:** Test Environment

## Integration with SDLC Platform

The QA Orchestrator integrates with existing SDLC components:

### ADO Work Items

Created during pipeline:
- Test Plan (in Test Design stage)
- Test Cases (linked to Test Plan)
- Bugs (in Defect Management stage, linked to parent story)

**Tagging:** All work items created include `claude:generated` tag

### Shared Memory

Run context stored in `.sdlc/memory/qa/`:
- `runs.json`: All active/completed runs
- `{run-id}.json`: Full context dump on completion
- `metrics.json`: Aggregated metrics (token usage, duration, pass rates)

### Metrics Dashboard

Access via SDLC Portal or CLI:
```bash
sdlc qa metrics [--run-id=<run-id>] [--period=<days>]
```

Shows:
- Average agent duration
- Claude token usage per agent
- Test pass rate trends
- Most common failure types

## Troubleshooting

### Pipeline stuck at gate?

1. Check status:
   ```bash
   sdlc qa status <run-id>
   ```

2. Approve gate:
   ```bash
   sdlc qa approve <run-id> <checkpoint> APPROVED
   ```

3. Or request refinement:
   ```bash
   sdlc qa approve <run-id> <checkpoint> REFINE --reason="..."
   ```

### Agent failed?

Check logs:
```bash
docker logs qa-orchestrator-api | grep ERROR
```

Or retrieve full context:
```bash
sdlc qa kb <run-id> --format=json | jq '.audit'
```

### Redis not responding?

Restart Redis:
```bash
docker-compose restart redis
```

### Configuration error?

Verify setup:
```bash
sdlc qa health

# If failed, check env:
cat orchestrator/qa/.env

# Must have:
# ANTHROPIC_API_KEY=...
# ADO_PAT=...
```

## Advanced Usage

### Manual API Calls

For integration with external tools:

```bash
# Start pipeline
curl -X POST http://localhost:8000/trigger \
  -H "Content-Type: application/json" \
  -d '{"story_id": "US-12345", "priority": "high"}'

# Approve gate
curl -X POST 'http://localhost:8000/approve?run_id=550e8400-...' \
  -H "Content-Type: application/json" \
  -d '{"checkpoint": "requirements", "decision": "APPROVED"}'

# Get status
curl http://localhost:8000/status/550e8400-...

# Get KB
curl http://localhost:8000/kb/550e8400-.../test_cases
```

### Webhook Notifications

Enable in config:
```bash
ENABLE_WEBHOOK_NOTIFICATIONS=true
WEBHOOK_URL=https://your-service/qa-events
```

Receives events when gates pause or agents complete.

### Parallel Execution (Experimental)

```bash
ENABLE_PARALLEL_EXECUTION=true
```

Executes independent agents concurrently (test_environment, test_execution can run in parallel to other stages).

## Related Topics

- SDLC Platform: `/README.md`
- QA Orchestrator Architecture: `/orchestrator/qa/README.md`
- Azure DevOps Standards: `/rules/ado-standards.md`
- Token Optimization: `/rules/token-optimization.md`

---

**Skill**: QA Orchestrator  
**Version**: 1.0.0  
**Last Updated**: 2026-04-11
