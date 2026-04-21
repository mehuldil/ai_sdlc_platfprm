# Code coverage target (G6 / dev complete)

**Default:** line/branch coverage **≥ 80%** for new and changed code in application services unless a **stack-specific rule** or **ADR** sets a different bar.

- **Peer review** and **G6 (dev:complete)** use this threshold together with passing tests — see `agents/shared/gate-informant.md` and `rules/gate-enforcement.md`.
- **Waiving** coverage follows the same path as other test policy: do not silently skip; document on the Azure Boards work item and follow `rules/pre-merge-test-enforcement.md`.

Agents should **reference this file** instead of restating the numeric threshold in prose.
