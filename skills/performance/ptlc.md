# Performance Testing Lifecycle (PTLC)

**Team**: Performance  
**Model**: Varies by phase  
**Trigger**: `sdlc perf start <story-id>`  
**Complexity**: Expert  
**Status**: Production Ready

---

## Overview

The Performance Testing Lifecycle (PTLC) is an 8-phase end-to-end workflow for performance testing. It takes performance requirements from a user story through execution, analysis, and Go/No-Go release decision.

This skill orchestrates coordination between multiple specialized agents:
- **perf-architect** — SLA extraction, planning, test design (Opus 4.6)
- **perf-builder** — JMeter script + test data generation (Sonnet 4.6)
- **perf-executor** — Git push, infrastructure validation (Haiku 4.5)
- **perf-analyst** — Test execution, result analysis (Sonnet 4.6)
- **perf-reporter** — Performance report + risk assessment (Sonnet 4.6)
- **Human** — Release approval (JIRA/ADO sign-off)

**Total Duration**: 5-10 business days (full pipeline)  
**Parallel Phases**: G4 and G5 can run simultaneously  
**Entry Points**: 6 (start at any phase)

---

## Phases (G1-G8)

| Phase | Agent | Duration | Purpose | Gate |
|-------|-------|----------|---------|------|
| **G1** | perf-architect | 4-6h | Requirement analysis, SLA extraction | Product Owner |
| **G2** | perf-architect | 3-4h | Planning, module selection, load shapes | Tech Lead + Infra |
| **G3** | perf-architect | 4-6h | Test case design, scenarios, assertions | QA Lead + Perf Eng |
| **G4** | perf-builder | 6-8h | JMeter script generation, properties | Architect (GUI review) |
| **G5** | perf-builder | 3-4h | Test data generation (CSV), validation | QA Lead |
| **G6** | perf-executor | 2-3h | Git push, pre-push validation, Argo trigger | DevOps (PR merge) |
| **G7** | perf-analyst | 4-6h | Test execution, result analysis, SLA comparison | Perf Engineer |
| **G8** | perf-reporter | 2-3h | Report generation, risk assessment, GO/NO-GO | **Release Manager** |

---

## Full Pipeline Workflow

