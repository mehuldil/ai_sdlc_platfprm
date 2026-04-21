---
name: Pre-Grooming
description: TPM validates PRD against template and Figma specs
phase: 2
requires_stages: [Requirement Intake, PRD Review]  # advisory — stage can run independently
gate: G2 - Pre-Grooming Complete
model: sonnet-4-6
token_budget:
  input: 6000
  output: 2500
---

# Pre-Grooming

## When to Run
Tech Product Manager validates PRD structure. Any role can invoke, TPM approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Requirement Intake, PRD Review]
   - If completed: load outputs from `.sdlc/memory/03-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- PRD + gap analysis

## Pre-Conditions
- Feature work item selected
- PRD Review complete (or User Story entered at intake)
- workflow-state.md shows Pipeline=Active

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- PRD document
- prd-template.md (sections §6, §8, §12)
- workflow-state.md

### Load If Available
- Figma board link
- Analytics spec document
- Cross-pod dependency map

## Execution Steps
1. Load PRD and validate against template sections:
   - §6 User Flows: present and detailed
   - §8 Analytics Specification: approved status confirmed
   - §12 Open Questions: all answered or documented
2. Invoke pre-grooming-brief skill:
   - Validate Figma frames labeled with COMPONENT, INTERACTION, EVENT, API
   - Verify all interactive elements have frames
   - Check frame naming convention (CamelCase + type suffix)
3. Confirm Analytics Spec state = "Approved"
4. Verify cross-pod dependencies have ADO Predecessor links
5. Present validation summary: X issues found, Y validations passed
6. WAIT for user decision

## Gate Protocol
Present summary → Ask "Approve Pre-Grooming / Request Changes?" →
- Approve → tags applied, proceed
- Request Changes → update PRD, loop back

## Output
- pre-grooming-validation.md (checklist results)
- workflow-state.md: pregrooming-status=complete

## ADO Actions
- Add tags: pregrooming:complete, ready:grooming (if approved)
- Add tags: blocked:pre-grooming (if issues found)
- Add comment: "Pre-Grooming Complete — [X] Figma frames valid, Analytics spec approved"

## Next Stage Options
- 04-grooming (if Pre-Grooming Approved)
- 03-pre-grooming (if Request Changes — loop back)
