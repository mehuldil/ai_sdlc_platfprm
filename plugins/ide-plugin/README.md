# AI-SDLC Platform IDE Plugin

Complete intelligent SDLC automation in your IDE. Supports 15-stage workflow from requirements to incident response with natural language commands and interactive prompts.

**Status**: Production-ready for Cursor IDE and Claude Code

## Quick Start (One Command)

### Prerequisites
- Node.js 18+ installed
- Azure DevOps account with project access
- Cursor IDE or Claude Code (or both)

### Setup

```bash
# From repo root after clone:
cd plugins/ide-plugin && npm run setup
```

This single command does everything:
1. Installs npm dependencies (MCP SDK, axios, zod)
2. Creates `env/.env` from template
3. Bootstraps `.sdlc/` directory (memory, config, state)
4. Wires `.claude/commands/` for Claude Code slash commands (`/project:*`)
5. Wires `.cursor/mcp.json` for Cursor IDE MCP tools
6. Validates MCP server syntax
7. Tests ADO connection (if PAT set)

### After setup — one manual step:

```bash
# Edit env/.env and set your ADO Personal Access Token:
ADO_PAT=your-token-here

# Get PAT: Azure DevOps → User Settings → Personal Access Tokens → New Token
# Scopes: Work Items (Read & Write), Code (Read)
```

### Verify it works:

```bash
# Test MCP server with inspector:
npx @modelcontextprotocol/inspector node plugins/ide-plugin/mcp/ado-server.js

# In Claude Code:
/project:prd-review AB#12345

# In Cursor: MCP tools auto-loaded (list-work-items, post-comment, etc.)
```

Done! You're ready to automate your entire SDLC.

---

## Usage Examples

### Example 1: Create a New Feature (5 minutes)

```
User: I want to build multi-language support for our signup flow

Claude: 📋 Requirement Intake & Work Item Creation
  
  What are we building?
    [1] New feature (user-facing capability)
    [2] Bug fix (defect resolution)
    ...
  
User: [1]

[Interactive prompts for details...]

✓ Created Epic AB#12345 (Multi-language signup)
✓ Created Master Story AB#12346
```

### Example 2: Review PRD for Completeness

```
User: /project:prd-review AB#12345 --role=backend

Claude: 🎯 PRD Review & Gap Analysis

✅ COMPLETE SECTIONS:
  • Goals & metrics ✓
  • User stories ✓
  • Success criteria ✓

⚠️ GAPS (Backend perspective):
  1. Missing: API contract details (BLOCKING)
  2. Unclear: Async vs sync strategy
  3. Missing: Data model

[Posts gaps as ADO comment on work item...]
```

### Example 3: Break Down Story into Sprint Tasks

```
User: /project:sprint-planning AB#12346 --sprint=12

Claude: 📅 Sprint Planning & Task Breakdown

Team assignment:
  • Backend: Alice (4h) + Bob (6h)
  • Frontend: Carol (6h) + Dave (4h)
  • QA: Eve (7h)

Total: 27 hours (fits in sprint capacity)

[Creates 11 ADO tasks with dependencies...]
```

### Example 4: Natural Language Example

```
User: Help me test the phone verification feature, I need a test matrix for all edge cases

Claude: 🧪 Test Design & Matrix

Detected: test-design request for story with acceptance criteria

Create test matrix for: Phone verification & OTP
  [1] Unit + Integration tests only
  [2] Full scope (unit + integration + E2E + performance)
  [3] Manual testing guide

User: [2]

[Generates comprehensive test matrix with 18 test cases in Gherkin format...]
```

---

## 15 SDLC Stages

| # | Stage | Command | What It Does | Output |
|---|-------|---------|-------------|--------|
| 1 | Requirement Intake | `/project:requirement-intake` | Capture requirements, create Epic + Master Story | ADO work items |
| 2 | PRD Review | `/project:prd-review AB#123` | Review for gaps, post as ADO comments | Gap report + ADO comments |
| 3 | Story Grooming | `/project:grooming AB#123` | Break into sprint stories with AC | Sprint stories + tasks |
| 4 | Architecture Review | `/project:architecture-review AB#123` | Design decisions, create ADRs | ADRs + risk analysis |
| 5 | System Design | `/project:system-design AB#123` | Data model, APIs, deployment strategy | OpenAPI spec + diagrams |
| 6 | Sprint Planning | `/project:sprint-planning AB#123` | Task breakdown, team assignment | Task board + plan |
| 7 | Implementation | `/project:implementation AB#123` | Dev guidance, code templates | Code templates + progress |
| 8 | Code Review | `/project:code-review --pr=2456` | PR review, security audit | Review comments + approval |
| 9 | Test Design | `/project:test-design AB#123` | QA test matrix, automation | Test cases + scripts |
| 10 | Performance Testing | `/project:performance-testing AB#123` | Load testing, NFR validation | Performance report |
| 11 | Staging Validation | `/project:staging-validation AB#123` | Deploy to staging, get sign-offs | Validation report + approvals |
| 12 | Release Prep | `/project:release-prep AB#123` | Compliance check, release notes | Checklist + release notes |
| 13 | Deployment | `/project:deployment AB#123 --version=1.2.0` | Deploy to production (canary) | Deployment record |
| 14 | Monitoring | `/project:monitoring AB#123` | Setup alerts, create runbooks | Dashboard + runbooks |
| 15 | Incident Response | `/project:incident-response --incident=INC-2456` | Handle incidents, create post-mortem | Post-mortem + ADO comments |

