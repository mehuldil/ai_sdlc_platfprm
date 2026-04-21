---
name: Summary & Close
description: Present summary, close work item, clean up workflow state
phase: 7
requires_stages: [Release Signoff]  # advisory — stage can run independently
gate: Confirm close (advisory)
model: haiku-4-5
token_budget:
  input: 4000
  output: 2000
---

# Summary & Close

## When to Run
Any role can run, typically after Release Signoff approval.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Release Signoff]
   - If completed: load outputs from `.sdlc/memory/15-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Release status, sprint metrics

## Pre-Conditions
- Release Signoff approved
- workflow-state.md: release-status=approved
- All tasks in Dev Complete or resolved state

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- Feature/User Story work item
- All task work items
- workflow-state.md
- code-review-findings.md
- test-execution-report.md

### Load If Available
- git log (for commit count)
- design-doc.md (for summary)

## Execution Steps
1. Gather feature summary:
   - Feature/US ID and title
   - Design approach (1-sentence)
   - Tasks completed (count and list)
   - Code review verdict (APPROVED)
   - Test results (all tests PASSED)
2. Gather implementation details:
   - Commits (count, hash range)
   - Files changed (count and impact)
   - Lines added/deleted
3. Gather documentation status:
   - Architecture docs (updated/not applicable)
   - API docs (updated/not applicable)
   - Wiki status (synced/not applicable)
4. Present comprehensive summary
5. Update ADO:
   - User Story state: Ready for Release → Resolved
   - Add summary comment with all details
6. Clear workflow-state.md: set Pipeline=Inactive
7. For frontend: cleanup temp files, reset workflow state
8. WAIT for confirmation (advisory only)

## Gate Protocol
Present summary → Ask "Confirm Close?" →
- Confirm → update ADO, clear workflow state
- Continue → stay in summary (user decision)

## Output
- summary.md (feature overview, design, implementation, results)
- Resolved User Story in ADO

## ADO Actions
- User Story state: Ready for Release → Resolved
- Add summary comment: "[Summary of work completed]"
- Add tags: pipeline:closed, release:ready
- Link all tasks (should be linked already)
- Clear any blocking tags

## Next Stage Options
- 01-requirement-intake (new feature cycle)
- None (pipeline complete)

## Post-Close Actions
- workflow-state.md: Pipeline=Inactive, clear selected work item
- Notify stakeholders (integration with notification system)
- Archive design docs if applicable
