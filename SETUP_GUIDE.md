# AI-SDLC Platform: Complete Setup Guide

## Quick Start (5 Minutes)

### After Cloning the Repository

```bash
# 1. Enter the repository
cd ai-sdlc-platform

# 2. Run setup (installs everything: SDLC, IDE, documentation automation)
./setup.sh

# 3. (Optional) Verify documentation automation
./setup-documentation.sh --verify

# Done! All systems ready.

# 4. Verify hooks + health (required after clone)
sdlc doctor
```

### Multi-repo workspaces (10+ microservices under one parent)

If you're a module owner with many repos under a parent folder
(e.g. `example-app/{TejAuthService,tejpublicservices,tejsecurity}`), use
**workspace init** instead of running `sdlc setup` once per repo:

```bash
cd /path/to/parent-folder            # e.g., example-app/
sdlc workspace init --dry-run        # preview what will be set up
sdlc workspace init                  # set up every child repo once

# Daily:
sdlc workspace status                # per-repo state
sdlc workspace sync                  # re-run after platform upgrades
```

What it does:
- Caches ADO PAT + org + project **once** in `~/.sdlc/ado.env` — no re-prompting
- Writes a `.sdlc-workspace.json` manifest at the parent
- Runs `sdlc setup --from-env` in each child, which means only the strictly
  per-repo pieces (`.sdlc/` scaffolding, git hooks, `module init`, `.env` merge)
  actually execute per repo. IDE plugin / doc libs / creds are done once.

### Unified memory (one command, auto-routed)

Three physical memory layers stay, but you use one command:

```bash
sdlc remember "POST /v1/photos requires X-Tenant-Id header"
# → auto-routes to .sdlc/module/contracts/api.yaml

sdlc remember "Decided: Redis for session store" --kind=decision
# → auto-routes to semantic memory (SQLite + team JSONL)

sdlc remember "tejsecurity depends on TejAuthService /token" --to=shared --kind=deps
# → .sdlc/memory/shared/cross-team-dependencies.md

sdlc recall "photo upload limits"
# → federated read across all 3 layers
```

See `sdlc memory doctor --fix` to remove the deprecated empty
`.sdlc/module-kb/` folder on repos that were set up with earlier versions.

Setup **auto-installs** git hooks and retries if needed; it does **not** exit on hook issues. Run `sdlc doctor` to confirm.

---

## What Gets Installed

The single `./setup.sh` command installs everything in one step:

### Phase 1: Main SDLC Setup

- SDLC environment (.sdlc/ directory)
- IDE plugins and configuration
- MCP servers (Azure DevOps, Wiki.js, Elasticsearch)
- Environment variables and credentials
- CLI tools and commands

**Output**: "All slash commands work, MCP tools available"

### Phase 2: Documentation Automation (Integrated)

Automatically installed as part of `./setup.sh`:
- Registry auto-generation (hooks + scripts)
- Documentation validation (pre-commit)
- Semantic versioning system
- Git hooks for automation

**Output**: "Documentation automation is active and ready"

**Note**: Previously `setup-documentation.sh` was a separate step. It's now integrated into `setup.sh` and runs automatically. You can still run it manually if needed.

---

## Detailed Setup Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/example-org/ai-sdlc-platform.git
cd ai-sdlc-platform
```

### Step 2: Run Setup (One Command)

```bash
./setup.sh
```

**What it does**:
1. **Main SDLC Setup**
   - Validates git installation
   - Creates .sdlc/ directory structure
   - Installs IDE plugins
   - Configures MCP servers
   - Sets up environment variables
   - Tests ADO connection (if credentials provided)

2. **Documentation Automation Setup** (automatic)
   - Makes scripts executable (regenerate-registries.sh, bump-version.sh)
   - Configures git hooks (core.hooksPath = hooks)
   - Verifies installation
   - Tests all automation systems

**Success message**:
```
╔════════════════════════════════════════╗
║  ✓ AI-SDLC Platform Ready              ║
║  → All systems configured              ║
║  → Documentation automation installed  ║
║  → Try: /project:prd-review            ║
╚════════════════════════════════════════╝
```

### Step 3: Optional Verification

```bash
# Verify documentation automation is working
./setup-documentation.sh --verify

