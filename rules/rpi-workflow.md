# RPI Workflow — Research, Plan, Implement with Verification

**Governance:** AI-SDLC Platform v2.0+  
**Goal:** Serialize complex tasks into strict phases with human gates to prevent hallucination and scope creep.  
**Improvement over Claude's RPI:** Added Verify phase post-Implement for implementation-vs-plan validation.

---

## Core Principle: RPI Serialization

Complex tasks must flow through four sequential phases, each with human checkpoint gates:

```
Research (read-only) → [Human: APPROVED?] → 
Plan (design-only) → [Human: APPROVED?] → 
Implement (execute plan strictly) → [Human: APPROVED?] →
Verify (validate vs plan) → [Human: PASS?] →
Complete
```

**Key rule:** Each phase consumes ONLY its predecessor's output. No deviation. No scope expansion.

---

## When to Use RPI vs Direct Execution

### Use RPI (Full 4-Phase Flow) — high-ambiguity, high-blast-radius work
- `NEW_FEATURE`: Add new capability spanning **>3 files AND >1 module contract** (api/data/events)
- `REFACTOR`: Restructure code or architecture, **>3 files** AND spans ≥2 packages
- `BUG_FIX`: Complex bug involving cross-service logic or data migration

### Use Direct Execution (ASK → PLAN → IMPLEMENT) — low-ambiguity work
- `HOTFIX`: P0 emergency fix, 1-2 files, skip design phases
- `CONFIG_CHANGE`: Configuration-only, no code changes
- `UI_TWEAK`: UI/styling change, <2 files
- **Additive API change**: New field/endpoint only, no consumer break (covered by module contracts)
- **Test-only change**: Adding tests to existing code with no behavior change
- **Docs-only change**: No code change

**Token guardrail (v2.1.2):** RPI Research + Plan costs 9-15K. Before invoking, ask: *does the work item meet the strict RPI threshold above?* If no, use direct execution. Over-invocation of RPI is the single largest token waste pattern observed.

**Route decision:** Smart Routing agent (see `agents/shared/smart-routing.md`) classifies task and recommends RPI vs direct. Dimension 8 of code review (story-AC verification) also flags RPI used on sub-threshold work as scope creep.

---

## Phase 1: Research (Scope Isolation)

**Model:** Sonnet 4.6  
**Duration:** 5-15 minutes  
**Output:** `.sdlc/rpi/{story-id}/research.md`  
**Gate:** Human reviews research findings and approves scope.

### What Happens
1. **Fetch ADO work item**: Extract title, description, acceptance criteria (AC), tags
2. **Codebase search**: Identify max 10 relevant files; extract max 2K chars per file
3. **Wiki.js lookup**: Find architecture docs, API specs, known constraints
4. **Risk identification**: Document edge cases, breaking changes, cross-service dependencies
5. **Token budget estimation**: Forecast tokens needed for Plan + Implement phases

### Output Format
```markdown
# Research Summary: {story-title}

## Story Context
- **ID**: US-XXXX
- **Type**: Feature / Bug / Refactor
- **Route**: NEW_FEATURE / BUG_FIX / CONFIG_CHANGE
- **Scope**: {brief scope statement}

## Problem Statement
{What needs to be done, why}

## Relevant Codebase Context
### Files to Modify (max 10)
- Path: {path}
  - Current: {current behavior, max 2K chars}
  - Location: Line {n}-{m}
- ...

### Key Patterns & Conventions
{Architectural patterns found in codebase}

## Wiki Context
### Architecture Documents
- {Wiki page title}: {Link}
  - Relevant section: {summary}

### API / Service Contracts
- {Contract name}: {Link}
  - Version: {version}
  - Impact: {how it affects this story}

### Known Constraints
- {Constraint 1}
- {Constraint 2}

## Dependencies & Cross-Team Impact
### Internal Dependencies
- Service A: {Impact}
- Database: {Impact}

### External Dependencies
- {External service/API}: {Impact}

### Affected Teams
- Backend team: {Why}
- Frontend team: {Why}

## Risk Assessment
### Edge Cases & Error Scenarios
- Scenario 1: {Description} → Mitigation: {How to handle}
- Scenario 2: {Description} → Mitigation: {How to handle}

### Breaking Changes
- {Change 1}: {Impact}
- {Change 2}: {Impact}

### Performance Implications
- {Implication 1}
- {Implication 2}

## ADO Comments & Extended Discussion
{Summary of comments in work item thread; extended requirements}

## Token Budget Forecast
- **Research→Plan**: ~3-5K tokens (Opus depth reasoning)
- **Plan→Implement**: ~6-10K tokens (file-by-file execution)
- **Verify phase**: ~2-3K tokens (diff validation)
- **Total estimated**: {X}K tokens

## Recommended Approach
{Brief summary of recommended implementation strategy}

## Sign-Off
- Researcher: {AI model used}
- Date: {ISO 8601}
- Status: READY FOR REVIEW
```

