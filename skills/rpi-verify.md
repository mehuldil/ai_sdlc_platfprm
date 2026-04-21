# RPI Verify — Implementation Validation

**Model:** Claude 3.5 Sonnet | **Trigger:** `sdlc rpi verify <story-id>` or `/project:rpi-verify AB#<id>`

---

## What It Does

This skill executes Phase 4 of the RPI workflow: validates implementation against plan. It compares the actual git diff to planned changes and verifies all tests pass and coverage meets minimum.

**This phase is NEW and unique to the SDLC Platform's improved RPI workflow.**

1. Load `plan.md` and actual `git diff --cached` (staged changes)
2. Compare each planned change against actual diff
3. Detect missing changes (incomplete implementation)
4. Detect scope creep (unplanned changes)
5. Validate all tests pass with expected output
6. Check coverage ≥80% minimum
7. Output `.sdlc/rpi/{story-id}/verify.md` with pass/fail verdict

---

## Execution Steps

### Step 1: Load Plan & Staged Diff

```bash
plan_file=".sdlc/rpi/${story_id}/plan.md"
if [ ! -f "$plan_file" ]; then
  echo "ERROR: plan.md not found."
  exit 1
fi

# Get staged changes (what implementer produced)
git diff --cached > /tmp/staged.diff
if [ ! -s /tmp/staged.diff ]; then
  echo "ERROR: No staged changes found. Did implementer run?"
  exit 1
fi
```

### Step 2: Parse Planned Changes from Plan.md

Extract from plan.md all planned diffs and organize by file:

```
PLANNED_CHANGES:
  src/auth/AuthService.java:
    - @@ -50,5 +50,12 @@ (add OAuth2 method)
    - @@ -80,3 +87,4 @@ (add provider mapping)
  src/config/SecurityConfig.java:
    - @@ -60,2 +60,5 @@ (add OAuth2 client config)
  ...
```

### Step 3: Compare Planned vs Actual

For each file in plan:

#### 3a. Extract Planned Changes
Parse plan.md unified diff for file:
```
--- a/src/auth/AuthService.java
+++ b/src/auth/AuthService.java
@@ -50,5 +50,12 @@
   public LoginResponse login(...) { ... }
+  public LoginResponse login(OAuthProvider provider, String code) {
+    ...
+  }
```

#### 3b. Extract Actual Changes
Parse staged diff for same file:
```
git diff --cached src/auth/AuthService.java
```

#### 3c. Line-by-Line Comparison

For each planned change:
- **Does actual diff contain the planned diff?** (allowing whitespace variations)
- **Are the line numbers approximately correct?** (within 5 lines is acceptable if code context is present)
- **Is the change semantic equivalent?** (e.g., `String x = "value"` vs `String x="value"` are equivalent)

**Matching algorithm**:
```
1. Extract planned diff block (lines + additions)
2. Search staged diff for exact or semantic match
3. If found: PASS for this change
4. If not found: MISSING CHANGE — Flag as FAIL
```

### Step 4: Detect Scope Creep

In actual staged diff, look for changes NOT in planned diff:

```
For each file in staged diff:
  For each hunk in staged diff:
    if hunk NOT in planned diff:
      if hunk is "obvious cleanup" (whitespace, comment fix):
        Flag as WARNING (not critical)
      else:
        Flag as UNPLANNED CHANGE — Scope creep FAIL
```

**Obvious cleanups to ignore**:
- Removing trailing whitespace
- Adding javadoc/docstring (if not part of change)
- Fixing lint errors in modified section

**Unplanned changes to flag**:
- New methods/classes not in plan
- Refactoring of unrelated code
- Changes to files not in plan

### Step 5: Validate Tests

From plan.md, extract test list:
- New tests: `test_login_withOAuthProvider_success`, ...
- Modified tests: `test_login_withEmailPassword`, ...

#### 5a. Check Test Output

From implementer's test run output:
```
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0

test_login_withOAuthProvider_success... PASS ✓
test_login_withOAuthProvider_timeout... PASS ✓
test_userData_mergedFromProvider_correctEmail... PASS ✓
```

**Expected**: All tests PASS  
**Actual**: Check output  
**Status**: PASS if actual matches expected

#### 5b. Compare Test Counts

From plan:
- "New tests to add": N tests
- "Tests to modify": M tests

From actual output:
- Total tests run: X

**Expected**: X ≥ N + M (at least new + modified)  
**Status**: PASS if X ≥ N + M

### Step 6: Validate Coverage

From coverage report (JaCoCo, Jest, Xcode, etc.):

```
Expected (from plan):
  Line coverage: 82%
  Branch coverage: 78%
  Target: ≥80%

Actual (from coverage tool):
  Line coverage: 82%
  Branch coverage: 78%
  Target: ≥80%
```

**Status**: PASS if Actual ≥ Target (≥80%)

### Step 7: Generate Verification Report

Create detailed report (see output format below).

---

## Output Format

Create `.sdlc/rpi/{story-id}/verify.md`:

