# Atomic Skill: Risk Identify

**ID**: `risk-identify`  
**Category**: `analysis`  
**Cost**: ~200 tokens  
**Duration**: 2-5 seconds  
**Cacheable**: No (context-dependent)

---

## Purpose

Identify risks in implementation based on work item, files, and known issues.

---

## Input Schema

```json
{
  "type": "object",
  "required": ["work_item", "files"],
  "properties": {
    "work_item": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "description": {"type": "string"},
        "acceptance_criteria": {"type": "string"}
      }
    },
    "files": {
      "type": "array",
      "items": {"type": "string"}
    },
    "known_issues": {
      "type": "string",
      "description": "Path to known-issues.md or content"
    },
    "impact_rules": {
      "type": "string",
      "description": "Path to impact-rules.md or content"
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
    "risks": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "category": {"enum": ["scope", "technical", "dependency", "regression", "performance"]},
          "severity": {"enum": ["low", "medium", "high", "critical"]},
          "description": {"type": "string"},
          "mitigation": {"type": "string"},
          "files_at_risk": {"type": "array", "items": {"type": "string"}}
        }
      }
    },
    "overall_risk_score": {"type": "number", "minimum": 0, "maximum": 1}
  }
}
```

---

## Used In

- `composed/rpi-research.yaml` — Step 4: Risk analysis
- `composed/system-design.yaml` — Design risk assessment

---

**Created**: 2026-04-17  
**Last Updated**: 2026-04-17  
**Governed By**: AI-SDLC Platform
