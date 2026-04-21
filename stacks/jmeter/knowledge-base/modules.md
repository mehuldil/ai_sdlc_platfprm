# JMeter Module Registry

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Audience**: Performance architects, perf-builder agents, perf-executor

---

## Overview

The Module Registry is a catalog of reusable, composable JMeter modules that can be assembled into complete performance test plans. Each module encapsulates a specific API interaction or test behavior and can be reused across multiple test scenarios.

Modules are designed to be:
- **Parameterized**: Accept runtime variables for flexibility
- **Composable**: Chain multiple modules into a single test flow
- **Reusable**: Share across multiple test plans and scenarios
- **Versioned**: Track changes and compatibility

---

## Module Registry (12+ Registered Modules)

### 1. LOGIN (Authentication Module)

**Module ID**: `LOGIN-v2.0`  
**Purpose**: Handle user login and access token acquisition  
**API Pattern**: `POST /api/v1/auth/login`  
**Dependencies**: None (entry point)

**Parameters**:
- `${host-security}` - Auth service host (default: localhost:8443)
- `${base-path}` - API base path (default: /api/v1)
- `${login-timeout}` - Login timeout in ms (default: 5000)

**Extractors**:
- `accessToken` — From response: `$.token` or `$.data.accessToken`
- `tokenType` — Token type (Bearer, Basic, JWT)
- `expiresIn` — Token expiration in seconds

**Output Variables**:
- `${accessToken}` — Bearer token for subsequent requests
- `${userId}` — Extracted user ID
- `${sessionId}` — Session identifier

**JMX Structure**:
```xml
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy">
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
  <stringProp name="HTTPSampler.domain">${host-security}</stringProp>
  <stringProp name="HTTPSampler.path">${base-path}/auth/login</stringProp>
  <stringProp name="HTTPSampler.method">POST</stringProp>
  <stringProp name="HTTPSampler.connect_timeout">5000</stringProp>
  <stringProp name="HTTPSampler.response_timeout">5000</stringProp>
</HTTPSamplerProxy>
```

---

### 2. UPL (User Profile Lookup)

**Module ID**: `UPL-v2.0`  
**Purpose**: Retrieve user profile information  
**API Pattern**: `GET /api/v1/users/{userId}/profile`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-core}` - Core API host
- `${userId}` - User identifier
- `${accessToken}` - Bearer token from LOGIN

**Extractors**:
- `userRole` — From response: `$.role`
- `folderKey` — From response: `$.folderKey`
- `quotaUsed` — From response: `$.storage.quotaUsed`

**Output Variables**:
- `${userRole}` — Role of authenticated user
- `${folderKey}` — Primary folder identifier
- `${quotaUsed}` — Current quota usage

**Assertion Rules**:
- HTTP Status Code: 200
- Response time < 500ms
- Response contains `$.id` field

---

### 3. CUPL (Collaborative User Profile Lookup)

**Module ID**: `CUPL-v2.0`  
**Purpose**: Retrieve collaborator profile data with access control  
**API Pattern**: `GET /api/v1/users/{collaboratorId}/profile/shared`  
**Dependencies**: LOGIN, UPL

**Parameters**:
- `${host-core}` - Core API host
- `${collaboratorId}` - Collaborator user ID
- `${accessToken}` - Bearer token

**Extractors**:
- `collaboratorRole` — From response: `$.role`
- `sharedFolders` — Count from response: `$.folders | length`

**Output Variables**:
- `${collaboratorRole}` — Role of collaborator
- `${sharedFolderCount}` — Number of shared folders

---

### 4. NMSI (New Message Store Initialize)

**Module ID**: `NMSI-v2.0`  
**Purpose**: Initialize message store and create session  
**API Pattern**: `POST /api/v1/messaging/store/init`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-messaging}` - Messaging service host
- `${storeType}` - Store type (cache|database)

**Extractors**:
- `storeId` — From response: `$.storeId`
- `sessionToken` — From response: `$.sessionToken`

**Output Variables**:
- `${storeId}` — Message store identifier
- `${sessionToken}` — Session token for messaging

---

### 5. NMSD (New Message Store Destroy)

**Module ID**: `NMSD-v2.0`  
**Purpose**: Clean up message store and close session  
**API Pattern**: `DELETE /api/v1/messaging/store/{storeId}`  
**Dependencies**: NMSI

**Parameters**:
- `${host-messaging}` - Messaging service host
- `${storeId}` - Store ID from NMSI

**Assertion Rules**:
- HTTP Status Code: 204 or 200
- Response time < 200ms

---

### 6. DWN (Document Download)

