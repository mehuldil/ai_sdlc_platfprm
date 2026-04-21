# 📋 Sprint Story — Family Hub: Member Management & Storage Alerts

> **Sprint 4 scope:** Owner member removal, voluntary member exit, storage quota alerts, and complete notification matrix implementation.
>
> **Parent Master Story:** FH-001-master-family-hub-phase1.md
> **Depends on:** FH-001-S01-sprint-hub-creation-invite.md (Sprint 3)

---

## 🎯 What We're Building

- **Feature/Change:** Member management capabilities (owner removal, self-exit), storage quota enforcement, and over-quota alerts
- **User Impact:** Owners can manage hub membership; members can leave voluntarily; storage accountability maintained on exit
- **Sprint Acceptance:** This sprint is done when owner can remove members, members can leave, and storage alerts work correctly

---

## 🔍 Context

- **Why now:** Depends on Sprint 3 hub creation and invite acceptance; completes Phase 1 member lifecycle
- **What it enables:** Full Family Hub membership management; storage governance; foundation for Phase 2 photo sharing
- **User scenario:** Adult child leaves Family Hub when moving out; owner removes inactive member to make room for new invite

---

## ⚡ Scope

### ✅ Included (This Sprint)

| # | Capability | From Master Story |
|---|------------|-------------------|
| 1 | Owner removes member with confirmation | Flow D — Owner Removes Member |
| 2 | Removal notifications (Push + WhatsApp) | N7, N8 |
| 3 | Member voluntarily leaves hub | Flow E — Member Voluntarily Leaves |
| 4 | Leave confirmation and self-exit | E19 |
| 5 | Member left notifications to remaining | N9 |
| 6 | Storage quota check on removal/exit | Storage & Membership S5 |
| 7 | Over-quota alert (>50GB) | N10 |
| 8 | Mandatory cleanup/upgrade screen | E20 |
| 9 | 90% storage warning banner | N11, S2 |
| 10 | Storage almost full reappearing banner | S2 |
| 11 | Owner delete account hub handling | S6, N14 |
| 12 | Owner view: individual member storage | R15 |
| 13 | Member view: total storage only, no breakdown | R14 |

### 🚫 Excluded (Future Sprints)

| Capability | Reason | Target Sprint |
|------------|--------|---------------|
| Hub ownership transfer | Not in Phase 1 scope | Phase 2 |
| Re-invite after removal | Requires invite system update | Phase 2 |
| Storage rebalancing on exit | Complex quota logic | Phase 2 |
| Family photo sharing | Phase 2 core feature | Phase 2 |
| Family memories/clusters | Data collected, not used | Phase 3 |

### ⚠️ Assumptions

- Sprint 3 hub creation and invite acceptance complete
- Storage service APIs available for quota checks
- Profile screen family view (POD 3) complete with member storage breakdown

---

## 📎 PRD / Master lift *(this sprint only)*

### Notifications & Copy (Sprint Scope)

| ID | Full text | Surface | Trigger |
|----|-----------|---------|---------|
| **N7** | "You have been removed from the Family Hub by [Owner]." | Push | On removal |
| **N8** | "[Owner] removed you from the Family Hub on JioPhotos." | WhatsApp | On removal (if WA-registered) |
| **N9** | "[Member Name] has left the Family Hub." | Push | On self-exit |
| **N10** | "Your storage is [X] GB — over your 50 GB limit. Clean up or upgrade your plan." | Push + WhatsApp | With removal (if >50GB) |
| **N11** | "Storage almost full ([X]% used). Free space or upgrade." | Banner | On app open (≥90%) |
| **N14** | "Family Hub owner has left, so the shared storage pool isn't available right now." | Push | Owner deletes account |
| **Removal Confirm** | "Remove [Name] from Family Hub?" | Dialog | Owner taps Remove |
| **Leave Confirm** | "Leave Family Hub? Your personal library is unaffected." | Dialog | Member taps Leave |

### Errors & Edge Copy (Sprint Scope)

| ID | Full text | When shown |
|----|-----------|------------|
| **E19** | Remove option not shown | Owner tries to remove self |
| **E20** | Over-quota alert + mandatory cleanup screen | Removed/left member >50GB |
| **Over-quota Screen** | "Manage Storage" \| "Upgrade Plan" buttons | Mandatory on next app open |

### Storage Rules (Sprint Scope)

| Rule | Value |
|------|-------|
| Default storage limit | 50 GB |
| Over-quota threshold | >50 GB |
| Warning threshold | ≥90% capacity |
| Warning frequency | Reappears every 24h after dismiss |
| Storage on exit | Stays on leaving/removed member's quota |

---

## 🏗️ Technical Approach

- **Architecture:** Server-side storage quota check on removal/exit; client-side banner management for warnings
- **Tech choices:** Background job for storage calculation; scheduled reappearing banner logic
- **Integration points:** Storage service API, Push notification service, WhatsApp engine (POD 2)
- **Data model:** Updates to `hub_members` status; storage audit log for quota tracking

---

## 🧾 Acceptance Criteria

### Happy Path — Owner Removal

1. [ ] Owner can view Hub Settings → Member List with all active members

2. [ ] Owner sees member details: name, avatar, join date, individual storage usage

3. [ ] Owner taps member → "Remove from Hub" option appears

4. [ ] Remove option NOT shown for Owner's own profile (E19)

5. [ ] Owner sees confirmation dialog: "Remove [Name] from Family Hub?"

6. [ ] On confirm, member access revoked instantly

7. [ ] N7 Push sent to removed member: "You have been removed from the Family Hub by [Owner]."

8. [ ] N8 WhatsApp sent if removed member has WA-registered number

9. [ ] Removed member redirected to JioPhotos profile/storage screen on next app open