### Rules
- **Max 10 files** in scope — if more, escalate for split stories
- **No code changes** — read-only phase only
- **No planning** — only document what exists
- **Wiki lookup MANDATORY** — architecture context required
- **After output:** STOP and wait for human approval before proceeding to Plan

### Gate Criteria (Human Decides)
1. Is scope clear and bounded?
2. Are all relevant files identified?
3. Are wiki/architecture dependencies documented?
4. Are risks and edge cases identified?
5. Is token forecast reasonable?

**Human options:**
- (1) Approve research → Proceed to Plan
- (2) Request changes → Researcher revises
- (3) Split into smaller stories → Create multiple RPI sequences

---

## Phase 2: Plan (Strategy Lock)

**Model:** Opus 4.6 (deep reasoning for line-level planning)  
**Duration:** 15-30 minutes  
**Input:** `.sdlc/rpi/{story-id}/research.md` ONLY — scope is locked  
**Output:** `.sdlc/rpi/{story-id}/plan.md`  
**Gate:** Human reviews plan granularity and approves implementation strategy.

### What Happens
1. **Load research.md** — ABORT if not found or not `.approved-research`
2. **For each file in scope**: Specify exact modifications using diff format
3. **Plan tests**: What tests to add/modify, expected coverage targets
4. **Plan rollback**: Explicit undo strategy per file
5. **Scope lock**: Document out-of-scope items explicitly

### Output Format
```markdown
# Implementation Plan: {story-title}

## Story Reference
- **ID**: US-XXXX
- **Research approved**: {date}
- **Approved by**: {person name}

## Files in Scope
{List files from research.md}

## File-by-File Modifications

### File 1: {path}
**Current state**: {2-3 line description of current code}
**Reason for change**: {Why this file must change}

**Modifications**:
```diff
--- a/{path}
+++ b/{path}
@@ -{line-start},{line-count} +{line-start},{line-count} @@
- old line 1
- old line 2
+ new line 1
+ new line 2
```

**Line-level changes**:
| Line Range | Description | Type |
|---|---|---|
| 45-48 | Add null check for user object | Safety |
| 67-72 | Update query to fetch new columns | Feature |

**Impact**: {What depends on this change}

### File 2: {path}
{Repeat above section for each file}

## Test Plan

### New Tests to Add
| Test Name | Scenario | Assertion | Coverage Impact |
|---|---|---|---|
| test_userLogin_withOTP_success | Happy path | Token returned | AC-01 |
| test_userLogin_withInvalidOTP_error | Error case | Error message shown | AC-E01 |

### Tests to Modify
| Test Name | Change | Reason |
|---|---|---|
| test_phoneVerification_existing | Update expected fields | New field added in response |

### Expected Coverage
- **Before**: {X}%
- **After**: {Y}%
- **Target**: ≥80%

## Rollback Strategy

### Per-File Rollback
| File | Rollback Approach | Duration |
|---|---|---|
| {file1} | Git revert + run migration rollback | 2 min |
| {file2} | Config change revert | <1 min |

### Critical Path
- {file1} must be reverted first (dependency)
- {file2} then {file3} can be reverted in parallel

### Health Checks Post-Rollback
- API health endpoint returns 200
- Database connections stable
- No orphaned records in {table_name}

## Out of Scope (Explicit)
- {Item 1}: Reason it's out of scope
- {Item 2}: Link to new story if created

## Dependencies & Blockers
- {Dependency 1}: Status
- {Blocker 1}: Resolution status

## Assumptions
- {Assumption 1}: {Why assumed}
- {Assumption 2}: {Why assumed}

## Sign-Off
- Planner: {AI model used}
- Date: {ISO 8601}
- Status: READY FOR IMPLEMENTATION
```

