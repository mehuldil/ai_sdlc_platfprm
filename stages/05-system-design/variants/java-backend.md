---
name: Java Backend Design Variant
description: System design specifics for Java/TEJ microservices
stack: java-backend
---

# Java Backend Design Variant

## Architecture Considerations

### API Design
- OpenAPI 3.1 specification required
- Use RESTful conventions (GET, POST, PUT, DELETE)
- Version APIs: /api/v1/... with deprecation path
- Request/response use JSON; validate with schema

### Database Design
- PostgreSQL schema required
- Migration scripts: liquibase or flyway format
- Naming: lowercase with underscores (user_profiles, not UserProfiles)
- Primary keys: id (bigserial), timestamps: created_at, updated_at
- Foreign keys: explicit constraints with CASCADE rules

### Message Queue Design (Kafka)
- Topic naming: domain.event.version (user.created.v1)
- Schema: Avro with version control
- Producer: singleton pattern (use Spring Bean)
- Consumer: topic per consumer group (partition handling)
- Retention: 7 days default (adjust per domain)

### Exception Handling
- TEJ Exception Hierarchy:
  - TechErrorBase (root)
  - ValidationException (invalid input)
  - ResourceNotFoundException (404 equivalent)
  - ConflictException (business logic conflict)
  - ServiceUnavailableException (external service down)
- All exceptions include: code, message, context

### Deployment & Config
- Spring Boot configuration per environment: application-{env}.properties
- Use ConfigServer for dynamic properties
- Graceful shutdown: ContextClosedEvent listener
- Health checks: /actuator/health endpoint
- Metrics: Micrometer + Prometheus format

## Tech Decision Template
- Framework: Spring Boot 3.x (or TEJ equivalent)
- Database: PostgreSQL 15+
- Message Broker: Kafka (or alternative)
- Serialization: Gson (not Jackson for consistency)
- Build: Gradle 8.x
- Testing: JUnit 5 + Mockito

## Risk Mitigations
- SPOF: Kafka broker clustering, DB replication
- Data consistency: 2PC or event sourcing pattern
- Security: OAuth2 + JWT, SQL parameterization, secret rotation
