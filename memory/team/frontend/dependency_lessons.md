# Frontend Dependency Management Lessons

**Team**: Frontend  
**Last Updated**: 2026-04-10  

---

## Dependency Issues & Resolutions

### Issue 1: React-Router v5 → v6 Migration (Completed)
- **Problem**: React Router v5 EOL; security patches ending
- **Decision**: Migrate to v6 (breaking changes in routing syntax)
- **Timeline**: 3 sprints (2026-01 to 2026-02)
- **Lessons**:
  - Plan major migrations 1 sprint early
  - Test thoroughly on mobile (route changes differ)
  - Update API contract simultaneously (no version mismatch)

### Issue 2: Axios Breaking Release (Avoided)
- **Problem**: Axios 1.x released; breaking change in interceptor order
- **Decision**: Pin to 0.27.x; backport critical security fixes
- **Timeline**: Postpone upgrade to Q3 2026
- **Lessons**:
  - Major version upgrades require full regression test
  - Consider SemVer carefully when choosing deps
  - Maintain changelog for team communication

### Issue 3: TypeScript Strict Mode (Implemented)
- **Problem**: Found 200+ implicit `any` types in codebase
- **Solution**: Enable strict mode; fix type issues iteratively
- **Timeline**: 2 sprints (2026-02 to 2026-03)
- **Lessons**:
  - Enforce strict mode in CI (catch errors early)
  - Use type guards (`typeof`, `instanceof`) liberally
  - Type inference reduces boilerplate significantly

---

## Dependency Best Practices

### Approval Workflow
1. Developer proposes new dependency
2. Code review includes dependency check
3. Check for:
   - Size impact (npm view react-final-form --bundlesize)
   - Security (npm audit)
   - Maintenance status (GitHub stars, last commit date)

### Regular Maintenance
- **Quarterly**: `npm outdated` review; update patch/minor versions
- **Annually**: Major version evaluation (breaking changes assessment)
- **Monthly**: Security audit (`npm audit`)

### Dependencies to Avoid
- No small utility libraries (implement inline)
- No overlapping packages (e.g., lodash + underscore)
- No unmaintained packages (>1 year since last release)

---

## Current Dependencies Health
- **Total**: 45 (prod) + 20 (dev)
- **Outdated**: 2 minor versions available
- **Vulnerabilities**: 0 critical
- **Last Audit**: 2026-04-10 (clean)

---

**Maintained By**: Carol Davis, Dependency Champion
