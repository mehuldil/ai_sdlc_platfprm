# Story Hierarchy Example
**Real-world example of the 4-tier story system in action**

---

## 📊 Overview

This example shows how a feature request flows through all 4 story tiers, with specific cross-POD coordination.

**Feature:** "Batch Upload Files" — Allow users to upload multiple files at once.

---

## 1️⃣ MASTER STORY

**File:** `MS-001-batch-upload.md`  
**Created By:** Product Manager (PM)  
**Stage:** 04-grooming  
**Time Horizon:** Q2 2026 (next quarter)

```markdown
# 🧠 Master Story: Batch Upload Files

## 🎯 Outcome
- **User Outcome:** Upload 10+ files at once without clicking "upload" individually
- **Business Impact:** Reduce support tickets by 20% (file upload errors)
- **Success Metric:** ↑ from 5% to 25% of users upload in batches
- **Time Horizon:** Q2 2026

## 🔍 Problem Definition
- **Current user behavior:** Users upload files one at a time (click, wait, click, wait)
- **Pain/friction:** Uploading 20 family photos takes 5+ minutes
- **Evidence:** Support tickets show "upload is slow" as #2 complaint
- **Why this matters now:** Family storage is our #1 use case (40% of DAU)

## 👤 Target User & Context
- **Persona:** Power Users (upload 10+ files/week)
- **Trigger moment:** "I need to move my photo library to our service"
- **Environment:** Web app, Desktop (Chrome/Safari/Firefox)

## ⚡ Job To Be Done
**When** my family wants to migrate photos from Google Photos,  
**I want to** upload all 500 photos at once,  
**So I can** complete migration in 2 hours instead of 10 hours

## 💡 Solution Hypothesis
- **Core idea:** Add drag-drop multiple files. Auto-retry failed uploads. Show progress bar.
- **Why it should work:** Users expect batch operations (Gmail, Dropbox)
- **User behavior change:** Power users will upload complete libraries at once

## 🧩 Capability Definition
### Core Capability
- **User can:** "Select 100+ files and upload all at once"
- **System enables:** "Parallel upload queue, max 5 files at once"
- **System ensures:** "No duplicate uploads, atomic success/failure per file"

### Guardrails
- **Constraints:** "Max 1GB per batch", "Batch timeout 30 min"

## 🎯 Experience Intent
- **Should feel:** "Effortless, fire-and-forget"
- **Speed expectation:** "Progress updates every 2 seconds"
- **Cognitive load:** "One click: select files, then upload starts"

## 📊 Measurement & Signals
### Primary Metric
- **Name:** "Batch Upload Adoption"
- **Target:** ↑ from 5% to 25% of monthly active users
- **Observation window:** 1 month post-launch

### Secondary Signals
- **Engagement:** "Avg files per batch = 8" (vs current 1)
- **Retention:** "7-day return rate after batch upload = 70%"

## 🧪 Validation Plan
- **Experiment type:** Canary rollout (5% → 25% → 100%)
- **Success threshold:** Batch adoption >15%, error rate <2%
- **Observation window:** 2 weeks per rollout phase

## ⚠️ Risks & Unknowns
- **Adoption risk:** "Power users might not discover batch feature"
- **Behavioral uncertainty:** "Users might expect drag-drop; we offer button"
- **Dependency risk:** "Requires S3 API rate limit increase from AWS"

## 🔗 Dependencies
- **Cross-POD blockers:**
  - "POD-Storage: Must implement retry logic (currently fails on 1 error)"
  - "POD-Analytics: Event schema must include batch_id + file_count"
- **Timeline dependencies:** "POD-Auth: JWT token refresh needed for long uploads"

## 🚫 Explicit Non-Goals
- "Not building mobile-native upload (iOS/Android v2.0)"
- "Not supporting files >1GB (enterprise plan Q3)"
- "Not supporting resumable uploads (phase 2)"

## 🧾 Acceptance Criteria
### Core Flow
**Given** user has 10 files selected  
**When** user clicks "Upload All"  
**Then** all files enter upload queue and progress bar appears

### Failure Case
**Given** network connection drops mid-upload  
**When** connection restored  
**Then** failed files auto-retry (max 3x)

## 📅 Priority & Rollout Strategy
- **Priority:** P0 (drives engagement, reduces support load)
- **Rollout:** 5% (day 1) → 25% (day 3) → 100% (day 7)
- **Gate:** Error rate <2%, batch adoption >10%
```

