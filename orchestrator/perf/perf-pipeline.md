# Performance Testing Lifecycle (PTLC) — Full Pipeline Orchestration

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Status**: Production Ready  
**Audience**: Performance team leads, Argo workflow operators, SDLC orchestrators

---

## Pipeline Overview

The PTLC Pipeline is an end-to-end workflow that takes performance requirements from a user story through execution, analysis, and release approval. It spans 8 phases (G1-G8) and involves multiple agents, approval gates, and infrastructure components.

**Total Pipeline Duration**: 5-10 business days  
**Agents**: 6 dedicated roles (perf-architect, perf-builder, perf-executor, perf-analyst, perf-reporter, human)  
**Infrastructure**: ADO, Git, Argo Workflows, JMeter, S3, Prometheus  
**Entry Points**: 6 (full pipeline, mid-stream starts)

---

## Pipeline Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  PERFORMANCE TESTING LIFECYCLE (PTLC) — 8-Phase Orchestration       │
└─────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────┐
  │  G1: Requirement Analysis & SLA Extraction                       │
  │  Agent: perf-architect (Opus 4.6)                                 │
  │  Duration: 4-6 hours                                              │
  │  Input: User Story, PRD, SLA docs                                │
  │  Output: SLA requirements, test scope, baseline comparison       │
  │  Gate: Product Owner approval (SLA signed off)                   │
  └──────────────────────────────────────────────────────────────────┘
                              ↓ G1:APPROVED
  ┌──────────────────────────────────────────────────────────────────┐
  │  G2: Planning & Module Selection                                 │
  │  Agent: perf-architect (Opus 4.6)                                 │
  │  Duration: 3-4 hours                                              │
  │  Input: G1 output, module registry                               │
  │  Output: Test plan, load shapes, module dependency tree          │
  │  Gate: Tech Lead + Infrastructure approval                       │
  └──────────────────────────────────────────────────────────────────┘
                              ↓ G2:APPROVED
  ┌──────────────────────────────────────────────────────────────────┐
  │  G3: Test Case Design                                            │
  │  Agent: perf-architect (Opus 4.6)                                 │
  │  Duration: 4-6 hours                                              │
  │  Input: G2 output, API registry                                  │
  │  Output: Test case matrix, scenarios, assertions, metrics plan   │
  │  Gate: QA Lead + Performance Engineer approval                   │
  └──────────────────────────────────────────────────────────────────┘
                              ↓ G3:APPROVED
         ┌────────────────────┴────────────────────┐
         │ (Parallel Execution)                    │
         ↓                                         ↓
  ┌─────────────────────┐            ┌─────────────────────┐
  │  G4: JMX Script     │            │  G5: Test Data      │
  │  Generation         │            │  Generation         │
  │                     │            │                     │
  │  Agent:             │            │  Agent:             │
  │  perf-builder       │            │  perf-builder       │
  │  (Sonnet 4.6)       │            │  (Sonnet 4.6)       │
  │                     │            │                     │
  │  Duration: 6-8 hrs  │            │  Duration: 3-4 hrs  │
  │                     │            │                     │
  │  Input:             │            │  Input:             │
  │  G3 output, module  │            │  G2 capacity plan   │
  │  registry           │            │  API registry       │
  │                     │            │                     │
  │  Output:            │            │  Output:            │
  │  JMX files, props   │            │  CSV files, data    │
  │  files              │            │  dictionary         │
  │                     │            │                     │
  │  Gate:              │            │  Gate:              │
  │  GUI Review +       │            │  Data validation +  │
  │  Architect signed   │            │  QA signed off      │
  │                     │            │                     │
  └─────────────────────┘            └─────────────────────┘
         ↓ G4:APPROVED                      ↓ G5:APPROVED
         └────────────────────┬────────────────────┘
                              ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │  G6: Execution & Push to Git                                     │
  │  Agent: perf-executor (Haiku 4.5)                                 │
  │  Duration: 2-3 hours                                              │
  │  Input: G4 output (JMX), G5 output (CSV)                         │
  │  Steps:                                                           │
  │    1. Organize artifacts (JMX, data, properties, README)         │
  │    2. Pre-push validation (XML syntax, file references)          │
  │    3. Create feature branch: perf/story-{ID}-test-scripts        │
  │    4. Git commit with gate approvals documented                  │
  │    5. Push to remote (creates PR)                                │
  │    6. Trigger Argo Workflow for G7 execution                    │
  │  Gate: Architect + DevOps PR approval                            │
  └──────────────────────────────────────────────────────────────────┘
                              ↓ G6:APPROVED (PR merged)
                    Argo Workflow Triggered
                              ↓
  ┌──────────────────────────────────────────────────────────────────┐
  │  G7: Test Execution & Analysis (Argo Workflow)                  │
  │  Agent: perf-analyst (Sonnet 4.6)                                 │
  │  Duration: 4-6 hours (test runtime) + analysis time              │
  │  Argo Steps:                                                      │
  │    1. Provision test environment (JMeter agents)                 │
  │    2. Run smoke test (5 min, 10 RPS)                             │
  │    3. Run load test (30 min, 500 RPS)                            │
  │    4. Run stress test (30 min ramp, until failure)               │
  │    5. Run soak test (8 hours, 800 RPS)                           │
  │    6. Collect metrics (JMeter + Prometheus)                      │
  │    7. Parse results (response times, throughput, errors)         │
  │    8. Compare vs. SLA (pass/fail per test case)                  │
  │    9. Compare vs. baseline (detect regressions)                  │
  │    10. Generate analysis report                                  │
  │  Output: Analysis report, metrics, graphs                        │
  │  Gate: Performance Engineer approval of analysis                 │
  └──────────────────────────────────────────────────────────────────┘
                              ↓ G7:APPROVED
  ┌──────────────────────────────────────────────────────────────────┐
  │  G8: Performance Reporting & Go/No-Go Decision                  │
  │  Agent: perf-reporter (Sonnet 4.6) + HUMAN APPROVAL REQUIRED    │
  │  Duration: 2-3 hours                                              │
  │  Steps:                                                           │
  │    1. Create executive summary (1 page)                          │
  │    2. Create detailed findings (2 pages)                         │
  │    3. Define risk level (GREEN/YELLOW/RED)                       │
  │    4. Make recommendation: GO / NO-GO / GO-WITH-CAUTION          │
  │    5. Deployment recommendations + monitoring alerts            │
  │    6. Document assumptions and caveats                           │
  │  Output: Release report, risk assessment                         │
  │  Gate: HUMAN REQUIRED — Release Manager must approve GO         │
  │        No AI auto-approval of release decision                   │
  └──────────────────────────────────────────────────────────────────┘
                              ↓ G8:APPROVED
  ┌──────────────────────────────────────────────────────────────────┐
  │  Release Decision Outcomes                                        │
  │  ✓ GO — Ready for production (conditional on monitoring)        │
  │  ⚠️ GO-WITH-CAUTION — Conditional deployment (mitigations req)  │
  │  ✗ NO-GO — Not ready (investigation + re-testing required)      │
  └──────────────────────────────────────────────────────────────────┘
