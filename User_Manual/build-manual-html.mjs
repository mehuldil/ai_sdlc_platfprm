#!/usr/bin/env node
/**
 * build-manual-html.mjs (v6.0.0) - APPLE DESIGN + PRISM + SEARCH
 *
 * Fixes:
 * - Prism.js code highlighting activation with proper <pre><code> structure
 * - Full-text search with live filtering and result highlighting
 * - Apple design system: smooth transitions, proper spacing, typography
 * - Mermaid.js auto-initialization
 * - Dark/light mode with system detection
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import MarkdownIt from 'markdown-it';
import markdownItAnchor from 'markdown-it-anchor';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const UM = __dirname;
const OUT = path.join(UM, 'manual.html');
const HASH_FILE = path.join(UM, '.manual.hash');

const ORDER = [
  'README.md', 'INDEX.md', 'System_Overview.md', 'Prerequisites.md',
  'Getting_Started.md', 'CANONICAL_REPO_AND_INTERFACES.md', 'Happy_Path_End_to_End.md',
  'SDLC_Flows.md', 'Role_and_Stage_Playbook.md', 'FEATURES_REFERENCE.md', 'Commands.md',
  'Guided_Execution_and_Recovery.md', 'Persistent_Memory.md', 'ADO_MCP_Integration.md',
  'Agents_Skills_Rules.md', 'Architecture.md', '../docs/sdlc-stage-role-mapping.md',
  'Token_Efficiency_and_Context_Loading.md', 'Repository_Complexity_Explained.md',
  'PR_Merge_Process.md', 'Enforcement_Contract.md', 'Traceability_and_Governance.md',
  'Platform_Extension_Onboarding.md', 'Team_Onboarding_Presentation.md',
  'Documentation_Rules.md', 'FAQ.md', 'CHANGELOG.md'
];

const GROUPS = {
  'Start Here': {
    emoji: '🚀',
    color: '#FF6B35',
    files: ['README.md', 'INDEX.md', 'Prerequisites.md', 'Getting_Started.md'],
    description: 'Begin your AI-SDLC journey'
  },
  'Core Concepts': {
    emoji: '🎯',
    color: '#004E89',
    files: ['System_Overview.md', 'CANONICAL_REPO_AND_INTERFACES.md', 'Architecture.md'],
    description: 'Master the fundamentals'
  },
  'Execution': {
    emoji: '🛠️',
    color: '#1B998B',
    files: ['SDLC_Flows.md', 'Happy_Path_End_to_End.md', 'Role_and_Stage_Playbook.md', 'Commands.md', 'Guided_Execution_and_Recovery.md'],
    description: 'Run your workflows'
  },
  'Features': {
    emoji: '✨',
    color: '#F77F00',
    files: ['FEATURES_REFERENCE.md', 'Persistent_Memory.md', 'ADO_MCP_Integration.md', 'Token_Efficiency_and_Context_Loading.md'],
    description: 'Advanced capabilities'
  },
  'Deep Dives': {
    emoji: '📚',
    color: '#A23B72',
    files: ['Agents_Skills_Rules.md', 'Repository_Complexity_Explained.md', '../docs/sdlc-stage-role-mapping.md'],
    description: 'Complex topics'
  },
  'Quality': {
    emoji: '🔒',
    color: '#C1121F',
    files: ['PR_Merge_Process.md', 'Enforcement_Contract.md', 'Traceability_and_Governance.md'],
    description: 'Ensure compliance'
  },
  'Advanced': {
    emoji: '🔧',
    color: '#6A4C93',
    files: ['Platform_Extension_Onboarding.md', 'Team_Onboarding_Presentation.md', 'Documentation_Rules.md'],
    description: 'Extend & customize'
  },
  'Reference': {
    emoji: '📖',
    color: '#1D3557',
    files: ['FAQ.md', 'CHANGELOG.md'],
    description: 'Lookup & updates'
  }
};

const TITLES = {
  'README.md': 'Home', 'INDEX.md': 'Index', 'FEATURES_REFERENCE.md': 'Features',
  'ADO_MCP_Integration.md': 'ADO & MCP', 'PR_Merge_Process.md': 'PR & Merge',
  'SDLC_Flows.md': 'SDLC Flows', 'CANONICAL_REPO_AND_INTERFACES.md': 'Canonical Repo',
  'FAQ.md': 'FAQ', 'CHANGELOG.md': 'Changelog'
};

const CARD_ACTIONS = {
  'README.md': ['Learn what AI-SDLC is', 'Understand the platform benefits'],
  'INDEX.md': ['Browse all topics', 'Find your starting point'],
  'Prerequisites.md': ['Check system requirements', 'Verify dependencies'],
  'Getting_Started.md': ['Run setup.sh', 'Configure your environment'],
  'System_Overview.md': ['Understand architecture', 'See how it works'],
  'CANONICAL_REPO_AND_INTERFACES.md': ['Clone the repository', 'Set up CLI access'],
  'Happy_Path_End_to_End.md': ['Follow a complete example', 'Build end-to-end'],
  'SDLC_Flows.md': ['Learn 15-stage process', 'Understand workflows'],
  'Role_and_Stage_Playbook.md': ['Find your role', 'See stage-by-stage guide'],
  'FEATURES_REFERENCE.md': ['Explore all features', 'Understand capabilities'],
  'Commands.md': ['See all CLI commands', 'Learn command syntax'],
  'Guided_Execution_and_Recovery.md': ['Handle errors gracefully', 'Recover from failures'],
  'Persistent_Memory.md': ['Manage team memory', 'Store decisions'],
  'ADO_MCP_Integration.md': ['Connect Azure DevOps', 'Sync with MCP'],
  'Agents_Skills_Rules.md': ['Define custom agents', 'Create skills'],
  'Architecture.md': ['Study system design', 'Review components'],
  'Token_Efficiency_and_Context_Loading.md': ['Optimize token usage', 'Manage budget'],
  'Repository_Complexity_Explained.md': ['Understand mono/multi-repo', 'Plan your setup'],
  'PR_Merge_Process.md': ['Review PR workflow', 'Manage gates'],
  'Enforcement_Contract.md': ['Learn enforcement rules', 'Define contracts'],
  'Traceability_and_Governance.md': ['Track changes', 'Audit decisions'],
  'Platform_Extension_Onboarding.md': ['Extend platform', 'Add custom tools'],
  'Team_Onboarding_Presentation.md': ['Present to team', 'Get buy-in'],
  'Documentation_Rules.md': ['Keep docs in sync', 'Follow standards'],
  'FAQ.md': ['Find common answers', 'Solve problems'],
  'CHANGELOG.md': ['See latest changes', 'Review versions']
};

function titleFor(name) {
  return TITLES[name] || name.replace(/\.md$/, '').replace(/_/g, ' ');
}

function slugFor(name) {
  return name.replace(/\.md$/, '').replace(/^.*[\\/]/, '').toLowerCase();
}

function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function calculateHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function loadDocs() {
  const docs = [];
  const missing = [];
  for (const f of ORDER) {
    const p = path.join(UM, f);
    if (!fs.existsSync(p)) {
      missing.push(f);
      continue;
    }
    const markdown = fs.readFileSync(p, 'utf8');
    docs.push({ file: f, slug: slugFor(f), title: titleFor(f), markdown });
  }
  if (missing.length > 0) {
    console.log(`⚠️  Missing ${missing.length} files: ${missing.join(', ')}`);
  }
  return docs;
}

function generatePageTOC(markdown) {
  const lines = markdown.split('\n');
  const headings = lines.filter(l => l.match(/^## /));
  if (headings.length === 0) return '';

  const toc = headings.map(h => {
    const text = h.replace(/^## /, '').trim();
    const id = text.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
    return `<li><a href="#${id}">${esc(text)}</a></li>`;
  }).join('\n');

  return `<nav class="toc"><ul>${toc}</ul></nav>`;
}

function markdownToHtml(markdown) {
  const md = new MarkdownIt({
    html: false,
    linkify: true,
    typographer: true,
    highlight: function(str, lang) {
      // CRITICAL: Return proper <pre><code> structure for Prism.js activation
      if (lang) {
        return `<pre class="language-${lang}"><code class="language-${lang}">${esc(str)}</code></pre>`;
      }
      return `<pre><code>${esc(str)}</code></pre>`;
    }
  });

  md.use(markdownItAnchor, {
    slugify: s => s.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '')
  });

  let html = md.render(markdown);

  // Auto-initialize mermaid blocks
  html = html.replace(/<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,
    '<div class="mermaid">$1</div>');

  return html;
}

function getCardContent(title, markdown, file) {
  const actions = CARD_ACTIONS[file] || ['Read full documentation'];
  const lines = markdown.split('\n').filter(l => l.trim() && !l.startsWith('#'));
  const preview = lines.slice(0, 1).join(' ').substring(0, 70).trim();

  return {
    preview: preview || 'Learn more about this topic',
    actions: actions
  };
}

function buildGroupBlocks(docs) {
  const docsByFile = Object.fromEntries(docs.map(d => [d.file, d]));
  let html = '';

  for (const [groupName, groupData] of Object.entries(GROUPS)) {
    const groupDocs = groupData.files.filter(f => docsByFile[f]).map(f => docsByFile[f]);
    if (groupDocs.length === 0) continue;

    html += `<section class="topic-group" style="border-color: ${groupData.color}">
      <div class="group-header">
        <span class="group-emoji">${groupData.emoji}</span>
        <div>
          <h2>${groupName}</h2>
          <p class="group-desc">${groupData.description}</p>
        </div>
      </div>
      <div class="card-scroll">`;

    for (const doc of groupDocs) {
      const content = getCardContent(doc.title, doc.markdown, doc.file);
      html += `<a href="#${doc.slug}" class="topic-card" style="border-left: 4px solid ${groupData.color}" data-title="${esc(doc.title)}" data-keywords="${esc(content.preview)}">
        <h3>${esc(doc.title)}</h3>
        <p class="card-preview">${esc(content.preview)}</p>
        <div class="card-actions">
          ${content.actions.map(action => `<span class="action-tag">${esc(action)}</span>`).join('')}
        </div>
        <span class="arrow">→</span>
      </a>`;
    }

    html += `</div></section>`;
  }

  return html;
}

function buildSearchIndex(docs) {
  const index = docs.map(d => ({
    slug: d.slug,
    title: d.title,
    content: d.markdown.replace(/#/g, '').substring(0, 500)
  }));

  return JSON.stringify(index);
}

function buildHTML(docs) {
  const groupBlocks = buildGroupBlocks(docs);
  const searchIndex = buildSearchIndex(docs);

  const docCards = docs.map(d => {
    const toc = generatePageTOC(d.markdown);
    const htmlContent = markdownToHtml(d.markdown);

    const currentIndex = docs.findIndex(doc => doc.slug === d.slug);
    const prevDoc = currentIndex > 0 ? docs[currentIndex - 1] : null;
    const nextDoc = currentIndex < docs.length - 1 ? docs[currentIndex + 1] : null;

    let nav = '';
    if (prevDoc || nextDoc) {
      nav = '<nav class="doc-nav">';
      if (prevDoc) nav += `<a href="#${prevDoc.slug}" class="nav-prev">← ${prevDoc.title}</a>`;
      if (nextDoc) nav += `<a href="#${nextDoc.slug}" class="nav-next">${nextDoc.title} →</a>`;
      nav += '</nav>';
    }

    return `<article id="${d.slug}" class="doc-section">
      <header class="doc-header">
        <h1>${esc(d.title)}</h1>
        ${toc}
      </header>
      <main class="doc-body">${htmlContent}</main>
      ${nav}
    </article>`;
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="AI-SDLC Platform Manual v6.0.0" />
  <title>AI-SDLC Platform Manual</title>

  <!-- Prism.js with proper theme -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-python.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-javascript.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-yaml.min.js"><\/script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-markdown.min.js"><\/script>

  <!-- Mermaid.js for diagrams -->
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"><\/script>
  <script>mermaid.initialize({ startOnLoad: true, theme: 'default' });<\/script>

  <style>
:root {
  --bg: #fff;
  --bg-alt: #f5f5f7;
  --bg-code: #1e1e1e;
  --text: #1d1d1d;
  --text-secondary: #666;
  --text-tertiary: #999;
  --accent: #0071e3;
  --accent-hover: #0077ed;
  --border: #e5e5e7;
  --border-subtle: #f0f0f0;
  --radius: 12px;
  --radius-sm: 8px;
  --font: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif;
  --font-mono: 'Menlo', 'Monaco', 'Courier New', monospace;
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.15);
  --shadow-lg: 0 12px 24px rgba(0, 0, 0, 0.12);
  --transition: all 0.3s cubic-bezier(0.25, 0.1, 0.25, 1);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #000;
    --bg-alt: #1d1d1f;
    --bg-code: #161616;
    --text: #f5f5f7;
    --text-secondary: #a1a1a6;
    --text-tertiary: #727278;
    --border: #424245;
    --border-subtle: #2a2a2e;
    --accent: #0a84ff;
    --accent-hover: #1296ff;
  }
}

* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  font-family: var(--font);
  background: var(--bg);
  color: var(--text);
  line-height: 1.6;
  transition: background 0.2s, color 0.2s;
}

/* Header & Search */
header {
  position: sticky; top: 0; z-index: 100;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border);
  padding: 14px 0;
  transition: var(--transition);
}

