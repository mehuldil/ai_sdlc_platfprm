# Pipeline Coordinator Agent

> **SDLC authoring:** See [`templates/AUTHORING_STANDARDS.md`](../../templates/AUTHORING_STANDARDS.md).

**Tier:** Universal Tier-1 Agent  
**Scope:** All pipelines (backend, frontend, QA, performance, DevOps)  
**Trigger:** Stage entry, manual status query  
**Purpose:** Monitor and enforce cross-pipeline dependencies

---

## Overview

The Pipeline Coordinator Agent is a universal agent that monitors the cross-pipeline trigger system. It operates at stage entry to check for blocking dependencies and informs users about pending cross-pipeline events.

### Key Responsibilities

1. **Dependency Enforcement**: Prevent stage progression if blocking dependencies are not satisfied
2. **Status Awareness**: Show current status of upstream dependencies
3. **Risk Alerts**: Warn users about potential blocking conditions ahead
4. **Informational Notifications**: Display optional notifications from upstream pipelines
5. **Override Management**: Track and audit manual overrides of blocking dependencies

---

## Activation Points

### 1. On Stage Entry
Triggered when a user attempts to start a new pipeline stage:
- Query `.sdlc/triggers/pending-triggers.json` for pending events
- Check for blocking dependencies targeting the current stage
- Evaluate blocking condition status
- Warn or block based on dependency type

### 2. On Manual Status Query
Triggered when user runs: `sdlc status --dependencies`
- Show all active dependencies
- Show pending triggers
- Show historical trigger events

### 3. On Stage Completion
Triggered after pipeline stage completion:
- Query `.sdlc/triggers/fired/` for recently fired triggers
- Summarize what downstream teams were notified
- Suggest next coordination steps

---

## Blocking Dependency Detection

### Workflow

When a user attempts to enter a stage (e.g., Frontend Stage 08):

```
1. Agent queries pipeline-dependencies.json for blocking dependencies
   └─ Find: BLOCKING dependencies where target.team == "frontend" AND target.stage == "08-implementation"
   
2. For each blocking dependency found:
   ├─ Check source stage status (e.g., backend Stage 04)
   ├─ Evaluate blocking_condition (if present)
   ├─ Calculate upstream completion status
   └─ Determine if block applies

3. If blocking dependency NOT satisfied:
   ├─ Display warning with status and ETA
   ├─ Show current upstream progress
   ├─ Offer override option
   └─ Log risk acknowledgment if overridden

4. If blocking dependency satisfied OR overridden:
   └─ Proceed to stage start
```

### Example: Frontend Implementation Block

**Scenario**: User attempts `frontend stage 08-implementation start`

**Agent Response**:
```
⚠️ BLOCKING DEPENDENCY DETECTED

Stage: Frontend - Implementation (Stage 08)
Requires: Backend - Technical Design (Stage 04) COMPLETE

Current Status:
  Backend Stage 04: IN_PROGRESS (60% complete)
  Last Update: 2 hours ago
  Team: @backend-team
  ETA: 1-2 days

Options:
  [1] Wait for backend completion (recommended)
  [2] Override and start stage (risk acknowledged)
  [3] Show detailed dependency info
  [4] Contact backend team

Your choice: _
```

---

## Informational Trigger Handling

### Workflow

When informational triggers exist for the current stage:

```
1. Query .sdlc/triggers/pending-triggers.json for INFORMATIONAL triggers
   └─ Filter: target.team == current_team AND target.stage == current_stage

2. Display notification summary:
   ├─ Source team and stage
   ├─ Artifact reference
   ├─ Notification message
   └─ Timestamp

3. Proceed automatically:
   └─ User can acknowledge or review artifacts
   └─ Stage progression not blocked
```

### Example: QA Notification

**Scenario**: User starts `qa stage 10-test-design`

**Agent Response**:
```
ℹ️ INFORMATIONAL TRIGGER

You have 2 pending notifications from upstream teams:

1. Backend - Implementation Complete
   Status: Backend Stage 08 implementation merged
   Artifact: backend/main branch (commit abc123def)
   Message: Backend code ready for test design. 
            Feature scope: [auth, payments, analytics]
   Timestamp: 2 hours ago
   
2. Backend - API Contract Available (from 3 hours ago)
   Artifact: backend/specs/openapi.yaml
   Message: API contract v2.1.0 available. 
            Endpoints: 24, Schemas: 18

Proceeding to stage start...
```

---

## Status Commands

### Query Blocking Dependencies
```bash
sdlc status --blocking [--team TEAM] [--stage STAGE]
```

Shows all currently blocking dependencies:
```
BLOCKING DEPENDENCIES

Current Team: Frontend
Current Stage: 08-implementation

Blocking Dependencies:
  ✓ Backend 04-tech-design: SATISFIED (Completed: 4 hours ago)
  ✓ Backend 08-implementation: INFORMATIONAL ONLY

Next Blocking: Performance baseline for Stage 14
  Status: IN_PROGRESS
  ETA: 2-3 days
  Impact: Required before production release approval
```

