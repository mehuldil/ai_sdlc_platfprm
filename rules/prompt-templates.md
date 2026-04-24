# Compressed Prompt Templates

Use these templates for common operations. Each template is optimized for token efficiency and clarity.

---

## 1. Stage Execution Prompt

**Use when:** Running a stage with `sdlc run <stage>`

```
Role: {role} | Stack: {stack} | Stage: {stage}
Story: {story_id} | Route: {route_type} | Gate: {gate_depth}
Memory: {last_stage_completion_file}
---
Execute {stage} per STAGE.md.

Input summary:
- Story context: See {story_path}
- Previous output: See {memory_path}

Output required:
{expected_output_list}

Gate validation:
- AC checklist: {ac_refs}
- Review with: {stakeholder}
```

**Example:**
```
Role: Backend | Stack: java | Stage: 03-system-design
Story: US-1234 | Route: NEW_FEATURE | Gate: FULL
Memory: .sdlc/memory/02-prd-review-completion.md
---
Execute system design per stages/03-system-design/STAGE.md.

Input: PRD from stage 02, acceptance criteria (AC-01 to AC-06)
Output: Design doc, data model, API spec, deployment strategy

Gate validation:
- Architecture approved by tech lead
- All APIs documented (OpenAPI format)
```

---

## 2. Story Generation Prompt

**Use when:** Creating Master or Sprint stories

```
Mode: {master|sprint|tech-task}
Epic: {epic_id} | Feature: {feature_summary}
Template: {template_path}
Persona: {persona_name}
---
Generate {mode} story per template. Follow sections §{n}-§{m}.

Input constraints:
- PRD section: {prd_ref} OR Feature description: {feature_desc}
- Scope: {scope_definition}
- Capacity: {points_or_hours}

Rules applied:
- {rule_1} (e.g., One success metric per story)
- {rule_2} (e.g., AC must be independently testable)

Output validation:
- Metadata complete (§1): {fields}
- Success metric defined (§2): {metric_format}
- All AC states covered (§9): No data, Loading, Success, Error, No connection
```

**Example (Master Story):**
```
Mode: master
Epic: ONBOARD | Feature: Phone-based authentication
Template: /templates/master-user-story-template.md
Persona: New user on iOS
---
Generate master story per template sections §1-§16.

Input: PRD sections 4B + 4C (Authentication)
Scope: Phone entry + OTP + Profile setup
Rules: JTBD format, one success metric, problem-first

Output validation:
- Metadata: Sprint breakdown included
- ACs: All 5 states covered, AC-01 to AC-E02
```

**Example (Sprint Story):**
```
Mode: sprint
Epic: ONBOARD | Feature: Phone-based authentication
Template: /templates/sprint-user-story-template.md
Persona: New user on iOS
---
Generate sprint story from Master ONBOARD-AUTH.

Input: Master story ID + Sprint 12 scope
Scope: Phone entry + OTP happy path only (exclude resend + errors)
Capacity: 5 story points
Rules: Subset of Master ACs, include tasks (BE/FE/QA)

Output validation:
- ACs: AC-01 to AC-06 + AC-E01 (happy path only)
- Tasks: 8 items with estimates + owners
```

---

## 3. Code Review Prompt

**Use when:** Reviewing PRs or architecture

```
PR: {pr_id} | Files: {file_count}
Stack: {stack} | Variant: {variant}
Focus: {security|perf|logic|style|all}
---
Review {file_count} files per stage 09 (Code Review).

Review checklist:
- Logic correctness: Match AC from {story_id}
- Code style: Per {variant}.md conventions
- Performance: No N+1 queries, caching strategy
- Security: Input validation, SQL injection, auth checks
- Testing: Unit test coverage >70%

Output format:
| File | Issue | Severity | Blocker? | Fix |
|------|-------|----------|----------|-----|
| ... | ... | ... | ... | ... |

Blocking issues: Flag YES for PR hold.
Suggestions: Flag NO for future sprint.
```

**Example:**
```
PR: 2456 | Files: 5
Stack: java | Variant: java-backend
Focus: security
---
Review 5 files for security gaps.

Checklist:
- SQL injection: Parameterized queries?
- Auth: Token validation on every endpoint?
- Data exposure: No PII in logs?
- Input validation: All fields sanitized?

Output: Table format with blocked/suggested fixes.
```

---

## 4. ADO Create Prompt

**Use when:** Creating work items in Azure DevOps

```
Type: {work_item_type: Epic|Feature|User Story|Task|Bug}
Title: {title}
Parent: {parent_id}
Stack: {stack}
Fields: {field_json}
---
Create ADO work item.

Field mapping:
- Title: {title}
- Description: {description_brief}
- Acceptance Criteria: {ac_refs}
- Story Points: {sp}
- Tags: {tag_list}
- Team: {team}

Return:
- Work Item ID
- ADO URL
- Created timestamp
```

**Example:**
```
Type: User Story
Title: US-1234 | Phone verification (Sprint 12)
Parent: ONBOARD-AUTH (Epic)
Stack: java
Fields: 
  Description: "Enable users to verify phone via OTP"
  Story Points: 5
  Team: Backend
  Tags: [onboarding, critical, sprint-12]
---
Create ADO work item.

Return: US-1234 ID, URL, creation time.
```

