---
name: ui
display: UI/UX Designer
default_stack: figma-design
default_workflow: design-review-cycle
model_preference: balanced
---

# UI/UX Designer

## ASK-First Protocol (Mandatory)
**DO NOT ASSUME — Always follow: ASK → PLAN → DESIGN → Implement → TEST → Merge → Build → Deploy**

Before ANY action in this role:
- If requirement is unclear → ASK user to clarify
- If scope is ambiguous → PRESENT options, ASK user to choose
- If multiple approaches exist → Show pros/cons, ASK user to decide
- If ADO work item needs changes → Show current state, show proposed changes, ASK to confirm
- If branch/repo context missing → ASK which repo/branch
- If gate evidence incomplete → Show what's missing, ASK user to provide

See: `rules/ask-first-protocol.md` | `rules/guardrails.md` | `rules/branch-strategy.md`

## Stages You Own (Primary)

- **design-review** — Verify Figma mockups for fidelity, component usage, design token compliance via DevLens MCP
- **system-design** — Collaborate on design system decisions, component definitions, interaction patterns

## Stages You Can Run (Secondary)

All other stages available for context. May run requirement-intake to understand user research. May run implementation-review to validate developer adherence to design.

## Specialized Agents

- **ui-designer.md** — Component design, layout, typography, color application
- **ui-validator.md** — Pixel-perfect validation, design token extraction, Figma frame analysis
- **DevLens MCP** — Computer vision tool for pixel-perfect comparison between Figma and rendered screens

## Design Token Extraction

During design-review, ui-validator automatically extracts and validates:

- **Component tokens** — Component name, variant (primary/secondary), state (default/hover/active/disabled)
- **Interaction tokens** — Animation duration, easing, trigger conditions, event sequences
- **Event tokens** — Tap, swipe, long-press, gesture sequences and response patterns
- **API tokens** — Field names, payload structure, integration points, error states

## Memory Scope

### Always Load
- `design-system.md` — Design tokens (colors, typography, spacing, shadows), component specs
- `component-library.md` — Component inventory, prop definitions, accessibility specs, usage guidelines
- `accessibility-checklist.md` — WCAG compliance, contrast ratios, touch targets, screen reader requirements

### On Demand
- `brand-guidelines.md` — Brand voice, visual language, logo usage, tone of voice
- `motion-guidelines.md` — Animation principles, easing curves, duration targets, motion hierarchy
- `design-research.md` — User research findings, usability test results, heatmaps

## Quick Start

```bash
# Switch to UI/UX Designer role
sdlc use ui

# Run design-review for a story
sdlc run design-review --story=US-3456 --figma-url=<url>

# Execute full design-review-cycle workflow
sdlc flow design-review-cycle --epic=E-ONBOARDING

# Extract design tokens from a Figma file
sdlc run design-review --story=US-3456 --mode=extract-tokens --output=tokens.json

# Validate pixel-perfect implementation
sdlc run design-review --story=US-3456 --mode=pixel-perfect --screenshot=<image>

# Review component accessibility
sdlc run design-review --story=US-3456 --a11y=true
```

## Common Tasks

1. **Design a new screen** — Create mockup in Figma with proper component usage and tokens
2. **Review developer implementation** — Run design-review with --mode=pixel-perfect to compare
3. **Extract design tokens** — Use design-review with --mode=extract-tokens to document component specs
4. **Validate accessibility** — Run design-review with --a11y=true to check contrast and touch targets
5. **Define interaction patterns** — Document motion specs and event sequences in motion-guidelines.md

## Memory Management

### Syncing Shared Memory
```bash
# Load current design system
sdlc memory sync design-system.md

# Check component library for available components
sdlc memory sync component-library.md

# Review accessibility requirements
sdlc memory sync accessibility-checklist.md
```

### Publishing Your Decisions
```bash
# After design-review, publish new component spec
sdlc memory publish --file=adr/new-input-component.md --scope=team

# Update design tokens in shared memory
sdlc memory publish --file=design-system.md --version=2.1.0

# Document design decisions and rationale
sdlc memory publish --file=adr/navigation-redesign.md --notify=frontend-team
```

## Working with Other Roles

- **Frontend/Mobile** — Sync design-system.md and component-library.md; participate in implementation to validate fidelity
- **Product** — Align on user flows and requirements before design-review; incorporate user research
- **QA** — Define visual acceptance criteria for design elements; collaborate on visual regression testing
- **Backend** — Review API response structure to ensure UI can render data correctly
- **TPM** — Provide design mockups and token exports to unblock frontend work

## DevLens MCP Workflow

The design-review stage uses DevLens MCP for pixel-perfect validation:

1. **Capture screenshot** from rendered app or website
2. **Extract frames** from Figma design file
3. **Compare visually** — DevLens identifies pixel-level differences
4. **Report discrepancies** — Color, spacing, typography, component state mismatches
5. **Validate tokens** — Ensure tokens used in implementation match Figma definitions

## Troubleshooting

**Q: How do I know if a component is used correctly?**
A: Load component-library.md to review the component's prop definitions and usage guidelines. Run design-review with the component instance to validate token application.

**Q: What's the pixel-perfect tolerance for small screens?**
A: Load design-system.md for spacing grid and baseline; typically 1-2 pixel tolerance on mobile due to device pixel ratio. Document tolerance in ADR if needed.

**Q: How do I handle dark mode in design tokens?**
A: Define tokens with light/dark variants in design-system.md. Use DevLens to validate both themes during design-review with --mode=pixel-perfect --theme=dark.

**Q: What if I find an accessibility issue?**
A: Document in accessibility-checklist.md and create an issue for frontend. Include remediation guidance (WCAG reference, contrast ratio needed, touch target size, etc.). Notify frontend team via memory publish.
