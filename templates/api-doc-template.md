# API Documentation

**API Version**: 1.0  
**Last Updated**: [YYYY-MM-DD]  
**Status**: Draft | **Published** | Deprecated  
**Audience**: Backend developers, mobile developers, third-party integrators  

> **SDLC alignment:** API contracts must match **approved design** and **Tech Story** / module contracts. User-visible strings belong in **PRD** and story **📎** sections per [`AUTHORING_STANDARDS.md`](AUTHORING_STANDARDS.md).

---

## §1 Overview

Purpose and scope of this API:

- **Service**: User Profile Service
- **Primary Purpose**: Manage user profile data, preferences, and settings
- **Capabilities**:
  - Retrieve user profile information
  - Update user profile data (bio, avatar, contact info)
  - Manage user preferences (notifications, privacy, language)
  - Upload and manage user avatars
  
**Key Features**:
- RESTful API with JSON request/response bodies
- OAuth 2.0 authentication with JWT tokens
- Role-based access control (RBAC)
- Versioned endpoints (v1, v2 planned)
- Pagination support for list endpoints

---

## §2 Base URL

Where to reach the API:

- **Production**: `https://api.example.com/v1`
- **Staging**: `https://staging-api.example.com/v1`
- **Local Development**: `http://localhost:8080/v1`

**Protocol**: HTTPS (TLS 1.3)  
**Rate Limit**: 1000 requests per minute per API key

---

## §3 Authentication

How to authenticate requests:

### OAuth 2.0 with JWT Tokens

All requests require an `Authorization` header with a Bearer token:

```
Authorization: Bearer <jwt_token>
```

**Token Acquisition**:
```bash
curl -X POST https://auth.example.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET"
  }'
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "read:profile write:profile"
}
```

**Token Validity**: 1 hour (3600 seconds)  
**Refresh Token**: Available via refresh grant (valid for 30 days)

### Authentication Errors

```
Status: 401 Unauthorized
Authorization header missing or malformed

Status: 403 Forbidden
Insufficient permissions for this resource
```

---

## §4 Endpoints

Available API endpoints and operations:

### Get User Profile

Retrieve a user's profile information.

**Endpoint**: `GET /users/{userId}`

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | Yes | User ID (UUID format: `550e8400-e29b-41d4-a716-446655440000`) |

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| include | string | - | Include related data: `preferences`, `avatar`, `profile_history` (comma-separated) |
| fields | string | all | Return only specified fields (comma-separated) |

**Request**:
```bash
curl -X GET "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000?include=preferences,avatar" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Response (Success - 200 OK)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "bio": "Software engineer from San Francisco",
  "avatar": {
    "url": "https://cdn.example.com/avatars/550e8400.jpg",
    "uploadedAt": "2024-01-15T10:30:00Z",
    "size": "2048 bytes"
  },
  "createdAt": "2023-01-01T00:00:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "preferences": {
    "notificationsEnabled": true,
    "emailFrequency": "weekly",
    "language": "en-US",
    "privacyLevel": "friends_only"
  }
}
```

**Response (Not Found - 404)**:
```json
{
  "error": "USER_NOT_FOUND",
  "message": "User with ID 550e8400-e29b-41d4-a716-446655440000 does not exist",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

### Update User Profile

Update a user's profile information.

**Endpoint**: `PUT /users/{userId}`

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | Yes | User ID (must match authenticated user or be admin) |

**Request Body**:
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "bio": "Updated bio text (max 500 chars)",
  "phone": "+1-555-0123",
  "location": "San Francisco, CA"
}
```

**Validation Rules**:
- `firstName`: 1-50 characters, alphanumeric + spaces
- `lastName`: 1-50 characters, alphanumeric + spaces
- `bio`: 0-500 characters, no HTML/scripts allowed
- `phone`: Valid E.164 format (e.g., +1-555-0123)
- `location`: 0-100 characters

**Request**:
```bash
curl -X PUT "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "bio": "Senior engineer passionate about clean code"
  }'
```

**Response (Success - 200 OK)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "firstName": "John",
  "lastName": "Doe",
  "bio": "Senior engineer passionate about clean code",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

