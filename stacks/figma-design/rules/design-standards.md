# Design System Standards (Figma)

## Design Tokens

### Color Palette
```json
{
  "primary-50": "#f0f9ff",
  "primary-500": "#0066ff",
  "primary-900": "#00264d",
  "neutral-0": "#ffffff",
  "neutral-100": "#f5f5f5",
  "neutral-900": "#1a1a1a",
  "semantic-error": "#dc2626",
  "semantic-success": "#16a34a",
  "semantic-warning": "#ea580c"
}
```

### Typography
- **System Font Stack**: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
- **Display**: 48px, bold
- **Heading 1**: 32px, bold
- **Heading 2**: 24px, semibold
- **Body**: 16px, regular
- **Caption**: 12px, regular
- **Line Height**: 1.5x font size (minimum)

### Spacing System (4px base)
- `space-1` = 4px
- `space-2` = 8px
- `space-3` = 12px
- `space-4` = 16px
- `space-6` = 24px
- `space-8` = 32px

### Shadows (Elevation)
```json
{
  "shadow-1": "0 1px 2px rgba(0,0,0,0.05)",
  "shadow-2": "0 4px 6px rgba(0,0,0,0.1)",
  "shadow-elevated": "0 16px 24px rgba(0,0,0,0.15)"
}
```

## Component Specifications

### Button Component
- **States**: Default, Hover, Pressed, Disabled
- **Sizes**: Small (32px), Medium (40px), Large (48px)
- **Variants**: Primary, Secondary, Tertiary
- **Padding**: space-4 horizontal, space-2 vertical

### Input Fields
- **Height**: 40px (medium)
- **Border**: 1px, neutral-300
- **Padding**: space-3
- **Focus**: Blue border, shadow-2

### Cards
- **Border Radius**: 8px
- **Padding**: space-4
- **Shadow**: shadow-1
- **Responsive**: Full width mobile, max-width 400px desktop

## Accessibility
- Color contrast ≥4.5:1 (AA standard)
- Interactive elements ≥44px touch target
- Alt text for all images
- Keyboard navigation for all interactions

---
**Last Updated**: 2026-04-10  
**Stack**: Figma Design
