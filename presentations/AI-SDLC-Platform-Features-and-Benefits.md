---
marp: true
theme: default
paginate: true
size: 16:9
title: AI-SDLC Platform — Features & Benefits
description: For end users, CTO, CPO, and business stakeholders
---

<!-- 
  Present with: VS Code "Marp for VS Code" extension → Export PDF / PPTX
  Or paste sections into PowerPoint / Google Slides manually.
-->

# AI-SDLC Platform
## Features & Benefits

**Audience:** End users · Engineering · **CTO · CPO · Business**

*Single deck — two lenses: **delivery** and **business value***

---

# What this session covers

| For **you** (users) | For **leadership** |
|---------------------|-------------------|
| What you get day to day | Why it matters strategically |
| How to work (CLI, IDE, stories) | Risk, speed, traceability, cost of change |
| Where to get help | Governance without blocking delivery |

---

# The problem we solve

- **Fragmented** AI tooling — different prompts per team, no shared playbook  
- **Weak traceability** — hard to tie code, PRs, and requirements together  
- **Slow onboarding** — every new engineer reinvents “how we work”  
- **Leadership blind spots** — release readiness and quality depend on tribal knowledge  

**AI-SDLC** = one **natural-language** SDLC engine: **same rules, agents, and flows** in terminal, Cursor, and Claude Code.

---

# One-line value proposition

> **Ship faster with AI — without losing control.**  
> Standardized **stages**, **roles**, and **quality gates**; **human approval** at every critical step; **full traceability** to Azure DevOps and repo memory.

---

# What the platform *is*

| Dimension | Description |
|-----------|-------------|
| **What** | AI-native **orchestration** for the full SDLC — intake → design → build → test → release → close |
| **Where** | **IDE** (Cursor, Claude Code) + **terminal** — one command surface: `sdlc` |
| **How** | **Roles** → **agents** → **skills** → **stages**; **ask-first** (AI proposes, humans decide) |

---

# Business benefits (executive view)

| Benefit | What it means |
|---------|----------------|
| **Predictability** | Same **15 stages**, **10 gates** (advisory), shared vocabulary across teams |
| **Traceability** | Work items, stories, PRs, and **AB#** linkage — audit-friendly |
| **Velocity** | Reusable **templates**, **slash commands**, **CLI** — less time on ceremony |
| **Quality** | **Hooks**, validators, **doctor** — issues surface early, not at release |
| **Scale** | New stack / team = **extend** platform (roles, stacks, workflows) — not a rewrite |

---

# End-user benefits (day to day)

- **One CLI** — `sdlc use`, `sdlc run`, `sdlc story`, `sdlc ado`, `sdlc doctor`  
- **4-tier stories** — Master → Sprint → Tech → Task — **push to ADO** from Markdown  
- **Clear recovery** — errors suggest **next commands** (`sdlc context`, `sdlc doctor`)  
- **Offline manual** — `User_Manual/manual.html` — searchable single file  

---

# Coverage at a glance

| Area | Platform support |
|------|------------------|
| **Stages** | **15** numbered stages (requirement intake → summary close) |
| **Roles** | **8** (product, backend, frontend, QA, UI, TPM, performance, boss) |
| **Workflows** | **9** named flows (e.g. full-sdlc, quick-fix, prd-to-stories, perf-cycle) |
| **Integrations** | **Azure DevOps** (MCP + REST), git-backed **memory** |

*Numbers reflect current platform inventory; see User Manual for live counts.*

---

# Story pipeline (why product & engineering care)

```
PRD / intake → Master Story → Sprint Story → (optional) Tech Story → Tasks
                                      ↓
                         sdlc story validate → sdlc story push → ADO work item
```

- **Traceability** from doc to **ADO**  
- **One format** for grooming and planning — less rework  

---

# Roles & ownership (without bureaucracy)

- Each **role** has **primary** stages — clear **accountability**  
- **Any role can run any stage** when needed — flexibility for real projects  
- **Chain of command** documented in **Role & Stage Playbook** — who leads, who approves (humans)

*Leadership gets clarity; teams keep autonomy.*

---

# How people actually work

