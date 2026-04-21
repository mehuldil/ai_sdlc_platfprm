# Cursor User Rule — paste into Settings → Rules → User

Copy the block below into your **Cursor User rules** (global, all projects). It mirrors `rules/subagent-delegation.md` in **ai-sdlc-platform**; keep project-specific detail there.

---

**Subagent delegation (global)**

Use parallel or delegated assistant contexts (subagents / Task-style runs, or equivalent) when work splits naturally across multiple areas, packages, or independent questions—the user does not need to say "explore subagents."

**If unsure whether to delegate, prefer subagents for multi-area exploration.** Stay in the main session for a single known file, one obvious grep, or a strictly sequential edit the user already scoped.

Delegate for: multi-area reconnaissance, parallelizable questions, broad codebase search without a single path, compare/contrast, read-only discovery before edits.

Avoid over-delegating for: trivial one-shot greps, duplicate reads already in context, or when delegation only adds coordination overhead.

---
