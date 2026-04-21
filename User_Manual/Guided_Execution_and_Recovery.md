# Guided execution & recovery (all surfaces)

**Goal:** When something is **missing** or a command **cannot run yet**, you get **what to do next**, **exact syntax**, and **step-by-step** options — instead of a bare failure with no path forward.

This page describes **how the platform is designed to behave** and **what you should expect** from the CLI, from **Cursor / Claude Code chat**, and from **natural-language** requests. It complements [Commands](Commands.md) and [FAQ](FAQ.md).

---

## 1. Surfaces (same engine, different UX)

| Surface | How “guided” execution shows up |
|---------|----------------------------------|
| **Interactive terminal (bash)** | `sdlc` may **prompt** for role / stack / stage when guards need context (TTY). You pick from numbered lists. |
| **Non-interactive run** (IDE agent runs a command **without** a real terminal stdin) | Guards **cannot** prompt. CLI prints **`ASK in chat:`** plus **copy-paste** commands (e.g. `sdlc use <role>`). **You or the assistant** run the next step in chat or a real terminal. |
| **Cursor / Claude Code chat** | Assistant should **read stderr**, **paraphrase** what’s missing, and **output the exact** `sdlc` lines (see §4). |
| **Natural language** (“install SDLC”, “run grooming”) | Assistant maps intent → **`setup.sh`** / **`sdlc use`** / **`sdlc run`** per [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md). |

---

## 2. What the CLI and tooling already do

- **Context guard** (`cli/lib/guards.sh`): Before many flows, if **role** (and optionally **stack** / **stage**) is unset:
  - **TTY:** numbered menu → your choice → continues.
  - **No TTY:** **fails with instructions**, not silence — e.g. *Missing role — non-interactive session* → **ASK in chat** → shows `sdlc use <role>` and lists **Roles:** …
- **Recovery footer** (`cli/lib/logging.sh` — `log_recovery_footer` / `log_error_recovery`): After many recoverable errors, the CLI prints **`── Next steps ──`** with **`sdlc context`**, **`sdlc doctor`**, and a pointer to this doc.
- **`sdlc doctor`**: Single place to see what’s wrong (hooks, config, tools, memory, ADO when possible). Use it whenever something “doesn’t work.”
- **Cursor rule** `.cursor/rules/guided-recovery.mdc` (**always on**): Instructs the assistant to **never** stop at “command failed” — always give **numbered** next steps and **copy-paste** `sdlc` syntax when the user pastes errors.
- **Registry check** `scripts/verify-platform-registry.sh`: Verifies **stage** folders match `cli/lib/config.sh`, **`agents/agent-registry.json`** is valid, **rules** count — run after large platform changes (also invoked from `cli/tests/smoke.sh` when present).

---

## 3. Recovery pattern (users)

1. **Read the last lines of output** — often the **fix is printed there** (especially “ASK in chat”).
2. Run **`sdlc context`** — see current role / stack / stage.
3. Run **`sdlc doctor`** — full checklist.
4. If the message names a command, **copy it** and adjust placeholders (`<role>`, `<stage-id>`). Full reference: [Commands](Commands.md).
5. In **chat**, paste the error and ask: **“What should I run next?”** — the assistant should apply §4.

---

## 4. Recovery pattern (assistants — Cursor, Claude Code, any NL agent)

When a user’s command **fails** or **prerequisites are missing**, **do not** stop at “it failed.” **Do:**

1. **State** what is missing (role, stack, `env/.env`, hooks, Python for a script, etc.).
2. **Give the next 1–3 steps** in order, each as a **ready-to-run** line (user fills only IDs or paths they know).
3. **Show syntax** — e.g. `sdlc use product`, `sdlc run 04-grooming`, `./setup.sh /path/to/app` — so the user **does not have to memorize** flags from memory.
4. If the failure is **non-TTY / ASK in chat**, explain: *“The terminal the IDE used can’t prompt; run this in chat or an interactive terminal.”*
5. Point to **`sdlc doctor`** for ambiguous “something is broken” cases.
6. Follow **ask-first** / **guardrails** in `rules/ask-first-protocol.md` — propose, let the user confirm before destructive or ADO-changing actions.

This matches the platform’s **ASK-first** model: AI **surfaces** gaps and **suggests** commands; the user **executes** or **approves**.

---

## 5. Common situations → next commands

| Symptom / message | Typical next step |
|-------------------|-------------------|
| Missing role / “ASK in chat” / `sdlc run` blocked | `sdlc use <role>` then `sdlc use <role> --stack=<stack>` if needed |
| Missing stage context | `sdlc run <stage-id>` (see [SDLC_Flows](SDLC_Flows.md)) |
| Setup incomplete / hooks missing | `./setup.sh` or `sdlc setup` from platform or app repo per [Getting_Started](Getting_Started.md) |
| ADO / MCP issues | Check `env/.env`; `sdlc doctor`; [ADO_MCP_Integration](ADO_MCP_Integration.md) |
| Semantic memory / Python errors | Install Python 3; see [Persistent_Memory](Persistent_Memory.md) |
| “Usage:” / wrong flags | Open [Commands](Commands.md) for the exact subcommand |

---

## 6. What is *not* automatic today

- **No daemon** watches every chat and injects commands without you running or approving something.
- **IDE** does not auto-type into your terminal; **copy-paste** or **ask the assistant to run** a safe command is the norm.
- **Uniform** “friendly + next steps” on **every** `sdlc` subcommand is a **direction**; high-traffic paths (`use`, `run`, `ado` without creds, `flow`, gate/template usage, unknown command, `module` script missing, `sync`/`publish`, test-skip) **append** the recovery footer; other subcommands are improved over time.

---

## 7. Related rules & docs

| Resource | Role |
|----------|------|
| `rules/ask-first-protocol.md` | Ask before assuming |
| [Commands](Commands.md) | Syntax for CLI and slash commands |
| [Getting_Started](Getting_Started.md) | Setup and first `sdlc` use |
| [FAQ](FAQ.md) | Short troubleshooting Q&A |

---

**Summary:** Missing prerequisites should **surface** as **clear messages**, **stepwise** fixes, and **copy-paste-friendly** `sdlc` syntax — from the CLI when possible, and from **assistants** in chat when the terminal can’t prompt. Use **`sdlc doctor`** when in doubt.
