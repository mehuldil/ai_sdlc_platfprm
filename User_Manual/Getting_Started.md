# Getting Started

## Prerequisites

- **Required:** Bash, Git, Node.js 18+, npm (see [Prerequisites](Prerequisites.md) for full list and optional tools)
- **IDE:** Cursor or Claude Code (recommended) or terminal-only

**End-to-end path (PRD → merge):** see **[Happy_Path_End_to_End](Happy_Path_End_to_End.md)** — single layman-friendly guide with CLI, slash commands, and NL.

## Setup (1 Command)

```bash
./setup.sh /path/to/your/project
```

This does everything:
1. Validates prerequisites
2. Creates `.sdlc/` directory with memory, state
3. Symlinks `.claude/commands`, `.claude/rules`, and **full** canonical trees: `agents/`, `skills/`, `templates/` → `.claude/` (single symlink per tree — avoids drift and duplicate nested folders)
4. Installs IDE plugin (`npm install`)
5. Creates `env/.env` from template
6. Installs or retries **git hooks** (pre-commit, commit-msg, **post-merge**, **post-checkout**, post-commit backup; setup does not fail if hooks were missing)
7. Runs **bootstrap** for semantic memory DB init + module system (`module-init` once per repo; set `SDL_SKIP_MODULE_INIT=1` to skip the scan)
   - Also installs **Python doc-ingestion libraries** automatically (pypdf, mammoth, openpyxl, etc. for `sdlc doc convert`; set `SDL_SKIP_DOC_LIBS=1` to skip)
8. Validates setup (counts commands, checks connections where possible)
9. Runs **CI `--quick`** (`scripts/ci-sdlc-platform.sh --quick`) — same lint gate as GitHub Actions / Azure Pipelines (no extra command for you); full CI also runs **registry drift** (`regenerate-registries.sh --check`) and **stage 08 variant** checks

**If `.claude/agents` or `.claude/skills` show nested duplicate paths** (e.g. `.claude/skills/skills/`): from the platform repo run `bash scripts/repair-claude-mirrors.sh`, or re-run setup for the project.

**Self-setup (platform development):**
```bash
./setup.sh --self
```

## Post-Setup

**Platform contributors:** When adding agents, rules, skills, roles, stacks, or stages — see **[Platform_Extension_Onboarding](Platform_Extension_Onboarding.md)** for the full checklist and CI commands.

1. Edit `env/.env` — add `ADO_PAT`, `ADO_ORG`, `ADO_PROJECT` if using Azure DevOps
2. Restart IDE — MCP servers auto-connect
3. Run `sdlc doctor` — validates everything (including git hooks)

**Natural language:** you can ask the assistant to “run setup” or “install SDLC” — it should run `./setup.sh` or `sdlc setup` per [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md).

## Many microservice repositories

Each **separate git repository** still needs its **own** `.sdlc/`, git hooks, and IDE symlinks — there is no single global install for all repos on a machine. Module knowledge (`.sdlc/module/`) and team memory exports are **per repo** by design.

**Automate the repetition** (same platform clone; one path per service):

1. **Manifest script (supported)** — From the platform root, create a manifest file (see `scripts/repos.manifest.example`) listing one repository root per line, then run:
   ```bash
   ./scripts/setup-repos-from-manifest.sh /path/to/repos.manifest
   ```
   - Omit the argument to use `./repos.manifest` in the current directory.
   - **`--continue`** — keep going if one repo fails.
   - **`--skip-module-init`** — sets `SDL_SKIP_MODULE_INIT=1` for every run (faster bulk pass; run `sdlc module init .` later in repos that need it).
2. **Shell loop** — From the platform root, for example:
   ```bash
   while IFS= read -r d; do
     [[ "$d" =~ ^[[:space:]]*# ]] && continue
     [[ "$d" =~ ^[[:space:]]*$ ]] && continue
     ./setup.sh "$d"
   done < repos.manifest
   ```
3. **Non-interactive / CI** — After each repo has `env/.env` (or shared credentials on the agent), use **`sdlc setup --from-env`** from that repo root so setup does not prompt; Azure Pipelines / GitHub Actions can loop over a list of checked-out service repos the same way.
4. **Fewer repos** — If many services share one git root (**monorepo**), run **`./setup.sh /path/to/monorepo-root` once**; trade-offs are repo size and ownership boundaries.

After any bulk run, **`cd` into each service repo** and run **`sdlc doctor`** (and complete **`env/.env`** where ADO is used).

## First Run

```bash
sdlc use backend --stack=java   # Select role + stack
sdlc context                         # Verify setup
sdlc run 08-implementation           # Run a stage
```

**In IDE chat:**
```
/project:implementation
```

## Role Selection

```bash
sdlc use product          # Product Manager
sdlc use backend          # Backend Developer
sdlc use frontend         # Frontend Developer
sdlc use qa               # QA Engineer
sdlc use ui               # UI Designer
sdlc use tpm              # Technical Program Manager
sdlc use performance      # Performance Engineer
sdlc use boss             # Engineering Leader
```

Switch roles anytime. Current role: `sdlc context`

## Validation

```bash
sdlc doctor               # Full diagnostic
bash scripts/verify.sh    # Cross-reference validation
bash cli/tests/smoke.sh   # Smoke tests
```

> For detailed setup options, ask: "Explain TTY vs IDE chat setup modes"

> For troubleshooting, see [FAQ](FAQ.md)
