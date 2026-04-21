# Stage Template: [Stage Name]

Replace `[Stage Name]` with stage name (e.g., "Data Model Review", "Performance Testing").

Create this file at: `stages/[NN]-[stage-name]/STAGE.md` where NN is 01-14.

---

## Stage Metadata

```yaml
---
name: [Stage Name]
description: [One sentence describing what happens in this stage]
phase: [Number: 1-14, or fractional like 2.5 for between stages]
requires_stages: [[Previous stage name]]  # Advisory, stage can run independently
gate: [G1-G10 or "None"]
model: [claude-opus | sonnet-4-6 | haiku]
token_budget:
  input: [Number, e.g., 6000]
  output: [Number, e.g., 3000]
---
```

## Stage Overview

### When to Run
[When should this stage be triggered? E.g., "After PRD is approved by Product Manager and assigned to sprint."]

### Independent Execution
[Can this stage run standalone or does it require prior stages? E.g., "Yes, can run independently at any time if work item has PRD attached."]

#### Pre-Flight Checks (if standalone)
When running independently:
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check [required context, e.g., "workflow-state.md"]
4. Check required stage completions: [List stages]
   - If completed: load outputs from [file]
   - If NOT completed: warn user, ask to continue or abort

#### Minimum Context Required
- [What must exist? E.g., "PRD document", "Code repository", "Test results"]

## Execution

### Context Loading
Which context is loaded and in what priority?

**Always Load** (Tier 1):
- [E.g., work item from ADO]
- [E.g., stage definition (STAGE.md)]
- [E.g., gate definitions (gate-enforcement.md)]

**Load If Available** (Tier 2):
- [E.g., previous stage outputs]
- [E.g., team memory (conventions)]
- [E.g., stack rules]

**Load On Demand** (Tier 3):
- [E.g., service registry, performance baselines]

### Execution Steps
1. [Step 1, e.g., "Load work item from ADO"]
2. [Step 2, e.g., "Invoke agent: backend-engineer-agent"]
   - Check gates: [G1, G5]
   - Invoke skills: [skill-1, skill-2]
3. [Step 3, e.g., "Validate gate criteria"]
4. [Step 4, e.g., "Present findings: X met, Y unmet, Z partial"]
5. [Step 5, e.g., "Ask user: approve / address / skip / pause"]
6. [Step 6, e.g., "Update ADO work item"]

## Gate Protocol

### Gate [N] Definition
[Gate name and description from gate-enforcement.md]

**What AI Validates**:
- [Criterion 1, e.g., "PRD has 7 sections complete?"]
- [Criterion 2]

**Ask Prompt**:
"[Gate [N] check message. E.g., 'PRD check: X/Y sections complete. Proceed? (1) Yes (2) I'll fix gaps (3) Skip']"

**User Options**:
- (1) Proceed — accept current state
- (2) Provide missing info — user fills gaps
- (3) Skip — move forward, note what's incomplete
- (4) Pause — work on gaps before continuing

## Output

### Files Created
- [output-file-1.md] — [Description, e.g., "Findings summary with X findings, Y recommendations"]
- [output-file-2.json] — [Description]

### ADO Actions
- **Tags**: Add [e.g., `prd:reviewed`, `ready:pre-grooming`]
- **Blocking Tags**: Add [e.g., `blocked:prd-review`] if [condition]
- **Create Tasks**: [Describe any tasks created for gaps found]
- **Add Comment**: "[Comment template, e.g., 'PRD Review Complete — 7-check: [results]']"
- **Work Item State**: [Keep open / Mark done / etc.]

### State Saved
- `.sdlc/stage` updated to this stage
- `.sdlc/memory/[stage]/outputs.md` created with results
- ADO comment logged with user decision

## Next Stage Options

After this stage completes, user can:
- (1) Move to [Next Stage Name] (normal flow)
- (2) Loop back to this stage (address findings)
- (3) Jump to [Alternative Stage] (if applicable)
- (4) Abandon workflow (save progress)

### Normal Flow
Stage [N-1] → **Stage [N]** → Stage [N+1]

### Conditional Paths
- If [condition]: → Stage [alternative]
- If [condition]: → Loop back to Stage [N]

---

## Pre-Conditions & Post-Conditions

### Pre-Conditions
[What must be true before this stage starts?]
- [ ] [E.g., feature work item exists in ADO]
- [ ] [E.g., PRD document attached or linked]

### Post-Conditions
[What's true after this stage completes successfully?]
- [ ] [E.g., ADO work item has `prd:reviewed` tag]
- [ ] [E.g., dependencies identified and linked]

---

## Example

### Input
```
Work item: Feature US-1234 (Recommendation Carousel)
PRD: [attached PDF]
```

### Execution
1. Load PRD and stage definition
2. Invoke product-manager-agent
   - Check G1 gate (PRD approved?)
   - Use prd-gap-analyzer skill
3. Present findings:
   - G1 Status: Partial (3/7 sections complete)
   - Gaps: OpenAPI contract missing, edge cases not documented
4. Ask: "Address gaps? (1) Yes (2) Proceed anyway (3) Pause"
5. User chooses (2) Proceed anyway
6. Record decision in ADO comment

### Output
```
PRD Review Findings:
- Status: PARTIAL
- Complete: Objectives, Success Metrics, User Stories
- Gaps: OpenAPI Contract, Edge Cases, Performance NFRs
- User Decision: PROCEED (gaps will be addressed post-sprint)
- Gate G1: Approved with gaps acknowledged
```

---

## See Also

- `rules/gate-enforcement.md` — Gate definitions G1-G10
- `stages/[N-1]-[previous-stage]/STAGE.md` — Previous stage
- `stages/[N+1]-[next-stage]/STAGE.md` — Next stage
- `agents/[category]/[role]-agent.md` — Agent this stage invokes
- `skills/*/SKILL.md` — Skills used by agents

---

**Created**: [YYYY-MM-DD]  
**Last Updated**: [YYYY-MM-DD]  
**Governed By**: AI-SDLC Platform
