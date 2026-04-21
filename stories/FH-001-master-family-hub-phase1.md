# 🧠 Master Story — Family Hub Phase 1

> **ADO completeness:** Self-contained work item with all PRD-sourced specifics (notifications, errors, field limits) so engineers don't need to open the PRD.
>
> **PRD Source:** `FamilyHub_Phase 1.docx` (v3.1)

---

## 🎯 Outcome

- **User Outcome:** JioPhotos users can create a private Family Hub, invite up to 4 family members, and manage shared storage with clear membership controls
- **Business Impact:** Increase user engagement through family network effects; drive storage plan upgrades via pooled family storage
- **Success Metric:** 30% of eligible users create a Family Hub within 3 months of launch; 60% invite rate among hub creators
- **Time Horizon:** Q2 2026 (Sprint 3-4)

---

## 🔍 Problem Definition

- **Current user behavior:** Users share photos via external channels (WhatsApp, SMS) losing organization and privacy
- **Pain / friction:** No centralized way for families to pool storage and manage photo sharing permissions
- **Evidence:** User research shows 70% of JioPhotos users share photos with family members regularly; storage quota complaints from multi-device households
- **Why this matters now:** Market opportunity for family-centric photo management; competitive feature parity needed

---

## 👤 Target User & Context

- **Persona:** Primary JioPhotos users (age 25-55) who manage family photos and want to share storage with spouses, parents, children
- **Trigger moment:** User reaches storage limit or wants to share photos with family members
- **Environment:** JioPhotos mobile app (Android/iOS), home screen Family Hub entry point

---

## ⚡ Job To Be Done (JTBD)

**When** I am managing family photos across multiple devices and users,
**I want to** create a centralized family space with shared storage and controlled access,
**So they can** securely share photos, pool storage resources, and manage family memories in one place

---

## 💡 Solution Hypothesis

- **Core idea:** A Family Hub feature allowing one owner to create a private hub, invite up to 4 members via multi-channel invites (SMS/WhatsApp/Push), with owner-controlled membership and individual storage accountability
- **Why it should work:** Universal links simplify invite acceptance; owner-controlled membership ensures trust; storage stays with members upon exit reducing disputes
- **User behavior change expected:** Users will invite family members within 7 days of hub creation; 80% of invites accepted within 15 days

---

## 🧩 Capability Definition

### Core Capabilities

1. **Hub Creation & Management**
   - User can create Family Hub (becomes Owner)
   - Owner can view member list with statuses
   - Max 5 members including Owner

2. **Multi-Channel Invitation System**
   - Owner can invite via: Name (max 25 chars), Phone (10-digit Indian), Relationship dropdown, Optional photo
   - Invites sent via SMS + WhatsApp (if registered) + Push (if app installed)
   - Universal link for invite acceptance
   - 15-day invite expiry with resend option

3. **Member Lifecycle Management**
   - Invitee can accept/decline invite (requires login)
   - Owner can remove members
   - Members can voluntarily leave
   - Re-invite support for removed/declined members

4. **Notification System**
   - Multi-channel delivery: Push (in-app), SMS, WhatsApp
   - Channel logic: SMS+WhatsApp+Push for invites; Push for in-app events; WhatsApp courtesy for removal

5. **Storage Management**
   - Individual storage quotas remain with members
   - 90% capacity warnings (banner, reappears every 24h)
   - Over-quota alerts for removed members (>50GB)

### Guardrails

- **System must prevent:** Multiple hub membership (one family per user), owner self-removal, duplicate pending invites
- **Constraints:** Max 5 members per hub; 15-day invite expiry; 25-character name limit; 10-digit phone validation

---

## 📎 PRD-sourced specifics

### Notifications & User-Visible Copy

| ID | User-visible text | Surface | Trigger |
|----|-------------------|---------|---------|
| **N1 - Invite SMS** | "You have been invited to [Owner Name]'s Family Hub on JioPhotos. Join here: [invite-link]. Install JioPhotos if not already installed." | SMS | Immediate on invite |
| **N2 - Invite WhatsApp** | "[Owner Name] has invited you to join their Family Hub on JioPhotos. Tap to join: [invite-link]" | WhatsApp | Immediate (if WA-registered) |
| **N2a - Invite Push** | "[Owner Name] has invited you to join the Family Hub. Tap to view invite." | Push | Immediate (if app installed) |
| **N3 - Joined** | "[Member Name] has joined the Family Hub." | Push to all existing | On Accept |
| **N7 - Removed Push** | "You have been removed from the Family Hub by [Owner]." | Push | On removal |
| **N8 - Removed WhatsApp** | "[Owner] removed you from the Family Hub on JioPhotos." | WhatsApp | On removal (if WA-registered) |
| **N9 - Left** | "[Member Name] has left the Family Hub." | Push to remaining | On self-exit |
| **N10 - Over-quota** | "Your storage is [X] GB — over your 50 GB limit. Clean up or upgrade your plan." | Push + WhatsApp | With removal (if >50GB) |
| **N11 - Storage 90%** | "Storage almost full ([X]% used). Free space or upgrade." | Banner | On app open |
| **Welcome Toast** | "Welcome to the Family Hub!" | Toast | After Accept |
| **Leave Confirmation** | "Leave Family Hub? Your personal library is unaffected." | Dialog | On Leave tap |
| **Removal Confirmation** | "Remove [Name] from Family Hub?" | Dialog | On Remove tap |

