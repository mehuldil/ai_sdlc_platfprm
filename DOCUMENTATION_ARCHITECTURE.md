# Documentation Architecture & Governance Plan
## AI-SDLC Platform

**Status**: Active  
**Last Updated**: 2026-04-13  
**Maintainer**: Technical PM / Documentation Engineer

---

## Executive Summary

The AI-SDLC platform has **277 documentation files** organized across multiple layers. This document defines:
1. Which layer is the **single source of truth** (Public API)
2. Which layers are **implementation reference** (Internal)
3. **Auto-update validation** to prevent documentation drift
4. **Deduplication strategy** to minimize maintenance burden

---

## Documentation Layers

### Layer 1: PUBLIC API (User Manual) ✅ PRODUCTION-READY
**Location**: `/User_Manual/`  
**Files**: 11 core documents (1,199 lines)  
**Audience**: End users, developers, PMs, admins  
**Status**: COMPLETE, NO RESTRUCTURING NEEDED

**Files**:
- `README.md` — Navigation index
- `System_Overview.md` — What/why/how the system works
- `Getting_Started.md` — Setup & first run
- `Architecture.md` — Component structure, extension points
- `Commands.md` — CLI & IDE slash commands
- `SDLC_Flows.md` — 15-stage pipeline, gates, roles
- `Agents_Skills_Rules.md` — Inventory of all agents, skills, rules
- `PR_Merge_Process.md` — Code review, PR templates, hooks
- `ADO_MCP_Integration.md` — Azure DevOps sync via MCP
- `Documentation_Rules.md` — Single-source-of-truth principle, governance
- `FAQ.md` — 25+ Q&A pairs

**Principles** (ENFORCED):
- Minimal verbosity (no long prose)
- Atomic definitions (each concept once only)
- Cross-reference, don't duplicate
- "Ask for details" prompts
- Token-efficient (avg 100 lines per file)

**Update Trigger**: When agents, skills, rules, commands, or flows change

---

### Layer 2: IMPLEMENTATION REFERENCE (Internal Docs)
**Audience**: System developers, AI engineers, maintainers

#### 2a. IDE Rules & Commands
**Location**: `.claude/rules/`, `.claude/commands/`  
**Files**: 51 command implementations + 6 enforcement rules  
**Purpose**: IDE-specific implementations of the system  
**Relationship to User_Manual**: Commands.md REFERENCES these, but implementation details stay here

**Auto-Update Rule**:
- If `.claude/commands/` changes → update `User_Manual/Commands.md` summary
- If new command added → auto-generate registry entry

#### 2b. Agent Definitions
**Location**: `agents/`  
**Files**: 68 AI agents organized by domain  
**Relationship to User_Manual**: `Agents_Skills_Rules.md` contains INVENTORY; full agent code lives here

**Auto-Update Rule**:
- If agent count changes → regenerate `agents/CAPABILITY_MATRIX.md` and `User_Manual/Agents_Skills_Rules.md`
- If agent description changes → update matrix

#### 2c. Skill Definitions
**Location**: `skills/`  
**Files**: 42 executable skills (RPI phases, QA orchestration, etc.)  
**Relationship to User_Manual**: `Agents_Skills_Rules.md` lists them; implementations live here

**Auto-Update Rule**:
- If skill count changes → regenerate `skills/SKILL.md` registry and User_Manual entry

#### 2d. Rules & Standards
**Location**: `rules/`  
**Files**: 26 governance, standards, and enforcement rules  
**Relationship to User_Manual**: `Agents_Skills_Rules.md` lists key rules; full text lives here  
**Sub-categories**:
- ask-first-protocol.md (enforcement)
- rpi-workflow.md (process)
- gate-enforcement.md (validation)
- token-optimization.md (budgets)
- pre-merge-test-enforcement.md (quality)
- qa-guardrails.md (testing standards)
- compliance-standards.md (legal/security)
- commit-conventions.md (git)
- And 18 others...

**Auto-Update Rule**:
- If rule changes → check if User_Manual is impacted
- If rule affects commands/agents/flows → trigger User_Manual update

#### 2e. Pipeline Stages
**Location**: `stages/`  
**Files**: 15 stage definitions (01-15) + routing + variants  
**Relationship to User_Manual**: `SDLC_Flows.md` describes the pipeline; stage details live here

