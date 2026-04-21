# Java Code Review Checklist (7 Dimensions)

## 1. Security
- [ ] No SQL injection (parameterized queries)
- [ ] No hardcoded secrets/credentials
- [ ] Proper authentication/authorization checks
- [ ] Input validation on all user data
- [ ] No use of weak cryptography

## 2. Reliability
- [ ] All exceptions caught and handled
- [ ] No silent failures (catch-and-ignore)
- [ ] Proper logging at each exception point
- [ ] Timeout handling for I/O operations
- [ ] Circuit breaker pattern for external calls

## 3. Performance
- [ ] No N+1 query problems
- [ ] Efficient data structures (HashMap vs ArrayList)
- [ ] No large object creation in loops
- [ ] Connection/resource pooling used
- [ ] Caching strategies documented

## 4. Maintainability
- [ ] Clear method names (verb-noun)
- [ ] Methods <30 lines (complexity check)
- [ ] No duplicated code (DRY principle)
- [ ] Comments explain *why*, not *what*
- [ ] Proper use of design patterns

## 5. Testing
- [ ] Unit test coverage ≥80%
- [ ] Test method names describe scenario
- [ ] Mocking used for external dependencies
- [ ] Edge cases tested (null, empty, negative)
- [ ] No hardcoded test data paths

## 6. Standards Compliance
- [ ] Java 17 conventions followed
- [ ] Gradle build correctly configured
- [ ] No deprecated APIs used
- [ ] Logging via SLF4J (no System.out)
- [ ] Serialization via Gson (no Jackson)

## 7. Code Quality
- [ ] No TODO comments without dates
- [ ] No commented-out code
- [ ] No dead code (unused methods/classes)
- [ ] Consistent formatting (4-space indent)
- [ ] Max line length 120 characters

## 8. Standards Compliance

### SQL & Database
- ❌ **String concatenation in SQL**
  ```java
  // FORBIDDEN
  String sql = "SELECT * FROM users WHERE id = " + userId;
  ```
- ✅ **Parameterized queries only**
  ```java
  String sql = "SELECT * FROM users WHERE id = ?";
  stmt.setLong(1, userId);
  ```
- ❌ **Raw JDBC without try-with-resources**
- ✅ **Always use try-with-resources**
  ```java
  try (PreparedStatement stmt = conn.prepareStatement(sql)) { }
  ```

### Exception Handling
- ❌ Catch and ignore (silent failures)
- ❌ Raw RuntimeException throws
- ✅ Wrap in ApplicationServiceException with error code
- ✅ Log full exception context (logger.error with stacktrace)

### Serialization
- ❌ Jackson, XStream, manual JSON parsing
- ✅ Gson only (org.gson)

### Logging
- ❌ System.out, System.err, printStackTrace()
- ✅ SLF4J via LoggerFactory.getLogger()

### Code Review Checks
1. All SQL parameterized?
2. No raw RuntimeException?
3. All try-with-resources used?
4. No System.out/err?
5. Logging via SLF4J?
6. No commented-out code?
7. Coverage ≥80%?

---
**Last Updated**: 2026-04-11  
**Stack**: Java 17 TEJ/RestExpress
