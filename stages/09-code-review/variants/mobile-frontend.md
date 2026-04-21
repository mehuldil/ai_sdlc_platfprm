---
name: Mobile Frontend Code Review Variant
description: Multi-agent code review for iOS, Android, React Native
stack: mobile-frontend
---

# Mobile Frontend Code Review Variant

## 7-Passive Agent Architecture

Code review runs 7 agents in parallel; each checks one dimension (no blocking, advisory-only):

### 1. Architecture Guardian
- Checks: MVVM pattern adherence (View → ViewModel → Model)
- Checks: Layer separation (Presentation, Domain, Data)
- Checks: Component composition (single responsibility)
- Red Flag: Business logic in UI layer
- Red Flag: Direct API calls from views
- Advisory: Suggest DDD patterns, domain models

### 2. Dependency Watchdog
- Checks: Package.json or build.gradle.kts dependencies
- Checks: No deprecated or EOL libraries
- Checks: Version conflicts (same lib, different versions)
- Checks: Security advisories (npm audit, gradle dependencyUpdates)
- Red Flag: Unlisted dependencies (used but not declared)
- Red Flag: Vulnerable packages (known CVEs)
- Advisory: Suggest upgrades, alternatives

### 3. Security Reviewer
- Checks: No secrets in code (API keys, tokens, passwords)
- Checks: Network: certificate pinning, HTTPS only
- Checks: Storage: sensitive data encrypted, Keychain/Keystore used
- Checks: Authentication: OAuth2/PKCE, token refresh
- Red Flag: Hardcoded credentials
- Red Flag: Plain HTTP, no pinning
- Advisory: Suggest secure patterns (Keychain, OAuth2)

### 4. Crash Monitor
- Checks: Exception handling (try-catch, error boundaries)
- Checks: Null safety (optional unwrapping in Swift, null checks in Java)
- Checks: Memory: no memory leaks (weak references in Swift, lifecycle cleanup in Android)
- Red Flag: Unhandled exceptions
- Red Flag: Force-unwrapping optionals (!)
- Red Flag: Retain cycles (strong self in closures)
- Advisory: Add error handling, defensive coding

### 5. Performance Profiler
- Checks: UI rendering (no janky animations, frame drops)
- Checks: List performance (FlatList, RecyclerView, LazyColumn)
- Checks: Image handling (compressed, lazy-loaded)
- Checks: Async operations (no blocking main thread)
- Red Flag: ScrollView with dynamic content
- Red Flag: Synchronous network calls on main thread
- Red Flag: Unoptimized images
- Advisory: Suggest Performance Monitoring

### 6. Memory Budget Controller
- Checks: Memory usage patterns (allocations, deallocations)
- Checks: Caching strategy (LRU, TTL)
- Checks: Closures (capture minimally, weak self)
- Checks: Large data structures (pagination vs loading all)
- Red Flag: Unbounded caches
- Red Flag: Circular references
- Red Flag: Large payload processing on main thread
- Advisory: Profile with Instruments, optimize allocations

### 7. Context Memory Manager
- Checks: Context/ViewController lifecycle (retained contexts)
- Checks: Listener cleanup (observers, callbacks)
- Checks: Navigation stack (popped, not leaked)
- Checks: Fragment/ViewController transitions (proper cleanup)
- Red Flag: Context passed across packages
- Red Flag: Static references to context
- Red Flag: Registered listeners not unregistered
- Advisory: Use weak references, lifecycle hooks

## Verdict Rules
- All agents report: APPROVED, CONCERN, or CRITICAL
- APPROVED: proceed
- CONCERN (1-2 agents): address before merge
- CRITICAL (3+ agents or security issue): block, return to implementation
