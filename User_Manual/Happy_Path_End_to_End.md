# Happy path: PRD → code → tests → merge (end-to-end)

**Audience:** Anyone who wants one readable path from “we have a PRD” to “code is merged in Git (including Azure DevOps).”
**Not replaced elsewhere:** Deep detail stays in [SDLC_Flows](SDLC_Flows.md), [Commands](Commands.md), [QUICKSTART_4TIER_STORIES.md](../../QUICKSTART_4TIER_STORIES.md) (repo root), [PR_Merge_Process](PR_Merge_Process.md), [ADO_MCP_Integration](ADO_MCP_Integration.md). This page is the **single narrative**.

---

## One-time: before you start

| Step | Plain English | CLI (terminal) | IDE chat (Cursor / Claude Code) | Natural language (NL) examples |
|------|---------------|----------------|----------------------------------|--------------------------------|
| Get the platform | Clone **`ai-sdlc-platform`** from Azure DevOps ([URL](https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git)); clone your **app repo** too if separate. | `git clone https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git` → `cd AI-sdlc-platform` → `./setup.sh` or `./setup.sh /path/to/app` | Open repo in IDE → ask to **run setup** | “Install SDLC” / “Run `./setup.sh` for this project” |
| Check health | Confirms tools, hooks, docs, ADO env (if set). | `sdlc doctor` | Ask: **“Run sdlc doctor”** | “Diagnose SDLC setup” |
| Pick who you are | Role drives rules and suggestions (e.g. backend vs QA). | `sdlc use backend --stack=java` (example) | — | “Set my role to backend, stack java” |
| Azure DevOps (optional) | Needed to push stories / sync work items. | Edit `env/.env`: `ADO_PAT`, `ADO_ORG`, `ADO_PROJECT` | Paste PAT only in secure chat if your policy allows | “Help me configure ADO in env/.env” |

**Cursor / agent setup (no keyboard on the script):** If the assistant runs `./setup.sh` or `sdlc-setup.sh` for you, the shell often has **no TTY**. Use **AskQuestion** in chat for role, stack, and ADO, then re-run with **`SDL_SETUP_*`** and **`ADO_*`** exports (see **`cli/sdlc-setup.sh --help`** and [INDEX](INDEX.md)).

**After setup (automatic on your machine):** git **hooks** (pre-commit, post-merge, etc.) and optional **module + memory sync** — see [Commands — Auto-sync](Commands.md). You do **not** run extra sync scripts for the default path.

---

## Map of the 15 stages (layman labels)

| # | Stage id | Layman meaning |
|---|----------|----------------|
| 01 | `01-requirement-intake` | Bring requirements / PRD into the process |
| 02 | `02-prd-review` | Review PRD for gaps and alignment |
| 03 | `03-pre-grooming` | Prep before grooming |
| 04 | `04-grooming` | Groom backlog / scope for the sprint |
| 05 | `05-system-design` | Technical design for the solution |
| 06 | `06-design-review` | Review and approve design |
| 07 | `07-task-breakdown` | Split work into tasks / stories |
| 08 | `08-implementation` | Write code |
| 09 | `09-code-review` | Peer review |
| 10 | `10-test-design` | Plan tests (incl. unit test strategy) |
| 11 | `11-test-execution` | Run tests (unit, integration, etc.) |
| 12 | `12-commit-push` | Commit with traceability, push branch |
| 13 | `13-documentation` | Update docs |
| 14 | `14-release-signoff` | Release approval |
| 15 | `15-summary-close` | Close the loop |

Run a stage explicitly: **`sdlc run <stage-id>`** (example: `sdlc run 02-prd-review`). Slash command pattern: **`/project:<stage-name>`** (see [Commands](Commands.md)).

---

## Happy path A — From PRD to design (stages 01 → 06)

**Goal:** PRD is understood, scoped, and design is reviewed.

