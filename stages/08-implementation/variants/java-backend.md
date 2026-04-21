---
name: Java Backend Implementation Variant
description: Implementation RPI rules and guardrails for Java/TEJ stack
stack: java-backend
---

# Java Backend Implementation Variant

## Tech Stack
- Language: Java 17+
- Framework: Spring Boot 3.x (TEJ/RestExpress alternative)
- Build: Gradle 8.x
- Database: PostgreSQL 15+
- Message Broker: Kafka
- Serialization: Gson (strict, no Jackson)
- Testing: JUnit 5 + Mockito
- HTTP Client: RestTemplate or WebClient

## RPI Rules

**Serialization:** [rpi-serialization-baseline.md](../../_includes/rpi-serialization-baseline.md) — phase locks for every stack. **Normative:** [rpi-workflow.md](../../../rules/rpi-workflow.md).

### Research Phase
- Load max 10 files (2K chars each)
- Read: spring-boot-starter.gradle, build.gradle.kts, pom.xml
- Read: relevant controller, service, repository, entity classes
- Read: tej-controller-patterns.md, kafka-patterns.md
- Read: guardrails.md, java-coding-standards.md

### Plan Phase
- Plan file structure: create/modify/delete operations per file
- Define Spring Bean candidates, Kafka topics, DB tables
- No code in plan, only structure and rationale
- Estimate lines of code per file

### Implement Phase
- Create Spring components: @Service, @Repository, @Controller
- Use try-with-resources (auto-close resources)
- SQL: parameterized queries only (PreparedStatement, @Query with ?)
- Logging: SLF4J only (no System.out, no log4j direct)
- Exception handling: throw TEJ exception hierarchy
- Kafka: singleton producer, topic-per-consumer pattern

## Guardrails

### Code Style
- Checkstyle enforces Google Java Style
- Method names: camelCase, verb-noun (getUserById)
- Constants: UPPER_SNAKE_CASE
- Class names: PascalCase
- Package names: reverse domain (com.jio.photos.api)

### Security
- SQL injection: no string concatenation, use parameterized queries
- Secrets: use ConfigServer or environment variables, never hardcode
- Authentication: OAuth2 + JWT tokens
- RBAC: use Spring Security @PreAuthorize annotations

### Performance
- N+1 queries: use FETCH JOIN or pagination
- Cache: @Cacheable for read-heavy operations
- Async: @Async for non-blocking operations
- Connection pooling: HikariCP (default in Spring Boot)

### Testing
- Unit tests: mock external dependencies
- Integration tests: use @SpringBootTest with TestContainers (Kafka, Postgres)
- Coverage: aim for 80%+ lines covered
- Mock Kafka: EmbeddedKafka for tests

## Dependency Checklist
- Spring Boot Starter Web (HTTP)
- Spring Boot Starter Data JPA (database)
- Spring Boot Starter Kafka (messaging)
- Gson (JSON serialization)
- JUnit 5 + Mockito (testing)
- PostgreSQL driver
- Liquibase or Flyway (migrations)
- SLF4J + Logback (logging)
