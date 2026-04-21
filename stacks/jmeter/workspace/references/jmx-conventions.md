# JMeter JMX Conventions & Standards

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Purpose**: Comprehensive guide for JMeter script structure, naming, configuration  
**Audience**: perf-builder agents, JMeter developers

---

## Overview

These conventions ensure JMeter test plans are consistent, maintainable, and reusable across the performance team. All JMX files must follow these standards.

---

## 1. Thread Group Conventions

### 1.1 Thread Group Naming

**Format**: `{testType}_{api}_{rampup}_{threads}_{duration}`

**Components**:
- `testType`: baseline | load | stress | soak | spike
- `api`: primary API being tested (auth, search, upload)
- `rampup`: ramp-up time (e.g., 30s, 1m, 10m)
- `threads`: number of concurrent threads (e.g., 10, 100, 1000)
- `duration`: hold time in seconds (e.g., 300s for 5 minutes)

**Examples**:
```
baseline_auth_30s_10_300s
  → Test Type: baseline
  → API: auth (login)
  → Ramp-up: 30 seconds
  → Threads: 10 concurrent users
  → Duration: 300 seconds (5 minutes steady state)

load_search_1m_500_1800s
  → Test Type: load
  → API: search
  → Ramp-up: 1 minute (60 seconds)
  → Threads: 500 concurrent users
  → Duration: 1800 seconds (30 minutes)

stress_upload_30m_2000_until-fail
  → Test Type: stress
  → API: upload
  → Ramp-up: 30 minutes
  → Threads: 2000 (ramp to breaking point)
  → Duration: until-fail (continue until response times exceed SLA)
```

### 1.2 Thread Group Configuration

**ArrivalsThreadGroup** (for constant RPS target):
```xml
<kg.apc.jmeter.timers.VariableThroughputTimer guiclass="kg.apc.jmeter.timers.VariableThroughputTimerGui">
  <stringProp name="calcMode">0</stringProp>
  <collectionProp name="load_profile">
    <collectionProp name="156171">
      <stringProp name="1633">1</stringProp>       <!-- 1 minute -->
      <stringProp name="1633">500</stringProp>    <!-- 500 RPS target -->
    </collectionProp>
  </collectionProp>
</kg.apc.jmeter.timers.VariableThroughputTimer>
```

**ConcurrencyThreadGroup** (for constant thread count):
```xml
<com.blazemeter.jmeter.threads.concurrency.ConcurrencyThreadGroup guiclass="com.blazemeter.jmeter.threads.concurrency.ConcurrencyThreadGroupGui">
  <stringProp name="ThreadGroup.name">load_auth_1m_100_1800s</stringProp>
  <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
  <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
    <stringProp name="LoopController.loops">-1</stringProp>  <!-- infinite loops -->
    <boolProp name="LoopController.continue_forever">false</boolProp>
  </elementProp>
  <stringProp name="concurrencyThreadGroup.start_threads_count">10</stringProp>
  <stringProp name="concurrencyThreadGroup.add_threads_count">9</stringProp>   <!-- ramp by 1/sec -->
  <stringProp name="concurrencyThreadGroup.ramp_time">90</stringProp>  <!-- 90 seconds to reach 100 -->
  <stringProp name="concurrencyThreadGroup.hold_load_for_time">1800</stringProp>  <!-- 30 min hold -->
  <stringProp name="concurrencyThreadGroup.shutdown_timeout">60</stringProp>
</com.blazemeter.jmeter.threads.concurrency.ConcurrencyThreadGroup>
```

**Standard ThreadGroup** (basic):
```xml
<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup">
  <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
  <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
    <stringProp name="LoopController.loops">-1</stringProp>
    <boolProp name="LoopController.continue_forever">false</boolProp>
  </elementProp>
  <stringProp name="ThreadGroup.num_threads">10</stringProp>
  <stringProp name="ThreadGroup.ramp_time">30</stringProp>
  <boolProp name="ThreadGroup.scheduler">true</boolProp>
  <stringProp name="ThreadGroup.duration">300</stringProp>
  <stringProp name="ThreadGroup.delay">0</stringProp>
</ThreadGroup>
```

### 1.3 Error Handling Strategy

**For Critical Tests** (load, stress):
```xml
<stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
```
Reason: Don't stop test on first error — need to measure system behavior under load, including errors.

**For Baseline Tests** (smoke):
```xml
<stringProp name="ThreadGroup.on_sample_error">stoponerror</stringProp>
```
Reason: Stop immediately if basic connectivity fails — indicates infrastructure issue.

