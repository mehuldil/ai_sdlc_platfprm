#!/usr/bin/env node
/**
 * Markdown → HTML for Azure DevOps System.Description (readable spacing, lists, numbered scenarios).
 * Reads UTF-8 from stdin, writes HTML to stdout.
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
  return t;
}

const lines = md.split('\n');
const out = [];
let para = [];
let list = [];
let olOpen = false;

const P =
  '<p style="margin:0 0 12px 0;line-height:1.5;">';
const PC = '</p>';
const UL =
  '<ul style="margin:0 0 14px 0;padding-left:22px;line-height:1.5;">';
const ULC = '</ul>';
const LI = '<li style="margin-bottom:6px;">';
const LIC = '</li>';
const OL =
  '<ol style="margin:0 0 14px 0;padding-left:22px;line-height:1.5;list-style-type:decimal;">';
const H2 = (c) =>
  `<h2 style="margin:18px 0 10px 0;font-size:1.1em;line-height:1.35;">${c}</h2>`;
const H3 = (c) =>
  `<h3 style="margin:14px 0 8px 0;font-size:1.05em;line-height:1.35;">${c}</h3>`;

function closeOl() {
  if (olOpen) {
    out.push('</ol>');
    olOpen = false;
  }
}

function flushPara() {
  if (para.length) {
    closeOl();
    out.push(P + inlineFormat(para.join(' ')) + PC);
    para = [];
  }
}
function flushList() {
  if (list.length) {
    closeOl();
    out.push(UL + list.map((li) => LI + inlineFormat(li) + LIC).join('') + ULC);
    list = [];
  }
}

for (let i = 0; i < lines.length; i++) {
  const raw = lines[i];
  const line = raw.trimEnd();
  const t = line.trim();

  if (!t) {
    flushList();
    flushPara();
    continue;
  }

  if (t.startsWith('### ')) {
    flushList();
    flushPara();
    closeOl();
    out.push(H3(inlineFormat(t.slice(4))));
    continue;
  }
  if (t.startsWith('## ')) {
    flushList();
    flushPara();
    closeOl();
    out.push(H2(inlineFormat(t.slice(3))));
    continue;
  }
  if (t.startsWith('# ') && !t.startsWith('##')) {
    flushList();
    flushPara();
    closeOl();
    out.push(
      `<h1 style="margin:18px 0 10px 0;font-size:1.15em;">${inlineFormat(t.slice(2))}</h1>`
    );
    continue;
  }

  const bullet = t.match(/^[-*]\s+(.*)$/);
  if (bullet) {
    flushPara();
    list.push(bullet[1]);
    continue;
  }

  const numbered = t.match(/^(\d+)\.\s+(.*)$/);
  if (numbered) {
    flushPara();
    flushList();
    if (!olOpen) {
      out.push(OL);
      olOpen = true;
    }
    const parts = [numbered[2]];
    let j = i + 1;
    while (j < lines.length) {
      const nt = lines[j].trim();
      if (!nt) {
        j++;
        break;
      }
      if (/^\d+\.\s/.test(nt)) break;
      if (/^#{1,3}\s/.test(nt)) break;
      if (/^[-*]\s/.test(nt)) break;
      parts.push(nt);
      j++;
    }
    i = j - 1;
    const liInner = parts.map(inlineFormat).join('<br/>');
    out.push(
      '<li style="margin-bottom:14px;line-height:1.5;">' + liInner + '</li>'
    );
    continue;
  }

  const hr = /^---+$|^\*\*\*+$/.test(t);
  if (hr) {
    flushList();
    flushPara();
    closeOl();
    out.push(
      '<hr style="margin:14px 0;border:none;border-top:1px solid #e0e0e0;"/>'
    );
    continue;
  }

  flushList();
  closeOl();
  para.push(t);
}
flushList();
flushPara();
closeOl();

process.stdout.write(out.join(''));
