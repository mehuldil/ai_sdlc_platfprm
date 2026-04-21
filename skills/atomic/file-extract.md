# Atomic Skill: File Extract

**ID**: `file-extract`  
**Category**: `code-analysis`  
**Cost**: ~50 tokens per file  
**Duration**: <1 second per file  
**Cacheable**: Yes (TTL: 1 hour)

---

## Purpose

Extract file content with limits (lines, characters). Returns excerpt, not full file.

---

## Input Schema

```json
{
  "type": "object",
  "required": ["files"],
  "properties": {
    "files": {
      "type": "array",
      "items": {"type": "string"},
      "description": "File paths to extract"
    },
    "max_chars_per_file": {
      "type": "integer",
      "default": 2000,
      "maximum": 10000
    },
    "max_lines": {
      "type": "integer",
      "default": 100,
      "maximum": 500
    },
    "strategy": {
      "type": "string",
      "enum": ["head", "smart", "signatures"],
      "default": "smart",
      "description": "head=first N lines, smart=imports+signatures, signatures=method/class signatures only"
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
    "files": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "path": {"type": "string"},
          "total_lines": {"type": "integer"},
          "excerpt": {"type": "string"},
          "excerpt_lines": {"type": "integer"},
          "strategy_used": {"type": "string"}
        }
      }
    },
    "total_chars": {"type": "integer"},
    "truncated_files": {"type": "integer"}
  }
}
```

---

## Used In

- `composed/rpi-research.yaml` — Step 2b: Extract file content
- `composed/code-review.yaml` — Load files for review

---

**Created**: 2026-04-17  
**Last Updated**: 2026-04-17  
**Governed By**: AI-SDLC Platform
