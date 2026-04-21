# RPI serialization baseline (stage variants)

Shared by stack **variants** under `stages/*/variants/` so every stack uses the **same phase contract** during implementation (and similar execution-heavy stages).

**Normative source:** [`rules/rpi-workflow.md`](../../rules/rpi-workflow.md) — Research → Plan → Implement → (Verify when required).

## Phase contract (non‑negotiable)

| Phase | Allowed inputs | Forbidden | Typical output |
|-------|------------------|-----------|----------------|
| **Research** | Read repo, ADO, docs; bounded file reads | Writing production code; skipping documented limits | `research.md` (or team equivalent) |
| **Plan** | Research output only | Code in prod paths; scope beyond research | `plan.md` — structure, files, rationale |
| **Implement** | Plan only | New scope not in plan; skipping plan checkpoints | Code + tests per plan |

Locks:

- Plan is **locked** to approved research summary.
- Implementation is **locked** to approved plan.
- Each phase needs explicit human **approval** in chat before the next (ASK-first).

## Variant files

Per-stack bullets (tooling, paths, frameworks) live next to this baseline in `stages/<stage>/variants/<stack>.md`, not duplicated in `rules/`.