```
User Story (ADO)
      ↓
 ┌─────────────────────────────────────────────────────┐
 │ G1: Requirement Analysis (perf-architect)           │
 │ Input: Story, PRD, SLA docs                          │
 │ Output: SLA requirements, test scope                │
 │ Gate: Product Owner approval                         │
 └─────────────────────────────────────────────────────┘
      ↓ G1:APPROVED
 ┌─────────────────────────────────────────────────────┐
 │ G2: Planning (perf-architect)                       │
 │ Input: G1 output, module registry                   │
 │ Output: Test plan, load shapes, modules             │
 │ Gate: Tech Lead + Infrastructure                    │
 └─────────────────────────────────────────────────────┘
      ↓ G2:APPROVED
 ┌─────────────────────────────────────────────────────┐
 │ G3: Test Design (perf-architect)                    │
 │ Input: G2 output, API registry                      │
 │ Output: Test cases, scenarios, assertions           │
 │ Gate: QA Lead + Performance Engineer                │
 └─────────────────────────────────────────────────────┘
      ↓ G3:APPROVED
      ├─────────────────────────────────────────────────┐
      │                                                  │
      ↓                                                  ↓
 ┌───────────────────┐                    ┌─────────────────────┐
 │ G4: JMX Scripts   │ (PARALLEL)         │ G5: Test Data       │
 │ (perf-builder)    │                    │ (perf-builder)      │
 │ 6-8 hours         │                    │ 3-4 hours           │
 │ Architect review  │                    │ QA validation       │
 └───────────────────┘                    └─────────────────────┘
      ↓ G4:APPROVED                            ↓ G5:APPROVED
      └─────────────────────────────────────────┘
                      ↓
 ┌─────────────────────────────────────────────────────┐
 │ G6: Git Push & Execution (perf-executor)           │
 │ Input: G4 (JMX), G5 (CSV)                           │
 │ Steps: Organize, validate, commit, push, trigger   │
 │ Gate: DevOps PR approval (auto-triggers Argo)       │
 └─────────────────────────────────────────────────────┘
      ↓ G6:APPROVED (PR merged)
    Argo Workflow Triggered
      ↓
 ┌─────────────────────────────────────────────────────┐
 │ G7: Test Execution & Analysis (perf-analyst)       │
 │ Argo Steps:                                         │
 │  1. Provision JMeter cluster                        │
 │  2. Run smoke test (5 min @ 10 RPS)                 │
 │  3. Run load test (30 min @ 500 RPS)                │
 │  4. Run stress test (ramp to 2000 RPS)              │
 │  5. Run soak test (8 hours @ 800 RPS, if applicable)│
 │  6. Collect metrics (JMeter + Prometheus)           │
 │  7. Analyze results (statistics, SLA validation)    │
 │  8. Compare to baseline (regression detection)      │
 │  9. Generate report                                 │
 │ Gate: Performance Engineer approval                 │
 └─────────────────────────────────────────────────────┘
      ↓ G7:APPROVED
 ┌─────────────────────────────────────────────────────┐
 │ G8: Reporting & Go/No-Go (perf-reporter + HUMAN)   │
 │ Input: G7 analysis report                           │
 │ Output: Release report, risk assessment             │
 │ Recommendation: GO / NO-GO / CAUTION               │
 │ Gate: **HUMAN REQUIRED** — Release Manager          │
 │       (No AI auto-approval of release decision)     │
 └─────────────────────────────────────────────────────┘
      ↓ G8:APPROVED:GO
 ┌──────────────────────────────────────────────┐
 │ Deployment Ready (with monitoring + rollback) │
 └──────────────────────────────────────────────┘
```

---

## Entry Points (6 Options)

You can start the PTLC at any phase:

1. **ptlc-start-full** (G1→G8): Complete pipeline from scratch
   ```
   sdlc perf start <story-id>
   ```

2. **ptlc-start-jmx** (G4→G8): Start from JMX generation
   ```
   sdlc perf jmx <story-id>
   ```
   (Assumes G1-G3 complete)

3. **ptlc-start-data** (G5→G8): Start from test data generation
   ```
   sdlc perf data <story-id>
   ```
   (Assumes G1-G4 complete)

4. **ptlc-start-execute** (G6→G8): Start from Git push
   ```
   sdlc perf push <story-id>
   ```
   (Assumes G1-G5 complete)

5. **ptlc-start-analyze** (G7→G8): Start from test analysis
   ```
   sdlc perf analyze <story-id>
   ```
   (Assumes G1-G6 complete, tests have run)

6. **ptlc-start-report** (G8 only): Generate release report
   ```
   sdlc perf report <story-id>
   ```
   (Assumes G1-G7 complete, G7 analysis available)

---

## Phase Details

### G1: Requirement Analysis & SLA Extraction

**Agent**: perf-architect (Opus 4.6)  
**Duration**: 4-6 hours  
**Inputs**: User story, PRD, SLA docs, historical baseline

**Key Activities**:
1. Extract SLA requirements
   - Throughput targets (RPS)
   - Response time SLAs (p95, p99)
   - Error rate limits
   - Availability requirements

2. Analyze feature scope
   - Which APIs affected?
   - Which user journeys critical?
   - Data volume expectations

3. Assess current state
   - Historical performance data
   - Known bottlenecks
   - Infrastructure capacity

4. Define test scope
   - Smoke test (basic connectivity)
   - Load test (sustained normal traffic)
   - Stress test (beyond SLA until failure)
   - Soak test (long-duration run)

**Output Artifacts**:
- `G1-sla-requirements.md` — Extracted SLAs, test scope
- `G1-baseline-analysis.md` — Historical comparison

**Approval Gate**: Product Owner (SLA sign-off)

---

### G2: Planning & Module Selection

