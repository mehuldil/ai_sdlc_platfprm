# Migrating from V2 to Current Version

This guide is for teams currently using **AI-SDLC-Platform V2** who need to migrate to the **current version** with the enhanced 3-tier context loading, token optimization, and streamlined stage execution.

---

## What Changed (Simple Summary)

| What | V2 (Before) | Current (After) | What You Need to Do |
|------|-------------|-------------------|---------------------|
| **Context loading** | Load everything, filter later | 3-tier progressive loading (base → stage → skills) | Update your `.sdlc/config` with `loading_strategy: tiered` |
| **Token budgets** | Per-stage soft limits | Enforced per-role daily/sprint budgets | Run `sdlc budget init` to set your team budgets |
| **Memory storage** | SQLite + JSONL in `.sdlc/memory/` | Same, but with **git-sync tracking** | Run `sdlc memory migrate` to add sync metadata |
| **Agent registry** | Single `agent-registry.json` | **Stack-specific registries** (e.g., `agents/java-tej/registry.json`) | Re-run `sdlc use <role> --stack=<stack>` to regenerate links |
| **Stage variants** | All in one `STAGE.md` | **Split by stack** in `variants/` subdirectories | No action — automatic fallback |
| **CLI commands** | `sdlc run <stage>` works | **Same**, but with token pre-check | Update scripts that bypass CLI (use `sdlc run --force` if needed) |
| **Hooks** | 23 separate hook scripts | **Consolidated** to 12 core hooks | Re-run `./setup.sh` to update hooks |

**Bottom line:** Most changes are **under the hood improvements**. Your workflows stay the same, but you get better performance and cost control.

---

## Who Needs to Do What

### **For Individual Developers (5 minutes)**

1. **Update your platform clone:**
   ```bash
   cd /path/to/ai-sdlc-platform
   git pull origin main
   ```

2. **Re-run setup in your app repo:**
   ```bash
   ./setup.sh /path/to/your/app
   ```
   This updates symlinks and hooks to the new structure.

3. **Verify your role and stack:**
   ```bash
   sdlc context
   # Should show: Role, Stack, Loading Strategy: tiered
   ```

4. **Check token budgets are set:**
   ```bash
   sdlc budget status
   # Shows: Daily used/remaining, Sprint used/remaining
   ```

**If you get "Budget not initialized":** Ask your TPM/Lead to run `sdlc budget init --team=<team>`.

---

### **For Tech Leads / TPMs (15 minutes)**

1. **Set team token budgets:**
   ```bash
   # Edit scripts/token-blocker.sh or use CLI
   sdlc budget set --role=backend-engineer --daily=60000 --sprint=600000
   sdlc budget set --role=product-manager --daily=30000 --sprint=300000
   # ... for each role
   ```

2. **Update team documentation:**
   - Share this migration guide with your team
   - Update any internal wiki pages referencing `sdlc run` (still valid, but mention token budgets)

3. **Verify CI/CD pipelines:**
   - If you have scripts calling `sdlc` directly, they continue to work
   - Optional: Add `sdlc budget check` before heavy operations in CI

4. **Monitor first week:**
   ```bash
   sdlc budget report --team --sprint
   # Review token usage patterns
   ```

---

### **For Platform Administrators (30 minutes)**

1. **Review new file structure:**
   ```
   agents/
   ├── backend/
   │   ├── java-tej/
   │   │   ├── agent-registry.json     # NEW: Stack-specific
   │   │   └── agents/
   ├── shared/
   │   └── context-guard.md              # NEW: Tiered loading rules
   ```

2. **Update organization-wide config:**
   - Copy `config/token-budgets.template.sh` to `config/token-budgets.sh`
   - Set your organization's defaults

3. **Migrate existing `.sdlc/` directories:**
   ```bash
   # Run on each app repo
   sdlc migrate v2-to-current --path=/path/to/app
   ```
   This:
   - Adds `loading_strategy: tiered` to `.sdlc/config`
   - Migrates memory files to new sync format
   - Updates `state.json` with budget tracking fields

4. **Validate migration:**
   ```bash
   sdlc doctor --full
   bash scripts/validate-migration.sh
   ```

5. **Update documentation:**
   - Regenerate manual.html: `node User_Manual/build-manual-html.mjs`
   - Notify teams via email/Slack with link to this guide

---

## Step-by-Step Migration (Detailed)

### Step 1: Backup Your Current Setup

```bash
# Before making any changes
cd /path/to/your/app
cp -r .sdlc .sdlc-backup-v2
cp -r .claude .claude-backup-v2 2>/dev/null || true
```

### Step 2: Update Platform Repository

```bash
cd /path/to/ai-sdlc-platform
git fetch origin
git checkout main
git pull origin main
```

### Step 3: Re-run Setup (Critical Step)

```bash
# From platform repo
./setup.sh /path/to/your/app

# Or using sdlc CLI
sdlc setup /path/to/your/app
```

