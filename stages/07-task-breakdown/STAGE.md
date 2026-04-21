---
name: Task Breakdown
description: PM derives independently-implementable tasks from design
phase: 4
requires_stages: [Design Review]  # advisory — stage can run independently
gate: Approve & Create in ADO / Edit / Reject
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# Task Breakdown

## When to Run
Product Manager breaks down design into implementation tasks. Any role can invoke, PM approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Design Review]
   - If completed: load outputs from `.sdlc/memory/07-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Approved design, story points

## Pre-Conditions
- Design Review Complete
- design-doc.md and ADRs finalized
- workflow-state.md: design-review-status=approved

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- design-doc.md
- User Stories (4N stories from grooming)
- workflow-state.md

### Load If Available
- Team velocity metrics
- Dependency graph
- Risk assessment

## Execution Steps
1. Load design doc; parse tech decisions and modules
2. For each module/component, derive tasks:
   - Task is independently implementable
   - Task has clear acceptance criteria
   - Task ordered by logical dependency (no circular deps)
3. Assign task metadata:
   - Story type: Backend, Frontend (platform-specific), QA, DevOps
   - Story points estimate
   - Blockers: backend, analytics:required, etc.
4. Create task objects (ADO format)
5. Link each task to parent User Story
6. Generate dependency ordering (critical path)
7. Present task list with dependency graph
8. WAIT for approval

## Gate Protocol
Present task list → Ask "Approve & Create in ADO / Edit / Reject?" →
- Approve → create tasks in ADO, apply tags
- Edit → show editing interface
- Reject → return to design review

## Output
- tasks.md (task definitions with ACs)
- task-dependency-graph.md (Mermaid diagram)
- task-summary.md (by stack, by story, by person)

## ADO Actions
- Create Tasks in ADO (if approved)
- Add tags: claude:generated, task:breakdown
- Add stack-specific tags: backend:java, frontend:android, frontend:ios, frontend:rn, frontend:web, qa:automated, perf:test
- Add blocking tags if applicable: dependency:external, blocked:backend, analytics:required
- Link to User Story
- Add comment: "Task Breakdown Complete — [N] tasks created, critical path [M] days"

## Next Stage Options
- 08-implementation (if Approve & Create)
- 07-task-breakdown (if Edit — loop back)
- 06-design-review (if Reject — return to previous phase)