**Agent**: perf-architect (Opus 4.6)  
**Duration**: 3-4 hours  
**Inputs**: G1 output, module registry, load patterns

**Key Activities**:
1. Select modules from registry
2. Define load shapes (constant, ramp, wave)
3. Plan execution sequence
4. Capacity planning (threads, ramp-up, hold times)
5. Risk assessment

**Modules Used**:
Pre-built, composable modules for common APIs:
- `LOGIN` — Authentication
- `UPL` — User profile lookup
- `SEARCH` — Full-text search
- `UPLOAD` — File upload
- `DWN` — File download
- And 6+ more

See: `stacks/jmeter/knowledge-base/modules.md`

**Output Artifacts**:
- `G2-test-plan.md` — Module selection, load shapes
- `G2-capacity-plan.md` — Threads, ramp-up, data requirements

**Approval Gate**: Tech Lead + Infrastructure

---

### G3: Test Case Design

**Agent**: perf-architect (Opus 4.6)  
**Duration**: 4-6 hours  
**Inputs**: G2 output, API registry

**Key Activities**:
1. Create test case matrix
2. Define scenarios (happy path, error, edge case, spike)
3. Specify assertions
4. Define metrics to collect
5. Define acceptance criteria (pass/fail rules)

**Scenarios**:
- Happy path (70% traffic) — normal user behavior
- Error (5% traffic) — API errors, timeouts
- Edge case (5% traffic) — boundary conditions
- Spike (20% traffic in stress) — sudden load burst

**Output Artifacts**:
- `G3-test-design.md` — Test cases, scenarios, assertions
- `G3-metrics-plan.md` — Metrics to collect

**Approval Gate**: QA Lead + Performance Engineer

---

### G4: JMX Script Generation

**Agent**: perf-builder (Sonnet 4.6)  
**Duration**: 6-8 hours  
**Inputs**: G3 output, module registry, conventions

**Key Activities**:
1. Generate base JMX for each test type
2. Assemble modules in dependency order
3. Configure thread groups per capacity plan
4. Add listeners (aggregate report, result file)
5. Create property files (hosts.properties, sla.properties)
6. Create README with execution instructions

**Conventions**:
Follow JMX conventions from: `stacks/jmeter/workspace/references/jmx-conventions.md`
- Thread group naming: `{testType}_{api}_{rampup}_{threads}_{duration}`
- Variable naming: `${host-service}`, `${field}`
- Assertion patterns: Status code + response time
- File path patterns: Relative with `${TESTPLAN_DIR}`

**Output Artifacts**:
- `baseline-test.jmx` — Smoke test JMX
- `load-test.jmx` — Load test JMX
- `stress-test.jmx` — Stress test JMX
- `soak-test.jmx` — Soak test JMX
- `hosts.properties` — Host configuration
- `sla.properties` — SLA thresholds

**Approval Gate**: Architect (GUI review in JMeter required)

---

### G5: Test Data Generation

**Agent**: perf-builder (Sonnet 4.6)  
**Duration**: 3-4 hours  
**Inputs**: G2 capacity plan, API registry

**Key Activities**:
1. Generate user credentials (users.csv)
2. Generate search queries (search-queries.csv)
3. Generate file metadata if needed (upload-files.csv)
4. Validate CSV structure
5. Create data dictionary (README.md)

**CSV Conventions**:
Follow CSV conventions from: `stacks/jmeter/workspace/references/csv-conventions.md`
- Column naming: `lowercase_with_underscores`
- Row count: `thread_count × 1.2` (minimum)
- Data format: UTF-8, no real PII (@test.com only)
- File location: `data/{api}_{scenario}.csv`

**Data Example** (users.csv):
```
userId,deviceKey,emailId,password,authKey,shardKey,folderKey
user001,dk-001,user001@test.com,Test@123,base64token001,shard-1,rf-001
user002,dk-002,user002@test.com,Test@123,base64token002,shard-2,rf-002
```