### Errors & Edge Copy

| ID | Error Message | When Shown |
|----|---------------|------------|
| **E1** | "Name is required." | Name empty on invite (inline) |
| **E3** | Input capped at 25 characters | Name exceeds 25 chars (blocking) |
| **E4** | "Phone Number is required." | Phone empty (inline) |
| **E5** | Input capped at 10 digits | Invalid phone (non-numeric/short/long) |
| **E6** | "An invite is already pending for this number" | Duplicate pending invite |
| **E7** | "This user is already part of another Family Hub. A user can only belong to one family." | Invitee in another hub |
| **E9** | Send Invite button disabled | Hub at 5/5 member cap |
| **E10** | "This invite has expired. Ask [Owner Name] to send a new invite." | Expired link (15 days) |
| **E11** | "Invalid invite link. Please check with the person who invited you." | Invalid/tampered URL |
| **E12** | Redirect to login | User not logged in (non-blocking) |
| **E14** | "Install JioPhotos if not already installed" | App not installed (SMS text) |
| **E20** | Over-quota alert + mandatory cleanup screen | Removed member >50GB |

### Data / Config Limits

| Field / Rule | Value | PRD § |
|--------------|-------|-------|
| Max members per hub | 5 (including Owner) | R3 |
| Invite expiry | 15 days | R4 |
| Name max length | 25 characters | E3 |
| Phone format | 10-digit Indian mobile | E5 |
| Relationships | Parent / Spouse / Child / Sibling / Other | Invite screen |
| Storage warning threshold | 90% capacity | S2, N11 |
| Default storage limit | 50 GB | S5, N10 |
| Pending invite cap | Counts toward 5-member limit | R17 |

---

## 🎯 Experience Intent

- **Should feel:** Trustworthy, family-oriented, secure yet inviting
- **Speed expectation:** Sub-second for hub creation; invite delivery within 60 seconds
- **Cognitive load:** Minimal - one-tap invites, clear status indicators, guided flows
- **Default vs control:** Smart defaults (owner as hub creator), power user controls (member management, resend invites)

---

## 🎨 UI & design

- **Figma (primary):** USER_INPUT_REQUIRED — Sprint 3 clarification: Profile screen for members (non-owners) shows only total storage used and leave option — no individual member breakdown. Owner's profile screen shows all member details with storage per member. Design with Laxman (POD 3).
- **Prototype:** USER_INPUT_REQUIRED
- **Design status:** [ ] Not started  [x] Draft  [ ] Ready for dev  [ ] N/A (no UI)

---

## 🧾 Acceptance Criteria

### Core Flow - Hub Creation & Invite

1. **Given** User is on JioPhotos home screen
   **When** User taps Family Hub entry point (banner/card with '+' icon)
   **Then** If no hub exists, "Create Family Hub" CTA is shown

2. **Given** User taps "Create Family Hub"
   **When** User confirms creation
   **Then** User is set as Group Owner and hub is active

3. **Given** Owner is in invite screen
   **When** Owner enters Name (≤25 chars), Phone (10 digits), selects Relationship, optional Photo
   **Then** SMS + WhatsApp (if WA-registered) + Push (if app installed) are sent with universal invite link

4. **Given** Owner has 5 members including pending invites
   **When** Owner tries to send new invite
   **Then** Send Invite button is disabled (E9)

### Core Flow - Accept Invite

5. **Given** Invitee receives invite notification (SMS/WhatsApp/Push)
   **When** Invitee clicks universal link
   **Then** If app installed → opens invite screen; if not → user installs manually then clicks link again

6. **Given** Invitee opens invite screen
   **When** Invitee is not logged in
   **Then** Redirect to login/account creation, then back to invite screen

7. **Given** Invitee is logged in and on invite screen
   **When** Invitee taps Accept
   **Then** User joins hub; "Welcome to the Family Hub!" toast shown; N3 sent to existing members

8. **Given** Invitee is logged in and on invite screen
   **When** Invitee taps Decline (or "Decide Later")
   **Then** Invite dismissed; owner sees Declined status; re-invite allowed

### Core Flow - Member Management

