# Atomic Skill: ADO Fetch

**ID**: `ado-fetch`  
**Category**: `integration`  
**Cost**: ~50 tokens  
**Duration**: 1-3 seconds  
**Cacheable**: Yes (TTL: 5 minutes)

---

## Purpose

Fetch work item details from Azure DevOps. Minimal atomic operation with no side effects.

---

## Input Schema

```json
{
  "type": "object",
  "required": ["story_id"],
  "properties": {
    "story_id": {
      "type": "string",
      "description": "ADO work item ID (numeric) or formatted (US-12345, AB#12345)"
    },
    "fields": {
      "type": "array",
      "items": {"type": "string"},
      "default": ["System.Title", "System.Description", "System.State"],
      "description": "ADO fields to fetch"
    }
  }
}
```

---

## Output Schema

```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string"},
    "title": {"type": "string"},
    "description": {"type": "string"},
    "state": {"type": "string"},
    "acceptance_criteria": {"type": "string"},
    "tags": {"type": "array"},
    "assigned_to": {"type": "string"},
    "parent_id": {"type": "string"},
    "url": {"type": "string"},
    "fetched_at": {"type": "string", "format": "date-time"}
  }
}
```

---

## Execution

```bash
#!/bin/bash
# ado-fetch.sh

story_id="$1"
normalized_id=$(echo "$story_id" | grep -oE '[0-9]+$')

# Fetch from ADO
curl -sS "https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${normalized_id}?api-version=7.0" \
  -u ":${ADO_PAT}" | \
  jq '{
    id: (.id | tostring),
    title: .fields["System.Title"],
    description: .fields["System.Description"],
    state: .fields["System.State"],
    acceptance_criteria: .fields["Microsoft.VSTS.Common.AcceptanceCriteria"],
    tags: (.fields["System.Tags"] // "" | split(";") | map(trim)),
    assigned_to: .fields["System.AssignedTo"].displayName,
    parent_id: (.relations // [] | map(select(.rel == "System.LinkTypes.Hierarchy-Reverse")) | .[0]?.url | split("/") | last),
    url: ._links.html.href,
    fetched_at: now | todate
  }'
```

---

## Error Handling

| Error | Response | Retry |
|-------|----------|-------|
| HTTP 404 | `{error: "Work item not found"}` | No |
| HTTP 401 | `{error: "Authentication failed"}` | No |
| Network timeout | `{error: "Timeout"}` | Yes (1 retry) |

---

## Used In

- `composed/rpi-research.yaml` — Step 1: Fetch story details
- `composed/sprint-planning.yaml` — Load work items
- `composed/qa-triage.yaml` — Fetch bug details

---

**Created**: 2026-04-17  
**Last Updated**: 2026-04-17  
**Governed By**: AI-SDLC Platform