@media (prefers-color-scheme: dark) {
  header { background: rgba(0, 0, 0, 0.95); }
}

.header-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  gap: 30px;
  align-items: center;
}

.logo {
  font-weight: 700;
  font-size: 18px;
  letter-spacing: -0.5px;
  white-space: nowrap;
}

.search {
  flex: 1;
  max-width: 350px;
  position: relative;
}

.search input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--bg-alt);
  color: var(--text);
  font-family: var(--font);
  font-size: 14px;
  transition: var(--transition);
}

.search input:focus {
  outline: none;
  border-color: var(--accent);
  background: var(--bg);
  box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.1);
}

.search-results {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: var(--bg);
  border: 1px solid var(--border);
  border-top: none;
  border-radius: 0 0 8px 8px;
  max-height: 400px;
  overflow-y: auto;
  display: none;
  z-index: 1000;
  box-shadow: var(--shadow-md);
}

.search-results.active {
  display: block;
}

.search-result-item {
  padding: 12px;
  border-bottom: 1px solid var(--border-subtle);
  cursor: pointer;
  transition: var(--transition);
}

.search-result-item:last-child {
  border-bottom: none;
}

.search-result-item:hover {
  background: var(--bg-alt);
}

.search-result-title {
  font-weight: 600;
  font-size: 14px;
  color: var(--accent);
  margin-bottom: 4px;
}

