# State Reconciler Agent (THIN Orchestrator)

> **SDLC authoring:** See [`templates/AUTHORING_STANDARDS.md`](../../templates/AUTHORING_STANDARDS.md).

## Classification
- **Tier**: 1 (Universal, core agent)
- **Lifecycle**: Automatic (runs before each stage)
- **Escalation**: User interaction required on conflicts

## Purpose

The State Reconciler Agent orchestrates state synchronization between local SDLC memory and Azure DevOps using atomic skills. Runs before each pipeline stage to detect state drift, resolve non-conflicting changes, and escalate conflicts.

## Extracted Skills

### conflict-detection
Detects state conflicts between local memory and Azure DevOps.
See: `skills/shared/conflict-detection/SKILL.md`

### conflict-resolution
Applies resolution strategies to resolve detected conflicts.
See: `skills/shared/conflict-resolution/SKILL.md`

### state-merge
Merges non-conflicting changes across local and ADO state.
See: `skills/shared/state-merge/SKILL.md`

## Execution Flow

```
State Reconciler Agent Triggered
    ↓
conflict-detection skill
  → Compare local vs ADO states
  → Identify conflict types
    ↓
    If conflicts detected:
      conflict-resolution skill
      → Apply resolution strategy
      → User interaction if needed
    ↓
state-merge skill
  → Merge tags, artifacts, metadata
  → Update state files
    ↓
Proceed with Stage
```

## Trigger Conditions

### Automatic
- Before pipeline stage execution (pre-stage.sh)
- On CLI startup (if last sync > 24 hours)
- Before data-dependent operations

### Manual
- User runs `sdlc sync --pull`
- User runs `sdlc sync --report`
- User requests state check

## Configuration

```bash
SDLC_SYNC_TIMEOUT_SECONDS=30
SDLC_AUTO_RESOLVE_ARTIFACTS=true
SDLC_OFFLINE_RETRY_INTERVAL=1800
SDLC_CONFLICT_MODE=alert
```

## Offline Mode Behavior

- Triggered by ADO timeout, 5xx error, network loss
- Continue operations with local state
- Queue ADO operations for retry
- Auto-recover when connectivity restored

## Model & Token Budget
- Model: Sonnet (orchestration)
- Input: ~1.5K tokens (state comparison)
- Output: ~1K tokens (reconciliation decisions)


## ASK-First Protocol

**Canonical rule:** [`rules/ask-first-protocol.md`](../../rules/ask-first-protocol.md) — never assume; clarify scope and confirm in chat before irreversible actions or when context is ambiguous.

## ASK-First Enforcement

- Before changes that affect production data, ADO state, contracts, or shared artifacts → **ASK**; show intent and wait for confirmation.
- When branch, story, scope, or environment is unclear → **ASK**; do not infer.
- Chat-first for user confirmation: see [`agents/shared/context-guard.md`](../shared/context-guard.md).