### Query All Active Triggers
```bash
sdlc status --triggers [--filter TYPE|TEAM|STAGE]
```

Shows pending and fired triggers:
```
ACTIVE TRIGGERS

Pending Triggers: 3
  • backend-04-to-frontend-08 (BLOCKING, not yet satisfied)
  • backend-08-to-qa-10 (INFORMATIONAL)
  • frontend-08-to-qa-11 (INFORMATIONAL)

Recent Fired Triggers: 8
  • backend-04-to-frontend-08 [SATISFIED] - 4h ago
  • backend-04-to-qa-10 [FIRED] - 4h ago
  • backend-08-to-qa-10 [PENDING] - 2h ago
```

### Query Dependency Graph
```bash
sdlc status --graph [--format DOT|JSON|TEXT]
```

Shows dependency relationships:
```
DEPENDENCY GRAPH

backend 04 ──BLOCKING──> frontend 08
           ──INFO────────> qa 10

backend 08 ──INFO────────> qa 10
           ──INFO────────> qa 11

frontend 08 ──INFO────────> qa 11

qa 11 ──BLOCKING──> devops 13

performance 12 ──INFO────────> release 14
```

---

## Override Mechanism

### When to Allow Override

Blocking dependencies can be overridden only under explicit conditions:

| Scenario | Override Allowed | Risk Level | Approval |
|----------|------------------|-----------|----------|
| Upstream stage delayed >48h | YES | High | Team lead + manager |
| Upstream team unavailable | YES | High | Manager + stakeholder |
| Critical path acceleration | YES | Critical | Director + team leads |
| Routine delays | NO | Low | N/A |

### Override Process

```
1. User attempts override:
   sdlc stage START --override --risk-level HIGH

2. Agent prompts for:
   ├─ Risk acknowledgment statement
   ├─ Business justification
   ├─ Approval chain (manager, team lead)
   └─ Impact scope

3. Override logged:
   └─ .sdlc/triggers/overrides/{timestamp}-{trigger_id}.json
      Contains: who overrode, why, risk level, timestamp, approval chain

4. Downstream notification:
   └─ ADO comment on parent epic:
      "⚠️ Frontend Stage 08 started without Backend Stage 04 completion.
          Approved by: @manager-name
          Risk level: HIGH
          Justification: Critical path acceleration"
```

### Override Log

All overrides tracked in `.sdlc/triggers/overrides/`:
```json
{
  "override_id": "frontend-08-override-20260411-143022",
  "timestamp": "2026-04-11T14:30:22Z",
  "stage_team": "frontend",
  "stage_name": "08-implementation",
  "blocking_dependency": "backend-04-to-frontend-08",
  "reason": "Backend stage delayed, critical path approval",
  "risk_level": "HIGH",
  "approval_chain": [
    {"role": "team_lead", "user": "john.doe", "timestamp": "2026-04-11T14:28:00Z"},
    {"role": "manager", "user": "jane.smith", "timestamp": "2026-04-11T14:29:15Z"}
  ],
  "status": "APPROVED"
}
```

---

## Dependency Satisfaction Logic

### Blocking Condition Evaluation

Each blocking dependency defines a `blocking_condition`. Agent evaluates:

```
blocking_condition: "SIT_PASSED"
  ├─ Query .sdlc/qa-results/sit-report.json
  ├─ Extract: result.status == "PASSED"
  ├─ Check: no critical defects
  └─ Verdict: SATISFIED if all true

blocking_condition: null (default: source stage COMPLETE)
  ├─ Query source stage status
  ├─ Check: stage_status == "COMPLETE"
  └─ Verdict: SATISFIED if true
```

### Status Determination

Agent determines upstream status from:
1. `.sdlc/stages/{team}/{stage}/status.json` - Current stage state
2. `.sdlc/triggers/trigger-log.jsonl` - Historical events
3. Team metrics in `.sdlc/team-metrics.json` - Velocity and ETA
4. ADO API (if available) - Real-time progress

---

## Artifact Reference Management

When a trigger fires, the agent can:
- Show artifact location and version
- Check artifact availability
- Provide artifact summary or diff
- Link to artifact in repository/ADO

### Example: API Contract Artifact
```
Artifact Type: OpenAPI Specification
Location: backend/specs/openapi.yaml
Version: 2.1.0
Available: YES
Summary:
  - Endpoints: 24
  - Schemas: 18
  - HTTP methods: GET(8), POST(6), PUT(6), DELETE(4)
  - Authentication: OAuth 2.0 (already documented)

To review artifact:
  git show origin/main:backend/specs/openapi.yaml
  or
  cd backend && npm run specs:view
```

---

## Informational Messaging

### Notification Display Format

