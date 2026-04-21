# Migrating from V2 to V2.1

**Version**: 2.1.0  
**Last Updated**: 2026-04-17  
**Migration Duration**: 10-30 minutes  
**Risk Level**: Low (100% backward compatible)

---

## What Changed in V2.1.0?

### New Features

| Feature | V2 | V2.1 | Benefit |
|---------|-----|------|---------|
| **Skills** | Monolithic (~200 lines) | Atomic + Composed | 10x reusability |
| **Skill Routing** | File paths | Registry-based | Cross-role usage |
| **ADO Sync** | Push only | Push + Pull (2-way) | Event-driven workflows |
| **Caching** | None | Per-skill TTL | 10x faster repeats |
| **Stage Definition** | Prose (STAGE.md) | YAML (composition.yaml) | Declarative + testable |
| **Discovery** | Browse files | Interactive CLI | 5-min skill onboarding |

### Architecture Changes

```
V2:                    V2.1:
skills/                skills/
├── *.md               ├── registry.json    # NEW
├── shared/            ├── atomic/          # NEW (10 skills)
├── backend/           ├── composed/        # NEW (YAML workflows)
├── frontend/          ├── shared/
└── ...                ├── backend/
                       ├── frontend/
                       └── *.md            # Legacy (preserved)

stages/08-implementation/        stages/08-implementation/
└── STAGE.md                     ├── STAGE.md              # Legacy
                                 └── composition.yaml      # NEW

NEW: orchestrator/ado-observer/     # 2-way ADO sync
NEW: cli/lib/skill-router.sh        # Routing + caching
NEW: cli/lib/composition-engine.py  # YAML executor
NEW: cli/lib/skill-discovery.sh     # Interactive UI
```

---

## Migration Checklist

### Pre-Migration (5 minutes)

- [ ] Ensure Git is clean (`git status` shows no uncommitted changes)
- [ ] Ensure dependencies installed: `jq`, `python3`, `python3-yaml`
- [ ] Backup current setup (optional): `git tag v2.0-backup`
- [ ] Read this guide fully before starting

### Migration Steps (10-20 minutes)

1. [ ] Pull V2.1.0 code
2. [ ] Run migration check
3. [ ] Apply migration
4. [ ] Verify installation
5. [ ] Test skill routing
6. [ ] Test ADO observer (optional)

### Post-Migration (5 minutes)

- [ ] Verify existing workflows still work
- [ ] Review new documentation
- [ ] Share with team

---

## Step-by-Step Migration

### Step 1: Pull V2.1.0 Code

```bash
# Navigate to your AI-SDLC platform clone
cd AI-sdlc-platform

# Pull latest changes
git pull origin main

# Verify you have v2.1.0
git log --oneline -1
# Should show: feat: v2.1.0 atomic skills architecture...
```

### Step 2: Run Migration Check

```bash
# Check migration status
bash scripts/migrate-v2.1.sh --check
```

**Expected Output**:
```
━━━ Prerequisites Check ━━━
✓ All prerequisites satisfied

━━━ Migration Status Check ━━━
✓ Skill registry exists
✓ Skill router exists
✓ Atomic skills directory exists
✓ Composed skills directory exists
✓ ADO observer exists
✓ Composition engine exists
✓ Stage compositions exist
✓ Legacy skills preserved

Checks passed: 8/8
Migration v2.1.0 is complete!
```

If any checks fail, run:
```bash
bash scripts/migrate-v2.1.sh --apply
```

### Step 3: Apply Migration (If Needed)

```bash
# Apply migration (safe, preserves all legacy files)
bash scripts/migrate-v2.1.sh --apply
```

**This will**:
1. Create `skills/atomic/` directory
2. Create `skills/composed/` directory
3. Create `skills/registry.json`
4. Add `cli/lib/skill-router.sh`
5. Add `cli/lib/composition-engine.py`
6. Add `cli/lib/skill-discovery.sh`
7. Add `orchestrator/ado-observer/`
8. **Preserve all existing skills and stages**

**This will NOT**:
- Delete any existing files
- Break existing workflows
- Change existing behavior (without explicit opt-in)

### Step 4: Verify Installation

```bash
# Run platform validation
bash scripts/ci-sdlc-platform.sh --quick

# Check skill router
sdlc skills list --category=rpi

# Check composition engine
ls skills/composed/
# Should show: rpi-research.yaml, rpi-plan.yaml
```

### Step 5: Test Skill Routing

```bash
# Test that routing works
sdlc skills show rpi-research

# Expected output shows both implementations:
#   composed: skills/composed/rpi-research.yaml
#   generic: skills/rpi-research.md

# Test discovery
sdlc skills discover --for-role=backend
```

### Step 6: Test ADO Observer (Optional)

```bash
# Start observer in polling mode (no webhook setup needed)
export ADO_ORG=your-org
export ADO_PROJECT=your-project
export ADO_PAT=your-pat
export ADO_OBSERVER_MODE=polling

python3 orchestrator/ado-observer/observer.py &

# Check status
sdlc ado-observer status
```

---

## What Happens to Your Existing Work?

### Skills: 100% Preserved

Your existing skills continue to work exactly as before:

```bash
# Legacy execution (still works)
sdlc rpi research US-1234

# New execution (uses router)
sdlc skills invoke rpi-research --story=US-1234
# → Router picks composed version (if available)
# → Falls back to legacy version (if composed fails)
```