---

## Features

### 🎯 Natural Language + Slash Commands

Choose your style:
- **Slash commands**: `/project:grooming AB#123` (fast, clear)
- **Natural language**: "Break down this story into sprint tasks" (flexible)
- **Hybrid**: Describe what you need, Claude suggests which command

### 📊 Interactive Prompts

Get prompted for missing information right in IDE chat:
```
Claude: 📋 Requirement Intake

What are we building?
  [1] New feature
  [2] Bug fix
  [3] Technical task
  [4] Epic

Select option or type custom: _
```

### 💾 Memory Persistence

Previous decisions automatically loaded:
- Story context from earlier stages
- Architecture decisions (ADRs)
- Test matrices
- Deployment strategy

No re-explaining needed across stages!

### 🔄 Orchestrator Agent

Run multi-stage workflows automatically:
```
User: Create a complete feature from requirements to deployment

Claude: 🚀 Orchestrator: Feature → Deployment

Phases:
  1. PRD Review (10 min) → Review requirements for completeness
  2. Grooming (15 min) → Create sprint stories
  3. Design (20 min) → Architecture + data model
  4. Sprint Planning (10 min) → Task breakdown + assignment
  
Continue?
  [1] Yes, auto-run all phases
  [2] Manual control (pause between phases)
  [3] Edit phases first

User: [1]

[Executes workflow with real-time progress dashboard...]

✅ Complete workflow finished in 55 minutes
```

### 🔐 Secure ADO Integration

- Uses ADO Personal Access Tokens (not passwords)
- No credentials stored in code or chat
- Supports enterprise ADO organizations
- Works with both cloud and on-premises Azure DevOps

### 📈 Smart Model Selection

Automatically chooses right model for task:
- **Haiku** (fast, cheap): Simple validation, routing
- **Sonnet** (balanced): Story generation, code review
- **Opus** (powerful): Complex design, architecture decisions

---

## Configuration

### Environment Variables

Required:
```bash
ADO_ORG=your-ado-org              # Your ADO organization
ADO_PROJECT=YourAzureProject             # Your ADO project
ADO_PAT=your-token-here          # Personal Access Token
```

Optional:
```bash
MODEL_TIER=sonnet                # Default model (haiku/sonnet/opus)
MEMORY_PATH=.sdlc/memory         # Where to save context
CANARY_PERCENTAGE=5              # Default canary rollout %
```

### Save to .env File

1. Create `env/.env` in your project root
2. Add variables (one per line)
3. Plugin auto-loads on startup

**Example env/.env:**
```bash
ADO_ORG=your-ado-org
ADO_PROJECT=YourAzureProject
ADO_PAT=pa2vkcx3hjwhz...
MODEL_TIER=sonnet
CANARY_PERCENTAGE=5
```

### Getting Your ADO PAT

1. Go to https://dev.azure.com/
2. Click your profile → User Settings
3. Click "Personal access tokens"
4. Click "+ New Token"
5. Fill in:
   - Name: `ai-sdlc-platform`
   - Scopes: Check "Work Items" (Read & Write)
   - Expiration: 90 days (or 1 year)