### Rules
- **Input is research.md ONLY** — scope is locked, no expansion
- **No code changes** — plan document only
- **Abort if research not approved** — check `.approved-research` file
- **Line-level detail** — use diff format, specify exact line ranges
- **Explicit scope boundaries** — "Out of Scope" section is mandatory
- **After output:** STOP and wait for human approval

### Gate Criteria (Human Decides)
1. Is plan detailed enough to follow without judgment calls?
2. Are all AC from story covered by plan?
3. Are tests adequate for story scope?
4. Is rollback strategy clear and safe?
5. Is there any scope creep vs research.md?

**Human options:**
- (1) Approve plan → Proceed to Implement
- (2) Request changes → Planner revises
- (3) Split implementation → Create multiple RPI sequences

---

## Phase 3: Implement (Strict Execution)

**Model:** Sonnet 4.6 (best coder, follows plans precisely)  
**Duration:** Varies by plan size (typically 30 mins - 2 hours)  
**Input:** `.sdlc/rpi/{story-id}/plan.md` ONLY  
**Output:** Modified files, test results, git diff  
**Gate:** Human validates all changes were implemented, no more, no less.

### What Happens
1. **Load plan.md** — ABORT if not found or not `.approved-plan`
2. **Execute changes file-by-file**, in order listed in plan
3. **Run tests** specified in plan section
4. **Generate diff summary** showing what was changed vs plan

### Rules
- **Input is plan.md ONLY** — no deviations, no judgment calls
- **Zero deviations** — implement exactly what plan says, no improvements
- **If blocked:** STOP immediately and report. Do NOT improvise or skip.
- **One file at a time** — verify each before proceeding to next
- **Do NOT commit** — leave staged for human review
- **If plan incomplete:** Do NOT fill gaps; report and STOP

### Execution Checklist
```
[ ] Load plan.md and verify approval
[ ] Review file list from plan
[ ] For each file:
    [ ] Read current state (git show <file>)
    [ ] Apply exact changes from plan (line-level diffs)
    [ ] Verify changes match plan diff
    [ ] Stage file (git add)
[ ] Run test suite from plan
[ ] Capture test output
[ ] Generate git diff: `git diff --cached`
[ ] Report: "Plan executed. Review staged changes before commit."
```

### Post-Implementation Output
```markdown
# Implementation Summary: {story-id}

## Files Modified
- {file1}: {lines changed}
- {file2}: {lines changed}

## Test Results
{Test output summary}

## Staged Changes
{git diff --cached output, first 100 lines}

## Status
READY FOR REVIEW — All changes staged, awaiting human approval.
```

### Gate Criteria (Human Decides)
1. Does every planned change appear in git diff?
2. Are there any unplanned changes in git diff?
3. Do all tests pass?
4. Is test output as expected?

**Human options:**
- (1) Approve implementation → Proceed to Verify
- (2) Request changes → Implementer revises (stay in Implement phase)
- (3) Abort → Revert staged changes, return to Plan phase

---

## Phase 4: Verify (Implementation Validation) — NEW

**Model:** Sonnet 4.6  
**Duration:** 10-15 minutes  
**Input:** plan.md + actual git diff (staged changes)  
**Output:** `.sdlc/rpi/{story-id}/verify.md`  
**Gate:** Human confirms implementation matches plan exactly.

### What Happens
1. **Load plan.md** and **compare against actual git diff** (staged)
2. **Check completeness**: Every planned change is in actual diff
3. **Check scope**: No unplanned changes (scope creep detection)
4. **Validate tests**: All planned tests run and pass
5. **Coverage check**: Implementation maintains ≥80% coverage
6. **Output verification report** with pass/fail per planned item

