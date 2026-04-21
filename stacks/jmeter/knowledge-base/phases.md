# Performance Testing Lifecycle (PTLC) — 8-Phase Definition

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Status**: Production Ready  
**Audience**: Performance team, SDLC orchestrators, release managers

---

## PTLC Overview

The Performance Testing Lifecycle (PTLC) is an 8-phase workflow that takes a performance requirement from a user story through to a Go/No-Go release decision. Each phase has defined inputs, outputs, agent roles, guardrails, and approval gates.

**Total Pipeline Duration**: 5-10 business days (end-to-end)  
**Parallel Phase Capability**: G4, G5 (Script and Data) can run in parallel  
**Approval Gates**: 6 mandatory gates (G1, G2, G3, G4, G7, G8)

---

## Phase Definitions (G1–G8)

### G1: Requirement Analysis & SLA Extraction

**Agent Role**: `perf-architect` (Claude Opus 4.6)  
**Duration**: 4-6 hours  
**Trigger**: User story linked to performance epic  
**Input Documents**:
- Product requirement document (PRD)
- User story with acceptance criteria
- Current performance baseline (if exists)
- SLA/non-functional requirements document
- Business impact analysis

**Key Activities**:

1. **Extract SLA Requirements**
   - Parse throughput targets (requests per second)
   - Identify response time SLAs (p50, p95, p99)
   - Extract availability/uptime requirements
   - Identify peak load scenarios and duration
   - Determine geographic/multi-region needs

2. **Analyze Feature Set**
   - Which APIs/endpoints are affected?
   - Which user journeys are critical?
   - What data volumes are expected?
   - Are there integration dependencies?

3. **Assess Current State**
   - Review historical performance data
   - Identify bottleneck services
   - Check infrastructure capacity
   - Review past performance incidents

4. **Identify Test Scope**
   - Smoke test: basic connectivity (5 min load)
   - Load test: sustained normal traffic (30-60 min)
   - Stress test: push beyond SLA until failure (30 min ramp)
   - Soak test: long-duration run (4-8 hours)
   - Spike test: sudden traffic burst (optional)

**Output Artifacts**:
```
G1-sla-requirements.md
├── Extracted SLAs
│   ├── Throughput: 1000 RPS (target), 1500 RPS (peak)
│   ├── Response Time p95: <200ms, p99: <500ms
│   ├── Availability: 99.95% uptime during test window
│   └── Error Rate: <0.1%
├── Feature Analysis
│   ├── APIs affected: [LOGIN, UPL, SEARCH, UPLOAD]
│   ├── User journeys: [auth_flow, document_search, file_upload]
│   └── Data volumes: 100K concurrent users
├── Test Scope Matrix
│   ├── Smoke: 1 hour, 10 RPS
│   ├── Load: 2 hours, 500 RPS
│   ├── Stress: 1 hour, 1500+ RPS (ramp)
│   └── Soak: 8 hours, 800 RPS
└── Approval: [SLA signed off by product owner]
```

**Guardrails**:
- [ ] All SLAs are quantifiable and measurable
- [ ] Scope is bounded (max 6 APIs per G1)
- [ ] Historical baseline exists or is noted as missing
- [ ] Infrastructure team confirmed capacity availability
- [ ] No scope creep: requirements are frozen

**Approval Gate**: Product owner + Tech Lead sign-off  
**Approval Format**: Comment in JIRA/ADO with "G1:APPROVED" tag  
**Blocked By**: Incomplete SLA definition, scope ambiguity

**Next Gate**: G2 (Planning)

---

### G2: Planning & Module Selection

**Agent Role**: `perf-architect` (Claude Opus 4.6)  
**Duration**: 3-4 hours  
**Dependency**: G1 approval

**Key Activities**:

1. **Select Modules**
   - Review module registry (stacks/jmeter/knowledge-base/modules.md)
   - Select modules matching identified APIs
   - Validate module compatibility and dependency order
   - Document module parameters and extractors

2. **Define Load Shapes**
   - Constant load: flat RPS line (for baseline/soak)
   - Ramp-up: gradual increase over time (for stress test)
   - Wave: multiple peaks (for burst scenario)
   - Random: variable load (for chaos testing)

3. **Plan Execution Schedule**
   - Which tests run first? (Smoke → Load → Stress)
   - Parallel execution possible? (G4 + G5)
   - Environment setup required before each test?
   - Rollback/cleanup procedures between tests?

4. **Capacity Planning**
   - How many thread groups (virtual users)?
   - How long ramp-up? (typically 1-5 minutes per 100 threads)
   - How long steady-state hold? (typically 30-60 minutes)
   - How many data records required? (1 per virtual user minimum)

5. **Risk Assessment**
   - Will test impact production? (no — test on staging)
   - Are there known bottlenecks to isolate?
   - What success metrics matter most?
   - What would constitute test failure?