---

## 2. Authentication Patterns

### 2.1 Login → Token Extraction → Bearer Auth

**Pattern**:
1. First sampler: POST /auth/login
2. Extractor: JSON Path to get `accessToken`
3. Subsequent samplers: Add `Authorization: Bearer ${accessToken}` header

**JMX Structure**:
```xml
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy">
  <stringProp name="HTTPSampler.name">01 - LOGIN</stringProp>
  <stringProp name="HTTPSampler.domain">${host-security}</stringProp>
  <stringProp name="HTTPSampler.path">/api/v1/auth/login</stringProp>
  <stringProp name="HTTPSampler.method">POST</stringProp>
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="emailId" elementType="HTTPArgument">
        <stringProp name="Argument.name">emailId</stringProp>
        <stringProp name="Argument.value">${emailId}</stringProp>
      </elementProp>
      <elementProp name="password" elementType="HTTPArgument">
        <stringProp name="Argument.name">password</stringProp>
        <stringProp name="Argument.value">${password}</stringProp>
      </elementProp>
    </collectionProp>
  </elementProp>
  <stringProp name="HTTPSampler.connect_timeout">5000</stringProp>
  <stringProp name="HTTPSampler.response_timeout">5000</stringProp>
</HTTPSamplerProxy>
<hashTree>
  <JSONPostProcessor guiclass="JSONPostProcessor" testclass="JSONPostProcessor">
    <stringProp name="JSONPostProcessor.referenceNames">accessToken</stringProp>
    <stringProp name="JSONPostProcessor.jsonPathExprs">$.data.accessToken</stringProp>
    <stringProp name="JSONPostProcessor.match_numbers">1</stringProp>
  </JSONPostProcessor>
</hashTree>

<!-- Subsequent API call using extracted token -->
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy">
  <stringProp name="HTTPSampler.name">02 - GET PROFILE</stringProp>
  <stringProp name="HTTPSampler.domain">${host-core}</stringProp>
  <stringProp name="HTTPSampler.path">/api/v1/users/${userId}/profile</stringProp>
  <stringProp name="HTTPSampler.method">GET</stringProp>
  <!-- Add Authorization header -->
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="Authorization" elementType="HTTPArgument">
        <stringProp name="Argument.name">Authorization</stringProp>
        <stringProp name="Argument.value">Bearer ${accessToken}</stringProp>
        <boolProp name="HTTPArgument.use_equals">true</boolProp>
        <boolProp name="HTTPArgument.always_encode">false</boolProp>
      </elementProp>
    </collectionProp>
  </elementProp>
</HTTPSamplerProxy>
```

### 2.2 Token Refresh Pattern

**When to Refresh**:
- Test duration > token expiry time
- Token expiry < 5 minutes remaining

**Implementation**:
```xml
<!-- After LOGIN, extract refreshToken -->
<JSONPostProcessor guiclass="JSONPostProcessor" testclass="JSONPostProcessor">
  <stringProp name="JSONPostProcessor.referenceNames">refreshToken,tokenExpiresIn</stringProp>
  <stringProp name="JSONPostProcessor.jsonPathExprs">$.data.refreshToken;$.data.expiresIn</stringProp>
</JSONPostProcessor>

<!-- Add If Controller: refresh if expiresIn < 300 seconds (5 min) -->
<IfController guiclass="IfControllerPanel" testclass="IfController">
  <stringProp name="IfController.condition">${tokenExpiresIn} &lt; 300</stringProp>
  
  <!-- REFRESH Token sampler -->
  <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy">
    <stringProp name="HTTPSampler.name">RETOKEN</stringProp>
    <stringProp name="HTTPSampler.domain">${host-security}</stringProp>
    <stringProp name="HTTPSampler.path">/api/v1/auth/refresh</stringProp>
    <stringProp name="HTTPSampler.method">POST</stringProp>
    <!-- body: {"refreshToken": "${refreshToken}"} -->
  </HTTPSamplerProxy>
  <hashTree>
    <JSONPostProcessor>
      <stringProp name="JSONPostProcessor.referenceNames">accessToken</stringProp>
      <stringProp name="JSONPostProcessor.jsonPathExprs">$.data.accessToken</stringProp>
    </JSONPostProcessor>
  </hashTree>
</IfController>
```

---

## 3. CSV Data Set Config Conventions

### 3.1 CSV File Placement

**Location**: `data/{api}_{scenario}.csv`

**Examples**:
```
data/auth_credentials.csv      (users for login)
data/search_queries.csv         (search terms)
data/upload_files.csv           (file metadata)
data/users_complex.csv          (users with multiple attributes)
```

