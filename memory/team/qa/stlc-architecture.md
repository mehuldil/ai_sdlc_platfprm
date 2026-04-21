# STLC (Software Testing Life Cycle) Architecture

**Team**: QA  
**Last Updated**: 2026-04-10  
**Maintained By**: QA Lead  

---

## Testing Layers

### Layer 1: Unit Tests (Developer Responsibility)
- **Framework**: Jest (JavaScript), JUnit4 (Java)
- **Coverage Target**: ≥80%
- **Execution**: During build (pre-commit)
- **Owner**: Individual engineers
- **Tools**: Jest, Mockito, TestNG

### Layer 2: Integration Tests
- **Framework**: TestContainers (for database/services)
- **Coverage**: Service-to-service communication, API contracts
- **Execution**: CI/CD pipeline (pre-merge)
- **Owner**: Feature team QA
- **Tools**: TestContainers, Postman, REST Assured

### Layer 3: System/E2E Tests
- **Framework**: Cypress (web), Detox (mobile)
- **Coverage**: Full user journeys, multiple features
- **Execution**: Nightly + release gate
- **Owner**: QA team
- **Tools**: Cypress, Detox, BrowserStack

### Layer 4: Load/Performance Tests
- **Framework**: JMeter, k6
- **Coverage**: Baseline, peak, stress, soak profiles
- **Execution**: Quarterly + pre-release
- **Owner**: Performance QA team
- **Tools**: JMeter, Grafana, custom scripts

---

## Test Environment Stages

```
Developer Local
  ↓ (Push to feature branch)
CI Environment (GitHub Actions)
  ├─ Unit tests
  ├─ Linting
  ├─ Integration tests
  └─ Build artifact
  ↓ (Merge to develop)
Staging Environment
  ├─ Deploy build
  ├─ E2E tests (smoke)
  ├─ Regression suite
  └─ Manual exploratory testing
  ↓ (Release approval)
Production Environment
  ├─ Blue-green deployment
  ├─ Smoke tests (post-deploy)
  └─ Monitoring & alerting
```

---

## Gate Criteria

| Gate | Blocker | Owner | Requirement |
|------|---------|-------|-------------|
| Unit Test | Yes | Dev | 100% pass, coverage ≥80% |
| Integration | Yes | Dev | 100% pass |
| Build | Yes | CI/CD | Build succeeds, artifact created |
| E2E Smoke | Yes | QA | Critical paths pass |
| Regression | Yes | QA | No regressions, pass rate >95% |
| Performance | No | QA | Meets baseline, no degradation |
| UAT | No | Product | Product sign-off |

---

## Test Data Management
- **Fixtures**: Reusable test datasets in code (seeds)
- **Database Reset**: Before each test suite (clean state)
- **User Accounts**: Pre-created for different scenarios (admin, standard, guest)
- **Test Environment Refresh**: Daily (removes stale data)

---

**Next STLC Review**: Q2 2026
