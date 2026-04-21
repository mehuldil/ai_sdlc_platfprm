#!/usr/bin/env node
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..", "agents");

const ASK_RE = /ask.*protocol|ask.*first|ask.before|must.*ask|always.*ask/i;

const BLOCK_DOMAIN = `

## ASK-First Protocol

**Canonical rule:** [\`rules/ask-first-protocol.md\`](../../rules/ask-first-protocol.md) — never assume; clarify scope and confirm in chat before irreversible actions or when context is ambiguous.

## ASK-First Enforcement

- Before changes that affect production data, ADO state, contracts, or shared artifacts → **ASK**; show intent and wait for confirmation.
- When branch, story, scope, or environment is unclear → **ASK**; do not infer.
- Chat-first for user confirmation: see [\`agents/shared/context-guard.md\`](../shared/context-guard.md).

`;

const BLOCK_SHARED = BLOCK_DOMAIN.replace(
  "[\\`agents/shared/context-guard.md\\`](../shared/context-guard.md)",
  "[\\`context-guard.md\\`](./context-guard.md)"
);

function walk(dir, out) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walk(p, out);
    else if (name.endsWith(".md") && name !== "CAPABILITY_MATRIX.md") out.push(p);
  }
}

function insertBlock(text, block) {
  const tries = [
    /^## Integration(?:\s|$)/m,
    /^## Integration Points/m,
    /^## Integration with/m,
    /^## Guardrails\b/m,
  ];
  for (const re of tries) {
    const m = text.match(re);
    if (m && m.index !== undefined) return text.slice(0, m.index) + block + text.slice(m.index);
  }
  return text.trimEnd() + "\n" + block;
}

const files = [];
walk(ROOT, files);
let n = 0;
for (const f of files.sort()) {
  let t = fs.readFileSync(f, "utf8");
  if (ASK_RE.test(t) || t.includes("## ASK-First Protocol")) continue;
  const parts = f.split(path.sep);
  const shared = parts[parts.indexOf("agents") + 1] === "shared";
  const block = shared ? BLOCK_SHARED : BLOCK_DOMAIN;
  fs.writeFileSync(f, insertBlock(t, block), "utf8");
  console.log("patched", path.relative(path.join(__dirname, ".."), f));
  n++;
}
console.log(`Done. Patched ${n} file(s).`);