| Surface | Examples |
|---------|----------|
| **Terminal** | `sdlc use product` · `sdlc run 04-grooming` · `sdlc doctor` |
| **Cursor** | `/project:grooming` · rules + commands symlinked to platform |
| **Claude Code** | Same flows via `.claude/` integration |
| **Business / PM** | Stories, ADO sync, release gates — without touching low-level scripts |

---

# Quality & governance (CTO / compliance lens)

- **Gates G1–G10** — **informational**; humans decide (no silent auto-promotion)  
- **Git hooks** — secrets, traceability, branch/commit rules — **fail fast** where policy requires  
- **`sdlc doctor`** — environment, hooks, registries, drift checks — **one diagnostic**  
- **Ask-first protocol** — AI does not override gates or approvals  

---

# Memory & knowledge (why it scales)

- **`.sdlc/memory/`** — git-synced, **cross-team** context  
- **Semantic memory** (where enabled) — ranked retrieval, lifecycle rules  
- **Less duplicate** meetings — decisions live in **repo + ADO**  

---

# From V1 to V2 (if you used ai-claude-platform)

| V1 | V2 (AI-SDLC) |
|----|----------------|
| Team-sliced platform trees | **One canonical** engine (`ai-sdlc-platform`) |
| Script sprawl | **Unified `sdlc` CLI** |
| Mixed onboarding | **User Manual + manual.html** + **migration guide** |

*Migration path documented in User Manual — no forced big-bang.*

---

# Cost & control (CPO / finance angle)

- **Token budgets** per role / stage — **visibility** via `sdlc tokens` / `sdlc cost`  
- **No surprise automation** — skills run when **you** or the **assistant** invokes them  
- **Sunk cost of rework** drops when **templates and validators** align early  

---

# What we ask of end users

1. Run **`./setup.sh`** or **`sdlc setup`** once per app repo  
2. Set **`sdlc use <role>`** before stage work  
3. Use **`sdlc doctor`** when something fails — follow **“Next steps”** on errors  
4. Prefer **4-tier stories** + **`sdlc story push`** for ADO alignment  

---

# What we ask of leadership

1. **Sponsor** one canonical platform repo — **no shadow copies** of agents/skills  
2. **Treat gates as decisions** — PM/TPM/Boss sign-off where your org requires it  
3. **Measure** lead time, defect escape rate, and **release readiness** — platform supplies **artifacts**, not vanity metrics  

---

# Demo checklist (for a live session)

1. `sdlc doctor` — green path  
2. `sdlc use product` → `sdlc run 02-prd-review` (context load)  
3. `sdlc story create sprint --output=./stories/` → show template  
4. (Optional) `sdlc story push` with test project + PAT  
5. Open **`User_Manual/manual.html`** — search  

---

# Artifacts to share

| Artifact | Location |
|----------|----------|
| User Manual (browser) | `User_Manual/manual.html` |
| Commands reference | `User_Manual/Commands.md` |
| Role & stage playbook | `User_Manual/Role_and_Stage_Playbook.md` |
| V1 → V2 migration | `User_Manual/Migrating_From_V1_to_V2.md` |

---

# Summary — features

- **Unified NL + SDLC** — CLI, Cursor, Claude Code  
- **15 stages · 8 roles · 9 workflows** — documented, extensible  
- **4-tier stories + ADO** — traceability  
- **Gates, hooks, doctor** — quality built in  
- **Guided errors** — stepwise recovery, not dead ends  

---

# Summary — benefits

| Stakeholder | Benefit |
|-------------|---------|
| **Engineers** | Less friction; same commands everywhere; clear next steps on errors |
| **Product / PM** | Story pipeline tied to **ADO**; grooming flows |
| **QA / TPM** | Test and release stages; cross-team memory |
| **CTO / CPO** | Governance, auditability, scale — **without** killing agility |

---

# Thank you

**AI-SDLC Platform** — *calm, precise, traceable delivery with AI.*

**Questions?**  
→ Run **`sdlc doctor`** · Read **`User_Manual/manual.html`** · Ask your platform team for a **sandbox** project.

---

## Appendix — suggested speaker notes (non-slides)

- **Technical audience:** Deep-dive: `Architecture.md`, `Agents_Skills_Rules.md`, `cli/` structure.  
- **Executive audience:** Stay on slides 3–8, 12–14, 22–24; avoid command details unless asked.  
- **Workshop:** Use “Demo checklist” slide + one real repo with ADO test project.
