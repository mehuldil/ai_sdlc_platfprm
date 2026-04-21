---
name: Smart Routing Integration
description: How task classification affects stage execution
---

# Smart Routing × Stage Execution

When `sdlc run <stage>` is invoked, the system first classifies the task using the Smart Routing agent (Haiku). Classification determines which stages are optimal for the change type, enabling fast-track execution for low-risk changes while maintaining full rigor for high-risk work.

---

## Classification → Stage Map

The routing system maps change types to Gate Depth levels, which determine which stages execute:

| Route | Gate Depth | Stages Executed | Stages Skipped | Use Case |
|-------|-----------|----------------|---------------|----------|
| CONFIG_CHANGE | LITE | 01, 08, 09, 12, 15 | 02-07, 10-11, 13-14 | Update config files, environment variables, feature flags (non-code changes) |
| BUG_FIX | FULL | 01, 05, 07, 08, 09, 10, 11, 12, 13, 15 | 02-04, 06, 14 | Fix defects in existing functionality; requires testing and design review |
| HOTFIX | SKIP | 01, 08, 12, 15 | 02-07, 09-11, 13-14 | Critical production bugs; minimal gates, fast deploy. Use sparingly |
| UI_TWEAK | LITE | 01, 06, 08, 09, 10, 12, 15 | 02-05, 07, 11, 13-14 | Minor visual updates, copy changes, layout tweaks (no logic changes) |
| REFACTOR | FULL | 01, 05, 07, 08, 09, 10, 11, 12, 13, 15 | 02-04, 06, 14 | Code quality improvements; requires full testing to ensure behavior unchanged |
| NEW_FEATURE | FULL | 01-15 (all) | None | New capability; requires all stages (intake → design → dev → test → deploy) |

### Stage Reference
```
01: Requirement Intake
02: PRD Review
03: Pre-Grooming
04: Grooming
05: System Design
06: Design Review
07: Task Breakdown
08: Implementation
09: Code Review
10: Test Design
11: Test Execution
12: Commit/Push
13: Documentation
14: Release Signoff
15: Summary/Close
```

---

## How It Works

### Step-by-Step Execution Flow

1. **User invokes command** with task description or sprint story ID:
   ```bash
   sdlc route "fix null pointer in upload service"
   # OR
   sdlc run 08-implementation --story=US-1234
   ```

2. **Smart Routing agent (Haiku) classifies** the change:
   - Analyzes task description/code changes
   - Determines route: BUG_FIX, NEW_FEATURE, HOTFIX, etc.
   - Returns classification + confidence level
   - Example output:
     ```json
     {
       "route": "BUG_FIX",
       "confidence": 0.92,
       "reasoning": "Fixes null pointer exception in existing upload logic",
       "gate_depth": "FULL",
       "recommended_stages": [1, 5, 7, 8, 9, 10, 11, 12, 13, 15],
       "skipped_stages": [2, 3, 4, 6, 14]
     }
     ```

3. **System checks applicable stages** for the detected route:
   - If user specified a stage (`sdlc run 08-implementation`), verify it's in the applicable list
   - If user runs a stage outside the recommended set, system warns but allows override
   - Example warning:
     ```
     ⚠️ Stage 02 (PRD Review) not typical for BUG_FIX route.
     Continue anyway? This is a NEW_FEATURE-level review. (y/n)
     ```

4. **Gate depth determines approval requirements**:
   - **SKIP**: Auto-approve intermediate gates; human only at final deploy gate (stage 15)
   - **LITE**: Human approval at entry + exit gates only (stages 01 & 15)
   - **FULL**: Human approval at every gate (01, 05, 07, 08, 09, 10, 11, 12, 13, 15)

5. **Stage executes with pre-conditions checked**:
   - Each stage loads its own STAGE.md for pre-conditions
   - System checks `.sdlc/memory/` for completion records of prior stages
   - If upstream stage not completed, system prompts:
     ```
     Stage 05 (System Design) not completed.
     Stage 08 requires design to be approved. Continue anyway? (y/n)
     ```

6. **Stage completes and records status**:
   - Success recorded in `.sdlc/memory/stage-08-implementation.json`
   - Metadata captured: user, timestamp, duration, outputs
   - Next stage can read this state

