# RPI Implement — Strict Execution

**Model:** Claude 3.5 Sonnet | **Trigger:** `sdlc rpi implement <story-id>` or `/project:rpi-implement AB#<id>`

---

## What It Does

This skill executes Phase 3 of the RPI workflow: implementing exactly what the plan says, with zero deviations.

**Repo grounding:** Implementation **must** reference **real paths** from the plan and approved design (**§0** / **§5**). Before and after edits, use **existing tests** next to the change (and any tests listed in the plan) to validate **new behavior** and **regression**—same commands as in the plan (JUnit, pytest, Jest, etc.).

1. Load `.sdlc/rpi/{story-id}/plan.md` — ABORT if not found
2. Verify human approved plan (check `.sdlc/rpi/{story-id}/.approved-plan` marker)
3. Execute changes file by file, in order listed in plan
4. Run tests specified in plan
5. Generate diff summary showing all changes
6. Output summary and STOP for human review (do NOT commit)

---

## Execution Steps

### Step 1: Load & Verify Plan

```bash
plan_file=".sdlc/rpi/${story_id}/plan.md"
if [ ! -f "$plan_file" ]; then
  echo "ERROR: plan.md not found. Run 'sdlc rpi plan' first."
  exit 1
fi

if [ ! -f ".sdlc/rpi/${story_id}/.approved-plan" ]; then
  echo "ERROR: Plan not approved. Waiting for human approval."
  exit 1
fi
```

**Stop immediately if either check fails.**

### Step 2: Parse File Order from Plan

Extract file list from plan.md in order:
```
1. src/auth/AuthService.java
2. src/config/SecurityConfig.java
3. src/model/User.java
4. db/schema/V003__add_oauth_columns.sql
5. src/test/AuthServiceTest.java
```

**Important**: Implement in THIS order. Do NOT reorder.

### Step 3: For Each File, Apply Changes

For file N in file list:

#### 3a. Read Current State
```bash
# Get current file from HEAD
git show HEAD:{filepath} > /tmp/before.txt

# Or if new file
touch /tmp/before.txt  # empty file
```

#### 3b. Apply Exact Changes from Plan

Read the plan.md section for this file and apply changes line-by-line.

**Method 1: Use the diff from plan (preferred)**
```bash
# Plan includes unified diff like:
# @@ -45,5 +45,8 @@
# Copy exact lines from plan and apply to file

# Apply using patch if possible
patch -p0 < /tmp/changes.patch
```

