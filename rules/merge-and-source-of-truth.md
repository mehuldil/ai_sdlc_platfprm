# Merge enforcement & source of truth

## Soft gates (AI-SDLC)

- Gates are **checkpoints**, not autonomous blockers — see `gate-enforcement.md` and **[Enforcement_Contract](../User_Manual/Enforcement_Contract.md)** (when to log skip/override rationale).
- **User decisions** and **gaps** are logged on the **ADO work item** via the standard comment format.

## Hard merge blockers (configure outside this repo)

| Layer | What to configure | Purpose |
|-------|-------------------|---------|
| **Azure Repos** | Branch policies: required reviewers, required builds, comment resolution | Block merge if CI/tests/policy fail |
| **CI / Jenkins** | Required checks: unit tests, lint, security scan | Block merge if quality bar not met |
| **ADO** | Policies on work item state (e.g. not “Done” until review) — optional | Process gate; complements Repos |
| **Local** | Pre-commit hooks (`hooks/`), `sdlc` doctor | Fast feedback before push |

This platform **documents** the model; **branch policies** must be turned on in **your** Azure DevOps project.

## Source of truth when systems disagree

| System | Holds | When it wins |
|--------|--------|----------------|
| **Git** | Code, PRs, commit history | **Authoritative for source** |
| **ADO** | Work items, state, traceability comments | **Authoritative for backlog / status** |
| **Local / `.sdlc`** | Session memory, drafts | **Draft until pushed or synced** |

**Rule:** If Git and ADO diverge (e.g. merged PR but WI not updated), **reconcile** in ADO and/or Git (link PR, update state). Prefer **automation** (service hooks, release pipelines) where possible.

## Drift prevention

- After merge: update **ADO** state + tags; ensure **AB#** in merge commit or PR.
- Periodic: query WIs “In Progress” with no linked PR for older than N days.