### Output Format
```markdown
# Verification Report: {story-id}

## Implementation Completeness

### Planned vs Actual Comparison
| File | Planned Changes | Actual Changes | Status |
|---|---|---|---|
| {file1} | Add lines 45-48, Remove line 50 | FOUND in diff | PASS |
| {file2} | Modify lines 10-15 | FOUND in diff | PASS |

### Missing Changes
| File | Planned Change | Status |
|---|---|---|
| {file1} | Update docstring | NOT FOUND — FAIL |

### Unplanned Changes (Scope Creep Detection)
| File | Change | Plan Allowed? | Status |
|---|---|---|---|
| {file1} | Refactored helper function | NO — FAIL |
| {file3} | Added new import | Was this in plan? CHECK |

## Test Validation

### Planned Tests
| Test | Status | Output |
|---|---|---|
| test_userLogin_withOTP_success | PASS | ✓ |
| test_userLogin_withInvalidOTP_error | PASS | ✓ |

### Test Coverage
- **Planned target**: ≥80%
- **Actual coverage**: {X}%
- **Status**: PASS / FAIL

## Detailed Verification

### File 1: {path}
- Planned: Add validation check at line 45
- Actual diff: `+ if (!user.valid()) { throw new Error(...) }`
- Status: MATCHES PLAN ✓

### File 2: {path}
- Planned: Modify query to fetch columns [col1, col2, col3]
- Actual diff: `SELECT col1, col2, col3 FROM users`
- Status: MATCHES PLAN ✓

## Summary

**Overall Status**: PASS / FAIL

### If PASS:
- All planned changes implemented
- No scope creep detected
- Tests pass
- Coverage maintained
- **Ready to commit and merge**

### If FAIL:
- Missing implementations: {list}
- Unplanned changes: {list}
- Test failures: {list}
- Coverage gaps: {list}
- **Action**: Return to Implement phase or plan revision

## Sign-Off
- Verifier: {AI model used}
- Date: {ISO 8601}
- Status: VERIFIED / BLOCKED
```

### Rules
- **Load plan.md** and actual git diff only
- **Line-by-line comparison** — ensure plan matches reality
- **Scope creep detection** — flag unplanned changes immediately
- **Test validation** — must match planned test output
- **Coverage enforcement** — ≥80% minimum, else FAIL
- **After output:** Present findings to human; wait for go/no-go

### Gate Criteria (Human Decides)
1. Is every planned change in the actual diff?
2. Are there any unplanned changes? (If yes: scope creep)
3. Do all tests pass as expected?
4. Is coverage ≥80%?
5. Are there any anomalies or inconsistencies?

**Human options:**
- (1) PASS — Changes match plan exactly → Commit
- (2) FAIL — Issues found → Return to Implement or Plan
- (3) CONDITIONAL PASS — Accept with documented deviations (log reason)

---

## Integration with Smart Routing

**Routing agent workflow:**
```
1. User task input
2. Smart Routing classifies: NEW_FEATURE / BUG_FIX / HOTFIX / CONFIG_CHANGE / REFACTOR / UI_TWEAK
3. If NEW_FEATURE or REFACTOR (>3 files) or BUG_FIX (complex):
   → Recommend RPI workflow
   → User approves → sdlc rpi research <story-id>
4. Otherwise:
   → Recommend direct execution (ASK → PLAN → IMPLEMENT)
```

See: `agents/shared/smart-routing.md`

---

## File Organization

RPI workflow files are stored in `.sdlc/rpi/{story-id}/`:

```
.sdlc/rpi/
├── US-1234-phone-auth/
│   ├── research.md                    # Phase 1 output
│   ├── .approved-research             # Gating marker (human approval)
│   ├── plan.md                        # Phase 2 output
│   ├── .approved-plan                 # Gating marker (human approval)
│   └── verify.md                      # Phase 4 output
├── US-1235-otp-resend/
│   └── ...
```

**Markers**: Files named `.approved-*` are empty markers indicating human approval at each gate.

---

## Token Budgeting for RPI

### Tier 1: Research (Sonnet, ~400 tokens input max)
```
INPUT:
- Story ID + AC (50 tokens)
- Codebase context (200 tokens max)
- Wiki docs (100 tokens max)
OUTPUT:
- research.md (300-500 tokens)
TOTAL: ~3-5K tokens
```

### Tier 2: Plan (Opus, ~1K tokens input)
```
INPUT:
- research.md (500 tokens)
- Archive of codebase files (500 tokens max)
OUTPUT:
- plan.md with line-level diffs (2-3K tokens)
TOTAL: ~6-10K tokens
```

### Tier 3: Implement (Sonnet, ~2K tokens input)
```
INPUT:
- plan.md (500 tokens)
OUTPUT:
- Modified files (3-5K tokens)
- Test output (500 tokens)
TOTAL: ~6-10K tokens
```

