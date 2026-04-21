# Git-tracked memory — conflict policy

`memory/shared/` and `memory/team/*` are **versioned in git**. When two branches both change the same memory file:

1. **Prefer merge over overwrite** — resolve conflicts in the PR like normal code; do not “take mine” silently for narrative memory.
2. **Product vs engineering facts** — if both sides updated the same fact (dates, owners), open a short thread and align; update the file once with the agreed truth.
3. **Semantic memory export** (`.sdlc/memory/semantic-memory-team.jsonl`) — follow `skills/shared/state-merge/SKILL.md` and CLI `conflict-strategy` behavior (`last_write_wins` is for automated import only; human review for sensitive domains).
4. **Escalation** — if conflict reflects a requirements dispute, link the resolution to the ADO work item and/or ADR instead of leaving contradictory paragraphs.

This policy complements `rules/merge-and-source-of-truth.md` for traceability between Git and Azure Boards.
