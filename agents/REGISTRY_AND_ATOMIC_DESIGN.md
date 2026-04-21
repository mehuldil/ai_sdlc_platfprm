# Agent registry governance & atomic design

**Authoritative file:** [agent-registry.json](agent-registry.json)  
**Companion:** [CAPABILITY_MATRIX.md](CAPABILITY_MATRIX.md) (inventory view).

---

## Registry rules (items 5 & 13)

1. **Single source of truth:** New agents are added **only** through `agent-registry.json` (and the file under `agents/**` that `path` references).
2. **No duplicate IDs:** Agent IDs must be **globally unique** across tier 1 and tier 2 domains. CI (`scripts/verify-platform-registry.sh`) fails on duplicates.
3. **Path must exist:** Every `path` must resolve to a real markdown file under `agents/`.
4. **Regeneration:** After bulk changes, run `bash scripts/regenerate-registries.sh --update` so `CAPABILITY_MATRIX.md` stays aligned.

## Reducing semantic overlap (item 5)

- **Before** adding an agent, search the registry for **overlapping tags** and **descriptions** (e.g. “requirements”, “prd”, “analysis”).
- Prefer **one new atomic skill** under `skills/` plus a **thin agent** that references it, instead of a second agent that reimplements the same steps.

## Skills-first composition (item 6)

- **Agents** orchestrate: stage, role, ordering, and which **skills** to invoke.
- **Skills** hold reusable procedures (parsing, mapping, validation).
- **Rules** hold policy text referenced by both.

If two agents would run the same multi-step logic, **extract a skill** and link both agents to it.

## Governance & behavior

This file is a **governance document**, not a runnable agent. Any change it proposes to registry state (adding/removing agents, renaming IDs, moving paths) must follow [`rules/ask-first-protocol.md`](../rules/ask-first-protocol.md): the AI **must ask first**, present findings, and wait for user approval before executing the change. Registry edits are irreversible once pushed, so always ask before you act.