**Validator Output:**
```bash
$ ./validators/master-story-validator.sh MS-001-batch-upload.md
Validating master story: MS-001-batch-upload.md
---
✓ Section present: 🎯 Outcome
✓ Section present: 🔍 Problem Definition
✓ Section present: 👤 Target User & Context
✓ Section present: ⚡ Job To Be Done
✓ Section present: 💡 Solution Hypothesis
✓ Section present: 🧩 Capability Definition
✓ Section present: 🎯 Experience Intent
✓ Section present: 📊 Measurement & Signals
✓ Section present: 🧪 Validation Plan
✓ Section present: ⚠️ Risks & Unknowns
✓ Section present: 🔗 Dependencies
✓ Cross-POD blockers: POD-Storage, POD-Analytics identified ✓
✓ Success metric appears quantified
✓ Acceptance criteria use Given/When/Then format
---
Validation complete: 14 passes, 0 warnings
```

---

## 2️⃣ SPRINT STORY (Child of Master)

**File:** `SS-001-batch-upload-s1.md`  
**Created By:** Tech Lead  
**Stage:** 07-sprint-planning  
**Sprint:** Sprint 5 (2-week sprint)  
**Parent:** MS-001-batch-upload

```markdown
# 📋 Sprint Story: Batch Upload Frontend — Sprint 5

Parent Master Story: MS-001-batch-upload

## 🎯 What We're Building
- **Feature/Change:** Add "Select Multiple Files" button + file queue UI
- **User Impact:** Users can now select 10+ files instead of 1
- **Sprint Acceptance:** File selector works, shows files in queue, upload starts

## 🔍 Context
- **Why now:** POD-Storage just shipped retry logic (dependency met)
- **What it enables:** Sprint 6 can build the backend queue system
- **User scenario:** "I click 'Upload Photos', browser dialog opens, I select 20 files, they appear in queue"

## ⚡ Scope
### ✅ Included
| Capability | From Master |
|------------|-------------|
| Multiple file selector | Core Capability |
| Queue display UI | Experience Intent |
| Progress indicators | Experience Intent |

### 🚫 Excluded
| Capability | Reason | Target |
|------------|--------|--------|
| Drag-drop | Design not finalized | Sprint 6 |
| Retry logic | POD-Storage owns this | Sprint 6 |
| Performance optimization | Premature | Q2 |

## 🏗️ Technical Approach
- **Architecture:** "React context for queue state, no Redux"
- **Tech choices:** "Use HTML5 file input, FileList API"
- **Integration:** "Call existing /api/upload endpoint (will be queued in Sprint 6)"

## 🧾 Acceptance Criteria
### Happy Path
- [ ] File input accepts multiple files
- [ ] Selected files display in table (name, size, status)
- [ ] "Upload" button triggers upload for each file
- [ ] Progress bar shows file upload progress
- [ ] Network error shows retry banner

### Quality Standards
- [ ] Unit tests ≥80% coverage
- [ ] Accessible (WCAG AA)
- [ ] Responsive on mobile/desktop

## 🔗 Dependencies
- **Data/Setup:** "POD-Storage retry endpoint must be live"
- **Blockers:** "Design review must approve UI (Figma link)"

## 📊 How We'll Measure It
- **Primary metric:** "Batch upload adoption (same as master)"
- **Instrumentation:** Event `file_batch_selected` with `file_count` parameter
- **Target this sprint:** "No users yet (Sprint 6 enables actual upload)"

## 👥 Team & Effort
- **Assignee:** @frontend-engineer-1
- **Design:** @design-lead
- **QA:** @qa-engineer
- **Estimated effort:** 10 days
- **Confidence:** High

## 🚀 Definition of Done
- [ ] All ACs pass
- [ ] Code reviewed + merged
- [ ] Unit tests ≥80%
- [ ] Design review approved
- [ ] Docs updated
- [ ] Feature flag enabled for internal testing
- [ ] No critical bugs
```

**Validator Output:**
```bash
$ ./validators/sprint-story-validator.sh SS-001-batch-upload-s1.md
✓ Parent Master Story linked
✓ Section present: 🎯 What We're Building
✓ Section present: 🔍 Context
✓ Section present: ⚡ Scope
✓ Scope has both IN and OUT
✓ Section present: 🧾 Acceptance Criteria
✓ Acceptance criteria use checkboxes
✓ Effort estimate reasonable: 10 days
✓ Team assigned
---
Validation complete: 8 passes, 0 warnings
```

