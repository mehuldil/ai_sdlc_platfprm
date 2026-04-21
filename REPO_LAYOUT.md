# Repository layout — single source of truth

**Canonical repo for platform work:** `ai-sdlc-platform` (primary on Azure Repos). A public mirror may exist elsewhere to strip org-specific references; do not edit platform behavior only in the mirror.

## Agents, skills, templates

| Authoritative path | Purpose |
|--------------------|---------|
| `agents/` | **Only** editable agent definitions. Registries (`agent-registry.json`, `CAPABILITY_MATRIX.md`) are generated from here. |
| `skills/` | Skill definitions consumed by CLI and orchestrators. |
| `templates/` | Story and doc templates. |

IDE tooling expects the same content under `.claude/agents`, `.claude/skills`, and `.claude/templates`. Those paths must **not** hold divergent copies.

### Enforcing one tree

From the platform root (Git Bash, macOS, or Linux):

```bash
bash scripts/repair-claude-mirrors.sh
```

That replaces `.claude/{agents,skills,templates}` with **symlinks** to the canonical directories above. After cloning, run this once (or re-run `./setup.sh`) so local `.claude/` mirrors do not drift.

**CI:** On GitHub Actions, `scripts/verify-claude-ssot-ci.sh` fails the build if `.claude/agents` (or skills/templates) contains duplicated real files instead of a symlink or legacy all-symlink layout.

## Commands: base vs `/project:`

Slash commands under `.claude/commands/` follow a single routing model; see `.claude/commands/COMMAND_ROUTING.md`.
