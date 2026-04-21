---
name: boss
display: BOSS (Executive)
default_stack: null
default_workflow: boss-report
model_preference: balanced
---

# BOSS (Executive)

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

This role operates outside standard SDLC stages. Instead, it defines custom report stages:

- **sprint-health** — Generate sprint health dashboard with burndown, velocity, capacity, risk flags
- **release-readiness** — Assess release gate status, test coverage, P0/P1 items, go/no-go decision
- **dependency-tracker** — Monitor cross-team blockers, critical path status, integration readiness

## Capabilities (Non-Standard)

The BOSS role queries Azure DevOps (ADO) for:

- Work item state (To Do, In Progress, Done, Blocked)
- Sprint burndown (actual vs. planned velocity)
- Blocked items and root causes
- Release gates and pass/fail status
- Team velocity trends (past 5 sprints)
- Resource capacity and allocation

## Memory Scope

### Always Load
- `sprint-context/` — Current sprint goals, capacity, team velocity
- `dependency-graph.md` — Cross-team dependencies, critical path, blocking relationships
- `release-state.md` — Release gates (design, impl, test, perf), gate status, sign-off decisions

### On Demand
- `risk-register.md` — Known risks, mitigation plans, impact assessments
- `capacity-plan.md` — Team allocation, planned time off, skill distribution
- `adr/` — Architecture decisions affecting release or cross-team coordination

## Quick Start

```bash
# Switch to BOSS role
sdlc use boss

# Generate sprint health dashboard
sdlc run sprint-health --sprint=<sprint-id>

# Assess release readiness
sdlc run release-readiness --release=Q2-V1.5

# View cross-team dependency status
sdlc run dependency-tracker --view=blocking-items

# Get executive summary (all three reports)
sdlc run boss-report --sprint=<sprint-id> --release=Q2-V1.5

# Check for P0/P1 items blocking release
sdlc run release-readiness --filter=critical --release=Q2-V1.5
```

## Sprint Health Dashboard

Provides current sprint status at a glance:

- **Burndown Chart** — Planned vs. actual work completed (by story points)
- **Velocity Trend** — Past 5 sprints, current sprint forecast
- **Blocked Items** — Count, root cause, owner, ETA for unblock
- **Capacity Status** — Team utilization, time off, allocation conflicts
- **Risk Flags** — Items trending red, dependencies at risk, integration readiness

Query ADO for:
```
SELECT COUNT(*) WHERE State='Done' AND [Iteration Path]='@CurrentIteration'
SELECT COUNT(*) WHERE State='In Progress' AND [Iteration Path]='@CurrentIteration'
SELECT COUNT(*) WHERE State='Blocked' AND [Iteration Path]='@CurrentIteration'
```

## Release Readiness Report

Assesses go/no-go for release:

- **Gate Status** — design-review (gate), code-review (gate), test-execution (80% coverage), perf-signoff (gate)
- **P0/P1 Items** — Outstanding critical bugs, remediation ETA
- **Integration Points** — Cross-pod dependencies, contract validation, deployment readiness
- **Deployment Checklist** — Infrastructure ready, runbooks complete, monitoring configured

Query ADO for:
```
SELECT * WHERE Tag='release-gate' AND Release='<release-id>'
SELECT COUNT(*) WHERE Severity='P0' OR Severity='P1' AND [Iteration Path] IN release scope
SELECT * WHERE Tag='release-signoff' AND Release='<release-id>'
```

## Dependency Tracker

Monitors cross-team blockers and critical path:

- **Blocking Items** — Teams blocked, root cause, ETA to unblock
- **Critical Path** — Minimum sequence to release, currently on-path indicators
- **Contract Status** — Inter-service contracts validated, integration tests passing
- **Sequencing** — Release order for multi-pod deployments

Queries cross-team-dependencies.md and dependency-graph.md for:
- Predecessor/successor relationships
- Integration readiness (contract validated)
- Blocking team and owner
- Mitigation plans

## Memory Management

### Syncing Shared Memory
```bash
# Load current sprint context
sdlc memory sync sprint-context/

# Review cross-team dependencies
sdlc memory sync dependency-graph.md

# Check release gate status
sdlc memory sync release-state.md

# Review risk register
sdlc memory sync risk-register.md
```

### Publishing Your Decisions
```bash
# After sprint-health run, publish sprint summary
sdlc memory publish --file=sprint-context/sprint-summary-<date>.md --scope=leadership

# After release-readiness, publish go/no-go decision
sdlc memory publish --file=release-state.md --notify=all-teams

# Document executive decisions and blockers
sdlc memory publish --file=adr/release-decision-Q2-V1.5.md --scope=leadership
```

## Working with Other Roles

- **TPM** — Provide sprint health and release readiness inputs; escalate blockers
- **Product** — Validate epic prioritization and roadmap alignment
- **Engineering Leads** — Discuss team capacity, velocity trends, risk mitigation
- **Ops/SRE** — Coordinate release timing, infrastructure readiness, deployment windows
- **All Roles** — Consume sprint health and release readiness reports for transparency

## Key Metrics for BOSS Reports

**Sprint Health:**
- Sprint velocity (story points completed)
- Burndown pace (ideal vs. actual)
- Blocked items count and duration
- Team capacity utilization (%)
- Risk flags (items trending red)

**Release Readiness:**
- Gate pass rate (%) (design, impl, test, perf)
- Test coverage (%) (line, branch, critical path)
- P0/P1 item count
- Critical path on-time indicator
- Integration test pass rate (%)

**Dependency Tracker:**
- Blocking items count
- Critical path length (days)
- Contract validation status
- Sequencing plan confidence (%)

## Example ADO Queries

```
# Blocked items in current sprint
SELECT [ID], [Title], [State], [Assigned To], [Tags]
WHERE State='Blocked' AND [Iteration Path]='@CurrentIteration'
ORDER BY [Created Date] DESC

# P0/P1 items in release scope
SELECT [ID], [Title], [Severity], [State], [Assigned To]
WHERE (Severity='P0' OR Severity='P1')
AND [Release]='Q2-V1.5'
ORDER BY Severity, [Created Date]

# Release gate status
SELECT [ID], [Title], [State], [Tag]
WHERE Tag='release-gate'
AND [Release]='Q2-V1.5'
GROUP BY [Tag], State
```

## Troubleshooting

**Q: Why is sprint burndown trending red?**
A: Load sprint-context/ to review team capacity and allocation. Check for blocked items. Run sprint-health with --drill-down=true to see item-level details. Escalate to TPM for unblocking.

**Q: Can we release this week?**
A: Run release-readiness with --release=<release-id>. Verify all gates passed. Check critical-path status. If blockers exist, review dependency-tracker and risk-register. Escalate go/no-go decision to TPM.

**Q: Which team is blocking our release?**
A: Run dependency-tracker with --view=blocking-items. Filter by release. Identify blocking team and root cause. Load cross-team-dependencies.md for mitigation plan. Notify blocking team and escalate if needed.

**Q: What's our velocity trend?**
A: Run sprint-health with --trend=5-sprints to see past 5 sprints. Compare to sprint-context/capacity-plan.md. If declining, investigate: staffing changes, tech debt, dependency delays. Discuss with engineering lead.