### 3.2 CSV Column Naming

**Format**: lowercase_with_underscores (matching JMX variable names)

**Standard Columns**:
```
userId,emailId,password,authKey,shardKey,rootFolderKey
user001,user001@test.com,Test@123,base64token001,shard-1,rf-001
user002,user002@test.com,Test@123,base64token002,shard-1,rf-002
```

### 3.3 CSV Config Element

```xml
<CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet">
  <stringProp name="delimiter">,</stringProp>
  <stringProp name="fileEncoding">UTF-8</stringProp>
  <stringProp name="filename">${TESTPLAN_DIR}/data/users.csv</stringProp>
  <boolProp name="ignoreFirstLine">false</boolProp>
  <boolProp name="quotedData">false</boolProp>
  <boolProp name="recycle">true</boolProp>  <!-- restart from beginning when exhausted -->
  <boolProp name="stopThread">false</boolProp>  <!-- continue if file exhausted -->
  <stringProp name="shareMode">shareMode.all</stringProp>  <!-- all threads share same data -->
</CSVDataSet>
```

### 3.4 File Path Variables

**Use relative paths with ${TESTPLAN_DIR}**:
```xml
<stringProp name="filename">${TESTPLAN_DIR}/data/users.csv</stringProp>
```

Never hardcode absolute paths like `/home/user/...` or `C:\Users\...`

---

## 4. Assertion Conventions

### 4.1 Status Code Assertion

**Required for every HTTP sampler**:

```xml
<ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion">
  <stringProp name="TestType">6</stringProp>  <!-- response code assertion -->
  <collectionProp name="Asserions">
    <stringProp name="1633">200</stringProp>
  </collectionProp>
  <stringProp name="Assertion.test_type">6</stringProp>
  <intProp name="Assertion.test_strings_type">6</intProp>
  <boolProp name="Assertion.assume_success">false</boolProp>
</ResponseAssertion>
```

### 4.2 Response Time Assertion

**For SLA validation**:

```xml
<DurationAssertion guiclass="DurationAssertionGui" testclass="DurationAssertion">
  <stringProp name="DurationAssertion.failure_message">Response time SLA exceeded</stringProp>
  <intProp name="DurationAssertion.milliseconds">500</intProp>  <!-- max 500ms -->
</DurationAssertion>
```

**For different SLAs**:
- Login: < 5000ms
- Profile lookup: < 2000ms
- Search: < 5000ms
- File operations: < 30000ms

### 4.3 Content Assertion (JSON Response)

**Validate response structure**:

```xml
<JSONPathAssertion guiclass="JSONPathAssertionGui" testclass="JSONPathAssertion">
  <stringProp name="JSON_PATH">$.status</stringProp>
  <stringProp name="EXPECT_NULL">false</stringProp>
  <boolProp name="INVERT">false</boolProp>
  <boolProp name="ISREGEX">false</boolProp>
  <stringProp name="EXPECTED_VALUE">success</stringProp>
  <boolProp name="JSONVALIDATION">true</boolProp>
</JSONPathAssertion>
```

### 4.4 Assertion Failure Handling

- **Continue on assertion failure**: Let error rate rise (measure system behavior)
- **Stop on assertion failure**: Only for smoke tests (early detection of blocker)

---

## 5. Listener Conventions

### 5.1 Listeners to Include

**Production/CI Runs** (save to file):

```xml
<!-- Aggregate Report (required) -->
<ResultCollector guiclass="AssertionVisualizer" testclass="ResultCollector">
  <stringProp name="ResultCollector.error_logging">false</stringProp>
  <objProp>
    <name>ResultCollector.sample_listener</name>
    <value class="SampleSaveConfiguration">
      <time>true</time>
      <latency>true</latency>
      <timestamp>true</timestamp>
      <success>true</success>
      <label>true</label>
      <code>true</code>
      <message>true</message>
      <threadName>true</threadName>
      <dataType>true</dataType>
      <encoding>false</encoding>
      <assertions>true</assertions>
      <subresults>true</subresults>
      <responseData>false</responseData>
      <samplerData>false</samplerData>
      <xml>false</xml>
      <fieldNames>true</fieldNames>
      <responseHeaders>false</responseHeaders>
      <requestHeaders>false</requestHeaders>
      <responseDataOnError>false</responseDataOnError>
      <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage>
      <assertionsResultsToSave>0</assertionsResultsToSave>
      <bytes>true</bytes>
      <sentBytes>true</sentBytes>
      <url>true</url>
      <threadCounts>true</threadCounts>
      <idleTime>true</idleTime>
      <connectTime>true</connectTime>
    </value>
  </objProp>
  <stringProp name="filename">results/results-${__time(yyyyMMdd-HHmmss)}.jtl</stringProp>
</ResultCollector>
```