**Output Artifacts**:
```
G2-test-plan.md
├── Module Selection
│   ├── Modules: LOGIN → UPL → SEARCH → UPLOAD → DELETE
│   ├── Dependency Tree: (validated acyclic)
│   ├── Parameters: {host-core, host-security, userId, etc.}
│   └── Extractors: {accessToken, userId, folderId, etc.}
├── Load Shapes
│   ├── Smoke Test: Constant 10 RPS for 5 minutes
│   ├── Load Test: Ramp 0→500 RPS over 10 min, hold 30 min
│   ├── Stress Test: Ramp 0→2000 RPS over 30 min, hold until fail
│   └── Soak Test: Constant 800 RPS for 8 hours
├── Execution Schedule
│   ├── Order: Smoke (0min) → Load (1hr) → Stress (2.5hr) → Soak (TBD)
│   ├── Environment: staging-perf cluster
│   ├── Cleanup: Between tests (database reset)
│   └── Rollback: Kill test if CPU >90% on any service
├── Capacity Plan
│   ├── Threads: {Smoke:50, Load:500, Stress:2000, Soak:1000}
│   ├── Ramp-up: {Smoke:2min, Load:10min, Stress:30min, Soak:10min}
│   ├── Hold: {Smoke:5min, Load:30min, Stress:until failure, Soak:480min}
│   └── Data records: 2500 (covers peak + 20% buffer)
└── Approval: [Tech lead, infrastructure team sign-off]
```

**Guardrails**:
- [ ] Module dependency tree is acyclic
- [ ] Load shapes are realistic and justified
- [ ] Capacity matches available infrastructure
- [ ] Test will NOT impact production
- [ ] Baseline environment confirmed stable
- [ ] Cleanup/rollback procedures documented

**Approval Gate**: Tech Lead + Infrastructure confirmation  
**Approval Format**: JIRA comment with "G2:APPROVED" + test plan link

**Next Gate**: G3 (Design)

---

### G3: Test Case Design

**Agent Role**: `perf-architect` (Claude Opus 4.6)  
**Duration**: 4-6 hours  
**Dependency**: G2 approval

**Key Activities**:

1. **Define Test Cases**
   - Create detailed test case table with ID, name, scenario, RPS, duration
   - For each test: define pre-conditions, success criteria, failure criteria
   - Map to PTLC phases (Smoke, Load, Stress, Soak)

2. **Define Scenarios**
   - Happy path: normal user behavior (70% of traffic)
   - Error scenario: API errors, timeouts (5% of traffic)
   - Edge case: boundary conditions (5% of traffic)
   - Spike: sudden load increase (optional, 20% of traffic in stress)

3. **Define Assertions**
   - Response time assertions: p95 < SLA, p99 < SLA
   - Status code assertions: 95%+ must be 200-299
   - Error rate assertions: <1% total errors
   - Data validation: responses contain expected fields
   - Business logic: responses meet functional requirements

4. **Define Metrics to Collect**
   - Response time (min, max, mean, p95, p99)
   - Throughput (successful requests per second)
   - Error rate (errors as % of total)
   - Thread behavior (active, started, stopped)
   - Resource utilization (CPU, memory, connections on backend)

5. **Define Acceptance Criteria**
   - Pass/fail criteria for each test case
   - Regression criteria (compare to baseline)
   - Infrastructure constraints (CPU, memory thresholds)

**Output Artifacts**:
```
G3-test-design.md
├── Test Case Matrix
│   ├── TC-SMOKE-01: [Smoke test, 10 RPS, 5 min, baseline connectivity]
│   ├── TC-LOAD-01: [Load test, constant 500 RPS, 30 min, SLA validation]
│   ├── TC-STRESS-01: [Stress test, ramp 0→2000 RPS, 30 min, find breaking point]
│   ├── TC-SOAK-01: [Soak test, constant 800 RPS, 8 hours, memory leaks]
│   └── (10-12 total test cases)
├── Scenario Definitions
│   ├── SCENARIO-HAPPY-PATH: [User login → profile → search → download]
│   ├── SCENARIO-ERROR-HANDLING: [Simulate 5xx errors from API]
│   ├── SCENARIO-SPIKE: [Sudden 3x traffic increase]
│   └── SCENARIO-EDGE-CASE: [Large file upload, complex search query]
├── Assertion Rules
│   ├── Response Time: p95 < 200ms, p99 < 500ms (from G1 SLA)
│   ├── Status Code: 95%+ are 200-299
│   ├── Error Rate: <0.1% (from G1 SLA)
│   ├── Data Validation: every response has required fields
│   └── Business Logic: search results match query
├── Metrics Plan
│   ├── Collect: response_time, throughput, error_rate, cpu_usage
│   ├── Visualize: graphs of response time trend, error rate over test duration
│   ├── Compare: current run vs. baseline historical run
│   └── Report: summary statistics + pass/fail per test case
└── Acceptance Criteria
    ├── PASS if: all SLAs met + error rate <0.1% + no memory leaks
    ├── FAIL if: any SLA exceeded + error rate >1% + CPU >90% sustained
    └── REVIEW if: error rate 0.1-1% (investigate but may pass)
```

