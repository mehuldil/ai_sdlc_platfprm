# Known Flaky Tests

**Team**: QA  
**Last Updated**: 2026-04-10  
**Maintained By**: QA Lead  

---

## Currently Flaky Tests (Intermittent Failures)

### 1. Search Results Pagination Test (E2E)
- **Test**: `test/e2e/search-pagination.spec.ts`
- **Failure Rate**: ~5% (1 in 20 runs)
- **Root Cause**: Elasticsearch sync delay (100-200ms variability)
- **Flakiness Pattern**: Fails when ES index not synced before test assertion
- **Workaround**: Added 300ms wait before pagination test
- **Permanent Fix**: Pending ES index optimization (DevOps, Q2 2026)

### 2. Notification Dropdown Close Test (Mobile)
- **Test**: `test/e2e/mobile-notification-dropdown.spec.ts`
- **Failure Rate**: ~8% (1 in 12 runs on iOS)
- **Root Cause**: Network delay in notification socket connection
- **Flakiness Pattern**: Dropdown doesn't close because WS connection not established
- **Workaround**: Added explicit wait for socket.ready event
- **Permanent Fix**: Implement socket reconnection with backoff

### 3. Avatar Upload Integration Test
- **Test**: `test/integration/avatar-upload.spec.ts`
- **Failure Rate**: ~3% (environmental)
- **Root Cause**: File system sync issues on concurrent uploads
- **Flakiness Pattern**: Fails when multiple tests upload simultaneously
- **Workaround**: Sequential test execution (disabled parallelism for this suite)
- **Permanent Fix**: Mock S3 instead of file system (TestContainers)

---

## Monitoring Flakiness

### Test Suite Health
- **Total Tests**: 342 (unit: 200, integration: 85, e2e: 57)
- **Currently Flaky**: 3 tests
- **Flakiness Rate**: 0.9% (acceptable <1%)

### Recent Improvements
- Fixed: AuthToken refresh test (was 12% flaky, now 0%)
- Fixed: Database connection pool test (was 4% flaky, now 0%)

---

## Prevention Strategy
1. **Isolate & Retry**: Run flaky tests 3x; pass if ≥2 succeed
2. **CI Monitoring**: Alert if flakiness >1% in any suite
3. **Root Cause Triage**: Investigate any new flakiness within 24 hours
4. **Quarterly Cleanup**: Remove workarounds once permanent fix deployed

---

**Next Review**: 2026-04-17  
**Alert Threshold**: >2% flakiness
