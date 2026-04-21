---
name: be-sdlc-pipeline-agent
description: Backend SDLC pipeline orchestrator managing workflow from story to production
model: null
token_budget: null
---

> **SDLC authoring:** See [	emplates/AUTHORING_STANDARDS.md](../../templates/AUTHORING_STANDARDS.md).

# Backend SDLC Pipeline Agent

> **REFERENCE DOCUMENT** — Not an executable agent. Describes the complete backend SDLC pipeline workflow.

## Pipeline Phases

### Phase 1: Intake & Triage (G1)
- Smart-routing classifies task type
- Story created with acceptance criteria
- Backend architect assigned

### Phase 2: Story Grooming (G2)
- EM orchestrates 5-skill grooming
- Architect, Developer, QA, Code Reviewer, DevOps participate
- Effort estimated, dependencies identified

### Phase 3: Design Review (G3)
- Architect creates system design
- ADR generated with trade-offs
- OpenAPI spec + DB schema completed
- Gate approval required

### Phase 4: Implementation Planning (G4)
- Developer analyzes design and AC
- Implementation plan created
- Tasks broken into sprint work items
- Code structure validated

### Phase 5: Implementation (G5 Prep)
- Developer writes code following standards
- Unit tests created (>80% coverage)
- Code follows TEJ/Kafka patterns
- PR submitted for review

### Phase 5: Code Review (G5)
- Code Reviewer executes 7-dimension review
- Blockers addressed before merge
- PR approved and merged
- Gate clearance

### Phase 6: Testing & QA (G6)
- QA executes integration tests
- Coverage metrics validated
- Defects logged and tracked
- Test report generated

### Phase 7: Security Audit (G7)
- Security scan for vulnerabilities
- Secrets detection
- Policy compliance check
- Clearance for next phase

### Phase 8: Performance Review (G8)
- Load testing execution
- NFR validation (throughput, latency, resource usage)
- Bottlenecks identified
- Baseline established

### Phase 9: Release Readiness (G9)
- Deployment guide prepared
- Configuration validated
- Release notes generated
- Deployment package created

### Phase 10: Production Deployment (G10)
- Git push to production
- Argo workflow execution
- Health checks validated
- Monitoring configured



## ASK-First Protocol

**Canonical rule:** [`rules/ask-first-protocol.md`](../../rules/ask-first-protocol.md) — never assume; clarify scope and confirm in chat before irreversible actions or when context is ambiguous.

## ASK-First Enforcement

- Before changes that affect production data, ADO state, contracts, or shared artifacts → **ASK**; show intent and wait for confirmation.
- When branch, story, scope, or environment is unclear → **ASK**; do not infer.
- Chat-first for user confirmation: see [`agents/shared/context-guard.md`](../shared/context-guard.md).

## Integration Points

- **Product**: PRD validation (G1)
- **TPM**: Dependency tracking
- **QA**: Test case alignment (G2, G6)
- **DevOps**: Deployment coordination (G9, G10)
- **Security**: Audit points (G7)

## Success Metrics

- Lead time: < 5 days per gate
- Code review turnaround: < 4 hours
- Test coverage: >= 80%
- Deployment success rate: >= 99%