---

## Stage Independence (Role-Based Access)

**Key Principle**: Every stage CAN be run independently, regardless of route classification.

This enables:
- QA to jump straight to stage 10 (Test Design) to review test plans
- DevOps to jump to stage 12 (Commit/Push) to handle deployment
- Product to jump to stage 01 (Requirement Intake) to intake new requests
- Tech Lead to jump to stage 09 (Code Review) to review code without waiting for prior stages

### Independent Stage Execution Flow

1. **User runs a stage directly**:
   ```bash
   sdlc run 10-test-design --story=US-1234
   # (No prior stages completed)
   ```

2. **Stage loads STAGE.md** for pre-conditions:
   - Reads declared upstream dependencies
   - Example from stage 10 (Test Design):
     ```yaml
     prerequisite_stages: [01, 05, 07]  # Requires: Intake, Design, Task Breakdown
     ```

3. **System checks completion records**:
   - Queries `.sdlc/memory/` for completion of stage 01, 05, 07
   - If any missing, user is prompted:
     ```
     ⚠️ Stage 10 depends on:
       ✓ Stage 01 (Requirement Intake) — NOT COMPLETED
       ? Stage 05 (System Design) — NOT COMPLETED
       ? Stage 07 (Task Breakdown) — NOT COMPLETED
     
     Continue anyway? (y/n)
     If yes, you may need to manually review requirements/design.
     ```

4. **User chooses**: Skip preconditions or cancel
   - If continue: Stage runs in "unchecked" mode (user assumes responsibility)
   - If cancel: User returns to prior stage

5. **Stage executes** and records output:
   - Completion status written to `.sdlc/memory/stage-10-test-design.json`
   - Downstream stages can now see this stage is complete

---

## Routing Examples

### Example 1: Bug Fix

**Scenario**: Critical null pointer in upload service (user-facing bug)

```bash
sdlc route "null pointer exception when uploading large files"

# System classifies as BUG_FIX (confidence: 0.95)
# Gate Depth: FULL
# Stages to run: 01, 05, 07, 08, 09, 10, 11, 12, 13, 15
# Skipped: 02, 03, 04, 06, 14 (PRD review not needed for bug fix)

# Execution flow:
sdlc run 01-requirement-intake     # ✓ Intake bug report
sdlc run 05-system-design          # ✓ Design fix approach
sdlc run 07-task-breakdown         # ✓ Break into dev tasks
sdlc run 08-implementation         # ✓ Implement fix
sdlc run 09-code-review            # ✓ Review code
sdlc run 10-test-design            # ✓ Design test cases
sdlc run 11-test-execution         # ✓ Run tests
sdlc run 12-commit-push            # ✓ Commit and push
sdlc run 13-documentation          # ✓ Update docs
sdlc run 15-summary-close          # ✓ Verify closure

# Approvals required at gates: 01, 05, 07, 08, 09, 10, 11, 12, 13, 15
```

### Example 2: Config Change

**Scenario**: Update API base URL in environment config

```bash
sdlc route "update API_BASE_URL to new staging endpoint"

# System classifies as CONFIG_CHANGE (confidence: 0.98)
# Gate Depth: LITE
# Stages to run: 01, 08, 09, 12, 15
# Skipped: 02-07, 10-11, 13-14

# Execution flow:
sdlc run 01-requirement-intake     # ✓ Log change reason
sdlc run 08-implementation         # ✓ Update config file
sdlc run 09-code-review            # ✓ Verify config change
sdlc run 12-commit-push            # ✓ Commit and push
sdlc run 15-summary-close          # ✓ Verify deployed

# Approvals required at gates: 01, 15 (entry and exit only)
# Auto-approved: 08, 09, 12
```

### Example 3: Hotfix

**Scenario**: Database connection pool exhausted in production

