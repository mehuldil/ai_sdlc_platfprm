---
name: Test Design
description: QA engineer designs test cases from ACs and edge cases
phase: 5
requires_stages: [Code Review]  # advisory — stage can run independently
gate: Approve & Create in ADO / Edit / Skip
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# Test Design

## When to Run
QA engineer designs tests. Any role can invoke, QA approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Code Review]
   - If completed: load outputs from `.sdlc/memory/10-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Code changes, acceptance criteria

## Pre-Conditions
- Code Review Approve
- workflow-state.md: code-review-status=approved
- User Stories finalized

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- User Story acceptance criteria
- design-doc.md (for edge cases)
- test-plan-template.md
- code-review-findings.md (findings may trigger additional tests)
- **Module knowledge:** `.sdlc/module/knowledge/known-issues.md` when present
- **Impact rules:** `.sdlc/module/knowledge/impact-rules.md` when present (guides what must not regress)

### Load If Available
- Previous test cases (for similar features)
- Performance requirements
- Broader known issues from team (beyond module KB)

### Token efficiency
- Read **`known-issues.md`** and **`impact-rules.md`** as **focused inputs**; summarize regression risks in the test plan instead of duplicating long KB text.

## Execution Steps
1. Load test-plan-template.md
2. Load User Story ACs; create test cases per AC
3. Design **regression / non-regression** coverage alongside new AC tests: list **existing scenarios, flows, or automated suites** that must still pass (aligned with design **§0** backward-compatibility notes and module **impact-rules**). Include both behavioral regression and, where applicable, adjacent unit/integration tests for unchanged surfaces at risk.
4. Design 5 test categories:
   - Happy Path: happy path scenarios per AC
   - Edge Cases: boundary conditions, null values, empty collections
   - Negative Tests: invalid inputs, security scenarios
   - Analytics Validation: correct events fired, correct payload
   - NFR Validation: performance, scalability, security assertions
5. For QA team: run full STLC analysis:
   - Requirement Analysis: gaps in spec
   - Risk Analysis: high-risk areas
   - Test Case Design: prioritized by risk
6. For performance: generate smoke/load/stress/SLA test cases
7. Create test-plan.md with all test cases (including regression scope from step 3)
8. Assign test case IDs (TC-{id}-{name})
9. Present test plan (grouped by category)
10. WAIT for user decision

## Gate Protocol
Present test plan → Ask "Approve & Create in ADO / Edit / Skip?" →
- Approve & Create → create Tasks in ADO, apply tags
- Edit → show editing interface
- Skip → skip to test execution

## Output
- test-plan.md (all 5 categories, per AC)
- test-case-summary.md (count by category)
- performance-test-cases.md (if applicable)

## ADO Actions
- Create Test Tasks in ADO (if approved)
- Add tags: test:designed, test:automated (for each category)
- Tag by category: test:happy-path, test:edge-cases, test:negative, test:analytics, test:nfr
- Add tag: perf:test (if performance tests created)
- Link to User Story
- Add comment: "Test Design Complete — [N] test cases, [X] high-risk areas identified"

## Next Stage Options
- 11-test-execution (if Approve & Create or Skip)
- 10-test-design (if Edit — loop back)
