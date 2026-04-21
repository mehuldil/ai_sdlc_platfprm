# RPI Plan — Strategy Lock

**Model:** Claude 3.5 Opus | **Trigger:** `sdlc rpi plan <story-id>` or `/project:rpi-plan AB#<id>`

---

## What It Does

This skill executes Phase 2 of the RPI workflow: detailed planning and design lock. It consumes only research.md and produces a line-by-line implementation plan.

1. Load `.sdlc/rpi/{story-id}/research.md` — ABORT if not found
2. Verify human approved research (check `.sdlc/rpi/{story-id}/.approved-research` marker)
3. For each file in scope: specify exact modifications with diff format
4. Plan tests: what to add/modify, expected coverage targets
5. Plan rollback: explicit undo strategy per file
6. Output `.sdlc/rpi/{story-id}/plan.md` and STOP for human review

---

## Execution Steps

### Step 1: Load & Verify Research

```bash
# Read research file
research_file=".sdlc/rpi/${story_id}/research.md"
if [ ! -f "$research_file" ]; then
  echo "ERROR: research.md not found. Run 'sdlc rpi research' first."
  exit 1
fi

# Check approval marker
if [ ! -f ".sdlc/rpi/${story_id}/.approved-research" ]; then
  echo "ERROR: Research not approved. Waiting for human approval."
  exit 1
fi
```

**Stop immediately if either check fails.**

### Step 2: Read Codebase for Each File

For each file listed in research.md:
```bash
# Read full current state of file
git show HEAD:{filepath}  # or cat {filepath} if not in git

# Identify lines to modify based on research context
# Create line-range mappings
```

### Step 3: Specify Line-Level Changes

For EACH file, create diff showing:
- Current lines (with line numbers)
- Proposed lines (with explanations)
- Why each change is needed
- Dependencies on other file changes

Use unified diff format:
```diff
--- a/path/to/file.java
+++ b/path/to/file.java
@@ -45,3 +45,6 @@
  existing line 45
  existing line 46
  existing line 47
+ new line 48 (reason: add validation)
```

### Step 4: Plan Tests

Identify tests to:
- **Add**: New test methods covering new behavior
- **Modify**: Existing tests that need updates (because API changed)
- **Delete**: Any tests no longer applicable

For each test:
- Test name (follow convention: `test_<method>_<scenario>_<expected>`)
- Scenario being tested (GIVEN/WHEN/THEN)
- What assertions are expected
- How it maps to AC from story

### Step 5: Plan Rollback

For each file, document:
- **Rollback approach**: How to undo changes (git revert, config rollback, migration rollback)
- **Duration**: How long the rollback takes
- **Prerequisites**: What must be true before rollback (no active transactions, etc.)
- **Verification**: Health checks after rollback

Identify **critical path**: dependencies between rollbacks (File A must revert before File B can revert).

### Step 6: Lock Scope

Create explicit "Out of Scope" section listing:
- Items mentioned in comments but not included
- Why they're excluded
- Which story (if any) will handle them later

---

## Output Format

Create `.sdlc/rpi/{story-id}/plan.md`:

```markdown
# Implementation Plan: {story-title}

## Story Reference
- **ID**: {story-id}
- **Type**: Feature / Bug / Refactor
- **Research Approved**: {date}
- **Approved By**: {person or "Human via AI-SDLC"}
- **Scope**: {From research.md}

## Files in Scope
{List all files to modify, from research.md}

---

## File-by-File Implementation

### File 1: {path/to/file.java}

**Current State**:
- **Lines**: {total line count}
- **Purpose**: {What this file does}
- **Current behavior**: {2-3 sentence summary}

**Why This File Changes**:
{From research.md, explain why this file is impacted}

**Modifications**:

#### Change Set 1: {Description}
```diff
--- a/{path}
+++ b/{path}
@@ -45,5 +45,8 @@
   // existing code line 43
   // existing code line 44
   // existing code line 45