| Stage | What you do (layman) | **Pre** (before / checks) | **Post** (after / outputs) | CLI | Slash command (IDE) | NL examples |
|-------|------------------------|---------------------------|----------------------------|-----|----------------------|-----------|
| 01 | Put the PRD in the repo or wiki; open a **feature branch** (`feature/…` or team convention). | Branch naming policy; ADO feature link if used. | Requirements captured in markdown / ADO. | `git checkout -b feature/my-feature`<br>`sdlc run 01-requirement-intake` | `/project:requirement-intake` | “Run requirement intake for this PRD” |
| 02 | Review PRD for clarity, risks, dependencies. | PRD file or link ready. | Review notes; updates to PRD or follow-up items. | `sdlc run 02-prd-review` | `/project:prd-review` | “Review this PRD from a backend perspective” |
| 03–04 | Groom scope for the sprint; align PO / tech. | Master/sprint story drafts if you use 4-tier. | Groomed backlog; sprint scope. | `sdlc run 03-pre-grooming` / `04-grooming` | `/project:pre-grooming` / `/project:grooming` | “Help me groom this for the next sprint” |
| 05 | **System design** — APIs, services, data, failure modes. | Role set (e.g. backend); context loaded. | Design doc / ADO design artifact. | `sdlc use backend --stack=…`<br>`sdlc run 05-system-design`<br>Optional context: `sdlc module load api` | `/project:system-design` | “System design for this feature; use our microservice boundaries” |
| 06 | Formal **design review** (sign-off or comments). | Design doc ready. | Approved / action items. | `sdlc run 06-design-review` | `/project:design-review` | “Run design review checklist on this design” |

**Stories (4-tier):** Create **Master → Sprint → (optional) Tech → Task** markdown files, validate, then push to ADO when ready — see [QUICKSTART_4TIER_STORIES](../QUICKSTART_4TIER_STORIES.md) (platform repo root). Commands: `sdlc story create …`, `sdlc story validate …`, `sdlc story push …`. The platform does **not** auto-create separate “frontend + backend” stories unless **you** split them (same PRD can drive multiple stories).

---

## Happy path B — Tasks and implementation (stages 07 → 09)

**Goal:** Work is broken down; code is written and reviewed.

| Stage | What you do (layman) | **Pre** | **Post** | CLI | Slash | NL examples |
|-------|------------------------|---------|----------|-----|-------|-------------|
| 07 | **Task breakdown** — map sprint story to tasks, owners, order. | Sprint story + design stable. | Task list / task-tier markdown files; ADO tasks optional. | `sdlc run 07-task-breakdown` | `/project:task-breakdown` | “Break this sprint story into tasks for two devs” |
| 08 | **Implementation** — write service/API/UI code on the feature branch. | Branch checked out; optionally load module context. | Code + unit tests in repo. | `sdlc run 08-implementation`<br>**Context:** `sdlc module load api` or `logic` (saves tokens)<br>**Memory:** `sdlc memory semantic-query --text="…"` if you store decisions | `/project:implementation` | “Implement the REST endpoint per TS-…” |
| 09 | **Code review** — PR or local review. | Code pushed or ready for diff. | Review comments; fixes. | `sdlc run 09-code-review` | `/project:code-review` | “Review this PR for security and style” |

**Microservices:** Code is generated **by your team** (with AI assistance); the platform **does not** ship a single “generate entire microservice” button. **Module KB** (`.sdlc/module`) describes **what the repo contains**; **`sdlc module load`** pulls the right slice for the agent. **Semantic memory** holds **decisions** (export/import via git — see [Persistent_Memory](Persistent_Memory.md)).

---

## Happy path C — Tests (stages 10 → 11)

| Stage | What you do (layman) | **Pre** | **Post** | CLI | Slash | NL |
|-------|------------------------|---------|----------|-----|-------|-----|
| 10 | **Test design** — what to test, data, environments. | Requirements & design known. | Test plan. | `sdlc run 10-test-design` | `/project:test-design` | “Write test scenarios for the payment API” |
| 11 | **Test execution** — run **unit tests** (and other tests) locally/CI. | Build passes; test env ready. | Green tests or defects filed. | `sdlc run 11-test-execution` → then run your stack’s test runner (e.g. Maven/Gradle/npm/Jest) **outside** `sdlc` as per project | `/project:test-execution` | “Run unit tests and summarize failures” |

