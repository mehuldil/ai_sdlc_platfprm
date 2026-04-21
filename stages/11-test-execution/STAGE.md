---
name: Test Execution
description: Write and run automated tests, present results
phase: 5
requires_stages: [Test Design]  # advisory — stage can run independently
gate: Approve / Fix Failures / Defer
model: sonnet-4-6
token_budget:
  input: 6000
  output: 3000
---

# Test Execution

## When to Run
QA engineer or automation engineer runs test suite. Any role can invoke.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Test Design]
   - If completed: load outputs from `.sdlc/memory/11-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Test cases, test environment

## Pre-Conditions
- Test Design Complete
- Code Review Approved
- Code committed to feature branch
- test-plan.md created

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- test-plan.md
- Feature branch code
- Test framework setup (JUnit 5, Jest, Appium, JMeter)
- workflow-state.md

### Load If Available
- Performance baselines
- Test data fixtures
- Mock/stub configurations

## Execution Steps
1. Load test-plan.md; iterate per test category
2. For Backend (Java):
   - Generate JUnit 5 tests with Mockito
   - Run with `gradle test`
   - Parse Surefire results
3. For Frontend (JavaScript):
   - Generate Jest tests
   - Run with `npm test`
   - Collect coverage report
4. For QA/Mobile (Appium):
   - Invoke test-automation-agent (Java POM model)
   - Invoke test-execution-agent (Surefire parsing)
   - Run Appium suite
5. For Performance (JMeter):
   - Invoke jmx-generator
   - Invoke test-data-generator
   - Execute Argo workflow
   - Parse results vs SLA targets
6. Aggregate results: PASS/FAIL by test category
7. Identify failed tests (root cause if obvious)
8. Present test execution report
9. WAIT for user decision

## Gate Protocol
Present results → Ask "Approve / Fix Failures / Defer?" →
- Approve → all tests green, proceed
- Fix Failures → return to implementation
- Defer → skip to commit-push (with caveat)

## Output
- test-execution-report.md (results by category)
- test-coverage-report.md (if applicable)
- performance-results.md (if perf tests run)
- surefire-report.xml (raw backend results)

## ADO Actions
- Add tag: test:executed
- If all pass: test:green, ready:commit
- If failures: test:failures, needs:fix
- Add comment: "[N] tests executed, [X] passed, [Y] failed, coverage [Z]%"
- Attach test-execution-report.md to Task

## Next Stage Options
- 12-commit-push (if Approve)
- 08-implementation (if Fix Failures — return to implementation)
- 12-commit-push (if Defer — proceed with caveat)