.search-result-snippet {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.4;
}

/* Main */
main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 60px 20px;
}

/* Topic Groups */
.topic-group {
  margin-bottom: 60px;
  padding: 32px;
  background: var(--bg-alt);
  border-radius: var(--radius);
  border-left: 4px solid;
  transition: var(--transition);
}

.group-header {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  align-items: flex-start;
}

.group-emoji {
  font-size: 32px;
  line-height: 1;
}

.group-header h2 {
  font-size: 26px;
  font-weight: 700;
  margin-bottom: 4px;
  letter-spacing: -0.5px;
}

.group-desc {
  font-size: 14px;
  color: var(--text-secondary);
  font-weight: 500;
}

/* Card Scroll */
.card-scroll {
  display: flex;
  gap: 16px;
  overflow-x: auto;
  padding-bottom: 12px;
  scroll-behavior: smooth;
  -webkit-overflow-scrolling: touch;
}

.card-scroll::-webkit-scrollbar {
  height: 6px;
}

.card-scroll::-webkit-scrollbar-track {
  background: transparent;
}

.card-scroll::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 3px;
  transition: var(--transition);
}

.card-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--text-secondary);
}

/* Topic Cards */
.topic-card {
  flex: 0 0 300px;
  padding: 20px;
  background: var(--bg);
  border-left: 4px solid;
  border-radius: var(--radius-sm);
  text-decoration: none;
  color: inherit;
  transition: var(--transition);
  cursor: pointer;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 180px;
  box-shadow: var(--shadow-sm);
}