```
Source Team: backend
Source Stage: 08-implementation
Type: INFORMATIONAL
Artifact: Backend implementation code merged to main
Message: Backend code ready for test design. 
         Feature scope: auth-service, payment-integration, analytics-sdk
         Code coverage: 87%

Action: No action required. Notification is informational.
Status: Stage can proceed.
```

---

## ETA Calculation

Agent shows ETA based on:
1. Current upstream stage progress percentage
2. Team velocity metrics from `.sdlc/team-metrics.json`
3. Historical stage duration data
4. Current blockers or risks

### Example ETA Display
```
Backend Stage 04 Status:
  Completion: 60%
  Estimated Duration: 3 days
  Current Time in Stage: 18 hours
  ETA: 2026-04-13 (tomorrow) ± 1 day

Calculation:
  - Avg Backend Stage 04 duration: 3 days (historical)
  - Current progress: 60%
  - Remaining: 40% ≈ 1.2 days
  - Current time: 18 hours into 3-day cycle
  - ETA: 18h + 1.2d = 42h = 2026-04-13 10:00 UTC
```

---

## Error Handling

### Missing Dependency File
```
⚠️ WARNING: Dependency graph not found
   File: .sdlc/triggers/pipeline-dependencies.json
   
   Proceeding without cross-pipeline coordination.
   Some dependencies may not be enforced.
   
   To fix: Ensure dependency graph is initialized in repo.
```

### Unavailable Upstream Status
```
⚠️ WARNING: Cannot determine Backend Stage 04 status
   Reason: Status file missing or inaccessible
   
   Blocking dependency cannot be evaluated.
   Options:
   [1] Override and proceed (mark risk HIGH)
   [2] Wait and retry
   [3] Contact backend team for status
   
   Your choice: _
```

### Cyclic Dependencies
```
❌ ERROR: Cyclic dependency detected
   Path: backend 04 -> frontend 08 -> qa 10 -> backend 04
   
   This indicates a configuration error.
   Coordinator agent cannot proceed until cycle is resolved.
   
   To fix: Review .sdlc/triggers/pipeline-dependencies.json
   Validate with: sdlc validate --dependencies
```

---

## Monitoring & Observability

### Coordinator Agent Metrics
- Total stage entries checked for dependencies
- Blocking dependencies enforced / overridden
- Average time waiting on blocking dependencies
- Most common blocking triggers
- Override approval rate and risk levels

### Logs Location
- `.sdlc/triggers/coordinator-log.jsonl` - All agent actions
- `.sdlc/triggers/overrides/` - Override records
- `.sdlc/triggers/trigger-log.jsonl` - Trigger events

### Example Log Entry
```json
{
  "timestamp": "2026-04-11T14:30:22Z",
  "event": "stage_entry_check",
  "team": "frontend",
  "stage": "08-implementation",
  "blocking_dependencies_found": 1,
  "blocking_dependencies_satisfied": 1,
  "status": "ALLOWED_TO_PROCEED",
  "informational_triggers": 2,
  "user": "alice.dev"
}
```

---



## ASK-First Protocol

**Canonical rule:** [`rules/ask-first-protocol.md`](../../rules/ask-first-protocol.md) — never assume; clarify scope and confirm in chat before irreversible actions or when context is ambiguous.

## ASK-First Enforcement

- Before changes that affect production data, ADO state, contracts, or shared artifacts → **ASK**; show intent and wait for confirmation.
- When branch, story, scope, or environment is unclear → **ASK**; do not infer.
- Chat-first for user confirmation: see [`agents/shared/context-guard.md`](../shared/context-guard.md).

## Integration Points

### Called From
- `sdlc stage START` command - Check blocking dependencies
- `sdlc status` command - Report on dependencies
- CI/CD pipeline post-stage hook - Log trigger events
- Manual `sdlc verify-dependencies` - Validation command

### Calls To
- `trigger-dispatcher.sh` - Fire new triggers on stage completion
- ADO REST API - Post comments on epics/features (optional)
- Local trigger files - Read pending/fired triggers
- Team metrics system - Get ETA estimates

---

## Design Principles

1. **Non-Blocking Information**: Informational triggers never prevent stage progression
2. **Override Transparency**: All overrides are logged and communicated to affected teams
3. **Graceful Degradation**: If dependency system fails, pipelines can still proceed with risk marking
4. **Auditability**: Every trigger event and override is logged and traceable
5. **Team Communication**: Cross-pipeline coordination drives ADO notifications
6. **Autonomy with Guardrails**: Teams can override but with oversight and risk acknowledgment

---

## Future Enhancements

- Real-time Slack/Teams notifications for triggers
- Automatic escalation for blocked dependencies >48h
- ML-based ETA prediction using historical velocity
- Dependency visualization dashboard
- Trigger replay for failed notifications
- Conditional dependencies based on feature flags
- Parallel path detection for independent feature streams
