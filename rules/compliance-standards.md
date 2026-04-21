# Release Compliance Standards

## Required Security Scans
All releases must pass the following compliance checks before production deployment:

### 1. SAST (Static Application Security Testing)
- **Tool**: Fortify
- **Purpose**: Identify code vulnerabilities
- **Pass criteria**: Zero critical/high severity issues
- **Report**: Security scan results attached to release

### 2. DAST (Dynamic Application Security Testing)
- **Tool**: OWASP ZAP
- **Purpose**: Identify runtime vulnerabilities
- **Pass criteria**: Zero critical/high severity findings
- **Coverage**: All public endpoints and workflows

### 3. SCA (Software Composition Analysis)
- **Tool**: BlackDuck
- **Purpose**: Audit dependencies for known vulnerabilities
- **Pass criteria**: No critical vulnerabilities in dependency tree
- **License check**: Verify compliance with project license requirements

### 4. Container Security
- **Tool**: Kubernetes (K8s) container scanning
- **Purpose**: Scan base images and runtime dependencies
- **Pass criteria**: No critical vulnerabilities in images
- **Registry scanning**: On push to production registry

### 5. Code Quality
- **Tool**: SonarQube
- **Purpose**: Enforce code quality standards
- **Pass criteria**: Quality gate passes (coverage >80%, no blockers)
- **Report**: Integrated with CI/CD pipeline

## Release Gate Policy
- **No release without all scans**: Bypass requires CTO + Security approval
- **Automated gates**: CI/CD must fail build if any check fails
- **Exception process**: Document in ADO work item with justification

## Rollback Runbook (5 Required Sections)

### 1. Rollback Triggers
- Criteria that warrant immediate rollback
- Error thresholds (error rate, latency, availability)
- Escalation path

### 2. Pre-Rollback Validation
- Confirm backup/previous version available
- Notify stakeholders and start war room
- Capture current logs and metrics

### 3. Rollback Steps
- Step-by-step instructions (numbered)
- Commands and expected outputs
- Estimated duration per step

### 4. Post-Rollback Validation
- Health checks and smoke tests
- Metrics to monitor (latency, errors, throughput)
- Customer communication template

### 5. Post-Incident Review
- Root cause analysis template
- Lessons learned documentation
- Follow-up actions and owners

---
**Last Updated**: 2026-04-11  
**Governed By**: AI-SDLC Platform
