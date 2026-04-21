# Agent & delegation behavior (this repo)

This project follows the AI SDLC platform: **thin agents**, **skills**, and **orchestrators** as documented in `User_Manual/Agents_Skills_Rules.md`.

## Subagents and parallel context

For **how the assistant should delegate** (when to use subagents / parallel contexts without the user naming them), the canonical rule is:

- **`rules/subagent-delegation.md`**

Condensed copy for Claude Code IDE loads: **`.claude/rules/subagent-delegation.md`**.

After `sdlc-setup`, Cursor receives the same file via **`.cursor/rules/rule-subagent-delegation.md`** → symlink to `rules/subagent-delegation.md`.

To apply the same expectations **globally** in Cursor, paste the snippet from **`extension-templates/cursor-user-rule-subagent-delegation-snippet.md`** into **Cursor Settings → Rules → User**.
