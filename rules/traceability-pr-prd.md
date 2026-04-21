# Traceability: PR ↔ PRD ↔ ADO

**Purpose:** Explicit references so every PR can be mapped to requirements without guesswork.

## Story templates (downstream of PRD)

Master / Sprint / Task / Tech Story templates include **PRD section IDs** and **ADO IDs** so every PR and commit can map to a PRD slice. Fill the **PRD traceability** table on the Master Story first.

## PRD reference scheme (mandatory in PR title or description)

Use a stable ID from the PRD or feature doc:

| Element | Format | Example |
|---------|--------|---------|
| PRD doc | Repo path or Wiki URL | `docs/prd/ONBOARD-001.md` or Wiki path |
| Section | `PRD-REF-<PRD_ID>-SEC<section>` | `PRD-REF-ONBOARD-001-SEC3.2` |
| ADO parent | `AB#<id>` | `AB#851789` |

**Pull request template (minimum):**

```markdown
## Traceability
- **PRD:** <path or link>
- **PRD-REF:** PRD-REF-<id>-SEC<section>
- **ADO:** AB#<work-item-id> (Feature / Story / Task)
- **Stack / area:** backend | frontend | …
```

## Automatic ADO linking (assistant + tooling)

1. **Parent work item** — Every PR description should include **AB#** so Azure DevOps and Git integrations can link commits/PRs when policies require it.
2. **MCP / `sdlc ado`** — Use **create/link/update** with **parent** set; avoid duplicate WIs for the same scope (check existing query first).
3. **Commits** — `AB#<id>` in message (org standard) for automatic relation where enabled.

## Without org-wide standards yet

Adopt **this file** + **PR template** as the **default** for teams using this platform; extend with your compliance IDs later.

## Machine checks

On **GitHub**, `.github/workflows/sdlc-ci.yml` runs **`pr-traceability`** on pull requests: the PR body must contain a **`PRD-REF-…-SEC…`** token and an **`AB#`** work item reference (numeric id). The default template is `.github/pull_request_template.md`.