+ // new line 46: {reason}
+ String newField = validate(input);
+ if (newField == null) throw new ValidationException();
```

**Line-by-line explanation**:
| Line | Old → New | Reason |
|------|-----------|--------|
| 46 | (new) | Add validation check |
| 47 | (new) | Set field from validated input |
| 48 | (new) | Throw error if validation fails |

**Impact**:
- Callers of this method will now get ValidationException if input is invalid
- Test {test_name} will break and needs update

#### Change Set 2: {Description}
{Repeat diff format for each logical change in the file}

**Total changes to {file}**: {N} lines added, {N} lines removed, {N} lines modified

---

### File 2: {path/to/file.kt}
{Repeat above section}

---

## Test Plan

### New Tests to Add

| Test Name | Test Class | Scenario | Given | When | Then | Maps to AC |
|---|---|---|---|---|---|---|
| test_login_withOAuthProvider_success | AuthServiceTest | Happy path | User redirects to OAuth provider | User logs in successfully | User is authenticated, redirected to app | AC-01 |
| test_login_withOAuthProvider_timeout | AuthServiceTest | Timeout | OAuth provider times out | System waits >5s | Fallback to email login shown | Error case |
| test_userData_mergedFromProvider_correctEmail | UserMergeTest | Email merge | Two accounts with same email | OAuth login with existing email | Accounts merged, no duplicate | AC-02 |

### Tests to Modify

| Test Name | Current Assertion | Why Change | New Assertion | File |
|---|---|---|---|---|
| test_login_withEmailPassword | `user != null` | AuthService now returns provider info | `user != null && user.getProviderId() == null` | AuthServiceTest.java |
| test_userProfile_completeness | Checks 5 fields | New provider fields added | Checks 7 fields + provider info | UserProfileTest.java |

### Test Removal

| Test Name | Reason |
|---|---|
| (none) | No existing tests are obsoleted |

### Coverage Expectations

| Metric | Before | After | Target | Status |
|---|---|---|---|---|
| Line Coverage | 78% | 82% | ≥80% | PASS |
| Branch Coverage | 72% | 78% | ≥70% | PASS |
| Conditional Coverage | 68% | 75% | ≥65% | PASS |

**Coverage tool**: JaCoCo (Gradle plugin)  
**Coverage report location**: `build/reports/jacoco/test/html/index.html`

---

## Rollback Strategy

### Per-File Rollback

| File | Current Version | Rollback Approach | Estimated Time | Health Check |
|---|---|---|---|---|
| src/auth/AuthService.java | v1.2 | git revert commit {hash} | <1 min | AuthController health check |
| src/config/SecurityConfig.java | v1.1 | git revert commit {hash} | <1 min | OAuth2 health endpoint 404 |
| db/schema/users_table.sql | V003 | `./scripts/migrate.sh down` | 2 min | SELECT count(provider_id) returns error (column doesn't exist) |

### Rollback Critical Path

```
1. REVERT db migration first (V003 down)
   - Blocks other reversions until complete
2. REVERT SecurityConfig (must be before AuthService)
   - Depends on: Step 1 complete
3. REVERT AuthService (last)
   - Depends on: Step 2 complete
```

**Total rollback duration**: ~3-4 minutes (sequential)

### Post-Rollback Health Checks

After all reversions:
```bash
# Health endpoint should respond
curl http://localhost:8080/actuator/health → HTTP 200

# Database schema should not have provider columns
SELECT * FROM users LIMIT 1 → Error: column 'provider_id' not found

# No orphaned provider tokens
SELECT COUNT(*) FROM oauth_provider_tokens → Should be 0 or handle error gracefully