```markdown
# Verification Report: {story-id}

## Report Metadata
- **Story ID**: US-{story-id}
- **Story Title**: {title}
- **Verification Date**: {ISO 8601}
- **Verifier**: Claude 3.5 Sonnet
- **Plan Approved By**: {person}

---

## OVERALL VERDICT: PASS / FAIL / CONDITIONAL

**Summary**: {1-2 sentence summary of verification result}

If FAIL: {List critical issues preventing merge}  
If PASS: {Ready to commit and merge}  
If CONDITIONAL: {Issues found but may be acceptable with justification}

---

## Implementation Completeness

### Planned Changes vs Actual Changes

| # | File | Planned Change | Line Range | Found in Diff | Status |
|---|---|---|---|---|---|
| 1 | src/auth/AuthService.java | Add OAuth2 login method | 50-12 | ✓ YES | PASS |
| 2 | src/auth/AuthService.java | Add provider mapping | 80-4 | ✓ YES | PASS |
| 3 | src/config/SecurityConfig.java | Add OAuth2 client config | 60-5 | ✓ YES | PASS |
| 4 | src/model/User.java | Add provider_id field | 30-3 | ✓ YES | PASS |
| 5 | db/schema/V003__add_oauth_columns.sql | Create migration file | N/A | ✓ YES | PASS |
| 6 | src/test/AuthServiceTest.java | Add 3 new tests | 400-30 | ✓ YES | PASS |

**Summary**: 6/6 planned changes found in actual diff (100% complete)

---

## Scope Creep Detection

### Unplanned Changes Found
| File | Change Description | In Plan? | Type | Issue Level |
|---|---|---|---|---|
| src/auth/AuthService.java | Refactored `validateEmail` method | NO | Refactor | ⚠️ WARNING |
| src/util/StringUtils.java | Added new utility method | NO | New code | ❌ FAIL |

**Summary**: 1 warning (minor cleanup), 1 unplanned change (scope creep)

**Issues**:
1. ❌ **FAIL**: StringUtils.java has new method `isValidOAuth2Provider()` not in plan
   - **Impact**: Scope creep; increases risk
   - **Recommendation**: Remove or add to plan explicitly
2. ⚠️ **WARNING**: validateEmail method was refactored (whitespace + logic)
   - **Impact**: Minor; if behavior-preserving, acceptable
   - **Recommendation**: Verify refactoring doesn't change behavior

---

## Test Validation

### Planned Tests vs Actual Test Results

| Test Name | Test Class | Planned Status | Actual Result | Maps to AC |
|---|---|---|---|---|
| test_login_withOAuthProvider_success | AuthServiceTest | NEW | PASS ✓ | AC-01 |
| test_login_withOAuthProvider_timeout | AuthServiceTest | NEW | PASS ✓ | Error case |
| test_userData_mergedFromProvider_correctEmail | UserMergeTest | NEW | PASS ✓ | AC-02 |
| test_login_withEmailPassword | AuthServiceTest | MODIFIED | PASS ✓ | AC-03 (existing) |
| test_userProfile_completeness | UserProfileTest | MODIFIED | PASS ✓ | Regression |

**Summary**: 5/5 tests PASS (as expected)

### Test Count Verification
| Metric | Planned | Actual | Status |
|---|---|---|---|
| New tests | 3 | 3 | ✓ |
| Modified tests | 2 | 2 | ✓ |
| Total tests run | 5+ | 11 | ✓ (includes existing tests) |

**Status**: PASS — All planned tests present and passing

---

## Coverage Validation

### Coverage Metrics
| Metric | Planned Target | Actual | Status |
|---|---|---|---|
| Line Coverage | ≥80% | 82% | ✓ PASS |
| Branch Coverage | ≥70% | 78% | ✓ PASS |
| Conditional Coverage | ≥65% | 75% | ✓ PASS |

**Tool**: JaCoCo (Maven) / Jest / Xcode Coverage  
**Report**: {Link to report or path}  
**Status**: PASS — All metrics meet or exceed targets

---

## Detailed File-by-File Verification

### File 1: src/auth/AuthService.java

**Planned Changes**:
```diff
@@ -50,5 +50,12 @@
   public LoginResponse login(String email, String password) {
     // existing code
   }
+
+  public LoginResponse login(OAuthProvider provider, String code) {
+    String token = provider.exchangeCode(code);
+    User user = fetchUserFromProvider(provider, token);
+    mergeUserAccounts(user);
+    return createLoginResponse(user);
+  }
```

**Actual Diff**:
```diff
@@ -50,5 +50,12 @@
   public LoginResponse login(String email, String password) {
     // existing code
   }
+
+  public LoginResponse login(OAuthProvider provider, String code) {
+    String token = provider.exchangeCode(code);
+    User user = fetchUserFromProvider(provider, token);
+    mergeUserAccounts(user);
+    return createLoginResponse(user);
+  }
```

**Comparison**: ✓ EXACT MATCH  
**Status**: PASS

---

### File 2: src/config/SecurityConfig.java

**Planned Changes**:
```diff
@@ -60,2 +60,5 @@
   // Bean definitions
