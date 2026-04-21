# API Registry for Performance Testing

**Version**: 2.0.0  
**Last Updated**: 2026-04-11  
**Purpose**: Catalog of known APIs with request/response specs, extractors, and CSV formats  
**Audience**: perf-builder agents, JMeter script developers

---

## Overview

The API Registry is a reference guide containing specifications for all known service APIs. Each entry includes:
- Endpoint URL pattern
- HTTP method and authentication
- Request payload (if applicable)
- Response payload (sample)
- JSON Path extractors for key fields
- CSV column format for test data

---

## Service 1: Authentication Service (Auth API)

**Service Host**: `${host-security}`  
**Base Path**: `/api/v1/auth`  
**Protocol**: HTTPS (port 443)  
**Auth**: None (login endpoint), Bearer token (others)

### 1.1 Login Endpoint

**Endpoint**: `POST /api/v1/auth/login`  
**Purpose**: Authenticate user and obtain access token  
**Rate Limit**: 10 requests/second  
**Timeout**: 5000ms

**Request Headers**:
```
Content-Type: application/json
Accept: application/json
```

**Request Payload** (JSON):
```json
{
  "emailId": "user001@test.com",
  "password": "Test@123"
}
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "userId": "user001",
    "email": "user001@test.com",
    "role": "user"
  }
}
```

**Response Payload** (HTTP 401 — Invalid credentials):
```json
{
  "status": "error",
  "code": "INVALID_CREDENTIALS",
  "message": "Email or password is incorrect"
}
```

**Extractors** (JSON Path):
```
$.data.accessToken        → accessToken
$.data.tokenType          → tokenType
$.data.expiresIn          → expiresIn
$.data.userId             → userId
$.data.role               → userRole
```

**Assertions**:
- HTTP Status Code: 200
- Response contains `$.data.accessToken`
- Response time < 5000ms
- Body contains `success` in `$.status`

**CSV Format** (users.csv):
```
userId,emailId,password
user001,user001@test.com,Test@123
user002,user002@test.com,Test@123
```

### 1.2 Token Refresh Endpoint

**Endpoint**: `POST /api/v1/auth/refresh`  
**Purpose**: Refresh access token before expiration  
**Dependency**: Must call LOGIN first to get `refreshToken`

**Request Payload**:
```json
{
  "refreshToken": "refresh_token_from_login_response"
}
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "accessToken": "new_access_token_here",
    "expiresIn": 3600
  }
}
```

**Extractors**:
```
$.data.accessToken  → newAccessToken (overwrite old token)
$.data.expiresIn    → newExpiresIn
```

---

## Service 2: Core API (User Profile & Folders)

**Service Host**: `${host-core}`  
**Base Path**: `/api/v1`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 2.1 Get User Profile

**Endpoint**: `GET /api/v1/users/{userId}/profile`  
**Purpose**: Retrieve authenticated user's profile information  
**Rate Limit**: 100 requests/second  
**Timeout**: 2000ms

**Request Headers**:
```
Authorization: Bearer ${accessToken}
Accept: application/json
```

**URL Variables**:
```
userId = ${userId}  (from login response)
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "id": "user001",
    "email": "user001@test.com",
    "role": "user",
    "firstName": "John",
    "lastName": "Doe",
    "rootFolderKey": "rf-001",
    "storage": {
      "quotaTotal": 1099511627776,
      "quotaUsed": 102400000,
      "quotaPercentage": 9.31
    },
    "createdAt": "2025-01-15T10:30:00Z",
    "lastLogin": "2026-04-10T14:25:00Z"
  }
}
```

**Extractors**:
```
$.data.id                    → userId
$.data.email                 → userEmail
$.data.role                  → userRole
$.data.rootFolderKey         → rootFolderKey
$.data.storage.quotaUsed     → quotaUsed
$.data.storage.quotaPercent  → storagePercent
```

**Assertions**:
- HTTP Status Code: 200
- Response contains `$.data.id`
- Response time < 2000ms
- `$.data.role` matches expected role

### 2.2 List User's Folders

**Endpoint**: `GET /api/v1/users/{userId}/folders?page={page}&limit={limit}`  
**Purpose**: List all folders owned by user  
**Rate Limit**: 100 requests/second  
**Timeout**: 3000ms

