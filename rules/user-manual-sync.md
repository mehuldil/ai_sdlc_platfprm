# User Manual sync (mandatory for platform changes)

When **this task** or **the same commit** touches any path under the platform tree:

| Area | Path (from `ai-sdlc-platform/` root) |
|------|----------------------------------------|
| Skills | `skills/` |
| Agents | `agents/` |
| Org rules | `rules/` (canonical markdown — not `User_Manual/`) |
| CLI | `cli/` |

You **must** include matching updates under **`User_Manual/`** in the **same change** (same PR / same agent turn).

## What to update

| Change type | Primary `User_Manual` target |
|-------------|------------------------------|
| Skill added/changed/removed | [Agents_Skills_Rules.md](../User_Manual/Agents_Skills_Rules.md), counts/tables as needed |
| Agent added/changed/removed | [Agents_Skills_Rules.md](../User_Manual/Agents_Skills_Rules.md) |
| Rule added/changed (in `rules/`) | [Agents_Skills_Rules.md](../User_Manual/Agents_Skills_Rules.md) or cross-links from [Architecture.md](../User_Manual/Architecture.md) |
| CLI command, flag, or behavior | [Commands.md](../User_Manual/Commands.md) |
| New/changed script surface for users | [Commands.md](../User_Manual/Commands.md) or [FAQ.md](../User_Manual/FAQ.md) |

Full mapping: [Documentation_Rules.md](../User_Manual/Documentation_Rules.md) — **Auto-Update Triggers**.

## Completion rule

Do **not** treat the task as complete without `User_Manual/` updates unless the user **explicitly** says documentation is out of scope.

## Exceptions

- Whitespace-only, typo-only, or comment-only edits with **no** user-visible behavior.
- Regenerated artifacts **if** behavior is unchanged (still update docs if help text or command list would drift).

## Offline HTML bundle

After you edit **`User_Manual/*.md`**, **`hooks/pre-commit.sh`** runs `node User_Manual/build-manual-html.mjs` and **stages `User_Manual/manual.html`** so the single-file offline reader stays in sync — no separate manual step. CI runs `build-manual-html.mjs --check` if sources and `manual.html` diverge.

## Verification

- `sdlc doctor` (documentation drift checks where configured)
- On commit: `hooks/doc-change-check.sh` blocks if system paths changed without `User_Manual/` updates; **`manual.html`** is refreshed by the same pre-commit hook when `User_Manual` sources change
