# JMeter Testing Standards

## Thread Group Configuration

### Parameters
- **Ramp-up Time**: How quickly to reach target threads
  - Baseline: 30-60 seconds
  - Peak: 1-2 minutes
  - Stress: 30 seconds
- **Hold Load Time**: Duration to maintain load
  - Baseline: 5 minutes
  - Peak: 10 minutes
  - Stress: 2 minutes
- **Loop Count**: Often "infinite" for duration-based tests

## Listeners (Observers)

### Aggregate Report
- CSV export: Pass/fail counts, response times (min/avg/max/p95/p99)
- File: `results/aggregate_{test-name}_{timestamp}.csv`

### Graph Results
- Real-time visualization
- X-axis: Time, Y-axis: Response time (ms)
- Helps identify bottlenecks

### View Results Tree
- Debug only (high overhead)
- Disable in production runs
- Captures request/response bodies

## Assertions (Validations)

### HTTP Status Code
```
Expected: 200
```

### Response Assertion
- Type: Contains (substring match)
- Pattern: `"success": true` (for JSON)

### Duration Assertion
```
> 500 ms → FAIL
```

## Sampler Configuration

### HTTP Request
- Protocol: https
- Hostname: {BASE_URL}
- Port: (auto from protocol)
- Path: /api/v1/users
- Method: GET/POST/PUT

## CSV Data Set Configuration
- Filename: `src/test/data/{api}.csv`
- Delimiter: `,`
- Variable names: `user_id, email, password`
- Recycle on EOF: `True`
- Stop thread on EOF: `False`

---
**Last Updated**: 2026-04-10  
**Stack**: JMeter
