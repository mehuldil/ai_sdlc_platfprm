#!/usr/bin/env node
/**
 * Reads markdown from stdin, converts to HTML (markdown-to-html.js), emits JSON Patch
 * for Azure DevOps System.Description. Avoids bash quoting/size limits on Windows.
 *
 * Env: SDL_DESC_PATCH_OP = "replace" | "add" (default replace)
 */
const fs = require('fs');
const { spawnSync } = require('child_process');
const path = require('path');

const md = fs.readFileSync(0, 'utf8');
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
const op = process.env.SDL_DESC_PATCH_OP || 'replace';
const patch = [{ op, path: '/fields/System.Description', value: html }];
process.stdout.write(JSON.stringify(patch));
