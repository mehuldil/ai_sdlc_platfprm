# ADO Observer — inbound (2-way) sync

This service implements **inbound** Azure DevOps integration: **Service Hooks** (preferred) or **polling** (fallback) deliver work item and PR events so the platform can react when ADO changes.

## Outbound vs inbound

| Direction | Mechanism | Purpose |
|-----------|-----------|---------|
| **Outbound** | `sdlc ado …`, REST from CLI/agents | Create/update work items, post comments from repo workflows |
| **Inbound** | `observer.py` (this folder) | Receive WI state/comment/PR events; trigger gates, orchestrator steps, or notifications |

**Agents:** read [`agents/shared/ado-integration.md`](../../agents/shared/ado-integration.md) for ask-first CRUD. **Two-way posture:** outbound changes should be reconciled with inbound events (observers); use idempotent handlers and log correlation IDs on both sides.

## Running

- **Webhook mode:** deploy the FastAPI app, register ADO Service Hooks to `POST /webhook/ado`, set `ADO_WEBHOOK_SECRET` for signature verification.
- **Polling mode:** set `mode=polling` (or `auto` with no reachable hook); configure `polling_interval`.

Environment variables follow the same PAT/org/project conventions as the rest of the platform (`ADO_PAT`, `ADO_ORG`, `ADO_PROJECT`).

## Handlers

Register `TriggerRule` instances for `WORKITEM_STATE_CHANGED`, `WORKITEM_COMMENTED`, etc. Handlers should advance **next stage** only when policy allows (same gates as `rules/gate-enforcement.md`).
