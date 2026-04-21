# AI-SDLC Platform: Stage-Role-Skill-Agent-Validator-Rule Mapping

> **Purpose:** Single source of truth for understanding what components are involved at each SDLC stage, and which files to modify when making changes.

---

## Quick Navigation

| If you want to... | See Section |
|-------------------|-------------|
| Understand stage flow | [15-Stage Pipeline](#15-stage-pipeline-overview) |
| Know which role does what | [Roles by Stage](#roles-by-stage) |
| Find which skill to invoke | [Skills by Stage](#skills-by-stage) |
| Identify which agent to use | [Agents by Stage](#agents-by-stage) |
| Know which validator runs | [Validators by Stage](#validators-by-stage) |
| Understand which rules apply | [Rules by Stage](#rules-by-stage) |
| Update a component | [Component Registry](#component-registry) |
| See impact of changes | [Impact Mapping](#impact-mapping) |

---

## 15-Stage Pipeline Overview

```
01-requirement-intake → 02-prd-review → 03-approvals → 04-grooming → 05-system-design
        ↓
06-implementation-prep → 07-sprint-planning → 08-implementation → 09-code-review → 10-test-design
        ↓
11-test-execution → 12-deployment-prep → 13-release → 14-monitoring → 15-summary-close
```

---

## Stage-by-Stage Detailed Mapping

### Stage 01: Requirement Intake

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Capture raw requirements from any source | - |
| **Roles** | Product Manager, Business Analyst | `roles/product-manager.md` |
| **Primary Skill** | `requirement-intake` | `skills/shared/requirement-intake/SKILL.md` |
| **Supporting Skills** | `prd-gap-analyzer` | `skills/shared/prd-gap-analyzer/SKILL.md` |
| **Agent** | `intake-agent` | `agents/intake-agent/` |
| **Validators** | `check-prd-completeness` | `templates/validators/check-prd-completeness.sh` |
| **Rules** | `ask-first-protocol`, `prompt-templates` | `rules/ask-first-protocol.md`, `rules/prompt-templates.md` |
| **Templates** | `prd-template.md` | `templates/prd-template.md` |
| **Output** | Draft PRD | `docs/prd-[feature].md` |

**Impact of Changes:**
- Updating `prd-template.md` → Affects all new PRDs
- Changing intake skill → Affects requirement quality
- Modifying validators → Affects PRD completeness gates

---

### Stage 02: PRD Review

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Review and approve PRD | - |
| **Roles** | Product Manager, Engineering Lead, QA Lead | `roles/product-manager.md`, `roles/engineering-lead.md` |
| **Primary Skill** | `prd-reviewer` | `skills/shared/prd-reviewer/SKILL.md` |
| **Supporting Skills** | `prd-gap-analyzer` | `skills/shared/prd-gap-analyzer/SKILL.md` |
| **Agent** | `prd-reviewer-agent` | `agents/prd-reviewer-agent/` |
| **Validators** | `check-prd-sections`, `check-prd-signoff` | `templates/validators/check-prd-sections.sh` |
| **Rules** | `prd-standards`, `ask-first-protocol` | `rules/prd-standards.md` |
| **Gates** | G1: PRD signed | `rules/gate-enforcement.md` |

**Impact of Changes:**
- Updating PRD standards → Affects all PRD approvals
- Changing validators → Affects G1 gate enforcement

---

### Stage 03: Approvals

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Cross-functional approvals | - |
| **Roles** | Product Manager, Engineering Lead, Security, Compliance | `roles/` |
| **Primary Skill** | `approval-workflow` | `skills/shared/approval-workflow/SKILL.md` |
| **Agent** | `approval-agent` | `agents/approval-agent/` |
| **Rules** | `compliance-standards` | `rules/compliance-standards.md` |
| **Gates** | G2: Approvals complete | - |

---

### Stage 04: Grooming

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Create Master Story from PRD | - |
| **Roles** | Product Manager | `roles/product-manager.md` |
| **Primary Skill** | `story-generator` | `skills/shared/story-generator/SKILL.md` |
| **Supporting Skills** | `story-splitter`, `estimation-helper` | `skills/shared/story-splitter/SKILL.md` |
| **Agent** | `story-generator-agent` | `agents/story-generator-agent/` |
| **Validators** | `master-story-validator`, `authoring-standards-validator` | `templates/validators/authoring-standards-validator.sh` |
| **Rules** | `AUTHORING_STANDARDS`, `ado-html-formatting`, `no-invention` | `templates/AUTHORING_STANDARDS.md`, `rules/ado-html-formatting.md` |
| **Templates** | `master-story-template.md` | `templates/story-templates/master-story-template.md` |
| **Output** | Master Story | `stories/[MS-XXX].md` (local only, not in repo) |

**Impact of Changes:**
- **CRITICAL:** Updating `story-generator` skill → Affects all future Master Stories
- Updating `master-story-template.md` → Affects all story structure
- **CRITICAL:** Changing `AUTHORING_STANDARDS.md` → Affects all stories organization-wide
- Updating `ado-html-formatting.md` → Affects ADO work item formatting

**Important:** 
- Master Stories contain organization-specific data (ADO IDs) → **Never commit to platform repo**
- Use `USER_INPUT_REQUIRED` pattern for missing PRD data
- Run `authoring-standards-validator.sh` before ADO push

---

### Stage 05: System Design

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Technical architecture and design | - |
| **Roles** | Architect, Engineering Lead, Tech Lead | `roles/architect.md`, `roles/engineering-lead.md` |
| **Primary Skill** | `system-designer` | `skills/architect/system-designer/SKILL.md` |
| **Supporting Skills** | `adr-writer`, `api-designer` | `skills/architect/adr-writer/SKILL.md` |
| **Agent** | `architect-agent` | `agents/architect-agent/` |
| **Validators** | `check-design-sections` | `templates/validators/check-design-sections.sh` |
| **Rules** | `repo-grounded-change`, `quality-standards` | `rules/repo-grounded-change.md` |
| **Templates** | `design-doc-template.md`, `adr-template.md` | `templates/design-doc-template.md` |
| **Gates** | G4: Design reviewed | - |

---

### Stage 06: Implementation Prep

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Prepare for implementation | - |
| **Roles** | Tech Lead, Engineering Lead | `roles/tech-lead.md` |
| **Primary Skill** | `tech-task-generator` | `skills/shared/tech-task-generator/SKILL.md` |
| **Supporting Skills** | `module-loader`, `dependency-checker` | `skills/shared/module-loader/SKILL.md` |
| **Agent** | `tech-lead-agent` | `agents/tech-lead-agent/` |
| **Validators** | `check-task-completeness` | `templates/validators/check-task-completeness.sh` |
| **Templates** | `task-template.md` | `templates/story-templates/task-template.md` |

---

### Stage 07: Sprint Planning

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Create Sprint Stories and tasks | - |
| **Roles** | Tech Lead, Product Manager, QA | `roles/tech-lead.md`, `roles/qa-engineer.md` |
| **Primary Skill** | `sprint-story-generator` | `skills/shared/sprint-story-generator/SKILL.md` |
| **Supporting Skills** | `tech-task-generator`, `estimation-helper` | `skills/shared/tech-task-generator/SKILL.md` |
| **Agent** | `sprint-planner-agent` | `agents/sprint-planner-agent/` |
| **Validators** | `sprint-story-validator`, `authoring-standards-validator` | `templates/validators/authoring-standards-validator.sh` |
| **Rules** | `AUTHORING_STANDARDS`, `ado-html-formatting` | `templates/AUTHORING_STANDARDS.md` |
| **Templates** | `sprint-story-template.md` | `templates/story-templates/sprint-story-template.md` |
| **Output** | Sprint Stories, Tasks | `stories/[SS-XXX].md`, `tasks/[TASK-XXX].md` |

**Impact of Changes:**
- **CRITICAL:** Updating `sprint-story-generator` skill → Affects all future Sprint Stories
- Updating `sprint-story-template.md` → Affects sprint story structure
- **CRITICAL:** `AUTHORING_STANDARDS.md` changes → Affects all sprint stories

**Important:**
- Sprint Stories contain organization-specific data → **Never commit to platform repo**
- Always validate with `authoring-standards-validator.sh` before ADO push

---

### Stage 08: Implementation

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Code implementation | - |
| **Roles** | Developer, Tech Lead | `roles/developer.md` |
| **Primary Skill** | `code-generator`, `test-generator` | `skills/[stack]/code-generator/SKILL.md` |
| **Supporting Skills** | `code-reviewer`, `refactor-helper` | `skills/shared/code-reviewer/SKILL.md` |
| **Agent** | `developer-agent` | `agents/developer-agent/` |
| **Validators** | `check-code-quality`, `coverage-rule` | `templates/validators/check-code-quality.sh` |
| **Rules** | `repo-grounded-change`, `quality-standards`, `coverage-rule` | `rules/repo-grounded-change.md`, `rules/coverage-rule.md` |
| **RPI Workflow** | Research → Plan → Implement | `rules/rpi-workflow.md` |

---

### Stage 09: Code Review

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Peer review of code | - |
| **Roles** | Developer, Engineering Lead | `roles/developer.md`, `roles/engineering-lead.md` |
| **Primary Skill** | `code-reviewer` | `skills/shared/code-reviewer/SKILL.md` |
| **Supporting Skills** | `security-reviewer`, `performance-reviewer` | `skills/shared/security-reviewer/SKILL.md` |
| **Agent** | `reviewer-agent` | `agents/reviewer-agent/` |
| **Validators** | `check-code-review`, `check-coverage` | `templates/validators/check-code-review.sh` |
| **Rules** | `quality-standards`, `mobile-code-review` | `rules/quality-standards.md` |
| **Gates** | G5: Code review passed | - |

---

### Stage 10: Test Design

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Create test plans | - |
| **Roles** | QA Engineer | `roles/qa-engineer.md` |
| **Primary Skill** | `test-designer` | `skills/qa/test-designer/SKILL.md` |
| **Supporting Skills** | `test-case-generator`, `automation-designer` | `skills/qa/test-case-generator/SKILL.md` |
| **Agent** | `qa-agent` | `agents/qa-agent/` |
| **Validators** | `check-test-matrix` | `templates/validators/check-test-matrix.sh` |
| **Templates** | `test-plan-template.md` | `templates/test-plan-template.md` |

---

### Stage 11: Test Execution

| Component | Details | File to Update |
|-----------|---------|----------------|
| **Purpose** | Execute tests | - |
| **Roles** | QA Engineer | `roles/qa-engineer.md` |
| **Primary Skill** | `test-executor` | `skills/qa/test-executor/SKILL.md` |
| **Supporting Skills** | `defect-reporter`, `regression-helper` | `skills/qa/defect-reporter/SKILL.md` |
| **Agent** | `qa-agent` | `agents/qa-agent/` |
| **Validators** | `check-test-coverage`, `check-defects` | `templates/validators/check-test-coverage.sh` |
| **Rules** | `qa-guardrails`, `coverage-rule` | `rules/qa-guardrails.md` |
| **Gates** | G7: SIT certified | - |

---

### Stage 12-15: Deployment, Release, Monitoring, Close

| Stages | Components |
|--------|-----------|
| 12: Deployment Prep | `deployment-agent`, `release-manager-role` |
| 13: Release | `release-agent`, `operational-reliability-rule` |
| 14: Monitoring | `monitoring-agent`, `nfr-targets-rule` |
| 15: Summary Close | `docs-agent`, `user-manual-sync-rule` |

---

## Component Registry

### Templates

| Template | Purpose | Stage | File Path |
|----------|---------|-------|-----------|
| `prd-template.md` | Product requirements | 01, 02 | `templates/prd-template.md` |
| `master-story-template.md` | Master story structure | 04 | `templates/story-templates/master-story-template.md` |
| `sprint-story-template.md` | Sprint story structure | 07 | `templates/story-templates/sprint-story-template.md` |
| `tech-story-template.md` | Technical story | 05, 07 | `templates/story-templates/tech-story-template.md` |
| `task-template.md` | Task breakdown | 06, 07 | `templates/story-templates/task-template.md` |
| `design-doc-template.md` | System design | 05 | `templates/design-doc-template.md` |
| `adr-template.md` | Architecture decisions | 05 | `templates/adr-template.md` |
| `test-plan-template.md` | Test planning | 10 | `templates/test-plan-template.md` |

### Validators

| Validator | Purpose | Stage(s) | File Path |
|-----------|---------|----------|-----------|
| `check-prd-sections` | Validate PRD completeness | 02 | `templates/validators/check-prd-sections.sh` |
| `master-story-validator` | Validate master story | 04 | `templates/validators/master-story-validator.sh` |
| `sprint-story-validator` | Validate sprint story | 07 | `templates/validators/sprint-story-validator.sh` |
| `authoring-standards-validator` | Validate AUTHORING_STANDARDS | 04, 07 | `templates/validators/authoring-standards-validator.sh` |
| `check-task-completeness` | Validate tasks | 06 | `templates/validators/check-task-completeness.sh` |
| `check-design-sections` | Validate design docs | 05 | `templates/validators/check-design-sections.sh` |
| `check-test-matrix` | Validate test plans | 10 | `templates/validators/check-test-matrix.sh` |

### Rules

| Rule | Purpose | Stage(s) | File Path |
|------|---------|----------|-----------|
| `AUTHORING_STANDARDS.md` | Story authoring standards | 04, 07 | `templates/AUTHORING_STANDARDS.md` |
| `ado-html-formatting.md` | ADO work item formatting | 04, 07 | `rules/ado-html-formatting.md` |
| `ask-first-protocol.md` | AI never acts without asking | All | `rules/ask-first-protocol.md` |
| `rpi-workflow.md` | Research-Plan-Implement workflow | 08 | `rules/rpi-workflow.md` |
| `repo-grounded-change.md` | Changes anchored to real files | 05, 08 | `rules/repo-grounded-change.md` |
| `gate-enforcement.md` | Quality gates | All | `rules/gate-enforcement.md` |
| `coverage-rule.md` | Test coverage targets | 08, 09, 11 | `rules/coverage-rule.md` |
| `prd-standards.md` | PRD quality standards | 01, 02 | `rules/prd-standards.md` |
| `qa-guardrails.md` | QA standards | 10, 11 | `rules/qa-guardrails.md` |
| `pre-merge-test-enforcement.md` | Test requirements for merge | 09 | `rules/pre-merge-test-enforcement.md` |

---

## Impact Mapping

### If You Change This File... | These Are Affected

| File Changed | Impact | Who/What is Affected |
|--------------|--------|---------------------|
| `templates/AUTHORING_STANDARDS.md` | **CRITICAL** | All stories organization-wide (Master, Sprint, Tech, Task) |
| `rules/ado-html-formatting.md` | **HIGH** | All ADO work items formatting |
| `skills/shared/story-generator/SKILL.md` | **HIGH** | All Master Stories created going forward |
| `skills/shared/sprint-story-generator/SKILL.md` | **HIGH** | All Sprint Stories created going forward |
| `templates/story-templates/master-story-template.md` | **MEDIUM** | Structure of all future Master Stories |
| `templates/story-templates/sprint-story-template.md` | **MEDIUM** | Structure of all future Sprint Stories |
| `templates/validators/authoring-standards-validator.sh` | **MEDIUM** | Validation results before ADO push |
| `rules/ask-first-protocol.md` | **HIGH** | All AI interactions |
| `rules/rpi-workflow.md` | **MEDIUM** | Implementation stage workflow |
| `rules/gate-enforcement.md` | **MEDIUM** | All quality gates |
| `templates/prd-template.md` | **MEDIUM** | All future PRDs |
| `stories/*.md` (in local workspace) | **LOW** | Only that specific story |

---

## Quick Reference: What File to Touch

### To Add a New...

| Component Type | Where to Add | Example |
|---------------|--------------|---------|
| **New Stage** | Add to `stages/[NN]-[name]/STAGE.md`, update this mapping doc | `stages/16-feedback/` |
| **New Role** | Create `roles/[role-name].md`, update stage mappings | `roles/data-engineer.md` |
| **New Skill** | Create `skills/[category]/[skill-name]/SKILL.md`, update registry | `skills/shared/api-designer/` |
| **New Agent** | Create `agents/[agent-name]/`, update stage mappings | `agents/ml-engineer-agent/` |
| **New Validator** | Create `templates/validators/[name].sh`, update registry and this doc | `templates/validators/check-ml-model.sh` |
| **New Rule** | Create `rules/[name].md`, update `rules/README.md` and this doc | `rules/ml-standards.md` |
| **New Template** | Create `templates/[name].md`, update registry and this doc | `templates/ml-model-card.md` |

### To Update...

| Update Type | File to Edit | Additional Steps |
|-------------|--------------|------------------|
| **Change story structure** | `templates/story-templates/[type]-template.md` | Run `authoring-standards-validator.sh` to test |
| **Change ADO formatting rules** | `rules/ado-html-formatting.md` | Update `skills/shared/story-generator/SKILL.md` |
| **Change validation logic** | `templates/validators/[name].sh` | Test on sample story, update this doc |
| **Change skill behavior** | `skills/[category]/[skill]/SKILL.md` | Validate with `sdlc skill validate [skill]` |
| **Change rule** | `rules/[name].md` | Update dependent skills/agents |

---

## Maintenance Notes

**When adding new components:**
1. Create the component file
2. Update this mapping document (`docs/sdlc-stage-role-mapping.md`)
3. Update `User_Manual/manual.html` (run `node User_Manual/build-manual-html.mjs`)
4. Test the component
5. Commit and push to both remotes (`origin` and `github`)

**When this document becomes outdated:**
- Run `sdlc doctor` to check for drift
- Review `skills/` and `agents/` directories for new additions
- Check recent commits for new validators or rules
- Update this document and regenerate `manual.html`

---

## See Also

- [Architecture](User_Manual/Architecture.md)
- [Happy Path End-to-End](User_Manual/Happy_Path_End_to_End.md)
- [Agents, Skills, Rules](User_Manual/Agents_Skills_Rules.md)
- [Story Template Registry](templates/story-templates/STORY_TEMPLATE_REGISTRY.md)
- [Authoring Standards](templates/AUTHORING_STANDARDS.md)
- [ADO HTML Formatting](rules/ado-html-formatting.md)