**Request Parameters**:
```
page=1           (default: 1)
limit=50         (default: 50, max: 100)
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "folderId": "folder-001",
        "name": "Projects",
        "createdAt": "2025-02-01T10:00:00Z",
        "itemCount": 45
      },
      {
        "folderId": "folder-002",
        "name": "Archive",
        "createdAt": "2025-03-15T14:30:00Z",
        "itemCount": 120
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 2,
      "totalPages": 1
    }
  }
}
```

**Extractors**:
```
$.data.items[0].folderId       → firstFolderId
$.data.items | length          → folderCount
$.data.pagination.total        → totalFolders
```

**CSV Format** (folders.csv):
```
folderId,page,limit
folder-001,1,50
folder-002,1,50
```

---

## Service 3: Search API

**Service Host**: `${host-core}`  
**Base Path**: `/api/v1/search`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 3.1 Full-Text Search

**Endpoint**: `GET /api/v1/search/documents?q={query}&page={page}&limit={limit}`  
**Purpose**: Search documents by keyword  
**Rate Limit**: 50 requests/second (higher rate requires whitelisting)  
**Timeout**: 5000ms

**Request Parameters**:
```
q=python tutorial      (search query, URL encoded)
page=1                 (default: 1)
limit=20               (default: 20, max: 100)
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "query": "python tutorial",
    "results": [
      {
        "documentId": "doc-001",
        "title": "Python Tutorial for Beginners",
        "snippet": "This tutorial covers the fundamentals of Python programming...",
        "relevance": 0.95,
        "createdAt": "2025-01-10T09:00:00Z"
      },
      {
        "documentId": "doc-002",
        "title": "Advanced Python Patterns",
        "snippet": "Deep dive into design patterns in Python...",
        "relevance": 0.87,
        "createdAt": "2025-02-20T11:15:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1250,
      "totalPages": 63
    },
    "executionTimeMs": 234
  }
}
```

**Response Payload** (HTTP 200 — No results):
```json
{
  "status": "success",
  "data": {
    "query": "nonexistent-query-xyz",
    "results": [],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "totalPages": 0
    },
    "executionTimeMs": 45
  }
}
```

**Extractors**:
```
$.data.results | length         → resultCount
$.data.pagination.total         → totalResults
$.data.pagination.totalPages    → totalPages
$.data.executionTimeMs          → searchTimeMs
$.data.results[0].documentId    → firstDocumentId
```

**Assertions**:
- HTTP Status Code: 200
- Response time < 5000ms
- If `$.data.pagination.total > 0`: results array is not empty
- All results have `$.relevance` between 0 and 1

**CSV Format** (search-queries.csv):
```
searchQuery,page,limit
python tutorial,1,20
machine learning,1,20
java spring framework,1,20
database optimization,1,50
```

---

## Service 4: File Storage API

**Service Host**: `${host-storage}`  
**Base Path**: `/api/v1`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 4.1 Upload File

**Endpoint**: `POST /api/v1/documents/upload`  
**Purpose**: Upload file to user's folder  
**Rate Limit**: 10 requests/second  
**Timeout**: 30000ms (supports large files)  
**Content-Type**: multipart/form-data

**Request Form Data**:
```
file: (binary file content)
parentFolderId: folder-001
fileName: report-q1.pdf
```

**Response Payload** (HTTP 201):
```json
{
  "status": "success",
  "data": {
    "documentId": "doc-new-001",
    "fileName": "report-q1.pdf",
    "fileSize": 2048000,
    "mimeType": "application/pdf",
    "uploadedAt": "2026-04-11T15:30:00Z",
    "parentFolderId": "folder-001",
    "storageKey": "s3://bucket/user001/doc-new-001"
  }
}
```

**Extractors**:
```
$.data.documentId    → uploadedDocumentId
$.data.fileSize      → uploadedFileSize
$.data.storageKey    → storageKey
```

**Assertions**:
- HTTP Status Code: 201
- Response contains `$.data.documentId`
- `$.data.fileSize` > 0
- Response time < 30000ms

**CSV Format** (upload-files.csv):
```
fileName,fileSize,mimeType,parentFolderId
report-q1.pdf,2048000,application/pdf,folder-001
presentation.pptx,5000000,application/vnd.presentationml,folder-001
spreadsheet.xlsx,512000,application/vnd.ms-excel,folder-002
document.docx,256000,application/vnd.openxmlformats-officedocument.wordprocessingml.document,folder-002
```

