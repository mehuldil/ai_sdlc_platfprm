# Features — how they work

This chapter explains **what each major capability is** and **how it behaves in practice** (files, processes, entry points). It sits **after** [Happy_Path_End_to_End](Happy_Path_End_to_End.md), [SDLC_Flows](SDLC_Flows.md), and [Role_and_Stage_Playbook](Role_and_Stage_Playbook.md) so you already know *when* you use a feature; here you learn *what runs under the hood*.

For every command name and flag, the authoritative list is still [Commands](Commands.md).

---

## 1. Platform shell and project setup

### What it is

**Setup** wires your **application repository** (or monorepo root) to the **platform package** (`ai-sdlc-platform`) so the same rules, slash commands, MCP config, and CLI behavior appear in every clone of your app.

### How it works

1. You run **`./setup.sh`** from the platform repo, passing your **project path** (or `--self` for the platform repo itself).
2. **`cli/sdlc-setup.sh`** runs against that path. It creates **`PROJECT/.sdlc/`** (state: role, stack, stage metadata), **`PROJECT/.claude/`** and **`PROJECT/.cursor/`** as **symlinks** into the platform’s commands, rules, agents, skills, and templates (so updates to the platform repo show up after pull).
3. It adds **`PROJECT/env/`** (templates for `.env`), optional **`workflow-state.md`**, and updates **`.gitignore`** so secrets and local DB files are not committed blindly.
4. If **`PROJECT/.git`** exists, it installs **wrapper hooks** under **`.git/hooks/`** that call back into the platform (pre-commit secrets/formatting, commit-msg **AB#** enforcement, post-merge / post-checkout / post-commit **auto-sync** scripts when present).
5. On **non-TTY** runs (typical Cursor agent), role / stack / ADO are not read from a keyboard; they are supplied via **`SDL_SETUP_*`** after AskQuestion in chat (see **`cli/sdlc-setup.sh --help`**).

### What you see on disk

| Path | Role |
|------|------|
| `.sdlc/` | Machine-local state, logs, optional SQLite, **ignored** pieces vs **committed** module/memory exports (see granular gitignore rules) |
| `.claude/`, `.cursor/` | IDE integration; mostly **links** to the platform, not copies |
| `env/` | Credentials and endpoints (`ADO_PAT`, …) — **never** commit real `.env` |

### Read more

[Getting_Started](Getting_Started.md), [Prerequisites](Prerequisites.md), [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md), [FAQ](FAQ.md).

---

## 2. Stages and `sdlc run`

### What it is

A **stage** is one step in the delivery lifecycle (numbered **01–15**: intake → … → summary). The platform packages **scripts, prompts, and checklists** per stage under the platform’s **`stages/`** tree (and related rules). Your project does not duplicate that tree; the **CLI** resolves the stage and runs the right orchestration.

### How it works

1. You set **role** (and often **stack**) with **`sdlc use`** so the correct rules and stage variants load.
2. **`sdlc run <stage-id>`** (example: `sdlc run 08-implementation`) loads stage metadata, may run **gate** checks, then invokes the stage’s driver scripts / instructions. Output and decisions can be written to **memory** or **workflow files** depending on the stage.
3. **Slash commands** in the IDE (e.g. `/project:implementation`) are **markdown command files** symlinked from the platform; the IDE sends their content to the model as a structured task — same *intent* as `sdlc run`, different **transport** (IDE vs terminal).
4. Stages are **advisory**: roles do not hard-block you from running another stage, but playbooks explain **recommended** order.

### Read more

[SDLC_Flows](SDLC_Flows.md), [Happy_Path_End_to_End](Happy_Path_End_to_End.md), [Commands](Commands.md).

---

## 3. Workflows (`sdlc flow`)

### What it is

A **workflow** (flow) is a **named sequence** of stages for a scenario (full SDLC, quick-fix, performance cycle, plan-design-implement, boss report, …). It saves you from remembering stage ids in order.

### How it works

1. **`sdlc flow list`** shows bundled workflows defined by the platform.
2. **`sdlc flow <name>`** expands the workflow into **ordered stage runs** (or equivalent driver behavior), reusing the same stage engine as `sdlc run`.
3. Workflows may apply **extra gates** or **serialization** (e.g. plan → design → implement) where the product team wanted stricter sequencing than arbitrary `sdlc run` calls.

### Read more

[SDLC_Flows](SDLC_Flows.md), [Commands](Commands.md).

---

## 4. Roles, stacks, and context

### What it is

**Role** answers: “Who am I *for the AI*?” (product, backend, qa, tpm, …). **Stack** answers: “Which technology lane?” (java-tej, kotlin-android, …). Together they **select** which rules, stage variants, and playbook text apply — they do not change your HR job title.

### How it works

1. **`sdlc use <role> [--stack=…]`** writes into **`.sdlc/`** (e.g. `role`, `stack` files) and refreshes what the next `sdlc run` / IDE session should assume.
2. **`sdlc context`** prints the resolved role, stack, and stage hints for debugging “why did the agent lean QA-style here?”
3. **Rules** in `.cursor/rules` / `.claude` are loaded by the IDE according to its own policy; the platform ensures the **symlinked** rule set matches the repo’s setup.

### Read more

[Role_and_Stage_Playbook](Role_and_Stage_Playbook.md), [Agents_Skills_Rules](Agents_Skills_Rules.md).

---

## 5. Module knowledge base (code-derived)

### What it is

The **module system** builds a **knowledge base from your repository**: service boundaries, **API contracts**, dependencies, and metadata under **`.sdlc/module/`**. It is **ground truth from code**, not prose someone typed once and forgot.

### How it works

1. **`sdlc module init .`** (from your app repo root) runs **`scripts/module-init.sh`** (and related scanners): discovers build files, stack type, routes, etc., and writes/updates YAML/JSON under **`.sdlc/module/`**.
2. **`sdlc module load <slice>`** prints a **bounded** slice (`api`, `data`, `events`, `logic`, `all`) so agents load **only** relevant contracts — saving tokens and reducing hallucinated APIs.
3. **`sdlc module validate`** / **`report`** / **`budget`** support pre-merge hygiene and impact questions (“what breaks if we change this DTO?”).
4. **Hooks**: on **commit** / **merge** / **checkout**, **`sdlc module update`** (when configured) refreshes the KB so what you committed matches what the KB describes. Teammates get updates via **git**, not by copying folders.

### Read more

[Commands](Commands.md) (auto-sync table), [Architecture](Architecture.md), [FAQ](FAQ.md) (module troubleshooting).

---

## 6. Semantic memory (decision-derived)

### What it is

**Semantic memory** stores **decisions**, rationales, QA findings, and other **long-lived text** that is **not** automatically derivable from code. It is **separate** from the module KB (see [Persistent_Memory](Persistent_Memory.md) table at top).

### How it works

1. Locally, an index lives in **SQLite** under **`.sdlc/memory/`** (gitignored) for fast **vector-ish** retrieval.
2. A **team bus** file **`.sdlc/memory/semantic-memory-team.jsonl`** is **committed** so merges carry memory across machines.
3. **Hooks** **export** local writes into JSONL on commit and **import** teammates’ JSONL into your SQLite after **pull / merge / checkout**, so `git` remains the system of record.
4. **CLI**: `sdlc memory semantic-upsert`, `semantic-query`, `semantic-status`, `semantic-lifecycle` manage content and retention policies.

### Read more

[Persistent_Memory](Persistent_Memory.md), [Commands](Commands.md).

---

## 7. Stories (four tiers), PRDs, and traceability

### What it is

**Four-tier stories** structure work from **Master** (initiative) down to **Task** (executable unit): markdown templates with validation rules and optional **ADO push**.

### How it works

1. **`sdlc story create <tier> --output=…`** drops a template file (`MS-*`, `SS-*`, `TS-*`, `T-*`).
2. Humans (or agents) fill fields; **`sdlc story validate <file>`** checks required sections and traceability hints.
3. **`sdlc story push`** (or `sdlc ado push-story`) sends the body to Azure DevOps and returns the **numeric id** for **AB#** references.
4. **Hooks / PR policy** encourage **AB#** in commit messages so boards, PRs, and code stay linked (see PR chapter).

### Read more

[Commands](Commands.md), repo **`QUICKSTART_4TIER_STORIES.md`**, [PR_Merge_Process](PR_Merge_Process.md).

---

## 8. Azure DevOps: CLI, lightweight scripts, MCP

### What it is

Three **layers** hit the same org/project:

| Layer | When to use it |
|-------|----------------|
| **`sdlc ado`** | Full bash environment; rich subcommands (`sync`, `list`, `comment`, …). |
| **`scripts/ado.ps1` / `ado-mac.sh`** | Minimal environments (quick edits from a laptop without full setup). |
| **MCP in the IDE** | The model calls ADO **as a tool** (create/query/update) during chat; credentials come from the same **`env/.env`** pattern wired at setup. |

### How it works

1. **`env/.env`** holds **`ADO_PAT`**, org, project — loaded by CLI wrappers and MCP launcher scripts.
2. **`sdlc ado sync`** coordinates **two-way** state between local tags/notes and work items (exact behavior in [ADO_MCP_Integration](ADO_MCP_Integration.md)).
3. **MCP** is configured via **`.mcp.json` / `.cursor/mcp.json`** symlinked from the platform during setup; restarting the IDE picks up changes.

### Read more

[ADO_MCP_Integration](ADO_MCP_Integration.md), [Commands](Commands.md).

---

## 9. Agents, skills, and rules

### What it is

- **Rules** — always-on constraints (security, style, org process).
- **Skills** — optional playbooks the model opens when the task matches (story writing, doc conversion, …).
- **Agents** — persona + tool policy bundles for specialized threads (orchestrators, domain agents).

### How it works

1. Content lives in the **platform repo** under **`rules/`**, **`skills/`**, **`agents/`**, mirrored into your project via **symlinks** at setup.
2. The IDE merges **rules** into the system prompt according to Cursor/Claude policies; **skills** are usually retrieved by name when the user or router invokes them.
3. **Token budgets** (see `sdlc cost`, stage budgets in scripts) **signal** when a stage is expensive; blocking behavior depends on team configuration.

### Read more

[Agents_Skills_Rules](Agents_Skills_Rules.md), [Architecture](Architecture.md).

---

## 10. Token budgets and cost signals

### What it is

Stages and flows can be **token-heavy**. The platform surfaces **budgets** and usage hints so teams can split work or request exceptions through the proper channel.

### How it works

1. Budget constants live in platform scripts (e.g. **`scripts/token-blocker.sh`**) keyed by **stage id**.
2. **`sdlc run`** / orchestration consults these values when token blocking is enabled for your org.
3. **`sdlc cost`** prints configured budgets and optional spend snapshots from **`.sdlc/state.json`** when present.

### Read more

[Commands](Commands.md), [Agents_Skills_Rules](Agents_Skills_Rules.md).

---

## 11. Git hooks and auto-sync

### What it is

**Hooks** are small programs Git runs at commit, merge, push, etc. The platform installs **wrappers** that call back into **`ai-sdlc-platform`** scripts for **secrets scanning**, **message format**, **module update**, and **memory export/import**.

### How it works

1. **pre-commit** — runs platform **`hooks/pre-commit.sh`** (or inline fallback) before a commit is recorded.
2. **commit-msg** — enforces **AB#** or **`[no-ref]`** for traceability.
3. **post-merge / post-checkout / post-commit** — call **`sdlc-auto-sync.sh`** so **module KB** and **semantic JSONL** stay aligned with what just landed in `git`.

### Read more

[Commands](Commands.md), [PR_Merge_Process](PR_Merge_Process.md).

---

## 12. Documentation, `manual.html`, and drift

### What it is

**User_Manual** is the **single written source** for humans; **`manual.html`** embeds all pages for **offline** reading and **search** in one file.

### How it works

1. **`node User_Manual/build-manual-html.mjs`** reads the **`ORDER`** list in **`build-manual-html.mjs`**, loads each Markdown file, embeds JSON + client JS into **`manual.html`**.
2. **Pre-commit** can regenerate **`manual.html`** when manual sources change; **CI** runs **`--check`** so the HTML never drifts from Markdown.
3. **`detect-doc-drift.sh`** / doctor integrations warn when **code paths** changed without matching doc updates (see [Documentation_Rules](Documentation_Rules.md)).

### Read more

[Documentation_Rules](Documentation_Rules.md), [INDEX](INDEX.md).

---

## 13. Extension, QA orchestrator, and CI

### What it is

Teams can **add** stages, skills, agents, and rules using **`extension-templates/`** and the checklists in [Platform_Extension_Onboarding](Platform_Extension_Onboarding.md). Optional **QA orchestrator** HTTP APIs are reachable via **`sdlc qa`**. **CI** scripts (`ci-sdlc-platform.sh`, smoke tests, registry checks) validate the platform repo itself.

### How it works

1. Extension follows **file placement + registry regeneration** (`regenerate-registries.sh`) so new skills/agents appear in IDE and matrices.
2. **`sdlc qa`** is a thin HTTP client; the server is optional and separate from core SDLC stages.
3. **CI** runs bash smoke tests, **`manual.html --check`**, and structural validators (rules, commands, stage variants).

### Read more

[Platform_Extension_Onboarding](Platform_Extension_Onboarding.md), [Commands](Commands.md), [Prerequisites](Prerequisites.md).

---

## Quick command map (reminder)

| Intent | Typical entry |
|--------|----------------|
| Health | `sdlc doctor` |
| Role | `sdlc use <role> [--stack=…]` |
| One stage | `sdlc run <stage-id>` |
| One flow | `sdlc flow <name>` |
| Module | `sdlc module init .` · `sdlc module load api` |
| Memory | `sdlc memory semantic-query --text="…"` |
| Story | `sdlc story create sprint --output=./stories/` |
| ADO | `sdlc ado show <id>` · `sdlc ado sync` |

---

## V1 → V2

If you are migrating an older **`ai-claude-platform`** deployment, read [Migrating_From_V1_to_V2](Migrating_From_V1_to_V2.md) and [V2_Improvements_Over_V1](V2_Improvements_Over_V1.md) **after** you understand the features above — they focus on deltas, not first principles.
