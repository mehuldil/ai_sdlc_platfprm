# Azure DevOps Standards

## Organization & Project
- **Organization**: your-ado-org
- **Project**: YourAzureProject
- **All AI-generated work items**: Must carry `claude:generated` tag

## Work Item Types
1. **Epic** — Large initiatives spanning quarters
2. **Feature** — Shippable work (sprint-level)
3. **User Story** — End-user value (story points, 17-section format)
4. **Task** — Engineering work supporting stories
5. **Bug** — Defect fixes

## State Transitions
- **New** → Approved → Committed → In Progress → Done
- **Blocked** state: Can transition from any active state; must link to blocking work item
- **Closed** state: Terminal (Done or Won't Do)

## Tag Conventions (40+ Tags)

### Story Type Tags
- `story:product` — Product story
- `story:backend` — Backend implementation
- `story:frontend` — Frontend implementation
- `story:database` — Data model work
- `story:qa` — Testing story

### Status Tags
- `prd:reviewed` — PRD reviewed by product
- `blocked:prd-review` — Blocked on PRD review
- `ready:pre-grooming` — Ready for pre-grooming
- `pregrooming:complete` — Pre-grooming done
- `blocked:pre-grooming` — Blocked on pre-grooming
- `ready:grooming` — Ready for grooming
- `grooming:complete` — Grooming done
- `blocked:grooming` — Blocked on grooming
- `ready:sprint` — Sprint-ready
- `techdesign:reviewed` — Technical design reviewed
- `dev:complete` — Development complete
- `sit:certified` — SIT certification passed
- `pp:certified` — Pre-prod certification passed
- `compliance:done` — Compliance review done
- `perf:approved` — Performance approved
- `release:reviewed` — Release reviewed

### Blocking Tags
- `blocked:api-contract` — Blocked on API contract
- `blocked:design` — Blocked on design
- `blocked:backend` — Blocked on backend
- `blocked:qa` — Blocked on QA
- `adr:required` — ADR required before dev

### Dependency Tags
- `dependency:external` — External dependency
- `dependency:backend-api` — Backend API dependency
- `dependency:db-migration` — DB migration dependency

### Quality Tags
- `analytics:required` — Analytics implementation required
- `claude:generated` — AI-generated work item

## Field Usage
- **Title**: Concise, imperative (e.g., "Implement OAuth2 token refresh")
- **Description**: Narrative + acceptance criteria
- **Assigned To**: Team member responsible
- **Story Points**: 1-13 scale (Fibonacci)
- **Priority**: 1 (highest) to 4 (lowest)
- **Iteration Path**: Current sprint or future sprint

---
**Last Updated**: 2026-04-10  
**Governed By**: AI-SDLC Platform
