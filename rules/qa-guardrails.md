# QA Guardrails (Quality Assurance)

## Flaky Test Policy
- **Max retries**: 2 (test may run up to 3 times total)
- **Rationale**: Identify and fix root causes, not mask failures
- **Metrics**: Track retry rate per test (should be <5%)
- **Action**: Investigate tests with >10% retry rate

## External System Isolation
- **Use mocks**: Never depend on real external APIs in unit tests
- **Stub services**: Provide predictable, repeatable responses
- **Failure scenarios**: Mock both success and failure paths
- **Tools**: Use Mockito, WireMock, or equivalent

## Test Data Management
- **No hardcoded secrets**: Never include passwords, API keys, tokens
- **Sensitive data**: Use environment variables or secure vaults
- **Example**: Use `System.getenv("TEST_API_KEY")` not literal strings
- **Fixtures**: Store test data in files or databases, not source code

## State Cleanup
- **@AfterEach (or @After)**: Teardown after every test
- **Reset shared state**: Clear test databases, caches, temp files
- **Isolation**: Each test must be independent
- **Example**: Close connections, delete temp resources

## Prohibited Patterns
- **❌ Thread.sleep()**: Never use for timing
  - Use proper event-based synchronization
  - Implement explicit waits or polling loops
- **❌ Execution order dependencies**: Tests must run in any order
  - No shared state between tests
  - No assumptions about test sequence
- **❌ Hardcoded timeouts**: Use configurable values
  - Define constants for wait times
  - Allow override via test parameters

## Test Naming Convention
```
test_<method>_<scenario>_<expected>
```

### Examples
- `test_login_withValidCredentials_returnsAuthToken`
- `test_getUserById_withInvalidId_throwsNotFoundException`
- `test_calculateTotal_withEmptyCart_returnsZero`
- `test_submitForm_withMissingEmail_showsValidationError`

### Breakdown
- **test_**: Standard prefix
- **\<method>**: Function/method being tested (e.g., `login`, `getUserById`)
- **\<scenario>**: Test conditions (e.g., `withValidCredentials`, `withEmptyCart`)
- **\<expected>**: Expected outcome (e.g., `returnsAuthToken`, `throwsException`)

---
**Last Updated**: 2026-04-11  
**Governed By**: AI-SDLC Platform
