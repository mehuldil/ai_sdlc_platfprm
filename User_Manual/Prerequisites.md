# Prerequisites (before `setup`)

Install these **before** running `./setup.sh` or `sdlc setup`. The setup scripts assume a Unix-style shell (Bash) and will validate some of them automatically.

**Get the platform:** clone from Azure DevOps — see **[Getting_Started — Get the platform source](Getting_Started.md#get-the-platform-source)** (canonical URL).

## Required for `./setup.sh` (platform bootstrap)

| Software | Version / notes | Why |
|----------|-----------------|-----|
| **Bash** | 4.x+ typical | `setup.sh` and `cli/sdlc.sh` are Bash scripts. On Windows, use **Git Bash** (from [Git for Windows](https://git-scm.com/download/win)) or WSL. |
| **Git** | Recent stable | Repositories, hooks, distributed memory, ADO linking. |
| **Node.js** | **18 or later** | IDE plugin install, MCP server checks, `node --check` on MCP scripts. |
| **npm** | Bundled with Node | `npm install` for `plugins/ide-plugin`; **required** — setup fails if npm is missing. |
| **npx** | Bundled with Node | Used by MCP / tooling paths; expected on a normal Node install. |

Setup **stops with an error** if Node.js or npm is missing. Fix those first, then re-run `./setup.sh`.

## Strongly recommended (CLI and diagnostics)

| Software | Why |
|----------|-----|
| **curl** | `sdlc ado` operations, ADO connectivity checks in `sdlc doctor`, QA API helpers. |
| **jq** | JSON in CLI helpers, token state, doctor summaries. |

Without `curl` / `jq`, many commands still run, but ADO and some diagnostics are limited.

## Recommended for full platform features

| Software | Why |
|----------|-----|
| **Python 3** | Unified semantic memory (`scripts/semantic-memory.py`, `sdlc memory semantic-*`), distributed memory helpers, QA orchestrator, and **doc ingestion** (`sdlc doc convert`). Use `python3`, `python`, or on Windows `py -3`. |
| **IDE** | **Cursor** or **Claude Code** — slash commands and MCP integration (optional if you only use the terminal). |

**Python doc-ingestion libraries** are installed **automatically** by `./setup.sh` and `bootstrap-sdlc-features.sh` (best-effort, non-fatal). No manual step is required. To skip: set `SDL_SKIP_DOC_LIBS=1` before running setup.

Libraries installed: `pypdf pdfplumber mammoth python-docx openpyxl python-pptx beautifulsoup4 html2text trafilatura`

## Optional (specific subsystems)

| Software | When you need it |
|----------|-------------------|
| **Docker** + **Docker Compose** | Running the **QA orchestrator** from `orchestrator/qa/docker-compose.yml` locally. |
| **Redis** | QA orchestrator KB when not using defaults — see `orchestrator/qa/.env.example`. |

## Windows without admin (no WSL, no Git Bash)

The `sdlc` CLI is Bash-only. On a locked-down Windows machine you can still do **all ADO operations** directly:

```powershell
# No install needed — curl.exe is built into Windows 10+
powershell -File scripts\ado.ps1 description 863476 --file=stories\MS-FamilyHub-Phase1.md
powershell -File scripts\ado.ps1 show       863476
powershell -File scripts\ado.ps1 comment    863476 "Approved"
powershell -File scripts\ado.ps1 update     863476 --state=Active
powershell -File scripts\ado.ps1 push-story stories\SS-FamilyHub-01.md
powershell -File scripts\ado.ps1 push-story stories\MS-scope.md -pushType feature
```

`scripts\ado.ps1` auto-loads `env\.env`, needs **no admin, no pip, no bash**. Full command list: `powershell -File scripts\ado.ps1 help`

## macOS / Linux (without full sdlc setup)

```bash
# bash + curl are already installed on macOS
bash scripts/ado-mac.sh description 863476 --file=stories/MS-FamilyHub-Phase1.md
bash scripts/ado-mac.sh show       863476
bash scripts/ado-mac.sh push-story stories/SS-FamilyHub-01.md --parent=863476
bash scripts/ado-mac.sh push-story stories/MS-scope.md --type=feature
```

`scripts/ado-mac.sh` auto-loads `env/.env`. No sdlc setup required.

## Verify after install

```bash
sdlc doctor
sdlc doctor --verbose    # show validator script output
```

## Confirm all documentation is up to date

Use these together; **`sdlc doctor`** already runs the first two when executed from a project that resolves the platform directory correctly.

| Check | What it proves | Command (from `ai-sdlc-platform` repo root) |
|-------|----------------|---------------------------------------------|
| **Drift vs root docs** | `ROLES.md`, `COMMANDS.md`, `QUICKSTART.md`, `README.md` match roles, CLI handlers, and stages | `bash scripts/detect-doc-drift.sh .` |
| **Generated registries** | `agents/CAPABILITY_MATRIX.md`, skill registry, `.claude/commands/COMMANDS_REGISTRY.md` match source trees | `bash scripts/regenerate-registries.sh --check` |
| **CLI ↔ docs** | Documented `sdlc` commands match `cli/sdlc.sh` | Covered by `scripts/validate-commands.sh` (included in `sdlc doctor`) |
| **CI script + pipelines** | `scripts/ci-sdlc-platform.sh` matches repo; YAML present | `sdlc doctor` (section 14) or `bash scripts/ci-sdlc-platform.sh --quick` from platform root |
| **Offline manual.html** | Matches `User_Manual/*.md` + `VERSION` | `node User_Manual/build-manual-html.mjs --check` (also runs in CI); pre-commit regenerates when you stage `User_Manual` sources |
| **Doc automation bundle** | Hooks, version files, and scripts are present (`setup-documentation.sh`) | `./setup-documentation.sh --verify` (requires a git clone of the platform) |

If `--check` fails, regenerate (then commit):

```bash
bash scripts/regenerate-registries.sh --update
```

Pre-commit hooks (`hooks/doc-change-check.sh`) block commits when system paths change without matching **User_Manual** updates — see [Documentation_Rules](Documentation_Rules.md).

See also: [Getting_Started](Getting_Started.md), [Commands](Commands.md) (`sdlc doctor`), and [SETUP_GUIDE.md](../SETUP_GUIDE.md) at the repo root.
