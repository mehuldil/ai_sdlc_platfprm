# State Reconciliation Protocol

## Overview

The ADO sync pipeline operates in push-only mode, creating the potential for state drift between local memory and Azure DevOps. This protocol establishes a bi-directional reconciliation framework to maintain consistency and ensure ADO remains the source of truth while preserving local artifacts and context.

## Core Principles

1. **ADO is Source of Truth**: Work item status, assignments, and metadata on ADO represent the authoritative state
2. **Local Artifacts Preserved**: Local memory retains AI context, reasoning, and intermediate artifacts
3. **Pull Before Push**: Every action begins with ADO state retrieval to detect divergences
4. **Transparent Drift Detection**: Users are informed of any conflicts and presented with clear resolution options
5. **Graceful Degradation**: System continues operating in offline mode with conflict flagging for later resolution

## Pre-Stage Sync Process

### Trigger
- Automatically runs before each pipeline stage execution
- Can be manually triggered via `./scripts/ado-state-sync.sh`
- Runs on CLI startup if age of last sync exceeds `sync_max_age_hours` (default: 24 hours)

### Steps
1. Read active story ID from `.sdlc/state.json`
2. If no active story, skip to offline queue check
3. Invoke ADO MCP to fetch current work item state:
   - Status/State field
   - Assignee
   - Tags
   - Comments (last N, configurable)
   - Attachments
   - Iteration path
   - Updated timestamp
4. Compare retrieved state against local state in `.sdlc/memory/{story-id}/state.json`
5. Execute conflict detection and resolution
6. Update `memory_synced_at` timestamp
7. Log all actions to `.sdlc/sync-log.json`

## Conflict Detection

### Comparison Matrix

| Aspect | Detection Method | Scope |
|--------|------------------|-------|
| Status | Compare `status` fields exactly | If differ, conflict exists |
| Assignee | Compare `assignee` field | If differ, conflict exists |
| Tags | Set difference (ADO tags ∩ local tags) | Log missing/extra tags |
| Comments | Compare ADO comment count vs local | If ADO > local, comments need pull |
| Attachments | Compare ADO attachment list vs local | If ADO > local, attachments need pull |
| Timestamps | ADO `updated_at` vs local `synced_at` | Determine recency |

### Drift Definition
- **Minor Drift**: Non-status artifacts differ (comments, attachments, tags)
- **Major Drift**: Status or assignee differ
- **Critical Drift**: Unresolved conflicts persist >24 hours

## Resolution Rules

### Rule 1: Status Divergence
**Condition**: Local status ≠ ADO status

**Resolution**:
- ADO wins automatically if local changes are unsaved work
- If local state represents intended progress (in-memory edits), present user choice:
  1. Accept ADO status (revert local changes)
  2. Push local status to ADO (override ADO)
  3. Manual merge (user reviews both states)

**Example**: Local memory shows "In Review" but ADO shows "To Do"
- If local is unstaged scratch work → ADO wins
- If local represents intended progress → User chooses

### Rule 2: Missing Artifacts in ADO
**Condition**: Local memory has artifacts (code snippets, attachments, comments) not in ADO

**Resolution**:
- Automatically queue these for push
- Create ADO comments with artifact metadata
- Attach files to work item
- Log as "artifact sync required"
- Retry on next push opportunity

### Rule 3: ADO Newer Comments/Context
**Condition**: ADO comments count > local comments count, or ADO `updated_at` > local `synced_at`

**Resolution**:
- Automatically pull latest ADO comments into local memory
- Update `.sdlc/memory/{story-id}/ado-context.json` with comment thread
- Preserve local context without overwrite
- Update `last_ado_sync_at` timestamp
- Log pull action

### Rule 4: Tag Mismatch
**Condition**: ADO tags ≠ local tags

**Resolution**:
- Auto-pull ADO tags (source of truth)
- Update local tag set in state.json
- Log tag additions/removals
- Warn if critical tags removed (e.g., "blocked", "security")

### Rule 5: Assignee Change
**Condition**: Local `assignee` ≠ ADO `assignee`

**Resolution**:
- ADO assignee is source of truth (external reassignment)
- Update local state immediately
- Alert user if reassigned away from current user
- Log assignee change with timestamp
- Pause local work if reassigned to others

## Sync Timestamp Management

### `memory_synced_at` Field
- **Location**: `.sdlc/state.json` → `.metadata.memory_synced_at`
- **Format**: ISO 8601 timestamp with timezone (e.g., `2026-04-11T14:30:22Z`)
- **Updated**: After every successful sync operation
- **Reset**: When state.json is created or reset
- **Query**: Used to determine if sync is stale (> 24h old)

### Timestamp Accuracy
- Set immediately after successful ADO pull
- Do NOT set if sync fails (preserve last valid timestamp)
- Do NOT set for purely local operations
- Set to `null` if offline mode is activated