**File Format**: `.jtl` (JMeter Test Log, actually JSON Lines)

### 5.2 Listeners to AVOID in Production

- View Results Tree (expensive memory; disable in CI)
- Graph Results (GUI only, not for headless)
- Table Report (write to file instead)

### 5.3 Result File Location

**Format**: `results/results-{timestamp}.jtl`

**Example**:
```
results/results-20260411-143000.jtl
results/results-20260411-153015.jtl
```

---

## 6. Variable Naming Conventions

### 6.1 Host Variables (Infrastructure)

**Format**: `${host-<service>}`

**Examples**:
```
${host-security}     → Auth service host (e.g., auth-prod.example.com:8443)
${host-core}         → Core API host (e.g., api-prod.example.com:443)
${host-storage}      → File storage host (e.g., storage-prod.example.com:443)
${host-messaging}    → Messaging service host
${host-analytics}    → Analytics service host
```

### 6.2 User/Test Data Variables (CSV sourced)

**Format**: `${<field>}` (matches CSV header)

**Examples**:
```
${userId}
${emailId}
${password}
${authKey}
${shardKey}
${folderKey}
```

### 6.3 Extracted Variables (from API responses)

**Format**: `${<api>_<field>}` or just `${<field>}` (prefer shorter for brevity)

**Examples**:
```
${accessToken}      (from login)
${userId}           (from profile lookup)
${documentId}       (from search results)
${refreshToken}     (from login)
```

### 6.4 JMeter Built-in Variables

**Format**: `${__<function>()}`

**Examples**:
```
${__time()}                          → Current time in ms
${__timeStr(yyyy-MM-dd)}             → Formatted time
${__uuid()}                          → Random UUID
${__P(propertyName,defaultValue)}    → Command-line property
${__randomString(5,abcdef)}          → Random string
${__randomInt(1,100)}                → Random integer
${__javaScript(...)}                 → Inline JavaScript
```

### 6.5 User-Defined Variables (Test Plan level)

**Format**: UPPERCASE or camelCase (consistent within test)

**Examples**:
```
TEST_DURATION = 300
BASE_URL = https://api.example.com
SLA_RESPONSE_TIME_P95 = 200
RAMP_UP_TIME = 30
```

---

## 7. Timer Conventions

### 7.1 Think Time (Constant Timer)

**Purpose**: Simulate user delay between actions

**Standard Value**: 1000-3000ms (between requests in a user journey)

```xml
<ConstantTimer guiclass="ConstantTimerGui" testclass="ConstantTimer">
  <stringProp name="ConstantTimer.delay">1000</stringProp>
</ConstantTimer>
```

### 7.2 Random Timer

**Purpose**: Variable delay to avoid synchronized traffic

```xml
<RandomTimer guiclass="RandomTimerGui" testclass="RandomTimer">
  <stringProp name="RandomTimer.range">1000</stringProp>  <!-- +/- 1000ms -->
  <stringProp name="ConstantTimer.delay">500</stringProp>  <!-- base 500ms -->
</RandomTimer>
```

### 7.3 Gaussian Random Timer (Optional)

**Purpose**: More realistic distribution of delays

```xml
<GaussianRandomTimer guiclass="GaussianRandomTimerGui" testclass="GaussianRandomTimer">
  <stringProp name="GaussianRandomTimer.range">500</stringProp>
  <stringProp name="ConstantTimer.delay">1000</stringProp>
</GaussianRandomTimer>
```

---

## 8. JMX XML Structure Conventions

