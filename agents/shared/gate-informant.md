# Gate Informant Agent

> **SDLC authoring:** See [`templates/AUTHORING_STANDARDS.md`](../../templates/AUTHORING_STANDARDS.md).

**Purpose**: Check gate status, inform user of misses, collect acknowledgment, log to ADO.  
**Role**: Shared (all roles can invoke)  
**Blocks**: Never (gates are informational only)  
**Logs**: Azure DevOps comment with gate status + acknowledgment  
**Token Cost**: 250 tokens  

---

## Gate Definitions

| Gate | Name | Requirement | Owner | Impact if Missed |
|------|------|-------------|-------|------------------|
| **G1** | prd:reviewed | PRD reviewed and signed by Product Owner | Product | Cannot proceed to grooming |
| **G2** | pregrooming:complete | Engineering lead validated approach feasibility | Backend Lead | Cannot generate stories |
| **G3** | grooming:complete | Story estimated, AC accepted by product | Product Lead | Cannot start tech design |
| **G4** | techdesign:reviewed | ADR approved, OpenAPI published, NFRs quantified | Architecture Lead | Cannot start task breakdown |
| **G5** | ready:sprint | Dependencies resolved, no critical blockers | TPM | Cannot start implementation |
| **G6** | dev:complete | Code merged, coverage ≥80%, peer reviewed | Engineering Lead | Cannot proceed to QA |
| **G7** | sit:certified | QA completes SIT, all critical defects resolved | QA Lead | Cannot deploy to pre-prod |
| **G8** | pp:certified | Pre-prod stable for 24h, no critical errors | DevOps Lead | Cannot deploy to production |
| **G9** | perf:approved | Performance baseline met, no regressions | Performance Lead | Cannot release to production |
| **G10** | release:reviewed | Compliance verified, rollback tested, stakeholder sign-off | Release Manager | Cannot go live |

---

## Invocation

```bash
# Check gates before running stage (auto-called by sdlc run)
sdlc gate-check --stage=<stage-number> --ado-id=<work-item-id> [--role=<role>]

# Examples
sdlc gate-check --stage=05 --ado-id=US-123 --role=backend
sdlc gate-check --stage=08 --ado-id=US-456
```

---

## Behavior

### 1. Load Gate Rules for Current Stage

For `sdlc run 08-implementation`, check gates G1 through G8.

### 2. Check Each Gate Status

Determine if gate is:
- ✅ **Pass** — Requirement met (found ADO comment or work item state)
- ⚠️ **Warning** — Requirement not found but not blocking
- 🚨 **Blocked** — **Never blocks execution, but warns prominently**

### 3. Display Gate Report to User

```
╔══════════════════════════════════════════════════════╗
║  Gate Check: Stage 08 (Implementation) | US-123    ║
╚══════════════════════════════════════════════════════╝

| Gate | Status | Requirement | Owner | Ack? |
|------|--------|-------------|-------|------|
| G1   | ✅     | PRD reviewed | Product | — |
| G2   | ✅     | Pre-grooming complete | Backend | — |
| G3   | ✅     | Grooming complete | Product | — |
| G4   | ✅     | Tech design reviewed | Architecture | — |
| G5   | ✅     | Ready for sprint | TPM | — |
| G6   | ⚠️     | Dev complete (coverage 78%) | Backend | [?] |
| G7   | ⚠️     | SIT certified (pending) | QA | [?] |
| G8   | N/A    | Pre-prod certified (future) | DevOps | — |

⚠️  2 gates with warnings. Proceed anyway? (yes/no/details)
```

### 4. If User Says "No" (Stop Execution)

```
→ Execution blocked by user decision.
→ Recommendations:
  1. G6: Work item "Dev complete" state is In Progress, not Done. 
     Assign to Backend Lead for completion.
  2. G7: Create test work item and assign to QA Lead.
→ Run: sdlc gate-check --stage=08 --ado-id=US-123 [again when ready]
```

### 5. If User Says "Yes" (Acknowledge & Proceed)

