# Test Plan

**Test Plan ID**: TP-[###]  
**Related Story**: AB#[work-item-id]  
**QA Lead**: [Name]  
**Date Created**: [YYYY-MM-DD]  
**Status**: Draft | **Ready** | In Progress | Completed  

> **Authoring:** Scope and scenarios must trace to **Sprint/Master** acceptance and **PRD** copy (notifications/errors). **Non-regression** is mandatory—see [AUTHORING_STANDARDS.md](AUTHORING_STANDARDS.md).

---

## §1 Scope
What is being tested?
- Feature/functionality under test
- Platforms (web, mobile, etc.)
- Browser/OS versions (if applicable)
- What is explicitly NOT being tested

Example: "Testing user profile edit feature on web (Chrome 120+, Firefox 121+) and mobile (iOS 14+, Android 10+). Not testing user account creation or profile deletion."

### 1.1 Regression and non-regression scope (module impact)

Tie this plan to **what must not break** when the feature ships. Cross-check the design doc **§0** (backward compatibility) and, when present, `.sdlc/module/knowledge/impact-rules.md` and `known-issues.md`.

| Area / surface | At-risk behavior or contract | How we verify non-regression (manual ID, automated suite, or smoke checklist) |
|----------------|------------------------------|-------------------------------------------------------------------------------|
| Example: Profile read API | Existing clients expect 200 + same JSON shape | Run API contract tests `…`; smoke TC-R1 |
| | | |

---

## §2 Test Strategy

### 2.1 Functional Testing
User-facing functionality. Test scripts:
- **TC-1**: User can edit bio (max 250 chars)
- **TC-2**: User can upload avatar (jpg/png, <5MB)
- **TC-3**: User cannot save empty name
- **TC-4**: Changes persist after page reload
- **TC-5**: User receives success notification

### 2.2 Regression Testing
Ensure no existing functionality broken:
- Profile viewing (read-only) still works
- Dashboard loads with profile data
- Notifications still send
- Search still finds updated profiles

### 2.3 Usability Testing
UX flows and accessibility:
- **UT-1**: Form layout is responsive on mobile
- **UT-2**: All interactive elements keyboard-accessible
- **UT-3**: Error messages are clear
- **UT-4**: WCAG 2.1 AA color contrast met

### 2.4 Performance Testing
Load and responsiveness:
- Profile page loads in <2 seconds (p95)
- Image upload completes in <5 seconds
- No memory leaks after 10 edit cycles
- Handles avatar upload while typing bio

### 2.5 Security Testing
Data protection and validation:
- **SEC-1**: HTML/JS injection in bio rejected
- **SEC-2**: SQL injection in avatar filename rejected
- **SEC-3**: File upload restricted to image types
- **SEC-4**: User cannot edit another user's profile

---

## §3 Entry Criteria (Before Testing Starts)
- [ ] Code merged to staging branch
- [ ] Build pipeline passes (CI/CD green)
- [ ] Design approved (no UX changes expected)
- [ ] Test data prepared (5 test users created)
- [ ] QA environment stable

---

## §4 Test Environment
- **Web**: Chrome 120+, Firefox 121+, Safari 17+
- **Mobile**: iOS 14+ (iPhone 12+), Android 10+ (Pixel 6+)
- **Backend**: Staging database (non-prod data)
- **API**: Staging API endpoints
- **Tools**: Postman (API), Chrome DevTools (network), JMeter (load)

---

## §5 Test Data

### User Accounts
- Standard user (permissions: edit own profile)
- Admin user (permissions: edit any profile)
- Suspended user (permissions: none)

### Test Datasets
```csv
user_id,email,bio,avatar_filename
1,user1@test.com,"Engineer at YourAzureProject",avatar1.jpg
2,user2@test.com,"Product Manager","",
3,user3@test.com,"A"*200," Boundary value test",avatar3.jpg
```

---

## §6 Risk Areas (Prioritized)

### High Risk
- Avatar upload fails silently (no error shown)
- Concurrent edits create duplicate/lost data
- File size validation bypassed (oversized upload)

### Medium Risk
- Profile not visible to other users immediately
- Mobile form layout breaks on small screens
- Error message unclear to non-tech users

### Low Risk
- Typo in success message
- Border color slightly off from design
- Loading spinner animation skips frame

---

## §7 Schedule

| Phase | Start | End | Duration | Owner |
|-------|-------|-----|----------|-------|
| Smoke Test | D+1 | D+1 | 2 hours | QA Lead |
| Functional | D+1 | D+2 | 8 hours | QA Team (2 engineers) |
| Regression | D+2 | D+3 | 6 hours | QA Team |
| Performance | D+3 | D+3 | 4 hours | Performance QA |
| Security | D+3 | D+4 | 6 hours | Security Team |
| UAT | D+4 | D+5 | 4 hours | Product Manager |

**D** = First QA testing day (staging deployment)

---

## Exit Criteria (Before Release)
- [ ] All critical test cases passed (TC-1 to TC-5)
- [ ] No unresolved medium/high severity defects
- [ ] Coverage ≥80% (code + functional)
- [ ] Performance targets met (p95 latency <2s)
- [ ] Security scan passed (no critical vulnerabilities)
- [ ] UAT approval signed

---

## Test Execution Summary (Filled After Testing)
- **Total Executed**: 35
- **Passed**: 32
- **Failed**: 2
- **Blocked**: 1
- **Pass Rate**: 91%

### Defects Found
- **D-1** (High): Avatar upload fails for .gif files → Dev assigned
- **D-2** (Medium): Form labels not visible on mobile → Design review

---

## Sign-off
- **QA Lead**: ☐ Approved
- **Product Owner**: ☐ Approved
- **Tech Lead**: ☐ Approved

---
**Last Updated**: [date]
