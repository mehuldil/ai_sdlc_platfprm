# JMeter Load Testing Conventions

## Overview
JMeter is used for load, stress, and soak testing. Tests are version-controlled as .jmx files (XML format).

## JMX File Structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan">
      <elementProp name="TestPlan.user_defined_variables" 
                   elementType="Arguments" guiclass="ArgumentsPanel"/>
    </TestPlan>
    <hashTree>
      <!-- Thread Groups and Listeners -->
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

## Thread Group Naming
- **Format**: `{test-type}_{api}_{rampup}_{threads}_{duration}`
- Examples:
  - `baseline_auth-login_30s_10_300s`
  - `peak_user-profile_1m_100_600s`
  - `stress_search_30s_500_300s`

## Parameterization
- **CSV Data Files**: `src/test/data/{api}_{scenario}.csv`
- Headers: `user_id,email,password`
- CSV Config Element: Points to file, sets thread count

## Variables & Properties
- User-defined variables in Test Plan
- System properties for environment switching
- Example variables:
  ```
  BASE_URL = http://localhost:8080
  RAMP_UP_TIME = 30
  NUM_THREADS = 10
  HOLD_LOAD_TIME = 300
  ```

## Listener Configuration
- **View Results Tree** (DEBUG only; disable in production runs)
- **Aggregate Report** (for summary statistics)
- **Graph Results** (for visual analysis)
- Save responses to: `results/{test-name}_{timestamp}.jtl`

## Assertions & Validations
- HTTP Status Code: Expect 200, 201, etc.
- Response Assertion: Validate JSON/XML structure
- Duration Assertion: Request <500ms

## File Organization
```
jmeter/
├── tests/
│   ├── baseline_tests.jmx
│   ├── peak_tests.jmx
│   ├── stress_tests.jmx
│   ├── soak_tests.jmx
├── data/
│   ├── auth_credentials.csv
│   ├── search_queries.csv
├── results/
├── scripts/
│   ├── run_baseline.sh
│   ├── run_peak.sh
```

---
**Last Updated**: 2026-04-10  
**Stack**: JMeter