9. **Given** Owner is in Hub Settings → Member List
   **When** Owner taps member → "Remove from Hub"
   **Then** Confirmation dialog shown; on confirm, member access revoked instantly (N7 + N8 sent)

10. **Given** Member is on Family Hub screen
    **When** Member taps "Leave Family Hub"
    **Then** Confirmation dialog shown; on confirm, access revoked, personal library untouched (N9 sent)

### Failure / Edge Cases

11. **Given** Owner enters phone number with existing pending invite
    **When** Owner taps Send Invite
    **Then** Error E6 shown: "An invite is already pending for this number"

12. **Given** Invited user is already in another Family Hub
    **When** Owner tries to send invite
    **Then** Error E7 shown: "This user is already part of another Family Hub"

13. **Given** Invitee clicks invite link after 15 days
    **When** Universal link opens
    **Then** Error E10 shown: "This invite has expired. Ask [Owner Name] to send a new invite."

14. **Given** Removed/left member has storage >50GB
    **When** Member is removed or leaves
    **Then** N10 over-quota alert sent; mandatory cleanup screen on next app open

---

## 📊 Measurement & Signals

### Primary Metric
- **Name:** Family Hub creation rate
- **Baseline:** 0% (new feature)
- **Target:** 30% of eligible users create hub within 3 months
- **Observation window:** 3 months post-launch

### Secondary Signals
- **Engagement:** % of hub creators who invite members; invite acceptance rate; average time to accept
- **Retention:** 7-day retention of hub members vs non-members
- **Feature usage:** Average invites sent per hub; re-invite rate

### Event Tracking
- **Event names:** `family_hub_created`, `family_hub_invite_sent`, `family_hub_invite_accepted`, `family_hub_invite_declined`, `family_hub_member_removed`, `family_hub_member_left`
- **Parameters:** hub_id, owner_id, invitee_id, channel (SMS/WhatsApp/Push), invite_age_days

---

## 🧪 Validation Plan

- **Experiment type:** Rollout with phased % (5% → 25% → 100%)
- **Success threshold:** 30% creation rate, 60% invite acceptance, <5% error rate on invites
- **Observation window:** 2 weeks per phase

---

## ⚠️ Risks & Unknowns

- **Adoption risk:** Users may not discover Family Hub entry point
- **Behavioral uncertainty:** Users may prefer individual storage over shared pooling
- **Dependency risk:** Universal link setup (POD 3), WhatsApp engine (POD 2) are open blockers
- **Technical risk:** Firebase Dynamic Links deprecated — no auto-redirect from app store

---

## 🔗 Dependencies

| Dependency | Team | Status |
|------------|------|--------|
| Universal Link Setup | POD 3 | Open — needs setup |
| WhatsApp Engine Setup | POD 2 | Open — highlighted |
| Profile Screen — Family View | POD 3 (Laxman) | Design in progress |
| Member Details API | Backend | Required |

---

## 🚫 Explicit Non-Goals

- Shared photo albums within hub (future phase)
- Family memories/clusters (data collected but not used yet)
- Auto-redirect from app store (Firebase Dynamic Links deprecated)
- Multiple hub ownership per user
- Hub ownership transfer
- Member-to-member messaging

---

## 📅 Priority & Rollout Strategy

- **Priority:** P0 - Critical Path
- **Rollout plan:** Phased 5% → 25% → 100% over 6 weeks
- **Success gate:** 30% creation rate before 25% rollout; 50% before 100%

---

## 🏆 Related Stories

- **Depends on:** Profile screen family view (POD 3)
- **Unblocks:** Family photo sharing (Phase 2), Family memories/clusters (Phase 3)
- **Relates to:** JioPhotos storage management, invitation platform

---

## 📝 Notes

- Sprint 3 clarifications captured: Home screen entry point, owner photo on invite screen, explicit accept required even for logged-in users
- Relationship field collected for future cluster/memories integration
- Member sees their own JioPhotos profile name (not owner-entered name)

---

## 📋 Story Metadata

**Status:** [x] Draft  [ ] In Review  [ ] Approved  [ ] In Progress  [ ] Done  
**Owner:** Product Manager — Family Hub  
**Created:** 2026-04-21  
**Last Updated:** 2026-04-21

---

## 🔗 PRD Traceability *(required)*

| PRD document | Section IDs | ADO Feature ID |
|--------------|-------------|----------------|
| FamilyHub_Phase 1.docx | Flow A, Flow B, Flow D, Flow E, Notification Matrix, Error Scenarios, Storage & Membership | 865620 |

---

## 🎨 Design Resources

- **Figma (primary):** USER_INPUT_REQUIRED — Contact Laxman (POD 3) for Profile screen designs
- **Prototype:** USER_INPUT_REQUIRED
- **Design status:** [ ] Not started  [x] Draft  [ ] Ready for dev  [ ] N/A (no UI)