**Module ID**: `DWN-v2.0`  
**Purpose**: Download document with bandwidth simulation  
**API Pattern**: `GET /api/v1/documents/{documentId}/download`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-storage}` - Storage service host
- `${documentId}` - Document identifier
- `${downloadTimeout}` - Timeout for large files (default: 30000)

**Extractors**:
- `downloadSize` — From response headers: `Content-Length`
- `mimeType` — From response headers: `Content-Type`

**Output Variables**:
- `${downloadSize}` — Size of downloaded content
- `${downloadTime}` — Time taken for download

**Assertion Rules**:
- HTTP Status Code: 200
- Response headers contain `Content-Type`

---

### 7. RETOKEN (Token Refresh)

**Module ID**: `RETOKEN-v2.0`  
**Purpose**: Refresh access token before expiration  
**API Pattern**: `POST /api/v1/auth/refresh`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-security}` - Auth service host
- `${refreshToken}` - Refresh token from LOGIN

**Extractors**:
- `newAccessToken` — From response: `$.accessToken`
- `newExpiresIn` — From response: `$.expiresIn`

**Output Variables**:
- `${accessToken}` — New access token (overwrites old)
- `${tokenRefreshedAt}` — Timestamp of refresh

**Assertion Rules**:
- HTTP Status Code: 200
- Response contains `$.accessToken`

---

### 8. SEARCH (Full-Text Search)

**Module ID**: `SEARCH-v2.0`  
**Purpose**: Execute full-text search with pagination  
**API Pattern**: `GET /api/v1/search?q={query}&page={page}&limit={limit}`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-core}` - Core API host
- `${searchQuery}` - Search query string
- `${pageSize}` - Results per page (default: 20)

**Extractors**:
- `totalResults` — From response: `$.pagination.total`
- `nextPage` — From response: `$.pagination.nextPage`

**Output Variables**:
- `${totalResults}` — Total matching results
- `${currentPage}` — Current page number

---

### 9. UPLOAD (File Upload)

**Module ID**: `UPLOAD-v2.0`  
**Purpose**: Upload file with progress tracking  
**API Pattern**: `POST /api/v1/upload` (multipart/form-data)  
**Dependencies**: LOGIN

**Parameters**:
- `${host-storage}` - Storage service host
- `${uploadFile}` - Path to file to upload
- `${targetFolder}` - Destination folder ID

**Extractors**:
- `fileId` — From response: `$.fileId`
- `uploadedSize` — From response: `$.size`

**Output Variables**:
- `${uploadedFileId}` — ID of uploaded file
- `${uploadTime}` — Time taken for upload

---

### 10. DELETE (Resource Deletion)

**Module ID**: `DELETE-v2.0`  
**Purpose**: Delete resource with cascading cleanup  
**API Pattern**: `DELETE /api/v1/resources/{resourceId}`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-core}` - Core API host
- `${resourceId}` - Resource to delete
- `${cascadeDelete}` - Include related resources (true|false)

**Assertion Rules**:
- HTTP Status Code: 204 or 200
- Response time < 300ms

---

### 11. PERMISSION (Permission Check)

