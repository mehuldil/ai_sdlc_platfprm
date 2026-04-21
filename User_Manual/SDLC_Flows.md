# SDLC Flows

**Readable end-to-end walkthrough (layman, CLI + IDE + NL):** [Happy_Path_End_to_End](Happy_Path_End_to_End.md).

## Stage Pipeline (15 Stages)

```
01-requirement-intake → 02-prd-review → 03-pre-grooming → 04-grooming
→ 05-system-design → 06-design-review → 07-task-breakdown
→ 08-implementation → 09-code-review → 10-test-design → 11-test-execution
→ 12-commit-push → 13-documentation → 14-release-signoff → 15-summary-close
```

## Each stage — **what**, typical **I/O**, **how** to run, **where** it lands

Use this table with [Happy_Path_End_to_End](Happy_Path_End_to_End.md) for a full narrative. **Mechanics** (how `sdlc run` resolves files) are in [Features — how they work](FEATURES_REFERENCE.md) §2.

**Legend — “Where”:** *repo* = your source tree; *memory* = `.sdlc/memory/` or team JSONL when used; *ADO* = Azure Boards when `env/.env` is configured; *stage dir* = platform `stages/<id>/` scripts and markdown.

### Stages 01–08

| Stage id | **What** (lay) | You usually **bring** | You usually **produce** / **where** | **CLI** | **IDE slash** |
|----------|----------------|------------------------|----------------------------------------|---------|-----------------|
| `01-requirement-intake` | Frame the problem and inputs | PRD draft, links, stakeholders | Intake summary; notes in *memory* / ADO tags | `sdlc run 01-requirement-intake` | `/project:requirement-intake` |
| `02-prd-review` | Stress-test the PRD for gaps | Stable PRD | Review findings; updates in *repo* / ADO | `sdlc run 02-prd-review` | `/project:prd-review` |
| `03-pre-grooming` | Prepare backlog for grooming | Rough stories, dependencies | Scoped candidate list | `sdlc run 03-pre-grooming` | `/project:pre-grooming` |
| `04-grooming` | Agree sprint scope | Candidate backlog | Sprint-ready backlog; *memory* / ADO | `sdlc run 04-grooming` | `/project:grooming` |
| `05-system-design` | Technical architecture & APIs | PRD + constraints + **module** context | Design doc under *repo*; may cite `.sdlc/module/` | `sdlc run 05-system-design` | `/project:system-design` |
| `06-design-review` | Formal design pass | Design doc | Approvals / action items; *ADO* comments | `sdlc run 06-design-review` | `/project:design-review` |
| `07-task-breakdown` | Split into tasks / story files | Sprint story, design | `stories/*.md`, tasks; **ADO** via `sdlc story push` | `sdlc run 07-task-breakdown` | `/project:task-breakdown` |
| `08-implementation` | Implement and unit-test | Tasks, contracts | Code + tests in *repo*; optional *memory* decisions | `sdlc run 08-implementation` | `/project:implementation` |

### Stages 09–15

| Stage id | **What** (lay) | You usually **bring** | You usually **produce** / **where** | **CLI** | **IDE slash** |
|----------|----------------|------------------------|----------------------------------------|---------|-----------------|
| `09-code-review` | Peer review | Branch / PR diff | Review notes; fixes in *repo* | `sdlc run 09-code-review` | `/project:code-review` |
| `10-test-design` | Plan tests & data | NFR, APIs, risks | Test plan markdown / *repo* | `sdlc run 10-test-design` | `/project:test-design` |
| `11-test-execution` | Run automated / manual tests | Test plan, build | Results, logs, defects → *repo* / *ADO* | `sdlc run 11-test-execution` | `/project:test-execution` |
| `12-commit-push` | Commit with traceability; push | Clean working tree | Commits with **AB#**; remote branch | `sdlc run 12-commit-push` | `/project:commit-push` |
| `13-documentation` | User / ops docs | Shipped features | README / docs in *repo* | `sdlc run 13-documentation` | `/project:documentation` |
| `14-release-signoff` | Release readiness | Evidence from 10–12 | Sign-off record; *ADO* state | `sdlc run 14-release-signoff` | `/project:release-signoff` |
| `15-summary-close` | Close the loop | Links to work items | Retrospective / summary in *memory* / *repo* | `sdlc run 15-summary-close` | `/project:summary-close` |

Slash names match [Commands](Commands.md). Token helper: `/project:tokens`.

## Gate Protocol (G1-G10)

| Gate | Check | Stage |
|------|-------|-------|
| G1 | PRD reviewed | 02 |
| G2 | Pre-grooming complete | 04 |
| G3 | Architecture approved | 05 |
| G4 | Design reviewed | 06 |
| G5 | Sprint ready | 07 |
| G6 | Code complete | 08-09 |
| G7 | Tests passed | 10-11 |
| G8 | PR validated | 12 |
| G9 | Integration verified | 13 |
| G10 | Release approved | 14 |

Gates are **informational** — user always decides. AI presents findings, never blocks.

## Stage execution flow (diagram)

```
User runs stage → Context Guard checks role/stack
  → Loads: role.md + STAGE.md + variant.md (stack-specific file under `stages/<stage>/variants/<stack>.md`)
  → Smart routing: SKIP / LITE / FULL gate check
  → Execute stage (agents invoke skills)
  → Save outputs to .sdlc/memory/
  → Update ADO work item
  → Present options: next stage / fix / skip / pause
```

### What (one sentence)

