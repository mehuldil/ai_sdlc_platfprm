# Platform extension onboarding — agents, rules, skills, roles, stacks, stages

Use this checklist when you **add or change** platform behavior so CLI, IDE, NL, and CI stay aligned. Repository layout: [`CANONICAL_REPO_AND_INTERFACES`](CANONICAL_REPO_AND_INTERFACES.md).

## Quick reference

| You add… | Primary locations | Must update / run |
|----------|-------------------|-------------------|
| **Agent** | `agents/<domain>/*.md`, [`agents/agent-registry.json`](../agents/agent-registry.json) | Registries; optional: [`agents/CAPABILITY_MATRIX.md`](../agents/CAPABILITY_MATRIX.md) via script |
| **Rule** | [`rules/<name>.md`](../rules/) | Cursor: re-run project `setup` / `sdlc-setup` so `.cursor/rules/rule-*` symlinks exist; Claude Code: update condensed copies under [`.claude/rules/`](../.claude/rules/) if you maintain IDE-specific shortenings |
| **Skill** | `skills/<area>/<skill-name>/SKILL.md` | [`skills/SKILL.md`](../skills/SKILL.md) via regen script; reference from agents/commands as needed |
| **Role (“team”)** | [`cli/lib/config.sh`](../cli/lib/config.sh) (`ROLES`), [`cli/sdlc-setup.sh`](../cli/sdlc-setup.sh) interactive lists | [`roles/`](../roles/) markdown if role docs exist; User Manual tables ([`Role_and_Stage_Playbook`](Role_and_Stage_Playbook.md)) |
| **Tech stack** | `config.sh` (`STACKS`, `STACK_VARIANT_MAP`) | For **each** stage that uses variants: `stages/<stage>/variants/<mapped-name>.md` (see below) |
| **Stage / SDLC flow** | `stages/<NN-name>/STAGE.md`, [`cli/lib/config.sh`](../cli/lib/config.sh) (`STAGES`) | [`workflows/*.yml`](../workflows/) that include the stage; slash commands under [`.claude/commands/`](../.claude/commands/); [`User_Manual/SDLC_Flows`](SDLC_Flows.md) |

After edits, run from the repository root:

```bash
bash scripts/regenerate-registries.sh --update
bash scripts/validate-system-change.sh .
bash scripts/ci-sdlc-platform.sh --quick    # or full CI without --quick
node User_Manual/build-manual-html.mjs      # if User_Manual changed
```

---

## 1. Add an agent

1. **Create** `agents/<shared|backend|frontend|qa|performance|product|boss>/<agent-name>.md` (YAML frontmatter: `name`, `description`, `model`, `token_budget` as used elsewhere).
2. **Register** in [`agents/agent-registry.json`](../agents/agent-registry.json) (tier, path, tags, `accepts_roles`, env).
3. **Governance:** Link [`rules/ask-first-protocol.md`](../rules/ask-first-protocol.md) (or equivalent ASK-first language) so `validate-rules.sh` and reviews stay consistent.
4. **Wire invocation:** From stages, roles, or `cli/` only if the CLI exposes `sdlc agent invoke` for this id — follow existing patterns in [`cli/lib/executor.sh`](../cli/lib/executor.sh) and docs.
5. **Regenerate** [`agents/CAPABILITY_MATRIX.md`](../agents/CAPABILITY_MATRIX.md): `bash scripts/regenerate-registries.sh --update`.

**Thin agent pattern:** Prefer delegating heavy work to **skills** (see [Agents_Skills_Rules](Agents_Skills_Rules.md)).

---

## 2. Add a rule

1. **Create** [`rules/<rule-name>.md`](../rules/) (single responsibility; add a row to [`rules/README.md`](../rules/README.md) index if useful).
2. **Cursor:** Project setup symlinks `rules/*.md` → `.cursor/rules/rule-*.md` — contributors should **re-run** [`setup.sh`](../setup.sh) or `sdlc-setup` for the **app repo** after pulling (not always needed if symlink target updated in place).
3. **Claude Code:** If you keep condensed rule files under [`.claude/rules/`](../.claude/rules/), add or sync the short form there and keep naming aligned with [`validate-rules.sh`](../scripts/validate-rules.sh) / `_rule_file_exists` behavior.
4. **Validate:** `bash scripts/validate-rules.sh .`

---

## 3. Add a skill

1. **Create** directory `skills/<domain>/<skill-id>/SKILL.md` (frontmatter `name`, `description`, `model`, `token_budget`).
2. **Reference** from agents (orchestration) and optionally stages — same patterns as existing skills.
3. **Regenerate** [`skills/SKILL.md`](../skills/SKILL.md): `bash scripts/regenerate-registries.sh --update`.
4. **Dedup:** Run merge-time duplication checks as documented in [Agents_Skills_Rules](Agents_Skills_Rules.md) (`hooks/pre-merge-duplication-check.sh` where applicable).