---

## 5. Routing Prompt

**Use when:** Classifying incoming tasks

```
Task: {task_description}
---
Classify task → Route + Gate + Stages.

Analysis:
1. Type: CONFIG_CHANGE | BUG_FIX | HOTFIX | UI_TWEAK | REFACTOR | NEW_FEATURE
2. Gate Depth: SKIP | LITE | FULL
3. Stages: G{n} → G{m} (gate sequence)

Output format:
| Classification | Gate Depth | Entry Gate | Exit Gate | Est. Stages |
|---|---|---|---|---|
| {type} | {depth} | {g#} | {g#} | {count} |

Assumptions: {any ambiguities flagged}
Risk: {if P0/hotfix, confirm severity}
```

**Example:**
```
Task: Fix critical bug where OTP validation accepts invalid codes (P0 blocker)
---
Classify task → Route.

Type: HOTFIX (P0 severity)
Gate Depth: SKIP (1-2 gates)
Stages: G1 (Intake) → G10 (Deploy)
Est. Stages: 2 (emergency path)

Output: HOTFIX | SKIP | G1 | G10 | 2 gates
Risk confirmed: P0 severity warrants emergency deploy.
```

---

## 6. Validation Prompt (AC/Gherkin)

**Use when:** Checking acceptance criteria syntax

```
Story: {story_id}
ACs: {ac_count}
Format: Gherkin (GIVEN/WHEN/THEN)
---
Validate {ac_count} acceptance criteria.

Check:
✓ Gherkin syntax (GIVEN/WHEN/THEN structure)
✓ Independence (no AC depends on another)
✓ Testability (all assertions are verifiable)
✓ Completeness (all 5 states covered: No data, Loading, Success, Error, No connection)
✓ Numbering (AC-01, AC-02, ... | AC-E01, AC-E02, ... | AC-ERR01, ...)

Output format:
| AC# | Status | Issue | Recommendation |
|-----|--------|-------|-----------------|
| ... | ... | ... | ... |

Blockers: Mark with ❌ (fix before handoff)
Suggestions: Mark with ⚠️ (fix in next sprint)
```

**Example:**
```
Story: US-1234
ACs: 8
---
Validate 8 ACs from ONBOARD-AUTH-S01.

Output: Table with status for AC-01 through AC-E02.
Blockers: AC-02 missing Error state.
Suggestion: AC-03 wording ambiguous ("fast" not testable).
```

---

## 7. Memory Compression Prompt

**Use when:** Summarizing stage completion before handoff

```
Stage: {stage}
File: {memory_file}
---
Compress memory to 100-word summary.

Include:
- Key decision (1 sentence)
- Impact (on next stage)
- Blockers (if any)
- Sign-off (who approved)

Output format:
**{Stage} Completion**
Decision: ...
Impact: ...
Blockers: {none | list}
Approved by: {name}
Date: {date}
```

**Example:**
```
Stage: 03-system-design
File: .sdlc/memory/03-system-design-completion.md
---
Compress memory to 100 words.

Key decision: Opted for synchronous OTP validation via ExampleIdentity service.
Impact: Reduces setup complexity; requires ExampleIdentity service uptime.
Blockers: None.
Approved by: Tech Lead (Jane), PM (Raj)
Date: 2026-04-08
```

---

## 8. Dependency Analysis Prompt

**Use when:** Mapping cross-stage dependencies

```
Scope: {stage_range: 02-05}
Story: {story_id}
---
Map dependencies across stages {start}-{end}.

Identify:
1. Input dependencies (what this stage needs from previous)
2. Output dependencies (what next stage needs from this)
3. Blockers (missing inputs, external dependencies)
4. Critical path (longest dependency chain)

Output format:
Stage → Dep Type → Required By Stage → Blocker?
...

Critical path: {stage_seq} ({duration} estimate)
Blockers: {list or none}
```

**Example:**
```
Scope: 02-05 (PRD → Build)
Story: US-1234
---
Map dependencies across stages 02-05.

Output:
Stage 02 → API Spec → Stage 04 (FE build) → No
Stage 03 → Schema → Stage 05 (QA automation) → No
Stage 04 → Component lib → Stage 05 (integration) → Yes (blocker)

Critical path: 02 → 03 → 04 → 05 (4 weeks)
Blocker: Component library must ship by week 3.
```

---

## Usage Guidelines

1. **Replace placeholders** with actual values: `{role}` → `backend`, `{story_id}` → `US-1234`
2. **Omit optional sections** (marked with { }?) if not relevant
3. **Keep output format section** — always specify expected output shape
4. **Batch related work** — combine 3+ related items (e.g., AC validation) into one call
5. **Reference existing docs** — "See {path}" not "Here's the full content"

**Token savings from templates:**
- Base template: ~100 tokens (reusable)
- Values substitution: ~50-200 tokens (per call)
- Compressed output: 20-40% fewer tokens than freeform prompts

---

## Template Maintenance

Update these templates when:
- New stage added to workflow (add Stage Execution variant)
- New task type added to routing (add routing case)
- Process changes in story generation (add Mode)
- Model selection changes (update Model Selection Rules in token-optimization.md)
