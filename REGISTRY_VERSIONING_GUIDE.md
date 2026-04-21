# Registry Auto-Generation & Semantic Versioning Guide

## Overview

Two automated systems have been implemented to maintain the documentation ecosystem:

1. **Registry Auto-Generation** — Keeps agent/skill/command registries synchronized with source code
2. **Semantic Versioning** — Tracks User_Manual changes following semantic versioning standards

---

## 1. Registry Auto-Generation System

### What It Does

Automatically regenerates master registries when source files change:
- **agents/CAPABILITY_MATRIX.md** — Updated when agents/ directory changes
- **skills/SKILL.md** — Updated when skills/ directory changes  
- **.claude/commands/COMMANDS_REGISTRY.md** — Updated when commands/ directory changes

### Architecture

```
Code Change → Commit → Pre-Commit Hook (validates)
                      ↓
                   Post-Commit Hook (regenerates registries)
                      ↓
                   Registries Staged & Ready for Amend
```

### Three-Mode Operation

#### Mode 1: Check (pre-commit validation)
**Purpose**: Verify registries are current before allowing commit

```bash
./scripts/regenerate-registries.sh --check
```

**Exit codes**:
- `0` = All registries current (commit allowed)
- `1` = Registries out of date (commit blocked by pre-commit hook)

**Usage**: Called by pre-commit hook automatically

#### Mode 2: Update (regenerate)
**Purpose**: Regenerate registries from source files

```bash
./scripts/regenerate-registries.sh --update
```

**What it does**:
- Scans agents/, skills/, .claude/commands/ directories
- Counts entities by tier/domain
- Regenerates register files with latest information
- Timestamps each update
- Shows count of agents, skills, commands

**Usage**: Called by post-commit hook automatically

#### Mode 3: Dry-Run (preview)
**Purpose**: See what would change without modifying files

```bash
./scripts/regenerate-registries.sh --dry-run
```

**Output**: Shows diffs of what would be updated

---

### Workflow: Adding a New Agent

**Scenario**: You add a new backend architect agent

**Step 1: Create agent file**
```bash
# Create new agent
cat > agents/backend/new-architect-agent.md << 'EOF'
# New Architect Agent
...
EOF
```

**Step 2: Commit agent**
```bash
git add agents/backend/new-architect-agent.md
git commit -m "feat(agents): Add new-architect-agent for async API design"
```

**What happens automatically**:
1. ✅ Pre-commit hook validates doc updates (none needed for agent alone)
2. ✅ Post-commit hook detects `agents/` changed
3. ✅ Regenerates `agents/CAPABILITY_MATRIX.md`
4. ✅ Stages the updated registry
5. 👤 Prompts you: `git commit --amend --no-edit` to include registry update

**Step 3: Amend commit with registry**
```bash
git commit --amend --no-edit
```

**Result**: Commit now includes both agent AND updated CAPABILITY_MATRIX.md

---

### Workflow: Adding a New Skill

**Scenario**: You add a new performance optimization skill

**Step 1: Create skill**
```bash
mkdir skills/performance-optimization
cat > skills/performance-optimization/SKILL.md << 'EOF'
# Performance Optimization Skill
...
EOF
```

**Step 2: Commit skill**
```bash
git add skills/performance-optimization/
git commit -m "feat(skills): Add performance-optimization skill"
```

**What happens automatically**:
1. ✅ Post-commit hook detects `skills/` changed
2. ✅ Regenerates `skills/SKILL.md` registry
3. ✅ Stages updated registry
4. 👤 Prompts you: `git commit --amend --no-edit`

**Step 3: Amend commit**
```bash
git commit --amend --no-edit
```

---

### Workflow: Adding a New Command

**Scenario**: You add a new `/performance-baseline` command

**Step 1: Create command**
```bash
cat > .claude/commands/performance-baseline.md << 'EOF'
# /performance-baseline command
...
EOF
```

