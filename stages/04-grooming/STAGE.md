---
name: Grooming
description: EM orchestrates story generation and validation
phase: 3
requires_stages: [Pre-Grooming]  # advisory — stage can run independently
gate: G3 - Grooming Complete
model: opus-4-6
token_budget:
  input: 8000
  output: 4000
---

# Grooming

## When to Run
Execution Manager orchestrates story creation. Any role can invoke, human approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Pre-Grooming]
   - If completed: load outputs from `.sdlc/memory/04-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Pre-grooming brief, team availability

## Pre-Conditions
- Pre-Grooming Complete
- workflow-state.md: pregrooming-status=complete
- User Story created and linked to Feature

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- Feature PRD and acceptance criteria
- User Story work item
- workflow-state.md

### Load If Available
- Previous stories (for pattern consistency)
- Team velocity data
- Technical constraints doc

## Execution Steps
1. Invoke grooming-conflict-detector skill: check for contradictions in ACs
2. Invoke dependency-tagger skill: map story dependencies
3. Invoke contract-generator skill: create API contracts for each journey
4. Invoke story-generator skill: create 4 story types per user journey:
   - Product Story (user-facing feature)
   - Backend + Database Story
   - Frontend (iOS, Android, React Native, Web)
   - QA Story (test cases)
5. Invoke story-validator skill: 8 checks on 17-section format v2.0
   - ACs well-formed
   - Story points realistic
   - No external dependencies missing
   - Design references present
   - Tech tasks separated
6. Present stories in ADO format (ready to create)
7. WAIT for user approval

## Gate Protocol
Present 4 story types × N journeys → Ask "Approve & Create in ADO / Edit / Reject?" →
- Approve → create tasks, apply tags
- Edit → show edit form
- Reject → return to grooming

## Output
- 4N user stories in 17-section format v2.0
- stories.md (all stories ready for ADO creation)
- Story-validator report (8-check results)

## ADO Actions
- Create User Stories in ADO (if approved)
- Add tags: grooming:complete, ready:sprint, claude:generated
- Tag by story type: story:product, story:backend, story:frontend, story:qa
- Link to Feature
- Add comment: "Grooming Complete — [N] journeys, [4N] stories, all validations passed"

## Next Stage Options
- 05-system-design (if Grooming Approved)
- 04-grooming (if Edit selected — loop back)
