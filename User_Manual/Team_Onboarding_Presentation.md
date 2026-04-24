# AI-SDLC Platform - Team Onboarding Presentation

**Complete Guide for Teams | 15-Stage SDLC Flow | Memory & Git Workflows**

---

## Table of Contents

1. [Platform Overview](#1-platform-overview)
2. [Quick Start - First Time Setup](#2-quick-start---first-time-setup)
3. [15-Stage SDLC Flow](#3-15-stage-sdlc-flow)
   - Stages 01-05: Planning & Design
   - Stages 06-10: Implementation & Testing
   - Stages 11-15: Release & Closure
4. [Memory Management](#4-memory-management)
5. [Git Workflow Integration](#5-git-workflow-integration)
6. [Multi-Repo Workflow](#6-multi-repo-workflow)
7. [Common Scenarios](#7-common-scenarios)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Platform Overview

### What is AI-SDLC Platform?

An AI-native software development lifecycle platform that:
- **Guides** you through 15 standardized stages
- **Creates memory** for context preservation
- **Integrates** with Azure DevOps, Git, IDE
- **Supports** multiple repos, multiple teams

### Key Components

```
┌─────────────────────────────────────────────────────────┐
│  AI-SDLC Platform v2.1.0                                │
├─────────────────────────────────────────────────────────┤
│  • 15 Stages  → From requirements to release           │
│  • 8 Roles    → Product, Backend, Frontend, QA, etc.   │
│  • 3 Skills   → Atomic, Composed, Monolithic            │
│  • 2 Modes    → Chat (IDE) + CLI (Terminal)           │
│  • Memory     → Git-based + Semantic                  │
│  • Multi-Repo → Track dependencies across repos       │
└─────────────────────────────────────────────────────────┘
```

### Who Uses It?

| Role | Primary Stages | Key Commands |
|------|----------------|--------------|
| **Product** | 01, 02, 03, 04 | PRD creation, grooming |
| **Backend** | 05, 08, 09 | System design, implementation |
| **Frontend** | 05, 08, 09 | UI design, implementation |
| **QA** | 10, 11 | Test design, execution |
| **Performance** | 09, 10, 11 | Load testing, profiling |
| **TPM** | 01-15 | Cross-stage coordination |

---

## 2. Quick Start - First Time Setup

### Step 1: Platform Setup (One-time)

```bash
# Clone platform
git clone https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git
cd AI-sdlc-platform

# Setup platform (auto-detects your repos)
./setup.sh
```

**What setup.sh does automatically:**
1. ✅ Checks prerequisites (bash, node, python)
2. ✅ Creates `.sdlc/` directory structure
3. ✅ Creates IDE links (`.claude/`, `.cursor/`)
4. ✅ Installs IDE plugin
5. ✅ Sets up MCP servers
6. ✅ Creates `env/.env` template
7. ✅ **Auto-detects your repos** in `~/projects`, `~/workspace`
8. ✅ Adds `sdlc` command to PATH

### Step 2: Configure Azure DevOps

```bash
# Create ADO credentials file
mkdir -p ~/.sdlc
cat > ~/.sdlc/ado.env << 'EOF'
ADO_ORG=your-ado-org
ADO_PROJECT=YourAzureProject
ADO_PAT=your-personal-access-token
EOF
```

**Get PAT:** https://dev.azure.com/your-ado-org/_usersSettings/tokens

### Step 3: Verify Setup

```bash
# Check everything is working
sdlc doctor

# Show your context
sdlc context

# List detected repos
sdlc repos list
```

### Step 4: Choose Your Role

```bash
# Set your role
sdlc use backend --stack=java
sdlc use frontend --stack=react
sdlc use qa
sdlc use product
```

---

## 3. 15-Stage SDLC Flow

### Stage Overview

| Stage | Name | Purpose | Output | Memory? |
|-------|------|---------|--------|---------|
| 01 | Requirement Intake | Capture requirements | PRD draft | Yes |
| 02 | PRD Review | Review requirements | Approved PRD | Yes |
| 03 | Pre-Grooming | Preliminary estimation | Estimates | No |
| 04 | Grooming | Detailed planning | Groomed stories | Yes |
| 05 | System Design | Technical design | Design doc | Yes |
| 06 | Design Review | Review design | Approved design | No |
| 07 | Task Breakdown | Create sub-tasks | Tasks in ADO | Yes |
| 08 | Implementation | Code development | Code + tests | **Yes** |
| 09 | Code Review | Review code | Approved PR | Yes |
| 10 | Test Design | Design test cases | Test plan | Yes |
| 11 | Test Execution | Run tests | Test results | Yes |
| 12 | Commit/Push | Git operations | Commits | No |
| 13 | Documentation | Update docs | Updated docs | Yes |
| 14 | Release Signoff | Release approval | Signoff | Yes |
| 15 | Summary/Close | Close story | Closed story | No |

---

### Phase 1: Planning & Design (Stages 01-05)

#### Stage 01: Requirement Intake

**Purpose:** Capture and document requirements

**When to Run:**
- New feature request from product
- Customer requirement
- Bug report that needs scoping

**How to Run:**

```bash
# Option 1: CLI
sdlc run 01-requirement-intake --story=NEW

# Option 2: IDE Chat
"Create PRD for user authentication feature"
"Document requirements for AB#12345"
```

**What Happens:**
1. Creates `UserStory_YYYY-MM-DD-username.md` in `.sdlc/stories/`
2. AI helps structure the PRD
3. Saves to semantic memory

**Memory Created:** ✅ Yes
- Story file in `.sdlc/stories/`
- Semantic memory entry

**Output:**
```
.sdlc/stories/
└── UserStory_2026-04-17-john_doe.md
```

---

#### Stage 02: PRD Review

**Purpose:** Review and refine PRD

**When to Run:**
- PRD is ready for review
- Multiple stakeholders need to approve

**How to Run:**

```bash
# With specific story
sdlc run 02-prd-review --story=UserStory_2026-04-17-john_doe.md

# Or from ADO work item
sdlc run 02-prd-review --story=AB#12345
```

**What Happens:**
1. AI analyzes PRD for completeness
2. Checks for missing requirements
3. Suggests improvements
4. Updates story file with review notes

**Memory Created:** ✅ Yes
- Review notes appended to story
- Approval status tracked

---

#### Stage 03: Pre-Grooming

**Purpose:** Quick estimation and feasibility check

**When to Run:**
- Before formal grooming session
- Quick sizing needed

**How to Run:**

```bash
sdlc run 03-pre-grooming --story=AB#12345
```

**What Happens:**
1. AI estimates effort (T-shirt sizing)
2. Identifies risks
3. Suggests dependencies

**Memory Created:** ❌ No
- This is a transient stage

---

#### Stage 04: Grooming

**Purpose:** Detailed planning and story refinement

**When to Run:**
- Sprint planning
- Story refinement session

**How to Run:**

```bash
sdlc run 04-grooming --story=AB#12345
```

**What Happens:**
1. Breaks story into technical tasks
2. Creates acceptance criteria
3. Identifies technical dependencies
4. Pushes groomed story to ADO

**Memory Created:** ✅ Yes
- Groomed story file
- Task breakdown in memory

---

#### Stage 05: System Design

**Purpose:** Technical design document

**When to Run:**
- Before implementation
- Complex features requiring design

**How to Run:**

```bash
# Backend design
sdlc use backend --stack=java
sdlc run 05-system-design --story=AB#12345

# Frontend design  
sdlc use frontend --stack=react
sdlc run 05-system-design --story=AB#12345
```

**What Happens:**
1. Creates design document
2. Includes API contracts (if backend)
3. Includes UI mockups (if frontend)
4. Identifies integration points

**Memory Created:** ✅ Yes
- Design document in `.sdlc/module/designs/`
- API contracts (if applicable)
- UI specifications (if applicable)

**Output:**
```
.sdlc/module/
├── designs/
│   └── auth-service-design.md
├── contracts/
│   ├── api.yaml
│   └── data.yaml
```

---

### Phase 2: Implementation & Testing (Stages 06-11)

#### Stage 06: Design Review

**Purpose:** Review and approve design

**When to Run:**
- Design is complete
- Architecture review needed

**How to Run:**

```bash
sdlc run 06-design-review --story=AB#12345
```

**What Happens:**
1. AI reviews design for best practices
2. Checks security considerations
3. Validates scalability
4. Gets human approval (gate)

**Memory Created:** ❌ No
- Approval tracked in ADO

---

#### Stage 07: Task Breakdown

**Purpose:** Create implementation tasks

**When to Run:**
- After design approval
- Before coding starts

**How to Run:**

```bash
sdlc run 07-task-breakdown --story=AB#12345
```

**What Happens:**
1. Creates sub-tasks in ADO
2. Links tasks to parent story
3. Estimates each task

**Memory Created:** ✅ Yes
- Task mapping in memory
- ADO work item IDs stored

---

#### Stage 08: Implementation (RPI Workflow)

**Purpose:** Write the code

**When to Run:**
- Development phase
- Actually coding the feature

**How to Run:**

```bash
# Start implementation
sdlc run 08-implementation --story=AB#12345

# Or natural language in IDE
"Implement AB#12345 - user authentication"
```

**What Happens:**
1. **RPI Workflow executes:**
   - **R**esearch: Analyze codebase, ADO story
   - **P**lan: Create implementation plan
   - **I**mplement: Generate code
2. AI proposes changes
3. Human approves each gate
4. Code written to files

**Memory Created:** ✅✅✅ **CRITICAL**
- Implementation memory in `.sdlc/memory/`
- Branch context preserved
- Code decisions tracked

**Git Branch:**
```bash
# Auto-created branch
feature/AB-12345-user-authentication
```

**Memory Files:**
```
.sdlc/memory/
├── branches/
│   └── feature-AB-12345/
│       ├── context.json      # Branch context
│       ├── decisions.json    # Key decisions
│       └── state.json        # Current state
```

---

#### Stage 09: Code Review

**Purpose:** Review implementation

**When to Run:**
- Code is ready for review
- Before merging

**How to Run:**

```bash
# Create PR and review
sdlc run 09-code-review --story=AB#12345

# Or manual PR review
sdlc ado show AB#12345
```

**What Happens:**
1. AI reviews code for:
   - Best practices
   - Security issues
   - Performance
   - Test coverage
2. Creates review notes
3. Updates ADO with review status

**Memory Created:** ✅ Yes
- Review comments
- Approval status

---

#### Stage 10: Test Design

**Purpose:** Design test cases

**When to Run:**
- After implementation
- Before test execution

**How to Run:**

```bash
# QA team runs this
sdlc use qa
sdlc run 10-test-design --story=AB#12345
```

**What Happens:**
1. Creates test plan
2. Designs test cases:
   - Unit tests
   - Integration tests
   - E2E tests
3. Identifies test data needs

**Memory Created:** ✅ Yes
- Test plan in `.sdlc/memory/`
- Test cases documented

**Output:**
```
.sdlc/memory/
└── test-plans/
    └── AB-12345-test-plan.md
```

---

#### Stage 11: Test Execution

**Purpose:** Run tests and validate

**When to Run:**
- Tests are designed
- QA validation needed

**How to Run:**

```bash
sdlc use qa
sdlc run 11-test-execution --story=AB#12345
```

**What Happens:**
1. Runs automated tests
2. Reports results
3. Creates bugs for failures
4. Updates ADO status

**Memory Created:** ✅ Yes
- Test results
- Bug links
- Coverage reports

---

### Phase 3: Release & Closure (Stages 12-15)

#### Stage 12: Commit/Push

**Purpose:** Git operations

**When to Run:**
- Code is ready
- Tests pass

**How to Run:**

```bash
# Standard git workflow
git add .
git commit -m "feat: AB#12345 user authentication"
git push origin feature/AB-12345
```

**What Happens:**
- Code pushed to remote
- Memory synced to git

**Memory Created:** ❌ No
- Git handles versioning

---

#### Stage 13: Documentation

**Purpose:** Update documentation

**When to Run:**
- Before release
- After implementation complete

**How to Run:**

```bash
sdlc run 13-documentation --story=AB#12345
```

**What Happens:**
1. Updates API docs
2. Updates README
3. Updates User Manual
4. Syncs documentation

**Memory Created:** ✅ Yes
- Documentation updates
- Wiki sync (if configured)

---

#### Stage 14: Release Signoff

**Purpose:** Get release approval

**When to Run:**
- All tests pass
- Documentation updated

**How to Run:**

```bash
sdlc run 14-release-signoff --story=AB#12345
```

**What Happens:**
1. Validates all gates passed
2. Checks security scans
3. Gets stakeholder approval
4. Updates ADO to "Ready for Release"

**Memory Created:** ✅ Yes
- Signoff record
- Release notes

---

#### Stage 15: Summary/Close

**Purpose:** Close the story

**When to Run:**
- Feature is live
- Story complete

**How to Run:**

```bash
sdlc run 15-summary-close --story=AB#12345
```

**What Happens:**
1. Generates summary report
2. Updates ADO state to "Closed"
3. Archives memory
4. Cleanup temporary files

**Memory Created:** ❌ No
- Memory archived
- Story closed

---

## 4. Memory Management

### Types of Memory

| Type | Location | Purpose | Lifecycle |
|------|----------|---------|-----------|
| **Story Memory** | `.sdlc/stories/` | PRD, grooming docs | Permanent |
| **Branch Memory** | `.sdlc/memory/branches/` | Implementation context | Branch lifetime |
| **Semantic Memory** | SQLite + JSON | Searchable knowledge | Project lifetime |
| **Module Memory** | `.sdlc/module/` | Contracts, designs | Permanent |
| **Repo Memory** | `~/.sdlc/repos.json` | Multi-repo tracking | User lifetime |

### When is Memory Created?

#### ✅ Memory Created (11 Stages)

```
Stage 01: Story file created
Stage 02: Review notes added
Stage 04: Grooming artifacts
Stage 05: Design documents
Stage 07: Task mappings
Stage 08: Implementation context ⭐ CRITICAL
Stage 09: Review comments
Stage 10: Test plans
Stage 11: Test results
Stage 13: Documentation
Stage 14: Signoff records
```

#### ❌ No Memory (4 Stages)

```
Stage 03: Pre-grooming (transient)
Stage 06: Design review (approval in ADO)
Stage 12: Commit/push (git handles it)
Stage 15: Close (archive, not create)
```

### Memory Commands

```bash
# Initialize memory for a story
sdlc memory init AB#12345

# Show memory status
sdlc memory status

# List all branches with memory
sdlc memory list-branches

# Sync memory to git
sdlc sync

# Publish memory
sdlc publish

# Query semantic memory
sdlc memory semantic-query --text="authentication flow"

# Export team memory
sdlc memory semantic-export

# Import team memory
sdlc memory semantic-import
```

### Memory Best Practices

1. **Always initialize memory before Stage 08**
   ```bash
   sdlc memory init AB#12345
   ```

2. **Sync memory regularly**
   ```bash
   # In pre-commit hook
   sdlc sync
   ```

3. **Export before major changes**
   ```bash
   sdlc memory semantic-export
   ```

4. **Clean up old branches**
   ```bash
   # After merging
   sdlc memory list-branches
   # Archive old ones
   ```

---

## 5. Git Workflow Integration

### Branch Naming Convention

```
feature/AB-12345-short-description
bugfix/AB-12346-fix-login-issue
hotfix/PROD-789-critical-fix
```

### Standard Git Workflow

```bash
# 1. Start work (Stage 07 or 08)
sdlc run 07-task-breakdown --story=AB#12345

# 2. Create branch
git checkout -b feature/AB-12345-user-auth

# 3. Initialize memory
sdlc memory init AB#12345

# 4. Implement (Stage 08)
sdlc run 08-implementation --story=AB#12345

# 5. Review (Stage 09)
sdlc run 09-code-review --story=AB#12345

# 6. Commit
git add .
git commit -m "feat: AB#12345 user authentication

- Add login endpoint
- Add JWT token validation
- Add password hashing"

# 7. Push
git push origin feature/AB-12345-user-auth

# 8. Create PR (manual or via ADO)
# PR should link to AB#12345

# 9. After merge, cleanup
git checkout main
git pull origin main
git branch -d feature/AB-12345-user-auth
```

### Git Hooks (Auto-installed)

```
pre-commit:
  1. Run sdlc-auto-sync
  2. Update registries
  3. Validate documentation
```

### Memory + Git Sync

```bash
# Memory is stored in .sdlc/memory/
# Git tracks these files

# Check what's tracked
git ls-files | grep .sdlc

# Example output:
# .sdlc/module/meta.json
# .sdlc/stories/UserStory_2026-04-17.md
# .sdlc/memory/branches/feature-AB-12345/context.json

# Commit memory with code
git add .sdlc/
git commit -m "chore: sync memory for AB#12345"
```

---

## 6. Multi-Repo Workflow

### Scenario: Cross-Repo Dependencies

You have:
- `TejAuthService` (depends on TejSecurityServices)
- `TejSecurityServices` (shared library)
- `TejUserProfile` (depends on TejSecurityServices)

### Setup Multi-Repo

```bash
# Already done during ./setup.sh!
# But can manually add:
sdlc repos add ~/projects/TejAuthService
sdlc repos add ~/projects/TejSecurityServices

# Set dependencies
sdlc repos depend tej-auth-service tej-security
sdlc repos depend tej-user-profile tej-security
```

### Check Impact Before Changes

```bash
# Before modifying TejSecurityServices
cd ~/projects/TejSecurityServices
sdlc repos check tej-security

# Output:
# ⚠ Changes may affect: tej-auth-service, tej-user-profile
#   Paths:
#     tej-auth-service: ~/projects/TejAuthService
#     tej-user-profile: ~/projects/TejUserProfile
```

### Notify Dependent Teams

```bash
# After committing changes to tej-security
sdlc repos notify tej-security

# Creates notification in dependent repos:
# ~/projects/TejAuthService/.sdlc/notifications/dep-update-1234567890.json
```

### Switch Between Repos

```bash
# List all repos
sdlc repos list

# Output:
# → tej-auth-service (java)
#    Path: ~/projects/TejAuthService
#    Deps: tej-security
# 
#   tej-security (java)
#    Path: ~/projects/TejSecurityServices
#    Used by: tej-auth-service, tej-user-profile

# Switch context
sdlc repos switch tej-security
cd ~/projects/TejSecurityServices
```

---

## 7. Common Scenarios

### Scenario 1: Starting a New Feature

```bash
# 1. Product creates PRD
sdlc use product
sdlc run 01-requirement-intake --story=NEW

# 2. Review PRD
sdlc run 02-prd-review --story=UserStory_2026-04-17.md

# 3. Push to ADO
sdlc ado push-story UserStory_2026-04-17.md --type=feature
# → Creates AB#12345

# 4. Groom
sdlc run 04-grooming --story=AB#12345

# 5. Design
sdlc use backend
sdlc run 05-system-design --story=AB#12345

# 6. Implement
git checkout -b feature/AB-12345
sdlc memory init AB#12345
sdlc run 08-implementation --story=AB#12345

# 7. Test & Release
sdlc use qa
sdlc run 10-test-design --story=AB#12345
sdlc run 11-test-execution --story=AB#12345
sdlc run 14-release-signoff --story=AB#12345
```

### Scenario 2: Bug Fix

```bash
# 1. Get bug details
sdlc ado show AB#99999

# 2. Create branch
git checkout -b bugfix/AB-99999-login-error

# 3. Fix (skip to Stage 08)
sdlc use backend
sdlc run 08-implementation --story=AB#99999

# 4. Test
sdlc run 11-test-execution --story=AB#99999

# 5. Commit & PR
git commit -m "fix: AB#99999 resolve login error"
git push origin bugfix/AB-99999-login-error
```

### Scenario 3: Working Across Multiple Repos

```bash
# Current repo: TejSecurityServices
pwd
# ~/projects/TejSecurityServices

# Check who depends on this
sdlc repos check tej-security
# Shows: tej-auth-service, tej-user-profile

# Make changes...
# ... coding ...

# Commit
git commit -m "feat: add new encryption method"
git push

# Notify dependents
sdlc repos notify tej-security

# Switch to dependent repo
sdlc repos switch tej-auth-service
cd ~/projects/TejAuthService

# Check notification
cat .sdlc/notifications/*.json

# Run tests to verify compatibility
sdlc run 11-test-execution
```

### Scenario 4: QA Team End-to-End Testing

```bash
# QA has access to all stages
sdlc use qa

# Can run any stage
sdlc run 10-test-design --story=AB#12345
sdlc run 11-test-execution --story=AB#12345

# Check dependencies
sdlc repos deps

# Notify dev team of issues
sdlc ado update AB#12345 --state=Resolved
# Add comment with test results
```

---

## 8. Troubleshooting

### Issue: "sdlc: command not found"

```bash
# Add to PATH
export PATH="$PATH:/path/to/AI-sdlc-platform/cli"

# Or use full path
/path/to/AI-sdlc-platform/cli/sdlc.sh
```

### Issue: "ADO_PAT not configured"

```bash
# Create credentials file
mkdir -p ~/.sdlc
echo "ADO_PAT=your-token" > ~/.sdlc/ado.env

# Test connection
sdlc ado list
```

### Issue: "No repos found"

```bash
# Manually detect
sdlc repos detect

# Or manually add
sdlc repos add ~/path/to/your/repo
```

### Issue: "Memory not initialized"

```bash
# Initialize before Stage 08
sdlc memory init AB#12345

# Verify
ls -la .sdlc/memory/branches/
```

### Issue: "Stage command not found"

```bash
# Check available stages
sdlc help | grep "run"

# Run with explicit path
bash /path/to/AI-sdlc-platform/cli/sdlc.sh run 08-implementation
```

---

## Quick Reference Card

### Essential Commands

```bash
# Setup
./setup.sh
sdlc doctor

# Context
sdlc use <role> [--stack=<stack>]
sdlc context

# Repositories
sdlc repos list
sdlc repos switch <repo-id>
sdlc repos check <repo-id>

# Stages
sdlc run <stage> [--story=<id>]
sdlc run 01-requirement-intake
sdlc run 08-implementation
sdlc run 11-test-execution

# ADO
sdlc ado create story --title="..."
sdlc ado show <id>
sdlc ado push-story <file.md>

# Memory
sdlc memory init <story-id>
sdlc memory status
sdlc sync

# Help
sdlc help
sdlc doctor
```

### Stage Quick Reference

| Stage | Command | Memory? |
|-------|---------|---------|
| 01 | `sdlc run 01-requirement-intake` | ✅ |
| 02 | `sdlc run 02-prd-review` | ✅ |
| 03 | `sdlc run 03-pre-grooming` | ❌ |
| 04 | `sdlc run 04-grooming` | ✅ |
| 05 | `sdlc run 05-system-design` | ✅ |
| 06 | `sdlc run 06-design-review` | ❌ |
| 07 | `sdlc run 07-task-breakdown` | ✅ |
| 08 | `sdlc run 08-implementation` | ✅ |
| 09 | `sdlc run 09-code-review` | ✅ |
| 10 | `sdlc run 10-test-design` | ✅ |
| 11 | `sdlc run 11-test-execution` | ✅ |
| 12 | `git commit && git push` | ❌ |
| 13 | `sdlc run 13-documentation` | ✅ |
| 14 | `sdlc run 14-release-signoff` | ✅ |
| 15 | `sdlc run 15-summary-close` | ❌ |

---

## Conclusion

**You now know:**
1. ✅ How to set up the platform (auto-detects repos)
2. ✅ All 15 stages and when to use them
3. ✅ When memory is created (11 yes, 4 no)
4. ✅ Git workflow integration
5. ✅ Multi-repo dependency tracking
6. ✅ Common scenarios and troubleshooting

**Next Steps:**
1. Run `./setup.sh` if you haven't
2. Try `sdlc repos list` to see your repos
3. Pick a story and run `sdlc run 01-requirement-intake`

**Questions?**
- `sdlc help` - Full command list
- `sdlc doctor` - Diagnose issues
- User Manual: `User_Manual/manual.html`
