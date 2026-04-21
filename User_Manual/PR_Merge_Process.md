# PR & Merge Process

## PR Templates

6 templates in `extension-templates/` (previously PR-TEMPLATES/) for different change types:

| Template | When to Use |
|----------|------------|
| `STACK-PR-TEMPLATE.md` | Adding new tech stack |
| `WORKFLOW-PR-TEMPLATE.md` | New workflow creation |
| `STAGE-PR-TEMPLATE.md` | Stage additions |
| `SKILL-PR-TEMPLATE.md` | New skill creation |
| `AGENT-PR-TEMPLATE.md` | New agent definition |
| `RULE-PR-TEMPLATE.md` | Enforcement rule creation |

## Pre-Commit Hooks (HARD BLOCK)

| Hook | What It Enforces |
|------|-----------------|
| `commit-msg.sh` | Conventional commits: `<type>(<scope>): <desc> AB#<id>` |
| `branch-name-check.sh` | Branch pattern: `feature/AB#<id>-*`, `bugfix/*`, `hotfix/*`, `release/*` |
| `pre-commit.sh` | Secrets detection, formatting, stage docs |
| `token-guard.sh` | Token budget enforcement |

## Pre-Merge Hooks (HARD BLOCK)

| Hook | What It Enforces |
|------|-----------------|
| `pre-merge-trace.sh` | AB# traceability — every commit must reference work item |
| `test-bypass-escalation.sh` | Tests must pass OR **valid skip marker** (`.sdlc/skip-tests-{branch}` with `work_item=<id>` from `sdlc skip-tests`) OR TPM/Boss approval — see `rules/pre-merge-test-enforcement.md` (`SDLC_SKIP_TESTS=1` alone does **not** bypass) |
| `pre-merge-duplication-check.sh` | **Blocks** duplicate skill/agent **names** across files (`SDLC_DEDUP_SOFT=1` for advisory-only) |

## Pre-Merge Advisory Hooks

| Hook | What It Checks |
|------|---------------|
| `doc-change-check.sh` | Warns if system files changed but User_Manual/ not updated |
| `enforce-g4.sh` | Architecture gate advisory (ADR, API contracts) |
| `enforce-rpi.sh` | RPI workflow recommendation |
| `gate-advisory.sh` | Generic gate validation + ADO comments |

## Test Bypass Process

Tests cannot be bypassed self-service. Requires escalation:

```bash
# TPM or Boss creates approval file:
sdlc approve-test-skip --approver=<name> --role=tpm --reason="<reason>"
# Creates: .sdlc/test-skip-approval-{branch}.json
# Logged to: .sdlc/logs/test-bypass.log
```

## Commit Convention (Enforced by commit-msg.sh)

```
<type>(<scope>): <description> AB#<id>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`
Allow `[no-ref]` for infrastructure commits only.

## Branch Naming (Enforced by branch-name-check.sh)

```
feature/AB#<id>-<short-desc>
bugfix/AB#<id>-<short-desc>
hotfix/AB#<id>-<short-desc>
release/<version>
```

Protected: `main`, `master`, `develop` — require PR + review.

## Code Review (8 Dimensions)

Stage 09 validates against 8 dimensions:
1. Correctness  2. Security  3. Performance  4. Maintainability
5. Test Coverage  6. Standards  7. Regression Risk  8. **Story AC Verification**

Dimension 8 maps code changes to story acceptance criteria — flags scope creep and incomplete implementation.

## Merge Automation

On merge, git hooks auto-execute:
1. Memory merge + ADR decision consolidation
2. ADO comment with merge summary, linked work items, ADR entries, and engineers involved
3. Auto-close sub-work-items whose AB# appears in the merged commits
4. Trigger downstream CI pipelines (staging-validation, platform-ci)

## CI Enforcement (v2.1.1)

`.github/workflows/sdlc-ci.yml` runs three blocking jobs on every PR targeting `main`, `master`, or `develop`:

| Job | What it enforces | On failure |
|-----|------------------|------------|
| `pr-traceability` | PR body must contain **`PRD-REF-<id>-SEC<n>`** and **`AB#<id>`** tokens | Merge blocked with `::error::` pointing to `rules/traceability-pr-prd.md` |
| `claude-mirror-drift` | `.claude/{agents,skills,templates}` must be byte-identical to canonical `agents/`, `skills/`, `templates/` (runs `scripts/verify-claude-ssot-ci.sh`) | Merge blocked; run `bash scripts/sync-claude-mirrors.sh` to fix |
| `platform-ci` | Runs full platform lint gate via `scripts/ci-sdlc-platform.sh` (registry drift, stage variants, smoke tests, `manual.html --check`) | Merge blocked; fix reported offense |

PR template at [`.github/pull_request_template.md`](../.github/pull_request_template.md) carries the Traceability section. Write PRs using it.

### Bypass policy

There is no bypass for the three CI jobs except via direct-to-main merge (policy violation). Any such bypass **must** be documented as a comment on the ADO work item per [`rules/gate-enforcement-ide.md`](../rules/gate-enforcement-ide.md) with:

- Reason for bypass
- Work item references (PRD-REF + AB#)
- Approver (TPM or Boss)
- Follow-up to restore CI compliance

See [Enforcement_Contract](Enforcement_Contract.md) and [Traceability_and_Governance](Traceability_and_Governance.md) for the full enforcement matrix.