### Related Timestamps
- `.metadata.memory_created_at`: When local state was initialized
- `.metadata.last_ado_push_at`: When last push to ADO succeeded
- `.metadata.last_ado_pull_at`: When last pull from ADO succeeded
- `.metadata.sync_status`: "synced" | "unsynced" | "conflict" | "offline"

## Drift Alerting

### Alert Conditions

**Warning Level** (24+ hours unsynced):
```
⚠️  State not synced for 24+ hours
   Last sync: 2026-04-09T14:30Z (48 hours ago)
   Potential drift in status, comments, or assignments
   Run: sdlc sync --pull
```

**Error Level** (48+ hours unsynced):
```
❌ Critical drift detected: Local state >48h old
   Last sync: 2026-04-08T14:30Z
   ADO may have updates not in local memory
   Action required: Review ADO state before proceeding
   Run: sdlc sync --report
```

**Conflict Level** (unresolved conflicts):
```
🔄 Conflicting state detected:
   Local status: "In Review" | ADO status: "To Do"
   Local updated: 2026-04-11T10:00Z | ADO updated: 2026-04-11T12:00Z
   Choose resolution:
   1) Accept ADO state (lose local changes)
   2) Push local state (override ADO)
   3) Manual merge
```

### User Attention Triggers
- Status divergence detected
- Assignee changed in ADO
- ADO has comments not in local memory
- Sync fails 3+ consecutive times
- Offline mode activated

## Offline Mode

### Activation Conditions
- ADO MCP connection fails
- Network timeout (>30 seconds)
- ADO API returns 5xx error
- User explicitly runs `sdlc sync --offline`

### Offline Behavior
1. Log failure reason to `.sdlc/sync-log.json`
2. Mark state as `"sync_status": "offline"`
3. Set `memory_synced_at` to `null`
4. Continue operations with local state only
5. Queue all pending changes for next sync
6. Alert user:
   ```
   ⚠️  Offline mode: Operating with local state only
       Changes will sync when connection restored
       Synced pending: 3 artifacts, 2 status changes
   ```

### Pending Sync Queue
- Location: `.sdlc/pending-sync.json`
- Structure: Array of operations with timestamps and status
- Retry Strategy: Exponential backoff, max 5 retries over 24h
- Clear on Success: Remove operation after successful push/pull

### Offline Recovery
1. When connection restored, automatically attempt sync
2. Execute pending operations in chronological order
3. Detect and resolve any conflicts from offline period
4. Report results to user
5. Set `sync_status` back to "synced" if all operations succeed

## Implementation Checklist

- [ ] State-reconciler-agent runs before each stage
- [ ] `ado-state-sync.sh` script handles pull/compare/log operations
- [ ] `.sdlc/state.json` includes `memory_synced_at` field with actual timestamp management
- [ ] `.sdlc/sync-log.json` captures all sync operations
- [ ] Conflict detection presents clear user choices
- [ ] ADO MCP integration handles network failures gracefully
- [ ] Offline queue persists and retries automatically
- [ ] 24h drift alert triggers as configured
- [ ] Documentation explains sync behavior to users

## Monitoring & Troubleshooting

### Sync Log Analysis
```bash
# View recent sync operations
cat .sdlc/sync-log.json | jq '.[-10:]'

# Check for conflicts
cat .sdlc/sync-log.json | jq '.[] | select(.conflict == true)'

# Monitor offline queue
cat .sdlc/pending-sync.json | jq '.[] | select(.status == "pending")'
```

### Common Issues

| Issue | Cause | Resolution |
|-------|-------|-----------|
| `memory_synced_at` stays null | Sync never succeeds | Check ADO connectivity, review sync-log |
| Status conflict after ADO update | Pull didn't trigger | Run `sdlc sync --pull` manually |
| Offline queue grows unbounded | Connection persistently fails | Investigate ADO MCP, check network |
| Comments not syncing | ADO comments endpoint down | Check ADO status, retry after delay |

## Configuration

### Environment Variables
```bash
SDLC_SYNC_MAX_AGE_HOURS=24          # Alert if unsynced >24h
SDLC_SYNC_TIMEOUT_SECONDS=30        # Max time for ADO call
SDLC_OFFLINE_RETRY_INTERVAL=3600    # Offline queue retry interval
SDLC_AUTO_RESOLVE_ARTIFACTS=true    # Auto-pull non-status changes
SDLC_CONFLICT_MODE=alert            # alert | manual | auto (not recommended)
```

### Files Modified
- `.sdlc/state.json` - Add/update `memory_synced_at`
- `.sdlc/sync-log.json` - All sync operations logged
- `.sdlc/pending-sync.json` - Offline queue (created if needed)
- `.sdlc/memory/{story-id}/ado-context.json` - ADO comment thread cache

