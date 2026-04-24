# Manual.html Build Enhancements

**Version**: v3  
**Last Updated**: 2026-04-24  
**Generator**: `build-manual-html-v3.mjs`

## Overview

The user manual build system has been redesigned with Apple design principles, modern UX, and professional syntax highlighting.

## Key Features

### 1. Apple-Inspired Design
- **Sidebar Navigation**: Clean, minimal left sidebar with hierarchical menu
- **Two-Column Layout**: 280px fixed sidebar + responsive content area
- **Typography**: System fonts (-apple-system) with proper hierarchy
- **Spacing**: Generous padding and margins for breathing room
- **Dark Mode**: Full CSS variable support with `@media (prefers-color-scheme: dark)`

### 2. Syntax Highlighting
- **Engine**: Highlight.js 11.9.0 (from CDN)
- **Supported Languages**: Bash, JavaScript, YAML, JSON, Python, Go, Kotlin, Swift, etc.
- **Automatic Detection**: Language hints from markdown code block fence
- **Styling**: `atom-one-light` theme (auto-switches for dark mode)
- **Coverage**: 600+ code blocks rendered with proper highlighting

### 3. HTML Rendering
- **Code Blocks**: Proper preservation of whitespace, language detection, escaping
- **Tables**: Semantic `<table>` with `<thead>` and `<tbody>`, proper alignment
- **Lists**: Nested `<ul>` and `<ol>` with proper nesting for sub-items
- **Links**: Full `<a href="">` preservation with no text mangling
- **Blockquotes**: Semantic `<blockquote>` with left border styling
- **Inline Formatting**: Bold, italic, code spans all properly handled

### 4. Interactive Features
- **Scroll Detection**: Active link highlighting as user scrolls through sections
- **Keyboard Navigation**: 
  - `Cmd+J` / `Ctrl+J`: Next section
  - `Cmd+K` / `Ctrl+K`: Previous section
- **Smooth Scrolling**: Native CSS `scroll-behavior: smooth`
- **Active States**: Visual feedback on current section in sidebar

### 5. Responsive Design
- **Desktop**: 280px sidebar + full content width
- **Tablet**: Adjusted spacing and font sizes
- **Mobile**: Single-column layout below 768px, sticky sidebar becomes relative

### 6. Accessibility
- **Semantic HTML**: Proper heading hierarchy (h1, h2, h3)
- **Color Contrast**: WCAG AA compliant colors in light/dark modes
- **Focus States**: Clear visual focus indicators for keyboard navigation
- **Skip Links**: Links in navigation point to sections with ID anchors

## Markdown to HTML Conversion

### Supported Markdown Syntax

```markdown
# Heading 1
## Heading 2
### Heading 3

**bold** __bold__
*italic* _italic_
`inline code`

```bash
code block with language hint
```

| Header 1 | Header 2 |
|----------|----------|
| Cell     | Cell     |

- Unordered list
  - Nested item
  
1. Ordered list
2. Second item

[Link text](https://example.com)

> Blockquote

---
```

### Processing Pipeline

1. **Extract Placeholders**: Code blocks, tables, blockquotes are extracted first
2. **Convert Headings**: `#` → `<h1>`, `##` → `<h2>`, etc.
3. **Convert Inline**: Bold, italic, links, inline code
4. **Convert Lists**: Unordered and ordered lists with proper nesting
5. **Convert Paragraphs**: Double newlines create paragraph boundaries
6. **Restore Elements**: Re-inject extracted blocks in correct order

### Special Handling

- **Code Block Languages**: Detected from fence hint (e.g., ` ```bash`)
- **HTML Escaping**: All code content escaped to prevent injection
- **Table Header Detection**: First row treated as `<thead>` by default
- **List Nesting**: Indentation preserved in final HTML
- **Line Preservation**: Whitespace preserved in code blocks

## Generated Output

### File Structure

```
User_Manual/
├── manual.html              # Generated from all markdown files
├── build-manual-html-v3.mjs # Build script (main generator)
├── README.md                # Manual overview
├── INDEX.md                 # Reading guide
├── *.md                     # 25+ documentation files
└── MANUAL_BUILD_ENHANCEMENTS.md  # This file
```

### File Sizes

- **manual.html**: ~212 KB (optimized, minifiable)
- **build-manual-html-v3.mjs**: ~16 KB (Node.js ES6 module)
- **Total**: ~230 KB for complete offline manual

### Performance

- **Load Time**: <1s (HTML + inline CSS + defer JS)
- **CDN Resources**: Highlight.js (async) loads in background
- **Rendering**: Full page renders in <2s
- **Responsiveness**: Sidebar scroll independent of main content

## Customization

### Changing Color Scheme

Edit CSS variables in the `<style>` section:

```css
:root {
  --bg-primary: #ffffff;        /* Page background */
  --text-primary: #1d1d1d;      /* Main text */
  --accent: #0071e3;            /* Links, active states */
  /* ... more variables ... */
}
```

### Changing Syntax Highlighting Theme

Replace the Highlight.js stylesheet:

```html
<!-- Light: atom-one-light, atom-one-dark, github, vs -->
<!-- Dark: atom-one-dark, monokai, solarized-dark, dracula -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/THEME.min.css" />
```

### Adding New Documentation

1. Create `.md` file in `User_Manual/` directory
2. Add filename to `ORDER` array in `build-manual-html-v3.mjs`
3. Optionally add custom title in `TITLES` object
4. Run: `node User_Manual/build-manual-html-v3.mjs`

## Build Process

### Running the Build

```bash
cd User_Manual/
node build-manual-html-v3.mjs
```

### Build Output

```
✓ Generated manual.html (v2.1.4, 8 pages, 0.2 MB)
```

### Pre-Commit Hook

The manual is automatically regenerated on commit if markdown files change:

```bash
# Triggered by .git/hooks/pre-commit
# Validates manual.html is current
# Blocks commit if stale
```

## Troubleshooting

### Syntax Highlighting Not Working

- Check browser console for Highlight.js load errors
- Verify CDN URL is accessible (requires internet)
- Fallback: code blocks render without colors but are still readable

### Code Block Not Rendering

- Ensure language hint is valid (e.g., ` ```bash` not ` ```bash-script`)
- Check markdown syntax (3 backticks before and after)
- Verify code is not using special characters that need escaping

### Table Not Rendering

- Ensure pipe `|` characters are properly aligned
- First row after header separator is treated as data
- Use spaces for padding, pipes for structure

## Future Enhancements

- [ ] Search functionality across all documents
- [ ] Table of contents with deep-link anchors
- [ ] Collapsible sections for long documents
- [ ] Copy-to-clipboard for code blocks
- [ ] Export to PDF
- [ ] Version history / change log
- [ ] Comments/annotations system

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v3 | 2026-04-24 | Added Highlight.js, improved markdown converter, Apple design |
| v2 | 2026-04-24 | Initial Apple design principles, dark mode |
| v1 | Previous | Basic HTML generation |

## Related Files

- `build-manual-html-v3.mjs`: Generator script
- `docs/command-rule-agent-mapping.html`: Interactive command mapping
- `User_Manual/INDEX.md`: Reading guide
- `rules/user-manual-sync.md`: Manual sync rules