+  @Bean
+  public OAuth2ClientConfigurer oauth2ClientConfigurer() {
+    return new OAuth2ClientConfigurer();
+  }
```

**Actual Diff**: [Matches plan exactly]

**Status**: PASS

---

{Repeat for remaining files}

---

## Summary Table: All Checks

| Check | Requirement | Actual | Status |
|---|---|---|---|
| Completeness | All 6 planned changes present | 6/6 found | ✓ PASS |
| Scope Creep | No unplanned code additions | 1 utility method added | ❌ FAIL |
| Test Results | All planned tests PASS | 5/5 PASS | ✓ PASS |
| Test Coverage | ≥80% line coverage | 82% | ✓ PASS |
| Branch Coverage | ≥70% | 78% | ✓ PASS |
| No conflicts | No merge conflicts | 0 conflicts | ✓ PASS |

---

## Issues Summary

### Critical Issues (FAIL)
1. **Unplanned scope creep**: StringUtils.java `isValidOAuth2Provider()` not in plan
   - **Action**: Remove or update plan and re-implement

### Warnings (Review Required)
1. **refactoring**: validateEmail method refactored beyond plan scope
   - **Action**: Verify behavior preservation; may be acceptable if no logic change

### Observations (Informational)
- Test coverage improved as expected (78% → 82%)
- All planned changes are present and correct
- No missing implementations identified

---

## Verdict & Recommendations

### OVERALL VERDICT: CONDITIONAL PASS

**Status**: Can proceed to commit WITH CONDITIONS

**Conditions**:
1. Remove StringUtils.java `isValidOAuth2Provider()` method (scope creep)
2. OR: Justify addition and update plan.md explicitly

**After conditions met**: Ready to commit and merge

---

## Sign-Off

- **Verifier**: Claude 3.5 Sonnet
- **Date**: {ISO 8601}
- **Verified Against**: plan.md (v1.0, approved {date})
- **Status**: CONDITIONAL PASS

---

**Next Steps**:
1. Human reviews this verification report
2. Address issues listed above (remove scope creep or justify)
3. Re-run implement if changes needed (returns to Implement phase)
4. Once PASS or CONDITIONAL PASS approved:
   - Human commits staged changes
   - Human pushes to main
   - Marks story as DONE
```

---

## Rules & Constraints

### Comparison Strictness
- **Exact line matching**: Planned and actual must match (allowing ±2 line variance if context is correct)
- **Whitespace sensitivity**: Ignore trailing spaces and line-ending differences
- **Comment preservation**: Don't penalize if comments changed
- **Refactoring tolerance**: If logic is equivalent, minor style changes are OK

### Scope Creep Detection
- **Flag all unplanned changes** — even if they seem harmless
- **Document each unplanned change** — let human decide if acceptable
- **Include line numbers** — show exactly where scope creep occurs
- **Provide context** — explain why it's out of scope

### Test Validation
- **Count tests** — ensure count matches planned
- **Check PASS/FAIL** — all must pass
- **Verify coverage** — ≥80% minimum
- **Track AC mapping** — tests should cover acceptance criteria

### Coverage Enforcement
- **Line coverage ≥80%** — hard minimum
- **Branch coverage ≥70%** — recommended
- **Flag if below** — mark as FAIL, but allow human override with justification

### After Output
- **Present findings to human** — clear, structured report
- **Wait for human decision** — PASS, FAIL, or CONDITIONAL PASS
- **Do NOT auto-commit** — human always controls merge
- **Do NOT proceed without approval** — even if PASS

---

## Troubleshooting

| Issue | Action |
|-------|--------|
| plan.md not found | ABORT. Run Implement phase first. |
| No staged changes | ABORT. Implementer must stage changes. |
| Diff syntax error | Report error; ask human to check git status. |
| Test output not found | Skip test validation; note in report. |
| Coverage report missing | Omit coverage verification; note in report. |
| Multiple unplanned changes | Flag all of them; let human decide. |

---

## Integration Points

- **Input**: `plan.md` + staged git diff (from Implement phase)
- **Output**: `.sdlc/rpi/{story-id}/verify.md`
- **Gate**: Human approval of verification report
- **Final**: Human commits, pushes, and marks story DONE

---

## Example Verdict Scenarios

### Scenario 1: PASS
```
All 6 planned changes present in diff
No scope creep detected
All 5 tests passing
Coverage 82% (target ≥80%)

Verdict: PASS → Ready to commit
```

### Scenario 2: FAIL
```
Missing change: src/auth/AuthService.java line 95-98 not found
Unplanned change: New class OAuthUtil.java added

Verdict: FAIL → Return to Implement phase for fixes
```

### Scenario 3: CONDITIONAL PASS
```
All planned changes present
Scope creep: validateEmail method refactored (whitespace + formatting)
All tests passing
Coverage 82%

Verdict: CONDITIONAL PASS → Allow human to decide if refactoring is acceptable
```

---

**Last Updated**: 2026-04-11  
**Part of**: RPI Workflow (rules/rpi-workflow.md)  
**Unique To**: AI SDLC Platform (not in Claude's original RPI)