**Auto-Update Rule**:
- If stage added/removed → update `SDLC_Flows.md`
- If stage workflow changes → update the stage's gate sequence

#### 2f. Templates
**Location**: `templates/`  
**Files**: 17 reusable templates (PRD, ADR, API docs, stories, tech tasks)  
**Relationship to User_Manual**: Referenced in `Getting_Started.md` and FAQ

#### 2g. Tech Stack Conventions
**Location**: `stacks/`  
**Files**: 6 folders (Java, Android, iOS, React Native, JMeter, Figma)  
**Relationship to User_Manual**: Mentioned in `Architecture.md`

#### 2h. System Runtime State
**Location**: `.sdlc/`  
**Files**: Module contracts, memory structure, gate logs  
**Relationship to User_Manual**: Described in `Architecture.md` and `Documentation_Rules.md`

---

### Layer 3: ARCHIVE (Deprecated/Superseded)
**Location**: `/Old_Doc/` (future)  
**Status**: To be created if needed  
**Principle**: Never delete, just archive if superseded

---

## Auto-Update Validation System

**Goal**: Prevent documentation drift when code changes

### 3.1 Pre-Commit Hook (Enforcement)

**File**: `hooks/doc-change-check.sh`

Runs on every commit:

```bash
# RULE 1: If agent added/removed
if [ "$(git diff --name-only agents/)" != "" ]; then
    # Force regeneration of agents/CAPABILITY_MATRIX.md
    # Verify User_Manual/Agents_Skills_Rules.md updated
fi

# RULE 2: If skill added/removed
if [ "$(git diff --name-only skills/)" != "" ]; then
    # Force regeneration of skills/SKILL.md
fi

# RULE 3: If command changed
if [ "$(git diff --name-only .claude/commands/)" != "" ]; then
    # Force update of .claude/commands/COMMANDS_REGISTRY.md
fi

# RULE 4: If rule changed
if [ "$(git diff --name-only rules/)" != "" ]; then
    # Check if User_Manual/Agents_Skills_Rules.md needs update
fi

# RULE 5: If stage changed
if [ "$(git diff --name-only stages/)" != "" ]; then
    # Force update of User_Manual/SDLC_Flows.md
fi
```

**Enforcement**: ❌ BLOCK COMMIT if documentation not updated

### 3.2 Documentation Coverage Validation

Before merge, verify:
1. ✓ Is User_Manual/System_Overview.md accurate?
2. ✓ Are agent/skill/rule counts current?
3. ✓ Are stage workflows documented?
4. ✓ Are new commands in Commands.md?
5. ✓ Are new roles in Architecture.md?
6. ✓ No duplication between layers?

---

## Duplication Audit & Resolution

### Current Status: ZERO INTENTIONAL DUPLICATION

**Mirror Files (INTENTIONAL)**:
- `ask-first-protocol.md` exists in BOTH `rules/` and `.claude/rules/` (IDE vs CLI separation) ✓ Acceptable
- `gate-enforcement.md` exists in BOTH `rules/` and `.claude/rules/` ✓ Acceptable

**No Problematic Duplication Found**:
- System_Overview.md is NOT duplicated elsewhere
- Commands.md is NOT duplicated elsewhere
- SDLC_Flows.md is NOT duplicated elsewhere

**Conclusion**: Current documentation already follows atomic principle (each concept defined once)

---

## Documentation Maintenance Workflow

### When to update User_Manual:

1. **New Agent**: `agents/new-agent.md` created
   - Add 1-line entry to `Agents_Skills_Rules.md` inventory
   - Regenerate `agents/CAPABILITY_MATRIX.md`

2. **New Skill**: `skills/new-skill.md` created
   - Add 1-line entry to `Agents_Skills_Rules.md` inventory
   - Regenerate `skills/SKILL.md` registry

3. **New Command**: `.claude/commands/new-command.md` created
   - Add command to `Commands.md` reference section
   - Regenerate `COMMANDS_REGISTRY.md`

4. **New Rule**: `rules/new-rule.md` created
   - Check if affects User_Manual (ask-first rules, gates, standards)
   - If yes: update relevant User_Manual file
   - Regenerate `rules/RULES_REGISTRY.md` if it exists

5. **New Stage**: `stages/16-new-stage/STAGE.md` created
   - Update `SDLC_Flows.md` with new stage + gates
   - Update `stages/ROUTING.md` if classification affects routing

