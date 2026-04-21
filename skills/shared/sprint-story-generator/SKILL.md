---
name: sprint-story-generator
description: Generate Sprint Stories from Master Story + sprint scope — ADO-ready PRD lift, UI/Figma, non-redundant sections
model: sonnet-4-6
token_budget: {input: 6000, output: 4000}
---

> **Context:** Use **parent Master Story** + PRD section ids. Prefer `prd-gap-analyzer` if PRD quality is in question.
>
> **Authoring standards:** [templates/AUTHORING_STANDARDS.md](../../templates/AUTHORING_STANDARDS.md)

# Sprint Story Generator

## Role

Senior CSPO + Tech Lead: one sprint, one shippable slice. The **Sprint Story work item must stand alone** in Azure DevOps.

## Input

- Master Story (or link + id)
- Sprint id, capacity, scope boundaries
- Which Master ACs / capabilities are **in** vs **out** this sprint

## Non-negotiables

1. **📎 PRD / Master lift:** Include **full** user-visible strings for everything touched this sprint (notifications, errors, labels). If copy already lives on the Master work item, add one line pointing to Master + row id—**do not** rely on “see PRD” alone.
2. **No invention:** Missing facts → `USER_INPUT_REQUIRED` per `STORY_TEMPLATE_REGISTRY.md`.
3. **No redundancy:** **Context** = why this sprint. **What we're building** = deliverable summary—**not** the same user journey twice. **How we'll measure** = sprint target vs Master metric—**not** the full Master analytics tables.
4. **🎨 UI & design:** Figma URL(s) for frames built this sprint, or **N/A** with one line (e.g. backend-only).
5. **Readable:** Short sentences, **bold** labels, bullets, tables for copy.

## Output

Fill **`templates/story-templates/sprint-story-template.md`** completely. Key sections:

- Scope (IN/OUT)
- **📎 PRD / Master lift (this sprint)**
- Technical approach
- Acceptance criteria (checkboxes)
- **🎨 UI & design**
- Dependencies, risks, DoD
- Traceability (parent Master + PRD ids)

## Command example

```yaml
Command: generate sprint story

MASTER_STORY: ONBOARD-AUTH
SPRINT: 12
SCOPE: "Phone entry + OTP happy path"
INCLUDE_ACS: AC-01, AC-02, AC-03
```

## See also

- **Master story:** `skills/shared/story-generator/`
- **Tasks:** `skills/shared/tech-task-generator/`
- **Validate:** `skills/shared/story-validator/`
