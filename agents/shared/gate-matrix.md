---
name: gate-matrix
description: Reference file defining all 10 org-level SDLC gates with owners, tags, and blocking conditions
model: null
token_budget: null
---

> **SDLC authoring:** See [	emplates/AUTHORING_STANDARDS.md](../../templates/AUTHORING_STANDARDS.md).

# Gate Matrix Reference

> **REFERENCE DOCUMENT** — Not an executable agent. Defines the 10-gate matrix for the SDLC platform.

## ASK-First Enforcement
Gate transitions ALWAYS require human approval:
- Present evidence collected for gate criteria
- Show met/unmet status clearly
- ASK: Approve / Reject / Edit / Override
- NEVER auto-approve any gate
- Log all decisions in ADO comments

## All 10 Org-Level Gates

| Gate | Name | Owner | Tags | Blocking Conditions | Input | Output |
|------|------|-------|------|-------------------|-------|--------|
| G1 | Intake & Triage | PM/TPM | intake, classification | Missing PRD, unclear scope | Task/Issue | Classified work item |
| G2 | Story Grooming | EM | design, analysis, estimation | Ungroomed, no AC, arch issues | User story | Groomed story + estimates |
| G3 | Design Review | Architect | architecture, review, approval | Design gaps, missing ADR, API issues | Design doc | Approved design + contracts |
| G4 | Implementation Planning | Dev Lead | planning, estimation, assignment | Unclear tasks, missing specs | Groomed story | Implementation plan + sprints |
| G5 | Code Review | Code Reviewer | quality, standards, compliance | Quality failures, style violations | PR | Code review approval |
| G6 | Testing & QA | QA Lead | testing, coverage, defects | Insufficient coverage, open defects | Implementation | Test report + coverage metrics |
| G7 | Security Audit | Security Lead | security, vulnerability, compliance | Security issues, policy violations | Code + tests | Security clearance |
| G8 | Performance Review | Perf Engineer | performance, NFR validation | NFR failures, bottlenecks identified | Tested code | Performance baseline + approval |
| G9 | Release Readiness | Release Manager | deployment, config, docs | Missing docs, config issues | All gates passed | Release package |
| G10 | Production Deployment | DevOps Lead | deployment, monitoring, rollback | Failed deployment checks | Release package | Live in production |

## Gate Owners (Default)

- **Intake (G1)**: PM + TPM
- **Grooming (G2)**: Engineering Manager
- **Design (G3)**: Software Architect
- **Implementation (G4)**: Dev Lead
- **Code Review (G5)**: Senior Developer / Code Reviewer
- **Testing (G6)**: QA Lead
- **Security (G7)**: Security Lead
- **Performance (G8)**: Performance Engineer
- **Release (G9)**: Release Manager
- **Deployment (G10)**: DevOps Lead

## Gate Blocking Conditions

### G1 Blocking
- Missing product context
- Unclear acceptance criteria
- No estimated scope

### G2 Blocking
- Ungroomed technical requirements
- Missing architecture decision
- No effort estimate

### G3 Blocking
- Design doesn't match requirements
- Missing API contract
- Missing DB migration plan

### G4 Blocking
- No sprint assignment
- Unclear implementation steps
- Missing test case references

### G5 Blocking
- Code style violations
- Missing unit tests
- Insufficient test coverage (<80%)

### G6 Blocking
- Test execution failures
- Coverage below threshold
- Open P0/P1 defects

### G7 Blocking
- Security vulnerabilities found
- Secrets detected in code
- Policy violations

### G8 Blocking
- NFR thresholds not met
- Performance regressions
- Memory leaks identified

### G9 Blocking
- Missing deployment guide
- Config errors detected
- Incomplete release notes

### G10 Blocking
- Failed production healthchecks
- Rollback criteria triggered
- Monitoring/alerts not configured
