# AI-SDLC Platform — User Manual (home)

Welcome. This manual is written for **everyone** on the team: developers, testers, product owners, and leads. You do **not** need to know how the AI works internally to get value — in **`manual.html`**, read the **sidebar top to bottom** (that order is intentional), or open **[INDEX](INDEX.md)** for the numbered list and glossary.

## What is this?

**AI-SDLC** is a **workflow + documentation + tooling** layer around your normal Git and Azure DevOps habits. It helps you:

- Move work through **clear stages** (from a PRD to code, tests, and merge).
- Use the **same ideas** in the terminal, in Cursor, or in Claude Code (slash commands and chat).
- Keep **optional** long-lived **memory** (decisions) and a **knowledge base** built from your **code** (module system).

Nothing replaces your judgement or your release process — the platform **guides** and **automates the boring parts** (hooks, templates, context).

## The three fastest ways to read

| Way | Best for |
|-----|----------|
| **[Index & reading guide](INDEX.md)** | **Start here** — pick a goal (“install”, “merge”, “memory”) and we point you to the right page. |
| **[manual.html](manual.html)** in a browser | **Offline** — one file, sidebar, **search** (try several words; all must appear). Press **Ctrl+K** / **Cmd+K** for quick search. |
| Stay in **Markdown** in the repo | Developers editing docs — same content as the HTML file. |

## Clone the platform (canonical)

**Azure DevOps** — project **YourAzureProject**, repo **AI-sdlc-platform**:

```bash
git clone https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git
cd AI-sdlc-platform
```

Then open **[Getting_Started](Getting_Started.md)** (`./setup.sh`, `env/.env`, `sdlc doctor`). Use your team’s auth (PAT, Git Credential Manager, or SSH) if prompted.

## Short navigation (same order as `manual.html` sidebar)

| # | Topic | Document |
|---|-------|----------|
| 1 | **Index & glossary** | [INDEX](INDEX.md) |
| 2 | **Big picture** | [System_Overview](System_Overview.md) |
| 3 | **Requirements before install** | [Prerequisites](Prerequisites.md) |
| 4 | **Install & first run** | [Getting_Started](Getting_Started.md) |
| 5 | **Repo + IDE layout** | [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md) |
| 6 | **PRD → merge (one story)** | [Happy_Path_End_to_End](Happy_Path_End_to_End.md) |
| 7 | **Stages & workflows** | [SDLC_Flows](SDLC_Flows.md) |
| 8 | **Roles & who does what** | [Role_and_Stage_Playbook](Role_and_Stage_Playbook.md) |
| 9 | **Features — what they are & how they run** | [FEATURES_REFERENCE](FEATURES_REFERENCE.md) |
| 10 | **All commands** | [Commands](Commands.md) |
| 11 | **When something fails** | [Guided_Execution_and_Recovery](Guided_Execution_and_Recovery.md) |
| 12 | **Memory vs module KB** | [Persistent_Memory](Persistent_Memory.md) |
| 13 | **ADO & MCP** | [ADO_MCP_Integration](ADO_MCP_Integration.md) |
| 14 | **Agents, skills, rules** | [Agents_Skills_Rules](Agents_Skills_Rules.md) |
| 15 | **Architecture** | [Architecture](Architecture.md) |
| 16 | **PRs & AB#** | [PR_Merge_Process](PR_Merge_Process.md) |
| 17 | **Extend the platform** | [Platform_Extension_Onboarding](Platform_Extension_Onboarding.md) |
| 18 | **Doc rules & manual build** | [Documentation_Rules](Documentation_Rules.md) |
| 19 | **V1 → V2** | [Migrating_From_V1_to_V2](Migrating_From_V1_to_V2.md) · [V2_Improvements_Over_V1](V2_Improvements_Over_V1.md) |
| 20 | **FAQ** | [FAQ](FAQ.md) |
| 21 | **Manual changelog** | [CHANGELOG](CHANGELOG.md) |

## How search in `manual.html` works

- Search only scans **this manual** (embedded text), not your project or ADO.
- Type **one word** or **several words**. Several words mean: **show pages that contain every word** (order does not matter).
- Regenerate after editing Markdown: `node User_Manual/build-manual-html.mjs` from the platform repo root (needs Node 18+).

## Principles (short)

- **One concept, one primary page** — we link instead of copying long explanations.
- **You can always ask the IDE** — “Explain stage 08” or “What is semantic memory?” — the assistant should use this manual as ground truth.

## Older documentation

Historical material lives in **git history**. Example: `git log --all --diff-filter=D -- "*.md"`.
