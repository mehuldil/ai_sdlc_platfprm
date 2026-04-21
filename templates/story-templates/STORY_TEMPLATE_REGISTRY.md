# Story Template Registry

Maps story types to pipeline stages and validators.

> **Global authoring rules (ADO-ready, no invention, non-redundancy, traceability):** [../AUTHORING_STANDARDS.md](../AUTHORING_STANDARDS.md)

---

## Missing source material (authoring policy)

Applies to **Master Story**, **Sprint Story**, **Tech Story**, and **Task** templates — whether filled by a person or by an IDE agent.

**Rule:** If the PRD, parent story, or other agreed source **does not** contain the facts needed for a given section (or subsection), **do not invent or auto-generate** narrative to “complete” the template.

**Do this instead:**

1. **Stop** filling that section with synthetic content.
2. **Insert a `USER_INPUT_REQUIRED` block** for that section (copy the pattern below).
3. **List concrete questions** the author must answer (or point to the missing PRD section ID).
4. After the user supplies text, **replace** the block with their input and remove the marker.

**Pattern (copy and adapt):**

```markdown
<!-- USER_INPUT_REQUIRED section="Exact section heading" reason="PRD/source missing: brief note" -->
**Awaiting input**

- **Missing:** [What information is not in PRD/parent]
- **Questions:** 1) … 2) …
- **Owner to answer:** [role, e.g. PM / Tech Lead]

<!-- /USER_INPUT_REQUIRED -->
```

Optional one-line form for small gaps:  
`<!-- USER_INPUT_REQUIRED: [one sentence: what to ask the user] -->`

**Hierarchy:** Task ← Sprint Story ← Master / Tech Story ← PRD. If the parent does not define something, the child document must **not** fabricate it; prompt upward or use `USER_INPUT_REQUIRED`.

---

## ADO-ready content (no PRD re-read)

Applies to **Master** and **Sprint** stories pushed to Azure DevOps (or any work-item system).

**Goal:** A reader (dev, QA, TPM) can implement and test **without opening the PRD**.

**Do:**

- Copy **verbatim** user-visible strings: notifications, errors, tooltips, button labels, and **all locales** listed in the PRD.
- Put structured PRD tables into **one** place: Master → **📎 PRD-sourced specifics**; Sprint → **📎 PRD / Master lift (this sprint)**.
- Reference PRD rows in Acceptance criteria (e.g. “matches **Notification Nx** row in 📎 section”) instead of pasting the same string twice.
- Use **🎨 UI & design** for **Figma** (primary), prototype links, and design status — not for repeating business outcomes.

**Do not:**

- List PRD artifact ids (**Nx**, **§x.x**) **without** the lifted text (unless pointing to the Master work item row that contains the full text).
- Paste the same narrative into **Outcome**, **Problem**, **Context**, and **Solution**; each section has a single job (see section map in `master-story-template.md`).
- Duplicate the full **Measurement** block in **Validation plan** (methodology only in Validation).

**Formatting (readability):** Short sentences. **Bold** for scan labels. Bullets. Blank lines between items. Tables for PRD extracts.

---

## Quick Reference

| Story Type | Stage(s) | Created By | Validator | Purpose |
|-----------|----------|-----------|-----------|---------|
| **Master Story** | 04-grooming | Product Manager | master-story-validator.sh | Strategic, discovery-phase story. Defines outcome, problem, solution. |
| **Sprint Story** | 07-sprint-planning | Tech Lead / PM | sprint-story-validator.sh | Tactical, executable slice for one sprint. Derived from master. |
| **Tech Story** | 07-tech-design (parallel to sprint) | Architect / Tech Lead | tech-story-validator.sh | **Implementation SSoT:** grounded in **system design** + Master + Sprint; baseline, impact, **non-regression**; not speculative. |
| **Task** | 07-08 (daily work) | Engineer / Tech Lead | task-validator.sh | Atomic work unit. 2h-2d effort. |
| **Hierarchy** | All | Auto-check | story-hierarchy-validator.sh | Validates master → sprint → task linkage. |

**CLI (from repo with `sdlc` on PATH):**