```bash
sdlc route "production incident: db connection pool at 99%, connection timeout errors"

# System classifies as HOTFIX (confidence: 0.91)
# Gate Depth: SKIP
# Stages to run: 01, 08, 12, 15
# Skipped: 02-07, 09-11, 13-14

# Execution flow (minimal):
sdlc run 01-requirement-intake     # ✓ Log incident
sdlc run 08-implementation         # ✓ Deploy connection pool fix
sdlc run 12-commit-push            # ✓ Commit fix
sdlc run 15-summary-close          # ✓ Verify production impact resolved

# Approvals required at gates: 01, 15 only
# Auto-approved/skipped: everything else
# Note: Code review (09), testing (10-11), design review (06) bypassed
#       for speed. Incident post-mortem to review fix quality later.
```

### Example 4: UI Tweak

**Scenario**: Change button text from "Save" to "Save Profile"

```bash
sdlc route "change profile save button label to 'Save Profile' for clarity"

# System classifies as UI_TWEAK (confidence: 0.97)
# Gate Depth: LITE
# Stages to run: 01, 06, 08, 09, 10, 12, 15
# Skipped: 02-05, 07, 11, 13-14

# Execution flow:
sdlc run 01-requirement-intake     # ✓ Log change request
sdlc run 06-design-review          # ✓ Verify copy change approved
sdlc run 08-implementation         # ✓ Update button label + i18n strings
sdlc run 09-code-review            # ✓ Review change
sdlc run 10-test-design            # ✓ Verify label change renders correctly
sdlc run 12-commit-push            # ✓ Commit and push
sdlc run 15-summary-close          # ✓ Verify label live

# Approvals required at gates: 01, 15
# Design review (06) runs but auto-approves if copy is already approved
```

### Example 5: New Feature

**Scenario**: Add ability to save content to collections

```bash
sdlc route "implement saved collections feature allowing users to group content"

# System classifies as NEW_FEATURE (confidence: 0.96)
# Gate Depth: FULL
# Stages to run: 01-15 (ALL)
# Skipped: None

# Execution flow (full rigor):
sdlc run 01-requirement-intake     # ✓ Intake feature request, get user stories
sdlc run 02-prd-review             # ✓ Review PRD completeness
sdlc run 03-pre-grooming           # ✓ Pre-groom with team
sdlc run 04-grooming               # ✓ Full grooming (acceptance criteria, estimates)
sdlc run 05-system-design          # ✓ Design data model, APIs, UI
sdlc run 06-design-review          # ✓ Design review with lead
sdlc run 07-task-breakdown         # ✓ Break into sprint stories and tech tasks
sdlc run 08-implementation         # ✓ Build feature
sdlc run 09-code-review            # ✓ Code review (rigorous)
sdlc run 10-test-design            # ✓ Design comprehensive test plan
sdlc run 11-test-execution         # ✓ Full testing (unit, integration, UAT)
sdlc run 12-commit-push            # ✓ Commit and push to release branch
sdlc run 13-documentation          # ✓ Complete product docs, API docs, runbooks
sdlc run 14-release-signoff        # ✓ Stakeholder sign-off, release readiness review
sdlc run 15-summary-close          # ✓ Close feature, record learnings

# Approvals required at ALL gates: 01-15
# No stages skipped; full SDLC rigor applied
```

---

## Routing Confidence & Override Handling

### Low Confidence Classifications

If the routing agent is uncertain (confidence <0.70), system prompts:

```
⚠️ Route classification uncertain:
   Top candidates:
   1. BUG_FIX (0.65 confidence) — "Fixes existing bug"
   2. REFACTOR (0.62 confidence) — "Refactors code structure"

Which route is correct? (1/2/other):
[If user selects, system updates route and gates]
```

### User Override

Users can override automatic routing:

```bash
sdlc route "add logging to payment service" --route=REFACTOR
# Overrides auto-detected route with user-specified one

sdlc run 08-implementation --story=US-1234 --force-full-gates
# Force full gate depth even if route suggests lite
# (Audit trail: logged as user override with reason)
```

---

## Memory & State Management

### `.sdlc/memory/` Structure

Each completed stage creates a completion record:

```
.sdlc/memory/
├── stage-01-requirement-intake.json
├── stage-02-prd-review.json
├── stage-05-system-design.json
├── stage-08-implementation.json
├── stage-09-code-review.json
├── stage-10-test-design.json
├── stage-11-test-execution.json
├── stage-12-commit-push.json
├── stage-15-summary-close.json
└── routing-log.json
```

