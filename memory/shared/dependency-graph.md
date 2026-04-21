# Cross-Module Dependency Map

**Last Updated**: [date]  
**Maintained By**: Architecture Team  

---

## Overview
Real-time dependency graph showing how services and modules communicate. Updated weekly.

---

## Service A (Backend)
- **Owner**: Backend Team
- **Repo**: github.com/jiocloud/service-a
- **Status**: EXISTING

### Outbound Dependencies
```
Service A → Service B (REST/HTTP)
  Protocol: HTTPS
  Endpoint: /api/v1/users
  Contract: OpenAPI 3.1 (AB#15001)
  Version: v1.2
  Timeout: 5000ms
  Retry: 3x exponential backoff

Service A → Message Queue (Kafka)
  Protocol: Kafka
  Topic: user-events
  Format: JSON (Avro schema v2)
  Acks: all
  Retention: 7 days
```

### Inbound Dependencies
```
Frontend → Service A
  Protocol: REST/HTTPS
  Endpoints: GET /users, POST /users
  Auth: Bearer token (JWT)
```

---

## Service B (Backend)
- **Owner**: Backend Team
- **Repo**: github.com/jiocloud/service-b
- **Status**: EXISTING

### Outbound Dependencies
```
Service B → Database (PostgreSQL)
  Protocol: JDBC
  Queries: Parameterized (no SQL injection)
  Connection Pool: HikariCP (10 connections)
  Read Replica: Available (eventual consistency ok)

Service B → Cache (Redis)
  Protocol: TCP
  Key Format: user:{id}
  TTL: 3600 seconds
  Serialization: JSON
```

### Inbound Dependencies
```
Service A → Service B
  [See Service A section]
```

---

## Frontend (React Web)
- **Owner**: Frontend Team
- **Repo**: github.com/jiocloud/web-frontend
- **Status**: EXISTING

### Outbound Dependencies
```
Frontend → API Gateway
  Protocol: REST/HTTPS
  Base URL: https://api.jiocloud.io
  Auth: Bearer JWT
  Timeout: 30000ms

Frontend → Design System (Figma)
  Protocol: HTTP (design reference)
  Link: https://figma.com/file/...
  Updates: Synced manually weekly
```

---

## Mobile App (React Native)
- **Owner**: Mobile Team
- **Repo**: github.com/jiocloud/mobile-app
- **Status**: EXISTING

### Outbound Dependencies
```
Mobile → API Gateway
  Protocol: REST/HTTPS
  Endpoints: Same as Frontend
  Auth: Bearer JWT + Device ID
  Offline Mode: LocalStorage fallback

Mobile → Native Bridge (iOS/Android)
  Protocol: Native module calls
  Modules: Camera, Contacts, Notifications
```

---

## New Service C (TBD)
- **Owner**: TBD
- **Repo**: github.com/jiocloud/service-c
- **Status**: NEW (Planned Sprint 25)

### Planned Outbound Dependencies
```
Service C → Service A
  Protocol: gRPC (planned)
  Contract: [TBD - ADR pending]
  Latency Target: <100ms (p95)

Service C → Message Queue
  Protocol: Kafka
  Topic: transactions
  Format: Protobuf (schema v1)
```

---

## Message Queue (Kafka)
- **Provider**: AWS MSK (Managed Streaming for Kafka)
- **Brokers**: 3-node cluster
- **Replication Factor**: 3

### Topics
```
Topic: user-events
  Partitions: 12
  Retention: 7 days
  Format: JSON
  Consumers: Analytics Service, Notification Service

Topic: transactions
  Partitions: 6
  Retention: 30 days
  Format: Protobuf
  Consumers: Audit Service, Analytics Service
```

---

## Database (PostgreSQL)
- **Provider**: AWS RDS
- **Version**: 14.x
- **Replicas**: Read-only in us-west-2 (eventual consistency)

### Schemas
```
Schema: users
  Tables: users, user_profiles, user_settings

Schema: transactions
  Tables: transactions, transaction_details, audit_log
```

---

## Cache (Redis)
- **Provider**: AWS ElastiCache
- **Version**: 7.x
- **Cluster Mode**: Enabled
- **Eviction Policy**: allkeys-lru

### Key Patterns
```
user:{id}              → User session data (TTL: 3600s)
profile:{id}           → User profile cache (TTL: 1800s)
search-results:{hash}  → Search results (TTL: 300s)
```

---

## Critical Path
**Longest dependency chain** (highest risk if blocked):

```
Frontend
  ↓
API Gateway (LB + Auth)
  ↓
Service A (Business Logic)
  ↓
Service B (Data Access)
  ↓
Database (PostgreSQL)
```

**Latency Budget**: Frontend request → DB query → response back = <1000ms (p95)

---

## Notes
- All services must implement circuit breaker pattern (Hystrix)
- All database queries must be parameterized
- All async communication must be idempotent
- Weekly sync call to review dependency changes

---

**Next Review**: [date + 1 week]
