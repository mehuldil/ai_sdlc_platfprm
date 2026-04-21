# Template Registry

Maps templates to stages where they're required or optional.

> **Authoring standards (all templates & skills):** [AUTHORING_STANDARDS.md](AUTHORING_STANDARDS.md)

---

## Quick Reference

### Story Templates (4-tier system)
| Template | Stage(s) | Required? | Used For | Validator |
|----------|----------|-----------|----------|-----------|
| **story-templates/master-story-template.md** | 04-05 | Yes (G3) | Strategic feature definition | master-story-validator.sh |
| **story-templates/sprint-story-template.md** | 07-10 | Yes (G3) | Executable sprint slice | sprint-story-validator.sh |
| **story-templates/tech-story-template.md** | 07-08 | Optional | **Implementation SSoT** (design + master + sprint; baseline; non-regression) | tech-story-validator.sh |
| **story-templates/task-template.md** | 07-09 | Yes | Atomic work unit (2h-2d) | task-validator.sh |

**Traceability:** Master story includes **PRD document + section IDs**; sprint/task/tech templates carry **PRD section IDs** through to commits (AB#) and PRs — see `rules/traceability-pr-prd.md`.

**ADO-ready:** Master and Sprint templates include **📎 PRD-sourced specifics** / **📎 PRD / Master lift** (verbatim copy from PRD) and **🎨 UI & design** (Figma). Work items should be readable without opening the PRD — see `story-templates/STORY_TEMPLATE_REGISTRY.md` (ADO-ready content).

**CLI:** `sdlc story create …`, `sdlc story validate …`, `sdlc story push … [--type=feature|story|epic]` (Azure DevOps work item) — see `User_Manual/Commands.md`.

*See `story-templates/STORY_TEMPLATE_REGISTRY.md` for detailed story template docs.*

**Missing PRD/parent facts:** Do not auto-fill; use `USER_INPUT_REQUIRED` — see `story-templates/STORY_TEMPLATE_REGISTRY.md` (Missing source material).

### Other Templates
| Template | Stage(s) | Required? | Used For | Validator |
|----------|----------|-----------|----------|-----------|
| **prd-template.md** | 02-06 | Yes (G1) | Product requirements doc | check-prd-sections |
| **DEPRECATED/master-user-story-template.md** | — | Deprecated | Legacy; use **story-templates/master-story-template.md** | check-story-fields |
| **DEPRECATED/sprint-user-story-template.md** | — | Deprecated | Legacy; use **story-templates/sprint-story-template.md** | check-story-fields |
| **DEPRECATED/tech-task-template.md** | — | Deprecated | Legacy; use **story-templates/task-template.md** | check-task-completeness |
| **adr-template.md** | 05-06 | Yes (G4) | Architecture decisions | check-adr-syntax |
| **design-doc-template.md** | 05-06 | Optional | System design + data flows | check-design-sections |
| **test-plan-template.md** | 10-11 | Yes | QA test planning + execution | check-test-matrix |

---

## Template Details

### Legacy (DEPRECATED) — do not use for new work

The subsections **master-user-story-template**, **sprint-user-story-template**, and **tech-task-template** refer to files under **`templates/DEPRECATED/`**. New features must use **`templates/story-templates/`** (master, sprint, tech, task) per **[AUTHORING_STANDARDS.md](AUTHORING_STANDARDS.md)**.

---

### prd-template.md

**Stage**: 02-prd-review (created), 03-06 (updated)  
**Required**: Yes (Gates stage 02 → 04)  
**Sections**: 14 mandatory

```markdown
1. Overview
2. Goals & Objectives
3. User Personas
4. User Journeys
5. Feature Capabilities
6. Acceptance Criteria (Gherkin)
7. Measurement & Success Metrics
8. Technical Constraints
9. Performance Requirements
10. Security & Compliance
11. Dependencies & Blockers
12. Design References
13. Open Questions
14. Risks & Mitigations
```

**Validator**: `templates/validators/check-prd-sections.sh`

```bash
sdlc template-validate docs/prd.md --strict
# Output: ✓ All 14 sections found
#         ✓ Success metrics measurable
#         ✓ All 5 user personas defined
#         ⚠ Open Questions section is empty (optional)
```

### DEPRECATED: master-user-story-template.md

**Location:** `templates/DEPRECATED/` — **use `story-templates/master-story-template.md` instead.**  
**Stage**: 04-grooming (historical)  
**Sections**: 17 (legacy)

```markdown
1. Story ID & Title
2. Epic/Feature
3. User Persona
4. Job To Be Done (JTBD)
5. Outcome Hypothesis
6. Capabilities (numbered)
7. Acceptance Criteria (Gherkin - per capability)
8. Non-Functional Requirements
9. Dependencies
10. Story Points (estimated)
11. Acceptance (signed by Product)
12. Design References
13. API Contracts
14. Data Model Changes
15. Performance Requirements
16. Test Scenarios (high-level)
17. Rollback Plan
```

**Validator**: `templates/validators/check-story-fields.sh`

```bash
sdlc template-validate stories/US-123.md --type=master
# Output: ✓ Story ID format valid (US-*)
#         ✓ All 6 capabilities have AC
#         ✓ AC in valid Gherkin format
#         ✓ Story points: 8 (reasonable)
#         ⚠ Design references section empty (required)
```

### DEPRECATED: sprint-user-story-template.md

**Location:** `templates/DEPRECATED/` — **use `story-templates/sprint-story-template.md` instead.**  
**Stage**: 07-task-breakdown (historical)  
**Sections**: 8 (legacy)

```markdown
1. Story ID & Title
2. Sprint Objective
3. Parent Master Story (link)
4. Scope (subset of capabilities)
5. Acceptance Criteria (subset of master)
6. Implementation Notes
7. QA Checklist
8. Definition of Done
```

**Validator**: `templates/validators/check-story-fields.sh`

```bash
sdlc template-validate stories/US-123-sprint-001.md --type=sprint
# Output: ✓ Scope is subset of US-123
#         ✓ AC references master story ACs
#         ✓ Definition of Done includes: code review, tests, docs
```

### DEPRECATED: tech-task-template.md

**Location:** `templates/DEPRECATED/` — **use `story-templates/task-template.md` instead.**  
**Stage**: 07-task-breakdown (historical)  
**Sections**: 15 (legacy)

```markdown
1. Task ID & Title
2. Parent Story (link)
3. Task Type (feature|bugfix|refactor|tech-debt)
4. Description
5. Implementation Approach
6. API Contract (if BE)
7. Component Spec (if FE)
8. Data Model Changes (if applicable)
9. Code Structure (where to add code)
10. Dependencies (internal/external)
11. Observability (logging, metrics)
12. Error Handling (exceptions, fallbacks)
13. Testing Strategy (unit, integration)
14. Deployment Impact (backward compat, migrations)
15. Rollback Plan
```

**Validator**: `templates/validators/check-task-completeness.sh`

```bash
sdlc template-validate tasks/TASK-123-backend.md
# Output: ✓ Task ID format valid
#         ✓ Parent story linked
#         ✓ Implementation approach clear
#         ⚠ Error handling section sparse (should have 3+ cases)
#         ✓ Rollback plan present
```

### adr-template.md

**Stage**: 05-system-design (created during architecture review)  
**Required**: Yes (Gates G4)  
**Sections**: 7 mandatory

```markdown
1. Title
2. Status (Proposed | Accepted | Deprecated | Superseded)
3. Context
4. Decision
5. Rationale
6. Consequences (positive & negative)
7. Alternatives Considered
```

**Validator**: `templates/validators/check-adr-syntax.sh`

```bash
sdlc template-validate docs/adr/0001-use-redis.md
# Output: ✓ Status: Accepted
#         ✓ Context section explains problem
#         ✓ Rationale covers: performance, cost, team skill
#         ✓ 2 alternatives considered (sufficient)
#         ✓ Consequences: 3 positive, 1 risk documented
```

### design-doc-template.md

**Stage**: 05-system-design (optional, complements ADR)  
**Required**: Optional  
**Sections**: 7

```markdown
1. Overview
2. Architecture Diagram
3. Data Flow (BPMN or sequence diagram)
4. Component Specifications
5. API Contracts (OpenAPI)
6. Data Model (ER diagram)
7. Technical Decisions & Rationale
```

**Validator**: `templates/validators/check-design-sections.sh`

### test-plan-template.md

**Stage**: 10-test-design (created before execution)  
**Required**: Yes (Gates QA execution)  
**Sections**: 7 mandatory

```markdown
1. Test Scope
2. Test Strategy (unit, integration, E2E, manual)
3. Test Matrix (scenarios × stacks × versions)
4. Test Data Setup
5. Acceptance Criteria (same as story)
6. Test Execution Schedule
7. Rollback Testing Plan
```

**Validator**: `templates/validators/check-test-matrix.sh`

```bash
sdlc template-validate tests/test-plan-US-123.md
# Output: ✓ Test matrix covers all AC
#         ✓ Happy path: 5 scenarios
#         ✓ Edge cases: 8 scenarios
#         ✓ Error cases: 4 scenarios
#         ✓ Total: 17 scenarios (reasonable for story size 8)
#         ⚠ Mobile testing not covered (stack: react-native required)
```

---

## Template Workflow

### Stage 02-03: PRD Creation

1. **Intake agent** produces raw requirements
2. **prd-generator** skill fills `prd-template.md`
3. **prd-reviewer** validates against template
4. Gate G1: Signed PRD (from template)

### Stage 04: Story Generation

1. **story-generator** skill fills `master-user-story-template.md` for each capability
2. **Validate**: `check-story-fields.sh` verifies all 17 sections
3. Gate G3: Story estimated + AC accepted (from template)

### Stage 07: Task Breakdown

1. **Task breakdown agent** creates `tech-task-template.md` for each story
2. **Create sprint stories** from master (uses `sprint-user-story-template.md`)
3. Gate G5: Tasks ready for sprint (from template)

### Stage 10-11: Test Planning & Execution

1. **QA** creates `test-plan-template.md` from AC
2. **test-matrix skill** validates coverage
3. Gate G7: SIT certified (test matrix complete, all defects resolved)

---

## Validator Commands

```bash
# Validate single file
sdlc template-validate docs/prd.md

# Validate with strictness levels
sdlc template-validate docs/prd.md --strict      # Fail on warnings
sdlc template-validate docs/prd.md --lenient     # Warn only on errors

# Validate directory
sdlc template-validate stories/ --type=story

# Generate template
sdlc template-generate --type=prd --output=docs/prd.md
```

---

## Custom Templates

To add org-specific template:

1. Create `templates/custom-XXXX-template.md`
2. Add entry to this registry
3. Create validator script at `templates/validators/check-XXXX.sh`
4. Template auto-discovered by `sdlc template-validate`

---

## Integration with ADO

If templates are stored in ADO wiki:

```bash
sdlc template-sync --from=ado --project=YourAzureProject
# Downloads latest templates from wiki.js → templates/
```

---

## See Also

- **Gate Enforcement**: `rules/gate-enforcement.md`
- **CLAUDE.md**: Template loading order
- **Validators**: `templates/validators/`