**Guardrails**:
- [ ] Every test case has success + failure criteria
- [ ] Assertions are aligned with G1 SLAs
- [ ] Metrics collection plan is specific (not just "monitor")
- [ ] Test cases are independent (no cross-contamination)
- [ ] Failure criteria are clear and actionable

**Approval Gate**: QA Lead + Performance Engineer  
**Approval Format**: JIRA comment "G3:APPROVED" + sign-off

**Next Gate**: G4 (Script) + Parallel: G5 (Data)

---

### G4: JMX Script Generation

**Agent Role**: `perf-builder` (Claude Sonnet 4.6)  
**Duration**: 6-8 hours  
**Dependency**: G3 approval  
**Parallelizable**: Yes (can run parallel with G5)

**Key Activities**:

1. **Generate Base JMX**
   - Create TestPlan with user-defined variables
   - Define thread groups for each test scenario
   - Configure HTTP samplers for each API call
   - Set up assertions per G3 design

2. **Assemble Modules**
   - Insert LOGIN module (authentication)
   - Insert UPL module (user profile)
   - Insert SEARCH module (search function)
   - Insert other modules in dependency order
   - Wire extractors between modules

3. **Configure Thread Groups**
   - Name: `baseline_auth_30s_10_300s` (test_type_api_rampup_threads_duration)
   - Thread count: from G2 capacity plan
   - Ramp-up time: from G2 load shapes
   - Loop count: based on test duration and RPS
   - Scheduler: duration in seconds from G2

4. **Add Listeners**
   - Aggregate Report listener (for summary stats)
   - Response Time Graph (for visualization)
   - Summary Report (for pass/fail tracking)
   - View Results Tree (debug only — DISABLED in production)

5. **Parameter Configuration**
   - External file for host variables (hosts.properties)
   - External file for SLA thresholds (sla.properties)
   - CSV data file references (users.csv, queries.csv, etc.)
   - Thread-safe variable scoping

6. **Validation**
   - JMX XML structure valid
   - All variables referenced are defined
   - All extractors match API responses
   - All assertions have valid assertion types

**Output Artifacts**:
```
G4-jmx-scripts/
├── baseline-test.jmx (smoke test — 10 RPS, 5 min)
├── load-test.jmx (load test — 500 RPS, 30 min constant)
├── stress-test.jmx (stress test — ramp 0→2000 RPS)
├── soak-test.jmx (soak test — 800 RPS, 8 hours)
├── hosts.properties (BASE_URL, host-security, host-core, etc.)
├── sla.properties (p95_threshold=200, p99_threshold=500, etc.)
└── README.md (how to run each JMX, expected output)

Directory structure inside each JMX:
├── Test Plan
│   ├── User-defined variables (BASE_URL, accessToken, etc.)
│   └── Thread Group {
│       ├── CSV Data Set Config (users.csv, queries.csv)
│       ├── HTTP Sampler: LOGIN module
│       │   └── JSON Extractor (extract accessToken)
│       ├── HTTP Sampler: UPL module
│       │   └── JSON Extractor (extract userId, folderKey)
│       ├── HTTP Sampler: SEARCH module
│       │   ├── Assertion: Status code == 200
│       │   ├── Assertion: Response time < 200ms
│       │   └── JSON Extractor (extract searchResults)
│       └── Aggregate Report Listener
│   }
```

**Guardrails**:
- [ ] JMX structure is valid XML (tested in JMeter GUI)
- [ ] All modules follow jmx-conventions.md
- [ ] Variable naming matches convention (${host-xxx}, ${__P()})
- [ ] Every API call has status code assertion
- [ ] Response time assertions match G1 SLAs
- [ ] CSV references point to actual files (in G5)
- [ ] No hardcoded IDs — all parameterized
- [ ] Extractors are tested against actual API responses

**GUI Review Gate** (before G5): 
- [ ] JMX opened in JMeter GUI
- [ ] Thread groups visible and correctly named
- [ ] Samplers (HTTP requests) visible
- [ ] Extractors correctly configured
- [ ] No missing file references

**Approval Gate**: QA Lead + Performance Engineer (GUI review)  
**Approval Format**: Test run in GUI + screenshot confirmation + "G4:APPROVED"

**Deliverable Validation**:
```bash
# Validate JMX syntax
jmeter -n -t baseline-test.jmx -l results.jtl 2>&1 | grep -i error

# Validate against schema (optional but recommended)
xmllint --dtdvalid jmeter.dtd baseline-test.jmx
```

**Next Gate**: G5 (Data preparation) — can run in parallel

---

### G5: Test Data Generation

**Agent Role**: `perf-builder` (Claude Sonnet 4.6)  
**Duration**: 3-4 hours  
**Dependency**: G2 (capacity plan defines record count)  
**Parallelizable**: Yes (can run parallel with G4)

**Key Activities**:

1. **Identify Data Requirements**
   - How many user records needed? (from G2 thread count)
   - What fields per user? (userId, emailId, password, authKey, etc.)
   - How many queries for search test? (unique search terms)
   - How many files for upload test? (if file-based)
   - Are there constraints? (valid email format, specific domain, etc.)

