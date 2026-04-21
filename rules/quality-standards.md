# Mobile Quality Standards

Unified quality standards for all mobile platforms (Kotlin/Android, Swift/iOS, React Native).

---

## Code Coverage Requirements

- **Minimum: 80%** (statements, branches, lines, and functions)
- **Exceptions**: CTO approval required to go below 80%
- **Measurement**: Platform-specific tooling (see table below)

| Platform | Tool | Report Location |
|----------|------|------------------|
| Kotlin/Android | JaCoCo plugin in Gradle | `build/reports/jacoco/` |
| Swift/iOS | Xcode code coverage | Xcode Reports > Code Coverage |
| React Native | Jest coverage reports | `coverage/` directory in project root |

## Bug Fix Protocol

1. **Write failing test first**: Create test that reproduces the bug
2. **Prove the fix**: Test passes after code change
3. **Run regression suite**: Ensure no other tests break
4. **Coverage check**: New test code must maintain 80% threshold

## Task Sizing

- **Optimal: 1-2 hours** of focused development
- **Single objective**: One feature or bug per task
- **Limited files**: Modify 1-5 files maximum (excluding tests)
- **Clear acceptance criteria**: Definition of done visible before coding

## Dependency Management

Before adding any external dependency:

| Check | Kotlin/Android | Swift/iOS | React Native |
|-------|---|---|---|
| **Package size threshold** | JAR >2MB triggers review | Framework >5MB triggers review | >500KB triggers review |
| **Check transitive deps** | Audit for unnecessary indirect deps | Audit dependency tree | Audit for unnecessary indirect deps |
| **Native/Platform impact** | Flag native bindings (NDK) | Verify iOS version compatibility | Flag packages with native code/linking |
| **License compliance** | Verify project license compat | Verify project license compat | Verify project license compat |
| **Maintenance status** | Prefer actively maintained | Prefer actively maintained | Prefer actively maintained |

## Code Review Integration

- Run coverage check in CI/CD pipeline
- Fail build if coverage drops below threshold
- Document exceptions in ADO work item

---

## React Native Additions

### Pre-commit Hooks (Mandatory)

- **ESLint**: Enforce code quality rules
- **Prettier**: Enforce consistent formatting
- **TypeScript**: Type checking (if using TS)
- **commitlint**: Validate commit message format

### Cache Management

- **Images**: ≤150MB max cache
- **Videos**: ≤150MB max cache
- **Temp files**: ≤50MB max
- **Eviction**: LRU (least recently used) policy

### Storage Monitoring

- Track total app storage at startup
- Monitor storage changes after downloads
- Alert if storage exceeds device thresholds
- Implement cleanup routines for stale data

---

**Last Updated**: 2026-04-11
**Scope**: All mobile platforms (Kotlin/Android, Swift/iOS, React Native)