```

---

## Entry Points (6 Available)

### Entry Point 1: ptlc-start-full
**Trigger**: `sdlc perf start <story-id>`  
**Start Phase**: G1 (Requirement)  
**Use Case**: Complete new performance test from scratch  
**Duration**: 5-10 days

**Workflow**:
```
G1 → G2 → G3 → (G4 || G5) → G6 → G7 → G8
```

### Entry Point 2: ptlc-start-jmx
**Trigger**: `sdlc perf jmx <story-id>`  
**Start Phase**: G4 (Script)  
**Use Case**: SLA and modules already defined; jump to script generation  
**Duration**: 1-2 days

**Workflow**:
```
(Assume G1, G2, G3 complete) → G4 → G6 → G7 → G8
```

**Prerequisites**:
- [ ] G1 output available (SLA requirements)
- [ ] G2 output available (test plan)
- [ ] G3 output available (test case design)

### Entry Point 3: ptlc-start-data
**Trigger**: `sdlc perf data <story-id>`  
**Start Phase**: G5 (Data)  
**Use Case**: JMX already exists; need to generate test data  
**Duration**: 1 day

**Workflow**:
```
(Assume G4 complete) → G5 → G6 → G7 → G8
```

**Prerequisites**:
- [ ] G4 output available (JMX files, data field specs)

### Entry Point 4: ptlc-start-execute
**Trigger**: `sdlc perf push <story-id>`  
**Start Phase**: G6 (Execution)  
**Use Case**: JMX and data ready; push to Git and execute  
**Duration**: 4-6 hours

**Workflow**:
```
(Assume G4, G5 complete) → G6 → G7 → G8
```

**Prerequisites**:
- [ ] G4 output committed (JMeter scripts, properties)
- [ ] G5 output committed (CSV data)

### Entry Point 5: ptlc-start-analysis
**Trigger**: `sdlc perf analyze <story-id>`  
**Start Phase**: G7 (Analysis)  
**Use Case**: Tests already run; need to analyze results  
**Duration**: 4-6 hours

**Workflow**:
```
(Assume G6 complete) → G7 → G8
```

**Prerequisites**:
- [ ] Test results available (results.jtl files)
- [ ] Baseline for comparison (if available)

### Entry Point 6: ptlc-start-report
**Trigger**: `sdlc perf report <story-id>`  
**Start Phase**: G8 (Reporting)  
**Use Case**: Analysis complete; generate release report  
**Duration**: 2-3 hours

**Workflow**:
```
(Assume G7 complete) → G8
```

**Prerequisites**:
- [ ] G7 analysis report generated

---

## Phase-by-Phase Workflow Details

### Phase G1: Requirement Analysis

**Inputs**:
- User Story (from ADO)
- Product Requirement Document
- Historical baseline (if exists)
- SLA document from product

**Orchestration Steps**:
1. Agent reads user story from ADO
2. Agent extracts SLA requirements (throughput, response time, availability)
3. Agent analyzes feature scope (which APIs, user journeys)
4. Agent defines test scope (smoke, load, stress, soak)
5. Agent creates SLA requirements document
6. System requests G1 approval gate

**Approval Gate G1**:
- **Approver**: Product Owner
- **Checklist**:
  - [ ] All SLAs quantifiable
  - [ ] Scope bounded (max 6 APIs)
  - [ ] Historical baseline noted
  - [ ] Infrastructure capacity confirmed
- **Gate Comment Format**: `G1:APPROVED` + signature

**Output Artifacts**:
- `G1-sla-requirements.md` — SLA extraction, scope definition
- `G1-baseline-analysis.md` — Comparison with historical baseline (if available)

**Token Cost**: ~1200 tokens (Opus 4.6)

---

### Phase G2: Planning & Module Selection

**Inputs**:
- G1 approval + output
- Module registry (`stacks/jmeter/knowledge-base/modules.md`)
- Load profile patterns

**Orchestration Steps**:
1. Agent reads G1 output (SLA requirements)
2. Agent queries module registry for matching APIs
3. Agent selects modules and validates dependency tree
4. Agent defines load shapes (constant, ramp, wave)
5. Agent plans execution sequence (Smoke → Load → Stress → Soak)
6. Agent performs capacity planning (threads, ramp-up, hold times)
7. Agent assesses risks (infrastructure impact, data requirements)
8. System requests G2 approval gate

**Approval Gate G2**:
- **Approvers**: Tech Lead, Infrastructure Lead
- **Checklist**:
  - [ ] Module dependency tree is acyclic
  - [ ] Load shapes justified by SLA
  - [ ] Capacity matches infrastructure
  - [ ] Test won't impact production
  - [ ] Cleanup/rollback procedures documented
- **Gate Comment Format**: `G2:APPROVED` + signature

**Output Artifacts**:
- `G2-test-plan.md` — Module selection, load shapes, execution plan
- `G2-capacity-plan.md` — Thread groups, ramp-up times, data requirements
- `G2-risk-assessment.md` — Potential issues and mitigations

**Token Cost**: ~1500 tokens (Opus 4.6)

---

### Phase G3: Test Case Design

**Inputs**:
- G2 approval + output
- API registry (`stacks/jmeter/knowledge-base/api-registry.md`)
- SLA thresholds from G1

**Orchestration Steps**:
1. Agent reads G2 output (modules, load shapes)
2. Agent creates detailed test case matrix
3. Agent defines scenarios (happy path, error, edge case, spike)
4. Agent specifies assertions (status code, response time, content)
5. Agent defines metrics to collect
6. Agent defines acceptance criteria (pass/fail rules)
7. System requests G3 approval gate

**Approval Gate G3**:
- **Approvers**: QA Lead, Performance Engineer
- **Checklist**:
  - [ ] Every test case has success/failure criteria
  - [ ] Assertions aligned with G1 SLAs
  - [ ] Metrics collection plan is specific
  - [ ] Test cases are independent
  - [ ] Failure criteria are actionable
- **Gate Comment Format**: `G3:APPROVED` + signature

**Output Artifacts**:
- `G3-test-design.md` — Test case matrix, scenarios, assertions
- `G3-metrics-plan.md` — What to collect and how

**Token Cost**: ~1200 tokens (Opus 4.6)

---

### Phase G4: JMX Script Generation (Parallel with G5)

**Inputs**:
- G3 approval + output
- Module registry + reference JMX files
- JMX conventions guide

**Orchestration Steps**:
1. Agent reads G3 output (test cases, assertions)
2. Agent reads module registry for parameter specs
3. Agent generates JMX for each test type (baseline, load, stress, soak)
4. Agent assembles modules in correct dependency order
5. Agent configures thread groups per G2 capacity plan
6. Agent adds listeners (aggregate report, result file)
7. Agent creates property files (hosts.properties, sla.properties)
8. Agent creates README with execution instructions
9. System requests G4 GUI review gate

**Approval Gate G4**:
- **Approvers**: QA Lead, Performance Architect (GUI review required)
- **Process**:
  1. JMX files opened in JMeter GUI
  2. Thread groups verified
  3. Samplers and extractors verified
  4. Assertions verified
  5. File references verified
  6. Screenshot of GUI confirmation
- **Gate Comment Format**: `G4:APPROVED` + GUI review screenshot

**Output Artifacts**:
- `baseline-test.jmx` — Smoke test JMX
- `load-test.jmx` — Load test JMX
- `stress-test.jmx` — Stress test JMX
- `soak-test.jmx` — Soak test JMX
- `hosts.properties` — Host configuration
- `sla.properties` — SLA thresholds
- `README.md` — How to run tests locally

**Token Cost**: ~2000 tokens (Sonnet 4.6)

---

### Phase G5: Test Data Generation (Parallel with G4)

**Inputs**:
- G2 capacity plan (thread count, data requirements)
- API registry (field specifications)
- CSV conventions guide

**Orchestration Steps**:
1. Agent reads G2 output (capacity plan)
2. Agent reads API registry for field specs
3. Agent generates users.csv (thread_count × 1.2 rows)
4. Agent generates search-queries.csv (500+ unique queries)
5. Agent generates upload-files.csv (if needed)
6. Agent validates CSV structure (headers, uniqueness, format)
7. Agent creates data dictionary (README.md)
8. System requests G5 validation gate

**Approval Gate G5**:
- **Approvers**: QA Lead, Data Steward
- **Validation**:
  - [ ] CSV headers match JMX variable names
  - [ ] No duplicate user IDs
  - [ ] Row count ≥ capacity plan requirement
  - [ ] No real PII (@test.com only)
  - [ ] File format valid (UTF-8, proper escaping)
- **Gate Comment Format**: `G5:APPROVED` + validation report

**Output Artifacts**:
- `data/users.csv` — Test user credentials
- `data/search-queries.csv` — Search test terms
- `data/upload-files.csv` — File metadata (if applicable)
- `data/README.md` — Data dictionary

**Token Cost**: ~800 tokens (Sonnet 4.6)

---

### Phase G6: Execution & Push to Git

**Inputs**:
- G4 output (JMX files, properties)
- G5 output (CSV files)

**Orchestration Steps**:
1. Agent organizes all artifacts into directory:
   ```
   perf-tests/story-{STORY_ID}/
   ├── jmx/ (4 JMX files)
   ├── data/ (3+ CSV files)
   ├── properties/ (2 properties files)
   └── README.md
   ```
2. Agent validates before push:
   - JMX XML syntax valid
   - CSV file references correct
   - Properties files valid
   - No credentials in files
3. Agent creates Git feature branch: `perf/story-{STORY_ID}-test-scripts`
4. Agent commits with gate approvals documented
5. Agent pushes to remote (triggers PR)
6. System requests G6 PR approval
7. Upon approval, agent triggers Argo Workflow

**Approval Gate G6**:
- **Approvers**: Architect, DevOps
- **Process**: Standard GitHub PR review
- **Gate Comment Format**: `G6:APPROVED` (auto-merges PR and triggers Argo)

**Argo Trigger**:
```bash
argo submit perf-pipeline.yaml \
  --param story={STORY_ID} \
  --param git-commit={GIT_COMMIT_HASH}
