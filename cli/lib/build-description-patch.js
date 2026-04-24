#!/usr/bin/env node
/**
 * Reads markdown from stdin, converts to HTML (markdown-to-html.js), emits JSON Patch
 * for Azure DevOps System.Description. Avoids bash quoting/size limits on Windows.
<<<<<<< HEAD
=======
 * 
 * If input already contains HTML tags (<div>, <table>, etc.), uses it directly.
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
 *
 * Env: SDL_DESC_PATCH_OP = "replace" | "add" (default replace)
 */
const fs = require('fs');
const { spawnSync } = require('child_process');
const path = require('path');

const md = fs.readFileSync(0, 'utf8');
<<<<<<< HEAD
const converter = path.join(__dirname, 'markdown-to-html.js');
const conv = spawnSync(process.execPath, [converter], {
  input: md,
  encoding: 'utf8',
  maxBuffer: 50 * 1024 * 1024,
});
if (conv.status !== 0 && conv.status != null) {
  process.stderr.write(conv.stderr || 'markdown-to-html failed\n');
  process.exit(1);
}
const html = conv.stdout || '';
=======
let html = '';

// Check if content is already HTML (contains HTML tags)
const hasHtmlTags = /<(div|table|p|h[1-6]|ul|ol|li|span|br|b|i|strong|em)[^>]*>/i.test(md);

if (hasHtmlTags) {
  // Content is already HTML, use it directly but ensure proper wrapping
  if (!md.trim().startsWith('<div')) {
    html = `<div style="font-family:Segoe UI,sans-serif;">${md}</div>`;
  } else {
    html = md;
  }
} else {
  // Convert markdown to HTML
  const converter = path.join(__dirname, 'markdown-to-html.js');
  const conv = spawnSync(process.execPath, [converter], {
    input: md,
    encoding: 'utf8',
    maxBuffer: 50 * 1024 * 1024,
  });
  if (conv.status !== 0 && conv.status != null) {
    process.stderr.write(conv.stderr || 'markdown-to-html failed\n');
    process.exit(1);
  }
  html = conv.stdout || '';
}

>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
const op = process.env.SDL_DESC_PATCH_OP || 'replace';
const patch = [{ op, path: '/fields/System.Description', value: html }];
process.stdout.write(JSON.stringify(patch));
