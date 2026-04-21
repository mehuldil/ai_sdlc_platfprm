# Plugin Structure Reference

Complete file and directory structure of the AI-SDLC Platform IDE Plugin.

```
ai-sdlc-ide-plugin/
│
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest & metadata
│                                  - Defines all 15 skills
│                                  - Configures MCP servers
│                                  - Sets up hooks
│                                  - Specifies environment vars
│
├── .mcp.json                    # MCP server configuration
│                                  - Azure DevOps server setup
│                                  - Environment variable mapping
│
├── skills/                      # 15 skill implementations (one per SDLC stage)
│   ├── requirement-intake/
│   │   └── SKILL.md             # Stage 1: Capture requirements
│   │
│   ├── prd-review/
│   │   └── SKILL.md             # Stage 2: Review PRD for gaps
│   │
│   ├── grooming/
│   │   └── SKILL.md             # Stage 3: Story breakdown
│   │
│   ├── architecture-review/
│   │   └── SKILL.md             # Stage 4: Architecture decisions
│   │
│   ├── system-design/
│   │   └── SKILL.md             # Stage 5: Data model & APIs
│   │
│   ├── sprint-planning/
│   │   └── SKILL.md             # Stage 6: Task breakdown
│   │
│   ├── implementation/
│   │   └── SKILL.md             # Stage 7: Dev guidance
│   │
│   ├── code-review/
│   │   └── SKILL.md             # Stage 8: Code quality
│   │
│   ├── test-design/
│   │   └── SKILL.md             # Stage 9: QA test matrix
│   │
│   ├── performance-testing/
│   │   └── SKILL.md             # Stage 10: Load testing
│   │
│   ├── staging-validation/
│   │   └── SKILL.md             # Stage 11: Staging sign-off
│   │
│   ├── release-prep/
│   │   └── SKILL.md             # Stage 12: Compliance check
│   │
│   ├── deployment/
│   │   └── SKILL.md             # Stage 13: Production deploy
│   │
│   ├── monitoring/
│   │   └── SKILL.md             # Stage 14: Alerts & runbooks
│   │
│   ├── incident-response/
│   │   └── SKILL.md             # Stage 15: Incident mgmt
│   │
│   └── nl-processor/
│       └── SKILL.md             # Natural language processor
│                                  - Pattern matching
│                                  - Command classification
│
├── agents/
│   └── orchestrator-agent.md    # Multi-stage workflow orchestrator
│                                  - Runs complete feature delivery
│                                  - Progress dashboard
│                                  - Checkpoint & resumption
│
├── mcp/
│   └── ado-server.js            # Azure DevOps MCP server
│                                  - List work items
│                                  - Get work item details
│                                  - Create/update work items
│                                  - Post comments
│
├── hooks/
│   └── context-loader.js        # Context loading hook
│                                  - Auto-loads .sdlc/memory on startup
│                                  - Extracts context from chat messages
│                                  - Persists memory between stages
│
├── env/
│   └── env.template             # Environment variable template
│                                  - ADO_ORG, ADO_PROJECT, ADO_PAT
│                                  - Optional: MODEL_TIER, MEMORY_PATH
│
├── package.json                 # Node.js dependencies
│                                  - axios (HTTP client)
│                                  - Build & test scripts
│
├── README.md                    # Complete plugin documentation
│                                  - Quick start (2 min)
│                                  - Feature overview
│                                  - Usage examples
│                                  - Configuration guide
│                                  - Troubleshooting
│                                  - API reference
│
├── TEST_WORKFLOW_EXAMPLE.md    # End-to-end workflow example
│                                  - Complete 15-stage example
│                                  - Multi-language signup feature
│                                  - Output verification checklist
│
└── PLUGIN_STRUCTURE.md          # This file
```

## File Count Summary

- **Skills**: 16 SKILL.md files (15 stages + NL processor)
- **Core Components**: 3 files (plugin.json, .mcp.json, package.json)
- **Servers**: 1 MCP server (ado-server.js)
- **Hooks**: 1 hook (context-loader.js)
- **Agents**: 1 agent (orchestrator-agent.md)
- **Documentation**: 3 files (README.md, TEST_WORKFLOW_EXAMPLE.md, PLUGIN_STRUCTURE.md)
- **Configuration**: 1 template (env.template)

**Total**: 26 files

## Key Features

### 1. Natural Language Interface
- `/project:requirement-intake` (slash command)
- "Create a feature for multi-language signup" (natural language)
- Hybrid pattern matching + AI understanding

### 2. Memory Persistence
- `.sdlc/memory/` stores all stage outputs
- Automatically loaded on plugin startup
- Cross-session context maintained

