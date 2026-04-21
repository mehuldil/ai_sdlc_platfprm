# Canonical NL engine & interfaces

## Single source of truth (natural language + SDLC)

**Repository root:** `ai_sdlc_platform/` in this workspace — all agents, skills, rules, orchestrators, CLI, hooks, and the IDE plugin under `plugins/ide-plugin/` live here.

- **Do not** maintain a second copy of the same orchestrators or skills in another repo. If you have `ai-sdlc-ide-plugin` (or similar) elsewhere, treat it as **legacy** and **migrate** consumers to:
  - **Submodule**, **npm/git dependency**, or **documented path** to this repo; or
  - **Slash commands + MCP** pointing at this platform checkout.

## How the same flows run everywhere

| Interface | Entry | What runs |
|-----------|--------|-----------|
| **CLI** | `cli/sdlc.sh` → `sdlc <cmd>` | Same scripts as automation |
| **Cursor chat** | `.cursor/rules`, `/project:*` commands | Symlinks to platform; rules in `rules/` |
| **Claude Code** | `.claude/commands`, skills symlinks | Same platform tree |
| **Terminal / NL** | `sdlc setup`, `sdlc run`, `sdlc ado` | `cli/lib/*.sh` |

After clone, **`./setup.sh`** (or **`sdlc setup`**) is **required**: it **auto-installs git hooks** (never aborts the script), bootstraps **module memory + semantic DB init**, and links IDE + NL. In chat, say **“install SDLC”** or **“run setup”** so the assistant runs the same scripts. Validate with **`sdlc doctor`**.

## Ask-first + advisory gates

Gates **G1–G10** stay **advisory**: the NL engine surfaces gaps in chat; humans confirm; updates go to **ADO** via MCP / `sdlc ado` when online. No change to that philosophy.