# Output: All verifications passed!
```

---

## Automated Setup Hooks

After running `setup-documentation.sh`, these hooks are active:

### Pre-Commit Hook (doc-change-check.sh)

Runs before every commit to validate documentation:

```
git commit
  ↓
Pre-Commit Hook: Are agents/skills/rules/commands changed?
  ↓
  YES → User_Manual must be updated
  ✓ If updated: Commit allowed
  ✗ If not: Commit blocked
```

**Example**:
```bash
# Add new agent
git add agents/backend/new-agent.md

# Try to commit without updating User_Manual
git commit -m "feat: Add new agent"

# Output:
# [Doc-Change-Check] Agents directory changed:
#   ✗ User_Manual/Agents_Skills_Rules.md NOT updated
#   ✗ agents/CAPABILITY_MATRIX.md NOT updated
# 
# COMMIT BLOCKED
# 
# To proceed: Update User_Manual and CAPABILITY_MATRIX.md

# Fix it
vim User_Manual/Agents_Skills_Rules.md  # Update agent count
git add User_Manual/Agents_Skills_Rules.md

# Commit again (now passes)
git commit -m "feat: Add new agent"
# ✓ ALLOWED
```

### Post-Commit Hook (post-commit-registry-update.sh)

Runs after every commit to auto-update registries:

```
git commit → SUCCESS
  ↓
Post-Commit Hook: Did agents/skills/commands change?
  ↓
  YES → Regenerate affected registries
       → Stage updates automatically
       → Prompt user to amend commit
  ↓
User Action: git commit --amend --no-edit
  ↓
Final Commit: Code + Manual Updates + Auto-Generated Registries
```

**Example**:
```bash
# Create new agent
cat > agents/backend/validator.md << EOF
# Validator Agent
...
EOF

# Commit
git add agents/backend/validator.md
git commit -m "feat(agents): Add validator agent"

# What happens automatically:
# Post-commit: Detects agents/ changed
# Post-commit: Regenerates agents/CAPABILITY_MATRIX.md
# Post-commit: Stages the updated registry
# Output:
#   Registry files staged. Amend your commit:
#   git commit --amend --no-edit

# Follow the prompt
git commit --amend --no-edit

# Result: Commit now includes:
# - agents/backend/validator.md (code)
# - agents/CAPABILITY_MATRIX.md (registry, auto-generated)
```

---

## On-Demand Scripts

After setup, these scripts are available for manual use:

### 1. Registry Regeneration

```bash
# Check if registries are current
./scripts/regenerate-registries.sh --check

# Regenerate all registries
./scripts/regenerate-registries.sh --update

# Preview changes without modifying
./scripts/regenerate-registries.sh --dry-run
```

### 2. Version Bumping

```bash
# Show current version
./scripts/bump-version.sh --show
# Output: Current Version: 1.0.0

# Bump MAJOR (breaking changes: stages renamed, commands removed)
./scripts/bump-version.sh --major
# 1.0.0 → 2.0.0

# Bump MINOR (new features: agents, skills, commands)
./scripts/bump-version.sh --minor
# 1.0.0 → 1.1.0

# Bump PATCH (bug fixes, clarifications)
./scripts/bump-version.sh --patch
# 1.0.0 → 1.0.1
```

---

## Troubleshooting

### Q: Hooks not running after commit

**A**: Check installation:
```bash
# Verify hooks are installed
git config core.hooksPath
# Should output: hooks

# If not set, run setup again
./setup-documentation.sh
```

### Q: Pre-commit hook blocking my commit

**A**: Update the affected documentation:

If you changed agents:
```bash
# Update agent count in User_Manual
vim User_Manual/Agents_Skills_Rules.md

# Stage the update
git add User_Manual/Agents_Skills_Rules.md

# Commit again
git commit -m "feat(agents): Add new agent"
```

### Q: Registries not updating after commit

**A**: Manually regenerate:
```bash
# Regenerate all registries
./scripts/regenerate-registries.sh --update

# Stage them
git add agents/CAPABILITY_MATRIX.md skills/SKILL.md .claude/commands/COMMANDS_REGISTRY.md