### 3. ADO Integration
- MCP server communicates with Azure DevOps
- Creates/updates work items
- Posts comments with findings
- Manages tags and links

### 4. 15-Stage Workflow
- Each stage fully documented (SKILL.md)
- Interactive prompts with numbered options
- Output artifacts (ADO tasks, documents, reports)

### 5. Orchestrator Agent
- Runs multi-stage workflows automatically
- Progress dashboard with visual indicators
- Checkpoint system for interruption recovery

## Configuration Hierarchy

1. **env/.env** (highest priority)
   - User-specific Azure DevOps credentials
   - Override defaults
   - Never committed to git

2. **plugin.json** (defaults)
   - Model selection (haiku/sonnet/opus)
   - Memory path
   - Canary percentage

3. **Hardcoded defaults** (fallback)
   - If env var not set, use default

## Stage Execution Flow

```
User input (slash command or natural language)
         ↓
NL Processor (classify intent → stage)
         ↓
Context Loader (load .sdlc/memory context)
         ↓
Select Skill (match to 15 SDLC stages)
         ↓
Interactive Prompts (ask missing questions)
         ↓
ADO Integration (create/update work items)
         ↓
Generate Artifacts (templates, matrices, etc.)
         ↓
Save Memory (persist stage output)
         ↓
Update ADO Status (post comment with findings)
```

## Dependencies

### NPM Packages
- `axios` (^1.6.0) - HTTP client for ADO API calls

### Claude Models
- `haiku` - Simple classification, validation
- `sonnet` - Story generation, code review
- `opus` - Complex architecture decisions

### External Services
- Azure DevOps (work item management)
- CloudWatch (optional, for monitoring)
- PagerDuty (optional, for on-call)

## Memory Structure

```
.sdlc/
├── config                           # Project configuration
├── state.json                       # Current session state
└── memory/
    ├── requirement-intake-AB#12345.json
    ├── prd-review-AB#12345.md
    ├── grooming-AB#12346.json
    ├── architecture-review-AB#12352.md
    ├── system-design-AB#12352.yaml  (OpenAPI)
    ├── sprint-planning-AB#12352.json
    ├── implementation-AB#12352.json (progress)
    ├── code-review-AB#12352.md      (findings)
    ├── test-design-AB#12352.json    (test matrix)
    ├── performance-testing-AB#12352.json
    ├── staging-validation-AB#12352.md
    ├── release-prep-AB#12352.md
    ├── deployment-AB#12352.md       (canary rollout)
    ├── monitoring-AB#12352.json     (alert config)
    └── incident-response-INC-2456.md (post-mortem)
```

## Slash Commands Reference

```
/project:requirement-intake              [Stage 1]
/project:prd-review AB#123               [Stage 2]
/project:grooming AB#123 --type=master   [Stage 3]
/project:architecture-review AB#123      [Stage 4]
/project:system-design AB#123            [Stage 5]
/project:sprint-planning AB#123          [Stage 6]
/project:implementation AB#123           [Stage 7]
/project:code-review --pr=2456           [Stage 8]
/project:test-design AB#123              [Stage 9]
/project:performance-testing AB#123      [Stage 10]
/project:staging-validation AB#123       [Stage 11]
/project:release-prep AB#123             [Stage 12]
/project:deployment AB#123               [Stage 13]
/project:monitoring AB#123               [Stage 14]
/project:incident-response --incident=   [Stage 15]
/project:orchestrator --workflow=        [Multi-stage]
/project:help                            [Reference]
```

## Quick Start Commands

```bash
# Install dependencies
npm install

# Validate plugin structure
npm run validate

# Package as .plugin file
npm run package

# Install in IDE (copy .plugin file to plugins directory)
npm run install-plugin
```

## Extending the Plugin

### Add Custom Skill
1. Create `skills/my-skill/SKILL.md`
2. Add to `plugin.json` skills array
3. Define trigger keywords and commands

### Add Custom Agent
1. Create `agents/my-agent.md`
2. Reference in `plugin.json` agents array
3. Document capabilities

### Add Custom Hook
1. Create `hooks/my-hook.js`
2. Export function in module.exports
3. Reference in `plugin.json` hooks array with trigger

### Add New MCP Server
1. Create `mcp/my-server.js`
2. Implement stdin/stdout protocol
3. Reference in `.mcp.json` mcpServers

---

## Support

- **Documentation**: See README.md
- **Examples**: See TEST_WORKFLOW_EXAMPLE.md
- **API Reference**: See /project:help in IDE chat
- **Issues**: GitHub repository issues
- **Contact**: mehul.dedhia@ril.com

---

**Last Updated**: 2026-04-12  
**Plugin Version**: 1.0.0
