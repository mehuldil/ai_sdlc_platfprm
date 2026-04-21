# Role Template: [Role Name]

Replace `[Role Name]` with your role (e.g., "Data Engineer", "Security Engineer").

---

## Role Definition

### Title
[Job title, e.g., "Data Engineer", "Security Architect"]

### Function
[One paragraph describing what this role does in the SDLC. E.g., "Manages data pipelines, schemas, and analytics infrastructure for all features."]

### Responsibilities
- [ ] [Responsibility 1]
- [ ] [Responsibility 2]
- [ ] [Responsibility 3]
- [ ] [Responsibility 4]
- [ ] [Responsibility 5]

### Constraints
[What can't this role do? E.g., "Cannot deploy to production (only DevOps can). Cannot approve design (only architects can)."]

## Token Budget
- **Input tokens**: [e.g., 6000] — How much context can be loaded?
- **Output tokens**: [e.g., 4000] — How much output is expected?

**Rationale**: [Why this budget? E.g., "High input needed for code review (loads large files), moderate output for recommendations."]

## Example Workflow

When I run `sdlc use [role]`, what happens?

1. User selects role → Load role context from this file
2. User selects stage → Load stage definition
3. Agent loads relevant work item and team memory
4. Agent invokes skills (code review, gap analysis, etc.)
5. Agent presents findings → User decides (proceed/fix/skip)
6. State saved to `.sdlc/state.json`

## Integration

**Where this role appears in workflows**:
- [Stage name]: [purpose, e.g., "Code review in stage 09"]
- [Stage name]: [purpose, e.g., "Validation in stage 07"]

**Agent**: See `agents/[category]/[role]-agent.md`

**Skills**: See `skills/[role]/SKILL.md` (if role-specific)

**Team Memory**: See `memory/team/[role]/` (conventions, lessons learned, baselines)

---

**Created**: [YYYY-MM-DD]  
**Last Updated**: [YYYY-MM-DD]  
**Governed By**: AI-SDLC Platform