**Example Record**:
```json
{
  "stage": 8,
  "name": "implementation",
  "status": "completed",
  "completed_at": "2026-04-10T15:30:00Z",
  "completed_by": "alice.dev@example.com",
  "duration_seconds": 3600,
  "outputs": {
    "files_modified": ["src/components/Carousel.tsx", "..."],
    "commits": ["abc123def456"],
    "test_coverage": 0.78
  },
  "notes": "Implementation complete. All AC met."
}
```

### Prerequisite Checking

When a stage runs, it reads `.sdlc/memory/` to check if upstream stages completed:

```typescript
// Pseudo-code: Stage 10 checking prerequisites
const prerequisiteSages = [1, 5, 7];
const completedStages = fs.readdirSync('.sdlc/memory/')
  .filter(f => f.endsWith('.json'))
  .map(f => extractStageNumber(f));

const missingStages = prerequisiteStages.filter(
  s => !completedStages.includes(s)
);

if (missingStages.length > 0) {
  console.warn(`Prerequisite stages not completed: ${missingStages}`);
  const response = await promptUser('Continue anyway?');
  if (!response) process.exit(1);
}
```

---

## When to Use Each Route

### CONFIG_CHANGE
- Update config files (`.env`, `config.yml`, feature flags)
- Change environment variables or secrets
- Update non-code deployment settings
- **Approval**: Quick check from on-call lead

### BUG_FIX
- Fix defects in existing functionality
- Address crashes, data corruption, incorrect behavior
- Add safeguards (validation, error handling)
- **Approval**: Code review + QA sign-off required

### HOTFIX
- Production outages with customer impact (P0)
- Use ONLY for emergencies; requires incident context
- Expect post-incident review/blameless postmortem
- **Approval**: Minimal — ops approval to deploy

### UI_TWEAK
- Copy/label changes (no behavior change)
- Minor CSS adjustments (padding, colors, fonts)
- Reposition elements within existing layout
- **Approval**: Design check + code review

### REFACTOR
- Restructure code without behavior change
- Improve performance, maintainability, readability
- Extract functions, consolidate duplicates, update architecture
- **Approval**: Code review + full testing (ensure no side effects)

### NEW_FEATURE
- Add new user-visible capability
- Create new API endpoints or data models
- Introduce new workflow or interaction
- **Approval**: All stages; full product rigor

---

## Monitoring & Alerting

### Routing Health Metrics

Track classification accuracy and stage efficiency:

```
smartrouting_classification_confidence (histogram)
  - P50: 0.94, P95: 0.87 (target: >0.85)

stage_execution_time_by_route (histogram)
  - HOTFIX: avg 30 min
  - CONFIG_CHANGE: avg 45 min
  - BUG_FIX: avg 4 hours
  - NEW_FEATURE: avg 2 weeks

gate_approval_time_by_depth (histogram)
  - SKIP: avg 5 min
  - LITE: avg 15 min
  - FULL: avg 1 hour
```

### Alerts

```yaml
alerts:
  - name: high_misclassification_rate
    condition: "misclassification_pct > 10%"
    action: "Page routing team; review model drift"

  - name: stage_blocked_on_prerequisite
    condition: "user_override_prerequisite_check"
    severity: "warning"
    action: "Log for retrospective; ensure DoD enforcement"

  - name: hotfix_abuse
    condition: "hotfix_count > 3 in 24 hours"
    severity: "critical"
    action: "Page incident commander; may indicate systemic issues"
```

---

## Best Practices

1. **Use automatic routing** — Let Haiku classify; override only when confident
2. **Respect gate depth** — Don't skip gates arbitrarily; if necessary, document override reason
3. **Check prerequisites** — Don't ignore warnings about missing upstream stages
4. **Post-incident review** — After hotfixes, schedule retro to understand root cause
5. **Log overrides** — When you override routing, add context for audit trail
6. **Keep descriptions clear** — Detailed task descriptions help Haiku classify accurately
7. **Evolve routes over time** — Routes can be customized per team; start with defaults, adjust as needed

---

**Version**: 1.0  
**Last Updated**: 2026-04-10  
**Maintained By**: Platform Engineering Team
