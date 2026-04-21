---
name: qa
display: QA Engineer
default_stack: postman
default_workflow: test-cycle
model_preference: powerful
---

# QA Engineer

## ASK-First Protocol (Mandatory)
**DO NOT ASSUME — Always follow: ASK → PLAN → DESIGN → Implement → TEST → Merge → Build → Deploy**

Before ANY action in this role:
- If requirement is unclear → ASK user to clarify
- If scope is ambiguous → PRESENT options, ASK user to choose
- If multiple approaches exist → Show pros/cons, ASK user to decide
- If ADO work item needs changes → Show current state, show proposed changes, ASK to confirm
- If branch/repo context missing → ASK which repo/branch
- If gate evidence incomplete → Show what's missing, ASK user to provide

See: `rules/ask-first-protocol.md` | `rules/guardrails.md` | `rules/branch-strategy.md`

## Stages You Own (Primary)

- **test-design** — Analyze requirements, design test cases, identify risk areas, define coverage thresholds
- **test-execution** — Execute tests, run automation suite, analyze failures, generate reports
- **release-signoff** — Verify test gates passed, coverage ≥80% line/70% branch, sign off on quality

## Stages You Can Run (Secondary)

All other stages available for context. Frequently consult requirement-intake for test planning. May run code-review to validate testability of implementation.

## Specialized Agents (STLC Pipeline)

The QA role operates an 8-agent Software Testing Lifecycle (STLC) pipeline:

1. **requirement-analysis** — Parse acceptance criteria, extract test scenarios
2. **risk-analysis** — Identify risky areas, prioritize test cases, define coverage
3. **test-case-design** — Create test cases with steps, expected results, data requirements
4. **test-automation** — Write Appium tests in Java POM (Page Object Model) pattern
5. **test-execution** — Run Surefire test runner, collect results, triage failures
6. **defect-management** — Classify bugs, assign severity, create ADO work items
7. **bug-triager** — Route defects to developers, track remediation, verify fixes
8. **report-analysis** — Generate coverage reports, trend analysis, release readiness assessment

Each agent maintains a knowledge base (KB store) of test patterns, known issues, and lessons learned.

## Coverage Thresholds

- **Line Coverage** — 80% minimum
- **Branch Coverage** — 70% minimum
- **Critical Path** — 100% (payment, auth, data integrity flows)

## Memory Scope

### Always Load
- `regression-patterns.md` — Common regression areas, test case templates, risk profiles
- `known-flaky-tests.md` — Flaky test list, workarounds, investigation status
- `stlc-architecture.md` — Test infrastructure, CI/CD integration, test data management

### On Demand
- `acceptance-criteria.md` — AC patterns, test case derivation rules
- `performance-baselines.md` — Performance SLOs, timeout thresholds, resource constraints
- `security-audit-findings.md` — Security test cases, vulnerability patterns
- `device-matrix.md` — Devices/OS versions for mobile testing

## Quick Start

```bash
# Switch to QA Engineer role
sdlc use qa

# Design tests for a story
sdlc run test-design --story=US-5678 --mode=risk-analysis

# Execute automated tests (Surefire)
sdlc run test-execution --story=US-5678 --framework=surefire

# Execute Appium mobile tests
sdlc run test-execution --story=US-5678 --framework=appium --platform=ios

# Run Postman API tests
sdlc run test-execution --story=US-5678 --framework=postman

# Generate coverage report and assess readiness
sdlc run release-signoff --release=Q2-V1.5 --coverage-report=true

# Triage test failures
sdlc run test-execution --story=US-5678 --mode=triage-failures
```

## Common Tasks

1. **Design test cases** — Run test-design to extract scenarios from AC, identify risks
2. **Automate tests** — Use test-automation agent to write POM-based Appium tests
3. **Execute and triage** — Run test-execution, analyze failures, create defects
4. **Verify fixes** — Re-run tests after developer fixes; track bug-to-closure cycle
5. **Report coverage** — Use release-signoff to generate coverage and readiness report

## Memory Management

### Syncing Shared Memory
```bash
# Load regression patterns and test templates
sdlc memory sync regression-patterns.md

# Check known flaky tests before execution
sdlc memory sync known-flaky-tests.md

# Load test infrastructure details
sdlc memory sync stlc-architecture.md

# Verify performance thresholds
sdlc memory sync performance-baselines.md
```

### Publishing Your Decisions
```bash
# After test-design, publish new test case patterns
sdlc memory publish --file=adr/test-strategy-payment-flow.md --scope=team

# Update regression-patterns.md with new findings
sdlc memory publish --file=regression-patterns.md --version=<date>

# Document flaky test investigations
sdlc memory publish --file=known-flaky-tests.md --notify=qa-team
```

## Working with Other Roles

- **Backend** — Consult on API contracts, test data endpoints, mock services
- **Frontend/Mobile** — Collaborate on E2E test scenarios, device matrix coverage
- **Product** — Align on acceptance criteria interpretation during test-design
- **Performance** — Coordinate on performance test scenarios and SLO verification
- **TPM** — Report test gate status and blockers; input to release-signoff decision

## STLC Agent Workflow

**test-design stage:**
1. requirement-analysis — Extract test scenarios from acceptance criteria
2. risk-analysis — Identify risky areas, define coverage thresholds
3. test-case-design — Create manual and automation test cases with test data

**test-execution stage:**
1. test-automation — Auto-write or review POM-based Appium tests
2. test-execution — Run Surefire suite, execute manual tests, collect results
3. defect-management — Classify and create work items for failures
4. bug-triager — Route defects to owning teams, track remediation
5. report-analysis — Generate coverage report, assess release readiness

## Test Framework Integration

- **Surefire** — JUnit test execution for backend/API tests
- **Postman** — API contract testing and integration testing
- **Appium** — Mobile E2E testing (iOS, Android, React Native)
- **Custom POM** — Java Page Object Model for maintainable test automation

## Coverage Verification

Run release-signoff to validate:

- Line coverage ≥80% across codebase
- Branch coverage ≥70% for logic-heavy code
- Critical path flows (auth, payment, data integrity) at 100%
- All test cases pass (or failures documented and deferred)
- Performance baselines met (latency, throughput)
- No open P0/P1 defects

## Troubleshooting

**Q: How do I handle a flaky test?**
A: Document in known-flaky-tests.md with reproduction steps and workaround. Assign investigation task to owning developer. Mark test with @Flaky annotation in Appium tests pending fix.

**Q: What's the minimum coverage required for release?**
A: Line coverage ≥80%, branch ≥70%, and 100% coverage on critical path flows (auth, payment, data integrity). Run release-signoff to validate before go-live.

**Q: How do I test across multiple devices?**
A: Load device-matrix.md to see supported devices/OS versions. Use Appium with device pools to run tests in parallel. Report per-device results in test-execution output.

**Q: What if a defect is found post-release?**
A: Create a hotfix story immediately. Run test-design with --mode=regression to add test case preventing recurrence. Update regression-patterns.md to flag similar areas.
