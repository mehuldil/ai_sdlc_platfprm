# Enforcement contract (AI-SDLC vs Azure / CI)

**Audience:** Teams who need clarity on what **blocks** work vs what **advises**.  
**Related:** [merge-and-source-of-truth](../rules/merge-and-source-of-truth.md), [gate-enforcement](../rules/gate-enforcement.md), [pre-merge-test-enforcement](../rules/pre-merge-test-enforcement.md).

---

## Two layers (do not confuse them)

| Layer | Where it lives | Blocks merge / push? |
|-------|------------------|----------------------|
| **Soft gates (G1–G10)** | AI-SDLC stages, `gate-informant`, chat | **No.** Findings and choices are shown; the user may proceed, skip, or pause. |
| **Hard enforcement** | Azure Repos **branch policies**, **required pipelines**, optional ADO rules | **Yes** (when your org configures them). |

**Rule:** If documentation elsewhere says a gate “cannot proceed,” read that as **recommended sequencing for quality**, not as an automatic lock—unless your **Azure** policies enforce it. AI-SDLC **does not** autonomously block merges.

---

## When a gate is skipped or overridden (audit)

Whenever the user chooses **Proceed** or **Skip** while a gate is incomplete:

1. **Log to ADO** using the standard gate comment format (see `rules/gate-enforcement.md`).
2. Include explicitly:
   - **What** was skipped or not satisfied.
   - **Why** the user chose to continue (short rationale).
   - **Who** is accepting the debt (role/name if policy requires).

**Template (append to ADO comment):**

```text
Gate override / skip rationale: {why proceeding without full evidence}
Risk accepted by: {user or role}
```

This mirrors **test skip** policy: exceptions are allowed, but **reasons must be recorded**.

---

## Unit tests and merge (alignment with `sdlc skip-tests`)

- **`sdlc skip-tests --reason="..."`** requires **`--reason`** with at least **10 characters**: explain why tests are not run or not applicable.
- **Pre-merge hook** may still allow merges with skip markers or when **no test framework** is detected—see `rules/pre-merge-test-enforcement.md`. For “no framework” paths, teams should add a **written rationale** (e.g. `.sdlc/no-test-framework-reason.md` in the app repo) so auditors know why coverage is absent.

Hard blocking for tests is **optional** and is done in **CI / branch policy**, not inside AI-SDLC alone.

---

## Summary

- **AI-SDLC** = advise, log, ask-first on destructive operations where implemented.
- **Azure DevOps + CI** = where **mandatory** bars belong if the business requires them.
