# 📋 Sprint Story — Family Hub: Hub Creation & Invite Flow

> **Sprint 3 scope:** Hub creation, multi-channel invites, and invite acceptance flows. Member management (removal, leaving) deferred to Sprint 4.
>
> **Parent Master Story:** FH-001-master-family-hub-phase1.md

---

## 🎯 What We're Building

- **Feature/Change:** Family Hub creation flow and end-to-end invitation system including SMS/WhatsApp/Push delivery and invite acceptance
- **User Impact:** Users can create hubs and invite family members; invitees can accept/decline invites
- **Sprint Acceptance:** This sprint is done when owner can create hub, send invites via all channels, and invitee can accept/decline

---

## 🔍 Context

- **Why now:** Core foundation feature for Family Hub; blocks all other member management stories
- **What it enables:** Sprint 4 member management (removal, leaving) and storage management
- **User scenario:** Parent creates Family Hub after reaching storage limit, invites spouse and children to pool storage

---

## ⚡ Scope

### ✅ Included (This Sprint)

| # | Capability | From Master Story |
|---|------------|-------------------|
| 1 | Family Hub creation with owner assignment | Hub Creation & Management §3 |
| 2 | Invite screen with Name, Phone, Relationship, Photo fields | Multi-Channel Invitation System §2 |
| 3 | SMS + WhatsApp + Push invite delivery | Notification Matrix N1, N2, N2a |
| 4 | Universal link invite acceptance flow | Flow B - Accept Invite & Join Hub |
| 5 | Login/account creation redirect for non-logged users | Flow B §2 |
| 6 | Accept/Decline functionality with status updates | Flow B §3-4 |
| 7 | Home screen Family Hub entry point (banner/card with '+') | Sprint 3 Updates |
| 8 | Owner photo shown on invite screen (not invitee's) | Sprint 3 Updates |
| 9 | All field validations and error messages | Error Scenarios E1-E7, E9-E14 |

### 🚫 Excluded (Future Sprints)

| Capability | Reason | Target Sprint |
|------------|--------|---------------|
| Owner removes member | Requires storage quota check API | Sprint 4 |
| Member voluntarily leaves | Requires leave flow and notifications | Sprint 4 |
| Over-quota alerts | Requires storage integration | Sprint 4 |
| 90% storage warnings | Requires storage tracking | Sprint 4 |
| Owner account deletion handling | Edge case, hub survival rules | Sprint 4 |

### ⚠️ Assumptions

- Universal link setup (POD 3) completed before sprint end
- WhatsApp engine (POD 2) available for invite delivery
- Profile screen family view API available for member list

---

## 📎 PRD / Master lift *(this sprint only)*

### Notifications & Copy (Sprint Scope)

| ID | Full text | Surface | Notes |
|----|-----------|---------|-------|
| **N1** | "You have been invited to [Owner Name]'s Family Hub on JioPhotos. Join here: [invite-link]. Install JioPhotos if not already installed." | SMS | Always sent |
| **N2** | "[Owner Name] has invited you to join their Family Hub on JioPhotos. Tap to join: [invite-link]" | WhatsApp | If WA-registered |
| **N2a** | "[Owner Name] has invited you to join the Family Hub. Tap to view invite." | Push | If app installed |
| **N3** | "[Member Name] has joined the Family Hub." | Push | To existing on Accept |
| **Welcome** | "Welcome to the Family Hub!" | Toast | After Accept |

### Errors & Edge Copy (Sprint Scope)

| ID | Full text | When shown |
|----|-----------|------------|
| **E1** | "Name is required." | Inline, Name empty |
| **E3** | Input capped at 25 chars | Name >25 chars |
| **E4** | "Phone Number is required." | Inline, Phone empty |
| **E5** | Input capped at 10 digits | Invalid phone format |
| **E6** | "An invite is already pending for this number" | Duplicate pending |
| **E7** | "This user is already part of another Family Hub. A user can only belong to one family." | Invitee in another hub |
| **E9** | Send Invite button disabled | Hub at 5/5 cap |
| **E10** | "This invite has expired. Ask [Owner Name] to send a new invite." | After 15 days |
| **E11** | "Invalid invite link. Please check with the person who invited you." | Invalid/tampered URL |
| **E12** | Redirect to login | Non-logged user (non-blocking) |
| **E14** | "Install JioPhotos if not already installed" | SMS text guidance |

### Field Limits & Config (Sprint Scope)

| Field | Value |
|-------|-------|
| Name max | 25 characters |
| Phone | 10-digit Indian mobile |
| Relationships | Parent / Spouse / Child / Sibling / Other |
| Max members | 5 (including Owner) |
| Pending cap | Counts toward 5-member limit |
| Invite expiry | 15 days |

---

## 🏗️ Technical Approach

- **Architecture:** Server-side orchestration for invite lifecycle; client-side state for hub management
- **Tech choices:** Universal links for deep-linking; SMS/WhatsApp gateway integration; Push notification service
- **Integration points:** JioPhotos auth service, WhatsApp engine (POD 2), SMS gateway, Push notification service
- **Data model:** New tables: `family_hubs`, `hub_members`, `hub_invites` with status enum (Pending, Accepted, Declined, Expired)

---

## 🧾 Acceptance Criteria

### Happy Path

1. [ ] Owner can create Family Hub from home screen entry point (banner/card with '+')

2. [ ] Owner sees "Create Family Hub" CTA when no hub exists

3. [ ] Owner becomes Group Owner upon hub creation

4. [ ] Owner can access invite screen with fields: Name, Phone, Relationship, Photo

5. [ ] Invite screen validates Name (required, max 25 chars, alphanumeric + spaces)

6. [ ] Invite screen validates Phone (required, 10-digit Indian, capped at 10 digits)

7. [ ] Relationship dropdown shows: Parent, Spouse, Child, Sibling, Other

8. [ ] Photo upload is optional for invite

9. [ ] On Send Invite, SMS is always sent with N1 text

10. [ ] On Send Invite, WhatsApp is sent if phone is WA-registered (N2)

11. [ ] On Send Invite, Push is sent if app installed (N2a)

12. [ ] Invitee receives universal link that opens app directly if installed

13. [ ] Non-logged invitee is redirected to login then back to invite screen

14. [ ] Invitee sees owner photo (not own photo) on invite screen

15. [ ] Invitee can Accept invite and sees "Welcome to the Family Hub!" toast

16. [ ] On Accept, N3 sent to all existing hub members

17. [ ] Invitee can Decline (or "Decide Later") — treated as decline

18. [ ] On Decline, owner sees Declined status in member list

19. [ ] Owner can resend invite to Expired or Declined invites (new code generated)

20. [ ] Owner sees member statuses: Accepted / Pending / Expired

21. [ ] Send Invite disabled when hub at 5/5 member cap (including pending)

### Edge Cases

22. [ ] Duplicate pending invite shows E6 error: "An invite is already pending for this number"

23. [ ] Invite to user in another hub shows E7 error

24. [ ] Expired invite link (15 days) shows E10 error screen

25. [ ] Invalid/tampered invite link shows E11 error screen

26. [ ] App-not-installed flow: SMS text includes install guidance; user installs manually, clicks link again

### Quality Standards

27. [ ] Unit test coverage ≥ 70%

28. [ ] All API contracts documented

29. [ ] Accessibility: WCAG 2.1 AA compliance for invite screen

30. [ ] Error scenarios covered in automated tests

---

## 🎨 UI & design

- **Figma (primary):** USER_INPUT_REQUIRED — Design with Laxman (POD 3)
- **Master Story UI (reusing):** FH-001-master-family-hub-phase1.md §UI & design
- **Interactions covered this sprint:**
  - Home screen Family Hub entry (banner/card)
  - Hub creation flow
  - Invite form with validation
  - Invite screen (owner photo, Accept/Decline)
- **Responsive / platforms:** Android, iOS
- **Design status:** [ ] Draft  [x] In Progress  [ ] Ready for dev  [ ] N/A

---

## 🔗 Dependencies

- **Other sprints:** Sprint 2: Auth APIs ready; Sprint 3: Profile screen API
- **Data/Setup:** Feature flag `family_hub_phase1` configured
- **External:** Universal link setup (POD 3), WhatsApp engine (POD 2)
- **Blockers:** None current; Universal link setup must complete by mid-sprint

---

## 📊 How We'll Measure It

- **Primary metric (from Master):** Family Hub creation rate
- **Target this sprint:** Event instrumentation complete; 5% rollout to internal users
- **Instrumentation this sprint:** `family_hub_created`, `family_hub_invite_sent`, `family_hub_invite_accepted`, `family_hub_invite_declined` events firing
- **Baseline:** 0% (new feature)

---

## ⚠️ Known Risks

- **Technical risk:** Universal link setup (POD 3) may delay invite acceptance testing
- **Timeline risk:** WhatsApp engine (POD 2) integration may require fallback to SMS-only
- **Data risk:** Relationship field enum values not finalized for future cluster feature

---

## 👥 Team & Effort

- **Assignee:** USER_INPUT_REQUIRED
- **Design:** Laxman (POD 3)
- **QA:** USER_INPUT_REQUIRED
- **Estimated effort:** 15 days
- **Confidence:** Medium (pending external dependencies)

---

## 🚀 Definition of Done

1. [ ] Code complete and peer reviewed

2. [ ] Unit tests written and passing (≥70% coverage)

3. [ ] Acceptance criteria verified by QA

4. [ ] API contracts tested

5. [ ] Notification delivery tested (SMS, WhatsApp, Push)

6. [ ] Universal link flow tested on Android and iOS

7. [ ] Error scenarios tested

8. [ ] Documentation updated (API docs, user flows)

9. [ ] Feature flag `family_hub_phase1` toggled for controlled rollout

10. [ ] Analytics events firing correctly

---

## 📝 Notes & Updates

| Date | Note |
|------|------|
| 2026-04-21 | Sprint story created from FamilyHub_Phase 1.docx v3.1 |
| | Sprint 3 updates applied: Home screen entry point, owner photo on invite |

---

## 📋 Story Metadata

**Status:** [x] To Do  [ ] In Progress  [ ] In Review  [ ] Done  
**Sprint:** Sprint 3  
**Created:** 2026-04-21  
**Last Updated:** 2026-04-21

---

## 🔗 Traceability

**Parent Master Story:** FH-001-master-family-hub-phase1.md (ADO Feature: 865620)  
**PRD sections covered:** Flow A, Flow B (Accept), Sprint 3 Updates, Error Scenarios E1-E14
