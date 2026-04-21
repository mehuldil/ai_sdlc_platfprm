# Load Test Standards & Load Profiles

## Load Profiles

### Baseline (Normal Load)
- **Threads**: 10-50
- **Ramp-up**: 30-60 seconds
- **Duration**: 5 minutes
- **Purpose**: Validate system under expected load
- **Success Criteria**: p99 latency <500ms, 0% errors

### Peak (Expected Peak Hours)
- **Threads**: 100-500
- **Ramp-up**: 1-2 minutes
- **Duration**: 10 minutes
- **Purpose**: Validate system under peak load
- **Success Criteria**: p95 latency <1s, <1% errors

### Stress (Breaking Point)
- **Threads**: 500-2000
- **Ramp-up**: 30 seconds
- **Duration**: 2-5 minutes
- **Purpose**: Find system breaking point
- **Success Criteria**: Identify failure mode

### Soak (Long Running)
- **Threads**: 50-100 (moderate)
- **Ramp-up**: 2-5 minutes
- **Duration**: 1-4 hours
- **Purpose**: Detect memory leaks, cache issues
- **Success Criteria**: Stable response times, no gradual degradation

## Metrics to Track

### Response Time
- **Min**: Minimum response time
- **Avg**: Average response time
- **Max**: Maximum response time
- **p95/p99**: 95th and 99th percentile latencies

### Throughput
- **Requests/sec**: Total requests processed
- **Success rate**: % of successful requests
- **Error rate**: % of failed requests

### Resource Utilization
- CPU: <80% under normal load
- Memory: Stable (no leaks)
- Disk I/O: <90% utilization

## Baseline Establishment
1. Run baseline profile 3 times consecutively
2. Record avg response time, p95, p99
3. Establish as baseline reference
4. Future tests compared against baseline

## Test Reporting
- Graph: Response time trend over test duration
- Table: Min/avg/max/p95/p99 latencies
- Error log: All failed requests with timestamps
- Recommendation: Pass/fail/investigate

---
**Last Updated**: 2026-04-10  
**Stack**: JMeter
