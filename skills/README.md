# Skills directory

## Two indexes

There are **two** ways the repo counts “skills.” They are **both correct**; they answer different questions.

| What | Where | Purpose |
|------|--------|---------|
| **Full catalog** | `skills/SKILL.md` (regenerated) | Count of every `**/SKILL.md` under `skills/` (except the hub file). This is the **complete** set of procedural markdown skills. |
| **Machine-routed registry** | `skills/registry.json` | Only skills that **CLI routing** (`cli/lib/skill-router.sh`) must resolve with schemas, composed vs monolithic implementations, token budgets, and cache behavior. **Fewer entries** than the full tree. |

**Rule of thumb:** New work adds a **folder + `SKILL.md`**. Add a **`registry.json`** entry only when automation must **route** or **validate** that skill by id; otherwise agents and docs reference the **path** directly.

**Legacy routing:** Skills not listed in `registry.json` still load via `legacy:<id>` in the router when invoked by path.

## Related

- `scripts/regenerate-registries.sh --update` — refreshes `skills/SKILL.md` from the filesystem.
- `agents/REGISTRY_AND_ATOMIC_DESIGN.md` — skills-first composition for agents.
