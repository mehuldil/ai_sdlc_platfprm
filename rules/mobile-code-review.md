# Mobile Code Review Standards

Unified code review standards for all mobile platforms (Kotlin/Android, Swift/iOS, React Native).

---

## Developer Authority & Reviewer Role

- **Developer has context authority**: Developer set original requirements, architecture decisions, and implementation approach
- **Reviewer role**: Identify issues, bugs, and risks — NOT to redesign or redirect the solution
- **Issue classification**: Categorize findings as blocking, major, minor, or informational

## Change Scope Limits

- **Original files only**: Modify files introduced in the PR
- **Related tests**: Update unit/integration tests for changed logic
- **Bug fixes only**: Small fixes without scope expansion
- **Red flag**: Request to redesign, add features, or refactor unrelated code

## Reviewer Constraints

- **Validation**: Verify logic, security, performance against standards
- **Recommendations**: Suggest improvements but acknowledge developer's design choice
- **Never expand scope**: Do not add features, configs, or tasks beyond PR intent
- **Escalate disagreement**: If fundamental issues exist, discuss offline — don't delay via comments

## Minimal Fix Rule

- **Smallest change to fix each issue**: Apply minimal correction without refactoring
- **Avoid churn**: Don't enforce style preferences on unrelated code

## Platform-Specific Notes

### Kotlin/Android

**Minimal Fix Example**: If null check fails, add null check — don't rewrite entire method

**Approval Criteria**:
- ✓ No security vulnerabilities
- ✓ Meets coverage targets (80% minimum)
- ✓ No performance regressions
- ✓ Follows coding standards
- ✓ Clear commit messages with AB# reference

### Swift/iOS

**Platform-Specific Issues**:
- Force unwraps in non-test code
- Memory leaks or retain cycles

**Minimal Fix Example**: If force unwrap fails, use optional binding — don't rewrite entire function

**Approval Criteria**:
- ✓ No force unwraps in non-test code
- ✓ Meets coverage targets (80% minimum)
- ✓ No memory leaks or retain cycles
- ✓ Follows naming conventions and coding standards
- ✓ Clear commit messages with AB# reference

### React Native

**Platform-Specific Tools**:
- Pre-commit hooks (ESLint, Prettier, TypeScript, commitlint)
- Performance measured at 60fps

**Minimal Fix Example**: If hook dependency is missing, add it — don't rewrite component

**Approval Criteria**:
- ✓ Passes pre-commit hooks (ESLint, Prettier, TypeScript)
- ✓ Meets coverage targets (80% minimum)
- ✓ No performance regressions (measure at 60fps)
- ✓ Follows React Native conventions
- ✓ Clear commit messages with AB# reference

---

**Last Updated**: 2026-04-11
**Scope**: All mobile platforms (Kotlin/Android, Swift/iOS, React Native)