---

## 3️⃣ TECH STORY (Parallel to Sprint Story)

**File:** `TS-001-batch-upload-queue-system.md`  
**Created By:** Architect  
**Stage:** 07-tech-design  
**Related:** SS-002-batch-upload-s2 (will use this in Sprint 6)

```markdown
# 🏗️ Tech Story: Batch Upload Queue System

Relates to Sprint Story: SS-002-batch-upload-s2 (Sprint 6)

## 🎯 Technical Goal
- **System capability:** "Process up to 50 concurrent file uploads without queue overflow"
- **Performance target:** "P95 latency <2s per file, 100 files/s throughput"
- **Reliability target:** "99.9% availability, zero data loss"

## 🔍 Current Technical State
- **Current architecture:** "Single file upload endpoint, fails if any error"
- **Bottleneck:** "No retry logic, no queue"
- **Constraints:** "S3 rate limit = 500 req/s per bucket (AWS limit)"

## 🏛️ Architecture & Design
### System Design
- **Approach:** "Job queue (Bull on Redis) + Worker pool (5 workers)"
- **Components:**
  - Express endpoint: POST /api/upload-batch → adds jobs to queue
  - Bull worker: Processes 1 file at a time, 3x retry
  - Redis: Stores job state + progress
  - S3: Backend storage
- **Data flow:** Client → API → Queue → Workers → S3
- **Failure modes:** Worker crash → job retried; Redis down → no new batches; S3 down → retry

### Technology Choices
- **Queue:** Bull.js (already used in POD-Analytics)
- **Storage:** Redis (existing production instance)
- **Async:** Node.js workers (current stack)
- **Retry:** Exponential backoff (1s, 2s, 4s)

### Integration Points
- **Upstream:** Frontend: PUT /api/upload-batch + Client-side file selection (Sprint 5)
- **Downstream:** S3 SDK, POD-Auth (JWT validation)

## 📈 Performance & Scalability
- **Load model:** "1000 concurrent batch uploads, avg 8 files per batch"
- **Data volume:** "Max 50 concurrent files = 5GB if all 100MB files"
- **Latency SLA:** "P95 <2s per file (S3 put + queue)"
- **Throughput SLA:** "100 files/second"
- **Capacity plan:** "Current Redis instance supports 10K jobs; scale Redis at 5K threshold"

## 🔒 Reliability & Resilience
- **Failure scenarios:**
  - Worker crash → Bull reschedules job, picked by another worker
  - S3 500 error → Retry with exponential backoff
  - Network timeout → Kill job after 30s, retry
- **Monitoring:** CloudWatch metrics for queue depth, retry count, failure rate
- **Alerts:** Alert if queue depth >1000, error rate >2%

## 🔄 Rollout & Rollback Plan
- **Deployment:** Blue-green (old API + new API, switch via feature flag)
- **Rollout:** 5% (internal) → 25% (beta) → 100%
- **Rollback trigger:** Error rate >2%, timeout rate >1%, queue depth stuck >5min
- **Data migration:** No DB changes, backward compatible endpoint

## 📚 Documentation
- **Runbook:** How to monitor queue health, scale Redis, restart workers
- **API contract:** POST /api/upload-batch accepts {files: File[], bucket: string}
- **Testing:** Load test with 1000 concurrent uploads, chaos test with S3 errors

## ⚠️ Technical Risks
- **Risk:** "S3 rate limits at 500 req/s, we're pushing 100 files/s"
- **Mitigation:** "Request rate limit increase to 1000 req/s from AWS"
```

---

## 4️⃣ TASKS (Children of Sprint Story)

**Created By:** Engineer  
**Stage:** 07-08 (daily work)

### Task 1: Backend File Upload Queue Setup

