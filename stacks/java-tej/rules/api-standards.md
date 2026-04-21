# REST API Standards (Java TEJ)

## OpenAPI Specification
- **Version**: OpenAPI 3.1
- **Location**: `src/main/resources/openapi.yaml`
- **Validation**: Must pass OpenAPI Lint; gate G4 checks this

## URL Versioning
```
/api/v1/users         (v1 endpoints)
/api/v2/users         (v2 endpoints)
```

## Error Response Format
All errors must follow standard format:

```json
{
  "error": {
    "code": 400,
    "message": "Invalid request",
    "type": "VALIDATION_ERROR",
    "timestamp": "2026-04-10T14:22:15Z",
    "traceId": "abc-123-def"
  }
}
```

## Pagination
Query parameters:
- `pageSize` — Items per page (default: 20, max: 100)
- `pageNumber` — Zero-indexed
- Response includes:
  ```json
  {
    "data": [...],
    "pagination": {
      "pageNumber": 0,
      "pageSize": 20,
      "totalPages": 5,
      "totalItems": 100
    }
  }
  ```

## Rate Limiting
- Header: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Default: 1000 requests per hour per API key
- Exceeded: Return 429 Too Many Requests

## Status Codes
- `200` — Success
- `201` — Created
- `204` — No Content
- `400` — Bad Request
- `401` — Unauthorized
- `403` — Forbidden
- `404` — Not Found
- `409` — Conflict
- `422` — Unprocessable Entity
- `500` — Internal Server Error

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
