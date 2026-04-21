#!/usr/bin/env node
/**
 * Convert ADO System.Description HTML into rough markdown so tier validators
 * (grep ## headers, Given/When/Then) can run. Reads stdin, writes stdout.
 */
const fs = require('fs');
const html = fs.readFileSync(0, 'utf8');
if (!html.trim()) process.exit(0);

function decodeEntities(s) {
  return s
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(+n))
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&nbsp;/g, ' ');
}

function stripTags(s) {
  return s.replace(/<[^>]+>/g, ' ');
}

const parts = [];
let rest = html.replace(/<h2[^>]*>([\s\S]*?)<\/h2>/gi, (_, inner) => {
  const text = decodeEntities(stripTags(inner)).replace(/\s+/g, ' ').trim();
  if (text) parts.push(`## ${text}\n`);
  return '\n';
});

rest = rest
  .replace(/<br\s*\/?>/gi, '\n')
  .replace(/<\/(p|div|li|tr)\s*>/gi, '\n');
rest = decodeEntities(stripTags(rest));
const body = rest
  .split('\n')
  .map((l) => l.replace(/\s+/g, ' ').trim())
  .filter(Boolean)
  .join('\n');

process.stdout.write(parts.join('\n') + (body ? '\n\n' + body + '\n' : ''));
