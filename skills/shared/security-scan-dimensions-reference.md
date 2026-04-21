# Security scan — shared reference (cross-stack)

Referenced by `skills/frontend/security-scan` and `skills/backend/security-scan` so severity scales and atomic split stay consistent.

## Atomic split with `secrets-detector`

Always run **`skills/shared/secrets-detector`** first for credential-pattern detection. Full security scans (this repo: frontend or backend `security-scan`) add stack-specific checks on top without duplicating the secrets workflow in agents.

## Unified severity rubric

| Level | Meaning | Typical action |
|-------|---------|----------------|
| **P0** | Critical / blocking | Exposed secrets, exploitable vulns, auth bypass — fix before merge |
| **P1** | High | Data exposure, unsafe defaults, crash in security-sensitive paths — fix before release |
| **P2** | Medium | Validation gaps, moderate CVEs, weaker hardening — plan remediation |
| **P3** | Low | Hygiene, logging, minor CVEs — track or backlog |

Stack-specific checklists (npm/Java, Spring, mobile keystores, etc.) live in the respective `SKILL.md` files.
