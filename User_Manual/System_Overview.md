# System Overview

## 1. What This System Is

AI-SDLC is an AI-native orchestration platform that manages the full software development lifecycle — from requirement intake to release — across multiple teams, roles, and tech stacks.

It runs inside your IDE (Cursor, Claude Code) or terminal. One command sets it up. Natural language drives execution.

## 2. What It Does (End-to-End)

```
PRD → Stories → Tasks → Design → Code → Review → Test → PR → Merge → Deploy → Docs → ADO Sync
```

**Story files:** Use `sdlc story create` for 4-tier templates, fill in IDE or locally, then `sdlc story push <file.md>` to create the Azure DevOps work item (see [Commands](Commands.md)).

**15 stages, 10 gates, 8 roles, 6 tech stacks, multiple bundled workflows.**

Important outputs land in **repo files**, **`.sdlc/`** (state, optional memory exports), and **Azure DevOps** when you configure ADO — not every stage writes the same three places; see [SDLC_Flows](SDLC_Flows.md) per stage.

## 2a. Where it runs — **what**, **how**, **where**

### Two repositories in a normal setup

| | **What** | **How** | **Where** |
|---|-----------|---------|------------|
| **Platform repo** (`ai-sdlc-platform`) | Canonical **stages**, **skills**, **agents**, **rules**, slash-command markdown, CI scripts, this **User_Manual**. | You **clone** it once (or use a shared team path). **`cli/sdlc-setup.sh`** creates **symlinks** from your app into this tree so updates flow from `git pull` on the platform. | Your machine: e.g. `…/ai-sdlc-platform/stages/`, `…/skills/`, `…/rules/`. |
| **Application repo** (your product) | Your **source code**, **tests**, **PRDs**, **stories**, and **`.sdlc/`** state for that product. | You run **`./setup.sh /path/to/app`** (or equivalent) so the app gets `.sdlc/`, `.claude/`, `.cursor/`, `env/`, and **git hooks**. | App root: `.sdlc/`, `.claude/` → platform, `env/.env` (not committed). |

For clone URLs and IDE vs terminal entry points, see [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md).

### What happens when you “run a stage”

| | **What** | **How** | **Where** |
|---|-----------|---------|------------|
| **Terminal** | One **SDLC step** runs with the right prompts and scripts. | **`sdlc use`** sets persona; **`sdlc run <stage-id>`** loads stage metadata and drivers from the **platform** `stages/` tree (variants by **stack**). | Stdout/stderr; optional writes under **`.sdlc/`**; ADO via **`sdlc ado`** when PAT is set. |
| **IDE (Cursor / Claude Code)** | Same **intent** as `sdlc run`, packaged for chat. | Slash **`/project:…`** loads a command file that points at **skills** / checklists; the model follows that recipe. | Chat transcript; edits in your **workspace**; same `.sdlc/` and ADO as CLI when hooks/tools run. |

Mechanics (hooks, token budgets, module load): [Features — how they work](FEATURES_REFERENCE.md).

### Where “intelligence” is split (so you know what to open)

| Store | **What** | **How** | **Where** |
|-------|-----------|---------|------------|
| **Module KB** | Facts **mined from code** (APIs, contracts, layout). | **`sdlc module init`** / **`module update`** (often via **hooks**). | **`.sdlc/module/`** (mostly **committed**). |
| **Semantic memory** | **Decisions** and long-lived prose not inferable from code alone. | **`sdlc memory semantic-*`**; team bus via **JSONL** + hook **import/export**. | **`.sdlc/memory/`** (SQLite local; JSONL in git — see [Persistent_Memory](Persistent_Memory.md)). |
| **Azure DevOps** | Work items, boards, PRs. | **`sdlc ado`**, **`sdlc story push`**, **MCP tools** in the IDE. | Cloud; credentials in **`env/.env`**. |

## 2b. How this overview fits the rest of the manual

| You want… | Start here (this page) | Then read |
|-------------|------------------------|-----------|
| **Product story** — counts, principles, why | §1–§6 | — |
| **Stage-by-stage** — inputs, outputs, slash names | §2 pipeline | [SDLC_Flows](SDLC_Flows.md) |
| **Mechanics** — files, hooks, symlinks | §2a | [Features — how they work](FEATURES_REFERENCE.md) |
| **Commands & flags** | — | [Commands](Commands.md) |
| **One narrative PRD → merge** | — | [Happy_Path_End_to_End](Happy_Path_End_to_End.md) |