### Happy Path — Member Self-Exit

10. [ ] Member sees Family Hub screen with: own JioPhotos profile name, owner-added photo, storage usage, Leave option

11. [ ] Member CANNOT see: individual member storage breakdown, member management, invite/remove options

12. [ ] Member taps "Leave Family Hub" → confirmation dialog: "Leave Family Hub? Your personal library is unaffected."

13. [ ] On confirm, access revoked, personal library untouched

14. [ ] N9 Push sent to all remaining members + Owner: "[Member Name] has left the Family Hub."

### Storage Alerts & Quota

15. [ ] When member removed/left with storage >50GB, N10 sent: "Your storage is [X] GB — over your 50 GB limit. Clean up or upgrade your plan."

16. [ ] On next app open, removed/left member sees mandatory cleanup/upgrade screen

17. [ ] Mandatory screen has "Manage Storage" and "Upgrade Plan" buttons

18. [ ] Access blocked until storage ≤50GB or plan upgraded

19. [ ] When member's storage ≥90%, banner shown: "Storage almost full ([X]% used). Free space or upgrade."

20. [ ] Banner is dismissible but reappears every 24h until below 90%

21. [ ] Banner shown on JioPhotos home and inside Family Hub

### Owner View vs Member View

22. [ ] Owner sees: all members with names, individual storage usage, invite/remove options, hub settings

23. [ ] Member sees: own JioPhotos profile name (not owner-entered), owner-added photo, total family storage, Leave option

24. [ ] Member does NOT see: individual member storage, invite/remove, member management

### Owner Account Deletion

25. [ ] If owner deletes JioPhotos account, hub enters degraded state

26. [ ] N14 Push sent to all members: "Family Hub owner has left, so the shared storage pool isn't available right now."

### Edge Cases

27. [ ] Owner tries to remove self → Remove option not available (E19)

28. [ ] Removed member with exactly 50GB → No over-quota alert

29. [ ] Removed member with 50.1GB → Over-quota alert and mandatory screen

30. [ ] Member at 89% storage → No warning banner

31. [ ] Member at 90% storage → Warning banner appears

### Quality Standards

32. [ ] Unit test coverage ≥ 70%

33. [ ] Storage quota calculation accurate within 1%

34. [ ] All notification scenarios tested

35. [ ] Mandatory screen blocks access correctly

36. [ ] Banner reappears correctly after 24h

---

## 🎨 UI & design

- **Figma (primary):** USER_INPUT_REQUIRED — Profile screen family view with Laxman (POD 3)
- **Master Story UI (reusing):** FH-001-master-family-hub-phase1.md §UI & design
- **New screens this sprint:**
  - Member List with storage breakdown (owner view)
  - Member view (total storage only, Leave option)
  - Mandatory cleanup/upgrade screen
  - Storage warning banner (reappearing)
- **Responsive / platforms:** Android, iOS
- **Design status:** [ ] Draft  [x] In Progress  [ ] Ready for dev  [ ] N/A

---

## 🔗 Dependencies

- **Other sprints:** Sprint 3: FH-001-S01 (hub creation, invites) must be complete
- **Data/Setup:** Storage service APIs ready; Feature flag `family_hub_phase1_storage` configured
- **External:** Storage quota service, WhatsApp engine (POD 2)
- **Blockers:** None current; Profile screen API must be ready by sprint start

---

## 📊 How We'll Measure It

- **Primary metric (from Master):** Member retention after removal/exit
- **Target this sprint:** 25% rollout to production; storage alert accuracy >95%
- **Instrumentation this sprint:** `family_hub_member_removed`, `family_hub_member_left`, `family_hub_storage_alert_triggered` events firing
- **Baseline:** Sprint 3 internal metrics

---

## ⚠️ Known Risks

- **Technical risk:** Storage service API latency may affect removal flow performance
- **Timeline risk:** Mandatory screen design (POD 3) may delay implementation
- **Data risk:** Storage calculation accuracy across edge cases (exactly 50GB, exactly 90%)

---

## 👥 Team & Effort

- **Assignee:** USER_INPUT_REQUIRED
- **Design:** Laxman (POD 3)
- **QA:** USER_INPUT_REQUIRED
- **Estimated effort:** 12 days
- **Confidence:** High (builds on Sprint 3 foundation)

---

## 🚀 Definition of Done

1. [ ] Code complete and peer reviewed

2. [ ] Unit tests written and passing (≥70% coverage)

3. [ ] Acceptance criteria verified by QA

4. [ ] Storage quota calculations tested

5. [ ] Notification delivery tested (Push, WhatsApp)

6. [ ] Mandatory screen flow tested

7. [ ] Banner reappearing logic tested

8. [ ] Owner vs Member view permissions tested

9. [ ] Documentation updated

10. [ ] Feature flag toggled for 25% rollout

11. [ ] Analytics events firing correctly

12. [ ] Rollback plan documented

---

## 📝 Notes & Updates

| Date | Note |
|------|------|
| 2026-04-21 | Sprint story created; depends on Sprint 3 completion |
| | Member Details API required from backend |

---

## 📋 Story Metadata

**Status:** [x] To Do  [ ] In Progress  [ ] In Review  [ ] Done  
**Sprint:** Sprint 4  
**Created:** 2026-04-21  
**Last Updated:** 2026-04-21

---

## 🔗 Traceability

**Parent Master Story:** FH-001-master-family-hub-phase1.md (ADO Feature: 865620)  
**Depends on Sprint:** FH-001-S01-sprint-hub-creation-invite.md (ADO User Story: 865621)  
**PRD sections covered:** Flow D, Flow E, Notification Matrix N7-N11, N14, Error E19-E20, Storage & Membership S2, S5-S6, Rules R14-R16