6. **New Role**: `roles/new-role.md` created
   - Add to `Architecture.md` roles section

---

## Documentation Entry Points (By User Type)

| User Type | Start | Next | Deep Dive |
|-----------|-------|------|-----------|
| **New User** | README → System_Overview | Getting_Started | Architecture + Commands |
| **Developer** | System_Overview → Architecture | Commands | Agents_Skills_Rules → Implementation docs |
| **PM** | System_Overview → SDLC_Flows | FAQ | ADO_MCP_Integration |
| **TPM** | Getting_Started → Commands | SDLC_Flows | Agents_Skills_Rules + rules/ |
| **QA** | Getting_Started | PR_Merge_Process | ADO_MCP_Integration |
| **DevOps** | Architecture → ADO_MCP_Integration | Commands | .sdlc/ structure |
| **Maintainer** | Documentation_Rules | All layers | Implementation docs |

---

## Governance Rules

### 1. Single Source of Truth Principle
- User_Manual = Public API
- Everything else = Implementation details
- NO DUPLICATION across layers

### 2. Atomic Documentation
- Each concept defined ONCE
- All other references point to original
- No copy-paste documentation

### 3. Auto-Update Enforcement
- Commits that change agents/skills/rules/commands MUST update docs
- Pre-commit hook validates
-❌ BLOCKS merge if not updated

### 4. Token Efficiency
- User_Manual: ~100 lines per document
- Tables over prose
- "Ask for details" instead of over-explaining
- Typical read time: 2-3 minutes per file

### 5. Versioning
- User_Manual changes = documentation patch (doc changes only)
- Implementation changes (agents/skills/rules) = code change

---

## File Structure Visualization

```
/User_Manual/                     ← PUBLIC API (Single Source of Truth)
  ├── README.md
  ├── System_Overview.md
  ├── Getting_Started.md
  ├── Architecture.md
  ├── Commands.md
  ├── SDLC_Flows.md
  ├── Agents_Skills_Rules.md
  ├── PR_Merge_Process.md
  ├── ADO_MCP_Integration.md
  ├── Documentation_Rules.md
  └── FAQ.md

/.claude/                         ← IDE Implementation
  ├── rules/
  ├── commands/
  └── (system metadata)

/rules/                           ← Governance & Standards
  ├── ask-first-protocol.md
  ├── gate-enforcement.md
  ├── rpi-workflow.md
  ├── token-optimization.md
  └── (23 more governance docs)

/agents/                          ← AI Agent Implementations
  ├── CAPABILITY_MATRIX.md
  ├── backend/
  ├── frontend/
  ├── qa/
  ├── performance/
  └── shared/

/skills/                          ← Skill Implementations
  ├── SKILL.md (registry)
  ├── rpi-research/plan/impl/verify/
  ├── qa-orchestrator/
  └── role-based/

/stages/                          ← Pipeline Definitions
  ├── ROUTING.md (smart routing)
  ├── VARIANT_TEMPLATE.md
  └── 01-15/ (15 stage definitions)

/templates/                       ← Document Templates
  └── PRD, ADR, API docs, stories, tech tasks, etc.

/stacks/                          ← Tech Stack Conventions
  └── Java, Android, iOS, React Native, JMeter, Figma

/.sdlc/                           ← Runtime State
  ├── module-contracts/
  └── memory/

/Old_Doc/                         ← Archive (if needed in future)
  └── (superseded documentation)
```

---

## Next Steps

1. ✅ Audit complete: 277 docs across 10 layers
2. ✅ User_Manual verified: PRODUCTION-READY
3. ✅ Duplication audit: ZERO ISSUES
4. 🔄 TODO: Implement pre-commit hook `doc-change-check.sh`
5. 🔄 TODO: Auto-update registries (CAPABILITY_MATRIX, COMMANDS_REGISTRY, etc.)
6. 🔄 TODO: Establish documentation review checklist for PRs

---

## Questions for Clarification

1. Should pre-commit hook BLOCK commits or just WARN?
2. Do we want auto-generation of registries, or manual updates?
3. Should Old_Doc folder be created now or only if needed?

---

**Document Status**: GOVERNANCE FRAMEWORK  
**Applies To**: All 277 documentation files  
**Enforced By**: Pre-commit hooks + code review checklist