## 3. Core Capabilities

- **Any team, any stage** — Product, Backend, Frontend, QA, UI, TPM, Performance, Boss
- **Natural language execution** — `sdlc run 08-implementation` or `/project:implementation` in IDE chat
- **Distributed memory** — Cross-team context sharing via git-synced `.sdlc/memory/`
- **Ask-first model** — AI informs and suggests; user always decides
- **Atomic architecture** — Skills, agents, rules are independent, composable, reusable
- **Module intelligence** — Smart context loading (2-3K tokens vs 12K full load)

## 4. Key Features

- PRD-to-execution pipeline with automated story/task generation
- 10-gate validation (informational, not blocking)
- Unit test enforcement and code review agents
- PR validation with security gates and impact analysis
- Azure DevOps 2-way sync via MCP (IDE) and REST API (CLI)
- Auto-documentation on merge
- Parallel multi-branch development with conflict detection
- Token budget enforcement per role, per stage
- Memory merge with ADO auto-linking on branch merge

## 5. Why It Is Effective

- **Eliminates duplication** — Atomic docs, single-definition principle
- **Ensures traceability** — Every decision logged in ADO + git memory
- **Reduces manual coordination** — Distributed memory replaces meetings for context sharing
- **Improves developer velocity** — Smart context loading, pre-built templates, agent-assisted stages
- **Maintains consistency** — Rules hierarchy enforced: Stage > Stack > Global
- **Prevents degradation** — Gate validation, doc-update triggers, PR checks

## 6. Design Principles

| Principle | Meaning |
|-----------|---------|
| Atomic reuse | Each skill/agent/rule is standalone and composable |
| Modular architecture | Add roles, stacks, stages without touching core |
| Ask-first | AI never acts autonomously — always asks user |
| Low token usage | Smart loading, tiered context, budget enforcement |
| Self-validating | `sdlc doctor`, `scripts/verify.sh`, gate checks |
| Single source of truth | One definition per concept, cross-reference everything |

## 7. Component Inventory (Current)

Counts drift as the repo evolves; run **`sdlc doctor`** and inspect `agents/`, `skills/`, `.claude/commands/` for live totals.

| Component | Count (approx.) |
|-----------|-----------------|
| Agents | Many tiered agents under `agents/` (universal + domain + specialized) |
| Skills | Atomic skills + orchestrators under `skills/` and `orchestrator/` |
| Stages | 15 (`01-requirement-intake` → `15-summary-close`) |
| Gates | 10 (G1–G10), **advisory** by default |
| Roles | 8 product/engineering personas |
| Tech Stacks | 6 primary lanes (Java/TEJ, Kotlin/Android, Swift/iOS, RN, JMeter, Figma) |
| Workflows | Bundled flows such as `full-sdlc`, `dev-cycle`, `quick-fix`, `plan-design-implement`, `boss-report` — **`sdlc flow list`** |
| Git hooks | Installed wrappers + platform scripts (see [PR_Merge_Process](PR_Merge_Process.md)) |
| IDE rules | Policy rules under `rules/` mirrored into `.cursor/rules/` at setup |
| CLI / slash | **`sdlc help`**, [Commands](Commands.md) for slash list |

## 8. Enforcement Summary

| Enforcement | Type | Hook/Rule |
|------------|------|-----------|
| Secrets detection | HARD BLOCK | pre-commit.sh |
| AB# traceability | HARD BLOCK | pre-merge-trace.sh |
| Commit message format | HARD BLOCK | commit-msg.sh |
| Branch naming | HARD BLOCK | branch-name-check.sh |
| Token budget | HARD BLOCK | token-guard.sh |
| Test bypass | HARD BLOCK (requires TPM/Boss approval) | test-bypass-escalation.sh |
| Gate validation | ADVISORY | gate-advisory.sh |
| Doc drift detection | WARNING | doc-change-check.sh |
| Duplication detection | WARNING | pre-merge-duplication-check.sh |

> For deeper details, ask: "Explain the stage execution flow" or "How does distributed memory work?"
