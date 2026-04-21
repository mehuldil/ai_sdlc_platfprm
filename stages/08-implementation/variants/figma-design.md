---
name: Figma Design Implementation Variant
description: Stage 08 for design-system work — tokens, libraries, and handoff quality (not app codegen)
stack: figma-design
---

# Figma / design-system implementation (Stage 08)

Use when **primary deliverables** are design artifacts (variables, components, specs) rather than service code. For product engineering implementation, pick **java-backend**, **react-native**, etc.

## Tooling

- **Figma:** libraries, variables, component properties, dev-mode specs
- **Repo:** design tokens (JSON/CSS), Storybook or preview links as agreed by the team
- **Accessibility:** WCAG-oriented notes in component descriptions where applicable

## RPI Rules

**Serialization:** [rpi-serialization-baseline.md](../../_includes/rpi-serialization-baseline.md) — phase locks for every stack. **Normative:** [rpi-workflow.md](../../../rules/rpi-workflow.md).

### Research Phase

- Load current library version, branch/link, and any **approved** frames or flows for this increment
- Read team conventions: naming, token tiers, spacing scale, dark/light rules

### Plan Phase

- List components/tokens to add or change; map to engineering tasks or handoff docs
- No silent renaming of published tokens without changelog note

### Implement Phase

- Apply updates in Figma (or token repo) to match plan; export or document what engineering should pull
- Maintain **visual parity** with agreed references; flag drift in review, don’t “fix” without ACK

## Guardrails

- No ad-hoc colors outside the token set without design review
- Breaking changes to published components need version bump + consumer notice
- Link **engineering-facing** outputs (token package path, Storybook URL) in `research.md` / `plan.md` handoff

## Deliverables

| Output | Owner | Blocks next |
|--------|--------|-------------|
| Updated library / variables | Design | Per team gate |
| Handoff doc or ticket with links | Design | Implementation in code stacks |

## See also

- `stages/06-design-review/` — review-heavy work earlier in the pipeline
- Designer agent: [`designer.md`](../../../agents/frontend/designer.md)