2. **Generate User Data**
   - Create users.csv with columns: userId, emailId, password, authKey, shardKey, folderKey, deviceKey
   - Generate realistic but synthetic data (no real PII)
   - Ensure uniqueness per row (no duplicate emails)
   - Include variation (different folder keys, shard keys for distributed testing)

3. **Generate Query Data**
   - Create queries.csv with column: searchQuery
   - Include mix of simple and complex queries
   - Cover search operator variations (AND, OR, quotes, wildcards)
   - Include both high-result and low-result queries

4. **Generate File Metadata** (if uploading)
   - Create upload-files.csv with columns: fileName, fileSize, mimeType
   - Mix of file sizes (small: 1KB, medium: 100KB, large: 10MB)
   - Mix of mime types (PDF, image, document)

5. **Validation**
   - CSV headers match module parameter names
   - No missing values (all rows have all columns)
   - Data types are correct (email looks like email, numbers are numeric)
   - Row count matches G2 capacity plan (×1.2 buffer for failures)

**Output Artifacts**:
```
G5-test-data/
├── users.csv (sample below)
│   userId,deviceKey,emailId,password,authKey,shardKey,rootFolderKey
│   user001,dk-001,user001@test.com,Test@123,base64token001,shard-1,rf-001
│   user002,dk-002,user002@test.com,Test@123,base64token002,shard-1,rf-002
│   [... 2500 rows total for peak load ...]
│
├── search-queries.csv
│   searchQuery
│   python tutorial
│   machine learning
│   [... 500 unique queries ...]
│
├── upload-files.csv (if applicable)
│   fileName,fileSize,mimeType
│   report-q1.pdf,250000,application/pdf
│   presentation.pptx,5000000,application/vnd.presentationml
│   [... 100 sample files ...]
│
└── data-validation-report.md
    ├── users.csv: 2500 rows, 0 duplicates, 0 missing values
    ├── search-queries.csv: 500 rows, all valid
    ├── upload-files.csv: 100 rows, sizes within range
    └── PASS: All validation checks complete
```

**Data Generation Script** (example):
```bash
#!/usr/bin/env bash
# Generate 2500 users with realistic variation

cat > users.csv << 'EOF'
userId,deviceKey,emailId,password,authKey,shardKey,rootFolderKey
EOF

for i in {1..2500}; do
  user_id=$(printf "%06d" $i)
  device_key="dk-$user_id"
  email="user$user_id@test.com"
  auth_key="base64token$user_id"
  shard=$((i % 10))
  folder_key="rf-$user_id"
  echo "$user_id,$device_key,$email,Test@123,$auth_key,shard-$shard,$folder_key" >> users.csv
done
```

**Guardrails**:
- [ ] CSV headers match G4 JMX references exactly
- [ ] No duplicate user IDs (primary key constraint)
- [ ] Row count = max thread count × 1.2 (buffer)
- [ ] All passwords are synthetic (not real passwords)
- [ ] All emails are in test domain (@test.com)
- [ ] No PII (real names, real phone numbers, etc.)
- [ ] Data validated before commit

**Data Validation Gate**:
```bash
# Check row count
wc -l users.csv

# Check for duplicates
cut -d',' -f1 users.csv | sort | uniq -d

# Check CSV format
python3 -c "import csv; list(csv.DictReader(open('users.csv')))"
```

**Approval Gate**: QA Lead + Data Steward  
**Approval Format**: "G5:APPROVED" + validation report link

**Next Gate**: G6 (Execution)

---

### G6: Execution & Push to Git

**Agent Role**: `perf-executor` (Claude Haiku 4.5)  
**Duration**: 2-3 hours  
**Dependency**: G4 approval (JMX) + G5 approval (Data)

**Key Activities**:

1. **Organize Artifacts**
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
   │   └── README.md (data dictionary)
   ├── properties/
   │   ├── hosts.properties
   │   ├── sla.properties
   │   └── local.properties (for dev override)
   ├── README.md (how to run tests locally)
   ├── Jenkinsfile (CI/CD trigger)
   └── G6-execution-checklist.md
   ```

2. **Pre-Push Validation**
   - [ ] All JMX files have valid XML syntax
   - [ ] All referenced CSV files exist
   - [ ] All properties files are valid key=value format
   - [ ] No secrets/credentials in files
   - [ ] README has clear instructions
   - [ ] Test names match naming convention
   - [ ] Version tracked (G1, G2, G3, G4, G5 approvals documented)

3. **Create Git Feature Branch**
   ```bash
   git checkout -b perf/story-{STORY_ID}-test-scripts
   ```

4. **Commit with Message Convention**
   ```
   perf: Add performance tests for story-{STORY_ID}

   Modules: [LOGIN, UPL, SEARCH, UPLOAD]
   Test Types: [Smoke, Load, Stress, Soak]
   Load Target: 500 RPS sustained, 2000 RPS peak
   Expected p95: <200ms
   
   Gate Approvals:
   - G1: SLA Extracted (signed off)
   - G2: Test Plan (approved)
   - G3: Test Design (approved)
   - G4: JMX Scripts (approved + GUI reviewed)
   - G5: Test Data (validated)
   - G6: Ready for execution
   
   Story: {ADO_STORY_ID}
   ```

5. **Push to Remote**
   ```bash
   git push origin perf/story-{STORY_ID}-test-scripts
   ```

6. **Trigger Argo Workflow**
   - Create PR (triggers basic CI checks)
   - Once PR approved, trigger Argo: `argo submit perf-pipeline.yaml --param story={STORY_ID}`
   - Argo executes G7 (Analysis) automatically

**Output Artifacts**:
```
Git commit:
  perf/story-12345-test-scripts
  ├── perf-tests/story-12345/
  │   ├── jmx/ [4 JMX files]
  │   ├── data/ [3 CSV files]
  │   ├── properties/ [3 properties files]
  │   └── README.md