**Response (Validation Error - 400)**:
```json
{
  "error": "VALIDATION_FAILED",
  "message": "One or more fields are invalid",
  "details": [
    {
      "field": "bio",
      "value": "<script>alert('xss')</script>",
      "reason": "HTML/scripts not allowed"
    }
  ],
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

### Upload User Avatar

Upload or update a user's profile avatar image.

**Endpoint**: `POST /users/{userId}/avatar`

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | Yes | User ID |

**Request Format**: Multipart form data

**Form Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | file | Yes | Image file (PNG, JPG, GIF; max 5MB) |
| alt_text | string | No | Alt text for accessibility (max 200 chars) |

**Supported MIME Types**: `image/jpeg`, `image/png`, `image/gif`  
**Maximum File Size**: 5 MB  
**Image Dimensions**: 100x100px to 2000x2000px

**Request**:
```bash
curl -X POST "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000/avatar" \
  -H "Authorization: Bearer <token>" \
  -F "file=@avatar.jpg" \
  -F "alt_text=Profile photo"
```

**Response (Success - 201 Created)**:
```json
{
  "url": "https://cdn.example.com/avatars/550e8400-avatar-v2.jpg",
  "uploadedAt": "2024-01-15T10:30:00Z",
  "size": "2048 bytes",
  "dimensions": {
    "width": 500,
    "height": 500
  }
}
```

**Response (File Too Large - 413)**:
```json
{
  "error": "FILE_TOO_LARGE",
  "message": "File size (6.5MB) exceeds maximum allowed (5MB)",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

### Get User Preferences

Retrieve user preference settings.

**Endpoint**: `GET /users/{userId}/preferences`

**Request**:
```bash
curl -X GET "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000/preferences" \
  -H "Authorization: Bearer <token>"
```

**Response (Success - 200 OK)**:
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "notifications": {
    "enabled": true,
    "emailFrequency": "weekly",
    "pushNotifications": true,
    "smsNotifications": false,
    "categories": {
      "newFollowers": true,
      "comments": true,
      "likes": false
    }
  },
  "privacy": {
    "profileVisibility": "public",
    "showEmail": false,
    "allowMessages": "friends_only"
  },
  "display": {
    "theme": "light",
    "language": "en-US",
    "dateFormat": "MM/DD/YYYY"
  },
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

---

### Update User Preferences

Update user preference settings.

**Endpoint**: `PUT /users/{userId}/preferences`

**Request Body**:
```json
{
  "notifications": {
    "emailFrequency": "daily",
    "pushNotifications": false
  },
  "privacy": {
    "profileVisibility": "friends_only"
  },
  "display": {
    "theme": "dark",
    "language": "es-ES"
  }
}
```

**Request**:
```bash
curl -X PUT "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000/preferences" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "notifications": {"emailFrequency": "daily"},
    "display": {"theme": "dark"}
  }'
```

**Response (Success - 200 OK)**:
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "notifications": {
    "emailFrequency": "daily",
    "pushNotifications": true
  },
  "privacy": {
    "profileVisibility": "public"
  },
  "display": {
    "theme": "dark",
    "language": "en-US"
  },
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

---

## §5 Request/Response Schemas

Common data structures used in the API:

### User Profile Object

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "firstName": "string (1-50 chars)",
  "lastName": "string (1-50 chars)",
  "bio": "string (0-500 chars, no HTML)",
  "phone": "string (E.164 format)",
  "location": "string (0-100 chars)",
  "avatar": {
    "url": "string (HTTPS URL to CDN)",
    "uploadedAt": "string (ISO 8601 timestamp)",
    "size": "integer (bytes)"
  },
  "createdAt": "string (ISO 8601 timestamp)",
  "updatedAt": "string (ISO 8601 timestamp)"
}
```

### Error Response Object

```json
{
  "error": "string (error code: USER_NOT_FOUND, VALIDATION_FAILED, etc.)",
  "message": "string (human-readable error message)",
  "details": [
    {
      "field": "string (field name, if applicable)",
      "value": "any (the invalid value)",
      "reason": "string (why it's invalid)"
    }
  ],
  "timestamp": "string (ISO 8601 timestamp)",
  "requestId": "string (unique request ID for debugging)"
}
```

---

## §6 Error Codes

Standard error codes and their meanings:

| Status | Error Code | Message | Cause |
|--------|-----------|---------|-------|
| 400 | INVALID_REQUEST | Invalid request format | Malformed JSON, missing required fields |
| 400 | VALIDATION_FAILED | One or more fields are invalid | Field validation error (see details) |
| 400 | INVALID_PHONE_FORMAT | Phone number must be E.164 format | Invalid phone format |
| 401 | UNAUTHORIZED | Missing or invalid authentication | Missing token, expired token, invalid token |
| 403 | FORBIDDEN | You do not have permission to access this resource | Insufficient permissions (not admin, not owner) |
| 404 | USER_NOT_FOUND | User does not exist | UserId not found in database |
| 409 | DUPLICATE_EMAIL | Email already in use | Email conflicts with existing user |
| 413 | FILE_TOO_LARGE | File size exceeds maximum allowed | Avatar file > 5MB |
| 415 | UNSUPPORTED_MEDIA_TYPE | File type not supported | Avatar not PNG/JPG/GIF |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests | Exceeded 1000 req/min rate limit |
| 500 | INTERNAL_SERVER_ERROR | An error occurred processing your request | Server-side error (unrelated to input) |
| 503 | SERVICE_UNAVAILABLE | Service temporarily unavailable | Maintenance window, database down |

---

## §7 Rate Limits

API request throttling and quota:

**Request Limits**:
- **Default**: 1000 requests per minute per API key
- **Premium**: 10,000 requests per minute per API key

**Rate Limit Headers** (included in all responses):
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1705325400
```

