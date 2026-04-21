# Cross-Pipeline Trigger Protocol

## Overview
This document defines the automated coordination mechanism between backend, frontend, QA, performance, and DevOps pipelines in the AI SDLC Platform. Pipelines can now communicate through standardized trigger events rather than operating in isolation.

## Trigger Events

### Automatic Fire Rules
Triggers automatically fire when the following stage milestones are reached:

#### Backend Pipeline
- **Stage 04 (Tech Design) - COMPLETE** 
  - Event: API contract finalized and committed
  - Trigger: `BLOCKING` gate for Frontend Stage 08
  - Notification: "API contract v{version} available. Frontend implementation can begin."
  - Target: Frontend pipeline, QA pipeline (informational)

- **Stage 08 (Implementation) - COMPLETE**
  - Event: Backend implementation code complete and merged
  - Trigger: `INFORMATIONAL` notification to QA
  - Notification: "Backend code ready for test design. Feature scope: {feature_list}"
  - Target: QA pipeline Stage 10 (Test Design)

#### Frontend Pipeline
- **Stage 08 (Implementation) - COMPLETE**
  - Event: Frontend implementation code complete and merged
  - Trigger: `INFORMATIONAL` notification to QA
  - Notification: "Frontend code ready for integration testing. Components integrated: {component_list}"
  - Target: QA pipeline SIT (System Integration Testing)

#### QA Pipeline
- **Stage 10 (Test Design) - COMPLETE**
  - Event: Test cases and scenarios finalized
  - Trigger: `INFORMATIONAL` notification to Performance
  - Notification: "Test cases ready (count: {test_count}). Performance scenarios can be derived."
  - Target: Performance pipeline
  
- **SIT (System Integration Testing) - COMPLETE**
  - Event: All integration tests pass, no critical defects
  - Trigger: `BLOCKING` gate for DevOps deployment
  - Notification: "SIT passed with {pass_count} tests. Ready for pre-production deployment."
  - Target: DevOps pipeline (Deployment stage)

#### Performance Pipeline
- **Performance Testing - COMPLETE**
  - Event: Performance baseline established, reports generated
  - Trigger: `INFORMATIONAL` notification to Release Manager
  - Notification: "Performance baseline established. Throughput: {throughput}, Latency p99: {latency_p99}"
  - Target: Release Manager (approval gate)

## Trigger Mechanism

### Trigger File Structure
All triggers are appended to a queue file at: `.sdlc/triggers/pending-triggers.json`

### Trigger Lifecycle
1. **Fire**: Stage completion event triggers are added to pending queue
2. **Dispatch**: `trigger-dispatcher.sh` processes queue and creates fired trigger files
3. **Notify**: Notifications posted to ADO as comments on parent epic/feature
4. **Acknowledge**: Pipeline coordinator agent monitors and warns on blocking dependencies
5. **Clear**: Fired triggers moved to archive after acknowledgment

### File Locations
- Pending triggers queue: `.sdlc/triggers/pending-triggers.json`
- Dependency definition: `.sdlc/triggers/pipeline-dependencies.json`
- Fired triggers (archive): `.sdlc/triggers/fired/{timestamp}-{trigger_id}.json`
- Trigger execution log: `.sdlc/triggers/trigger-log.jsonl`

## Notification Format

### ADO Comment
Notifications posted as comments on the parent epic/feature:
```
🔗 **Cross-Pipeline Trigger**
From: {source_team} - {source_stage}
Event: {event_type}
Type: {BLOCKING|INFORMATIONAL}
Artifact: {artifact_details}
Message: {notification_message}
Timestamp: {iso_timestamp}
```

### Local Trigger File
Trigger metadata stored in fired trigger file for agent processing:
```json
{
  "trigger_id": "{uuid}",
  "timestamp": "{iso_timestamp}",
  "source": {
    "team": "{team}",
    "stage": "{stage_code}",
    "event": "{event_type}"
  },
  "target": {
    "team": "{team}",
    "stage": "{stage_code}"
  },
  "type": "BLOCKING|INFORMATIONAL",
  "artifact": "{artifact_reference}",
  "notification": "{message_text}",
  "status": "FIRED|ACKNOWLEDGED|CLEARED"
}
```

## Blocking vs Informational Dependencies

### BLOCKING Dependencies
Must be satisfied before downstream stage can start. Pipeline coordinator agent:
- Warns user at stage entry if blocking dependency not satisfied
- Shows current upstream status and ETA
- Prevents stage start without explicit override (with risk acknowledgment)
- Examples:
  - Frontend cannot start Stage 08 (Implementation) without Backend Stage 04 (Tech Design) complete
  - DevOps cannot start Deployment without QA SIT complete

### INFORMATIONAL Dependencies
Optional notifications. Pipeline coordinator agent:
- Shows notification at stage entry
- Provides context and upstream milestone details
- Allows immediate stage progression
- Examples:
  - QA notified when Backend Stage 08 complete (context for test planning)
  - Performance notified when QA Stage 10 complete (test scenarios ready)
  - Release Manager notified when Performance testing complete (baseline established)

## Dependency Graph

The complete dependency graph is defined in `pipeline-dependencies.json`. Key principles:
- Each dependency is unidirectional (source → target)
- Multiple targets supported (fan-out)
- Temporal constraints optional (ETA-based warnings)
- Artifact tracking enables traceability

### Dependency Types
- `BLOCKING`: Gate that must be passed
- `INFORMATIONAL`: Notification-only trigger

## Implementation

### Stage Completion Hook
After any stage completes:
1. `post-stage.sh` script calls `trigger-dispatcher.sh`
2. Dispatcher reads completed stage details
3. Dispatcher queries `pipeline-dependencies.json` for matching triggers
4. Dispatcher creates fired trigger files and log entries
5. Dispatcher posts ADO comments on epic/feature

### Coordinator Agent Processing
On pipeline entry or stage start:
1. Agent queries `.sdlc/triggers/pending-triggers.json`
2. Agent filters for blocking dependencies targeting current stage
3. If blocking dependency unsatisfied:
   - Warns user with status and ETA
   - Allows override with risk acknowledgment
4. If informational triggers exist:
   - Shows notifications in summary
   - Proceeds automatically

## Error Handling

### Trigger Failures
- If dispatcher cannot post ADO comment: log error, store trigger in retry queue
- If pipeline-dependencies.json missing/invalid: log error, proceed without automated triggers
- If upstream stage data unavailable: warn coordinator, allow manual override

### Deadlock Prevention
- Cyclic dependencies detected at validation time
- No "wait forever" triggers; all have timeout/override mechanisms
- Informational triggers never block progression

## Monitoring & Observability

### Trigger Metrics
- Total triggers fired per day
- Blocking trigger satisfaction time (SLA: <2 hours)
- Trigger notification delivery success rate
- Most common blocking dependencies

### Logs
- All events logged to `.sdlc/triggers/trigger-log.jsonl`
- Each entry includes: timestamp, source, target, type, status, details

### Debugging
- Trigger history: `jq '.[] | select(.source.team=="backend")' < .sdlc/triggers/trigger-log.jsonl`
- Current pending: `cat .sdlc/triggers/pending-triggers.json | jq`
- Blocking dependency status: Coordinator agent status command
