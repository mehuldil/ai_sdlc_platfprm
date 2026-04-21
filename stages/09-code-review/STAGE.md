---
name: Code Review
description: Review code across 8 dimensions with stack-specific checks
phase: 9
requires_stages: [Implementation]  # advisory — stage can run independently
gate: Approve / Fix / Block
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# Code Review

## When to Run
Team lead or architect reviews code. Any role can invoke, TL/architect approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Implementation]
   - If completed: load outputs from `.sdlc/memory/09-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Feature branch diff, design doc

## Pre-Conditions
- Code committed to feature branch
- All tasks in Implementation Complete state
- workflow-state.md: implementation-status=complete

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- Module Knowledgebase (.sdlc/module-kb/) — if available
  - api-surface.md (check API consistency)
  - change-impact-rules.md (verify impact analysis)
  - known-issues.md (check for similar past bugs)
- Feature branch git diff
- design-doc.md (for consistency check)
- variant-specific checks: variants/{stack}-checks.md

### Load If Available
- Security policies
- Performance baselines
- Code style guide
- Previous reviews (for patterns)

## Execution Steps
1. Load git diff for entire feature branch
2. Perform 8-dimension review:
   - Correctness: logic matches spec, no obvious bugs
   - Security: secrets not logged, SQL parameterized, RBAC enforced
   - Performance: no N+1 queries, caching used appropriately
   - Maintainability: naming clear, DRY principle, comments where needed
   - Test Coverage: happy path + edge cases covered
   - Standards Compliance: matches project style, linter clean
   - Regression Risk: identifies risky changes, affected components
   - Story AC Verification: Do code changes implement the story acceptance criteria? Map each changed file to the AC it fulfills. Flag code that doesn't trace to any AC (potential scope creep). Flag ACs that have no corresponding code changes (incomplete implementation).
3. Load stack-specific checks from variants/{stack}-checks.md
   - Java: TEJ exception hierarchy, Kafka singleton producer, parameterized SQL, SLF4J only, try-with-resources
   - Frontend: platform QA agents validate (Android QA, iOS QA, RN QA)
   - Additional: architecture guardian, dependency watchdog, security reviewer, crash monitor, performance profiler, memory budget controller
4. Classify findings: CRITICAL (must fix) | MAJOR (3+ must discuss) | MINOR (good to fix)
5. Present findings list with severity
6. WAIT for user decision

## Gate Protocol
Present findings → Ask "Approve / Fix / Block?" →
- Approve → apply tags, proceed to commit-push
- Fix → mark changes, loop back to implementation
- Block → identify root cause (design flaw), return to design-review

## Output
- code-review-findings.md (8-dimension results with story AC traceability)
  - Sections: Correctness, Security, Performance, Maintainability, Test Coverage, Standards Compliance, Regression Risk, Story AC Traceability
  - Story AC Traceability section includes:
    - ACs implemented: [list]
    - ACs missing implementation: [list]
    - Code changes without AC mapping: [list] (potential scope creep)
- code-review-summary.md (verdict & action items)

## ADO Actions
- Add tag: reviewed:approved (if Approve)
- Add tags: reviewed:issues, needs:fixes (if Fix)
- Add tag: reviewed:blocked, design:needs-revision (if Block)
- Add comment: "[X] CRITICAL, [Y] MAJOR, [Z] MINOR — [verdict]"
- Task state: Code Complete → Review Complete (if Approve)
- Task state: Code Complete → In Progress (if Fix)

## Next Stage Options
- 10-test-design (if Approve)
- 08-implementation (if Fix — loop back to implementation)
- 05-system-design (if Block — return to design phase)