```

**Output Artifacts**:
- Git commit in `perf/story-{ID}-test-scripts` branch
- Git tag: `perf-story-{ID}-ready-for-execution`

**Token Cost**: ~600 tokens (Haiku 4.5)

---

### Phase G7: Test Execution & Analysis (Argo Workflow)

**Inputs**:
- JMX files (from G6)
- CSV files (from G6)
- Baseline metrics (if available)

**Argo Workflow Steps**:
```yaml
1. provision-jmeter-agents     (spin up JMeter controller + agents)
2. run-smoke-test              (5 min @ 10 RPS)
3. run-load-test               (30 min @ 500 RPS)
4. run-stress-test             (30 min ramp → 2000 RPS)
5. run-soak-test               (8 hours @ 800 RPS, if needed)
6. collect-metrics             (aggregate JMeter + Prometheus)
7. analyze-results             (parse JTL, calculate percentiles)
8. compare-sla                 (validate each test vs SLA)
9. compare-baseline            (detect regressions)
10. generate-analysis-report   (create markdown report)
11. cleanup-jmeter             (teardown agents)
```

**Agent Role: perf-analyst (Sonnet 4.6)**

**Analysis Steps**:
1. Monitor live execution (tail JMeter output, watch metrics)
2. Collect raw metrics (results.jtl, Prometheus scrapes)
3. Parse results (response times, error rates, throughput)
4. Calculate statistics (min, max, mean, p50, p95, p99)
5. Compare vs. SLA (pass/fail per test case)
6. Compare vs. baseline (detect regressions)
7. Identify bottlenecks (slow APIs, high CPU)
8. Generate analysis report

**Output Artifacts**:
- `results/results-{timestamp}.jtl` — Raw JMeter metrics
- `G7-analysis-report.md` — Detailed analysis + pass/fail summary
- `G7-baseline-comparison.md` — vs. historical baseline
- Graphs (response time timeline, error rate trend)

**Approval Gate G7**:
- **Approvers**: Performance Engineer, Tech Lead
- **Checklist**:
  - [ ] All test results collected
  - [ ] SLA comparison is clear (PASS/FAIL per SLA)
  - [ ] Bottleneck analysis includes root cause
  - [ ] Baseline comparison documented
  - [ ] Confidence levels assessed
- **Gate Comment Format**: `G7:APPROVED` + analysis confirmation

**Token Cost**: ~2000 tokens (Sonnet 4.6)

---

### Phase G8: Performance Reporting & Go/No-Go Decision

**Inputs**:
- G7 approval + analysis report
- Risk assessment framework

**Orchestration Steps**:
1. Agent reads G7 analysis report
2. Agent creates executive summary (1 page, 200 words)
3. Agent creates detailed findings (2 pages)
4. Agent assesses risk level:
   - GREEN: All SLAs met, no bottlenecks → GO
   - YELLOW: Minor issues, mitigatable → GO-WITH-CAUTION
   - RED: Major SLA failures → NO-GO
5. Agent makes recommendation (GO / NO-GO / CAUTION)
6. Agent defines deployment conditions (if GO)
7. Agent specifies post-deployment monitoring
8. System creates release report document
9. System requests final approval from Release Manager

**Approval Gate G8** (HUMAN REQUIRED):
- **Approver**: Release Manager (mandatory human)
- **Process**:
  - Release Manager reviews report
  - Release Manager confirms GO/NO-GO decision
  - Release Manager signs off in ADO/JIRA
- **Gate Comment Format**: `G8:APPROVED:GO` (or `NO-GO` / `CAUTION`)
- **No Auto-Approval**: AI cannot approve release decisions

**Release Decision Matrix**:

| All SLAs Met | Bottlenecks | Baseline Regression | Decision |
|-------------|-------------|-------------------|----------|
| YES        | None       | <5%                | GO       |
| YES        | Outside load range | <10%        | GO       |
| PARTIAL    | Mitigatable| <10%                | CAUTION  |
| PARTIAL    | Within load range | Any           | NO-GO    |
| NO         | Any        | Any                 | NO-GO    |

**Output Artifacts**:
- `G8-release-report.md` — Executive summary, SLA comparison, risk assessment
- `G8-deployment-recommendations.md` — Conditions, monitoring, rollback plan
- `G8-go-decision.md` — Final decision, sign-off, approvers

**Token Cost**: ~1200 tokens (Sonnet 4.6)

---

## Agent Handoff Packets

Each phase creates a "handoff packet" for the next agent.

### G1 → G2 Handoff Packet
```
{
  "story_id": "PERF-1234",
  "phase_complete": "G1",
  "phase_output": "G1-sla-requirements.md",
  "sla_throughput_target": "1000 RPS",
  "sla_response_time_p95": "200ms",
  "sla_response_time_p99": "500ms",
  "sla_error_rate_max": "0.1%",
  "apis_in_scope": ["LOGIN", "UPL", "SEARCH", "UPLOAD"],
  "user_journey_count": 4,
  "baseline_exists": true,
  "infrastructure_capacity_available": true,
  "approved_by": "product-owner",
  "approval_timestamp": "2026-04-11T10:00:00Z"
}
```

### G2 → G3 Handoff Packet
```
{
  "story_id": "PERF-1234",
  "phase_complete": "G2",
  "phase_output": "G2-test-plan.md",
  "modules_selected": ["LOGIN", "UPL", "SEARCH", "UPLOAD", "DELETE"],
  "load_shapes": {
    "smoke": "constant 10 RPS for 5 min",
    "load": "ramp 0->500 RPS over 10 min, hold 30 min",
    "stress": "ramp 0->2000 RPS over 30 min"
  },
  "capacity_plan": {
    "smoke_threads": 10,
    "load_threads": 500,
    "stress_threads": 2000
  },
  "test_data_required": 2500,
  "approved_by": "tech-lead, infrastructure-lead"
}
```

### G3 → (G4, G5) Handoff Packet
```
{
  "story_id": "PERF-1234",
  "phase_complete": "G3",
  "phase_output": "G3-test-design.md",
  "test_cases": [
    {
      "id": "TC-SMOKE-01",
      "name": "Smoke test - basic connectivity",
      "type": "smoke",
      "thread_count": 10,
      "duration_sec": 300
    },
    ...
  ],
  "assertions": {
    "response_code": 200,
    "response_time_p95": "< 200ms",
    "response_time_p99": "< 500ms",
    "error_rate": "< 0.1%"
  },
  "approved_by": "qa-lead, perf-engineer"
}
```

### (G4, G5) → G6 Handoff Packet
```
{
  "story_id": "PERF-1234",
  "phase_complete": "G4, G5",
  "jmx_files": ["baseline-test.jmx", "load-test.jmx", "stress-test.jmx"],
  "csv_files": ["users.csv", "search-queries.csv"],
  "properties_files": ["hosts.properties", "sla.properties"],
  "test_data_rows": 2500,
  "g4_approved_by": "qa-lead",
  "g5_approved_by": "qa-lead",
  "ready_for_execution": true
}
```

### G6 → G7 Handoff Packet
```
{
  "story_id": "PERF-1234",
  "phase_complete": "G6",
  "git_commit": "a1b2c3d...",
  "git_branch": "perf/story-12345-test-scripts",
  "argo_workflow_id": "perf-12345-20260411-143000",
  "execution_start_time": "2026-04-11T14:30:00Z",
  "tests_to_run": ["smoke", "load", "stress", "soak"],
  "g6_approved_by": "architect, devops"
}
```

### G7 → G8 Handoff Packet
```
{
  "story_id": "PERF-1234",
  "phase_complete": "G7",
  "test_results": {
    "smoke_test": "PASS",
    "load_test": "PASS",
    "stress_test": "FAIL (bottleneck identified)",
    "soak_test": "PASS"
  },
  "sla_compliance": {
    "p95_response_time": "PASS (195ms < 200ms)",
    "p99_response_time": "PASS (380ms < 500ms)",
    "error_rate": "PASS (0.05% < 0.1%)"
  },
  "risk_level": "GREEN",
  "recommendation": "GO (with monitoring)",
  "analysis_report": "G7-analysis-report.md",
  "g7_approved_by": "perf-engineer, tech-lead"
}
```

---

## Infrastructure Reference

### Components

| Component | Purpose | Owner | Access |
|-----------|---------|-------|--------|
| ADO Org | Work items, stories, approvals | DevOps | https://dev.azure.com/org |
| Git Repo | Version control for JMX, CSV, properties | DevOps | git clone <repo> |
| Argo Workflows | Orchestration engine | DevOps | argo submit, argo watch |
| JMeter Cluster | Test execution (controller + agents) | DevOps | Private K8s cluster |
| Prometheus | Metrics collection (CPU, memory, requests) | DevOps | http://prometheus:9090 |
| S3 Bucket | Results storage (JTL files, reports) | DevOps | s3://perf-results/ |
| Bastion Host | SSH access to test infrastructure | DevOps | ssh bastion.company.com |

### URLs

```
Azure DevOps: https://dev.azure.com/your-ado-org/YourAzureProject
Git Repo: https://dev.azure.com/your-ado-org/YourAzureProject/_git/sdlc-platform
Argo UI: http://argo-ui.internal:3000/
JMeter Results: s3://perf-results/story-{ID}/
```

---

## Token Budget Per Phase

**Total Budget**: 10,000 tokens per full pipeline execution

| Phase | Agent | Model | Tokens | Notes |
|-------|-------|-------|--------|-------|
| G1 | perf-architect | Opus 4.6 | 1200 | SLA extraction, scope |
| G2 | perf-architect | Opus 4.6 | 1500 | Planning, capacity |
| G3 | perf-architect | Opus 4.6 | 1200 | Test design |
| G4 | perf-builder | Sonnet 4.6 | 2000 | JMX generation |
| G5 | perf-builder | Sonnet 4.6 | 800 | Data generation |
| G6 | perf-executor | Haiku 4.5 | 600 | Git push, validation |
| G7 | perf-analyst | Sonnet 4.6 | 2000 | Analysis + report |
| G8 | perf-reporter | Sonnet 4.6 | 1200 | Release report + decision |
| **TOTAL** | — | — | **10,500** | — |

---

## Error Handling & Recovery

### If G1 Fails
**Cause**: Incomplete SLA definition  
**Recovery**:
1. Request clarification from product owner
2. Re-run G1 with updated requirements
3. Continue to G2

### If G2 Fails
**Cause**: Module compatibility issues or capacity exceeded  
**Recovery**:
1. Adjust module selection or load shapes
2. Request infrastructure scaling if needed
3. Re-run G2

### If G4 or G5 Fails
**Cause**: JMX syntax error or CSV validation failure  
**Recovery**:
1. Fix identified issue
2. Re-run generation
3. Re-submit to approval gate

### If G6 Fails
**Cause**: Git conflicts or missing files  
**Recovery**:
1. Resolve conflicts
2. Validate files again
3. Retry push

### If G7 Execution Fails
**Cause**: Infrastructure issue (out of capacity, network failure)  
**Recovery**:
1. Check infrastructure health
2. Wait for available capacity
3. Re-trigger test execution (from G6)

### If G7 Analysis Fails
**Cause**: Incomplete metrics or corrupted results  
**Recovery**:
1. Re-run specific failed test
2. Re-analyze results
3. Request re-approval

### If G8 Fails
**Cause**: Risk assessment inconclusive  
**Recovery**:
1. Request additional investigation (schedule architecture review)
2. Re-run tests with different parameters
3. Request release manager escalation

---

## Monitoring & Notifications

### Real-Time Monitoring
- Argo Workflow dashboard shows live progress
- Slack notifications at each gate approval
- Email summary at pipeline completion

### Escalation Triggers
- Test execution runs >2x expected duration → Slack alert
- Test failure (status code 5xx) → Escalate to DevOps
- SLA breach → Slack alert to performance team
- Stress test failure → File incident ticket

---

## Approval Workflow Summary

| Gate | Approver(s) | Format | Auto-Merge? |
|------|----------|--------|------------|
| G1 | Product Owner | ADO comment `G1:APPROVED` | No |
| G2 | Tech Lead + Infra | ADO comment `G2:APPROVED` | No |
| G3 | QA Lead + Perf Eng | ADO comment `G3:APPROVED` | No |
| G4 | Architect (GUI review) | ADO comment `G4:APPROVED` | No |
| G5 | QA Lead | ADO comment `G5:APPROVED` | No |
| G6 | DevOps (PR approval) | GitHub PR merge | **YES** |
| G7 | Perf Engineer | ADO comment `G7:APPROVED` | No |
| G8 | Release Manager | ADO comment `G8:APPROVED:GO` | **HUMAN REQUIRED** |

---

## Rollback Procedures

### Before Deployment
If G8 result is NO-GO:
1. Archive test results (for investigation)
2. Close PR without merging
3. File issue ticket for improvements
4. Schedule re-testing

### After Deployment
If production performance degrades:
1. Compare production metrics vs. test results
2. If <10% variance → expected behavior, monitor
3. If >10% variance → potential issue, investigate
4. Rollback feature if metrics exceed thresholds

---

**Last Updated**: 2026-04-11  
**Owner**: Performance Architecture Team  
**Next Review**: 2026-05-11