**Step 2: Commit command**
```bash
git add .claude/commands/performance-baseline.md
git commit -m "feat(commands): Add /performance-baseline command"
```

**What happens automatically**:
1. ✅ Post-commit hook detects `.claude/commands/` changed
2. ✅ Regenerates `.claude/commands/COMMANDS_REGISTRY.md`
3. ✅ Stages updated registry
4. 👤 Prompts you: `git commit --amend --no-edit`

**Step 3: Amend commit**
```bash
git commit --amend --no-edit`
```

---

## 2. Semantic Versioning System

### What It Does

Manages User_Manual version according to semantic versioning:
- **MAJOR (X.0.0)**: Breaking changes (stages renamed, commands removed, roles changed)
- **MINOR (0.X.0)**: New features (new agents, skills, commands without breaking changes)
- **PATCH (0.0.X)**: Bug fixes, clarifications, improved documentation

### Files

| File | Purpose |
|------|---------|
| `User_Manual/VERSION` | Current version (e.g., `1.0.0`) |
| `User_Manual/CHANGELOG.md` | Release history and upgrade guide |

### Version Bump Script

**Show current version**:
```bash
./scripts/bump-version.sh --show
```

Output:
```
Current Version: 1.0.0
```

**Bump MAJOR version** (1.0.0 → 2.0.0):
```bash
./scripts/bump-version.sh --major
```

Use when:
- Stage added/removed
- Stage renamed
- Command signature changed
- Critical rule changed
- Roles removed or responsibilities significantly altered

**Bump MINOR version** (1.0.0 → 1.1.0):
```bash
./scripts/bump-version.sh --minor
```

Use when:
- New agent added
- New skill added
- New command added
- New integration added
- Significant new feature documented

**Bump PATCH version** (1.0.0 → 1.0.1):
```bash
./scripts/bump-version.sh --patch
```

Use when:
- Bug fix in documentation
- Clarification of existing feature
- Typo fix
- Example improvement
- FAQ entry added

---

### Workflow: Releasing v1.1.0 (New Agents)

**Scenario**: You added 3 new agents and need to release v1.1.0

**Step 1: Verify all agent additions**
```bash
git log --oneline --grep="feat(agents)" | head -5
```

**Step 2: Bump version**
```bash
./scripts/bump-version.sh --minor
```

**Output**:
```
→ Bumping MINOR version: 1.0.0 → 1.1.0
✓ Updated User_Manual/VERSION → 1.1.0
✓ Updated User_Manual/CHANGELOG.md with version 1.1.0

[Next Steps]

1. Review changes:
   git diff User_Manual/VERSION User_Manual/CHANGELOG.md

2. Stage version bump:
   git add User_Manual/VERSION User_Manual/CHANGELOG.md

3. Commit version bump:
   git commit -m "docs(user-manual): Release v1.1.0"

4. Create git tag:
   git tag -a v1.1.0 -m "User Manual v1.1.0"

5. Push to remote:
   git push && git push --tags
```

**Step 3: Follow the steps**
```bash
# Review
git diff User_Manual/VERSION User_Manual/CHANGELOG.md

# Stage
git add User_Manual/VERSION User_Manual/CHANGELOG.md

# Commit
git commit -m "docs(user-manual): Release v1.1.0"

# Tag
git tag -a v1.1.0 -m "User Manual v1.1.0"

# Push
git push && git push --tags
```

**Step 4: Announce release**
```
Version 1.1.0 released!

New agents:
- agent-a (new feature X)
- agent-b (new feature Y)
- agent-c (new feature Z)

User action: Optional. New features available.

See User_Manual/CHANGELOG.md for details.
```

---

### Workflow: Emergency Patch Release

**Scenario**: Found critical typo in System_Overview.md

**Step 1: Fix the typo**
```bash
# Edit file
vim User_Manual/System_Overview.md

# Stage change
git add User_Manual/System_Overview.md

