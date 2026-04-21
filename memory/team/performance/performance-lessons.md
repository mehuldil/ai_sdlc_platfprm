# Performance Lessons & Optimizations

**Team**: Performance  
**Last Updated**: 2026-04-10  
**Maintained By**: Performance Engineer  

---

## Major Optimizations Implemented

### Optimization 1: Database Query Indexing (Completed 2026-02-15)
- **Issue**: User profile queries took 250ms (slow for SLA)
- **Root Cause**: Missing index on email column
- **Solution**: Added composite index (email, status, created_at)
- **Result**: Query reduced to 20ms (12x improvement)
- **Impact**: Profile page load improved 150ms

### Optimization 2: Redis Caching Layer (Completed 2026-02-28)
- **Issue**: Profile service called DB on every request
- **Root Cause**: No caching strategy
- **Solution**: Redis cache with 3600s TTL + cache invalidation on update
- **Result**: 80% cache hit rate; reduced DB load 60%
- **Impact**: API latency reduced 200ms (p95)

### Optimization 3: Elasticsearch Query Rewrite (In Progress)
- **Issue**: Search queries took 500ms (3x target)
- **Root Cause**: Inefficient Elasticsearch query (full-text scan + filtering)
- **Solution**: 
  - Pre-computed filters in separate index
  - Query compilation optimization
  - Aggregation caching
- **Expected Result**: <200ms (p95)
- **ETA**: 2026-04-20

### Optimization 4: Frontend Code Splitting (Completed 2026-01-30)
- **Issue**: Bundle size 400KB; LCP 4+ seconds
- **Root Cause**: All JavaScript loaded upfront
- **Solution**: Route-based code splitting; lazy load components
- **Result**: Bundle 245KB, LCP 1.8s (mobile: 3.2s)
- **Impact**: Mobile conversion rate +8%

---

## Performance Anti-Patterns (To Avoid)

### Anti-Pattern 1: N+1 Query Problem
- **Issue**: Fetching users then their profiles (1 + N queries)
- **Solution**: Join users WITH profiles (1 query)
- **Prevention**: Code review checklist item

### Anti-Pattern 2: Unbounded Queries
- **Issue**: SELECT * FROM users (millions of rows)
- **Solution**: Always paginate; use LIMIT + OFFSET
- **Prevention**: Database query validation in CI

### Anti-Pattern 3: Synchronous External Calls
- **Issue**: Wait for third-party API (add 2-5s latency)
- **Solution**: Async Kafka messages; fire-and-forget
- **Prevention**: Architecture review for external calls

---

## Performance Monitoring Tools
- **Metrics**: Prometheus + Grafana
- **APM**: DataDog (custom instrumentation)
- **Browser**: Lighthouse CI (automated)
- **Load**: JMeter (custom dashboards)

---

## Q2 Goals
1. Search latency: <200ms (currently 500ms)
2. Mobile LCP: <3s (currently 3.2s)
3. Database connection pool: >90% efficiency

---

**Next Performance Review**: 2026-04-24