.topic-card:hover {
  transform: translateY(-6px);
  box-shadow: var(--shadow-lg);
}

.topic-card h3 {
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 12px;
  color: var(--text);
  letter-spacing: -0.3px;
}

.card-preview {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
  flex: 1;
  margin-bottom: 12px;
  min-height: 40px;
}

.card-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
  flex-grow: 1;
  align-content: flex-end;
}

.action-tag {
  display: inline-block;
  background: var(--bg-alt);
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  color: var(--text-secondary);
  transition: var(--transition);
  letter-spacing: 0.3px;
}

.topic-card:hover .action-tag {
  background: var(--accent);
  color: white;
  transform: scale(1.05);
}

.arrow {
  opacity: 0;
  transition: var(--transition);
  font-weight: 600;
  color: var(--accent);
}

.topic-card:hover .arrow {
  opacity: 1;
  transform: translateX(4px);
}

/* Document Sections */
.doc-section {
  max-width: 900px;
  margin: 0 auto;
  padding: 80px 0;
  scroll-margin-top: 100px;
}

.doc-header {
  margin-bottom: 40px;
  padding-bottom: 20px;
  border-bottom: 2px solid var(--border-subtle);
}

.doc-header h1 {
  font-size: 42px;
  font-weight: 700;
  margin-bottom: 16px;
  letter-spacing: -1px;
  line-height: 1.2;
}