6. Click "Create"
7. Copy the token immediately (can't retrieve later)
8. Paste into `env/.env` as `ADO_PAT`

---

## Project Structure

```
your-project/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata & configuration
├── .mcp.json                    # MCP server config (ADO)
├── env/
│   ├── .env                     # Your Azure DevOps credentials
│   └── env.template             # Template with required vars
├── .sdlc/
│   ├── config                   # Project configuration
│   ├── state.json               # Current session state
│   └── memory/
│       ├── requirement-intake-AB#12345.json
│       ├── prd-review-AB#12345.md
│       ├── grooming-AB#12346.json
│       └── ...                  # Previous stage outputs
├── skills/
│   ├── requirement-intake/
│   ├── prd-review/
│   ├── grooming/
│   ├── ... (13 more skills)
│   └── incident-response/
├── agents/
│   ├── orchestrator-agent.md    # Multi-stage workflow automation
│   └── nl-processor/            # Natural language command processor
├── mcp/
│   └── ado-server.js            # Azure DevOps MCP server
├── hooks/
│   └── context-loader.js        # Auto-load memory on startup
└── README.md                    # This file
```

---

## Workflow Examples

### Complete Feature Delivery (2-3 hours)

```
1. User describes feature → Requirement Intake (10 min)
2. Plugin creates Epic + Master Story
3. PM reviews PRD → PRD Review (15 min)
4. Engineering breaks down → Grooming (20 min)
5. Architect designs → Architecture + System Design (30 min)
6. Team plans sprint → Sprint Planning (10 min)
7. Developers implement → Implementation (multiple sessions)
8. Team tests → Test Design + Performance (20 min)
9. Deploy to staging → Staging Validation (15 min)
10. Release check → Release Prep (10 min)
11. Production deploy → Deployment (10 min)
12. Monitor → Monitoring setup (10 min)

Total: 2-3 hours of coordination automation
Team effort: 40-60 hours of development (tracked in ADO tasks)
```

### Bug Fix (1-2 hours)

```
1. User reports bug → Requirement Intake (5 min)
2. Triage as P1/P2 → Create Bug work item
3. Architect designs fix → Architecture Review (10 min)
4. Dev implements → Implementation (1-2 hours)
5. Test & code review → Code Review + Testing (30 min)
6. Deploy to staging → Staging Validation (15 min)
7. Release → Deployment (10 min)
8. Monitor → Monitoring + Incident Response (10 min)
```

### Emergency Hotfix (30 minutes)

```
1. /project:incident-response --incident=INC-2456
2. Plugin runs triage + runbook
3. Auto-escalates to on-call engineer
4. Coordinates fix deployment (bypass standard gates)
5. Post-mortem automation
```

---

## Troubleshooting

### Connection Issues

**Problem**: "ADO connection failed"

**Solution**:
1. Check `ADO_PAT` is correct (copy from Azure DevOps fresh)
2. Verify `ADO_ORG` matches your organization
3. Check PAT scopes include "Work Items" (Read & Write)
4. Verify network access to dev.azure.com
5. Check PAT hasn't expired (90-day default)

### Command Not Recognized

**Problem**: "/project:grooming not found"

**Solution**:
1. Check spelling: `/project:grooming` (not `/grooming`)
2. Verify skill is loaded: `/project:help`
3. Check plugin installed correctly
4. Restart IDE chat window
5. Reinstall plugin if issue persists

### Memory Not Loading

**Problem**: "Previous decisions not showing"

**Solution**:
1. Check `.sdlc/memory/` directory exists
2. Verify memory files have correct names (e.g., `grooming-AB#123.json`)
3. Check file permissions (readable)
4. Restart IDE to reload memory hook
5. Manually pass story ID: `/project:grooming AB#123`

### ADO Tasks Not Creating

**Problem**: "Failed to create work item"

**Solution**:
1. Check you have "Create" permission in ADO project
2. Verify parent Epic exists (if creating subtask)
3. Check ADO_PAT has "Work Items" scope (Read & Write)
4. Try manual creation first to verify ADO access
5. Check ADO server logs: `mcp/ado-server.js`

### Performance Issues

**Problem**: "Slow response from plugin"

**Solution**:
1. Check memory files aren't too large (>10MB)
2. Compress old memory files to archive
3. Use smaller story IDs in queries
4. Run `/project:help` to reload context
5. Clear browser cache if using Cursor browser extension

---

## Best Practices

### 1. Use Consistent Story IDs

Always reference work item the same way:
```
✓ /project:grooming AB#1234
✓ /project:grooming 1234
✗ /project:grooming "Multi-language signup"  (avoid plain text)
```

### 2. Provide Context in Natural Language

More detail = better automation:
```
✓ "Create a master story for multi-language signup feature including
   5 languages (EN, ES, FR, DE, ZH), backend + frontend + QA breakdown"
   
✗ "Create a story"
```

### 3. Save ADO PAT Securely

Never commit `env/.env` to git:
```bash
# Add to .gitignore
env/.env
env/.env.local
```

### 4. Review Automated Decisions

Plugin creates suggestions; you approve:
- Always review PRD gap analysis before marking "ready"
- Approve story estimation before committing to sprint
- Review deployment plan before going to production
- Validate post-mortem findings before publishing

### 5. Keep Memory Files Clean

Archive old memory periodically:
```bash
# Keep current sprint memory, compress older ones
tar -czf .sdlc/memory-archive-2026-03.tar.gz .sdlc/memory/*-AB#1*
rm .sdlc/memory/*-AB#1*
```

---

## Advanced Usage

### Custom Workflows with Orchestrator

```
User: Create custom 3-phase workflow for "Refactor" task

Claude: 🎯 Custom Orchestrator

Phase 1: Code Analysis
  - Run architecture-review
  - Identify refactor scope

Phase 2: Implementation
  - Generate code templates
  - Track progress with checkpoints

Phase 3: Validation
  - Code review
  - Performance testing (before/after)

Create this workflow?
  [1] Yes, save as "refactor-workflow"
  [2] Edit phases
  [3] Cancel

User: [1]

✓ Workflow "refactor-workflow" created
Access with: /project:orchestrator --workflow=refactor-workflow
```

### Multi-Team Coordination

```
/project:sprint-planning AB#123 --teams=backend,frontend,qa

Claude creates separate task lists per team, manages dependencies:
- Backend tasks must complete before Frontend starts
- QA tasks start in parallel with Development
- Plugin shows critical path & slack
```

### Custom Alerts & Runbooks

```
/project:monitoring AB#123 --create-custom-alert

Trigger: "Error rate > 1% for 2 minutes"
Action: "Rollback to previous version + page on-call"
Runbook: "Auto-generated troubleshooting guide"
```

---

## API Reference

### Slash Commands

```bash
/project:requirement-intake                    # Create requirements
/project:prd-review AB#123                     # Review PRD
/project:grooming AB#123 --type=master         # Create master story
/project:architecture-review AB#123 --role=backend
/project:system-design AB#123
/project:sprint-planning AB#123 --sprint=12
/project:implementation AB#123 --task=BKD-01
/project:code-review --pr=2456
/project:test-design AB#123
/project:performance-testing AB#123 --nfr=latency
/project:staging-validation AB#123
/project:release-prep AB#123 --version=1.2.0
/project:deployment AB#123 --canary=5%
/project:monitoring AB#123 --setup-alerts
/project:incident-response --incident=INC-2456
/project:orchestrator --workflow=feature-delivery
/project:help                                  # Show this reference
```

### Environment Variables

```bash
ADO_ORG                 # Azure DevOps organization
ADO_PROJECT             # Azure DevOps project
ADO_PAT                 # Personal Access Token (required)
MODEL_TIER              # Model selection (haiku/sonnet/opus)
MEMORY_PATH             # Context persistence directory
CANARY_PERCENTAGE       # Default canary rollout %
```

---

## Support & Contributing

### Report Issues
- GitHub Issues: [ai-sdlc-platform/issues](https://github.com/yourusername/ai-sdlc-platform/issues)
- Email: mehul.dedhia@ril.com

### Documentation
- Full Wiki: [ai-sdlc-platform/wiki](https://github.com/yourusername/ai-sdlc-platform/wiki)
- Quick Reference: Run `/project:help` in IDE chat
- Examples: See examples/ directory in repo

### Contributing
- Fork the repo
- Create feature branch: `git checkout -b feature/my-improvement`
- Add tests and documentation
- Submit pull request

---

## License

Proprietary — your-ado-org. All rights reserved.

---

## Changelog

### v1.0.0 (2026-04-12)
- Initial release
- 15 complete SDLC stages
- Natural language + slash command support
- Azure DevOps integration
- Memory persistence
- Multi-stage orchestration
- Production-ready for Cursor IDE & Claude Code

---

## Quick Reference

| Goal | Command |
|------|---------|
| Start new feature | `/project:requirement-intake` |
| Review PRD | `/project:prd-review AB#123` |
| Create sprint stories | `/project:grooming AB#123` |
| Design system | `/project:system-design AB#123` |
| Plan sprint | `/project:sprint-planning AB#123` |
| Get dev guidance | `/project:implementation AB#123` |
| Review code | `/project:code-review --pr=2456` |
| Design tests | `/project:test-design AB#123` |
| Load test | `/project:performance-testing AB#123` |
| Deploy to staging | `/project:staging-validation AB#123` |
| Release to production | `/project:deployment AB#123 --version=1.2.0` |
| Handle incident | `/project:incident-response --incident=INC-2456` |
| Auto-run full workflow | `/project:orchestrator --workflow=feature-delivery` |

---

**Made with ❤️ by Mehul Dedhia & your-ado-org Engineering**