**Method 2: Manual line-by-line edits (if diff doesn't apply cleanly)**
```bash
# For each line change in plan:
# 1. Verify the "before" context matches current file
# 2. Apply the exact "after" from plan
# 3. Do NOT improvise or "improve" the code
```

**CRITICAL RULE**: If the diff doesn't apply cleanly, STOP and report the mismatch. Do NOT guess or adapt. The plan is locked.

#### 3c. Verify Changes Match Plan

```bash
# Compare actual changes to planned changes
diff <(plan section for file) <(actual file) > /tmp/diff_check.txt

# If diff_check.txt is empty, PASS
# If diff_check.txt has content, ERROR — STOP and report
```

#### 3d. Stage the File
```bash
git add {filepath}
```

### Step 4: Run Tests Specified in Plan

From plan.md "Test Plan" section:

#### 4a. Run New Tests
```bash
# For each new test in plan:
# Example: test_login_withOAuthProvider_success

mvn test -Dtest=AuthServiceTest#test_login_withOAuthProvider_success
# or
./gradlew test --tests "*AuthServiceTest*test_login_withOAuthProvider_success"
```

Capture output. If FAIL, STOP and report.

#### 4b. Run Modified Tests
```bash
# Run all tests in classes that have modified tests
mvn test -Dtest=AuthServiceTest,UserMergeTest
# or
./gradlew test --tests "*AuthServiceTest*" "*UserMergeTest*"
```

Capture output. If FAIL, STOP and report.

#### 4c. Check Coverage
```bash
# Run full test suite with coverage
mvn clean test jacoco:report

# Check coverage report
cat target/site/jacoco/index.html | grep "Total"
# Should show ≥80% coverage

# If <80%, output warning but continue (coverage build failure handled in Verify phase)
```

### Step 5: Generate Diff Summary

```bash
# Show all staged changes
git diff --cached --stat > /tmp/diff_stat.txt
git diff --cached > /tmp/diff_full.txt

# Show first 100 lines of full diff
head -100 /tmp/diff_full.txt
```

### Step 6: Output Summary & Stop

Create summary (do NOT commit or push):

```
Execution Complete: RPI Implement for US-{id}

Files Modified: {count}
{file1}: {lines} added, {lines} removed
{file2}: {lines} added, {lines} removed

Tests Run: {count} passed, {count} failed
{test_name}: PASS
{test_name}: PASS

Coverage Report:
{coverage percentage}

Diff Summary:
{first 100 lines of git diff --cached}

Status: READY FOR REVIEW

Next Step: Human reviews staged changes. If approved, human commits.
```

---

## Output Format

After implementation, create a summary report (example):

```markdown
# Implementation Report: {story-id}

## Execution Status
- **Status**: COMPLETE
- **Started**: {ISO 8601}
- **Ended**: {ISO 8601}
- **Duration**: {X} minutes

## Files Modified
| File | Type | Lines Added | Lines Removed | Lines Modified |
|------|------|---|---|---|
| src/auth/AuthService.java | Modify | 12 | 0 | 3 |
| src/config/SecurityConfig.java | Modify | 8 | 1 | 2 |
| src/model/User.java | Modify | 3 | 0 | 1 |
| db/schema/V003__add_oauth_columns.sql | New | 10 | 0 | 0 |
| src/test/AuthServiceTest.java | Modify | 25 | 0 | 5 |

**Total**: 58 lines added, 1 line removed, 11 lines modified

## Test Results
```
[INFO] Building example-app-auth 1.0.0
[INFO]
[INFO] --- maven-surefire-plugin:2.22.2:test (default-test) @ example-app-auth ---
[INFO] Running com.jio.auth.AuthServiceTest
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.345 s
[INFO] Running com.jio.auth.UserMergeTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.567 s
[INFO]
[INFO] --- jacoco-maven-plugin:0.8.7:report (report) @ example-app-auth ---
[INFO] Skipping JaCoCo execution because provider.tx_ has file(s) that depend on this project.
[INFO]
[INFO] BUILD SUCCESS
```

**Summary**: 11 tests run, 0 failed, 0 errors

## Coverage Report
| Metric | Percentage |
|---|---|
| Line Coverage | 82% |
| Branch Coverage | 78% |
| Conditional Coverage | 75% |
| Target | ≥80% |
| Status | PASS |

Coverage tool: JaCoCo (Maven plugin)  
Report: `target/site/jacoco/index.html`

## Staged Changes (Preview)

```diff
diff --git a/src/auth/AuthService.java b/src/auth/AuthService.java
index 1234567..abcdefg 100644
--- a/src/auth/AuthService.java
+++ b/src/auth/AuthService.java
@@ -50,6 +50,12 @@ public class AuthService {
      return response;
    }

+  public LoginResponse login(OAuthProvider provider, String code) {
+    String token = provider.exchangeCode(code);
+    User user = fetchUserFromProvider(provider, token);
+    mergeUserAccounts(user);
+    return createLoginResponse(user);
+  }

diff --git a/src/test/AuthServiceTest.java b/src/test/AuthServiceTest.java
...
```

(Full diff truncated for brevity)

## Verification Checklist
- [x] All files from plan are staged
- [x] No additional files are staged
- [x] All new tests pass
- [x] All modified tests pass
- [x] Coverage ≥80%
- [x] No syntax errors
- [ ] Human approval required

## Implementation Notes
- All changes match plan.md exactly
- No deviations or improvements made
- Test coverage increased from 78% to 82%
- Ready for next phase: Verify

## Sign-Off
- **Implementer**: Claude 3.5 Sonnet
- **Date**: {ISO 8601, e.g. 2026-04-11T17:30:00Z}
- **Status**: READY FOR REVIEW

---

**Next Step**: Human reviews staged changes. Options:
1. Approve → Proceed to Verify phase
2. Request changes → Implementer revises and re-runs (stay in Implement phase)
3. Abort → Revert staged changes, return to Plan phase for revision
```

---

## Rules & Constraints

### Zero Deviations Policy
- **Implement EXACTLY what plan says** — no improvisation
- **No "improvements"** — even if you see a better way, follow the plan
- **No skipping changes** — if plan says change 47 lines, change exactly 47 lines
- **If blocked**: STOP and report. Do NOT work around issues.

### Execution Order
- **File order is fixed** — from plan.md file list
- **Do NOT reorder** — if file A depends on file B, plan specifies order
- **Sequential** — complete file N before starting file N+1

### Test Requirements
- **Run all planned tests** — do NOT skip
- **Capture full output** — include PASS/FAIL status for each
- **If any test fails**: STOP and report immediately
- **Coverage check**: ≥80% minimum; if below, report but continue (Verify phase will flag)

### Staging & Committing
- **Stage all changes** — `git add {files}`
- **Do NOT commit** — leave staged for human approval
- **Do NOT push** — human will commit and push after review
- **Do NOT force push** — never override history

### After Output
- **ALWAYS STOP** and wait for human approval
- **Do NOT proceed to Verify** until human explicitly approves
- **Do NOT make additional changes** after output
- Provide staged diff for human review

---

## Troubleshooting

| Issue | Action |
|-------|--------|
| Plan.md file not found | ABORT. User must run Plan phase first. |
| Plan not approved | ABORT. User must approve plan first. |
| Diff doesn't apply cleanly | STOP. Report context mismatch. Do NOT attempt patch -F3. |
| Test fails | STOP. Report test failure + output. Do NOT skip failing test. |
| Coverage <80% | Report warning, continue to Verify phase (will be flagged). |
| Syntax error in modified file | STOP. Report error. Do NOT attempt fix outside plan. |
| Merge conflict (git apply) | STOP. Report conflict. Do NOT resolve manually. |

---

## Integration Points

- **Input**: `.sdlc/rpi/{story-id}/plan.md` (+ approval marker)
- **Output**: Modified files (staged), test output
- **Gate**: Human approval of staged changes
- **Next phase**: `/project:rpi-verify AB#{story-id}` (after approval)

---

## Example Execution Trace

```
$ sdlc rpi implement US-1234
Loading plan... OK
Verifying approval... OK (.approved-plan found)
Parsing file list from plan... 5 files identified

Implementing file 1/5: src/auth/AuthService.java
  Reading current state... OK (250 lines)
  Applying changes... OK (12 lines added)
  Verifying against plan... OK (matches diff)
  Staging... OK

Implementing file 2/5: src/config/SecurityConfig.java
  Reading current state... OK (150 lines)
  Applying changes... OK (8 lines added, 1 removed)
  Verifying against plan... OK (matches diff)
  Staging... OK

Implementing file 3/5: src/model/User.java
  Reading current state... OK (180 lines)
  Applying changes... OK (3 lines added)
  Verifying against plan... OK (matches diff)
  Staging... OK

Implementing file 4/5: db/schema/V003__add_oauth_columns.sql
  Creating new file... OK
  Applying changes... OK (10 lines)
  Verifying against plan... OK (matches diff)
  Staging... OK

Implementing file 5/5: src/test/AuthServiceTest.java
  Reading current state... OK (450 lines)
  Applying changes... OK (25 lines added)
  Verifying against plan... OK (matches diff)
  Staging... OK

Running tests...
  test_login_withOAuthProvider_success... PASS
  test_login_withOAuthProvider_timeout... PASS
  test_userData_mergedFromProvider_correctEmail... PASS
  All 11 tests PASSED

Checking coverage...
  Line: 82% (target 80%) ✓
  Branch: 78% (target 70%) ✓
  Conditional: 75% (target 65%) ✓

Generating diff summary...
  58 lines added
  1 line removed
  11 lines modified

STATUS: READY FOR REVIEW
All changes staged. Awaiting human approval to proceed to Verify phase.
```

---

**Last Updated**: 2026-04-11  
**Part of**: RPI Workflow (rules/rpi-workflow.md)