# Commit
git commit -m "docs(user-manual): Fix typo in System_Overview"
```

**Step 2: Bump patch version**
```bash
./scripts/bump-version.sh --patch
```

**Output**:
```
→ Bumping PATCH version: 1.1.0 → 1.1.1
✓ Updated User_Manual/VERSION → 1.1.1
✓ Updated User_Manual/CHANGELOG.md with version 1.1.1
```

**Step 3: Release**
```bash
git add User_Manual/VERSION User_Manual/CHANGELOG.md
git commit -m "docs(user-manual): Release v1.1.1"
git tag -a v1.1.1 -m "User Manual v1.1.1"
git push && git push --tags
```

---

### CHANGELOG Structure

Each release section includes:

```markdown
## [1.1.0] - 2026-04-15

### MINOR Release

#### Added
- New performance agent
- New skills for optimization
- New commands

#### Changed
- Version bump to 1.1.0

---
```

---

## 3. Integration with Documentation Validation

### How They Work Together

```
Code Change
    ↓
Pre-Commit Hook: doc-change-check.sh
    ↓
    ├─ Agents/skills/rules/commands changed?
    └─ YES → User_Manual must be updated
             Registry regeneration detects NEW agents/skills/commands
             but does NOT update User_Manual (that's manual)
    ↓
Commit Allowed ✓
    ↓
Post-Commit Hook: post-commit-registry-update.sh
    ↓
    └─ Auto-regenerates affected registries
       (CAPABILITY_MATRIX, SKILL.md, COMMANDS_REGISTRY)
    ↓
Registries Staged ✓
    ↓
User Amends: git commit --amend --no-edit
    ↓
Final Commit Has Both Code + Updated Registries ✓
```

### Example: Adding a New Agent + Updating Manual

```bash
# Step 1: Create new agent
cat > agents/backend/new-validator.md << EOF
# New Validator Agent
EOF

# Step 2: Add entry to User_Manual/Agents_Skills_Rules.md
# Edit and update agent count from 52 → 53

# Step 3: Commit
git add agents/backend/new-validator.md User_Manual/Agents_Skills_Rules.md
git commit -m "feat(agents): Add new-validator agent"

# What happens:
#   Pre-commit validates: User_Manual updated? YES ✓
#   Commit: ALLOWED
#   Post-commit: Regenerates CAPABILITY_MATRIX.md, stages it
#   Amend: git commit --amend --no-edit

# Step 4: Amend to include registry
git commit --amend --no-edit

# Final commit contains:
# - agents/backend/new-validator.md (code)
# - User_Manual/Agents_Skills_Rules.md (docs, manual)
# - agents/CAPABILITY_MATRIX.md (registry, auto-generated)
```

---

## 4. Manual Registry Regeneration

If you need to manually regenerate registries:

```bash
# Check which registries are out of date
./scripts/regenerate-registries.sh --check

# Regenerate all registries
./scripts/regenerate-registries.sh --update

# Preview changes before applying
./scripts/regenerate-registries.sh --dry-run
```

**When to manually regenerate**:
- If post-commit hook didn't run
- If you want to clean up stale registries
- If you need to force regeneration

---

## 5. Installation

### Install Pre-Commit Hook (Validation)

```bash
# Option A: Symlink
ln -s ../../hooks/doc-change-check.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Option B: Use git config
git config core.hooksPath hooks
chmod +x hooks/doc-change-check.sh
```

### Install Post-Commit Hook (Registry Update)

```bash
# Option A: Symlink
ln -s ../../hooks/post-commit-registry-update.sh .git/hooks/post-commit
chmod +x .git/hooks/post-commit

# Option B: Use git config
git config core.hooksPath hooks
chmod +x hooks/post-commit-registry-update.sh
```

### Verify Installation

```bash
# Check hooks are linked
ls -la .git/hooks/pre-commit .git/hooks/post-commit

# Or check if core.hooksPath set
git config core.hooksPath
```

---

## 6. Common Scenarios

### Scenario 1: Adding 5 New Skills

```bash
# Create skills
for i in {1..5}; do
    mkdir skills/new-skill-$i
    cat > skills/new-skill-$i/SKILL.md << EOF
# New Skill $i
...
EOF
done

# Commit
git add skills/new-skill-*/
git commit -m "feat(skills): Add 5 new optimization skills"

# What happens:
# Post-commit hook detects skills/ changed
# Regenerates skills/SKILL.md (37 → 42 skills)
# Stages the updated registry
# Prompts you: git commit --amend --no-edit

# Amend to include registry
git commit --amend --no-edit

# Optionally: Bump version
./scripts/bump-version.sh --minor
git add User_Manual/VERSION User_Manual/CHANGELOG.md
git commit -m "docs(user-manual): Release v1.1.0"
git tag -a v1.1.0 -m "User Manual v1.1.0"
```

### Scenario 2: Renaming a Stage

```bash
# Rename stage file
mv stages/08-pre-prod/STAGE.md stages/08-staging/STAGE.md

# Update STAGE.md content
# Update all references in rules/, agents/, skills/
# Update User_Manual/SDLC_Flows.md

# Commit
git add stages/ User_Manual/SDLC_Flows.md rules/ agents/
git commit -m "refactor(stages): Rename pre-prod to staging"

# What happens:
# Pre-commit hook: Expects User_Manual/SDLC_Flows.md updated? YES ✓
# Commit: ALLOWED
# No registry changes (stages don't have a registry)
# No post-commit action

# MAJOR VERSION BUMP (breaking change)
./scripts/bump-version.sh --major
git add User_Manual/VERSION User_Manual/CHANGELOG.md
git commit -m "docs(user-manual): Release v2.0.0 - Stage renamed"
git tag -a v2.0.0 -m "User Manual v2.0.0"
```

---

## 7. Troubleshooting

### Q: Post-commit hook didn't run after my commit

**A**: Check installation:
```bash
ls -la .git/hooks/post-commit
```

If missing, reinstall:
```bash
git config core.hooksPath hooks
```

### Q: Registry shows old count

**A**: Manually regenerate:
```bash
./scripts/regenerate-registries.sh --update
git add agents/CAPABILITY_MATRIX.md skills/SKILL.md .claude/commands/COMMANDS_REGISTRY.md
git commit -m "docs: Regenerate registries"
```

### Q: Commit blocked because User_Manual not updated

**A**: Update relevant User_Manual file, then commit:
```bash
# Edit affected files (e.g., Agents_Skills_Rules.md)
vim User_Manual/Agents_Skills_Rules.md

# Stage changes
git add User_Manual/Agents_Skills_Rules.md

# Commit
git commit -m "docs(user-manual): Update agent count"
```

### Q: How do I skip doc validation?

**A**: Use `--no-verify` (not recommended):
```bash
git commit --no-verify
```

This bypasses pre-commit validation. Only use for emergency hotfixes.

---

## 8. Summary

| System | Purpose | Triggering | Scope |
|--------|---------|-----------|-------|
| **Registry Auto-Gen** | Keep registries in sync | agents/skills/commands changes | agents/CAPABILITY_MATRIX.md, skills/SKILL.md, .claude/commands/COMMANDS_REGISTRY.md |
| **Semantic Versioning** | Track documentation changes | Manual version bump | User_Manual/VERSION, User_Manual/CHANGELOG.md |
| **Pre-Commit Validation** | Enforce doc updates | Every commit | Blocks if system code changes without User_Manual updates |
| **Post-Commit Registry** | Auto-update registries | After commit | Stages registry updates for amend |

---

**Documentation**: REGISTRY_VERSIONING_GUIDE.md  
**Last Updated**: 2026-04-13  
**Maintainer**: Documentation Engineer
