# End-to-End Testing: Complete SDLC Workflow

This guide walks through a complete feature delivery using the AI-SDLC Platform Plugin in IDE chat.

**Scenario**: Building "Multi-Language Signup Support" feature for a SaaS application

**Estimated Time**: 30 minutes (to walk through all 15 stages)

**Actual SDLC Time**: 2-3 hours (automation coordination only)

---

## Stage 1: Requirement Intake (5 min)

### What You Do
In IDE chat, describe what you want to build:

```
User: I want to add multi-language support to our signup flow. 
We need to support 5 languages initially: English, Spanish, French, 
German, and Chinese. The goal is to increase signup conversion in 
non-English markets by 25% within Q2.
```

### What Plugin Does
```
Claude: 📋 Requirement Intake & Work Item Creation

What are we building?
  [1] New feature (user-facing capability)
  [2] Bug fix (defect resolution)
  [3] Technical task (refactor, tooling)
  [4] Epic (large initiative)

User: [1]

✅ UNDERSTANDING:
  • Type: Feature
  • Scope: Signup flow internationalization
  • Language support: 5 languages (EN, ES, FR, DE, ZH)
  • Success metric: 25% conversion increase

❓ MISSING INFORMATION:

1. Target markets & timelines?
   Need: Which markets by when?

2. Phase 1 scope?
   Need: All languages simultaneously or phased?

3. Analytics tracking?
   Need: Which events to track per language?

Next?
  [1] Answer questions now
  [2] Skip questions (fill later)
  [3] Upload PRD document
  [4] Cancel

User: [1]

📝 Target markets?
User: "USA, Spain, France, Germany, China - all in Q2"

📝 Phase 1 or all languages?
User: "Phase 1: Just backend + API in Q2, frontend in Q3"

📝 Analytics events?
User: "signup_initiated, otp_sent, signup_completed with language field"

✓ Captured all details.

CREATE WORK ITEM?
  [1] Create Epic + Master Story
  [2] Create as single User Story
  [3] Review & edit before creating
  [4] Cancel

User: [1]

✓ Created Epic AB#12345 (Multi-language signup)
✓ Created Master Story AB#12346
✓ Linked parent: AB#12345
✓ Tagged: claude:generated, ready:pre-grooming
✓ Saved to .sdlc/memory/requirement-intake-AB#12345.json

📊 SUMMARY:
Epic: AB#12345 — Multi-language signup support
Master Story: AB#12346 — Phase 1: Backend + API
Team: Backend (2 eng), Frontend (2 eng), QA (1 eng)
Estimated effort: 3 sprints
Success metric: 25% conversion increase
```

### Output
- **ADO Epic**: AB#12345 (Multi-language signup support)
- **ADO Master Story**: AB#12346 (Phase 1: Backend + API)
- **Memory**: `.sdlc/memory/requirement-intake-AB#12345.json`

---

## Stage 2: PRD Review (10 min)

### What You Do
```
User: /project:prd-review AB#12345 --role=backend
```

