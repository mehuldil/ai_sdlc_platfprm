---
name: JMeter Performance Implementation Variant
description: Implementation RPI rules and guardrails for JMeter performance tests
stack: jmeter-perf
---

# JMeter Performance Implementation Variant

## Tech Stack
- Test Framework: JMeter 5.6+
- Test Format: JMX (XML files)
- Load Execution: Argo Workflows or Jenkins
- Reporting: JMeter HTML reports, custom Grafana dashboards
- Data Generation: CSV data sets, custom Java functions
- Monitoring: Prometheus + Grafana (backend metrics)

## RPI Rules

**Serialization:** [rpi-serialization-baseline.md](../../_includes/rpi-serialization-baseline.md) — phase locks for every stack. **Normative:** [rpi-workflow.md](../../../rules/rpi-workflow.md).

### Research Phase
- Load max 10 files (2K chars each)
- Read: performance-requirements.md (NFRs, SLAs, targets)
- Read: existing JMX files (templates, structure)
- Read: jmeter-patterns.md, csv-data-prep.md
- Read: argo-workflow-guide.md

### Plan Phase
- Plan test scenarios: smoke, load, stress, soak tests
- Define test data: user count, ramp-up time, duration
- Plan assertions: response time, error rate, throughput targets
- List CSV data files needed
- List Argo workflow steps

### Implement Phase
- Create JMX file: Thread Groups, Samplers, Assertions, Listeners
- Generate CSV data: users.csv, products.csv, etc.
- Config Argo workflow: JMeter pod, inputs/outputs, resource limits
- Define assertions: response time <= SLA, errors < 1%
- Enable logging: only critical errors (high volume impacts perf)
- Post-test: cleanup threads, close connections

## JMeter Components

### Thread Group
- Number of Threads: per test type (smoke: 10, load: 100, stress: 1000)
- Ramp-Up: seconds to reach full load (typically = threads)
- Loop Count: iterations per thread (-1 = infinite, duration-limited)
- Duration: total test run time in seconds (scheduler)

### Samplers
- HTTP Request: method, URL, parameters, headers, body
- JDBC Request: SQL queries for database load
- Kafka Producer: publish messages (if using jmeter-kafka plugin)

### Assertions
- Response Assertion: check status code, response text
- Duration Assertion: response time <= SLA (e.g., 500ms)
- Regex Extractor: capture dynamic values for next request

### Listeners
- Summary Report: aggregate results (throughput, avg, min, max)
- HTML Dashboard: detailed HTML report with graphs
- Backend Listener: send results to external system (InfluxDB, Prometheus)

## Test Scenarios

### Smoke Test
- Threads: 10
- Ramp-up: 10s
- Duration: 5m
- Goal: validate test setup, no performance expectations

### Load Test
- Threads: 100
- Ramp-up: 100s (linear)
- Duration: 10m
- Goal: measure response time and throughput at normal load

### Stress Test
- Threads: 500-2000
- Ramp-up: 60s
- Duration: 5-10m
- Goal: find breaking point, system response under overload

### Soak Test
- Threads: 50% of peak
- Duration: 1-2h
- Goal: detect memory leaks, connection pool issues

## Guardrails

### Performance
- Heap: JMeter -Xmx2g (2GB minimum for load tests)
- Aggregation: summarize results post-test, not during
- Remote: use slave mode for distributed load (JMeter distributed architecture)
- Cleanup: disable Think Time between requests (synchronize load)

### Data Generation
- CSV data: separate file per data type (users, products)
- Randomization: use ${__Random()} function for variety
- User IDs: sequential or random (avoid collisions)
- Reset: loop CSV data or generate on-the-fly

### Reporting
- Store results: save JTL (results) file for analysis
- HTML dashboard: generate post-test with perfmon plugins
- Metrics: throughput (req/sec), latency (ms), error rate (%)
- SLA check: assert error rate < 1%, P95 latency < SLA

## Dependency Checklist
- JMeter 5.6+ (binary or Docker image)
- JMeter plugins: Dummy Sampler, Graphs, InfluxDB, Kafka (if needed)
- CSV data files (users.csv, products.csv, etc.)
- Argo Workflows (for distributed execution)
- Backend monitoring: Prometheus scrape config, Grafana dashboard
- Gradle or Maven (if custom Java functions needed)
