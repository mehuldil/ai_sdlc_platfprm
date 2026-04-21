# Consolidation changes — impact & scope

This note accompanies updates to canonical `agents/`, `skills/`, `rules/`, setup, and registries.

## 1–2. `.claude/` mirrors and `sdlc-setup.sh`

**What changed**

- `cli/sdlc-setup.sh` now creates **one symlink each** for `agents/`, `skills/`, and `templates/` under `.claude/` instead of linking only `agents/shared/*.md` and linking each top-level skill folder separately (which could recurse badly on some filesystems).
- Added `scripts/repair-claude-mirrors.sh` to fix local trees that already have nested paths (e.g. `.claude/skills/skills/`).

**Impact**

- **Projects:** After re-running setup, Claude Code sees the **full** agent and skill trees (backend, frontend, qa, etc.) under `.claude/agents` and `.claude/skills`, matching the repo layout.
- **Validators / scripts** that assume many per-file symlinks under `.claude/agents` need the **updated** `validate-cross-tool.sh` behavior (single-directory symlink is valid).
- **Windows / OneDrive:** Symlinks still require Developer Mode or appropriate Git rights; if `ln -sfn` fails, setup logs may warn — use the same mitigations as before.

**What you need to do locally**

- Re-run `./setup.sh` or `sdlc-setup` for the project, **or** run `bash scripts/repair-claude-mirrors.sh` from the platform root when developing the platform itself.
- Remove stale nested `.claude/*` directories if repair script replaced them.

## 3. Stage variants (implemented)

- **Shared baseline:** `stages/_includes/rpi-serialization-baseline.md` holds the common Research → Plan → Implement contract; normative detail remains in `rules/rpi-workflow.md`.
- **Stage 08** stack variants link that baseline and `rules/rpi-workflow.md`; redundant “Locked to …” lines were removed from stack bullets (locks are in the baseline).
- **`figma-design.md`** was replaced with a real design-system / Figma handoff variant (the old file was a placeholder template).
- **CI:** `scripts/validate-stage-variants.sh` enforces YAML `stack:` and RPI links for `stages/08-implementation/variants/*.md` only. Older stages that still ship template text are out of scope until migrated.

## 4. Rules thematic overlap

**What changed**

- Added `rules/README.md` as a **thematic index** — does **not** merge rule files.

**Impact**

- Low risk; no behavior change for tools. Authors use the index to choose the right file.

## 5. Registry vs narrative drift (`CAPABILITY_MATRIX.md`)

**What changed**

- `scripts/regenerate-registries.sh` rebuilds `agents/CAPABILITY_MATRIX.md` from **actual** `*.md` files per folder and points to **`agent-registry.json`** as the authoritative manifest.

**Impact**

- Matrix lists **filenames**, not marketing names; aligns counts with disk.
- **agent-registry.json** is still manual/curated — when adding agents, update **both** the new `.md` and the JSON (existing process).

## 6. Skills — shared security reference

**What changed**

- Added `skills/shared/security-scan-dimensions-reference.md`.
- Frontend and backend `security-scan` SKILL files link to it; frontend dropped a duplicated severity section.

**Impact**

- Orchestration should still invoke `secrets-detector` first; behavior unchanged, **less duplicated text**.
