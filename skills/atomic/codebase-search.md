# Atomic Skill: Codebase Search

**ID**: `codebase-search`  
**Category**: `code-analysis`  
**Cost**: ~100 tokens  
**Duration**: 2-5 seconds  
**Cacheable**: Yes (TTL: 1 hour, invalidated on git HEAD change)

---

## Purpose

Search codebase for files matching keywords. Returns file paths, not content.

---

## Input Schema

```json
{
  "type": "object",
  "required": ["keywords"],
  "properties": {
    "keywords": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 1,
      "maxItems": 10,
      "description": "Search terms from story/requirements"
    },
    "file_patterns": {
      "type": "array",
      "items": {"type": "string"},
      "default": ["*.java", "*.kt", "*.ts", "*.tsx"],
      "description": "File extensions to include"
    },
    "max_files": {
      "type": "integer",
      "default": 10,
      "maximum": 50,
      "description": "Maximum files to return"
    },
    "exclude_patterns": {
      "type": "array",
      "items": {"type": "string"},
      "default": ["*/test/*", "*/node_modules/*", "*/.git/*"]
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
          "lines": {"type": "integer"},
          "relevance_score": {"type": "number", "minimum": 0, "maximum": 1},
          "matched_keywords": {"type": "array", "items": {"type": "string"}}
        }
      }
    },
    "total_matches": {"type": "integer"},
    "search_time_ms": {"type": "integer"},
    "git_head": {"type": "string"}
  }
}
```

---

## Execution

```bash
#!/bin/bash
# codebase-search.sh

keywords="$1"
file_patterns="${2:-*.java,*.kt,*.ts}"
max_files="${3:-10}"

# Build find command
patterns=$(echo "$file_patterns" | tr ',' '\n' | sed 's/^/-o -name /' | tr '\n' ' ')

# Search for files containing keywords
results=$(
  for keyword in $keywords; do
    find . -type f \( $patterns \) -exec grep -l "$keyword" {} \; 2>/dev/null
  done | sort | uniq -c | sort -rn | head -$max_files
)

# Format output
jq -n \
  --arg files "$results" \
  --arg git_head "$(git rev-parse HEAD)" \
  '{
    files: ($files | split("\n") | map(select(length > 0) | {
      path: .,
      lines: 0,
      relevance_score: 0.5,
      matched_keywords: []
    })),
    total_matches: ($files | split("\n") | map(select(length > 0)) | length),
    search_time_ms: 0,
    git_head: $git_head
  }'
```

---

## Used In

- `composed/rpi-research.yaml` — Step 2: Find relevant files
- `composed/impact-analysis.yaml` — Find affected files
- `composed/refactoring.yaml` — Locate code to refactor

---

**Created**: 2026-04-17  
**Last Updated**: 2026-04-17  
**Governed By**: AI-SDLC Platform
