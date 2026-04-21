---
name: Requirement Intake
description: Fetch and select work item from ADO backlog
phase: 1
requires_stages: []  # advisory — stage can run independently
gate: User selection
model: haiku-4-5
token_budget:
  input: 4000
  output: 2000
---

# Requirement Intake

## When to Run
Any team member can initiate. Typically run by PM or TL to kick off a new feature or task.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: (none)
   - If completed: load outputs from `.sdlc/memory/01-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- ADO work item or PRD link (to begin intake)

## Pre-Conditions
- Azure DevOps project accessible
- Work items exist in backlog (assigned, open state)
- workflow-state.md exists (created if missing)

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- workflow-state.md (current pipeline status)
- ADO backlog (unstarted, assigned items only)

### Load If Available
- recent-selections.md (for context of last 3 items)

## Execution Steps
1. Query ADO: fetch work items where State=Open AND Assigned != null
2. Load workflow-state.md; check for in-progress items
3. Filter by type: Feature, User Story, Task
4. Present numbered list (ID, Title, Type, Assigned, Story Points)
5. WAIT for user selection (number or work item ID)
6. Route by work item type:
   - Feature → go to 02-prd-review
   - User Story → go to 03-pre-grooming (skip PRD)
   - Task → go to 07-task-breakdown (skip design phases)
7. Update workflow-state.md: Pipeline=Active, Selected=<work-item-id>

## Gate Protocol
Present list → Ask "Select item (number or ID):" → Wait for input → Validate selection

## Output
- workflow-state.md updated with selected work item
- Gate outcome: proceed to appropriate next stage based on work item type

## ADO Actions
- Tag: intake:started
- Work item state: remains Open (no state change yet)

## Next Stage Options
- 02-prd-review (if Feature)
- 03-pre-grooming (if User Story)
- 07-task-breakdown (if Task)