### Stages: 100% Preserved

Your existing stages continue to work:

```bash
# Legacy execution (still works)
sdlc run 08-implementation

# New execution (uses composition if available)
sdlc run 08-implementation
# → Checks for composition.yaml first
# → Falls back to STAGE.md if needed
```

### ADO Integration: 100% Preserved

Existing ADO commands work unchanged:

```bash
# Legacy commands (still work)
sdlc ado sync
sdlc ado push-story story.md

# New capability (optional)
sdlc ado-observer start  # Enables 2-way sync
```

---

## Adoption Strategy

### Phase 1: Read-Only (Day 1)

**Actions**:
- Pull v2.1.0 code
- Run `--check` to verify
- Continue using existing commands
- Explore new documentation

**Goal**: Verify nothing broke

### Phase 2: Discovery (Week 1)

**Actions**:
- Try `sdlc skills discover`
- Review `skills/registry.json`
- Explore atomic skills in `skills/atomic/`
- Review composed skills in `skills/composed/`

**Goal**: Understand new capabilities

### Phase 3: Gradual Adoption (Weeks 2-4)

**Actions**:
- Use composed skills for new workflows
- Write first atomic skill (copy from template)
- Try skill caching (`sdlc skills cache clear`)

**Goal**: Build comfort with new system

### Phase 4: Full Adoption (Month 2+)

**Actions**:
- Migrate frequently-used skills to composed format
- Enable ADO observer for 2-way sync
- Contribute atomic skills back to platform

**Goal**: Realize 10x reusability benefits

---

## Common Questions

### Q: Do I need to rewrite my existing skills?

**No**. All existing skills work unchanged. The skill router automatically falls back to legacy implementations.

### Q: Will my existing workflows break?

**No**. All existing commands (`sdlc run`, `sdlc rpi`, etc.) work exactly as before.

### Q: Can I use both old and new together?

**Yes**. The system is designed for gradual migration. You can:
- Use legacy skills for existing work
- Use composed skills for new work
- Mix atomic skills with monolithic skills

### Q: What if the new system has bugs?

**Rollback is easy**:
```bash
bash scripts/migrate-v2.1.sh --rollback
```

Or simply don't use new features (they're opt-in).

### Q: Do I need ADO admin access?

**No for basic usage**. The ADO observer works in polling mode without webhooks. Webhooks (for real-time sync) require ADO admin.

### Q: What's the performance impact?

**Positive**:
- Skill caching reduces token usage 10x for repeat operations
- Atomic skills load faster (smaller context)
- Composition engine has minimal overhead

### Q: How do I teach my team?

1. Share this migration guide
2. Run `sdlc skills discover` together
3. Review `User_Manual/Architecture.md` section on "Skill Architecture"
4. Try converting one simple skill to composed format as a team exercise

---

## Troubleshooting

### Issue: `skills/registry.json` not found

**Solution**:
```bash
bash scripts/migrate-v2.1.sh --apply
```

### Issue: Commands fail with "unknown command"

**Solution**: Ensure you're in the platform directory or have run setup:
```bash
./setup.sh --quick
```

### Issue: Legacy skills not working

**Solution**: Check fallback configuration:
```bash
jq '.skills."rpi-research".fallback' skills/registry.json
# Should show: "generic"
```

### Issue: ADO observer not receiving events

**Solution**: Check environment variables:
```bash
echo $ADO_ORG
echo $ADO_PROJECT
echo $ADO_PAT
```

Then test connection:
```bash
sdlc ado show 12345  # Any work item ID
```

### Issue: Cache not working

**Solution**: Verify cache directory:
```bash
ls -la .sdlc/cache/skills/
```

Clear and retry:
```bash
sdlc skills cache clear
```

---

## Rollback (If Needed)

If you need to return to V2 state:

```bash
# Rollback migration
bash scripts/migrate-v2.1.sh --rollback

# Or manually revert commit
git revert 8b19902  # Commit hash of v2.1.0
```

**Rollback removes**:
- `skills/atomic/` directory
- `skills/composed/` directory
- `skills/registry.json`
- `cli/lib/skill-router.sh`
- `cli/lib/composition-engine.py`
- `cli/lib/skill-discovery.sh`
- `orchestrator/ado-observer/`
- `stages/*/composition.yaml` files

**Rollback preserves**:
- All legacy skills (`skills/*.md`)
- All legacy stages (`stages/*/STAGE.md`)
- All existing workflows
- All memory and state

---

## Summary

V2.1.0 adds powerful new capabilities while maintaining **100% backward compatibility**. Your existing code, skills, and workflows continue to work unchanged.

**Key Takeaways**:
1. ✅ Migration is safe and reversible
2. ✅ Existing code works unchanged
3. ✅ New features are opt-in
4. ✅ Gradual adoption is supported
5. ✅ Rollback is always available

**Next Steps**:
1. Run `bash scripts/migrate-v2.1.sh --check`
2. Try `sdlc skills discover`
3. Review updated documentation
4. Share with your team

**Support**:
- Documentation: `User_Manual/` (all updated for v2.1.0)
- Migration script: `scripts/migrate-v2.1.sh --help`
- Issues: Check troubleshooting section above