| Action | Command |
|--------|---------|
| New files from templates | `sdlc story create master|sprint|tech|task --output=./stories/` |
| Validate one file | `sdlc story validate <file.md>` |
| Push markdown → ADO | `sdlc story push <file.md> [--type=…]` — alias of `sdlc ado push-story`; default **User Story**; **`--type=feature`** for master stories → ADO Feature; prints work item id |

PRD-filled content usually comes from the **story-generator** skill in the IDE; the CLI supplies templates and ADO push.

---

## Master Story

**File:** `master-story-template.md`  
**When Created:** After PRD approval (04-grooming)  
**Required Sections:** 14 (soft gates - all optional for creation, but recommended)  
**Key Validators:**
- ✓ Sections present (includes **📎 PRD-sourced specifics**, **🎨 UI & design**)
- ✓ Success metrics quantified
- ✓ Cross-POD blockers identified
- ✓ Acceptance criteria in Given/When/Then format
- ✓ Heuristic: PRD id patterns in body → PRD-sourced section expected

**Command:**
```bash
sdlc story create master --output=stories/
# or: sdlc template generate master-story --output=stories/
```

**ADO (after content is ready):** `sdlc story push stories/MS-....md --type=feature` (ADO **Feature**; put id in PRD Traceability table). Sprint files: `sdlc story push stories/SS-....md` or `--parent=<FeatureId>`.

**Validator:**
```bash
./templates/story-templates/validators/master-story-validator.sh stories/master.md
```

---

## Sprint Story

**File:** `sprint-story-template.md`  
**When Created:** Sprint planning (07-sprint-planning)  
**Derived From:** Master Story  
**Required Sections:** 8 (soft gates)  
**Key Validators:**
- ✓ Parent master story linked
- ✓ Scope has IN and OUT
- ✓ **📎 PRD / Master lift** present when PRD refs appear in body
- ✓ **🎨 UI & design** with Figma or N/A
- ✓ Acceptance criteria use checkboxes
- ✓ Team assigned (assignee TBD or named)
- ✓ Effort estimated (5d, 10d, 15d range)

**Command:**
```bash
sdlc template generate sprint-story \
  --master-id=MS-123 \
  --sprint="Sprint 5" \
  --output=stories/
```

**Validator:**
```bash
./templates/story-templates/validators/sprint-story-validator.sh stories/sprint-story-1.md
```

---

## Tech Story

**File:** `tech-story-template.md`  
**When Created:** Parallel to sprint planning (07-tech-design)  
**Derived From:** **System design** (primary) + **Master Story** + **Sprint Story**  
**Required Sections:** Inputs, baseline, goal/delta, design alignment, impact, **non-regression**, architecture, testing, AC, rollout, traceability  
**Key Validators:**
- ✓ **Traceability** to system design + Master + Sprint
- ✓ **Baseline / as-is** with repo anchors (no guesswork)
- ✓ **Non-regression** invariants and regression strategy
- ✓ Rollback / kill-switch
- ✓ Performance claims quantified or `USER_INPUT_REQUIRED`

**When to Use:**
- Non-trivial implementation; need **single technical source of truth**
- Cross-cutting APIs, data, messaging, or reliability
- Must prove **existing behavior** stays intact

**When NOT Needed:**
- Trivial change with no contract/behavior risk (team may use task template only—local policy)

**Command:**
```bash
sdlc template generate tech-story \
  --sprint-id=SS-456 \
  --output=stories/
```

**Validator:**
```bash
./templates/story-templates/validators/tech-story-validator.sh stories/tech-story.md
```

---

## Task

**File:** `task-template.md`  
**When Created:** Sprint execution (07-08)  
**Derived From:** Sprint Story (required)  
**Effort Range:** 2h - 2d (longer = break into subtasks)  
**Key Validators:**
- ✓ Sprint story linked
- ✓ Acceptance criteria checkboxes
- ✓ Effort in 2h-2d range
- ✓ Definition of Done clear

**Command:**
```bash
sdlc template generate task \
  --sprint-id=SS-456 \
  --effort=4h \
  --output=stories/
```