### 8.1 Overall Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0">
  <hashTree>
    
    <!-- TestPlan Element (root) -->
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan">
      <stringProp name="TestPlan.name">load_search_test</stringProp>
      <stringProp name="TestPlan.comments">
        Purpose: Load test search API at 500 RPS
        Duration: 30 minutes
        Story: PERF-1234
      </stringProp>
      
      <!-- User-defined variables -->
      <elementProp name="TestPlan.user_defined_variables" 
                   elementType="Arguments" 
                   guiclass="ArgumentsPanel">
        <collectionProp name="Arguments.arguments">
          <elementProp name="base-path" elementType="Argument">
            <stringProp name="Argument.name">base-path</stringProp>
            <stringProp name="Argument.value">/api/v1</stringProp>
          </elementProp>
        </collectionProp>
      </elementProp>
      
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
    </TestPlan>
    
    <!-- Hash tree for TestPlan children -->
    <hashTree>
      
      <!-- CSV Data Set (shared across all thread groups) -->
      <CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet">
        ...
      </CSVDataSet>
      <hashTree></hashTree>
      
      <!-- Thread Group -->
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup">
        ...
      </ThreadGroup>
      <hashTree>
        
        <!-- Samplers and postprocessors inside thread group -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy">
          ...
        </HTTPSamplerProxy>
        <hashTree>
          <JSONPostProcessor guiclass="JSONPostProcessor" testclass="JSONPostProcessor">
            ...
          </JSONPostProcessor>
          <hashTree></hashTree>
        </hashTree>
        
        <!-- Listeners -->
        <ResultCollector guiclass="AssertionVisualizer" testclass="ResultCollector">
          ...
        </ResultCollector>
        <hashTree></hashTree>
        
      </hashTree>
      
    </hashTree>
    
  </hashTree>
</jmeterTestPlan>
```

### 8.2 Element Nesting Rules

- Every element has a `<hashTree>` child for its sub-elements
- `<hashTree></hashTree>` (empty) means no children
- Proper nesting is critical for JMeter to parse correctly

### 8.3 Required Attributes

All elements must have:
- `guiclass` — GUI class (for display in JMeter GUI)
- `testclass` — Test class (actual implementation)

**Common Test Classes**:
- HTTPSamplerProxy (HTTP request)
- ThreadGroup (thread group)
- CSVDataSet (CSV data)
- JSONPostProcessor (JSON extraction)
- ResponseAssertion (assertion)
- ResultCollector (listener)
- ConstantTimer (timer)

---

## 9. Parameterization Patterns

### 9.1 Command-Line Properties

**Usage**: Pass parameters at runtime without modifying JMX

```bash
jmeter \
  -Jhost-security=custom-auth.example.com \
  -Jhost-core=custom-api.example.com \
  -Jnum_threads=1000 \
  -Jduration=600 \
  -n -t load-test.jmx \
  -l results.jtl
```

**In JMX**: Reference with `${__P(param_name,default_value)}`

```xml
<stringProp name="HTTPSampler.domain">${__P(host-core,localhost)}</stringProp>
<stringProp name="ThreadGroup.num_threads">${__P(num_threads,100)}</stringProp>
```

### 9.2 Properties File

**Create**: `jmeter.properties` in test directory

```properties
# hosts configuration
host-security=auth-prod.example.com:8443
host-core=api-prod.example.com:443
host-storage=storage-prod.example.com:443

# SLA thresholds
sla-response-time-p95=200
sla-response-time-p99=500
sla-error-rate=0.001

# test parameters
base-path=/api/v1
connect-timeout=5000
```

**Usage**:
```bash
jmeter -p jmeter.properties -n -t test.jmx -l results.jtl
```

### 9.3 Environment-Specific Properties

**dev.properties**:
```properties
host-security=localhost:8443
host-core=localhost:8080
```

**staging.properties**:
```properties
host-security=auth-staging.example.com:8443
host-core=api-staging.example.com:443
```

**prod.properties**:
```properties
host-security=auth-prod.example.com:8443
host-core=api-prod.example.com:443
```

**Usage**:
```bash
# Dev
jmeter -p dev.properties -n -t test.jmx -l results-dev.jtl

# Staging
jmeter -p staging.properties -n -t test.jmx -l results-staging.jtl

# Prod (never direct test against production!)
# Instead, use staging environment replicated from prod
```

---

## 10. Example Complete JMX Structure

See `template-login.jmx` in the workspace for a complete, working example.

---

## 11. Validation Checklist

Before committing JMX files:

- [ ] JMX opens in JMeter GUI without errors
- [ ] Thread group names follow convention: `{type}_{api}_{rampup}_{threads}_{duration}`
- [ ] All HTTP samplers have status code assertions
- [ ] All extracted variables are used in subsequent requests
- [ ] CSV file paths use relative `${TESTPLAN_DIR}`
- [ ] Host variables use `${host-<service>}` naming
- [ ] No hardcoded IPs, ports, or credentials
- [ ] Extractors match actual API response format
- [ ] Response time assertions match SLA thresholds
- [ ] Results file path is defined in listener
- [ ] Test duration and thread count are reasonable
- [ ] Listeners are configured for file output

---

**Last Updated**: 2026-04-11  
**Owner**: Performance Team  
**Next Review**: 2026-05-11
