# Cross-Team Dependency Management

## Overview
Cross-team dependencies must be explicit, tracked, and synchronized. This prevents silent blockers and enables parallel execution.

## Dependency Tagging Strategy

### Dependency Tags
- `dependency:backend-api` — Story depends on backend API
- `dependency:db-migration` — Story depends on database migration
- `dependency:external` — Story depends on external service/vendor
- `blocked:api-contract` — Blocked waiting for API contract
- `blocked:design` — Blocked waiting for design assets
- `blocked:backend` — Blocked waiting for backend work

### Blocking Pattern
When Story A depends on Story B:
1. **Add tags to Story A**:
   - `blocked:<topic>` (indicates blocker type)
   - `dependency:<team>-<component>` (indicates dependency)
2. **Add linking in ADO**:
   - Link: `relates to` Story B
   - Comment: "Blocked on AB#<Story B ID>"
3. **Update Story B**:
   - Add `blocked:<topic>` tag to Story B if not started
   - Add comment referencing Story A

## Contract-First Coupling

### API Contract Definition
Before backend development starts:
1. **Publish OpenAPI 3.1** contract in shared repo
2. **Tag**: `blocked:api-contract` on dependent stories
3. **Frontend/Mobile**: Mock API using contract
4. **Backend**: Implement against contract

### Database Contract Definition
Before migration scripts run:
1. **Define schema** in PR with `DB migration` label
2. **Link** to Story with `dependency:db-migration`
3. **QA**: Validate migration on staging first

## Shared Memory Sync Protocol

### Dependency Graph
Update `memory/shared/dependency-graph.md` weekly:

```markdown
## Week of 2026-04-07

Service A (Backend)
├─ → Service B (Kafka topic: user-events)
│   └─ Protocol: Kafka (acks=all, manual commit)
│   └─ Contract: v1.2 (AB#15234)
├─ → Database Shard 3 (parameterized queries)
│   └─ Migration: V001__add_user_audit_table.sql (AB#15235)

Service C (Frontend)
├─ → API Gateway (REST)
│   └─ OpenAPI: 3.1 (AB#15236)
```

### Predecessor/Successor Links
In ADO, use:
- **Predecessor**: Story X must complete before Story Y
- **Successor**: Story Y depends on Story X completing
- Links appear in story view; gates check predecessor status

### Cross-Team Decision Log
Append to `memory/shared/cross-team-log.md`:

```
2026-04-10 | Backend Team | Kafka topic schema change | 3-day delay for consumers | AB#15240
2026-04-10 | Frontend Team | API contract v1.3 released | Frontend can now integrate avatars | AB#15241
```

## Gate Coordination

### G5 Gate (Ready: Sprint)
Gate enforces:
- All predecessor stories completed or in current sprint
- API contracts published (if dependent on API)
- Database migrations linked (if DB work required)

**Owner**: Product Owner  
**Blocks**: Sprint start

---
**Last Updated**: 2026-04-10  
**Governed By**: AI-SDLC Platform