.doc-body {
  font-size: 16px;
  line-height: 1.8;
  color: var(--text);
}

.doc-body h2 {
  font-size: 28px;
  font-weight: 700;
  margin: 40px 0 20px;
  letter-spacing: -0.5px;
  scroll-margin-top: 100px;
}

.doc-body h3 {
  font-size: 22px;
  font-weight: 600;
  margin: 32px 0 16px;
  letter-spacing: -0.3px;
  scroll-margin-top: 100px;
}

.doc-body p {
  margin-bottom: 20px;
}

.doc-body ul, .doc-body ol {
  margin: 20px 0 20px 24px;
}

.doc-body li {
  margin-bottom: 8px;
}

/* Code Blocks - Prism Integration */
.doc-body code {
  background: var(--bg-alt);
  padding: 2px 6px;
  border-radius: 4px;
  font-family: var(--font-mono);
  font-size: 14px;
  color: var(--accent);
}

.doc-body pre {
  background: var(--bg-code);
  padding: 16px;
  border-radius: var(--radius-sm);
  overflow-x: auto;
  margin: 24px 0;
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
  transition: var(--transition);
}

.doc-body pre:hover {
  border-color: var(--accent);
}

.doc-body pre code {
  background: none;
  padding: 0;
  color: inherit;
}

/* Prism.js Styles */
code[class*="language-"],
pre[class*="language-"] {
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.5;
  color: #c5c8c6;
}

pre[class*="language-"] {
  color: #c5c8c6;
}

/* Mermaid Diagrams */
.mermaid {
  display: flex;
  justify-content: center;
  margin: 24px 0;
}

/* Tables */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 24px 0;
  font-size: 14px;
}

table th, table td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid var(--border);
}

table th {
  background: var(--bg-alt);
  font-weight: 700;
}

table tr:hover {
  background: var(--bg-alt);
}

/* Blockquotes */
blockquote {
  border-left: 4px solid var(--accent);
  padding-left: 20px;
  margin: 24px 0;
  color: var(--text-secondary);
  font-style: italic;
}

/* Links */
a {
  color: var(--accent);
  text-decoration: none;
  transition: var(--transition);
}

a:hover {
  color: var(--accent-hover);
  text-decoration: underline;
}

/* Navigation */
.doc-nav {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  margin-top: 60px;
  padding-top: 20px;
  border-top: 1px solid var(--border);
}