**Exceeded Limit Response** (Status 429):
```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Rate limit of 1000 requests per minute exceeded",
  "retryAfter": 60,
  "resetTime": "2024-01-15T10:31:40Z"
}
```

**Recommended Retry Strategy**:
- Exponential backoff: wait 2^n seconds between retries
- Maximum wait time: 300 seconds
- Total retry attempts: 5

---

## §8 Pagination

How to paginate through large result sets:

**Pagination Parameters**:
| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| page | integer | 1 | - | Page number (1-indexed) |
| pageSize | integer | 20 | 100 | Items per page |
| sort | string | `createdAt:desc` | - | Sort field and direction |

**Request**:
```bash
curl -X GET "https://api.example.com/v1/users?page=2&pageSize=50&sort=firstName:asc" \
  -H "Authorization: Bearer <token>"
```

**Response**:
```json
{
  "data": [
    { "id": "...", "firstName": "...", "lastName": "..." },
    ...
  ],
  "pagination": {
    "page": 2,
    "pageSize": 50,
    "totalItems": 250,
    "totalPages": 5,
    "hasNextPage": true,
    "hasPreviousPage": true
  }
}
```

---

## §9 Deprecations

API features being phased out:

### Deprecated Endpoints

| Endpoint | Deprecated | Removal | Alternative |
|----------|-----------|---------|-------------|
| `GET /v1/user` | 2024-01-01 | 2024-07-01 | `GET /v1/users/{userId}` |
| `POST /v1/user/profile` | 2024-01-01 | 2024-07-01 | `PUT /v1/users/{userId}` |

### Migration Guide

Old:
```bash
curl -X GET "https://api.example.com/v1/user" \
  -H "Authorization: Bearer <token>"
```

New:
```bash
curl -X GET "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer <token>"
```

**Support Period**: Deprecated endpoints will continue to work until removal date (6 months notice provided).

---

## §10 Changelog

Version history and updates:

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01-15 | Initial release: GET/PUT user profile, avatar upload, preferences management |
| 1.1 (planned) | 2024-Q2 | GraphQL endpoint addition, batch operations |
| 2.0 (planned) | 2024-Q4 | Breaking changes: simplified response format, new auth flow |

---

## SDK & Code Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

const client = axios.create({
  baseURL: 'https://api.example.com/v1',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  }
});

// Get user profile
const profile = await client.get('/users/550e8400-e29b-41d4-a716-446655440000');
console.log(profile.data);

// Update profile
await client.put('/users/550e8400-e29b-41d4-a716-446655440000', {
  firstName: 'John',
  bio: 'Updated bio'
});
```

### Python

```python
import requests

headers = {'Authorization': f'Bearer {access_token}'}
base_url = 'https://api.example.com/v1'

# Get user profile
response = requests.get(
  f'{base_url}/users/550e8400-e29b-41d4-a716-446655440000',
  headers=headers
)
profile = response.json()

# Update profile
response = requests.put(
  f'{base_url}/users/550e8400-e29b-41d4-a716-446655440000',
  headers=headers,
  json={'firstName': 'John', 'bio': 'Updated bio'}
)
```

---

## Support & Contact

For questions or issues:

- **Documentation**: https://docs.example.com
- **Status Page**: https://status.example.com
- **Support Email**: api-support@example.com
- **Slack Community**: #api-developers

---

**Status**: Published ✓  
**Last Updated**: [date]
