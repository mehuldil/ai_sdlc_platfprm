# Cross-Team Decision Log (Append-Only)

**Purpose**: Record decisions made across teams that affect other teams  
**Format**: ISO 8601 Date | Team | Decision | Impact | ADO Reference  
**Maintained By**: Product Owner  

---

## 2026-04-10

| Date | Team | Decision | Impact | ADO Ref |
|------|------|----------|--------|---------|
| 2026-04-10 | Backend | Kafka topic schema v2 released (user-events) | Mobile & Analytics teams must update consumers within 1 week | AB#15401 |
| 2026-04-09 | Design | Profile edit screen approved (responsive) | Frontend can begin implementation (no more design changes) | AB#15350 |
| 2026-04-08 | Frontend | API contract v1.3 published (user endpoints) | Backend can optimize endpoints for mobile usage | AB#15392 |

## 2026-04-03

| Date | Team | Decision | Impact | ADO Ref |
|------|------|----------|--------|---------|
| 2026-04-03 | DevOps | Database migration V005 deployed to production | Audit logging now available; analytics can query audit_log table | AB#15298 |
| 2026-04-02 | QA | Load test baseline established (10K events/sec) | Performance targets locked; future tests compared to baseline | AB#15280 |
| 2026-04-01 | Backend | gRPC endpoint for inter-service calls enabled | Search service can now call auth-service via gRPC (latency: <50ms vs 200ms REST) | AB#15267 |

## 2026-03-28

| Date | Team | Decision | Impact | ADO Ref |
|------|------|----------|--------|---------|
| 2026-03-28 | Product | Rollback plan required for all features >3 story points | Ops must validate rollback scripts before release | ADR-024 |
| 2026-03-27 | Frontend | Upgrade to React 18.3 completed | Mobile team can now update React Native dependencies | AB#15155 |
| 2026-03-26 | Backend | Legacy auth-service sunset date moved to June 30 | 3 additional weeks for client migration (from May 30) | ADR-015 |

## 2026-03-21

| Date | Team | Decision | Impact | ADO Ref |
|------|------|----------|--------|---------|
| 2026-03-21 | Architecture | Elasticsearch version upgrade: 7.x → 8.x | Search service API breaking changes; queries must use new syntax | AB#15089 |
| 2026-03-20 | QA | Mobile app minimum SDK changed to Android 11 | Drop support for Android 10 (0.5% of user base); simplifies testing | AB#15078 |
| 2026-03-19 | Design | Dark mode design tokens extracted (figma-tokens plugin) | Frontend can implement dark mode toggle; token sync automated weekly | AB#15050 |

## 2026-03-15

| Date | Team | Decision | Impact | ADO Ref |
|------|------|----------|--------|---------|
| 2026-03-15 | Backend | Kafka consumer lag alert threshold: >10K messages | Operations will page on-call if lag exceeds threshold | AB#15020 |
| 2026-03-14 | Product | User story template changed to v2.0 (17 sections) | All new stories must use updated template; existing stories grandfathered | AB#15001 |
| 2026-03-13 | Frontend | API rate limit: 1000 req/hr per client | Frontend must implement request queuing and retry logic | AB#14988 |

---

## Notes
- **Frequency**: Updated weekly during architecture sync (Thursdays, 2pm UTC)
- **Escalations**: Any decision blocking another team logged immediately (not weekly)
- **Retention**: Kept for 6 months; archived quarterly
- **Access**: Read access all teams; write access Product Owner only

---

**Last Updated**: 2026-04-10  
**Next Sync**: 2026-04-17 @ 14:00 UTC
