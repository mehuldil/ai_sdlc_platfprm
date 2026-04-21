# QA Orchestrator Integration Checklist

Use this checklist to integrate the QA Orchestrator into your deployment environment.

## Pre-Deployment Validation

- [ ] Clone/pull latest code
- [ ] Run syntax check: `python -m py_compile qa/*.py qa/**/*.py`
- [ ] Verify file structure matches directory tree in README.md
- [ ] Review DELIVERY_SUMMARY.md for architecture overview

## Environment Setup

### 1. Configuration

- [ ] Copy `.env.example` to `.env`
- [ ] Set `ANTHROPIC_API_KEY` (get from https://console.anthropic.com)
- [ ] Set `ADO_PAT` (Azure DevOps Personal Access Token)
  - [ ] Grant scopes: Work Items (Read & Write), Code (Read), Build (Read)
  - [ ] Set expiration: 90 days or 1 year
- [ ] Set `ADO_ORG` (typically `your-ado-org`)
- [ ] Set `ADO_PROJECT` (typically `YourAzureProject`)
- [ ] Verify other settings match your deployment requirements

### 2. Dependencies

- [ ] Python 3.11+ installed
- [ ] Create virtual environment: `python -m venv venv`
- [ ] Activate: `. venv/bin/activate`
- [ ] Install: `pip install -r requirements.txt`

### 3. Redis

**Option A: Docker**
- [ ] Docker installed
- [ ] Run: `docker-compose up -d redis`
- [ ] Verify: `redis-cli ping` should return `PONG`

**Option B: Local**
- [ ] Redis 7+ installed
- [ ] Run: `redis-server`
- [ ] Verify: `redis-cli ping` should return `PONG`

## Local Testing (Pre-Docker)

- [ ] Run health check: `python -c "from qa.app_config import AppConfig; c = AppConfig(); print(c.validate())"`
- [ ] Start API: `uvicorn qa.api.main:app --reload`
- [ ] Open http://localhost:8000/dashboard
- [ ] Test trigger endpoint:
  ```bash
  curl -X POST http://localhost:8000/trigger \
    -H "Content-Type: application/json" \
    -d '{"story_id": "US-99999"}'
  ```
- [ ] Check response contains `run_id`
- [ ] Stop API

## Docker Deployment

- [ ] Docker and docker-compose installed
- [ ] Review `docker-compose.yml` (update resource limits if needed)
- [ ] Build and run: `docker-compose up --build`
- [ ] Wait for Redis health check to pass
- [ ] Wait for API to report "listening on 0.0.0.0:8000"
- [ ] Test health endpoint: `curl http://localhost:8000/health`
- [ ] Expected response: `{"status": "healthy", ...}`

## SDLC Platform Integration

### 1. Skill Installation

- [ ] Copy skill file: `cp skills/qa-orchestrator.md /path/to/sdlc/skills/`
- [ ] Verify CLI commands work:
  ```bash
  sdlc qa start US-12345 --priority=high
  sdlc qa status <run-id>
  sdlc qa health
  ```

### 2. ADO Configuration

- [ ] Verify work items get `claude:generated` tag
- [ ] Test bug filing (defect_management agent)
- [ ] Verify parent-child links are created correctly
- [ ] Test attachment upload with screenshots

### 3. Shared Memory Setup

- [ ] Create `.sdlc/memory/qa/` directory
- [ ] Ensure write permissions for API process
- [ ] Verify archival writes to `data/kb_archive/`

## Feature Flag Verification

- [ ] `ENABLE_WEBHOOK_NOTIFICATIONS`: Set to `true` if using webhook events
- [ ] `ENABLE_METRICS_COLLECTION`: Set to `true` for metrics dashboard
- [ ] `ENABLE_PARALLEL_EXECUTION`: Keep `false` unless scaling tests
- [ ] `ENABLE_REFINE_GATES`: Set to `true` (enables REFINE decision at all gates)

## Governance Configuration

- [ ] Set `GOVERNANCE_TIMEOUT_HOURS`: Default 24, adjust based on SLA
- [ ] Set `AUTO_APPROVE`: Default `false` (human approval required)
  - If `true`: Gates auto-approve after timeout (use with caution)
- [ ] Verify gate requirements in `qa/governance.py` match your process

## API Endpoint Testing

### Trigger Pipeline

```bash
curl -X POST http://localhost:8000/trigger \
  -H "Content-Type: application/json" \
  -d '{
    "story_id": "US-12345",
    "priority": "high",
    "tags": ["regression", "critical"]
  }'
```

Expected: `{"run_id": "uuid", "status": "STARTED", ...}`

### Get Status

```bash
curl http://localhost:8000/status/550e8400-e29b-41d4-a716-446655440000
```

Expected: Full workflow + gate status

### Approve Gate

```bash
curl -X POST 'http://localhost:8000/approve?run_id=550e8400-...' \
  -H "Content-Type: application/json" \
  -d '{
    "checkpoint": "requirements",
    "decision": "APPROVED",
    "reason": "Verified by PM"
  }'
```

Expected: Confirmation + next agent starts

### Get KB Store

```bash
curl http://localhost:8000/kb/550e8400-.../test_cases
```

Expected: Full KB store JSON

### Health Check

```bash
curl http://localhost:8000/health
```

Expected: `{"status": "healthy", "redis": {...}, "config_valid": true}`

## Monitoring & Logging

- [ ] Configure log level: `LOG_LEVEL=INFO` (or DEBUG for troubleshooting)
- [ ] Set log format: `LOG_FORMAT=json` for structured logging
- [ ] Monitor Redis memory: `redis-cli INFO memory`
- [ ] Check API uptime: `docker logs qa-orchestrator-api`

## Performance Baseline

**Establish baselines before agents are fully implemented:**

- [ ] API response time (should be <100ms)
- [ ] Redis latency (should be <10ms)
- [ ] KB store size per run (should be <1MB)
- [ ] Memory footprint (API should use <500MB)

## Backup & Disaster Recovery

- [ ] Backup `.env` file (contains secrets)
- [ ] Backup KB archive directory: `data/kb_archive/`
- [ ] Document Redis backup strategy
- [ ] Test restore procedure for archived runs

## Security Hardening

- [ ] Change default `REDIS_PORT` if needed
- [ ] Restrict API access with reverse proxy/firewall
- [ ] Use HTTPS for production API (add SSL cert)
- [ ] Rotate ADO PAT annually
- [ ] Never commit `.env` to version control

## Agent Implementation Preparation

- [ ] Review agent stub files in `qa/agents/`
- [ ] Understand agent pattern from `requirement_analysis.py`
- [ ] Create implementation plan for 7 remaining agents
- [ ] Assign developers to agents
- [ ] Set implementation timeline

## Post-Deployment Checklist

- [ ] Dashboard accessible at http://localhost:8000/dashboard
- [ ] OpenAPI docs at http://localhost:8000/docs
- [ ] ReDoc at http://localhost:8000/redoc
- [ ] All 12 endpoints tested and working
- [ ] Redis persistence enabled (if needed)
- [ ] Logs being written to appropriate location
- [ ] Metrics collection active (if enabled)
- [ ] Team trained on CLI commands
- [ ] Runbook created for common operations
- [ ] Escalation path defined (who to contact if agent fails)

## Troubleshooting

### API Won't Start

- [ ] Check Redis is running: `redis-cli ping`
- [ ] Verify `.env` settings: `grep -E "ANTHROPIC|ADO_" .env`
- [ ] Check logs: `docker logs qa-orchestrator-api` or terminal output
- [ ] Verify port 8000 is available: `lsof -i :8000`

### Redis Connection Failed

- [ ] Check Redis service: `systemctl status redis` or `docker ps | grep redis`
- [ ] Verify Redis port: `redis-cli -p 6379 ping`
- [ ] Check firewalls blocking Redis port
- [ ] Verify `REDIS_HOST` and `REDIS_PORT` in `.env`

### Claude API Errors

- [ ] Verify `ANTHROPIC_API_KEY` is set and valid
- [ ] Check Claude API status: https://status.anthropic.com
- [ ] Verify network connectivity to api.anthropic.com
- [ ] Check rate limits (if hitting 429 errors)

### ADO Integration Issues

- [ ] Verify `ADO_PAT` is valid and not expired
- [ ] Check PAT has required scopes (Work Items: Read & Write)
- [ ] Verify `ADO_ORG` and `ADO_PROJECT` are correct
- [ ] Test manually: `curl -u ":${ADO_PAT}" https://dev.azure.com/your-ado-org/_apis/projects?api-version=7.0`

## Success Criteria

- [ ] Pipeline starts and reaches first governance gate
- [ ] Gate pauses waiting for approval
- [ ] Approval request processed successfully
- [ ] Workflow continues to next agent
- [ ] KB stores populated correctly
- [ ] No errors in logs
- [ ] Health check returns `status: healthy`
- [ ] Team can trigger and monitor via CLI

## Handoff Sign-Off

- [ ] Implementation lead reviews and approves
- [ ] QA lead validates test coverage
- [ ] DevOps lead approves deployment
- [ ] Product lead acknowledges integration
- [ ] Documentation is complete and reviewed
- [ ] All team members trained on system

---

**Checklist Version**: 1.0  
**Last Updated**: 2026-04-11  
**Maintained by**: AI-SDLC Platform Team