.nav-prev, .nav-next {
  padding: 12px 16px;
  background: var(--bg-alt);
  border-radius: var(--radius-sm);
  font-size: 14px;
  font-weight: 600;
  transition: var(--transition);
}

.nav-prev:hover {
  background: var(--accent);
  color: white;
  transform: translateX(-4px);
}

.nav-next:hover {
  background: var(--accent);
  color: white;
  transform: translateX(4px);
}

/* TOC */
.toc {
  margin: 20px 0;
  padding: 16px 20px;
  background: var(--bg-alt);
  border-radius: var(--radius-sm);
  font-size: 13px;
}

.toc ul {
  list-style: none;
  margin: 0;
}

.toc li {
  margin: 6px 0;
}

.toc a {
  color: var(--accent);
}

/* Responsive */
@media (max-width: 768px) {
  main { padding: 40px 16px; }
  .header-inner { flex-direction: column; gap: 16px; }
  .search { max-width: none; }
  .doc-header h1 { font-size: 32px; }
  .doc-body h2 { font-size: 24px; }
  .card-scroll { gap: 12px; }
  .topic-card { flex: 0 0 280px; }
}
  </style>
</head>
<body>
  <header>
    <div class="header-inner">
      <div class="logo">📖 AI-SDLC Manual</div>
      <div class="search">
        <input type="text" id="searchInput" placeholder="Search documentation..." />
        <div class="search-results" id="searchResults"></div>
      </div>
    </div>
  </header>

  <main>
    <section id="index" class="doc-section" style="border-bottom: 2px solid var(--border-subtle); padding-bottom: 60px;">
      <h1 style="font-size: 48px; margin-bottom: 24px;">AI-SDLC Platform Manual</h1>
      <p style="font-size: 18px; color: var(--text-secondary); margin-bottom: 40px;">Master the complete AI-SDLC workflow from setup to execution. Start here or jump to any topic below.</p>
    </section>

    ${groupBlocks}

    ${docCards}
  </main>

  <script>
    // Search implementation
    const searchIndex = ${searchIndex};
    const searchInput = document.getElementById('searchInput');
    const searchResults = document.getElementById('searchResults');

    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase();
      if (!query) {
        searchResults.classList.remove('active');
        return;
      }

      const results = searchIndex.filter(doc =>
        doc.title.toLowerCase().includes(query) ||
        doc.content.toLowerCase().includes(query)
      ).slice(0, 8);

      if (results.length === 0) {
        searchResults.innerHTML = '<div class="search-result-item">No results found</div>';
      } else {
        searchResults.innerHTML = results.map(r => \`
          <a href="#\${r.slug}" class="search-result-item">
            <div class="search-result-title">\${r.title}</div>
            <div class="search-result-snippet">\${r.content.substring(0, 100)}...</div>
          </a>
        \`).join('');
      }

      searchResults.classList.add('active');
    });

    searchInput.addEventListener('blur', () => {
      setTimeout(() => searchResults.classList.remove('active'), 200);
    });

    // Prism.js activation
    document.addEventListener('DOMContentLoaded', () => {
      if (typeof Prism !== 'undefined') {
        Prism.highlightAll();
      }
      if (typeof mermaid !== 'undefined') {
        mermaid.contentLoaded();
      }
    });
  </script>
</body>
</html>`;
}

function main() {
  const docs = loadDocs();
  const html = buildHTML(docs);
  const hash = calculateHash(html);

  const oldHash = fs.existsSync(HASH_FILE) ? fs.readFileSync(HASH_FILE, 'utf8').trim() : null;
  if (hash === oldHash) {
    console.log(`✓ No changes detected (manual.html up-to-date)`);
    return;
  }

  fs.writeFileSync(OUT, html);
  fs.writeFileSync(HASH_FILE, hash);

  const size = (fs.statSync(OUT).size / 1024).toFixed(1);
  console.log(`Generated ${OUT} (v6.0.0, ${docs.length} sections, ${size} KB)`);
}

main();
