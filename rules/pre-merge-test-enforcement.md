# Pre-Merge Test Enforcement (C3)

## Core Principle

**Tests enforce, but not everything is testable.**

The pre-merge test enforcement hook validates that unit tests pass before allowing merge, but respects the reality that not all code can be unit tested (infrastructure, one-off scripts, temporary debugging, etc.). **Bypassing** tests is **not** self-service via `SDLC_SKIP_TESTS=1` alone: you must either use **`sdlc skip-tests --work-item=<id> --reason="…"`** (structured marker + ADO discussion on that work item) or **TPM/Boss approval** — see `hooks/test-bypass-escalation.sh`.

## Hook Behavior

### Stage 1: Project Type Detection

The hook examines the working directory for test framework indicators:

| Indicator File | Framework | Test Command |
|---|---|---|
| `pom.xml` | Java/Maven | `mvn test` |
| `build.gradle` / `build.gradle.kts` | Kotlin/Gradle | `gradle test` |
| `package.json` (with `react-native`) | React Native | `npm test` |
| `package.json` (plain) | Node.js/npm | `npm test` |
| `*.xcodeproj` | Swift/Xcode | `xcodebuild test` |
| `*.jmx` or `test-plans/` | JMeter | `jmeter -n -t test-plans/*.jmx` |
| None of above | Unknown | Skip (WARN) |

### Stage 2: Test Execution

If a framework is detected, the hook runs the appropriate test command:

- **Pass** → Tests all pass → **EXIT 0** (merge allowed)
- **Fail** → Tests fail → Continue to Stage 3

### Stage 3: Skip Decision

If tests fail, the hook checks for a skip decision:

#### Marker File
```bash
.sdlc/skip-tests-{branch}
```

Example:
```
.sdlc/skip-tests-main
.sdlc/skip-tests-feature/auth-refactor
```

#### Environment Variable (`SDLC_SKIP_TESTS=1`)

**Not sufficient.** The hook **rejects** merges that rely only on this variable. Use **`sdlc skip-tests`** (marker includes `work_item=<id>`) or a **TPM/Boss approval** file.

#### Result (aligned with `hooks/test-bypass-escalation.sh`)
- **Valid skip marker** (`work_item=<numeric-id>` in `.sdlc/skip-tests-<branch>`) → Log → WARN → **EXIT 0** (merge allowed)
- **`SDLC_SKIP_TESTS=1` alone** → **EXIT 1** (blocked)
- **TPM/Boss approval file** (`.sdlc/test-skip-approval-<branch>.json`) → **EXIT 0**
- **None of the above** → **EXIT 1** (blocked)

Use **`sdlc skip-tests`** when full unit-test coverage is not realistic for the change — it records the work item and triggers ADO discussion when credentials allow. Use **approval file** for exceptional merges where tests failed but leadership accepts risk.

### Stage 4: No Framework Detected

If no test framework is found:

```
[WARN] No test framework found
       Supported: Maven, Gradle, npm, xcodebuild, JMeter
       → MERGE ALLOWED (no enforcement)
```

**Audit expectation:** Teams should record **why** there is no unit-test harness for this path (e.g. pure docs, generated-only repo, or infrastructure). Add a short file such as **`.sdlc/no-test-framework-reason.md`** in the **app repo** with that rationale, or reference an ADR. This mirrors the requirement that **`sdlc skip-tests`** must include **`--reason=`** (minimum length) when intentionally bypassing tests.

## CLI Commands

### Create Skip Marker

```bash
sdlc skip-tests --reason="Infrastructure code, not unit testable"
```

This creates:
- `.sdlc/skip-tests-{branch}` (marker file)
- Entry in `.sdlc/memory/test-skips.log` (audit trail)

### View Skip History

```bash
sdlc show-test-skips
```

Shows all test skip decisions with timestamps, branches, users, and reasons.

### Clear Skip Marker

```bash
sdlc clear-test-skips [branch]
```

Removes the skip marker for a branch (defaults to current branch).

### Sync to ADO + Master Story (recommended)

When creating a skip marker, the CLI can post an **ADO Discussion** comment and append a **Test execution** section to your Master Story file:

```bash
sdlc skip-tests --reason="…" [--work-item=12345] [--master-story=docs/stories/master-xyz.md]
```

- **`--work-item`** — ADO id if auto-detection fails (otherwise uses `.sdlc/story-id`, branch `feature/AB#12345-*`, or last commit `AB#`).
- **`--master-story`** — path to Master Story `.md` (otherwise uses one line in `.sdlc/memory/active-master-story.path`).
- Also appends **`.sdlc/memory/branch-test-skip.md`** and **`tracing-log.md`** (if present).