### What Plugin Does
```
Claude: 🎯 PRD Review & Gap Analysis (Backend perspective)

✅ COMPLETE SECTIONS:
  • Goals & success metrics ✓
  • User personas ✓
  • Feature scope ✓
  • Analytics plan ✓

⚠️ GAPS (Backend perspective):

1. Missing: API Contract Details (BLOCKING)
   Impact: Can't start architecture, design APIs
   Fix: Define REST endpoints + schemas for:
     - POST /auth/signup/initiate
     - POST /auth/signup/verify-otp
     - GET /i18n/language-packs
   Priority: BLOCKING

2. Unclear: Language Pack Distribution (BLOCKING)
   Need: Decision on CDN vs database vs app bundles
   Impact: Affects data model and deployment
   Fix: Choose strategy + document in PRD
   Priority: BLOCKING

3. Missing: RTL Language Support (MAJOR)
   Need: How to handle right-to-left languages (Arabic, Hebrew)?
   Note: Chinese, German don't need RTL, but future languages might
   Fix: Document RTL requirements
   Priority: MAJOR

4. Missing: Fallback Strategy (MAJOR)
   Need: What happens if language pack fails to load?
   Impact: Error handling, user experience
   Fix: Define fallback to English + error message
   Priority: MAJOR

5. Partial: Database Schema (MINOR)
   Current: "user profile stores language preference"
   Need: More specifics on multilingual content storage
   Fix: Include example schema
   Priority: MINOR

BLOCKING items: 2 (need PM action before proceeding)
MAJOR items: 2 (add to PRD or handle in design)
MINOR items: 1 (nice to have, can refine)

Next?
  [1] Create tasks for PM to fill gaps
  [2] Post feedback as comment
  [3] Proceed anyway (risky)
  [4] Cancel

User: [1]

Creating blocking tasks...
✓ Task AB#12347: "Define API contract for signup endpoints"
✓ Task AB#12348: "Decide language pack distribution strategy"
✓ Linked both as blockers for AB#12346

Creating major discussion tasks...
✓ Task AB#12349: "Design RTL language support"
✓ Task AB#12350: "Document language pack fallback strategy"

✓ Marked story AB#12346 as blocked:prd-review

GATE G1 STATUS: ⚠️ INCOMPLETE
Blocking gaps: 2 items
Action: PM to address AB#12347-AB#12350 before proceeding

[5 minutes later...]

PM: I've updated the PRD with API contract and language pack strategy

User: /project:prd-review AB#12345 --role=backend

Claude: 🎯 PRD Review (Re-check)

✅ ALL SECTIONS COMPLETE
  • API contract defined (OpenAPI) ✓
  • Language pack strategy: CDN-served bundles ✓
  • Database schema included ✓
  • RTL strategy documented ✓
  • Fallback strategy defined ✓

GATE G1: ✅ READY FOR GROOMING

All gaps resolved. Story ready for grooming phase.

✓ Removed blocked:prd-review tag
✓ Added tag: ready:pre-grooming
```

### Output
- **Gap Report**: Posted to ADO story comment
- **Blocking Tasks**: AB#12347-AB#12350 (for PM to resolve)
- **Memory**: `.sdlc/memory/prd-review-AB#12345.md`

---

## Stage 3: Story Grooming (10 min)

### What You Do
```
User: /project:grooming AB#12346 --type=master
```

### What Plugin Does
```
Claude: 🎯 Story Breakdown & Grooming

✅ LOADED MASTER STORY:
  Story: Multi-language signup - Phase 1 (Backend API)
  PRD sections: API contract + schema design
  Success metrics: >99.9% availability, P95 <200ms latency

📊 MASTER STORY BREAKDOWN:

Breaking into 3 feature areas (each becomes sprint story):

1. Backend Infrastructure
   • Service setup + dependency injection
   • Database + ORM configuration
   • i18n service setup
   Estimate: 13 points

2. Phone Verification API
   • POST /signup/initiate (phone validation)
   • POST /signup/verify-otp (OTP validation)
   • Database transactions
   Estimate: 8 points

3. Language Pack Management
   • Language list API
   • i18n bundle generation
   • CDN integration
   Estimate: 5 points

TOTAL: 26 story points
Capacity per sprint: 13-16 points
Timeline: 2 sprints

Create Master Story with AC?
  [1] Yes, create it
  [2] Preview AC first
  [3] Cancel

User: [1]

✅ GENERATED MASTER STORY: AB#12346

Acceptance Criteria:

AC-01: Backend infrastructure complete
  Given: Empty Java project with Spring Boot
  When: Configure Spring, JPA, PostgreSQL
  Then: All dependencies resolved, app starts without errors

AC-02: Database schema migrated
  Given: Migration tool installed
  When: Run V001__initial_schema.sql
  Then: All tables created (users, user_localization, language_bundles)

AC-03: Language list API working
  Given: CDN language pack URL configured
  When: Call GET /api/languages
  Then: Returns {languages: [{code, name, native_name}, ...]}

AC-04: Phone signup flow end-to-end
  Given: Phone validation + OTP service + user database
  When: Simulate signup (phone → OTP → verify → user created)
  Then: User created with language preference stored

... (8 more AC, all documented)

Success Metrics:
  • API P95 latency <200ms (production target)
  • Availability >99.9% (SLA target)
  • Support 1000 RPS (load test target)

Dependencies:
  • External: Twilio API (OTP delivery)
  • External: CDN (language pack hosting)
  • Internal: ExampleIdentity service (optional, for future SSO)

BREAKING INTO SPRINT STORIES:

Sprint Story 1: Backend Infrastructure Setup
  Points: 5
  AC subset: AC-01, AC-02
  Tasks: Service setup, DB config, dependency injection

Sprint Story 2: Phone Verification API
  Points: 8
  AC subset: AC-03, AC-04
  Tasks: Implement endpoints, add error handling, unit tests

Sprint Story 3: Language Pack Integration
  Points: 5
  AC subset: AC-05 (i18n service)
  Tasks: CDN integration, language selection, fallback

✓ Created Master Story AB#12346 with 16 AC
✓ Created Sprint Story 1: AB#12351 (5 points)
✓ Created Sprint Story 2: AB#12352 (8 points)
✓ Created Sprint Story 3: AB#12353 (5 points)
✓ All linked to parent Epic AB#12345
✓ Tagged: grooming:done, ready:sprint

GATE G3: ✅ GROOMING COMPLETE
Ready for architecture review → sprint planning
```

