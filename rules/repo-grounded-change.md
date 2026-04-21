# Repo-grounded change & regression-aware tests

**Purpose:** System design, implementation, and test design stay anchored to **this repository** (and the application repo under work), not to abstract bullets. Completion includes **unit (or equivalent) tests** for **new behavior** and **awareness of regression** for existing behavior.

**Applies to:** Engineers, architects, QA, and AI agents executing stages **05-system-design**, **08-implementation**, **10-test-design**, and RPI (research / plan / implement).

---

## Principles

1. **Ground in the repo** — Name **files, packages, services, and contracts** that already exist. Prefer **paths** over component nicknames.
2. **Use module knowledge** — When `.sdlc/module/` exists in the application repo, treat `.sdlc/module/contracts/*.yaml` and `.sdlc/module/knowledge/*.md` as first-class inputs. Refresh with `sdlc module init .` / `sdlc module update .` when the codebase changed; use `sdlc module show` or `sdlc module load` for read-only slices.
3. **Design doc §0** — The design template’s **§0 Repository baseline & change surface** is the checklist for baseline paths, contracts, backward compatibility, and links to ADRs / `tech-decisions.md`. **§5 Module impact** and **§6 What we don’t change** MUST stay consistent with §0.
4. **Tests before “done”** — Before marking implementation complete, run **tests for changed code** and **targeted regression** (same package/module or suite agreed in the task), using the project’s stack (JUnit, pytest, Jest, Go test, etc.).
5. **Test design** — Load `.sdlc/module/knowledge/known-issues.md` and `impact-rules.md` when present. Test plans MUST include **regression / non-regression** scope alongside new AC coverage (see `templates/test-plan-template.md` §1.1).

---

## Token efficiency (minimize context bloat)

Repo-grounded work **does not** mean loading or pasting the entire module KB into every session or design doc. **Keep token use low** while staying accurate:

1. **Pointers, not pastes** — In §0, tasks, and plans, cite **paths** and **stable identifiers** (REST paths, operationIds, event names, table names). Do **not** paste full OpenAPI, YAML contracts, or large source dumps into the design artifact unless a reviewer explicitly needs that excerpt.
2. **Slice module output** — Prefer `sdlc module show` for a compact view, or `sdlc module load api` / `data` / `events` / `logic` (or `all` only when necessary) instead of opening every file under `.sdlc/module/` by default.
3. **Keep §0 compact** — Short tables and bullets; one line per surface unless complexity requires more.
4. **Research and RPI** — Grounding means **naming** the right files and tests; follow existing **file/extract limits** in `skills/rpi-research.md`—do not inline whole files into `research.md`.
5. **Tiered context** — Load Tier 1 (story, stage, gates) first; add module slices and deeper files only when needed (`User_Manual/Architecture.md`, Context Loading tiers).

---

## Where this is enforced in the platform

| Artifact | What to follow |
|----------|------------------|
| `templates/design-doc-template.md` | §0 + §5/§6 cross-references |
| `stages/05-system-design/STAGE.md` | Module KB hygiene, repo paths, §0 in output |
| `stages/08-implementation/STAGE.md` | Plan tied to §0/§5; tests before marking dev complete |
| `stages/10-test-design/STAGE.md` | Known issues, impact rules, regression categories |
| `templates/story-templates/task-template.md`, `tech-story-template.md` | Repo anchors + unit/regression DoD |
| `skills/rpi-research.md`, `rpi-implement.md` | Concrete paths + existing tests near the change |

**Note:** This is **documentation and process** guidance. There is **no required CI gate** that fails merges if §0 is blank; teams enforce via **review** and **task DoD**.

---

## Reviewer checklist (lightweight)

- [ ] Design or task lists **concrete repo anchors** where applicable.
- [ ] Contracts or API identifiers are cited when the change touches boundaries.
- [ ] **Backward compatibility** or **explicit break** is stated.
- [ ] **Tests** mentioned or run: new coverage + regression scope for at-risk areas.

---

**Cross-references:** `rules/global-standards.md`, `rules/quality-standards.md`, `rules/rpi-workflow.md`, `.claude/rules/module-system.md` (module commands).
