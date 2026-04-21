# Persistent Memory

## In plain words: memory vs knowledge base

People often mix these up. In AI-SDLC they are **two different things**:

| | **Semantic memory** (“persistence”) | **Module / knowledge base** (“KB”) |
|---|-------------------------------------|-------------------------------------|
| **Stores** | Decisions, rationales, QA notes, long-lived facts you **write** or tools **upsert**. | Facts **extracted from your repository**: APIs, contracts, dependencies, layout. |
| **Lives in** | `.sdlc/memory/` — **SQLite** on your machine (ignored by git) + **JSONL** file for the **team** (committed). | `.sdlc/module/` — YAML/JSON and contracts generated from code (committed). |
| **Good question** | “What did we decide about OAuth timeouts?” | “What endpoints does this service expose?” |
| **Main commands** | `sdlc memory semantic-query`, `semantic-upsert`, `semantic-status` | `sdlc module init`, `sdlc module load`, `sdlc module validate` |
| **Synced how** | Git hooks **export** your local writes to JSONL on commit and **import** teammates’ JSONL after pull/merge. | Hooks run **`sdlc module update`** so the KB stays close to the code you committed. |

Use **[Features — how they work](FEATURES_REFERENCE.md)** for mechanics and **[Commands](Commands.md)** for auto-sync details.

---

## Unified Semantic Long-Term Memory

AI-SDLC now includes a shared semantic memory index at:

- `.sdlc/memory/semantic-memory.sqlite3`

It is intended for all orchestrators (QA first, then frontend/perf/reporting) and provides:

1. **Retrieval ranking**
   - Token + character-trigram vectorization
   - Cosine similarity ranking
   - Small freshness weighting for recency-aware results

2. **Conflict resolution**
   - `reject` (default)
   - `last_write_wins`
   - `merge_append`

3. **Lifecycle governance**
   - Entry states: `active`, `superseded`, `archived`
   - Version retention policy per key
   - Archival and hard-delete windows
   - Full audit events in `memory_audit`

## CLI

```bash
sdlc memory semantic-status
sdlc memory semantic-upsert --orchestrator=qa --namespace=requirements --key=US-123 --content-file=notes.md
sdlc memory semantic-query --text="oauth timeout edge case" --orchestrator=qa --limit=5
sdlc memory semantic-lifecycle
```

## Orchestrator Integration

- **QA orchestrator** mirrors KB/context writes into semantic memory through `orchestrator/qa/context_store.py`.
- Other orchestrators should call `orchestrator/shared/semantic_memory.py` directly for write/query/lifecycle.

## Team sync (git) — one source of truth

| Artifact | Role |
|----------|------|
| **SQLite** (`.sdlc/memory/semantic-memory.sqlite3`) | Local machine only; gitignored |
| **JSONL** (`.sdlc/memory/semantic-memory-team.jsonl`) | Team bus — **committed**; hooks export/import around commit/pull |
| **Module KB** (`.sdlc/module/**`) | Code-derived; **committed** after `module update` |

**Details (hooks, env toggles, pipeline files):** see [Commands](Commands.md) — sections *Auto-sync* and *CI* — do not duplicate here.

## Namespacing at scale (many engineers)

To limit merge contention and conflicting keys in **team JSONL** / semantic memory:

- Prefer **`--namespace=`** (and/or feature/sprint prefixes in **keys**) so unrelated work does not share one flat key space.
- Choose **conflict policy** per namespace: e.g. `reject` for canonical facts, `merge_append` for narrative notes (see `semantic-upsert` / lifecycle docs).
- Treat **SQLite** as a **local index**; **git-tracked JSONL + module KB** remain the shared bus for reconciliation.

See also [Traceability_and_Governance](Traceability_and_Governance.md) §6.

## Governance Recommendations

- Run `sdlc memory semantic-lifecycle` in CI nightly (or on a schedule).
- Keep `retain_versions` conservative (default 5) to avoid unbounded growth.
- Rely on **JSONL + module KB in git** for portability; SQLite is regenerated locally after pull.

