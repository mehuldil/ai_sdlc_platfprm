---
name: pipeline-flow
description: Reference file defining model tier assignments per SDLC phase
model: null
token_budget: null
---

> **SDLC authoring:** See [	emplates/AUTHORING_STANDARDS.md](../../templates/AUTHORING_STANDARDS.md).

# Pipeline Flow Reference

> **REFERENCE DOCUMENT** — Not an executable agent. Defines the model tier assignments per SDLC phase.

## ASK-First Enforcement  
Every pipeline step MUST follow: ASK → PLAN → DESIGN → Implement → TEST → Merge → Build → Deploy
- Before advancing stages → Show gate status, ASK for approval
- Before creating artifacts → Show plan, ASK to confirm
- Before any ADO update → Show changes, ASK to apply

## Phase-to-Model Mapping

| Phase | Gate | Primary Agent | Model | Input Budget | Output Budget | Rationale |
|-------|------|---------------|-------|--------------|---------------|-----------|
| 1. Intake | G1 | smart-routing | haiku-4-5 | 3000 | 1500 | Classification only |
| 2. Story Grooming | G2 | em-agent | opus-4-6 | 12000 | 5000 | Complex coordination |
| 3. Design Review | G3 | be-architect-agent | opus-4-6 | 10000 | 5000 | ADR generation, spec creation |
| 4. Implementation | G4 | be-developer-agent | sonnet-4-6 | 8000 | 4000 | Code generation, RPI |
| 5. Code Review | G5 | be-code-review-agent | sonnet-4-6 | 6000 | 3000 | Quality validation |
| 6. Testing & QA | G6 | qa-engineer | sonnet-4-6 | 8000 | 4000 | Test case generation |
| 7. Security Audit | G7 | security-reviewer | sonnet-4-6 | 6000 | 3000 | Security scanning |
| 8. Performance Review | G8 | perf-architect | opus-4-6 | 10000 | 5000 | Load testing design |
| 9. Release Readiness | G9 | release-manager | sonnet-4-6 | 6000 | 3000 | Release prep |
| 10. Production Deploy | G10 | perf-executor | haiku-4-5 | 2000 | 1000 | Git push, Argo trigger |

## Model Tier Guidelines

### Haiku 4.5 (Input: 2-3k, Output: 1-1.5k)
- **Use for**: Classification, routing, simple validation
- **Examples**: smart-routing, task routing decisions
- **Speed**: Fastest, lowest latency

### Sonnet 4.6 (Input: 6-8k, Output: 3-4k)
- **Use for**: Implementation, code review, test generation
- **Examples**: Developers, QA engineers, code reviewers
- **Balance**: Good speed/quality trade-off

### Opus 4.6 (Input: 10-12k, Output: 5k)
- **Use for**: Complex design, orchestration, high-stakes decisions
- **Examples**: Architects, Engineering Manager, Performance architects
- **Quality**: Best reasoning, complex trade-off analysis

## Gate Flow Sequence

```
G1 (Intake)
  ↓
G2 (Grooming) — Complex orchestration (Opus)
  ↓
G3 (Design) — Architecture expertise (Opus)
  ↓
G4 (Implementation) — Code generation (Sonnet)
  ↓
G5 (Code Review) — Quality gates (Sonnet)
  ↓
G6 (Testing) — QA execution (Sonnet)
  ↓
G7 (Security) — Security validation (Sonnet)
  ↓
G8 (Performance) — Load testing design (Opus)
  ↓
G9 (Release) — Release prep (Sonnet)
  ↓
G10 (Deploy) — Fast execution (Haiku)
```

## Token Budget Allocation

- **Total Input Budget**: ~75,000 tokens per feature
- **Total Output Budget**: ~35,000 tokens per feature
- **Reserve (10%)**: 11,000 tokens for overages

## Phase Dependencies

- G2 gates G3 (must have groomed story)
- G3 gates G4 (must have approved design)
- G5 gates G6 (code must pass review)
- G6 gates G7 (must pass functional tests)
- G8 gates G9 (must meet performance NFR)
- G9 gates G10 (must have release package)