### Output
- **Master Story**: AB#12346 with 16 acceptance criteria
- **Sprint Stories**: AB#12351, AB#12352, AB#12353 (total 18 points, fits sprint 12-16 point capacity)
- **Memory**: `.sdlc/memory/grooming-AB#12346.json`

---

## Stages 4-5: Architecture & System Design (10 min)

### What You Do
```
User: /project:architecture-review AB#12352 --role=backend
User: /project:system-design AB#12352 --role=backend
```

### What Plugin Does
```
Claude: 🏗️ Architecture Review

Asks role-specific questions:
  1. OTP delivery: Twilio vs in-app vs hybrid?
  2. Language storage: Database vs CDN vs both?
  3. Database design: Monolithic user table vs normalized?
  4. API sync: Sync REST vs async event-driven?

[User selects options based on architecture decisions...]

✓ Created 3 ADRs (Architecture Decision Records):
  - ADR-001: OTP Provider Strategy
  - ADR-002: i18n Distribution (CDN)
  - ADR-003: API Synchronicity

```

### Output
- **ADRs**: Architecture decisions documented
- **OpenAPI Spec**: REST endpoints (OpenAPI 3.1 format)
- **Data Model**: ER diagram + SQL migrations

---

## Stages 6-9: Development & QA (10 min simulation)

### What You Do
```
User: /project:sprint-planning AB#12352 --sprint=12
User: /project:implementation AB#12352
User: /project:code-review --pr=2456
User: /project:test-design AB#12352
```

### What Plugin Does
```
✓ Sprint planning: Creates 11 tasks (backend, frontend, QA)
✓ Implementation: Provides code templates + guidance
✓ Code review: Checks PR against 15-point checklist
✓ Test design: Creates 18 test cases (unit, integration, E2E)
```

### Output
- **Sprint Board**: 11 tasks assigned to team
- **Code Templates**: Boilerplate for signup service
- **Test Matrix**: Complete coverage map

---

## Stages 10-15: Validation, Release & Production (5 min simulation)

### What You Do
```
User: /project:staging-validation AB#12352
User: /project:release-prep AB#12352 --version=1.0.0
User: /project:deployment AB#12352 --version=1.0.0 --canary=5%
User: /project:monitoring AB#12352
```

### What Plugin Does
```
✓ Staging: Deploys to staging, runs tests, gets sign-offs
✓ Release prep: Verifies compliance (SAST, DAST, SCA), creates release notes
✓ Deployment: Deploys to production with canary (5% → 25% → 100%)
✓ Monitoring: Sets up alerts + runbooks for common issues
```

