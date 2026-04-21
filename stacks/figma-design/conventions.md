# Figma Design System Conventions

## Overview
Figma is the single source of truth for design. Design tokens are extracted and synced to code.

## Component Naming
- **Format**: `{Feature}/{Component}/{State}` (slash separates hierarchy)
- Examples:
  - `Buttons/Primary/Default`
  - `Buttons/Primary/Hover`
  - `Buttons/Secondary/Disabled`
  - `Cards/User/Loaded`
  - `Cards/User/Skeleton`

## Layer Organization
```
Page: "Components"
├── Frame: "Buttons"
│   ├── Component: "Button / Primary"
│   │   ├── Group: "default"
│   │   ├── Group: "hover"
│   │   ├── Group: "disabled"
├── Frame: "Cards"
│   ├── Component: "Card / User"
│   │   ├── Group: "loaded"
│   │   ├── Group: "skeleton"
```

## Annotation Labels
- **COMPONENT**: Indicates reusable component
- **INTERACTION**: Indicates interactive state/animation
- **EVENT**: Indicates action/trigger (e.g., "on-click")
- **API**: Data binding annotation

Example:
```
Frame: "User Card" {label: "COMPONENT"}
├─ Text: "User Name" {label: "API:userData.name"}
├─ Image: "Avatar" {label: "API:userData.avatar"}
├─ Button: "Follow" {label: "INTERACTION:on-click"}
```

## Responsive Breakpoints
- **Mobile**: 375px (iPhone SE)
- **Tablet**: 768px (iPad)
- **Desktop**: 1440px (Desktop standard)
- **4K**: 2560px (TV/Large display)

Create variants for each breakpoint in components.

## Design Tokens Extraction
- **Location**: `src/tokens/` (from Figma export)
- **Format**: JSON (Figma Tokens plugin)
- **Categories**:
  - `colors.json` — Color palette (primary, secondary, neutral)
  - `typography.json` — Font sizes, weights, line heights
  - `spacing.json` — Margin/padding units (4px base)
  - `shadows.json` — Drop shadows, elevations
  - `borders.json` — Border radius, widths

## Token Naming
- **Colors**: `{purpose}-{shade}` (primary-500, neutral-100)
- **Typography**: `{size}-{weight}` (body-medium, heading-bold)
- **Spacing**: `space-{multiplier}` (space-1, space-4)
- **Shadows**: `shadow-{level}` (shadow-1, shadow-elevated)

---
**Last Updated**: 2026-04-10  
**Stack**: Figma Design