**Note:** Unit test **commands** are **project-specific** (JUnit, pytest, Jest, …). The SDLC stage **frames** the activity; you still run your build tool.

---

## Happy path D — Commit, push, merge (stages 12 → 15 + Git)

| Stage | What you do (layman) | **Pre** | **Post** | CLI | Slash | NL |
|-------|------------------------|---------|----------|-----|-------|-----|
| 12 | **Commit & push** — message includes **AB#** work item (enforced by hook if installed). | Tests meaningful; secrets not in files. | Branch on **remote** (Azure Repos / GitHub). | `git add -A`<br>`git commit -m "feat: … AB#12345"`<br>`git push -u origin feature/…` | `/project:commit-push` | “Prepare commit message with AB# for this story” |
| 13 | **Documentation** — user docs, README, runbooks. | — | Docs updated. | `sdlc run 13-documentation` | `/project:documentation` | “Update README for the new endpoint” |
| 14–15 | **Release sign-off** & **summary close**. | Release criteria met. | Closed work items; retrospective notes. | `sdlc run 14-release-signoff` / `15-summary-close` | `/project:release-signoff` / `/project:summary-close` | “Close out this feature in ADO” |

### Local merge vs Azure DevOps Git

| Action | What happens (layman) | Commands / notes |
|--------|------------------------|------------------|
| **Merge locally** | You merge **another branch** into yours (or `git pull` from remote). | `git merge origin/develop` or `git pull`<br>**Hooks:** **post-merge** / **post-checkout** refresh **module KB** and **import semantic JSONL** into local SQLite (see [Commands](Commands.md)). |
| **Push to remote** | Your commits go to **Azure Repos** (or any Git remote). | `git push` |
| **PR + merge on server** | **Pull Request** in Azure DevOps → review → **Complete merge**. Branch policies and **CI** (e.g. `azure-pipelines.yml`) run on the server — **not** your local hooks. | Use ADO UI; link AB#; optional board updates via **`sdlc ado`** |

---

## Interfaces cheat sheet (same engine, different entry)

| You use | How to run a stage | How to say it in NL |
|---------|---------------------|---------------------|
| **Terminal** | `sdlc run 05-system-design` | “Run system design stage” |
| **Cursor** | `/project:system-design` or chat with rules loaded | “Take me through system design for AB#12345” |
| **Claude Code** | Same slash commands under `.claude/commands` | Same as Cursor after setup |
| **ADO / Wiki** | Attach PRD; link work items | “Create story from PRD section 3” + `sdlc story push` when file is ready |

Setup for IDE: [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md), [Getting_Started](Getting_Started.md).

---

## Memory & module (when they show up)

| Layer | When it helps | Layman |
|-------|----------------|--------|
| **Module KB** | Implementation, design, review | “What does our codebase say about APIs and dependencies?” — use **`sdlc module load`**. |
| **Semantic / persistence** | Decisions, QA notes, long-lived facts | “What did we decide about OAuth?” — **`sdlc memory semantic-query`**. Team copy lives in **git** as JSONL; local **SQLite** updates after **pull/merge** (hooks). |

Details: [Persistent_Memory](Persistent_Memory.md) + [Commands](Commands.md).

---

## If something fails

See [Guided_Execution_and_Recovery](Guided_Execution_and_Recovery.md) — **ASK in chat**, **`sdlc doctor`**, recovery footers on CLI errors.

---

## Full-path dry run (CLI rehearsal, no ADO required)

**Goal:** Exercise the same **mechanisms** as the happy path—module KB, semantic memory (including team JSONL), document ingestion, stage entry points, four-tier stories + validation—**without** pushing to Azure DevOps unless you choose to.

**Where to run:** Your **application git root** (the repo that holds product code). The platform clone supplies `sdlc`; [Getting_Started](Getting_Started.md) / [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md) describe PATH and setup.

