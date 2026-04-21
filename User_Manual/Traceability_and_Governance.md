# Traceability, ADO sync, ask-first, and PRD→story expectations

**Audience:** Architects, TPMs, and release owners.  
**Related:** [ADO_MCP_Integration](ADO_MCP_Integration.md), [Persistent_Memory](Persistent_Memory.md), [PR_Merge_Process](PR_Merge_Process.md).

---

## 1. Traceability contract (PRD → code → ADO)

**Goal:** One unbroken chain of identifiers you can query without guessing.

| Link | Minimum practice |
|------|------------------|
| **PRD ↔ stories** | Stable **requirement or feature IDs** in the PRD (e.g. `REQ-042`, or anchored sections). Stories reference those IDs in title or metadata. |
| **Stories ↔ tasks** | Task files reference **parent story ID** and feature/sprint tags. |
| **Tasks ↔ code** | Commits and PRs include **AB#** or agreed work-item reference (see [PR_Merge_Process](PR_Merge_Process.md)). |
| **PR ↔ ADO** | Branch policies or habits: merge commits or PR description link **work item id**. |

**Optional but powerful:** duplicate the same ID in **ADO tags** so Boards queries stay reliable when descriptions change.

---

## 2. PRD sections → stories (determinism)

**Deterministic** in this platform means:

- **Structured artifacts** (templates, `sdlc` story push, validators) produce **consistent fields** from the same markdown.
- **LLM-assisted** drafting is **not** guaranteed bitwise-identical on repeat unless you pin **model, temperature, and inputs** and add a **schema/check** step.

**Operational definition:** treat PRD→story as **validated** when output passes your template and any automated checks—not when two runs produce identical prose.

---

## 3. ADO sync and drift (realistic posture)

From [ADO_MCP_Integration](ADO_MCP_Integration.md): sync is **best-effort** and **eventually consistent**; offline or API failures must not block Git.

**Reconciliation playbook (periodic):**

1. Query work items **In Progress** / **Done** with **no linked PR** past a threshold.
2. Compare **Git default branch** merges to **ADO** state; fix state and comments.
3. Re-run **`sdlc ado`** sync or MCP tools when online; queue updates when offline.

There is **no** promise of zero drift without **automation + discipline** on both sides.

---

## 4. Ask-first policy (CLI / IDE / MCP)

| Surface | Read-only | Mutates ADO / creates WI | Notes |
|---------|-----------|---------------------------|--------|
| **`sdlc ado` list/show** | Safe | — | No confirmation needed for reads. |
| **`sdlc ado create`**, **`push-story`** | — | **Preview + confirm** in TTY; **non-TTY requires `--yes` or `SDLC_ADO_CONFIRM=yes`** | Prevents accidental WI creation from scripts/agents. |
| **IDE / MCP** | Varies by tool | Follow **ask-first** in agent docs; mirror CLI rules for automation. |

**Principle:** any entrypoint that **creates or updates** shared truth should **show a preview** and require **explicit** confirmation in **non-interactive** contexts.

---

## 5. CI / registry checks

Platform CI runs `scripts/verify-platform-registry.sh`, which validates **`agents/agent-registry.json`**:

- Every `path` points to an existing file under `agents/`.
- **Agent IDs** are unique across `tier_1_universal` and `tier_2_domain`.

Run locally: `bash scripts/verify-platform-registry.sh` (from platform repo root).

---

## 6. Semantic memory namespacing (scale)

When many engineers write to **team JSONL** / semantic memory:

- Prefer **keys** scoped by **feature**, **sprint**, or **namespace** (see `sdlc memory semantic-upsert --namespace=…`).
- Use documented **conflict policies** (`reject`, `last_write_wins`, `merge_append`) for the right **namespace**, not one global default.

Details: [Persistent_Memory](Persistent_Memory.md).