# Login endpoint still works (email/password only)
POST /api/auth/login body={email, password} → HTTP 200
```

### Rollback Assumptions

- Database has backup of pre-migration state
- Git history is intact (no force pushes between deploy and rollback)
- No oauth_provider_tokens table migration has cascading deletes
- Service is deployed via git commits (not direct file uploads)

---

## Out of Scope (Explicit)

| Item | Reason | Future Story |
|---|---|---|
| OAuth2 PKCE flow | Complexity beyond initial MVP; can add in follow-up | US-1235 |
| Multi-factor authentication | Out of scope; separate feature | US-1250 |
| Provider selection UI in mobile app | Frontend concern; depends on API contract only | US-1251 |
| Single sign-on (SSO) | Different protocol; future integration | Backlog |

**Why**: This story focuses on backend API + web UI. Mobile app and advanced OAuth flows are separate stories.

---

## Dependencies & Blockers

### Internal Dependencies

| Dependency | Status | Impact | Resolution |
|---|---|---|---|
| API Gateway must support redirect URLs | In progress (DevOps) | Cannot test end-to-end | Blocks implementation by 1 day (estimate) |
| Database migration framework working | Ready | Needed for schema changes | No blocker |

### External Dependencies

| Dependency | Status | Impact |
|---|---|---|
| Google OAuth2 Provider availability | Available | Must include timeout handling |
| GitHub OAuth2 Provider availability | Available | Must include timeout handling |

### Cross-Team Dependencies

| Team | What They Need | Status |
|---|---|---|
| Frontend | OpenAPI spec for /oauth/callback endpoint | Delivered in research phase |
| DevOps | Secrets rotation for OAuth client IDs | In progress |
| QA | Test provider accounts for testing | Will be set up by DevOps |

---

## Assumptions

| Assumption | Why | Risk |
|---|---|---|
| OAuth2 libraries are available in Maven | Standard JVM OAuth2 support | Low — widely available |
| Database migration tool supports rollback | Used in other migrations | Low — proven in codebase |
| User email is always present in OAuth2 scope | Assumed by design | Medium — some providers limit scope; mitigation: validation error |
| No existing provider_id usage in codebase | Searched in research phase | Low — confirmed in research |

---

## Sign-Off

- **Planner**: {AI model, e.g. "Claude 3.5 Opus"}
- **Date**: {ISO 8601, e.g. 2026-04-11T16:45:00Z}
- **Status**: READY FOR IMPLEMENTATION

---

**Next Step**: Human reviews plan, then approves or requests changes.  
**After approval**: `.sdlc/rpi/{story-id}/.approved-plan` marker created, proceed to Implement phase.  
**If changes requested**: Planner revises and re-outputs plan.md (no new file, same path).
```

---

## Rules & Constraints

### Scope Locking
- **Input is research.md ONLY** — no expansion beyond what was researched
- **No assumptions beyond research** — if not in research, ask human to update research
- **If scope too large**: Recommend story split (don't try to plan 15+ file changes)

### Line-Level Detail
- **Use unified diff format** — exactly what `git diff` would show
- **Specify line numbers** — before and after context
- **Explain each change** — why this line, what it does
- **Show dependencies** — "Change to file B depends on change to file A"

### Test Planning
- **Coverage is mandatory** — all new code must have tests
- **AC traceability** — each test maps to an AC
- **Follow convention** — `test_<method>_<scenario>_<expected>`
- **Expected failures** — if tests should fail, note why and what fixes them

### Rollback Safety
- **Every change must be reversible** — if not, reject the plan
- **Explicit critical path** — which reversions must happen first
- **Post-rollback health checks** — how to verify rollback succeeded
- **Document assumptions** — what must be true for rollback to work

### Out of Scope Section
- **Explicit list** — no ambiguity
- **Explain why** — justify each exclusion
- **Future reference** — link to new story if created for excluded item

### After Output
- **ALWAYS STOP** and wait for human approval
- **Do NOT proceed to Implement** until `.approved-plan` marker exists
- **Do NOT re-plan** after output; if changes needed, human requests revision
- Provide `.sdlc/rpi/{story-id}/plan.md` path for human to review

---

## Example Plan Section (Abbreviated)

```markdown
### File 1: src/auth/AuthService.java

**Current State**:
- Lines: 250
- Purpose: Handles authentication flows

**Modifications**:

#### Change Set 1: Add OAuth2Provider parameter
```diff
--- a/src/auth/AuthService.java
+++ b/src/auth/AuthService.java
@@ -50,5 +50,8 @@
   public LoginResponse login(String email, String password) {
     // existing implementation
   }
+
+  public LoginResponse login(OAuthProvider provider, String code) {
+    // new OAuth2 flow
+  }
```

**Test to add**: `test_login_withOAuthProvider_success`

**Rollback**: `git revert {commit-hash}` (~30 seconds)
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Research.md file not found | Abort; user must run research phase first |
| Research not approved | Abort; user must approve research first |
| Scope seems too large (>10 files) | Note in plan; recommend story split |
| Test coverage can't reach 80% | Document why in Coverage Expectations section |
| Rollback not possible | Flag as blocker; request different approach |

---

## Integration Points

- **Input**: `.sdlc/rpi/{story-id}/research.md` (+ approval marker)
- **Output**: `.sdlc/rpi/{story-id}/plan.md`
- **Gate**: `.sdlc/rpi/{story-id}/.approved-plan` (created by human)
- **Next phase**: `/project:rpi-implement AB#{story-id}` (after approval)

---

**Last Updated**: 2026-04-11  
**Part of**: RPI Workflow (rules/rpi-workflow.md)