### Output
- **Validation Report**: Test results + approvals
- **Release Notes**: Customer-facing summary
- **Deployment Record**: Canary rollout completed
- **Monitoring Dashboard**: CloudWatch dashboard + 8 alerts

---

## Complete Workflow Results

After 30 minutes of interactive prompts and decisions:

### ADO Work Items Created
- Epic AB#12345: Multi-language signup support
- Master Story AB#12346: Phase 1 backend
- Sprint Stories: AB#12351-AB#12353
- 11 development tasks (backend, frontend, QA)
- 5 PRD gap tasks (resolved by PM)
- 3 ADRs (architecture decisions)

### Artifacts Generated
- Grooming notes (16 AC, success metrics, dependencies)
- Architecture decisions (3 ADRs)
- Data model (ER diagram, SQL migrations)
- OpenAPI specification (6 endpoints documented)
- Sprint plan (11 tasks, team assignments, 18-point total)
- Code templates (signup service boilerplate)
- Test matrix (18 test cases, Gherkin format)
- Performance results (load test: P95 180ms, 1050 RPS)
- Release notes (4-page document)
- Monitoring setup (8 alerts, 3 runbooks)

### Memory Persisted
All stage outputs saved in `.sdlc/memory/`:
- requirement-intake-AB#12345.json
- prd-review-AB#12345.md
- grooming-AB#12346.json
- architecture-review-AB#12352.md
- system-design-AB#12352.yaml (OpenAPI)
- sprint-planning-AB#12352.json
- performance-testing-AB#12352.json
- deployment-AB#12352.md

### Automation Value

**Without Plugin:**
- 40-60 hours of manual coordination
- 5-10 back-and-forth sessions with PM
- 8-12 hours finding templates + examples
- 2-3 hours creating test matrix from scratch
- 1-2 hours writing deployment runbook

**With Plugin:**
- 30 minutes of interactive prompts
- Decisions captured immediately in ADO
- Templates auto-generated
- Test matrix auto-created
- Runbooks auto-generated
- Memory persists across sessions

**Time Saved**: 48-80 hours of coordination overhead

---

## Verification Checklist

After running through complete workflow, verify:

- [ ] ADO epic created with correct tags
- [ ] Master story has 16+ acceptance criteria
- [ ] Sprint stories fit sprint capacity (13-21 points)
- [ ] Architecture decisions documented (3+ ADRs)
- [ ] OpenAPI spec covers all endpoints
- [ ] Data model includes migrations
- [ ] Sprint board shows 11+ tasks
- [ ] Code review found 0 blocking issues
- [ ] Test matrix covers happy path + edge cases
- [ ] Performance test passed (P95 <200ms)
- [ ] Staging validation approved by QA + PM
- [ ] Release notes published
- [ ] Deployment completed (canary 5% → 100%)
- [ ] Monitoring alerts active
- [ ] All memory files saved in .sdlc/memory/

---

## Troubleshooting Test Workflow

### Issue: ADO Connection Failed
**Fix**: Verify `ADO_PAT` and organization name in `env/.env`

### Issue: Memory Not Loading
**Fix**: Check story ID matches ADO work item (e.g., AB#12352)

### Issue: Some Stages Skipped
**Fix**: Run them explicitly with correct story ID:
```
/project:prd-review AB#12345
/project:grooming AB#12346 --type=master
```

### Issue: Test Cases Not Generated
**Fix**: Ensure acceptance criteria are clear before running test-design

---

## Next Steps

After validating complete workflow:

1. **Real Project**: Run same steps on your actual project
2. **Team Training**: Share workflow examples with team
3. **Customize**: Create custom workflows for your process
4. **Expand**: Use Stage 15 (incident response) for production issues
5. **Monitor**: Use monitoring dashboard for ongoing tracking

---

## Questions?

- See `README.md` for full documentation
- Run `/project:help` in IDE chat for quick reference
- Check troubleshooting section above
- Create GitHub issue for bugs

Happy automating! 🚀
