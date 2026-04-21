#!/usr/bin/env node
/**
 * Markdown → HTML with proper table support for Azure DevOps
 */
const fs = require('fs');

let md = fs.readFileSync(0, 'utf8');
md = md.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function inlineFormat(s) {
  let t = escapeHtml(s);
  t = t.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  t = t.replace(/`([^`]+)`/g, '<code>$1</code>');
  t = t.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  return t;
}

// Process tables first
function processTables(text) {
  const lines = text.split('\n');
  const result = [];
  let i = 0;
  
  while (i < lines.length) {
    const line = lines[i];
    
    // Check if this is a table row (starts with |)
    if (line.trim().startsWith('|')) {
      // Collect all table rows
      const tableLines = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        tableLines.push(lines[i]);
        i++;
      }
      
      // Skip separator line (contains ---)
      const dataLines = tableLines.filter(l => !l.replace(/\|/g, '').trim().match(/^[-:]+$/));
      
      if (dataLines.length > 0) {
        // Build HTML table (with raw HTML, not escaped)
        let html = '<!--TABLE_START--><table style="border-collapse:collapse;width:100%;margin:10px 0;font-size:13px;">';
        
        // First row is header
        const headerCells = dataLines[0].split('|').filter(c => c.trim() !== '');
        html += '<thead><tr>';
        headerCells.forEach(cell => {
          html += `<th style="border:1px solid #ddd;padding:8px;text-align:left;background:#f5f5f5;font-weight:bold;">${inlineFormat(cell.trim())}</th>`;
        });
        html += '</tr></thead>';
        
        // Remaining rows are data
        if (dataLines.length > 1) {
          html += '<tbody>';
          for (let j = 1; j < dataLines.length; j++) {
            const cells = dataLines[j].split('|').filter(c => c.trim() !== '');
            html += '<tr>';
            cells.forEach(cell => {
              html += `<td style="border:1px solid #ddd;padding:8px;text-align:left;">${inlineFormat(cell.trim())}</td>`;
            });
            html += '</tr>';
          }
          html += '</tbody>';
        }
        
        html += '</table><!--TABLE_END-->';
        result.push(html);
      }
    } else {
      result.push(line);
      i++;
    }
  }
  
  return result.join('\n');
}

// Process non-table content
function processContent(text) {
  const lines = text.split('\n');
  const out = [];
  let para = [];
  let list = [];
  let olOpen = false;

  const P = '<p style="margin:0 0 12px 0;line-height:1.5;">';
  const PC = '</p>';
  const UL = '<ul style="margin:0 0 14px 0;padding-left:22px;line-height:1.5;">';
  const ULC = '</ul>';
  const LI = '<li style="margin-bottom:6px;">';
  const LIC = '</li>';
  const OL = '<ol style="margin:0 0 14px 0;padding-left:22px;line-height:1.5;list-style-type:decimal;">';
  const H2 = (c) => `<h2 style="margin:18px 0 10px 0;font-size:1.1em;line-height:1.35;">${c}</h2>`;
  const H3 = (c) => `<h3 style="margin:14px 0 8px 0;font-size:1.05em;line-height:1.35;">${c}</h3>`;

  function closeOl() {
    if (olOpen) {
      out.push('</ol>');
      olOpen = false;
    }
  }

  function flushPara() {
    if (para.length) {
      closeOl();
      const content = para.join(' ').trim();
      if (content) {
        out.push(P + inlineFormat(content) + PC);
      }
      para = [];
    }
  }

  function flushList() {
    if (list.length) {
      closeOl();
      out.push(UL);
      list.forEach(item => {
        out.push(LI + inlineFormat(item) + LIC);
      });
      out.push(ULC);
      list = [];
    }
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Skip table lines (already processed) - keep raw HTML
    if (line.includes('<!--TABLE_START-->')) {
      flushPara();
      flushList();
      // Extract table HTML without escaping
      const tableHtml = line.replace('<!--TABLE_START-->', '').replace('<!--TABLE_END-->', '');
      out.push(tableHtml);
      continue;
    }
    if (line.trim().startsWith('|')) {
      continue; // Skip raw table lines
    }

    // Headers
    if (line.startsWith('## ')) {
      flushPara();
      flushList();
      closeOl();
      out.push(H2(inlineFormat(line.replace(/^## /, ''))));
      continue;
    }
    if (line.startsWith('### ')) {
      flushPara();
      flushList();
      closeOl();
      out.push(H3(inlineFormat(line.replace(/^### /, ''))));
      continue;
    }
    if (line.startsWith('# ')) {
      flushPara();
      flushList();
      closeOl();
      out.push(`<h1 style="margin:18px 0 10px 0;font-size:1.15em;">${inlineFormat(line.replace(/^# /, ''))}</h1>`);
      continue;
    }

    // Horizontal rule
    if (line.replace(/-/g, '').trim() === '' && line.length >= 3) {
      flushPara();
      flushList();
      closeOl();
      out.push('<hr style="margin:14px 0;border:none;border-top:1px solid #e0e0e0;">');
      continue;
    }

    // Blockquote
    if (line.startsWith('> ')) {
      flushPara();
      flushList();
      out.push('<blockquote style="margin:10px 0;padding:10px 15px;border-left:3px solid #ddd;background:#f9f9f9;">');
      out.push(inlineFormat(line.replace(/^> /, '')));
      out.push('</blockquote>');
      continue;
    }

    // Unordered list
    if (line.match(/^\s*[-\*]\s/)) {
      flushPara();
      const item = line.replace(/^\s*[-\*]\s/, '');
      if (list.length === 0) closeOl();
      list.push(item);
      continue;
    }

    // Ordered list (numbered scenarios)
    if (line.match(/^\s*\d+\.\s/)) {
      flushPara();
      flushList();
      if (!olOpen) {
        out.push(OL);
        olOpen = true;
      }
      const item = line.replace(/^\s*\d+\.\s/, '');
      out.push(LI + inlineFormat(item) + LIC);
      continue;
    }

    // Checkbox items
    if (line.match(/^\s*\d*\.\s*\[([ x])\]/)) {
      flushPara();
      flushList();
      const checked = line.includes('[x]');
      const itemText = line.replace(/^\s*\d*\.\s*\[[ x]\]\s*/, '');
      const checkbox = checked ? '☑' : '☐';
      if (!olOpen) {
        out.push(OL);
        olOpen = true;
      }
      out.push(LI + checkbox + ' ' + inlineFormat(itemText) + LIC);
      continue;
    }

    // Empty line
    if (line.trim() === '') {
      flushPara();
      flushList();
      continue;
    }

    // Regular paragraph text
    para.push(line);
  }

  flushPara();
  flushList();
  closeOl();

  return out.join('\n');
}

// Main processing
const withTables = processTables(md);
const html = processContent(withTables);
process.stdout.write(html);
