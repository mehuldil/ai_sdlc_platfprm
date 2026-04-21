# Architecture

## Component Hierarchy

```
Roles → Agents → Skills → Stages
```

- **Role** — Job function, capabilities, token budget (e.g., `roles/backend-engineer.md`)
- **Agent** — AI persona that embodies a role at specific stages (e.g., `agents/backend/backend-engineer-agent.md`)
- **Skill** — Reusable AI capability invoked by agents (e.g., `skills/product/prd-gap-analyzer.md`)
  - **Atomic Skills** — Single-responsibility building blocks (~50 lines each)
  - **Composed Skills** — Declarative workflows combining atomic skills (YAML)
- **Stage** — Workflow phase with gates, context, routing (e.g., `stages/08-implementation/STAGE.md` or `stages/08-implementation/composition.yaml`)

## File Structure (v2.1.1)

```
ai-sdlc-platform/
├── rules/              # Global org rules (CANONICAL source of truth; see `rules/README.md`)
├── stacks/             # 6 tech stack configs (java, kotlin, swift, react-native, jmeter, figma)
├── roles/              # 8 role definitions
├── agents/             # 52 AI personas (agent-registry.json) — THIN orchestrator pattern
├── skills/             # Atomic + Composed skills
│   ├── registry.json       # Machine-routed subset (CLI); full SKILL.md count in skills/SKILL.md — see skills/README.md
│   ├── atomic/             # Ultra-atomic skills (single-responsibility)
│   │   ├── ado-fetch.md       # Fetch ADO work items
│   │   ├── codebase-search.md # Search repository
│   │   ├── file-extract.md    # Read file excerpts
│   │   ├── wiki-lookup.md     # Search WikiJS
│   │   └── risk-identify.md   # Analyze risks
│   ├── shared/             # Universal atomic skills
│   │   ├── update-documentation/                    # NEW v2.1.1 — doc sync for README/wiki/ADR/User_Manual
│   │   ├── sync-to-ado/                             # NEW v2.1.1 — outbound ADO CRUD (wires: cli + observer)
│   │   └── generate-or-validate-unit-tests/         # NEW v2.1.1 — BLOCKING test gate; bypass requires ADO comment
│   ├── composed/           # Declarative skill compositions (YAML)
│   │   ├── rpi-research.yaml  # Research → Search → Extract → Lookup → Risk
│   │   └── rpi-plan.yaml      # Research → Plan → Test → Rollback
│   ├── shared/             # Universal skills (35 total)
│   ├── backend/            # Backend-specific skills
│   ├── frontend/           # Frontend-specific skills
│   └── rpi-*.md            # Legacy monolithic RPI skills (backward compatible)
├── orchestrator/       # 4 orchestrators (frontend, qa, reporting, perf)
│   └── ado-observer/     # 2-way ADO sync (webhooks + polling)
│       └── observer.py   # Event-driven workflow triggers
├── stages/             # 15 workflow phases (01-15)
│   └── 08-implementation/
│       ├── STAGE.md           # Legacy prose definition
│       └── composition.yaml   # v2.1.0 declarative definition
├── templates/          # Story, PRD, ADR, test plan templates
├── memory/             # Shared + team-specific context
├── workflows/          # 8 workflow definitions (YAML)
├── cli/                # CLI entrypoint + 8 modular libraries
│   ├── sdlc.sh              # Main entry
│   └── lib/
│       ├── executor.sh      # Stage execution
│       ├── skill-router.sh  # NEW: Skill routing, caching, validation
│       ├── skill-discovery.sh # NEW: Interactive skill discovery
│       └── composition-engine.py  # NEW: YAML composition executor
├── hooks/              # 18 git hooks (5 hard-block + 13 advisory)
├── env/                # Environment config (.env, MCP launcher)
├── plugins/            # IDE plugin (MCP server)
├── .cursor/rules/      # Symlinks → rules/
├── .claude/rules/      # IDE-loaded rules
├── extension-templates/ # Templates for adding roles/agents/skills/stages/rules/stacks
├── User_Manual/        # This documentation
└── (previous docs in git history)
```

## Skill Architecture (v2.1.1)

### Three-Tier Skill System

```
┌─────────────────────────────────────────────────────────────┐
│                    SKILL EXECUTION                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐     ┌─────────────────────┐     │
│  │  Composed Skills    │     │  Monolithic Skills  │     │
│  │  (YAML workflows)   │────→│  (Legacy .md)       │     │
│  │  rpi-research.yaml  │     │  rpi-research.md    │     │
│  │  rpi-plan.yaml      │     │  (fallback)    