---

## 4. Add a role (“team”) — e.g. a new lane beside Product / QA / UI

**Note:** `ui` already exists in [`cli/lib/config.sh`](../cli/lib/config.sh) (`ROLES`). For a **new** role id:

1. **Append** the role id to the `ROLES=(...)` array in [`cli/lib/config.sh`](../cli/lib/config.sh) (and keep ordering consistent for UX).
2. **Interactive setup:** Update [`cli/sdlc-setup.sh`](../cli/sdlc-setup.sh) arrays `ROLES` and `ROLE_DESC` so `sdlc setup` prompts list the new role with a one-line description.
3. **Docs:** Update [`Role_and_Stage_Playbook`](Role_and_Stage_Playbook.md), [FAQ](FAQ.md) role lists if you mention supported roles, and token tables in [Agents_Skills_Rules](Agents_Skills_Rules.md) if the role gets a budget.
4. **Optional:** Add [`roles/<role>.md`](../roles/) if your repo uses per-role markdown.

`validate_role` in `config.sh` is the **single gate** for `sdlc use <role>`.

---

## 5. Add a tech stack (e.g. new mobile or backend flavor)

1. **Add** stack id to `STACKS=(...)` in [`cli/lib/config.sh`](../cli/lib/config.sh).
2. **Map** stack → variant filename: `STACK_VARIANT_MAP` must point to the **basename** of variant files (without `.md`).

   Resolver (see [`cli/lib/executor.sh`](../cli/lib/executor.sh)):  
   `stages/<stage>/variants/${STACK_VARIANT_MAP[$STACK]:-$STACK}.md`

3. **For each stage** that should differ by stack, add  
   `stages/<stage-id>/variants/<mapped-name>.md`  
   At minimum, maintain **08-implementation** variants; link [`stages/_includes/rpi-serialization-baseline.md`](../stages/_includes/rpi-serialization-baseline.md) per [stage variant validation](../scripts/validate-stage-variants.sh).
4. **Stacks config / doctor:** If [`scripts/verify-platform-registry.sh`](../scripts/verify-platform-registry.sh) or `sdlc doctor` references stack lists, update those scripts or docs.

---

## 6. Add or rename a stage / SDLC flow

Stages are **numbered directories** under [`stages/`](../stages/): `NN-short-name` with [`STAGE.md`](../stages/01-requirement-intake/STAGE.md) inside.

1. **Add folder** `stages/NN-<name>/STAGE.md` (follow existing YAML + structure).
2. **Register** stage id in `STAGES=(...)` in [`cli/lib/config.sh`](../cli/lib/config.sh) (exact directory name).
3. **Workflows:** Add or edit entries in [`workflows/*.yml`](../workflows/) (stage **names** in YAML are short names; the CLI maps them to `NN-name` directories — see comments in [`workflows/full-sdlc.yml`](../workflows/full-sdlc.yml)).
4. **Slash commands:** Add or update `.claude/commands` markdown if you expose a new `/project:*` (and rerun setup in consuming projects).
5. **User Manual:** [SDLC_Flows](SDLC_Flows.md), [Role_and_Stage_Playbook](Role_and_Stage_Playbook.md), [Happy_Path_End_to_End](Happy_Path_End_to_End.md) as appropriate.
6. **Hooks / memory / ADO:** Search for hardcoded stage lists (`workflow-state.md`, hooks, `ado.sh`) and extend if your automation references stage ids.

Renaming a stage is **high impact**: search the repo for the old folder name and old short name.

---

## 7. CI and manual

- **Registry drift:** `validate-system-change.sh` runs `regenerate-registries.sh --check`.
- **Stage 08 variants:** `validate-stage-variants.sh` enforces RPI links for `stages/08-implementation/variants/*.md`.
- **Offline manual:** After any `User_Manual/*.md` change, run `node User_Manual/build-manual-html.mjs` and commit [`manual.html`](manual.html).

---

## 8. Publishing a public distribution snapshot

When you maintain a **full** checkout and need a **separate** public tree (neutral clone URLs and curated overlays), use the scripts under [`scripts/mirror-public/`](../scripts/mirror-public/). See **[`scripts/mirror-public/README.md`](../scripts/mirror-public/README.md)** for the full publish workflow, dry-run, and environment variables.

**Overlay** files for public-facing wording live under **`scripts/mirror-public/overlays/`** in the **full** repository — edit those when the public tree should differ.

---

## See also

- [Architecture](Architecture.md) — components and extension points  
- [Agents_Skills_Rules](Agents_Skills_Rules.md) — deeper hierarchy  
- [Documentation_Rules](Documentation_Rules.md) — when to refresh which doc  
- [Commands](Commands.md) — CI parity commands  
