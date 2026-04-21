---
name: Java Backend Code Review Variant
description: Stack-specific code review checks for Java/TEJ
stack: java-backend
---

# Java Backend Code Review Variant

## Review Checks

### 1. TEJ Exception Hierarchy
- Check: All exceptions extend TechErrorBase or appropriate subclass
- Check: Exceptions include code, message, and context
- Check: Custom exceptions have JavaDoc
- Red Flag: Generic Exception or RuntimeException thrown
- Red Flag: Empty catch blocks (should log or re-throw)

### 2. Kafka Patterns
- Check: Producer is singleton @Bean (not new producer per call)
- Check: Topic names follow domain.event.version convention
- Check: Consumer group IDs unique per consumer
- Check: Message schema versioned (Avro)
- Red Flag: Blocking calls in Kafka handlers
- Red Flag: No error handling for failed publishes

### 3. SQL & Database
- Check: All SQL parameterized (PreparedStatement or @Query with ?)
- Check: No string concatenation in SQL
- Check: Connection pooling configured (HikariCP)
- Check: Transactions use @Transactional (not manual)
- Red Flag: SELECT * (specify columns)
- Red Flag: N+1 queries (use FETCH JOIN or pagination)
- Red Flag: Deadlocks (check query order)

### 4. Logging & Secrets
- Check: SLF4J only (no log4j, commons-logging, System.out)
- Check: No sensitive data logged (tokens, passwords, PII)
- Check: Secrets from ConfigServer or environment (not hardcoded)
- Check: Log levels appropriate (DEBUG for detailed, INFO for milestones)
- Red Flag: Passwords or tokens in logs
- Red Flag: System.out.println or System.err

### 5. Resource Management
- Check: try-with-resources for auto-closeable (streams, connections)
- Check: Explicit close() in finally if not try-with-resources
- Check: No unclosed resources (streams, readers, writers)
- Red Flag: new FileInputStream without try-with-resources
- Red Flag: Missing close() in non-try block

### 6. Spring Best Practices
- Check: Services are @Service, Repositories are @Repository
- Check: Dependency injection via constructor (not @Autowired on fields)
- Check: Configuration externalizes to properties (not hardcoded)
- Check: @Transactional on service methods (not repos)
- Red Flag: Circular dependencies
- Red Flag: Static fields injected

### 7. Testing
- Check: Unit tests for business logic
- Check: Mocks for external dependencies (DB, Kafka, HTTP)
- Check: Coverage > 80% for core logic
- Check: Test names describe what they test
- Red Flag: Tests dependent on test order
- Red Flag: Hardcoded delays (Thread.sleep)