**Validator:**
```bash
./templates/story-templates/validators/task-validator.sh stories/task-001.md
```

---

## Hierarchy Validation

**Purpose:** Ensure master → sprint → task linkage is consistent  
**When to Run:** Before sprint starts, or when checking family of stories

**Command:**
```bash
./templates/story-templates/validators/story-hierarchy-validator.sh \
  stories/master.md \
  stories/sprint-*.md \
  --strict
```

**Checks:**
- ✓ Sprint stories link to parent master
- ✓ Success metrics align
- ✓ Timeline is feasible
- ✓ Dependencies are documented

---

## Usage Examples

### Creating a Full Feature (Master → Sprint → Task)

```bash
# 1. Create master story
sdlc template generate master-story \
  --outcome="Users can batch upload files" \
  --output=stories/

# 2. Validate master story
./templates/story-templates/validators/master-story-validator.sh stories/master.md

# 3. Create sprint story from master
sdlc template generate sprint-story \
  --master-id=MS-001 \
  --sprint="Sprint 5" \
  --output=stories/

# 4. (Optional) Create tech story for architecture
sdlc template generate tech-story \
  --sprint-id=SS-001 \
  --output=stories/

# 5. Create 3-5 tasks from sprint story
for i in {1..3}; do
  sdlc template generate task \
    --sprint-id=SS-001 \
    --output=stories/
done

# 6. Validate entire hierarchy
./templates/story-templates/validators/story-hierarchy-validator.sh \
  stories/master.md \
  stories/sprint-*.md
```

### Quick Validation During Sprint

```bash
# Check all stories in current sprint
find .sdlc/stories -name "*.md" -type f | while read f; do
  echo "Validating $f..."
  ./templates/story-templates/validators/$(basename $f | sed 's/-.*//')-validator.sh "$f"
done
```

---

## Pipeline Integration

### Stage 04: Grooming
- **Input:** PRD approved
- **Output:** Master Story
- **Validator:** master-story-validator.sh
- **Gate:** Success metric defined, acceptance criteria clear

### Stage 07: Sprint Planning
- **Input:** Master Story(ies)
- **Output:** Sprint Story(ies) + Tasks
- **Validator:** sprint-story-validator.sh, task-validator.sh
- **Gate:** Team assigned, effort estimated, scope clear

### Stage 07: Tech Design (Parallel)
- **Input:** Sprint Story (if complex)
- **Output:** Tech Story
- **Validator:** tech-story-validator.sh
- **Gate:** Architecture defined, rollout plan clear

### Ongoing: Daily Execution
- **Input:** Task
- **Output:** Code + merged PR
- **Validator:** task-validator.sh
- **Gate:** Definition of Done met

---

## Migration from Old Templates

### Old → New Mapping
| Old | New | Differences |
|-----|-----|------------|
| master-user-story-template.md | master-story-template.md | Cleaner sections, outcome-first, soft gates |
| sprint-user-story-template.md | sprint-story-template.md | Tasks split to separate tier |
| tech-task-template.md | tech-story-template.md + task-template.md | Split: architecture vs. implementation |

### Backward Compatibility
- ✅ Old templates still work (in /templates/)
- ✅ New story-templates/ directory is separate
- ✅ Validators are opt-in (don't prevent creation)
- ✅ All existing CLI commands still work

### Migration Strategy
1. Keep old templates available for 1 sprint
2. New stories use new templates
3. Run validator on both old and new
4. Archive old templates after 2 sprints

---

## Customization

### Adding Custom Sections
Edit the template file and add your section:
```markdown
## 📝 Your Custom Section
[Your content]
```

Then update validator:
```bash
if grep -q "## 📝 Your Custom Section" "$story_file"; then
  echo -e "${GREEN}✓${NC} Custom section present"
fi
```

### Disabling Validators
Set `--strict=false` (default) to skip validation checks:
```bash
sdlc template validate master-story file.md --strict=false
```

---

## Support

For issues or questions:
- Check examples in `templates/story-templates/examples/`
- Review validator output (shows what's missing)
- Ask in #sdlc-templates Slack channel

