---
name: PRD Review
description: PM validates PRD against 7-check framework
phase: 2
requires_stages: [Requirement Intake]  # advisory — stage can run independently
gate: G1 - PRD Approved
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# PRD Review

## When to Run
Product Manager validates Feature PRD. Any role can invoke, but PM approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Requirement Intake]
   - If completed: load outputs from `.sdlc/memory/01-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- PRD document from Stage 01

## Pre-Conditions
- Feature work item selected in 01-requirement-intake
- ADO work item contains PRD link or description
- workflow-state.md shows Pipeline=Active

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- Work item PRD (attached file or linked document)
- workflow-state.md
- prd-gap-analyzer skill configuration

### Load If Available
- Related features or epics
- Previous PRD reviews (for patterns)
- Figma board link (if available)

## Execution Steps
1. Load PRD from work item attachment or link
2. Invoke prd-gap-analyzer skill: 7-check framework
   - Open Questions section completeness
   - Non-Functional Requirements (NFRs) defined
   - Analytics specification present
   - Edge cases documented
   - Figma link and frame labels
   - License/legal considerations
   - POD ownership & dependencies
3. Classify findings: BLOCKING (must fix) vs WARNING (document)
4. For each BLOCKING finding: create Task in ADO, tag blocked:prd-review, link to Feature
5. Present summary: X BLOCKING, Y WARNING findings
6. WAIT for user decision at gate

## Gate Protocol
Present findings list → Ask "Approve PRD / Address Findings?" → 
- Approve → tags applied, proceed
- Address → create tasks, loop back to 02 (or defer)

## Output
- prd-review-findings.md (2-5 blocking, 0-10 warnings)
- Tasks created in ADO for each BLOCKING item
- workflow-state.md: prd-status=approved (or pending)

## ADO Actions
- Add tags: prd:reviewed, ready:pre-grooming (if approved)
- Add tags: blocked:prd-review (if blocking items exist)
- Create blocking Tasks linked to Feature
- Add comment: "PRD Review Complete — 7-check: [results]"
- Work item state: remains Open until next stage

## Next Stage Options
- 03-pre-grooming (if PRD Approved)
- 02-prd-review (if Address Findings selected — loop back)
