---
name: Documentation
description: Architect creates/updates architecture and API documentation
phase: 6
requires_stages: [Commit & Push]  # advisory — stage can run independently
gate: Approve/Edit/Skip Docs + Sync/Skip Wiki
model: opus-4-6
token_budget:
  input: 8000
  output: 4000
---

# Documentation

## When to Run
Architect updates documentation. Any role can invoke, architect approval required at gate.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Commit & Push]
   - If completed: load outputs from `.sdlc/memory/13-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Completed code, API specs

## Pre-Conditions
- Code committed and pushed
- workflow-state.md: commit-status=complete
- Feature changed architecture or API (or not)

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- design-doc.md (from stage 05)
- Existing docs/ProjectName-Architecture.md (if exists)
- Existing docs/ProjectName-ApiDocumentation.md (if exists)

### Load If Available
- OpenAPI spec from code
- git diff (what changed)
- ADRs from stage 05

## Execution Steps
1. Assess documentation needs:
   - Did architecture change? → update docs/{ProjectName}-Architecture.md
   - Did API change? → update docs/{ProjectName}-ApiDocumentation.md
   - No changes? → skip to wiki sync or skip entirely
2. If architecture docs needed:
   - Load architecture doc template (8 sections)
   - Update sections: Overview, Components, Data Flow (Mermaid 8.x), Integration Points, Decisions, Deployment, Monitoring
   - Generate/update Mermaid diagrams
3. If API docs needed:
   - Load API documentation template (8 sections)
   - Update: Endpoints, Authentication, Request/Response, Error Codes, Rate Limits, Examples, Deprecations, Changelog
   - Sync with OpenAPI 3.1 spec from code
4. Present documentation changes
5. WAIT for user decision (Docs approval)

### Wiki Sync Phase
1. If docs approved or not changed:
   - Invoke wikijs-mcp-agent
   - Sync docs/ folder to wiki
2. WAIT for user decision (Wiki sync approval)

## Gate Protocol
Present docs → Ask "Approve/Edit/Skip?" →
- Approve → apply tags, proceed to wiki sync
- Edit → show edit form
- Skip → skip to wiki sync decision

Wiki sync → Ask "Sync to Wiki / Skip Wiki?" →
- Sync → sync docs to wiki
- Skip → skip wiki sync

## Output
- Updated docs/{ProjectName}-Architecture.md (if needed)
- Updated docs/{ProjectName}-ApiDocumentation.md (if needed)
- Wiki pages synchronized (if sync approved)

## ADO Actions
- Add tag: docs:updated (if docs created/modified)
- Add tag: wiki:synced (if wiki synced)
- Add tags: docs:architecture, docs:api (by type)
- Add comment: "Documentation updated — [X] sections modified, wiki synced"
- Link docs to Feature

## Next Stage Options
- 14-release-signoff (if docs complete)
