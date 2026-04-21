# QA Runtime Orchestration Engine

A production-ready LangGraph-based QA orchestration engine that drives end-to-end testing from ADO ticket to filed defects. Powered by Claude AI, Azure DevOps integration, and Redis knowledge base.

## Architecture

### 8-Agent Sequential Pipeline

```
Requirement Analysis → Gate: Requirements ┐
    ↓                                      │
Risk Analysis → Gate: Risk                ├─ Governance Checkpoints (pause for approval)
    ↓                                      │
Test Case Design → Gate: Test Design ─────┘
    ↓
Test Automation → Gate: Automation
    ↓
Test Environment Setup
    ↓
Test Execution (Appium)
    ↓
Report Analysis (failure classification)
    ↓
Defect Management (ADO bug filing)
```

### 4 Governance Gates

- **Requirements Gate**: Ensures requirements extracted and scope confirmed
- **Risk Gate**: Validates risk scoring and test estimate
- **Test Design Gate**: Approves test cases and self-review (supports REFINE)
- **Automation Gate**: Validates automation code is ready and compiles

All gates support:
- **APPROVED**: Proceed to next stage
- **REJECTED**: Stop workflow
- **REFINE**: Request rework and re-enter previous agent
- **PENDING**: Waiting for human decision (with configurable auto-approve timeout)

### Knowledge Base (Redis)

8 stores, each with 24-hour TTL:
- `requirements`: Extracted requirements and scope
- `risk_map`: Risk scores and test estimates
- `test_cases`: Generated test cases with self-review
- `automation`: Java POM + TestNG code
- `environment`: Device/APK/Appium status
- `execution`: Test run results
- `reports`: Failure analysis and classification
- `defects`: Filed ADO bugs with links

All stores auto-archive to disk at run completion.

## Quick Start

### 1. Setup Environment

```bash
cd orchestrator/qa

# Copy and configure
cp .env.example .env

# Required:
# - ANTHROPIC_API_KEY (from https://console.anthropic.com)
# - ADO_PAT (from Azure DevOps User Settings → Personal Access Tokens)
# - ADO_ORG (typically "your-ado-org")
# - ADO_PROJECT (typically "YourAzureProject")
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Start Redis

```bash
# Option A: Docker
docker-compose up -d redis

# Option B: Local Redis
redis-server
```

### 4. Run API

```bash
uvicorn qa.api.main:app --reload
```

Visit: http://localhost:8000/dashboard

## API Reference

### Start Pipeline

```bash
POST /trigger
Content-Type: application/json

{
  "story_id": "US-12345",
  "priority": "high",
  "tags": ["regression", "critical"]
}

Response: {
  "run_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "STARTED",
  "story_id": "US-12345"
}
```

### Get Status

```bash
GET /status/550e8400-e29b-41d4-a716-446655440000

Response: {
  "run_id": "550e8400-e29b-41d4-a716-446655440000",
  "story_id": "US-12345",
  "governance_gates": {
    "requirements": {
      "gate": "requirements",
      "status": "PENDING",
      "created_at": "2026-04-11T10:00:00",
      "decided_at": null
    },
    ...
  },
  "context": { ... }
}
```

### Approve Gate

```bash
POST /approve?run_id=550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{
  "checkpoint": "requirements",
  "decision": "APPROVED",
  "reason": "Requirements verified by PM"
}

Response: {
  "run_id": "550e8400-e29b-41d4-a716-446655440000",
  "checkpoint": "requirements",
  "decision": "APPROVED",
  "message": "Decision recorded"
}
```

Options for `decision`:
- `APPROVED` — proceed
- `REJECTED` — stop (go to END state)
- `REFINE` — request rework (re-enter previous agent)

### Get Knowledge Base

```bash
# All stores
GET /kb/550e8400-e29b-41d4-a716-446655440000

# Summary
GET /kb/550e8400-e29b-41d4-a716-446655440000/summary

# Specific store
GET /kb/550e8400-e29b-41d4-a716-446655440000/test_cases
```

Valid stores: `requirements`, `risk_map`, `test_cases`, `automation`, `environment`, `execution`, `reports`, `defects`

### Health Check

```bash
GET /health

Response: {
  "status": "healthy",
  "redis": {
    "status": "healthy",
    "redis_version": "7.0.0",
    "used_memory_human": "10.5M",
    "connected_clients": 3
  },
  "config_valid": true,
  "errors": []
}
```

## Docker Deployment

```bash
# Build and run with Redis
docker-compose up --build

# Test
curl http://localhost:8000/health
```

## Configuration

See `.env.example` for all options. Key settings:

```bash
# Claude AI
ANTHROPIC_API_KEY=sk-...
CLAUDE_MODEL=claude-sonnet-4-6