Git log:
  $ git log --oneline -5
  a1b2c3d perf: Add performance tests for story-12345
  x9y8z7w Merge pull request #456 from perf/story-12345-test-scripts
  ...
```

**Guardrails**:
- [ ] Only commit to `perf/` branches (never main/master)
- [ ] All files follow naming convention
- [ ] No credentials or secrets in committed files
- [ ] No large binary files (>10MB) — use Git LFS if needed
- [ ] Commit message includes gate approvals
- [ ] README explains how to run locally + CI

**Pre-Push Checklist**:
```bash
# Lint JMX files for XML errors
xmllint --noout perf-tests/story-*/jmx/*.jmx

# Check for secrets
grep -r "password=" perf-tests/ | grep -v "Test@123"
grep -r "token=" perf-tests/ | grep -v "base64token"

# Validate CSV format
python3 -c "
import csv
for f in glob('perf-tests/**/data/*.csv'):
  list(csv.DictReader(open(f)))
" 

# Confirm branch name
git branch --show-current | grep "^perf/"
```

**Approval Gate**: Architect + DevOps  
**Approval Format**: PR review + "Approve & Merge" button + Argo confirmation

**Next Gate**: G7 (Analysis) — triggered automatically by Argo

---

### G7: Execution Analysis

**Agent Role**: `perf-analyst` (Claude Sonnet 4.6)  
**Duration**: 4-6 hours (can overlap with test execution)  
**Dependency**: G6 (tests pushed + Argo triggered)

**Key Activities**:

1. **Monitor Live Test Execution**
   - Tail JMeter output (response times, throughput, errors)
   - Monitor backend service metrics (CPU, memory, connections)
   - Watch for anomalies (sudden error spike, latency jump)
   - Note any failures and their timing

2. **Collect Raw Metrics**
   - JMeter output: results.jtl file (JSON Lines format)
   - Backend metrics: Prometheus scrapes (CPU, memory, request latency)
   - Network metrics: packet loss, latency, jitter
   - Database metrics: query latency, connection pool usage

3. **Post-Test Analysis**
   - Parse results.jtl: extract response times, status codes, sample labels
   - Calculate statistics:
     - Min, max, mean response time
     - Percentiles: p50, p95, p99, p99.9
     - Throughput: successful requests per second
     - Error rate: (failed requests / total requests) × 100%
   - Compare against baseline:
     - Did response time increase? (regression?)
     - Did throughput decrease? (degradation?)
     - Did error rate increase? (new issues?)

4. **Validate Against SLAs** (from G1)
   - p95 response time < 200ms? (PASS/FAIL)
   - p99 response time < 500ms? (PASS/FAIL)
   - Error rate < 0.1%? (PASS/FAIL)
   - Throughput > 1000 RPS sustained? (PASS/FAIL)
   - No memory leaks detected? (PASS/FAIL for soak test)

5. **Generate Analysis Report**
   - Detailed statistics table (min/max/mean/p95/p99 for each test)
   - Pass/Fail summary per test case
   - Baseline comparison (if previous baseline exists)
   - Graphs: response time timeline, throughput timeline, error rate
   - Bottleneck identification: which API calls were slow?
   - Recommendations: scale up? optimize API? cache data?

6. **Investigate Failures** (if any)
   - Which test case failed first?
   - What was the error? (timeout, 5xx, assertion failure)
   - Did it correlate with metric spike? (CPU, memory)
   - Is it reproducible?

**Output Artifacts**:
```
G7-analysis-report.md
├── Test Summary
│   ├── Smoke Test: PASS (5 min @ 10 RPS)
│   ├── Load Test: PASS (30 min @ 500 RPS constant)
│   ├── Stress Test: FAIL (hit error rate threshold @ 1500 RPS)
│   └── Soak Test: PENDING (still running)
│
├── Results Tables
│   ├── Smoke Test Results
│   │   Response Time (ms): min=50, p50=95, p95=180, p99=210, max=450
│   │   Throughput: 10.2 RPS (target: 10)
│   │   Error Rate: 0.0%
│   │   Status: PASS ✓
│   │
│   ├── Load Test Results
│   │   Response Time (ms): min=52, p50=120, p95=195, p99=380, max=2100
│   │   Throughput: 499.8 RPS (target: 500)
│   │   Error Rate: 0.05%
│   │   Status: PASS ✓
│   │
│   └── Stress Test Results
│   │   Response Time (ms): min=60, p50=250, p95=650, p99=1200, max=5000
│   │   Throughput: peaked @ 1200 RPS (target: 2000)
│   │   Error Rate: 2.3% (threshold: <0.1%)
│   │   Status: FAIL ✗
│
├── SLA Comparison
│   ├── SLA: p95 < 200ms
│   ├── Load Test: p95 = 195ms → PASS ✓
│   ├── Stress Test: p95 = 650ms → FAIL ✗
│   │
│   ├── SLA: Error Rate < 0.1%
│   ├── Load Test: 0.05% → PASS ✓
│   ├── Stress Test: 2.3% → FAIL ✗
│
├── Baseline Comparison
│   ├── Previous Baseline (2026-04-05):
│   │   Load Test p95: 180ms
│   ├── Current Run (2026-04-11):
│   │   Load Test p95: 195ms
│   ├── Regression: +8.3% (within acceptable variance)
│   └── Status: ACCEPTABLE (baseline regression within 10% tolerance)
│
├── Bottleneck Analysis
│   ├── Slowest API Call: UPLOAD module (p95 = 850ms)
│   │   Observation: File upload limited by network bandwidth
│   │   Recommendation: Increase test client bandwidth or reduce file size
│   │
│   ├── Highest Error Rate: LOGIN module (3% in stress test)
│   │   Observation: Auth service connection pool exhausted at 1500 RPS
│   │   Recommendation: Scale auth service, increase connection pool size
│   │
│   └── Memory Leak: Soak test memory grew 400MB over 8 hours
│       Observation: Possible connection leak in search API
│       Recommendation: Investigate search service for connection cleanup
│
├── Graphs
│   ├── [Graph] Response Time Timeline (load test)
│   │   Y-axis: Response time (ms)
│   │   X-axis: Time (minutes)
│   │   Shows: steady p95 around 195ms, no drift
│   │
│   ├── [Graph] Response Time Timeline (stress test)
│   │   Y-axis: Response time (ms)
│   │   X-axis: RPS (load)
│   │   Shows: latency increases sharply after 1000 RPS
│   │
│   └── [Graph] Error Rate Over Load
│       Y-axis: Error Rate (%)
│       X-axis: RPS
│       Shows: errors increase from 0% at 500 RPS to 2.3% at 1500 RPS
│
└── Recommendations
    ├── For PASS test cases:
    │   ├── Load Test passed all SLAs
    │   ├── Can support 500 RPS sustained load
    │   ├── May have capacity for 700-800 RPS with 10% margin
    │   └── Recommendation: Deploy with 500 RPS SLA target
    │
    ├── For FAIL test cases:
    │   ├── Stress test fails at 1500 RPS
    │   ├── Auth service is bottleneck
    │   ├── Needs investigation: connection pool, auth latency, caching
    │   └── Recommendation: Do NOT release until auth scaling addressed
    │
    └── Next Steps:
        ├── 1. Schedule architecture review with auth team
        ├── 2. Implement connection pool size increase
        ├── 3. Re-run stress test after optimization
        ├── 4. Update load profile if needed for prod traffic patterns
        └── 5. Document final safe load thresholds
```

**Analysis Guardrails**:
- [ ] All metrics extracted from actual test results (not guessed)
- [ ] SLA comparison is objective (pass/fail, not subjective)
- [ ] Baseline comparison includes date and conditions
- [ ] Bottlenecks identified with specific metrics (not vague)
- [ ] Recommendations are actionable (not generic advice)
- [ ] Graphs include axis labels and data points

**Approval Gate**: Performance Engineer + Tech Lead  
**Approval Format**: Analysis review + "G7:APPROVED" comment

**Failure Handling**:
- If test fails due to infrastructure issue: Fix infrastructure, re-run G6
- If test fails due to application issue: File bug ticket, schedule investigation, defer to next sprint
- If test fails SLA but has minor regression: Acceptance depends on business impact

**Next Gate**: G8 (Reporting & Go/No-Go Decision)

---

### G8: Performance Reporting & Go/No-Go Decision

**Agent Role**: `perf-reporter` (Claude Sonnet 4.6) + **HUMAN REVIEW REQUIRED**  
**Duration**: 2-3 hours (plus human review time)  
**Dependency**: G7 approval

**Key Activities**:

1. **Create Executive Report**
   - 1-page summary: test results, pass/fail, risk level
   - 2-page detailed findings: SLA comparison, bottleneck analysis
   - Executive decision: GO, NO-GO, or GO-WITH-CAUTION

2. **Define Risk Levels**
   - **GREEN (GO)**: All SLAs met, no bottlenecks identified, ready for production
   - **YELLOW (CAUTION)**: Minor SLA misses (within 5%), bottlenecks identified but mitigated, conditional go
   - **RED (NO-GO)**: Major SLA failures, unresolved bottlenecks, not ready for production

3. **Create Deployment Recommendations**
   - For GO: Safe to deploy, no preconditions
   - For CAUTION: Deploy only if bottleneck mitigation merged, add monitoring alerts, plan post-deployment validation
   - For NO-GO: Do not deploy, requires investigation and re-testing

4. **Document Assumptions & Caveats**
   - Test was run on staging environment (not production)
   - Test load may not match actual user behavior
   - Test data is synthetic (not representative of production data complexity)
   - Backend services were in normal state (no degradation, no updates)

5. **Sign-Off & Release Decision**
   - Report sent to product owner, tech lead, release manager
   - **HUMAN REQUIRED**: Release manager must approve GO decision
   - Approval recorded in JIRA/ADO as gate approval

**Output Artifacts**:
```
G8-release-report.md
├── Executive Summary
│   ├── Status: GO / NO-GO / GO-WITH-CAUTION
│   ├── Risk Level: GREEN / YELLOW / RED
│   ├── Recommendation: Ready for production
│   │
│   ├── SLA Summary
│   │   ├── p95 Response Time: PASS (195ms < 200ms target)
│   │   ├── p99 Response Time: PASS (380ms < 500ms target)
│   │   ├── Error Rate: PASS (0.05% < 0.1% target)
│   │   └── Overall: PASS ✓
│   │
│   └── Confidence: 95% (based on load test results at 500 RPS for 30 min)
│
├── Detailed Findings
│   ├── Test Results Overview
│   │   ├── Smoke Test: PASS (validated basic connectivity)
│   │   ├── Load Test: PASS (validated 500 RPS sustained)
│   │   ├── Stress Test: INVESTIGATION NEEDED (failed at 1500 RPS)
│   │   └── Soak Test: PASS (8 hours, no memory leaks detected)
│   │
│   ├── SLA Compliance
│   │   ├── Requirement: p95 < 200ms
│   │   ├── Load Test Result: p95 = 195ms
│   │   ├── Status: PASS ✓
│   │   ├── Confidence: Very High (test ran 30 min at steady load)
│   │   │
│   │   ├── Requirement: Error Rate < 0.1%
│   │   ├── Load Test Result: 0.05%
│   │   ├── Status: PASS ✓
│   │   └── Confidence: Very High
│   │
│   ├── Bottleneck Analysis
│   │   ├── None identified in load test range (up to 500 RPS)
│   │   ├── Stress test revealed bottleneck at 1500 RPS (beyond planned capacity)
│   │   ├── Bottleneck: Auth service connection pool exhaustion
│   │   ├── Root Cause: Connection pool size = 100, insufficient for 1500 RPS
│   │   ├── Impact: Not in load test range, does not affect GO decision
│   │   └── Mitigation: For future stress test planning, scale auth service
│   │
│   ├── Baseline Comparison
│   │   ├── Previous Baseline (2026-04-05): p95 = 180ms
│   │   ├── Current Run (2026-04-11): p95 = 195ms
│   │   ├── Regression: +8.3%
│   │   ├── Within Acceptable Variance: Yes (threshold = 10%)
│   │   └── Root Cause: Increased backend load (also testing file upload)
│   │
│   └── Confidence Assessment
│       ├── Load Test: 95% confidence (30 min duration, stable metrics)
│       ├── Soak Test: 90% confidence (8 hours, no memory leak detected)
│       ├── Stress Test: 50% confidence (bottleneck identified out of scope)
│       └── Overall Production Readiness: 92% confidence for 500 RPS load
│
├── Deployment Recommendations
│   ├── Safe Load Threshold: 500 RPS sustained, 700 RPS peak
│   ├── Monitoring Recommendations:
│   │   ├── Alert on p95 response time > 250ms (20% headroom from 200ms SLA)
│   │   ├── Alert on error rate > 0.2% (2x our SLA threshold)
│   │   ├── Alert on auth service CPU > 80%
│   │   └── Alert on memory growth > 100MB per hour
│   │
│   ├── Scaling Guidance:
│   │   ├── For 1000 RPS: Will need to scale auth service (increase pool size)
│   │   ├── For 2000 RPS: Will need to scale multiple services (see stress test findings)
│   │   └── For >2000 RPS: Schedule architecture review
│   │
│   └── Post-Deployment Validation:
│       ├── Monitor first 24 hours for anomalies
│       ├── Compare production metrics vs. test results
│       ├── If p95 > 250ms in prod: Investigate feature flags, caching, database
│       └── If error rate > 0.2% in prod: Rollback feature or file incident
│
├── Assumptions & Caveats
│   ├── Test Environment:
│   │   ├── Staging cluster (not production)
│   │   ├── Staging has similar hardware to production
│   │   ├── No other tests running during test window
│   │   └── Database was warmed up before test
│   │
│   ├── Test Data:
│   │   ├── 2500 synthetic users (vs. 100K real users in production)
│   │   ├── Realistic but not production-representative data complexity
│   │   └── No edge cases (very large documents, very long searches)
│   │
│   ├── Traffic Pattern:
│   │   ├── Test assumes uniform distribution (vs. real traffic spikes)
│   │   ├── Test covers 4 APIs only (vs. 20+ APIs in production)
│   │   ├── No third-party service delays (vs. real Slack, Jira integrations)
│   │   └── Test does not include background jobs or cron tasks
│   │
│   └── Interpretation:
│       ├── Performance results apply to tested APIs only
│       ├── Other system changes may impact production performance
│       ├── Real user behavior may differ from test scenarios
│       └── Recommend post-launch performance monitoring
│
├── Risk Assessment
│   ├── Risk Level: GREEN ✓
│   ├── Risk Factors:
│   │   ├── Stress test bottleneck (minor — outside load test range)
│   │   ├── 8% regression from baseline (acceptable — within variance)
│   │   ├── Test data is synthetic (mitigated by post-launch monitoring)
│   │   └── Limited geographic testing (mitigated by monitoring coverage)
│   │
│   └── Mitigation Plan:
│       ├── Deploy with increased monitoring alerts
│       ├── Plan architecture review for auth service scaling
│       ├── Schedule post-launch validation within 48 hours
│       └── Prepare rollback plan if production metrics diverge
│
└── Final Recommendation
    ├── Status: ✓ GO — READY FOR PRODUCTION
    ├── Conditions:
    │   ├── Deploy only to targeted regions first (canary rollout)
    │   ├── Monitor metrics closely (24-hour validation period)
    │   ├── Prepare rollback in case of anomalies
    │   └── Schedule post-launch performance review
    │
    ├── Decision Authority:
    │   ├── Performance Engineer: RECOMMENDS GO
    │   ├── Product Owner: APPROVES GO
    │   ├── Tech Lead: APPROVES GO
    │   ├── Release Manager: FINAL APPROVAL REQUIRED
    │   └── DevOps: Deploy confirmation
    │
    ├── Sign-Off
    │   ├── Performance Engineer: Jane Doe (date: 2026-04-11)
    │   ├── Product Owner: John Smith (date: 2026-04-11)
    │   ├── Tech Lead: Alice Johnson (date: 2026-04-11)
    │   ├── Release Manager: [PENDING APPROVAL]
    │   └── Build ID: build-12345 (git hash: a1b2c3d)
    │
    └── Artifacts Location
        ├── Test Results: s3://perf-results/story-12345/
        ├── JMX Scripts: git repo perf/story-12345-test-scripts
        ├── Analysis Report: docs/performance/story-12345-analysis.md
        └── This Report: docs/performance/story-12345-release-report.md
```

**Report Review Checklist** (Human reviewer):
- [ ] SLA comparison is clear (PASS/FAIL per SLA)
- [ ] Bottleneck analysis includes root cause
- [ ] Risk level assessment is justified
- [ ] Deployment recommendations are actionable
- [ ] Assumptions are clearly stated
- [ ] Post-deployment monitoring plan is specific
- [ ] All sign-offs are collected (not presumed)

**Gate Approval**: Product Owner + Tech Lead + **Release Manager**  
**Approval Format**: JIRA comment "G8:APPROVED:GO" with release manager sign-off  
**No Auto-Approval**: G8 gate is **HUMAN REQUIRED** — AI cannot approve release decision

**Release Decision Matrix**:

| Test Result | Status | Release Decision |
|------------|--------|------------------|
| All SLAs met, no issues | PASS | GO (conditional on post-launch monitoring) |
| 1 SLA missed by <5%, mitigated | PASS | GO-WITH-CAUTION (monitoring + mitigation required) |
| 1+ SLA missed by >5%, unmitigated | FAIL | NO-GO (requires investigation + re-testing) |
| Bottleneck identified, outside load range | PASS | GO (plan mitigation for next iteration) |
| Bottleneck identified, within load range | FAIL | NO-GO (must fix before deployment) |
| Memory leak detected in soak test | FAIL | NO-GO (investigate + re-test) |

---

## PTLC Success Criteria

A Performance Testing Lifecycle is complete when:

1. **All 8 gates have been approved** (G1 through G8)
2. **Release decision is documented** (GO, NO-GO, or CAUTION)
3. **All test artifacts are version-controlled** (JMX, CSV, reports)
4. **Post-launch monitoring plan is in place** (alerts, dashboards, validation)
5. **Team has signed off** (perf-architect, perf-builder, perf-executor, perf-analyst, perf-reporter, product owner, tech lead, release manager)

---

## PTLC Workflow Diagram

```
G1: Requirement
(perf-architect)
     ↓
G2: Planning
(perf-architect)
     ↓
G3: Design
(perf-architect)
     ↓
     ├─→ G4: Script (perf-builder) ─┐
     │                              ├─→ G6: Execution (perf-executor)
     └─→ G5: Data (perf-builder) ──┘         ↓
                                    G7: Analysis (perf-analyst)
                                          ↓
                                    G8: Reporting (perf-reporter + HUMAN)
                                          ↓
                                    Release Decision
                                    GO / NO-GO / CAUTION
```

---

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Next Review**: 2026-05-11  
**Owner**: Performance Architecture Team
