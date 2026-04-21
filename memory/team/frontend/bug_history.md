# Frontend Bug History & Patterns

**Team**: Frontend  
**Last Updated**: 2026-04-10  

---

## Recent Bugs (Last 30 Days)

### Critical (2)
1. **Login redirect loop** (AB#15320, fixed 2026-04-09)
   - Users on expired tokens redirected to /login → /dashboard → /login (infinite loop)
   - Root cause: Missing token refresh check in PrivateRoute component
   - Fix: Added token validation before redirect

2. **Mobile form input blur** (AB#15365, in progress)
   - iPad 11-inch: Form input blurs when user types (responsive height issue)
   - Root cause: CSS viewport units (vh) conflict on iPad
   - Fix: Switch to JavaScript-based responsive height

### Medium (3)
- Avatar upload fails silently on slow network (retry logic incomplete)
- Search results pagination: Page 2+ shows stale data (cache invalidation)
- Notification dropdown: Doesn't close on route change

---

## Bug Patterns & Preventions

### Pattern 1: State Synchronization Issues (3 bugs)
- **Symptom**: Components out of sync with Redux/Context state
- **Root Cause**: Missing dependency arrays in useEffect
- **Prevention**: ESLint rule `react-hooks/exhaustive-deps` enabled

### Pattern 2: Mobile-Specific Responsive Layout (2 bugs)
- **Symptom**: Layout breaks on specific device (iPad, iPhone 12 mini)
- **Root Cause**: Testing only on desktop + standard sizes
- **Prevention**: Device testing automation (Cypress on BrowserStack)

### Pattern 3: API Error Handling (2 bugs)
- **Symptom**: Error response not caught; UI shows nothing
- **Root Cause**: Axios interceptor missing error case
- **Prevention**: Add axios error handler test for all endpoints

---

## Known Limitations
- Mobile Safari: CSS grid alignment off by 1-2px (cosmetic, low priority)
- Dark mode: Figma tokens not yet extractable (manual update weekly)

---

**Maintained By**: Carol Davis, Frontend QA Lead
