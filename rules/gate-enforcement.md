# Gate Validation Protocol

## Core Rule
**Gates are checkpoints, NOT blockers.** AI validates, checks, and presents findings. User decides whether to proceed, fix, or skip. Gates NEVER block progress autonomously.

## Gate Lifecycle
1. **Gather Evidence** — AI collects data for gate criteria
2. **Validate** — AI checks what's met and what's missing
3. **Present Findings** — AI shows gate status clearly (met/unmet/partial)
4. **ASK for Input** — Present options:
   - (1) Proceed — accept current state
   - (2) Provide missing info — user fills gaps
   - (3) Skip — move forward, note what's incomplete
   - (4) Pause — work on gaps before continuing
5. **Wait for User** — AI does NOT decide on behalf of user
6. **Log** — Record user's decision in ADO comment regardless of choice

**IMPORTANT**: Gates do NOT block. If user says "proceed" with incomplete gate, AI proceeds and logs what was skipped.

## Gate Table (G1–G10)

| Gate | Tag | Checked By | What AI Validates | ASK Prompt |
|------|-----|------------|-------------------|------------|
| G1 | `prd:reviewed` | Product | PRD sections, open questions, clarity | "PRD check: X/Y sections complete. Proceed? (1) Yes (2) I'll fix gaps (3) Skip" |
| G2 | `pregrooming:checked` | Eng Lead | Pre-grooming checklist items | "Pre-grooming: X/Y items ready. Proceed? (1) Yes (2) I'll provide more (3) Skip" |
| G3 | `grooming:checked` | Grooming Lead | AC present, scope clear, estimate exists | "Grooming check: AC={status}, Estimate={status}. Proceed? (1) Yes (2) Fix (3) Skip" |
| G4 | `techdesign:reviewed` | Architect | ADR exists, OpenAPI committed, NFRs noted | "Design check: ADR={status}, API={status}. Proceed? (1) Yes (2) Add info (3) Skip" |
| G5 | `sprint:ready` | Product Owner | Dependencies noted, blockers flagged | "Sprint readiness: {N} blockers found. Proceed? (1) Yes (2) Resolve (3) Skip" |
| G6 | `dev:checked` | Dev Lead | Code merged, coverage %, review status | "Dev check: Coverage={X}%, Tests={status}. Proceed? (1) Yes (2) Fix (3) Skip" |
| G7 | `sit:checked` | QA Lead | SIT execution status, defect count | "SIT check: {X} pass, {Y} fail. Proceed? (1) Yes (2) Fix defects (3) Skip" |
| G8 | `pp:checked` | DevOps Lead | PP deployment status, perf baseline | "PP check: Deploy={status}, Perf={status}. Proceed? (1) Yes (2) Investigate (3) Skip" |
| G9 | `perf:checked` | Perf Team | Perf test results vs targets | "Perf check: p95={X}ms, error={Y}%. Proceed? (1) Yes (2) Optimize (3) Skip" |
| G10 | `release:reviewed` | Release Mgr | Compliance scans, changelog, rollback plan | "Release check: {X}/{Y} items ready. Proceed? (1) Yes (2) Complete items (3) Skip" |

## What AI Does at Each Gate
1. **Validate** — Check criteria, collect evidence automatically
2. **Present** — Show clear status: what's ready, what's missing, what's partial
3. **ASK** — Always give user choice to proceed, fix, or skip
4. **Accept user decision** — If user says proceed with gaps, AI proceeds
5. **Log** — Record in ADO comment what was checked, what was status, what user decided

## What AI Does NOT Do
- ❌ Block progress because a gate criterion is unmet
- ❌ Refuse to advance because evidence is missing
- ❌ Force user to complete all gate items before moving on
- ❌ Auto-tag or auto-change state without user input

## Missing Evidence Handling
When gate evidence is incomplete:
1. Show what's available and what's missing
2. ASK: "Missing: {list}. What would you like to do?"
   - (1) Provide the info now
   - (2) Proceed without it (I'll handle it later)
   - (3) Pause and work on these items
3. All choices are valid — AI respects user decision
4. Log the decision and gaps in ADO comment

## ADO Comment Format for Gate Checks (soft gates — always log)

Every gate outcome MUST post a work item comment (or reply on the linked discussion) so audit survives beyond chat.

```
**[AI-SDLC] Gate {N} Validation | {gate-name}**
- Checked: {criteria list with met | partial | unmet}
- Missing / gaps: {explicit list — empty if none}
- User decision: {proceed | fix | skip | pause}
- If proceed/skip with gaps: {what was accepted as debt}
- Actor: {display name} via AI-SDLC
- Timestamp: {ISO 8601}
```

**Soft gate policy:** The user may proceed or skip; the comment records **what was missing** and **what they chose**. No automatic state change without user confirmation (see also `rules/ask-first-protocol.md`).

**Hard merge block:** Quality and policy enforcement (required builds, reviewers, branch policies) are configured in **Azure Repos / CI**, not by AI gates. See `rules/merge-and-source-of-truth.md`.

---
**Last Updated**: 2026-04-11
**Governed By**: AI-SDLC Platform