**Output Artifacts**:
- `users.csv` — Test user credentials
- `search-queries.csv` — Search test terms
- `upload-files.csv` — File metadata (if applicable)
- `data/README.md` — Data dictionary

**Approval Gate**: QA Lead (CSV validation)

---

### G6: Execution & Push to Git

**Agent**: perf-executor (Haiku 4.5)  
**Duration**: 2-3 hours  
**Inputs**: G4 (JMX), G5 (CSV)

**Key Activities**:
1. Organize artifacts (JMX, CSV, properties, README)
2. Validate before push (JMX syntax, CSV references)
3. Create feature branch: `perf/story-{STORY_ID}-test-scripts`
4. Commit with gate approvals documented
5. Push to remote (creates PR)
6. Trigger Argo Workflow upon PR merge

**Directory Structure**:
```
perf-tests/story-{STORY_ID}/
├── jmx/
│   ├── baseline-test.jmx
│   ├── load-test.jmx
│   ├── stress-test.jmx
│   └── soak-test.jmx
├── data/
│   ├── users.csv
│   ├── search-queries.csv
│   └── README.md
├── properties/
│   ├── hosts.properties
│   └── sla.properties
└── README.md
```

**Approval Gate**: DevOps (PR merge auto-triggers Argo)

---

### G7: Test Execution & Analysis

**Agent**: perf-analyst (Sonnet 4.6)  
**Duration**: 4-6 hours (live test) + analysis  
**Trigger**: Argo Workflow (automatic after G6)

**Argo Workflow Steps**:
1. Provision JMeter cluster
2. Run smoke test (5 min @ 10 RPS)
3. Run load test (30 min @ 500 RPS constant)
4. Run stress test (ramp 0→2000 RPS over 30 min)
5. Run soak test (8 hours @ 800 RPS, optional)
6. Collect metrics (JMeter .jtl + Prometheus)
7. Analyze results
8. Compare vs. SLA (pass/fail per test case)
9. Compare vs. baseline (detect regressions)
10. Generate analysis report

**Analysis Includes**:
- Response time statistics (min, max, mean, p50, p95, p99, p99.9)
- Throughput (successful requests per second)
- Error rate and breakdown
- Baseline comparison (% change from previous run)
- Bottleneck identification
- Infrastructure utilization

**Output Artifacts**:
- `results/results-{timestamp}.jtl` — Raw JMeter metrics
- `G7-analysis-report.md` — Detailed analysis + pass/fail
- `G7-baseline-comparison.md` — vs. historical
- Graphs (response time timeline, error rate trend)

**Approval Gate**: Performance Engineer (analysis review)

---

### G8: Performance Reporting & Go/No-Go

**Agent**: perf-reporter (Sonnet 4.6) + **HUMAN APPROVAL REQUIRED**  
**Duration**: 2-3 hours  
**Inputs**: G7 analysis report

**Key Activities**:
1. Create executive summary (1 page)
2. Create detailed findings (2 pages)
3. Assess risk level (GREEN/YELLOW/RED)
4. Recommend GO / NO-GO / GO-WITH-CAUTION
5. Define deployment conditions (if GO)
6. Specify post-deployment monitoring
7. Document assumptions and caveats

**Risk Levels**:
- **GREEN (GO)**: All SLAs met, no bottlenecks → Ready for production
- **YELLOW (CAUTION)**: Minor issues, mitigatable → Deploy with conditions
- **RED (NO-GO)**: Major SLA failures → Requires investigation + re-testing

**Approval Gate**: **HUMAN REQUIRED** — Release Manager  
**No Auto-Approval**: AI cannot approve release decisions  
**Gate Format**: JIRA comment `G8:APPROVED:GO` (or `NO-GO` / `CAUTION`)

**Output Artifacts**:
- `G8-release-report.md` — Executive summary + recommendations
- `G8-deployment-guidelines.md` — Conditions + monitoring

---

## Rules & Guardrails

### Module Registry Rules
- Read `stacks/jmeter/knowledge-base/modules.md` before selecting modules
- Check module dependencies (must be acyclic)
- New APIs not in registry? Ask for approval before creating test

