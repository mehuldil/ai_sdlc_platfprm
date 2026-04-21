# Performance Guardrails (JMeter)

## Phase Transition Gates
All performance test phases require explicit gate approval:
- **Smoke test**: Verify basic connectivity before load phase
- **Ramp-up**: Gradually increase load (mandatory validation point)
- **Sustained load**: Maintain peak load for duration (must pass health checks)
- **Ramp-down**: Graceful reduction (verify no cascading failures)
- **Gate approval**: Lead QA or architect must approve transition

## JMX Rules

### Structure & Configuration
- **No ConfigTestElement**: Never use for test data (use CSV or parameterized values)
- **CSV variables**: Use lowercase names (e.g., `user_id`, `session_token`)
- **JSON metadata**: Include full schema in JMX comments
  ```json
  {
    "test_name": "Login Performance",
    "target_throughput": 500,
    "ramp_up_period": 60,
    "threads": 100
  }
  ```

## Response Limits
- **Max output tokens**: 1200 per response in LLM integrations
- **Applies to**: JMeter result processing, analysis reporting
- **Enforcement**: Fail response if exceeds token limit

## Guardrails

### Scope Guardrails
- Clear definition of test boundaries (which endpoints/flows)
- Document assumptions (network latency, server config)
- Exclude external dependencies where possible

### Data Guardrails
- Use realistic, anonymized test data
- No hardcoded credentials in JMX
- Version-control test datasets separately
- Document data source location

### Execution Guardrails
- Run tests in isolated environment
- Monitor resource utilization (CPU, memory, network)
- Set reasonable timeouts (connection, read)
- Capture full logs for analysis
- Run at least 3 iterations for stability

## Reporting
- Document baseline metrics (before optimization)
- Report P50, P95, P99 latencies
- Include error rate and failed requests
- Identify bottlenecks and recommendations

---
**Last Updated**: 2026-04-11  
**Stack**: JMeter