## Skip Log Format

File: `.sdlc/memory/test-skips.log`

```
--- Test Skip Record ---
Timestamp: 2026-04-13T15:42:30Z
Branch: feature/db-migration
User: alice@company.com
Reason: Infrastructure code, not unit testable

--- Test Skip Record ---
Timestamp: 2026-04-13T14:21:15Z
Branch: hotfix/security-patch
User: bob@company.com
Reason: Emergency patch, tests will be added in follow-up story

```

## Merge Flow

```
Pre-merge trigger (git hook or CI/CD)
    ↓
Detect project type
    ↓
    ├─→ [No framework] → WARN, allow merge, exit 0
    │
    └─→ [Framework found] → Run tests
        ├─→ [Tests pass] → Allow merge, exit 0
        │
        └─→ [Tests fail]
            ├─→ [Valid skip marker with work_item=] → WARN, log, allow merge, exit 0
            ├─→ [TPM/Boss approval JSON] → Log, allow merge, exit 0
            └─→ [SDLC_SKIP_TESTS=1 only / invalid marker / none] → BLOCK merge, exit 1
```

## Usage Examples

### Example 1: Normal Flow (Tests Pass)

```bash
$ git merge feature/new-api
# Pre-merge hook runs
[INFO] Branch: main
[INFO] Project Type: java-maven
[INFO] Running Maven tests...
[✓] All tests passed!
# Merge proceeds
```

### Example 2: Test Failure with Skip

```bash
$ git merge feature/infra-update
# Pre-merge hook runs
[INFO] Branch: main
[INFO] Project Type: kotlin-gradle
[INFO] Running Gradle tests...
[✗] Tests FAILED
[WARN] Tests skipped by user decision
[✓] Merge allowed with test skip

# Or using CLI:
$ sdlc skip-tests --reason="Infrastructure changes, tests will be added in US-1234"
[✓] Test skip marker created: .sdlc/skip-tests-main
[✓] Skip logged to: .sdlc/memory/test-skips.log
```

### Example 3: Test Failure, No Skip (Blocked)

```bash
$ git merge feature/api-refactor
# Pre-merge hook runs
[INFO] Branch: feature/api-refactor
[INFO] Project Type: node-npm
[INFO] Running Node.js tests...
[✗] Tests FAILED
[✗] Merge BLOCKED: Tests failed and no skip marker found

[INFO] To allow merge despite failed tests, create a skip marker:
  Option 1: Use CLI command (recommended)
    sdlc skip-tests --reason="<reason>"
  
  Option 2: Create marker file manually
    mkdir -p .sdlc
    touch .sdlc/skip-tests-feature/api-refactor
  
  Option 3: TPM/Boss approval JSON (see hook output)
```

## Audit Trail

All skip decisions are logged to `.sdlc/memory/test-skips.log` for compliance:

```bash
$ sdlc show-test-skips
[...git sync to remote...]
# Log entries persist in version control
```

The log includes:
- Timestamp (ISO 8601)
- Branch name
- User (from git config)
- Reason (from `--reason` flag or "User decision")

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Pre-merge test enforcement
  run: bash .claude/hooks/pre-merge-tests.sh
```

### Azure DevOps Example

```yaml
- script: bash hooks/test-bypass-escalation.sh
  displayName: Test bypass policy (marker + ADO / TPM approval)
  # Do not use continueOnError: true to bypass mandatory unit-test policy without team approval.
```

## Design Rationale

### Why Conditional Pass?

Not all code is unit testable:
- Infrastructure automation (Terraform, scripts)
- One-off migration tools
- Temporary debugging/troubleshooting code
- Third-party integrations with side effects
- Configuration changes

Rather than give up on test enforcement entirely, C3 enforces where tests exist and respects explicit skip decisions with audit trails.

### Why Marker File?

- **Explicit**: Requires deliberate action (not just a forgotten env var)
- **Auditable**: Marker files are committed or at least logged
- **Branch-scoped**: Different branches can have different skip decisions
- **Reversible**: Can be cleared anytime with `sdlc clear-test-skips`

### Why Log to Memory?

- **Compliance**: All skip decisions persist in version control
- **Visibility**: Team can review via `sdlc show-test-skips`
- **Traceability**: Timestamp, user, reason all captured
- **Integration**: Stored in `.sdlc/memory/` which syncs with git

## See Also

- `hook:pre-commit.sh` — Secrets and formatting checks
- `hook:enforce-g4.sh` — Architecture & design validation (advisory)
- `hook:enforce-rpi.sh` — RPI workflow recommendation (advisory)
- `rules/gate-enforcement.md` — Full gate validation protocol