**Module ID**: `PERMISSION-v2.0`  
**Purpose**: Verify user permissions for resource  
**API Pattern**: `POST /api/v1/permissions/check`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-security}` - Auth service host
- `${resourceId}` - Resource to check
- `${requiredPermission}` - Permission level (read|write|admin)

**Extractors**:
- `hasPermission` — From response: `$.allowed`

**Output Variables**:
- `${hasPermission}` — Boolean: true|false

---

### 12. BATCH (Batch Operation)

**Module ID**: `BATCH-v2.0`  
**Purpose**: Execute batch operations on multiple resources  
**API Pattern**: `POST /api/v1/batch`  
**Dependencies**: LOGIN

**Parameters**:
- `${host-core}` - Core API host
- `${batchSize}` - Number of operations (default: 10)

**Extractors**:
- `successCount` — From response: `$.results | map(select(.status==200)) | length`
- `failureCount` — From response: `$.results | map(select(.status!=200)) | length`

**Output Variables**:
- `${batchSuccessCount}` — Number of successful operations
- `${batchFailureCount}` — Number of failed operations

---

## Known API Host Variables

| Variable | Purpose | Example Value | Environment |
|----------|---------|---------------|-------------|
| `${host-security}` | Authentication service host | `auth-prod.example.com:8443` | prod |
| `${host-core}` | Core API service host | `api-prod.example.com:443` | prod |
| `${host-storage}` | File storage service host | `storage-prod.example.com:443` | prod |
| `${host-messaging}` | Messaging service host | `msg-prod.example.com:443` | prod |
| `${host-analytics}` | Analytics service host | `analytics-prod.example.com:443` | prod |
| `${host-notification}` | Notification service host | `notify-prod.example.com:443` | prod |

---

## Reference JMX Files

| JMX File | Purpose | Modules Used | Notes |
|----------|---------|--------------|-------|
| `template-login.jmx` | Basic authentication flow | LOGIN, RETOKEN | Entry point for all tests |
| `template-read-ops.jmx` | Read-heavy scenario | LOGIN, UPL, SEARCH, DWN | 80/20 read/write ratio |
| `template-write-ops.jmx` | Write-heavy scenario | LOGIN, UPLOAD, PERMISSION | POST/PUT dominant |
| `template-user-flow.jmx` | Complete user journey | LOGIN, UPL, SEARCH, UPLOAD, DELETE | Full lifecycle |
| `template-messaging.jmx` | Messaging workflow | LOGIN, NMSI, NMSD | Message queue test |
| `template-batch.jmx` | Batch operations | LOGIN, BATCH, DELETE | Bulk operations |

---

## New Module Guardrail Rules

### Creation Guidelines

1. **Module Naming**
   - All caps: `LOGIN`, `UPL`, `SEARCH`
   - Short form: 5-6 characters max
   - Avoid collisions: Check registry before creation

2. **Dependency Rules**
   - Every non-entry module must list dependencies
   - Circular dependencies prohibited
   - Maximum dependency depth: 4 levels

3. **Parameter Naming Convention**
   ```
   ${host-<service>}     — For host variables
   ${<module>-<param>}   — For module-specific params
   ${__P(param,default)} — For JMeter property params
   ```

4. **Extractor Rules**
   - Use JSON Path for JSON APIs: `$.field.subfield`
   - Use XPath for XML APIs: `//element/@attribute`
   - Name extractors after output variables

5. **Variable Naming Convention**
   ```
   ${accessToken}        — Auth credentials
   ${userId}             — User identifiers
   ${resourceId}         — Resource identifiers
   ${timestamp}          — Time-based values
   ${responseTime}       — Metrics
   ```

6. **Assertion Requirements**
   - Minimum: HTTP status code check
   - Recommended: Response time assertion
   - For critical paths: Response content assertion

### Review Checklist

- [ ] Module name is unique in registry
- [ ] All dependencies listed and validated
- [ ] Parameters follow naming convention
- [ ] Extractors defined for reused values
- [ ] Assertions include status code + timeout
- [ ] JMX structure is valid XML
- [ ] Documentation includes examples
- [ ] Module tested in isolation first

---

## JMX Reuse Rules

### When to Create vs. Reuse

**REUSE if**:
- Same API endpoint (even with different parameters)
- Same authentication mechanism
- Same business operation (login, search, etc.)

**CREATE if**:
- Different API endpoint
- Different response format
- Different assertion requirements
- Significantly different load characteristics

### Module Assembly Pattern

```xml
<!-- Example: Combine LOGIN + UPL modules -->
<hashTree>
  <!-- LOGIN Module (inline) -->
  <HTTPSamplerProxy guiclass="..." testclass="HTTPSamplerProxy">
    <!-- login request -->
  </HTTPSamplerProxy>
  <hashTree>
    <JSONPostProcessor guiclass="..." testclass="JSONPostProcessor">
      <!-- Extract accessToken -->
    </JSONPostProcessor>
  </hashTree>
  
  <!-- UPL Module (inline, depends on LOGIN output) -->
  <HTTPSamplerProxy guiclass="..." testclass="HTTPSamplerProxy">
    <!-- user profile request using ${accessToken} -->
  </HTTPSamplerProxy>
  <hashTree>
    <JSONPostProcessor guiclass="..." testclass="JSONPostProcessor">
      <!-- Extract userRole, folderKey -->
    </JSONPostProcessor>
  </hashTree>
</hashTree>
```

### Parameterization Example

```bash
# Run login module with custom host
jmeter -Jhost-security=custom-auth.example.com \
       -Jbase-path=/api/v2 \
       -n -t login-test.jmx
```

---

## Module Versioning

Each module maintains backward compatibility within major version:
- `LOGIN-v2.0` — Current stable version
- `LOGIN-v1.9` — Previous version (deprecated)
- `LOGIN-v3.0` (future) — Will contain breaking changes

**Migration Guide**: When upgrading to new module versions, test in non-prod first.

---

## Integration with PTLC

Modules are discovered and assembled during:
- **G2 (Planning)**: perf-architect selects modules for test plan
- **G4 (Script)**: perf-builder assembles modules into JMX
- **G5 (Data)**: CSV data prepared per module specifications

---

**Last Updated**: 2026-04-11  
**Owner**: Performance Architecture Team  
**Next Review**: 2026-05-11