**Shell:** Bash (Git Bash on Windows). **Python 3** on PATH for `sdlc doc convert` and `sdlc memory semantic-*` ([Prerequisites](Prerequisites.md)).

| Phase | What this proves | Commands (see [Commands](Commands.md) for flags) |
|-------|------------------|--------------------------------------------------|
| **Health** | Tooling and docs aligned | `sdlc doctor` |
| **Role** | Stage prompts use correct rules | `sdlc use <role> --stack=<stack>` → `sdlc context` |
| **PRD ingest** | Office/PDF/HTML → markdown for review | `sdlc doc convert <file-or-dir>` → outputs under `.sdlc/import/*.extracted.md`; optional `sdlc doc list` |
| **PRD quality (IDE/skill)** | Gap analysis vs template | Use skill **`skills/shared/prd-gap-analyzer`** against PRD + [`templates/prd-template.md`](../templates/prd-template.md); align with [`templates/AUTHORING_STANDARDS.md`](../templates/AUTHORING_STANDARDS.md) |
| **Module KB** | Repo-grounded contracts before design/impl | `sdlc module init .` → `sdlc module show` → `sdlc module load api` (or `data` / `events` / `logic` / `all`) |
| **Story memory** | Per-branch / story scaffolding | `sdlc memory init` → `sdlc memory status` (and `list-branches` if multi-branch) |
| **Semantic memory + “cross-machine” bus** | Local SQLite + committed JSONL | `sdlc memory semantic-status` → optional `sdlc memory semantic-upsert` (test entry) → `sdlc memory semantic-export` → **simulate teammate:** new clone or `git pull` → `sdlc memory semantic-import` → `sdlc memory semantic-query --text="..."` ([Persistent_Memory](Persistent_Memory.md), [Commands — Auto-sync](Commands.md)) |
| **Stages (optional)** | Same entry points as production | `sdlc run 01-requirement-intake` … `sdlc run 06-design-review` as needed; or `sdlc flow list` / `sdlc flow <workflow>` ([SDLC_Flows](SDLC_Flows.md)) |
| **System design** | Traceable design doc | Author from [`templates/design-doc-template.md`](../templates/design-doc-template.md); ADRs from [`templates/adr-template.md`](../templates/adr-template.md) if applicable; registry: [`templates/TEMPLATE_REGISTRY.md`](../templates/TEMPLATE_REGISTRY.md) |
| **Four-tier stories + links** | Master → Sprint → Tech → Task with traceability | `sdlc story create master --output=./stories/` → fill **PRD / design / parent** IDs in each file → `sdlc story create sprint|tech|task --output=./stories/` → fill **Parent Master / Sprint / Tech** fields → `sdlc story validate <each>.md` ([QUICKSTART_4TIER_STORIES](../../QUICKSTART_4TIER_STORIES.md) at repo root) |
| **ADO (off by default in dry run)** | — | Skip `sdlc story push` / `sdlc ado *` until PAT and ids are ready |

**Minimal copy-paste sequence (empty templates, validates wiring):**

```bash
# From app repo root, with sdlc on PATH
sdlc doctor
sdlc use backend --stack=java   # example
sdlc doc convert ./path/to/PRD.docx
sdlc module init .
sdlc module load api
sdlc memory init
sdlc memory semantic-status
sdlc story create master --output=./stories/
sdlc story create sprint --output=./stories/
sdlc story create tech --output=./stories/
sdlc story create task --output=./stories/
# After filling placeholders: validate each tier file
sdlc story validate ./stories/MS-*.md
sdlc story validate ./stories/SS-*.md
sdlc story validate ./stories/TS-*.md
sdlc story validate ./stories/T-*.md
```

This does **not** replace product work: you still **author** PRD gaps, design sections, and parent/child IDs in markdown. The dry run confirms **CLI + templates + validators + memory/module hooks** on your machine.

---

## Document ownership

This file is the **only** full **happy-path narrative**. Other manuals link here; do not copy long tables into multiple files. Update this file when **default workflows** or **stage names** change.
