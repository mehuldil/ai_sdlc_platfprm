# Performance Baselines & Targets

**Team**: Performance  
**Last Updated**: 2026-04-10  
**Maintained By**: Performance Engineer  

---

## API Performance Baselines (Established 2026-02-01)

### auth-service
| Endpoint | Method | Baseline (p95) | Target | Status |
|----------|--------|--------|--------|--------|
| /login | POST | 120ms | <150ms | ✓ |
| /refresh-token | POST | 80ms | <100ms | ✓ |
| /validate | GET | 40ms | <50ms | ✓ |

### profile-service
| Endpoint | Method | Baseline (p95) | Target | Status |
|----------|--------|--------|--------|--------|
| /users/{id} | GET | 250ms | <300ms | ✓ |
| /users/{id} | PUT | 300ms | <400ms | ✓ |
| /users | GET (paginated) | 400ms | <500ms | ✓ |

### search-service
| Endpoint | Method | Baseline (p95) | Target | Status |
|----------|--------|--------|--------|--------|
| /search | GET | 500ms | <200ms | ⚠️ (AB#15380 in progress) |
| /filters | GET | 150ms | <150ms | ✓ |

---

## Frontend Performance Baselines

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| Lighthouse Score (Desktop) | 92 | >90 | ✓ |
| Lighthouse Score (Mobile) | 78 | >80 | ⚠️ (Image optimization pending) |
| LCP (Largest Contentful Paint) | 1.8s (desktop), 3.2s (mobile) | <2.5s / <3.5s | ✓ / ⚠️ |
| CLS (Cumulative Layout Shift) | 0.05 | <0.1 | ✓ |
| Bundle Size (gzipped) | 245KB | <300KB | ✓ |

---

## Database Performance Baselines

| Query | Baseline (p95) | Target | Status |
|-------|--------|--------|--------|
| SELECT * FROM users WHERE id = ? | 5ms | <10ms | ✓ |
| SELECT * FROM users WHERE email = ? | 8ms | <20ms | ✓ |
| Full-text search (Elasticsearch) | 500ms | <200ms | ⚠️ (In progress) |

---

## Load Test Results (Baseline Profile)
- **Load**: 10K events/sec
- **Threads**: 50 concurrent users
- **Duration**: 5 minutes
- **P95 Latency**: 280ms
- **Error Rate**: 0.1%
- **Throughput**: 9,950 req/sec

---

## Performance Budget (Sprint)
- **CPU**: <70% under normal load
- **Memory**: <60% utilization
- **Network**: <80% bandwidth utilization
- **Database Connections**: <50% of pool

---

**Next Baseline Refresh**: 2026-06-10