### 4.2 Download File

**Endpoint**: `GET /api/v1/documents/{documentId}/download`  
**Purpose**: Download file content  
**Rate Limit**: 20 requests/second  
**Timeout**: 30000ms

**URL Variables**:
```
documentId = ${documentId}
```

**Response Headers**:
```
Content-Type: application/pdf
Content-Length: 2048000
Content-Disposition: attachment; filename="report-q1.pdf"
```

**Response Body**: Binary file content (2MB in example)

**Extractors** (from headers):
```
${__javaScript(prev.getResponseHeaders().get('Content-Length'))}  → fileSize
${__javaScript(prev.getResponseHeaders().get('Content-Type'))}    → mimeType
```

**Assertions**:
- HTTP Status Code: 200
- Response has `Content-Length` header
- Response time < 30000ms
- Response body size matches `Content-Length`

---

## Service 5: Messaging API

**Service Host**: `${host-messaging}`  
**Base Path**: `/api/v1/messaging`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 5.1 Send Message

**Endpoint**: `POST /api/v1/messaging/messages/send`  
**Purpose**: Send message to another user  
**Rate Limit**: 30 requests/second  
**Timeout**: 3000ms

**Request Payload**:
```json
{
  "recipientId": "user002",
  "subject": "Project Update",
  "body": "Here's the latest project status...",
  "isHighPriority": false
}
```

**Response Payload** (HTTP 201):
```json
{
  "status": "success",
  "data": {
    "messageId": "msg-001",
    "recipientId": "user002",
    "subject": "Project Update",
    "sentAt": "2026-04-11T15:35:00Z",
    "deliveryStatus": "delivered"
  }
}
```

**Extractors**:
```
$.data.messageId        → messageId
$.data.deliveryStatus   → deliveryStatus
```

**Assertions**:
- HTTP Status Code: 201
- `$.data.deliveryStatus` = "delivered"

**CSV Format** (messages.csv):
```
recipientId,subject,body,isHighPriority
user002,Project Update,Here's the latest...,false
user003,Urgent Issue,There's a critical bug...,true
```

---

## Service 6: Permissions API

**Service Host**: `${host-security}`  
**Base Path**: `/api/v1/permissions`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 6.1 Check Permission

**Endpoint**: `POST /api/v1/permissions/check`  
**Purpose**: Verify if user has permission for resource  
**Rate Limit**: 100 requests/second  
**Timeout**: 1000ms

**Request Payload**:
```json
{
  "resourceId": "doc-001",
  "resourceType": "document",
  "requiredPermission": "read"
}
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "allowed": true,
    "resourceId": "doc-001",
    "permission": "read",
    "grantedAt": "2026-04-10T10:00:00Z"
  }
}
```

**Response Payload** (HTTP 200 — Permission denied):
```json
{
  "status": "success",
  "data": {
    "allowed": false,
    "resourceId": "doc-001",
    "permission": "write",
    "reason": "Only document owner can write"
  }
}
```

**Extractors**:
```
$.data.allowed      → hasPermission
$.data.permission   → grantedPermission
```

**CSV Format** (permissions.csv):
```
resourceId,requiredPermission
doc-001,read
doc-002,write
folder-001,admin
```

---

## Service 7: Analytics API

**Service Host**: `${host-analytics}`  
**Base Path**: `/api/v1/analytics`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 7.1 Get User Activity

**Endpoint**: `GET /api/v1/analytics/users/{userId}/activity?from={date}&to={date}`  
**Purpose**: Retrieve user's activity log  
**Rate Limit**: 30 requests/second  
**Timeout**: 5000ms

**URL Variables**:
```
userId = ${userId}
from = 2026-04-01
to = 2026-04-11
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "userId": "user001",
    "activities": [
      {
        "activityId": "act-001",
        "action": "document_viewed",
        "documentId": "doc-001",
        "timestamp": "2026-04-11T10:30:00Z"
      },
      {
        "activityId": "act-002",
        "action": "folder_created",
        "folderId": "folder-new-001",
        "timestamp": "2026-04-10T14:15:00Z"
      }
    ],
    "pagination": {
      "total": 250,
      "page": 1,
      "pageSize": 50
    }
  }
}
```

