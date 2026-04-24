# Migrating from AI-Claude-Platform (V1) to AI-SDLC-Platform (V2)

This guide is for teams and individuals who already use **`ai-claude-platform`** (V1) and want to adopt **`ai-sdlc-platform`** (V2) for application repositories and day-to-day SDLC work.

## 1. What Changes Conceptually

| Topic | V1 (`ai-claude-platform`) | V2 (`ai-sdlc-platform`) |
|-------|---------------------------|-------------------------|
| Platform layout | Team slices (e.g. `backend/`, `qa/`) inside the platform repo with per-team agents, skills, memory samples | **Single canonical tree** — `agents/`, `skills/`, `stages/`, `rules/`, `workflows/` — one NL engine |
| Project wiring | `setup.sh` links a **team** into the project’s `.claude/` / `.cursor/` | `setup.sh` (or `sdlc setup`) links **roles + stacks**, creates **`.sdlc/`**, bootstraps **semantic memory** |
| Primary CLI | Scripts under `scripts/` (`doctor.sh`, etc.) and team-specific usage | Unified **`sdlc`** CLI (`cli/sdlc.sh`) — same behavior in terminal and automation |
| Memory on disk | Project: `.claude/memory/` (workflow, conventions). Platform repo holds team `memory/` examples | Project: **`.sdlc/memory/`** plus optional **SQLite semantic index** for ranked recall |
| Identity in chat | Emphasis on **team** switch (`backend`, `qa`, …) | Emphasis on **role** + **stack** — `sdlc use <role> [--stack=…]` |

V2 does **not** remove the idea of teams; it **standardizes** how rules, agents, skills, stages, and workflows compose so every interface (Cursor, Claude Code, bash) runs the **same** definitions. See [V2 Improvements Over V1](V2_Improvements_Over_V1.md) for a full feature comparison.

## 2. Prerequisites Before You Migrate

- **Git** access to both repositories (or an internal mirror of V2).
- **Backup** of anything you customized under the **application** repo (not only the platform): `.claude/`, `env/`, local memory files, and any scripts that pointed at V1 paths.
- **Azure DevOps** (if used): keep your PAT and org/project settings; you will re-point `env/.env` after V2 setup.
- **Node.js 18+** and **npm** (for IDE plugin install during setup). See [Prerequisites](Prerequisites.md).

## 3. Team → Role Mapping (V1 → V2)

V1 **teams** map to V2 **roles** as follows:

| V1 team (`setup.sh`) | V2 role (`sdlc use …`) | Notes |
|----------------------|------------------------|--------|
| `backend` | `backend` | Choose stack, e.g. `--stack=java` |
| `frontend` | `frontend` | Stack e.g. React Native |
| `qa` | `qa` | QA orchestrator + skills unified in V2 |
| `product` | `product` | PM / PRD flows |
| `performance` | `performance` | Perf / JMeter-related stacks |
| `reports` | `tpm` or `boss` | Reporting / leadership visibility — pick what matches your workflow |

V2 adds explicit **`ui`** (design) and separates **`tpm`** and **`boss`** for program vs engineering leadership; use [FAQ](FAQ.md) or your org’s convention if unsure.

## 4. Migration Steps (Application Repository)

Do this on each **application** (product) repo that today consumes V1 via `setup.sh`.

### Step A — Freeze and document current state

1. Note the **absolute path** to your V1 `ai-claude-platform` checkout.
2. Record **active V1 team** and any **custom files** inside the project’s `.claude/` that are real files (not symlinks).
3. Export or copy **`env/.env`** (redact PATs in notes if sharing).

### Step B — Clone V2 and keep V1 until cutover

1. Clone **`ai-sdlc-platform`** to a stable path (parallel to where V1 lived is fine).
2. **Do not delete** the V1 clone until V2 `sdlc doctor` is clean and your team signs off.

### Step C — Run V2 setup against your project

From the **ai-sdlc-platform** root:

```bash
./setup.sh /path/to/your/application/repo
```

Or equivalently:

```bash
sdlc setup /path/to/your/application/repo
```

This will:

- Create **`.sdlc/`** (memory, state, semantic DB init where applicable).
- Symlink **`.claude/`** and **`.cursor/`** to the **V2** platform (per [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md)).
- Install or refresh **git hooks** (non-fatal if a hook step warns).
- Install the IDE plugin under `plugins/ide-plugin/` as documented in [Getting Started](Getting_Started.md).

### Step D — Environment and secrets

1. Merge your previous **`env/.env`** fields into the new template generated under the **project**: `ADO_PAT`, `ADO_ORG`, `ADO_PROJECT`, email, etc.
2. Restart **Cursor / Claude Code** so MCP servers reload.

### Step E — Carry forward institutional memory

| V1 content | Suggested V2 destination |
|------------|----------------------------|
| `workflow-state.md`, `service-registry.md`, `conventions.md`, `tech-stack.md` | Merge into **`.sdlc/memory/`** structured markdown, or team files under `memory/` patterns described in [Persistent Memory](Persistent_Memory.md) |
| QA / product notes under old team `memory/` in the **platform** repo | Relevant excerpts only — avoid duplicating entire trees; prefer links and short summaries |
| Custom gate or ADO notes | Align with V2 **stages** and **`sdlc ado`** — see [Commands](Commands.md) |

Run:

```bash
sdlc memory semantic-status
```

after first use to confirm the semantic store initialized.

### Step F — Select role and validate

```bash
sdlc use backend --stack=java   # example
sdlc context
sdlc doctor
```

In the IDE, use slash commands such as **`/project:implementation`** as in [Commands](Commands.md).

### Step G — Stories and ADO

V2 standardizes **4-tier story files** and push to ADO:

```bash
sdlc story create sprint --output=./stories/
# … edit file …
sdlc story push ./stories/SS-*.md
```

Replace ad-hoc V1 story paths with this flow over time; existing ADO work items need no change—only how **new** items are created from Markdown.

## 5. What to Remove or Stop Using from V1

- **Pointing `setup.sh` at `ai-claude-platform`** for new installs — switch scripts and docs to **`ai-sdlc-platform`**.
- **Relying on Glob for `.claude/`** — behaviour documented in legacy V1 `CLAUDE.md` still applies to symlinks: use **`find -L`** when listing symlinked trees.
- **Duplicate IDE plugins** named like `ai-sdlc-ide-plugin` elsewhere — consolidate on the plugin under V2’s `plugins/` per [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md).

## 6. Rollback

If you must return to V1 temporarily:

1. Re-run V1’s `scripts/setup.sh` with the **same project path** and **team** as before (per that repo’s README).
2. Restore **`env/.env`** from backup if V2 overwrote values you still need.

Long term, **standardize on V2** to avoid split-brain platform definitions.

## 7. Getting Help

- **Validation**: `sdlc doctor` and `bash scripts/verify.sh` from `ai-sdlc-platform`.
- **Conceptual**: [System Overview](System_Overview.md), [Architecture](Architecture.md).
- **Why move**: [V2 Improvements Over V1](V2_Improvements_Over_V1.md).

---

**Summary:** Treat V2 as a **drop-in upgrade path**: new setup command, new `.sdlc/` + unified `sdlc` CLI, and a single canonical platform repo—then migrate memory and habits incrementally without losing ADO history.
