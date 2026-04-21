---
name: System Design
description: Architect produces design doc with data flows and tech decisions
phase: 3
requires_stages: [Grooming]  # advisory — stage can run independently
gate: Approve / Edit / Reject
model: opus-4-6
token_budget:
  input: 8000
  output: 4000
---

# System Design

## When to Run
Solution Architect designs system. Any role can invoke, architect approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Grooming]
   - If completed: load outputs from `.sdlc/memory/05-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Groomed stories, stack conventions

## Pre-Conditions
- Grooming Complete
- User Stories created
- workflow-state.md: grooming-status=complete

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- **Unified module knowledge** (`.sdlc/module/`) — if present; otherwise plan to generate it from the application repo root:
  - `sdlc module init .` (first time) or `sdlc module update .` (refresh after code changes); read-only: `sdlc module show` / `sdlc module load`
  - Typical paths: `.sdlc/module/contracts/` (`api.yaml`, `data.yaml`, `events.yaml`, `dependencies.yaml`), `.sdlc/module/knowledge/` (`manifest.md`, `known-issues.md`, `impact-rules.md`, `tech-decisions.md`)
- User Stories (all 4N stories)
- design-doc-template.md (includes **§0 Repository baseline & change surface** plus §1–§7)
- adr-template.md
- workflow-state.md

### Load If Available
- Module knowledge: `.sdlc/module/knowledge/known-issues.md`, `.sdlc/module/knowledge/impact-rules.md`
- Existing system architecture (for extension/changes)
- Technology decision history
- Performance requirements
- Security policies

### Token efficiency (same stage)
- Prefer **`sdlc module show`** or **`sdlc module load <api|data|events|logic>`** for AI/session context over opening every contract file by default. Use **`all`** only when the change spans many surfaces.
- The written design doc **§0** stays a **summary** (paths + identifiers). Do not require pasting full OpenAPI/YAML into the design artifact; link or cite stable IDs instead (`rules/repo-grounded-change.md` — Token efficiency).

## Execution Steps
1. **Module KB hygiene (application repo):** If designing against a codebase, ensure `.sdlc/module/` exists or refresh it (`sdlc module init .` / `sdlc module update .`). If missing and not yet generated, note that in the design **§0**.
2. **Repo-grounded baseline:** Before drafting the full design, list **affected existing paths** (files, packages, services) and **invariants** (from contracts, code search, and `.sdlc/module/contracts/*.yaml`). This feeds **§0** and must align with **§5** / **§6**.
3. Load design-doc-template.md; identify variant needed (java-backend, mobile-frontend, etc.)
4. Load variant-specific details from variants/{stack}.md
5. Produce design doc using the template; the output **must** include populated **§0 Repository baseline & change surface** (or equivalent checklist), then:
   - What We Build (scope, boundaries)
   - How It Fits (integration points)
   - Data Flow (Mermaid 8.x diagram)
   - Tech Decisions (with rationale)
   - Module Impact (delta; cross-reference §0)
   - What We Don't Change (out of scope; consistent with §0 invariants)
   - Risks & Mitigations
6. Create ADRs (Architecture Decision Records) for each major decision
7. Set ADR status: Proposed (never final at this stage)
8. Present design doc and ADRs for review
9. WAIT for user feedback

## Gate Protocol
When `.sdlc/module/` exists in the target application repo, reviewers **should** verify **§0** is populated (paths, contracts, regression risk).  
Present design → Ask "Approve / Edit / Reject?" →
- Approve → apply tags, proceed
- Edit → show edit form, incorporate feedback
- Reject → return to grooming

## Output
- design-doc.md (includes §0 plus §1–§7, with Mermaid diagrams)
- adr-{decision-id}.md files (Proposed status)
- design-summary.md (1-page overview)

## ADO Actions
- Add tags: adr:required, design:complete, ready:design-review
- Tag by stack: design:java-backend, design:mobile-frontend, etc.
- Add blocking tags if external dependencies: blocked:api-contract, blocked:design, dependency:external
- Link design-doc.md to Feature
- Add comment: "Design Complete — [N] ADRs created, [X] integration points identified"

## Next Stage Options
- 06-design-review (if Design Approved)
- 05-system-design (if Edit selected — loop back)
- 04-grooming (if Reject — return to previous phase)