### JMX Generation Rules
- Follow `stacks/jmeter/workspace/references/jmx-conventions.md` exactly
- Every HTTP sampler must have status code assertion
- Every sampler with SLA constraint must have response time assertion
- Use relative file paths: `${TESTPLAN_DIR}/data/...`
- No hardcoded credentials or IPs

### CSV Generation Rules
- Follow `stacks/jmeter/workspace/references/csv-conventions.md`
- Column names must match JMX variable references
- No real PII (use @test.com domain only)
- Synthetic passwords: `Test@123`
- Row count ≥ thread_count × 1.2

### Git Commit Rules
- **NEVER push to main/master** — Always use `perf/` branches
- Commit message includes which gates passed
- All JMX and CSV files reviewed before push
- Include link to analysis report in PR description

### Release Decision Rules
- **G8 gate is HUMAN REQUIRED** — No AI auto-approval
- Green = ready, Yellow = conditional, Red = not ready
- Include post-launch monitoring plan
- Document assumptions and caveats

---

## Expected Timeline

**Full Pipeline (G1→G8)**: 5-10 business days
- G1: 1 day
- G2: 1 day
- G3: 1 day
- G4 + G5 (parallel): 1-2 days
- G6: 1 day (includes PR review)
- G7: 1-2 days (test runtime + analysis)
- G8: 1 day (reporting + human approval)

**Partial Pipeline Examples**:
- G4→G8 (existing SLA): 2-3 days
- G6→G8 (scripts ready): 1-2 days
- G7→G8 (tests run): <1 day

---

## Token Budget

**Total**: ~10,500 tokens for full pipeline

| Phase | Model | Tokens | Notes |
|-------|-------|--------|-------|
| G1 | Opus 4.6 | 1200 | SLA extraction |
| G2 | Opus 4.6 | 1500 | Planning |
| G3 | Opus 4.6 | 1200 | Test design |
| G4 | Sonnet 4.6 | 2000 | JMX generation |
| G5 | Sonnet 4.6 | 800 | Data generation |
| G6 | Haiku 4.5 | 600 | Git push + validation |
| G7 | Sonnet 4.6 | 2000 | Analysis + report |
| G8 | Sonnet 4.6 | 1200 | Release report |

---

## Related Documentation

- **Module Registry**: `stacks/jmeter/knowledge-base/modules.md`
- **API Registry**: `stacks/jmeter/knowledge-base/api-registry.md`
- **Phase Details**: `stacks/jmeter/knowledge-base/phases.md`
- **JMX Conventions**: `stacks/jmeter/workspace/references/jmx-conventions.md`
- **CSV Conventions**: `stacks/jmeter/workspace/references/csv-conventions.md`
- **Pipeline Orchestration**: `orchestrator/perf/perf-pipeline.md`

---

## Example Workflow

**User Story**: "As a user, I can search documents by keyword with <200ms p95 response time at 500 RPS"

```bash
# Start full pipeline
sdlc perf start PERF-1234

# At each gate, review artifacts and approve:
# G1: Review SLA requirements, approve if complete
# G2: Review test plan, approve if modules/capacity valid
# G3: Review test cases, approve if assertions align with SLA
# G4: Review JMX in GUI, approve if structure correct
# G5: Review CSV validation, approve if format valid
# G6: Review PR, merge (auto-triggers Argo)
# G7: (automated) Review analysis, approve if SLA met
# G8: Review release report, human release manager approves GO/NO-GO

# Result: Feature deployed with performance validated
```

---

## Support & Escalation

- **Questions about modules?** See `modules.md` and `api-registry.md`
- **Questions about JMX/CSV format?** See conventions guides
- **Test execution failed?** Check Argo logs, infrastructure health
- **Release decision unclear?** Escalate to performance engineering team

---

**Last Updated**: 2026-04-11  
**Owner**: Performance Team  
**Status**: Production Ready  
**Version**: 2.0.0
