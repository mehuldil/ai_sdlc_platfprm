# Backend Team Architecture

**Team**: Backend  
**Last Updated**: 2026-04-10  
**Maintained By**: Architecture Lead  

---

## Architecture Overview
Microservices architecture with event-driven communication. Services built in Java 17 using RestExpress (TEJ framework).

## Core Services

### auth-service
- Purpose: User authentication, token generation, session management
- Tech: Java 17, RestExpress, PostgreSQL, Redis
- Status: Production (v2.0)
- Owner: John Doe

### profile-service
- Purpose: User profile data management
- Tech: Java 17, RestExpress, PostgreSQL, Redis
- Status: Production (v1.5)
- Owner: Jane Smith

### notification-service
- Purpose: Send notifications (email, SMS, push)
- Tech: Java 17, RestExpress, Kafka, SendGrid, Twilio
- Status: Production (v1.0)
- Owner: Bob Johnson

### search-service
- Purpose: Elasticsearch-based search over user profiles
- Tech: Java 17, RestExpress, Elasticsearch, PostgreSQL
- Status: Production (v1.2)
- Owner: Alice Wong

---

## Communication Patterns

### Synchronous (REST/HTTP)
- Service-to-service calls: Circuit breaker (Hystrix)
- Timeout: 5000ms (adjustable per endpoint)
- Retry: 3x exponential backoff

### Asynchronous (Kafka)
- Event bus for cross-service communication
- Topics: user-events, transactions, audit-logs
- Dead Letter Queue for failed messages

---

## Database Strategy
- **Primary**: PostgreSQL (ACID compliance)
- **Cache**: Redis (user sessions, profile cache)
- **Search**: Elasticsearch (text search, aggregations)
- **Read Replicas**: Available in us-west-2 (eventual consistency)

---

## Deployment
- **Platform**: Kubernetes (AWS EKS)
- **Orchestration**: Helm charts
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack

---

**See Also**: service-registry.md, dependency-graph.md