### Tier 4: Verify (Sonnet, ~1K tokens input)
```
INPUT:
- plan.md (500 tokens)
- git diff (500 tokens max)
OUTPUT:
- verify.md (500-1K tokens)
TOTAL: ~2-3K tokens
```

**Total RPI sequence**: ~17-28K tokens (within daily budget of 50K)

---

## Model Selection Summary

| Phase | Model | Why | Token Efficiency |
|-------|-------|-----|------------------|
| **Research** | Sonnet 4.6 | Fast codebase comprehension | Read-only, bounded scope |
| **Plan** | Opus 4.6 | Deep reasoning for architecture | Line-level planning requires depth |
| **Implement** | Sonnet 4.6 | Best coder, strict adherence | Execute plan, no creativity |
| **Verify** | Sonnet 4.6 | Diff validation, pattern matching | Comparison task, no reasoning |

---

## Enforcement & Guardrails

### Pre-Tool Hooks
- **enforce-rpi.sh**: Block file writes if RPI required but not planned
- **enforce-gates.sh**: Block ADO writes if blocking gate tags present
- **check-ado-tag.sh**: Two-tier gate enforcement (blocking vs prerequisite tags)

See: `hooks/enforce-*.sh`

### CLI Commands
```bash
sdlc rpi research <story-id>          # Start Phase 1
sdlc rpi plan <story-id>              # Start Phase 2
sdlc rpi implement <story-id>         # Start Phase 3
sdlc rpi verify <story-id>            # Start Phase 4
sdlc rpi status <story-id>            # Show current phase
```

See: `cli/lib/executor.sh` (cmd_rpi function)

---

## Exceptions & Overrides

### When RPI Can Be Skipped
- P0 emergencies: HOTFIX with clear scope (1-2 files)
- Configuration-only changes: No code modifications
- UI tweaks: Styling/text only, <2 files

**Override process:**
1. User explicitly requests: "Skip RPI for {reason}"
2. Log decision in ADO comment with justification
3. Execute direct ASK → PLAN → IMPLEMENT workflow instead

### When Phases Can Be Abbreviated
- Research too large (>15 files): Split into multiple stories
- Plan missing detail: Planner revises, do not proceed to Implement
- Verification fails: Return to Implement; no forced-through passes

---

## Example RPI Sequence

**Story:** US-1234 (Implement OAuth2 provider integration)

```
DAY 1, 9:00 AM:
→ sdlc rpi research US-1234
  Output: research.md (Codebase: 5 files identified, Wiki: 3 docs, Risks: 2 noted)
  Status: READY FOR REVIEW

DAY 1, 10:00 AM (Human reviews):
→ Researcher approves, creates .approved-research
→ sdlc rpi plan US-1234
  Output: plan.md (5 files, 47 line-level changes, 8 new tests)
  Status: READY FOR REVIEW

DAY 1, 11:00 AM (Human reviews):
→ Planner approves, creates .approved-plan
→ sdlc rpi implement US-1234
  Output: 5 files modified, 8 tests pass, staged changes ready
  Status: READY FOR REVIEW

DAY 1, 12:00 PM (Human reviews):
→ Implementer approves
→ sdlc rpi verify US-1234
  Output: verify.md (All 47 changes found, 0 scope creep, 83% coverage)
  Status: VERIFIED ✓

→ Human commits and merges
```

---

## Comparison: RPI vs Claude's Original

| Feature | Claude | SDLC Platform |
|---------|--------|---------------|
| **Phases** | Research → Plan → Implement | Research → Plan → Implement → **Verify** |
| **Verification** | Manual review only | Automated diff validation + manual sign-off |
| **Scope creep detection** | Manual inspection | Structured comparison: Planned vs Actual |
| **Coverage enforcement** | Advisory | Enforced: ≥80% minimum |
| **Rollback strategy** | Documented in Plan | Explicit per-file + critical path |
| **Test coverage** | Listed in Plan | Planned + Actual coverage comparison |
| **Gate markers** | Comments | File-based (.approved-*) gates |
| **Token tracking** | Manual | Forecasted in research.md |

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-11 | Initial RPI specification with Verify phase |

**Governed By:** AI-SDLC Platform  
**Owner:** SDLC Platform Team  
**Last Updated:** 2026-04-11
