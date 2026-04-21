---
name: Release Signoff
description: Validate SIT readiness and performance targets before release
phase: 7
requires_stages: [Documentation]  # advisory — stage can run independently
gate: G5-G10 (6 gates: Dev Complete, SIT Certified, PP Certified, Compliance, Perf Check, Release Approval)
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# Release Signoff

## When to Run
Tech lead or release manager validates readiness. Any role can invoke.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Documentation]
   - If completed: load outputs from `.sdlc/memory/14-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- All test results, documentation

## Pre-Conditions
- Documentation complete (or skipped)
- Code merged to main branch (post-SIT)
- workflow-state.md: docs-status=complete

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- ADO work item summary (all tasks, test results)
- test-execution-report.md
- Performance results (if applicable)
- workflow-state.md

### Load If Available
- P0/P1 bugs list
- Unit test results
- Functional test results
- Performance vs NFR targets

## Execution Steps
1. Validate G5 (Dev Complete): all tasks Dev Complete
2. Validate SIT readiness: zero P0/P1 bugs, unit tests green
3. Validate G6 (SIT Certified): SIT test results reviewed
4. Link functional test results to User Story
5. Validate G7 (PP Certified): pre-production sign-off (if applicable)
6. Validate G8 (Compliance): security, accessibility, legal checks
7. For performance tests: run result analysis vs NFR targets
   - Compare actual vs SLA targets
   - Generate GO/NO-GO advisory
   - Validate G9 (Perf Check)
8. Present signoff checklist (all 6 gates)
9. WAIT for Release Approval (G10)

## Gate Protocol
Present readiness checklist (G5-G9) → Ask "Approve Release?" (G10) →
- Approve → apply tags, proceed to close
- Do Not Approve → return to implementation or testing

## Output
- release-signoff-checklist.md (6-gate results)
- performance-validation.md (actual vs targets)
- go-no-go-advisory.md (for perf-dependent features)

## ADO Actions
- Add tags: ready:release, g5:dev-complete, g6:sit-certified, g7:pp-certified, g8:compliant, g9:perf-check (for each gate passed)
- Add tag: g10:approved (if Release Approved)
- User Story state: In Progress → Ready for Release (if all gates pass)
- Add comment: "Release Signoff Complete — all gates passed, ready for production deployment"
- Attach release-signoff-checklist.md

## Next Stage Options
- 15-summary-close (if Release Approved)
- 08-implementation or 11-test-execution (if gates fail)