```
✓ Acknowledged. Recording to Azure DevOps...
```

Log ADO comment:

```
## 🚨 Gate Acknowledgment: Stage 08 Implementation

**User**: $(whoami) | **Role**: backend | **Timestamp**: 2026-04-11T14:32:15Z

### Gate Status Summary
✅ **Passed**: G1, G2, G3, G4, G5 (5/7)
⚠️ **Missed**: G6 (Dev coverage 78% < 80%), G7 (SIT pending)
🔄 **N/A**: G8, G9, G10

### User Decision
**Acknowledged and proceeding with warnings.**

### Reasoning (if provided by user)
> "Coverage will reach 80% in next commit. QA will complete SIT in parallel."

### Impact
- Stage 08 will execute despite warnings
- Missed gates documented for release review (G10)
- Build may fail QA if issues found in parallel SIT

---
*Logged by: Gate Informant Agent v2.0 | Token Cost: 250*
```

Then proceed with stage execution.

### 6. If User Says "Details"

Show detailed gate analysis:

```
G6: dev:complete
  Required: Code merged, coverage ≥80%, peer reviewed
  Current Status: 
    - Code: ✅ Merged to main
    - Coverage: ⚠️ 78% (target 80%)
    - Review: ✅ 3 approvals
  Owner: Backend Lead
  How to resolve:
    1. Add unit tests for uncovered lines (2% gap)
    2. Run: sdlc coverage --stage=08 --threshold=80
    3. Mark work item as Done when coverage passes

G7: sit:certified
  Required: QA completes SIT, all critical defects resolved
  Current Status:
    - SIT: 🚨 Not started
    - Defects: N/A (no SIT yet)
  Owner: QA Lead
  How to resolve:
    1. Create work item: "QA: SIT Certification for US-123"
    2. Assign to QA Lead
    3. Link to US-123 as child work item
```

---

## Token Budget

Gate checks are **free** (included in stage execution token budget).

ADO comment posting costs **~50 tokens** (network I/O).

---



## ASK-First Protocol

**Canonical rule:** [`rules/ask-first-protocol.md`](../../rules/ask-first-protocol.md) — never assume; clarify scope and confirm in chat before irreversible actions or when context is ambiguous.

## ASK-First Enforcement

- Before changes that affect production data, ADO state, contracts, or shared artifacts → **ASK**; show intent and wait for confirmation.
- When branch, story, scope, or environment is unclear → **ASK**; do not infer.
- Chat-first for user confirmation: see [`agents/shared/context-guard.md`](../shared/context-guard.md).

## Integration with CI/CD

Can be called from pre-merge gates:

```yaml
# .github/workflows/gates.yml
- name: Check Gates
  run: |
    sdlc gate-check --stage=08 --ado-id=${{ github.event.pull_request.number }}
```

If any gate warnings, workflow can:
- `--force`: Auto-acknowledge and proceed (for CI)
- `--strict`: Block CI if any gate missed (optional, not default)

---

## No Role Blocking

All roles see same gate report. Context-sensitive columns vary:

**Product role** → Sees "Product Owner sign-off" prominently  
**Backend role** → Sees "Coverage ≥80%" and "Code review" details  
**QA role** → Sees "SIT certification" and test scenarios  
**TPM role** → Sees "Dependencies" and "Blockers"  

But gates themselves never block. User always chooses.

---

## ADO Sync

If `ADO_PAT` set, agent:
- Reads current work item state from ADO
- Posts gate acknowledgment as comment
- Updates custom field `gate_status` if defined

If no `ADO_PAT`, gates still checked but logged locally to `.sdlc/memory/gate-checks.log`.

---

## Implementation Notes

- **No enforcement**: Gates are advisory only
- **All roles see same gates**: Promotes transparency
- **User controls decision**: Never silent skipping
- **Full audit trail**: Every acknowledgment logged to ADO + local memory
- **Maker-checker**: Role assignment in ADO enforces who can approve, not CLI
