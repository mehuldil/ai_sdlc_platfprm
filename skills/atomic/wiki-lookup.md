# Atomic Skill: Wiki Lookup

**ID**: `wiki-lookup`  
**Category**: `integration`  
**Cost**: ~50 tokens  
**Duration**: 1-3 seconds  
**Cacheable**: Yes (TTL: 1 hour)

---

## Purpose

Search WikiJS for architecture docs, API contracts, known constraints.

---

## Input Schema

```json
{
  "type": "object",
  "properties": {
    "search_terms": {
      "type": "array",
      "items": {"type": "string"}
    },
    "categories": {
      "type": "array",
      "items": {"type": "string"},
      "default": ["architecture", "api", "constraints"]
    },
    "max_results": {
      "type": "integer",
      "default": 5
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
    "results": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "url": {"type": "string"},
          "excerpt": {"type": "string"},
          "relevance": {"type": "number"}
        }
      }
    }
  }
}
```

---

## Used In

- `composed/rpi-research.yaml` — Step 3: Wiki lookup
- `composed/system-design.yaml` — Find architecture docs

---

**Created**: 2026-04-17  
**Last Updated**: 2026-04-17  
**Governed By**: AI-SDLC Platform
