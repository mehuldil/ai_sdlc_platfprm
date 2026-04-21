# Frontend Security Lessons

**Team**: Frontend  
**Last Updated**: 2026-04-10  

---

## Security Incidents & Resolutions

### Incident 1: XSS in Profile Bio (Fixed 2026-03-15)
- **Vulnerability**: User-entered bio not sanitized; `<script>` tags executed
- **Root Cause**: Direct innerHTML assignment in component
- **Fix**: Use DOMPurify library; sanitize all user input
- **Prevention**: ESLint rule `react/no-danger` enabled (alerts on innerHTML)

### Incident 2: JWT Token Exposure (Fixed 2026-02-28)
- **Vulnerability**: JWT tokens visible in localStorage; XSS could steal
- **Decision**: Keep JWT in localStorage (standard); enhance XSS prevention
- **Fix**: Implement Content Security Policy (CSP) headers
- **Prevention**: Regular security audit; bug bounty program

### Incident 3: Open Redirect in Login (Fixed 2026-01-30)
- **Vulnerability**: `?redirect=` parameter not validated; could redirect to phishing
- **Fix**: Whitelist allowed redirect URLs (internal only)
- **Prevention**: Add URL validation utility; unit test all redirects

---

## Security Best Practices

### Input Validation
- All user inputs sanitized (DOMPurify)
- Never use `dangerouslySetInnerHTML` without sanitization
- Server-side validation for critical operations (auth, payments)

### Authentication
- JWT tokens in localStorage (standard practice)
- Token refresh on 401 response (automatic via Axios interceptor)
- CSRF tokens for state-changing requests (POST, PUT, DELETE)

### Headers & CSP
```
Content-Security-Policy: default-src 'self'; script-src 'self'; 
  img-src 'self' data: https://cdn.jiocloud.io;
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
```

### Dependencies
- No malware in npm packages (scanned via npm audit + Snyk)
- Pin transitive dependencies (package-lock.json committed)
- Regular audit (monthly)

---

## Security Checklist (PR Review)
- [ ] No `innerHTML` (use textContent or DOMPurify)
- [ ] All API calls over HTTPS (enforced in config)
- [ ] Sensitive data not logged (no passwords, tokens in console)
- [ ] No hardcoded credentials or API keys
- [ ] URLs validated before redirect
- [ ] CSRF tokens present for state changes

---

## Known Limitations
- LocalStorage vulnerable to XSS (acceptable risk; CSP mitigates)
- Third-party CDN (images, fonts) could be compromised (risk acknowledged)

---

**Maintained By**: Carol Davis, Security Lead  
**Next Security Audit**: 2026-05-10
