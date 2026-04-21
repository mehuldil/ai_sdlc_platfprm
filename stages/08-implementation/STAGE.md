---
name: Implementation
description: Developers implement tasks using RPI loop (Research-Plan-Implement)
phase: 4
requires_stages: [Task Breakdown]  # advisory — stage can run independently
gate: Multiple (per RPI step: Research → Plan → Implement)
model: sonnet-4-6
token_budget:
  input: 6000
  output: 4000
---

# Implementation

## When to Run
Developers implement tasks. Any role can invoke, but developer executes RPI loop.

## Independent Execution

This stage can be invoked independently at any time by any role.

### Pre-Flight Checks
When running standalone (not as part of a workflow):
1. Check `.sdlc/role` — if not set, ask user to run `sdlc use <role>`
2. Check `.sdlc/stage` — update to this stage
3. Check smart routing classification in `.sdlc/memory/routing.md` — if not set, run classification first
4. Check required stage completions: [Task Breakdown]
   - If completed: load outputs from `.sdlc/memory/08-completion.md`
   - If NOT completed: warn user, ask to continue or abort

### Minimum Context Required
- Task list, stack conventions, API contracts

## Pre-Conditions
- Tasks created in ADO in stage 07
- Feature branch naming: feature/US-{id}-{short-name}
- workflow-state.md ready for tracking

## Context Loading (Minimal — load ONLY what's needed)
### Always Load
- **Unified module knowledge** (`.sdlc/module/`) — if present; refresh from application repo root with `sdlc module update .` when the codebase changed
  - Typical: `.sdlc/module/knowledge/manifest.md`, `.sdlc/module/contracts/api.yaml`, `.sdlc/module/knowledge/impact-rules.md`
- Task work item from ADO
- design-doc.md (for context), especially **§0**, **§5**, and **§6**
- variant-specific guardrails ({stack}-guardrails.md)

### Load If Available
- Similar completed tasks (for patterns)
- Performance baselines
- Security checklist

### Token efficiency
- Load **module slices** (`sdlc module load …`) or **specific files** from the plan/design §0—avoid pulling the full `.sdlc/module/` tree into context when a narrow slice suffices.

## Execution Steps
Per task, execute RPI loop:

### Research Phase
1. Invoke /rpi-research skill
2. Load research-prompt.md (task-specific)
3. Load max 10 files, 2K chars each
4. Generate research.md (read-only artifact)
5. Present research findings
6. WAIT for user approval

### Plan Phase
1. Load research.md (locked input)
2. Invoke /rpi-plan skill
3. Generate plan.md (implementation steps, file changes, code structure) **explicitly tied** to the approved design doc **§0** and **§5** (files, modules, contracts)
4. Present plan (with code outline)
5. WAIT for user approval

### Implement Phase
1. Load plan.md (locked input); ensure the plan maps to **files and modules** called out in the approved design doc **§0** / **§5** (and respects **§6**).
2. Invoke /rpi-implement skill
3. Create feature branch: feature/US-{id}-{short-name}
4. Implement code per plan.md
5. Update workflow-state.md after each task: Task=InProgress → Task=CodeComplete
6. Present code changes (git diff)
7. WAIT for user approval

### Post-Implementation
1. **Before marking development complete:** run **unit tests** for **changed code** and **targeted regression** tests (same package/module, or the suite agreed in the task / stack variant—e.g. JUnit, pytest, Jest, Go test). Document what ran or attach CI output.
2. Update workflow-state.md: Task=ReadyForReview
3. Run `sdlc kb update [repo-path]` (or `sdlc module update .` in the application repo) to keep module knowledge current
4. Prepare for 09-code-review

## Gate Protocol
Research → Ask "Approve?" → Plan → Ask "Approve?" → Implement → Ask "Approve?" →
- Approve each step → proceed to next
- Reject → redo phase

## Output
- research.md (per task)
- plan.md (per task)
- Code committed to feature branch
- workflow-state.md updated

## ADO Actions
- Task state: Open → In Progress → Code Complete
- Add tags: impl:research, impl:plan, impl:implement (per phase)
- Add comment: "Research Complete — [key findings]" (after research)
- Add comment: "Plan Complete — [X] files to create/modify" (after plan)
- Add comment: "Implementation Complete — [commit hash]" (after implement)

## Next Stage Options
- 09-code-review (after all tasks implemented)
- 08-implementation (if task loop continues)
