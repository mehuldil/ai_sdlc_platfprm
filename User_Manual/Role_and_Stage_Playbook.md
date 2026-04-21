# Role & Stage Playbook — Chains of Command

**Purpose:** Single place to see **who typically leads**, **what order work happens in**, and **how to run a stage** — without automating or locking behavior. This doc **extends** [SDLC_Flows](SDLC_Flows.md) and points to canonical **`roles/*.md`** and **`stages/*/STAGE.md`** in the repository.

---

## 1. How to read this playbook

| Concept | Meaning |
|---------|---------|
| **Primary owner** | Role most often **accountable** for that stage’s outcome (from `roles/*.md`). |
| **Chain of command** | **Ordered steps**: inputs → actions (chat + CLI) → outputs → who **approves** (always a human for gates). |
| **Flexibility** | **Any role may run any stage** when needed; primary ownership is a **default**, not a hard block. See [Agents_Skills_Rules](Agents_Skills_Rules.md). |
| **Automation** | Nothing here **auto-triggers** skills or validators. You run **`sdlc use`**, **`sdlc run &lt;stage-id&gt;`**, then follow **STAGE.md** in chat. |

**CLI reminders:**

```bash
sdlc use <role> [--stack=<stack>]   # Set role (and optional stack)
sdlc run <stage-id> [--story=US-…] # Set stage context; then execute work in IDE per STAGE.md
sdlc context                        # Show current role / stack / stage
```