# Azure DevOps
ADO_ORG=your-ado-org
ADO_PROJECT=YourAzureProject
ADO_PAT=your-pat-token

# Redis (default: localhost:6379)
REDIS_HOST=redis
REDIS_PORT=6379

# Governance
KB_TTL_HOURS=24                    # Redis TTL
GOVERNANCE_TIMEOUT_HOURS=24        # Auto-approve timeout
AUTO_APPROVE=false                 # Auto-approve after timeout

# Features
ENABLE_WEBHOOK_NOTIFICATIONS=true
ENABLE_METRICS_COLLECTION=true
ENABLE_PARALLEL_EXECUTION=false
ENABLE_REFINE_GATES=true
```

## Agent Implementation Roadmap

### Implemented Core

- [x] LangGraph state machine
- [x] Redis KB store with archival
- [x] 4 governance gates with decisions
- [x] FastAPI REST endpoints
- [x] Azure DevOps client (CRUD operations)
- [x] Claude API wrapper with temperature cap

### TODO: Agent Logic (requires Claude API calls)

- [ ] **Requirement Analysis Agent**
  - Fetch ADO ticket
  - Extract requirements and scope with Claude
  - Write to KB: requirements store

- [ ] **Risk Analysis Agent**
  - Read requirements from KB
  - Score risk and estimate test count with Claude
  - Write to KB: risk_map store

- [ ] **Test Case Design Agent**
  - Read requirements + risk
  - Generate test cases with Claude
  - Self-review with Claude
  - Generate Excel export
  - Sync to ADO (create test items)
  - Write to KB: test_cases store

- [ ] **Test Automation Agent**
  - Read test cases from KB
  - Generate Java POM + TestNG code with Claude
  - Write to KB: automation store

- [ ] **Test Environment Agent**
  - Check device availability (adb devices)
  - Check APK installation
  - Verify Appium connectivity
  - Write to KB: environment store

- [ ] **Test Execution Agent**
  - Run Appium tests
  - Collect Surefire XML results
  - Write to KB: execution store

- [ ] **Report Analysis Agent**
  - Parse Surefire results
  - Classify failures with Claude
  - Score severity + root cause
  - Write to KB: reports store

- [ ] **Defect Management Agent**
  - File ADO bugs for failures
  - Link to parent story
  - Attach screenshots + logs
  - Write to KB: defects store

## Enhancements Over Claude's Version

### Governance

1. **REFINE option on all gates** (not just testDesign)
   - Request rework at any checkpoint
   - Re-enter previous agent for refinement

2. **Flexible approval model**
   - No auto-block (gates are checkpoints, not blockers)
   - User can proceed with missing evidence
   - Auto-approve after timeout (configurable)

### Execution

3. **Parallel execution mode** (experimental)
   - Execute independent agents concurrently
   - `ENABLE_PARALLEL_EXECUTION=true` in config

4. **Metrics collection**
   - Track agent duration
   - Monitor token usage per agent
   - Dashboard for performance insights

5. **Better error resilience**
   - Retry logic per agent (configurable)
   - Graceful degradation on external service failure

### Integration

6. **Webhook notifications** (experimental)
   - Notify teams when gates pause
   - Configurable: `ENABLE_WEBHOOK_NOTIFICATIONS=true`

7. **Release Sign-Off agent** (planned)
   - Claude reviews compliance checklist
   - Files release checklist in ADO
   - Approves production deployment

## Development

### Running Tests

```bash
pytest --cov=qa
```

### Code Quality

```bash
black qa/
flake8 qa/
mypy qa/
```

### Running Locally

```bash
# Terminal 1: Redis
redis-server

# Terminal 2: API
uvicorn qa.api.main:app --reload

# Terminal 3: Test
curl -X POST http://localhost:8000/trigger \
  -H "Content-Type: application/json" \
  -d '{"story_id": "US-12345"}'
```

## Contributing

Follow SDLC platform conventions:
- See: `/rules/commit-conventions.md`
- See: `/rules/global-standards.md`
- See: `/rules/guardrails.md`

Commit format:
```
feat(orchestrator): implement requirement analysis agent AB#12345

- Fetch ADO ticket with context
- Extract requirements using Claude
- Write to KB with audit log
```

## Support

For issues or questions:
1. Check `/docs` (OpenAPI/Swagger)
2. Check health endpoint: `GET /health`
3. Review logs: `docker logs qa-orchestrator-api`
4. Check Redis: `redis-cli PING`

---

**Version**: 1.0.0  
**Last Updated**: 2026-04-11  
**Maintained by**: AI-SDLC Platform Team