```markdown
# ✅ Task: Setup Bull Queue Infrastructure

Sprint Story: SS-002-batch-upload-s2  
Tech Story: TS-001-batch-upload-queue-system

## 🎯 What's the Task?
- **Do this:** Create Bull queue configuration, Redis connection, test queue operations
- **Why:** Enables workers to process batch uploads in Sprint 6
- **Definition of Done:** Queue accepts jobs, worker processes them, Redis stores state

## 📋 Acceptance Criteria
- [ ] Bull queue initialized, connects to Redis
- [ ] Queue processes 10+ jobs without errors
- [ ] Job state persists in Redis
- [ ] Retry logic works (test 3x retry)
- [ ] Queue depth metric exported to CloudWatch
- [ ] Unit tests ≥90% coverage

## 🏗️ Implementation Notes
- **Approach:** "Use bull npm package, existing Redis connection"
- **Files:** "src/queue/upload-queue.js", "src/workers/upload-worker.js"
- **Dependencies:** bull, redis, dotenv
- **Estimated time:** 4 hours

## 📊 How We Know It Works
- [ ] Manual test: Send 10 jobs, verify all complete
- [ ] Automated: Unit tests pass, coverage >90%
- [ ] Staging: Queue processes 100 jobs without memory leak
```

### Task 2: Frontend File Queue UI

```markdown
# ✅ Task: Build File Queue Display Component

Sprint Story: SS-001-batch-upload-s1  
Tech Story: TS-001 (related)

## 🎯 What's the Task?
- **Do this:** React component showing selected files (name, size, progress, status)
- **Why:** UX shows what's uploading, gives user feedback
- **Definition of Done:** Component renders queue, updates as uploads progress

## 📋 Acceptance Criteria
- [ ] Component displays file list (name, size, status icons)
- [ ] Status icons: pending (gray), uploading (blue), done (green), error (red)
- [ ] Progress bar shows per-file progress
- [ ] Error message appears for failed files
- [ ] Responsive on mobile (single column)
- [ ] Unit tests ≥85% coverage
- [ ] Accessibility: WCAG AA compliant

## 🏗️ Implementation Notes
- **Approach:** "React hooks (useState, useContext for queue state)"
- **Files:** "src/components/FileQueueList.tsx"
- **Dependencies:** React, react-icons
- **Estimated time:** 6 hours

## 📊 How We Know It Works
- [ ] Manual: Select 10 files, see them in queue, upload starts
- [ ] Staging: Component renders without errors on Chrome/Safari/Firefox
- [ ] Accessibility: axe-core scan passes
```

---

## 🔗 HIERARCHY VALIDATION

```bash
$ ./validators/story-hierarchy-validator.sh \
  MS-001-batch-upload.md \
  SS-001-batch-upload-s1.md \
  SS-002-batch-upload-s2.md

Validating story hierarchy
---
✓ Master story found: MS-001-batch-upload.md
✓ Master story metric: ↑ from 5% to 25% of users upload in batches
Checking sprint story: SS-001-batch-upload-s1.md
  ✓ Links to parent master story
  ✓ Metric aligned with master story
Checking sprint story: SS-002-batch-upload-s2.md
  ✓ Links to parent master story
  ✓ Metric aligned with master story
---
Validation complete: 5 passes, 0 warnings
```

---

## 📊 SUMMARY

| Tier | What | Who | When |
|------|------|-----|------|
| **Master Story** | Outcome, problem, solution | PM | 04-grooming (1 week before sprint) |
| **Sprint Story** (2x) | Executable slices | Tech Lead + PM | 07-sprint-planning (start of sprint) |
| **Tech Story** (1x) | Architecture, performance, ops | Architect | 07-tech-design (parallel to sprint planning) |
| **Tasks** (6x) | Atomic work units | Engineers | 07-08 (daily work) |

**Flow:**
```
Master Story (MS-001)
  ├─ Sprint Story 1 (SS-001) — Frontend UI [Sprint 5]
  │   ├─ Task: Setup Queue (4h) @backend-eng
  │   └─ Task: Build UI (6h) @frontend-eng
  │
  ├─ Sprint Story 2 (SS-002) — Backend Queue [Sprint 6]
  │   ├─ Task: Workers (8h) @backend-eng
  │   └─ Task: Error Handling (4h) @backend-eng
  │
  └─ Tech Story (TS-001) — Architecture [Design phase]
      └─ Consulted during both sprints
```

---

## ✅ What This Example Shows

1. **Clear hierarchy:** Each tier has specific purpose, audience, timing
2. **Cross-POD coordination:** Master story explicitly lists POD blockers
3. **Optional rigor:** Templates don't prevent creation, validators just warn
4. **Backward compatibility:** Old and new systems work side-by-side
5. **Measurable outcomes:** Success metrics are quantified at every level
6. **Execution clarity:** Tasks are atomic, estimated, and assigned upfront

