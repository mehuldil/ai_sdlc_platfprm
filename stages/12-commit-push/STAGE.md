---
name: Commit & Push
description: Pre-commit checks, create commit, push to remote
phase: 6
requires_stages: [Test Execution]  # advisory — stage can run independently
gate: G4 (two gates: Approve Commit, Approve Push)
model: sonnet-4-6
token_budget:
  input: 4000
  output: 2000
---

# Commit & Push

## When to Run
Developer prepares and pushes code. Any role can invoke, developer decision at gates.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Test Execution]
   - If completed: load outputs from `.sdlc/memory/12-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Reviewed code, passing tests

## Pre-Conditions
- Test Execution Complete
- Code changes staged in feature branch
- workflow-state.md: test-status=approved

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- Feature branch git status
- git diff --stat
- Conventional Commits guidelines
- Pre-commit checklist

### Load If Available
- ADO work item ID
- Recent commits (for style pattern)

## Execution Steps

### Pre-Commit Phase
1. Run pre-commit checks:
   - No System.out/err prints in code
   - No secrets/API keys in files
   - No commented-out code blocks
   - Linter passes (ESLint for JS, Checkstyle for Java)
2. Show git status (list modified files)
3. Show git diff --stat (file change summary)
4. WAIT for user approval (Gate 1)

### Commit Phase
1. Create commit message: Conventional Commits format
   - Type: feat/fix/chore/refactor/test/docs
   - Format: `{type}: {description} (AB#{work-item-id})`
   - Example: `feat: Add photo filter endpoint (AB#12345)`
2. Execute: git commit -m "..."
3. Present commit hash and message
4. WAIT for user approval (Gate 2)

### Push Phase
1. Execute: git push origin feature/US-{id}-{short-name}
2. Present push confirmation (remote branch URL)
3. Update ADO task state: "Dev Complete"
4. Enforce G4 checks:
   - ADR acceptance status confirmed
   - OpenAPI spec committed (if API task)
   - DB migration linked in ADO (if data task)
   - NFRs quantified in story
   - Build passes (CI check)
   - Spring Boot config updated (if config change)

## Gate Protocol
Show pre-commit → Ask "Commit?" → Show commit message → Ask "Push?" → Execute push

## Output
- Commit hash (linked to ADO)
- Feature branch pushed to remote
- ADO task state updated

## ADO Actions
- Task state: Review Complete → Dev Complete
- Add tags: commit:done, pushed:origin
- Add comment: "Code committed and pushed — [commit-hash] — Branch: feature/US-{id}-{short-name}"
- Link commit to work item

## Next Stage Options
- 13-documentation (if push successful)
