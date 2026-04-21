# 📋 Sprint Story — [Feature / Sprint Scope Name]

> **ADO completeness:** This work item must stand alone in Azure DevOps. Include **full** user-visible strings for **this sprint’s** scope (notifications, errors, labels). Do **not** reference PRD codes (e.g. **Nx**, **§4.2**) without the lifted text, unless the **Master Story** already contains it and you add one line: “**Copy:** same as Master Story § PRD-sourced specifics — row **[id]**” plus the **Master work item link**.
>
> **No invention:** Missing facts → `USER_INPUT_REQUIRED`, not generic filler.
>
> **No redundancy:** **Context** = why this sprint. **What we're building** = deliverable summary only—do not paste the same user journey twice. **How we'll measure** = sprint delta vs master metric; do not re-copy the entire Master analytics section.

---

## 🎯 What We're Building
**<What exactly gets built this sprint?>**

- **Feature/Change:** [Specific, scoped feature]
- **User Impact:** [How does this move the needle on master story metric?]
- **Sprint Acceptance:** [This sprint is done when...]

---

## 🔍 Context
**<Why this sprint? What does it enable?>**

- **Why now:** [Why this sprint, not later?] *(optional)*
- **What it enables:** [What downstream work does this unblock?] *(optional)*
- **User scenario:** [Concrete example of how user will use this]

---

## ⚡ Scope
**<What's IN? What's OUT?>**

### ✅ Included (This Sprint)
| # | Capability | From Master Story |
|---|------------|-------------------|
| 1 | [What's being delivered] | [Reference to master AC or section] *(optional)* |
| 2 | [What's being delivered] | |

### 🚫 Excluded (Future Sprints)
| Capability | Reason | Target Sprint |
|------------|--------|---------------|
| [Deferred item] | [Why not now] | [Sprint X] *(optional)* |

### ⚠️ Assumptions *(optional)*
- [Assumption that must be true for this scope]
- [Dependency that's expected to be ready]

---

## 📎 PRD / Master lift *(this sprint only)*

**Purpose:** Verbatim facts needed to build/test **this sprint**, so engineers never open the PRD.

**Rules:**

- For every notification/error/label **touched this sprint**, include **full text** (or exact pointer to Master Story row + ADO id where it already lives).
- If nothing user-visible changes this sprint, state **N/A — backend/invisible change** and skip the tables.

### Notifications & copy (sprint scope)

| ID / ref | Full text (all locales required by PRD) | Notes |
|----------|----------------------------------------|-------|
| | | |

### Errors & edge copy (sprint scope)

| ID / ref | Full text | When shown |
|----------|-----------|------------|

---

## 🏗️ Technical Approach
**<How we'll build it - architecture level, not code>**

- **Architecture:** [e.g., "Client-side state machine", "Server-side orchestration"] *(optional)*
- **Tech choices:** [e.g., "React Suspense for loading", "GraphQL for data fetch"] *(optional)*
- **Integration points:** [What systems does this touch?] *(optional)*
- **Data model:** [New tables/schemas needed?] *(optional)*

---

## 🧾 Acceptance Criteria
**<This sprint is DONE when...>**

Use **numbered** checklist items (`1. [ ]`, `2. [ ]`, …). **Each criterion on its own line;** put a **blank line between** items.

### Happy Path

1. [ ] Feature works end-to-end for [scenario]

2. [ ] [Success metric] is trackable in logs *(optional)*

3. [ ] Performance: [Latency/throughput target] *(optional)*

4. [ ] No console errors in [browsers/devices] *(optional)*

### Edge Cases *(optional)*

1. [ ] [Edge case 1]: Expected behavior is [X]

2. [ ] [Edge case 2]: User sees [error message/fallback]

3. [ ] [Error handling]: System prevents [failure mode]

### Quality Standards *(optional)*

1. [ ] Unit test coverage ≥ [X]%

2. [ ] Accessibility: [WCAG standard] compliance

3. [ ] Documentation: [README/API doc/inline comments]

---

## 🎨 UI & design

**Purpose:** Figma and design readiness for **this sprint** (not duplicate of Master if unchanged—link Master + sprint frames).

- **Figma (primary):** [URL] — **Frame / page:** [name] — **Last updated:** [date]
- **Master Story UI (if reusing):** [ADO link or “same component — no new frame”]
- **Prototype:** [URL] *(optional)*
- **Interactions covered this sprint:** [Short bullet list] *(optional)*
- **Responsive / platforms:** [e.g. Android + iOS, or web only] *(optional)*
- **Design status:** [ ] Draft  [ ] Ready for dev  [ ] N/A (no UI this sprint)

*Backend-only sprint:* set **N/A** and one line under PRD lift explaining no visible copy change.*

---

## 🔗 Dependencies
**<What must be true before we start?>**

- **Other sprints:** [e.g., "Sprint 3: API contract ready"] *(optional)*
- **Data/Setup:** [e.g., "Feature flag configured", "DB migration deployed"] *(optional)*
- **External:** [e.g., "Payment processor approval"] *(optional)*
- **Blockers:** [Current blockers preventing start?] *(optional)*

---

## 📊 How We'll Measure It
**<Sprint-level signal only — name the master metric once, then sprint target or delta. Do not duplicate the full Master Story measurement tables.>**

- **Primary metric (from Master):** [Name — link Master work item if in ADO]
- **Target *this sprint* (or delta):** [e.g. “+5% vs baseline” or “event X instrumented”]
- **Instrumentation (this sprint):** [What ships now] *(optional)*
- **Baseline:** [If needed for this slice] *(optional)*

---

## ⚠️ Known Risks
**<What could go wrong?>**

- **Technical risk:** [e.g., "Third-party API performance unknown"] *(optional)*
- **Timeline risk:** [e.g., "Design review cycles may delay start"] *(optional)*
- **Data risk:** [e.g., "User segmentation not finalized"] *(optional)*

---

## 👥 Team & Effort
**<Who's building this? How much time?>**

- **Assignee:** [Engineer name] *(optional)*
- **Design:** [Designer if needed] *(optional)*
- **QA:** [QA engineer] *(optional)*
- **Estimated effort:** [5d, 10d, 15d] *(optional)*
- **Confidence:** [High/Medium/Low] *(optional)*

---

## 🚀 Definition of Done
**<Checklist: What makes this sprint complete?>**

1. [ ] Code complete and peer reviewed

2. [ ] Unit tests written and passing

3. [ ] Acceptance criteria verified by QA

4. [ ] Performance benchmarked *(optional)*

5. [ ] Documentation updated

6. [ ] Feature flag toggled for controlled rollout

7. [ ] Analytics events firing correctly *(optional)*

8. [ ] Rollback plan documented *(optional)*

---

## 📝 Notes & Updates
**<Any changes, blockers, or decisions during sprint>**

| Date | Note |
|------|------|
| | |

---

## 📋 Story Metadata

**Status:** [ ] To Do  [ ] In Progress  [ ] In Review  [ ] Done  
**Sprint:** [Sprint Name/Number]  
**Created:** [Date]  
**Last Updated:** [Date]

---

## 🔗 Traceability

**Parent Master Story:** [Link or ID] *(required)*  
**PRD sections covered (from Master):** [e.g. 4B, 4C] *(required)*

---

## ℹ️ Template Info
**Purpose:** Tactical, executable slice for one sprint. Derived from Master Story.  
**Audience:** Engineering, design, QA  
**Created by:** Product Manager / Tech Lead  
**Lifecycle:** Short-term (1-2 sprints)