# Amend commit
git commit --amend --no-edit
```

### Q: How do I skip pre-commit validation?

**A**: Use `--no-verify` (not recommended):
```bash
git commit --no-verify -m "Emergency hotfix"
```

---

## Setup Verification Checklist

After running setup, verify:

- [ ] `./setup.sh` completed successfully
- [ ] `./setup-documentation.sh` completed successfully
- [ ] `./setup-documentation.sh --verify` shows "All verifications passed"
- [ ] Git hooks are installed: `git config core.hooksPath` shows "hooks"
- [ ] Scripts are executable: `ls -la scripts/bump-version.sh` shows `x`
- [ ] Version system works: `./scripts/bump-version.sh --show` shows version
- [ ] Registry system works: `./scripts/regenerate-registries.sh --check` runs without error

**All checks passing?** ✓ You're ready to develop!

---

## First Commit (Test Automation)

To verify everything is working, make a test commit:

```bash
# Create an empty test commit
git commit --allow-empty -m "test: verify hooks work"

# What you should see:
# [Pre-Commit] Validating documentation updates...
# [Pre-Commit] No system files changed, allowing commit
# 
# [Post-Commit Registry Update] Checking registries...
# → No agents/skills/commands changed
# → No registry regeneration needed
#
# ✓ Test commit successful!
```

---

## Integration with CI/CD

If you're setting up CI/CD, add registry validation:

```bash
# Add to your CI/CD pipeline
./scripts/regenerate-registries.sh --check

# Exit code:
# 0 = All registries current (pass)
# 1 = Registries out of date (fail)
```

---

## Uninstalling Automation

If you need to remove hooks:

```bash
# Remove all hooks and unset git config
./setup-documentation.sh --uninstall

# To reinstall
./setup-documentation.sh
```

---

## Complete Workflow Example

**Scenario**: Adding 3 new agents and releasing v1.1.0

```bash
# 1. Create agents
mkdir agents/shared/{new-agent-1,new-agent-2,new-agent-3}
cat > agents/shared/new-agent-1/SKILL.md << EOF
# New Agent 1
EOF
# ... repeat for agents 2 and 3

# 2. Update User_Manual (BEFORE commit)
vim User_Manual/Agents_Skills_Rules.md
# Change: "52 agents" → "55 agents"

# 3. Commit
git add agents/
git add User_Manual/Agents_Skills_Rules.md
git commit -m "feat(agents): Add 3 new agents"

# What happens:
# Pre-commit: User_Manual/Agents_Skills_Rules.md updated? YES ✓
# Commit: ALLOWED
# Post-commit: Regenerates agents/CAPABILITY_MATRIX.md
# Post-commit: Stages updated registry
# Output: git commit --amend --no-edit

# 4. Amend to include registry
git commit --amend --no-edit

# 5. Bump version
./scripts/bump-version.sh --minor
# 1.0.0 → 1.1.0

# 6. Release
git add User_Manual/VERSION User_Manual/CHANGELOG.md
git commit -m "docs(user-manual): Release v1.1.0"
git tag -a v1.1.0 -m "User Manual v1.1.0"
git push && git push --tags

# Done! Released with all automation active.
```

---

## Key Concepts

**Pre-Commit Hook**: Validates code-to-docs synchronization
- Runs BEFORE commit is created
- Can BLOCK commit if validation fails
- Purpose: Ensure documentation stays in sync

**Post-Commit Hook**: Auto-generates registries
- Runs AFTER successful commit
- Non-blocking (doesn't prevent commits)
- Auto-stages updates for user to amend

**Registry Auto-Generation**: Keeps master registries current
- Detects when agents/skills/commands change
- Regenerates related registry files
- Timestamps and counts all entities

**Semantic Versioning**: Tracks User_Manual releases
- MAJOR: Breaking changes (stages renamed, commands removed)
- MINOR: New features (agents, skills, commands)
- PATCH: Bug fixes, clarifications

---

## Documentation

After setup, read these files for more details:

- **DOCUMENTATION_ARCHITECTURE.md** — Master governance framework
- **REGISTRY_VERSIONING_GUIDE.md** — Detailed automation guide
- **User_Manual/** — Complete user documentation (11 files)

---

**Setup Complete!** You're ready to develop with full documentation automation. 🚀