**Extractors**:
```
$.data.activities | length     → activityCount
$.data.pagination.total        → totalActivities
```

---

## Service 8: Notification API

**Service Host**: `${host-notification}`  
**Base Path**: `/api/v1/notifications`  
**Protocol**: HTTPS (port 443)  
**Auth**: Bearer token (required)

### 8.1 Get Unread Notifications

**Endpoint**: `GET /api/v1/notifications/unread?limit={limit}`  
**Purpose**: Retrieve unread notifications for user  
**Rate Limit**: 50 requests/second  
**Timeout**: 2000ms

**Request Parameters**:
```
limit=20  (default: 20, max: 100)
```

**Response Payload** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "unreadCount": 5,
    "notifications": [
      {
        "notificationId": "notif-001",
        "type": "message_received",
        "title": "New message from user002",
        "message": "User002 sent you a message",
        "createdAt": "2026-04-11T15:00:00Z",
        "isRead": false
      },
      {
        "notificationId": "notif-002",
        "type": "permission_granted",
        "title": "Document access granted",
        "message": "User003 shared doc-123 with you",
        "createdAt": "2026-04-11T14:30:00Z",
        "isRead": false
      }
    ]
  }
}
```

**Extractors**:
```
$.data.unreadCount     → unreadNotificationCount
$.data.notifications | length  → notificationCount
```

**Assertions**:
- HTTP Status Code: 200
- `$.data.unreadCount` >= 0
- All notifications have `isRead` field

---

## API Registry Summary Table

| Service | Endpoint | Method | Purpose | Rate Limit | Timeout |
|---------|----------|--------|---------|------------|---------|
| Auth | `/auth/login` | POST | User authentication | 10/sec | 5s |
| Auth | `/auth/refresh` | POST | Refresh token | 20/sec | 3s |
| Core | `/users/{id}/profile` | GET | Get user profile | 100/sec | 2s |
| Core | `/users/{id}/folders` | GET | List user folders | 100/sec | 3s |
| Search | `/search/documents` | GET | Full-text search | 50/sec | 5s |
| Storage | `/documents/upload` | POST | Upload file | 10/sec | 30s |
| Storage | `/documents/{id}/download` | GET | Download file | 20/sec | 30s |
| Messaging | `/messages/send` | POST | Send message | 30/sec | 3s |
| Permissions | `/permissions/check` | POST | Check permission | 100/sec | 1s |
| Analytics | `/analytics/users/{id}/activity` | GET | Get activity log | 30/sec | 5s |
| Notifications | `/notifications/unread` | GET | Get notifications | 50/sec | 2s |

---

## Common Response Codes

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 200 | OK | Success — process response |
| 201 | Created | Success — resource created |
| 204 | No Content | Success — no body in response |
| 400 | Bad Request | Error — check request payload |
| 401 | Unauthorized | Error — token expired or missing, call RETOKEN |
| 403 | Forbidden | Error — user lacks permission, check PERMISSION module |
| 404 | Not Found | Error — resource doesn't exist |
| 429 | Too Many Requests | Error — rate limit exceeded, back off for 60s |
| 500 | Server Error | Error — service is failing, retry with exponential backoff |
| 503 | Service Unavailable | Error — service is degraded, escalate to ops |

---

## Error Response Format

All services return errors in consistent format:

```json
{
  "status": "error",
  "code": "ERROR_CODE_HERE",
  "message": "Human-readable error description",
  "details": {
    "field": "fieldName",
    "reason": "Detailed reason for failure"
  }
}
```

**Common Error Codes**:
- `INVALID_CREDENTIALS` — Login failed (wrong password)
- `TOKEN_EXPIRED` — Auth token expired
- `PERMISSION_DENIED` — User lacks permission
- `RATE_LIMIT_EXCEEDED` — Too many requests
- `RESOURCE_NOT_FOUND` — 404 error
- `INVALID_REQUEST` — Malformed request body
- `SERVER_ERROR` — 5xx error

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- All monetary values are in cents (e.g., $10.00 = 1000)
- File uploads support up to 5GB per file
- API responses are gzipped if client sends `Accept-Encoding: gzip`
- Pagination uses 1-based page numbers (not 0-based)

---

**Last Updated**: 2026-04-11  
**Owner**: API Team  
**Next Review**: 2026-05-11