A **stage run** is: resolve **who you are** (role/stack) → load the **platform’s** stage recipe (`stages/<stage-id>/` + stack **variant**) → optionally evaluate **gates** → run the scripted / skill-driven work → persist **artifacts** (repo files, `.sdlc`, ADO) → suggest **next actions**.

### How (order of operations)

1. **Input**: You choose **CLI** (`sdlc run …`) or **IDE** (`/project:…`). Both target the same stage definitions on disk (see [Features — how they work](FEATURES_REFERENCE.md) §2).
2. **Context guard**: Reads **`.sdlc/`** role/stack (from `sdlc use`) so the correct **variant** file loads (e.g. Java vs React Native under `stages/08-implementation/variants/`).
3. **Content load**: Base **`STAGE.md`** plus **stack variant** plus relevant **rules**; optional **`sdlc module load`** for code-grounded facts before design/implementation.
4. **Gates**: **G1–G10** map to milestones in the table above — usually **advisory** (findings shown; you choose proceed/skip). See gate table § "informational".
5. **Execution**: Skills/agents run as defined for that stage (often: generate markdown, checklists, or drive local tools). Exact behavior lives in **platform** `stages/` and linked **skills/**.
6. **Output**: Writes go to **your repo** (docs, stories, code), **`.sdlc/memory/`** when the stage records decisions, and **ADO** when PAT + `sdlc ado` / story push / MCP sync are in play.

### Where (paths to know)

| Kind | Location |
|------|-----------|
| Stage definitions | **Platform** repo: `stages/<stage-id>/` (shared `STAGE.md`, `variants/<stack>.md`, includes under `stages/_includes/`) |
| Role / stack state | **App** repo: `.sdlc/role`, `.sdlc/stack`, `.sdlc/state.json` (as applicable) |
| Decisions / semantic facts | **App** repo: `.sdlc/memory/` (see [Persistent_Memory](Persistent_Memory.md)) |
| Code-derived KB | **App** repo: `.sdlc/module/` |
| ADO | Cloud + **`env/.env`** locally |

## Role Ownership by Stage

| Role | Stages |
|------|--------|
| Product Manager | 01-04, 14-15 |
| TPM | 03-04, 07, 14-15 |
| Backend Developer | 05-09, 12 |
| Frontend Developer | 05-09, 12 |
| QA Engineer | 10-11, (09, 14 secondary) |
| UI Designer | 05-06 |
| Performance Engineer | 06, 10-11 |
| Boss | 01-02, 14-15 |

For **who leads each stage**, **typical order of work**, and **handoffs** (chain of command) across all roles — see **[Role_and_Stage_Playbook](Role_and_Stage_Playbook.md)**.

## Story Pipeline

```
PRD/Feature Request
  → Story Generator Agent (IDE) / sdlc story create (CLI templates)
    → Master Story Template (16 sections, no tasks)
      → Sprint Story Template (13 sections, has tasks)
        → Tech Story + Task Templates (optional / atomic)
          → ADO Work Items: sdlc story push <file.md> [--type=feature|story|epic] or sdlc ado push-story (default: User Story; use --type=feature for master → Feature)
```

- Master story: strategic, long-lived
- Sprint story: tactical, sprint-scoped
- Tech story: optional architecture deep-dive
- Tasks: implementation-level, role-assigned
- **ADO:** markdown stories become work items when you run **`sdlc story push`** (after fill + confirm); use **`--type=feature`** for master stories; prints work item id

## Pre-Built Workflows (9)

| Workflow | Stages | Use Case |
|----------|--------|----------|
| `full-sdlc` | 01-15 | Complete feature lifecycle |
| `dev-cycle` | 05-15 | Design through close (skip planning) |
| `prd-to-stories` | 01-07 | Requirements to task breakdown |
| `quick-fix` | 08-09-12 | Hotfix, skip planning |
| `perf-cycle` | 06-10-11 | Performance testing cycle |
| `test-cycle` | 10-11 | Test design + execution only |
| `design-review-cycle` | 05-06 | Design review only |
| `plan-design-implement` | 03-12 (+13/15 optional) | Strict PLAN -> DESIGN -> IMPLEMENT mode |
| `boss-report` | — | Executive reporting (no stage execution) |

## Plan → Design → Implement Mode

The platform now supports a focused delivery mode through `dev-cycle` plus stage checkpoints:

```
PLAN:   03-pre-grooming + 04-grooming + 07-task-breakdown
DESIGN: 05-system-design + 06-design-review
IMPLEMENT: 08-implementation + 09-code-review + 10/11 tests + 12 commit
```

For strict serialization, use the RPI workflow inside stage 08:
`sdlc rpi research <US-id> -> plan -> implement -> verify`.

### Stack variants and shared RPI baseline

- **Variants** add stack-specific bullets (Java vs RN vs JMeter, etc.) on top of the stage’s `STAGE.md`.
- **Implementation (stage 08)** variants link a single baseline: `stages/_includes/rpi-serialization-baseline.md`, aligned with [`rules/rpi-workflow.md`](../rules/rpi-workflow.md). That avoids repeating the same “Research → Plan → Implement” contract in every stack file.
- **Figma / design-system** work in stage 08 uses `variants/figma-design.md` (tokens/libraries), distinct from mobile/backend codegen stacks.

## Cross-Team Context Flow

```
PM defines (01-04) → Memory stores decisions
  → Backend/Frontend reads context from memory (05-09)
    → QA reads design decisions for test planning (10-11)
      → PM reads test results for release decision (14)
```

Memory is git-synced. Team B pulls Team A's outputs without meetings.

> For flow diagrams (Mermaid), ask: "Show me the SDLC flow diagrams"

> For workflow customization, ask: "How do I create a custom workflow?"