**What this does:**
- Updates symlinks to new agent/skill structure
- Installs updated hooks (consolidated from 23 → 12)
- Creates `.sdlc/config` if missing `loading_strategy`
- Migrates `state.json` to new format

### Step 4: Set Token Budgets

**Option A: Using CLI (recommended)**
```bash
cd /path/to/your/app
sdlc budget init
sdlc budget set --daily=50000 --sprint=500000
```

**Option B: Manual edit**
Edit `.sdlc/config`:
```json
{
  "loading_strategy": "tiered",
  "token_budgets": {
    "daily": 50000,
    "sprint": 500000,
    "per_stage": {
      "01-requirement-intake": 3000,
      "08-implementation": 8000
    }
  }
}
```

### Step 5: Migrate Memory (if using semantic memory)

```bash
sdlc memory migrate
# Converts old JSONL format to new git-sync format
```

### Step 6: Verify Everything Works

```bash
# Check context loads correctly
sdlc context

# Check token budgets
sdlc budget status

# Run a lightweight stage to test
sdlc run 01-requirement-intake --dry-run

# Full diagnostic
sdlc doctor
```

### Step 7: Resume Normal Work

Your usual commands work the same:
```bash
sdlc use backend --stack=java-tej
sdlc run 08-implementation
sdlc story push ./stories/...
```

---

## Troubleshooting Migration Issues

### Issue: "Unknown loading strategy"

**Symptom:**
```
Error: config loading_strategy must be 'tiered' or 'full'
Current value: undefined
```

**Fix:**
```bash
sdlc config set loading_strategy=tiered
# Or edit .sdlc/config manually
```

### Issue: "Token budget exceeded" immediately

**Symptom:**
```
Error: Daily budget (0/50000) exceeded
```

**Fix:**
```bash
# Budgets not initialized
sdlc budget init --role=$(sdlc context --role)
```

### Issue: "Agent not found" after migration

**Symptom:**
```
Error: Agent 'java-backend-engineer' not found in registry
```

**Fix:**
```bash
# Re-set your role to regenerate registry links
sdlc use backend --stack=java-tej --refresh
```

### Issue: Hooks not firing

**Symptom:**
Pre-commit hooks don't run after migration.

**Fix:**
```bash
# Re-install hooks
sdlc hooks install --force

# Verify
ls -la .git/hooks/pre-commit
# Should link to platform hooks/
```

### Issue: Memory not syncing

**Symptom:**
`sdlc memory status` shows "Sync: disabled"

**Fix:**
```bash
# Enable git-sync for memory
sdlc memory config set sync.enabled=true
sdlc memory config set sync.branch=main
```

---

## Rollback Plan (If Needed)

If migration causes issues:

```bash
cd /path/to/your/app

# 1. Restore V2 .sdlc/
cp -r .sdlc-backup-v2 .sdlc

# 2. Switch platform repo back to V2 tag
cd /path/to/ai-sdlc-platform
git checkout v2.x.x  # Use your previous V2 tag

# 3. Re-run V2 setup
./setup.sh /path/to/your/app

# 4. Verify
sdlc doctor
```

**Note:** V2 and current version can coexist on the same machine — just use different platform repo paths.

---

## What's New for Each Role

### **Backend Engineers**
- **Faster context loading:** Only Java/TEJ rules load, not all stacks
- **Module KB integration:** `sdlc module load api` is now automatic in Stage 08
- **Better RPI workflow:** Research/Plan/Implement stages pre-check token budgets

### **Frontend Engineers**
- **Stack-specific variants:** React Native stages have dedicated templates
- **Component library awareness:** Memory tracks UI component decisions

### **QA Engineers**
- **Test plan templates:** Stage 10 loads relevant test patterns automatically
- **Defect tracking:** Integration with QA orchestrator improved

### **Product Managers**
- **Story generation:** Lower token costs for PRD → story creation
- **4-tier story tracking:** Better visibility across master/sprint/tech/task

### **Tech Leads / TPMs**
- **Budget dashboards:** `sdlc budget report --team` shows organization spend
- **Gate analytics:** Track which gates teams skip most often

---

## Post-Migration Checklist

- [ ] Platform repo updated to latest
- [ ] App repos re-setup with new symlinks
- [ ] Token budgets configured per role
- [ ] Memory migrated to sync format
- [ ] CI/CD scripts tested
- [ ] Team notified of changes
- [ ] Internal documentation updated
- [ ] First sprint completed successfully

---

## Questions?

- **Migration failed?** Run `sdlc doctor --verbose` and check logs in `.sdlc/logs/`
- **Budget questions?** See [Token Efficiency & Context Loading](Token_Efficiency_and_Context_Loading.md)
- **Architecture changes?** See [Architecture](Architecture.md) §Context Loading Tiers

> **Remember:** This migration is about **efficiency and cost control**, not workflow changes. Your day-to-day `sdlc` commands stay the same.