Stage IDs are the folder names under `stages/` (e.g. `04-grooming`). Full list in [§4](#4-stage-by-stage--chain-of-command).

---

## 2. Chain of command (principles)

1. **Human approves** — Gates G1–G10 are **informational**; AI proposes, you decide ([SDLC_Flows](SDLC_Flows.md)).
2. **Primary role** — Drives the stage; **others contribute** (e.g. TPM facilitates grooming; PM still owns product intent).
3. **Handoff** — Outputs land in **`.sdlc/memory/`**, **ADO**, and **repo** (stories, PRs) — next role **pulls** from there, not from a hidden queue.
4. **Skills** — Invoked **in chat** per agent + **STAGE.md** execution steps; not auto-fired by `sdlc run` alone ([Architecture](Architecture.md)).

---

## 3. Roles — primary stages, chain, handoffs

Canonical role definitions: **`roles/<name>.md`** (`product`, `backend`, `frontend`, `qa`, `ui`, `tpm`, `performance`, `boss`).

### 3.1 Product (`sdlc use product`)

| | |
|--|--|
| **Primary stages** | `01-requirement-intake` → `02-prd-review` → `03-pre-grooming` → `04-grooming` → `07-task-breakdown` (often); **release narrative** `14-release-signoff` / `15-summary-close` with leadership. |
| **Typical chain** | Intake work item or PRD → review PRD → pre-groom priorities → groom stories → **master/sprint stories** (templates + chat) → `sdlc story validate` / `sdlc story push` → hand off to TPM/eng for breakdown. |
| **Approves** | PRD scope, acceptance criteria, release readiness (with Boss). |

### 3.2 TPM (`sdlc use tpm`)

| | |
|--|--|
| **Primary stages** | `03-pre-grooming`, `04-grooming`, `04` (facilitation), `14-release-signoff` (cross-pod coordination). |
| **Typical chain** | Validate blockers / dependencies → facilitate estimation → align ADO links → escalate integration risks → **sign-off** with PM/QA on release readiness. |
| **Approves** | Dependency resolution, release sequencing (with PM/Boss). |

### 3.3 Backend (`sdlc use backend --stack=java-tej` or your stack)

| | |
|--|--|
| **Primary stages** | `05-system-design` → `08-implementation` → `09-code-review` → `12-commit-push` → `13-documentation`. |
| **Typical chain** | Design APIs/contracts → implement → review → commit → ADR/ops docs; **pair with** `10`/`11` when QA tests. |
| **Approves** | Tech design (with peers), merge after review. |

### 3.4 Frontend (`sdlc use frontend --stack=react-native` or stack)

| | |
|--|--|
| **Primary stages** | `05-system-design` → `06-design-review` (with UI) → `08-implementation` → `09-code-review` → `12-commit-push`. |
| **Typical chain** | Design app architecture → align with Figma → implement → review → commit; **UI** leads pixel/design-review depth. |
| **Approves** | PRD-level UX intent (PM); design fidelity (UI). |

### 3.5 UI (`sdlc use ui --stack=figma-design`)

| | |
|--|--|
| **Primary stages** | `05-system-design` (design system), **`06-design-review`** (fidelity, tokens). |
| **Typical chain** | Frames/specs ready → **design-review** → findings to **frontend** for `08`. |
| **Approves** | Design sign-off for release scope (with PM). |

### 3.6 QA (`sdlc use qa`)

| | |
|--|--|
| **Primary stages** | `10-test-design` → `11-test-execution` → **`14-release-signoff`** (quality bar). |
| **Typical chain** | AC → test cases → run automation/manual → defects → **quality gate** evidence for release. **Coordinates** with `09` for testability. |
| **Approves** | Quality sign-off (with TPM/PM for go/no-go). |

### 3.7 Performance (`sdlc use performance --stack=jmeter`)

| | |
|--|--|
| **Primary stages** | `10-test-design` (perf scenarios), `11-test-execution` (load/soak), **`14-release-signoff`** (perf gates). |
| **Typical chain** | SLOs from NFR → JMX / workflows → **perf report** → release gate. **Shares** test stages with QA; scope differs (perf vs functional). |
| **Approves** | Perf gate evidence (with engineering leadership). |

### 3.8 Boss (`sdlc use boss`)

| | |
|--|--|
| **Primary stages** | Not tied to a single **numbered** SDLC stage; uses **reporting orchestrator** (`boss-report` workflow) and **executive views** on ADO. For **pipeline** alignment, **14–15** with `boss` role for executive **go/no-go** narrative. |
| **Typical chain** | Pull metrics → health / readiness → decision → **communicate** to PM/TPM. |
| **Approves** | Strategic go/no-go, resource exceptions. |

---

## 4. Stage-by-stage — chain of command

Each stage has full detail in **`stages/<id>/STAGE.md`**. Below: **intent**, **primary owner**, **typical chain** (what to do in order), **next step**.

| Stage ID | Stage (short) | Gate | Primary owner | Typical chain (summary) |
|----------|---------------|------|----------------|-------------------------|
| `01-requirement-intake` | Intake | — | PM / anyone | Select backlog item or PRD → capture scope → **save** state / memory → **02** |
| `02-prd-review` | PRD review | G1 | PM | Load PRD → review vs `prd-gap-analyzer` / story skill → **approve** PRD → **03** |
| `03-pre-grooming` | Pre-groom | — | TPM / PM | Prioritize → blockers → **prep** grooming → **04** |
| `04-grooming` | Grooming | G2 | TPM / PM | Estimate → clarify AC → **stories** → **05** or **07** |
| `05-system-design` | System design | G3 | BE / FE / UI | Architecture + contracts → **design** outputs → **06** |
| `06-design-review` | Design review | G4 | UI / FE | Figma vs implementation → **issues** → **07** or **08** |
| `07-task-breakdown` | Task breakdown | G5 | PM / EM | **Tasks** from sprint story → **08** |
| `08-implementation` | Implementation | G6 | BE / FE | Code → **RPI** if needed → **09** |
| `09-code-review` | Code review | G6 | BE / FE / QA | Review → **approve** PR → **10** |
| `10-test-design` | Test design | G7 | QA / Perf | Cases / perf scenarios → **11** |
| `11-test-execution` | Test execution | G7 | QA / Perf | Execute → **results** → **12** |
| `12-commit-push` | Commit / push | G8 | BE / FE | Merge policy → **push** → **13** |
| `13-documentation` | Documentation | G9 | BE / FE / PM | Docs / ADR → **14** |
| `14-release-signoff` | Release signoff | G10 | TPM / QA / PM / Boss | **Go/no-go** → **15** |
| `15-summary-close` | Summary close | — | PM / TPM | Retrospective notes → **close** |

### 4.1 `01-requirement-intake`

- **Who leads:** PM or TL (anyone can start).
- **Chain:** Set role → `sdlc run 01-requirement-intake` → pick work item / attach PRD → **record** in workflow state → **memory** output.
- **Out:** Selected feature + scope for **02**.
- **Detail:** `stages/01-requirement-intake/STAGE.md`

### 4.2 `02-prd-review`

- **Who leads:** PM.
- **Chain:** `sdlc run 02-prd-review` → PRD + **gap analysis** → **story-generator** / master story draft in chat → **review** with stakeholders → **G1** evidence.
- **Out:** Approved PRD baseline.
- **Detail:** `stages/02-prd-review/STAGE.md`

### 4.3 `03-pre-grooming`

- **Who leads:** TPM / PM.
- **Chain:** Dependencies, priorities, **prep** for grooming session.
- **Out:** Ready backlog for **04**.
- **Detail:** `stages/03-pre-grooming/STAGE.md`

### 4.4 `04-grooming`

- **Who leads:** TPM facilitates; PM owns product decisions.
- **Chain:** `sdlc run 04-grooming` → estimate → **AC** → **story files** → validate → optional ADO push.
- **Out:** Groomed stories for **05** / **07**.
- **Detail:** `stages/04-grooming/STAGE.md`

### 4.5 `05-system-design`

- **Who leads:** Backend / Frontend (shared); UI for UX/system design.
- **Chain:** Contracts, diagrams, **ADR** seeds → **memory** for implementers.
- **Out:** Design for **06** or **08** (if review skipped).
- **Detail:** `stages/05-system-design/STAGE.md`

### 4.6 `06-design-review`

- **Who leads:** UI / Frontend.
- **Chain:** Compare implementation to Figma → **tokens** / **issues** → fixes.
- **Out:** Design approval for **07** / **08**.
- **Detail:** `stages/06-design-review/STAGE.md`

### 4.7 `07-task-breakdown`

- **Who leads:** PM / EM (task breakdown).
- **Chain:** Sprint story → **tasks** (T-*.md) → owners → **08**.
- **Out:** Executable tasks.
- **Detail:** `stages/07-task-breakdown/STAGE.md`

### 4.8 `08-implementation`

- **Who leads:** Backend / Frontend.
- **Chain:** Implement → **RPI** if required → **unit tests** → **09**; **memory** updates.
- **Out:** Code + PR.
- **Detail:** `stages/08-implementation/STAGE.md`

### 4.9 `09-code-review`

- **Who leads:** Peers; QA may join for testability.
- **Chain:** Review → **comments** → **approve** → merge policy.
- **Out:** Merged or revised PR.
- **Detail:** `stages/09-code-review/STAGE.md`

### 4.10 `10-test-design`

- **Who leads:** QA (functional); Performance (perf scenarios).
- **Chain:** AC → cases / **SLOs** → coverage plan.
- **Out:** Test plan for **11**.
- **Detail:** `stages/10-test-design/STAGE.md`

### 4.11 `11-test-execution`

- **Who leads:** QA / Performance.
- **Chain:** Run suites → **defects** → **retest** → evidence.
- **Out:** Test results for **12** / **14**.
- **Detail:** `stages/11-test-execution/STAGE.md`

### 4.12 `12-commit-push`

- **Who leads:** Developers.
- **Chain:** Final commits → **push** → CI → **hooks** advisory.
- **Out:** Green pipeline artifact.
- **Detail:** `stages/12-commit-push/STAGE.md`

### 4.13 `13-documentation`

- **Who leads:** PM / EM / devs (split by doc type).
- **Chain:** Update runbooks, API docs, **User_Manual** if platform changed.
- **Out:** Doc set for **14**.
- **Detail:** `stages/13-documentation/STAGE.md`

### 4.14 `14-release-signoff`

- **Who leads:** TPM / PM / QA / Boss (org-dependent).
- **Chain:** Gates **G1–G9** evidence → **go/no-go** decision.
- **Out:** Release approval.
- **Detail:** `stages/14-release-signoff/STAGE.md`

### 4.15 `15-summary-close`

- **Who leads:** PM / TPM.
- **Chain:** Retro → **metrics** → archive **memory** → close work items.
- **Out:** Closed loop.
- **Detail:** `stages/15-summary-close/STAGE.md`

---

## 5. Story & ADO chain (cross-cutting)

| Step | Action |
|------|--------|
| 1 | Create/fill **master** story (`sdlc story create master` + chat) |
| 2 | **Sprint** story from master + scope (`sdlc story create sprint` + chat) |
| 3 | Validate | `sdlc story validate <file.md>` |
| 4 | Push to ADO | `sdlc story push <file.md>` |

See [QUICKSTART_4TIER_STORIES](../QUICKSTART_4TIER_STORIES.md) (repo root) and [Commands](Commands.md).

---

## 6. Related documents

| Document | Use |
|----------|-----|
| [SDLC_Flows](SDLC_Flows.md) | Pipeline, gates, workflows |
| [Commands](Commands.md) | Full CLI / slash reference |
| [Architecture](Architecture.md) | Context loading, extension points |
| [Agents_Skills_Rules](Agents_Skills_Rules.md) | Agents, skills, rules hierarchy |
| `roles/*.md` | Per-role **stages you own**, memory, quick start |
| `stages/*/STAGE.md` | Per-stage **execution steps**, skills, pre-flight |

---

**Summary:** Use this playbook for **who** and **in what order**; use **`STAGE.md`** for **exact** steps and skill names; use **`sdlc`** for **state** (role + stage). Nothing here replaces **human** approval at gates.
