---
name: Design Review
description: Review design for compliance, patterns, security, and performance
phase: 3
requires_stages: [System Design]  # advisory — stage can run independently
gate: Approve / Address Concerns / Reject
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# Design Review

## When to Run
Any role can trigger. Architect and tech leads review design.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [System Design]
   - If completed: load outputs from `.sdlc/memory/06-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- System design doc, ADRs

## Pre-Conditions
- Design doc and ADRs produced in 05-system-design
- workflow-state.md: design-status=complete

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- design-doc.md from stage 05
- adr-*.md files
- relevant ADRs from previous projects

### Load If Available
- Security policies
- Performance baselines
- Backward compatibility requirements
- Error handling patterns

## Execution Steps
1. Load design doc and all ADRs
2. Perform 8-check review:
   - ADR Compliance: each tech decision has ADR
   - Architectural Patterns: SOLID, DDD, etc.
   - Security: no secrets in logs, encryption boundaries
   - Performance: scalability, caching strategy
   - Backward Compatibility: API versioning, deprecation
   - Error Handling: exception hierarchy, retry logic
   - Testability: seams for unit/integration tests
   - SPOF Analysis: single points of failure
3. For frontend: invoke module-generator, task-size-controller, designer-extraction skills
4. Present findings (severity: CRITICAL/MAJOR/MINOR)
5. WAIT for user decision

## Gate Protocol
Present review findings → Ask "Approve / Address Concerns / Reject?" →
- Approve → apply tags, proceed
- Address Concerns → update design, loop back
- Reject → return to system design

## Output
- design-review-findings.md (8-check results)
- Updated design-doc.md (if feedback incorporated)
- design-review-summary.md (1-page verdict)

## ADO Actions
- Add tag: design:reviewed (if approved)
- Add tags: design:concerns, blocked:design (if concerns found)
- Add comment: "[X] CRITICAL, [Y] MAJOR, [Z] MINOR findings — [verdict]"
- Link design-review-findings.md to Feature

## Next Stage Options
- 07-task-breakdown (if Design Approved)
- 06-design-review (if Address Concerns — loop back)
- 05-system-design (if Reject — return to previous phase)
