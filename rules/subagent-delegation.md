# Subagent & Multi-Context Delegation

**Goal:** Use parallel or delegated assistant contexts (subagents, Task-style runs, or equivalent) when that reduces risk, improves coverage, or saves main-session tokens—**without** requiring the user to say "explore subagents" or "use subagents".

**Applies to:** All tools (Cursor, Claude Code, and other IDEs that support delegation). Wording is tool-agnostic; map "subagents" to the product’s supported parallel or isolated context features.

---

## Default behavior

1. When several **independent** investigations would otherwise be serialized in one session (e.g. multiple directories, services, or hypotheses), **prefer delegating** so each slice runs in **focused context**.
2. You do **not** need explicit user phrasing such as "explore subagents" or "launch Task"—treat delegation as the **default** for the opportunities below.
3. **Tie-breaker:** If unsure whether to delegate, **prefer subagents (or equivalent) for multi-area exploration.** Prefer staying in the main session only when the work is clearly single-location and low-ambiguity.

---

## When delegation is appropriate ("opportunity")

Use delegation when **any** of these hold:

- **Multi-area reconnaissance** — Finding callers, routes, or config across several packages, services, or repos.
- **Parallelizable questions** — Two or more questions that can be answered **without** strict ordering (e.g. "how does auth work?" vs "where is billing configured?").
- **Broad codebase search** — No single file path given; impact or ownership is unknown.
- **Compare / contrast** — e.g. implementation A vs B, or behavior before vs after a migration.
- **Read-only discovery** — Exploring structure, naming, or dependencies before proposing edits.

---

## When to stay in the main session (avoid abuse)

Avoid spawning delegated work when:

- The task is **one edit in a known file**, **one symbol**, or **one obvious grep**.
- The user gave **exact paths** and a **single** sequential step list.
- Delegation would **duplicate** the same file reads already in context or add coordination overhead without benefit.
- The product or policy **restricts** delegation for the current mode (e.g. readonly subagents only for exploration—respect that).

---

## Handoff quality

Each delegated pass should receive a **self-contained brief**: goal, scope boundaries, tools allowed, and what to return (paths, findings, unknowns). Merge results in the main session for decisions and user-visible actions.

---

## Canonical references

- Thin orchestration and specialist agents: `agents/` and `User_Manual/Agents_Skills_Rules.md`
- Token discipline: `rules/token-optimization.md`
- Ask before irreversible actions: `rules/ask-first-protocol.md`
