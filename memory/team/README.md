# Team-owned memory (modular onboarding)

Each team maintains **only** its subtree here. Keep files **short**; link to ADO or wiki for long history.

| Directory | Typical content |
|-----------|-----------------|
| `backend/` | Service registry notes, conventions, architecture pointers |
| `frontend/` | Lessons learned, workflow state |
| `qa/` | Flaky tests, STLC notes, regression patterns |
| `product/` | Roadmap snippets, research pointers |
| `performance/` | Baselines, lessons |
| `ui/` | Design system, component notes |
| `reports/` | Release history pointers |

**Rules**

1. Prefer **append** or **small edits** — avoid 500-line dumps; summarize with links.
2. **Global** rules live in `rules/` — do not copy them here.
3. Conflicts with org standards → fix in `rules/` via platform PR, not local overrides that contradict ADO policy.

See **`docs/PLATFORM-PRINCIPLES.md` §7** for ownership vs platform scope.
