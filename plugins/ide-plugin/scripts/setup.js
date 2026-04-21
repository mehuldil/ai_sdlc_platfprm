#!/usr/bin/env node

/**
 * AI-SDLC IDE Plugin — One-Command Setup
 *
 * Run: npm run setup  (from plugins/ide-plugin/)
 * Or:  node plugins/ide-plugin/scripts/setup.js  (from repo root)
 *
 * What it does:
 *   1. Installs npm dependencies (MCP SDK, axios, zod)
 *   2. Creates env/.env from template (if missing)
 *   3. Bootstraps .sdlc/ directory structure
 *   4. Wires .claude/commands/ for Claude Code slash commands
 *   5. Wires .cursor/mcp.json for Cursor IDE
 *   6. Validates MCP server syntax
 *   7. Tests ADO connection (if PAT provided)
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Resolve paths
const PLUGIN_ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(PLUGIN_ROOT, '..', '..');

const green  = (s) => `\x1b[32m${s}\x1b[0m`;
const yellow = (s) => `\x1b[33m${s}\x1b[0m`;
const red    = (s) => `\x1b[31m${s}\x1b[0m`;
const bold   = (s) => `\x1b[1m${s}\x1b[0m`;

let stepNum = 0;
function step(msg) { console.log(`\n${bold(`[${++stepNum}]`)} ${msg}`); }
function ok(msg)   { console.log(`  ${green('✓')} ${msg}`); }
function warn(msg) { console.log(`  ${yellow('⚠')} ${msg}`); }
function fail(msg) { console.log(`  ${red('✗')} ${msg}`); }

console.log(bold('\n🚀 AI-SDLC IDE Plugin Setup\n'));
console.log(`Plugin:  ${PLUGIN_ROOT}`);
console.log(`Repo:    ${REPO_ROOT}`);

// ─── Step 1: Install npm dependencies ───────────────────────────────────────

step('Installing npm dependencies...');
try {
  execSync('npm install --production', { cwd: PLUGIN_ROOT, stdio: 'pipe' });
  ok('Dependencies installed (MCP SDK, axios, zod)');
} catch (e) {
  fail(`npm install failed: ${e.message}`);
  process.exit(1);
}

// ─── Step 2: Create env/.env from template ──────────────────────────────────

step('Setting up environment configuration...');
const envDir  = path.join(PLUGIN_ROOT, 'env');
const envFile = path.join(envDir, '.env');
const envTpl  = path.join(envDir, 'env.template');

if (!fs.existsSync(envDir)) fs.mkdirSync(envDir, { recursive: true });

if (fs.existsSync(envFile)) {
  ok('env/.env already exists');
  // Check if ADO_PAT is set
  const envContent = fs.readFileSync(envFile, 'utf-8');
  if (!envContent.match(/ADO_PAT=.+/)) {
    warn('ADO_PAT is empty in env/.env — fill it in to enable ADO integration');
  } else {
    ok('ADO_PAT is configured');
  }
} else if (fs.existsSync(envTpl)) {
  fs.copyFileSync(envTpl, envFile);
  ok('Created env/.env from template');
  warn('REQUIRED: Edit env/.env and set ADO_PAT (your Azure DevOps Personal Access Token)');
  warn('Get PAT: Azure DevOps → User Settings → Personal Access Tokens → New Token');
} else {
  // Create minimal .env
  const minEnv = `# Azure DevOps Configuration
ADO_ORG=your-ado-org
ADO_PROJECT=YourAzureProject
ADO_PAT=

# Get your PAT: https://dev.azure.com → User Settings → Personal Access Tokens
# Scopes needed: Work Items (Read & Write), Code (Read)
`;
  fs.writeFileSync(envFile, minEnv);
  ok('Created minimal env/.env');
  warn('REQUIRED: Edit env/.env and set ADO_PAT');
}

// ─── Step 3: Bootstrap .sdlc/ directory structure ───────────────────────────

step('Bootstrapping .sdlc/ project structure...');
const sdlcRoot = path.join(REPO_ROOT, '.sdlc');
const sdlcDirs = [
  path.join(sdlcRoot, 'memory'),
];
const sdlcFiles = {
  [path.join(sdlcRoot, 'config')]: JSON.stringify({
    project: 'ExampleApp',
    org: 'your-ado-org',
    adoProject: 'YourAzureProject',
    version: '1.0.0',
    createdAt: new Date().toISOString(),
  }, null, 2),
  [path.join(sdlcRoot, 'state.json')]: JSON.stringify({
    currentRole: null,
    currentStack: null,
    currentStage: null,
    lastStory: null,
    lastCommand: null,
    updatedAt: new Date().toISOString(),
  }, null, 2),
  [path.join(sdlcRoot, 'role')]: '',
  [path.join(sdlcRoot, 'stack')]: '',
  [path.join(sdlcRoot, 'stage')]: '',
};

for (const dir of sdlcDirs) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    ok(`Created ${path.relative(REPO_ROOT, dir)}/`);
  } else {
    ok(`${path.relative(REPO_ROOT, dir)}/ exists`);
  }
}

for (const [file, content] of Object.entries(sdlcFiles)) {
  if (!fs.existsSync(file)) {
    fs.writeFileSync(file, content);
    ok(`Created ${path.relative(REPO_ROOT, file)}`);
  } else {
    ok(`${path.relative(REPO_ROOT, file)} exists`);
  }
}

// ─── Step 4: Wire Claude Code slash commands ────────────────────────────────

step('Wiring Claude Code slash commands...');
const claudeCommandsDir = path.join(REPO_ROOT, '.claude', 'commands');
if (!fs.existsSync(claudeCommandsDir)) fs.mkdirSync(claudeCommandsDir, { recursive: true });

// Map skills to Claude Code commands
const skills = [
  'requirement-intake', 'prd-review', 'grooming', 'architecture-review',
  'system-design', 'sprint-planning', 'implementation', 'code-review',
  'test-design', 'performance-testing', 'staging-validation', 'release-prep',
  'deployment', 'monitoring', 'incident-response',
];

let commandsCreated = 0;
for (const skill of skills) {
  const cmdFile = path.join(claudeCommandsDir, `project-${skill}.md`);
  if (!fs.existsSync(cmdFile)) {
    const skillPath = path.relative(REPO_ROOT, path.join(PLUGIN_ROOT, 'skills', skill, 'SKILL.md'));
    const content = `Read and execute the skill defined in \`${skillPath}\`.\n\nPass any arguments from the user's command (e.g., work item ID, flags) to the skill.\n\nAlso read \`${path.relative(REPO_ROOT, path.join(PLUGIN_ROOT, 'skills', 'nl-processor', 'SKILL.md'))}\` for natural language routing context.\n`;
    fs.writeFileSync(cmdFile, content);
    commandsCreated++;
  }
}

// NL processor command
const nlCmdFile = path.join(claudeCommandsDir, 'project.md');
if (!fs.existsSync(nlCmdFile)) {
  const nlSkillPath = path.relative(REPO_ROOT, path.join(PLUGIN_ROOT, 'skills', 'nl-processor', 'SKILL.md'));
  const content = `You are the AI-SDLC natural language processor. Read and follow \`${nlSkillPath}\` to understand the user's intent and route to the correct SDLC skill.\n\nAvailable skills are in \`${path.relative(REPO_ROOT, path.join(PLUGIN_ROOT, 'skills'))}/*/SKILL.md\`.\n\nAlso load context from \`.sdlc/memory/\` if available.\n`;
  fs.writeFileSync(nlCmdFile, content);
  commandsCreated++;
}

ok(`${commandsCreated} Claude Code commands wired in .claude/commands/`);
ok('Usage: /project:<stage-name> or /project for NL routing');

// ─── Step 5: Wire Cursor IDE MCP config ─────────────────────────────────────

step('Wiring Cursor IDE MCP configuration...');
const cursorDir = path.join(REPO_ROOT, '.cursor');
if (!fs.existsSync(cursorDir)) fs.mkdirSync(cursorDir, { recursive: true });

const cursorMcpFile = path.join(cursorDir, 'mcp.json');
const adoServerPath = path.relative(REPO_ROOT, path.join(PLUGIN_ROOT, 'mcp', 'ado-server.js'));

const cursorMcpConfig = {
  mcpServers: {
    'ado-plugin': {
      command: 'node',
      args: [adoServerPath],
      env: {
        ADO_ORG: '${ADO_ORG}',
        ADO_PROJECT: '${ADO_PROJECT}',
        ADO_PAT: '${ADO_PAT}',
      },
    },
  },
};

if (!fs.existsSync(cursorMcpFile)) {
  fs.writeFileSync(cursorMcpFile, JSON.stringify(cursorMcpConfig, null, 2));
  ok('Created .cursor/mcp.json');
} else {
  // Merge with existing config
  try {
    const existing = JSON.parse(fs.readFileSync(cursorMcpFile, 'utf-8'));
    if (!existing.mcpServers?.['ado-plugin']) {
      existing.mcpServers = existing.mcpServers || {};
      existing.mcpServers['ado-plugin'] = cursorMcpConfig.mcpServers['ado-plugin'];
      fs.writeFileSync(cursorMcpFile, JSON.stringify(existing, null, 2));
      ok('Merged ado-plugin into existing .cursor/mcp.json');
    } else {
      ok('.cursor/mcp.json already has ado-plugin');
    }
  } catch {
    warn('Could not merge .cursor/mcp.json — check manually');
  }
}

// Also ensure plugin's own .mcp.json is correct for Claude Code
const pluginMcpFile = path.join(PLUGIN_ROOT, '.mcp.json');
const pluginMcpConfig = {
  mcpServers: {
    ado: {
      command: 'node',
      args: [`./${path.relative(REPO_ROOT, path.join(PLUGIN_ROOT, 'mcp', 'ado-server.js'))}`],
      env: {
        ADO_ORG: '${ADO_ORG}',
        ADO_PROJECT: '${ADO_PROJECT}',
        ADO_PAT: '${ADO_PAT}',
      },
      disabled: false,
      alwaysAllow: ['list-work-items', 'get-work-item', 'create-work-item', 'update-work-item', 'post-comment'],
    },
  },
};
fs.writeFileSync(pluginMcpFile, JSON.stringify(pluginMcpConfig, null, 2));
ok('Updated plugin .mcp.json for MCP SDK protocol');

// ─── Step 6: Validate MCP server ────────────────────────────────────────────

step('Validating MCP server...');
try {
  execSync(`node --check "${path.join(PLUGIN_ROOT, 'mcp', 'ado-server.js')}"`, { stdio: 'pipe' });
  ok('mcp/ado-server.js syntax valid');
} catch (e) {
  fail(`MCP server syntax error: ${e.stderr?.toString() || e.message}`);
}

try {
  execSync(`node --check "${path.join(PLUGIN_ROOT, 'hooks', 'context-loader.js')}"`, { stdio: 'pipe' });
  ok('hooks/context-loader.js syntax valid');
} catch (e) {
  fail(`Context loader syntax error: ${e.stderr?.toString() || e.message}`);
}

// ─── Step 7: Test ADO connection ────────────────────────────────────────────

step('Testing ADO connection...');
const envContent2 = fs.existsSync(envFile) ? fs.readFileSync(envFile, 'utf-8') : '';
const patMatch = envContent2.match(/ADO_PAT=(.+)/);
const pat = patMatch?.[1]?.trim();

if (pat && pat.length > 10) {
  try {
    const orgMatch = envContent2.match(/ADO_ORG=(.+)/);
    const org = orgMatch?.[1]?.trim() || 'your-ado-org';
    const result = execSync(
      `curl -s -o /dev/null -w "%{http_code}" -u ":${pat}" "https://dev.azure.com/${org}/_apis/projects?api-version=7.0"`,
      { stdio: 'pipe', timeout: 10000 }
    ).toString().trim();
    if (result === '200') {
      ok('ADO connection successful');
    } else {
      warn(`ADO returned HTTP ${result} — check ADO_PAT and ADO_ORG in env/.env`);
    }
  } catch {
    warn('Could not reach Azure DevOps — check network or PAT');
  }
} else {
  warn('ADO_PAT not set — skipping connection test');
  warn('Set it in env/.env to enable ADO integration');
}

// ─── Step 8: Add .gitignore entries ─────────────────────────────────────────

step('Ensuring .gitignore safety...');
const gitignorePath = path.join(REPO_ROOT, '.gitignore');
const ignoreEntries = ['env/.env', 'env/.env.local', '.sdlc/state.json', 'node_modules/', 'plugins/ide-plugin/node_modules/'];
let gitignoreContent = fs.existsSync(gitignorePath) ? fs.readFileSync(gitignorePath, 'utf-8') : '';
let added = 0;
for (const entry of ignoreEntries) {
  if (!gitignoreContent.includes(entry)) {
    gitignoreContent += `\n${entry}`;
    added++;
  }
}
if (added > 0) {
  fs.writeFileSync(gitignorePath, gitignoreContent.trimEnd() + '\n');
  ok(`Added ${added} entries to .gitignore`);
} else {
  ok('.gitignore already configured');
}

// ─── Done ───────────────────────────────────────────────────────────────────

console.log(`\n${green(bold('✅ Setup complete!'))}\n`);
console.log(bold('Next steps:'));
if (!pat || pat.length <= 10) {
  console.log(`  1. ${yellow('Edit env/.env')} → Set your ADO_PAT`);
  console.log(`     Get it: Azure DevOps → User Settings → Personal Access Tokens → New Token`);
  console.log(`     Scopes: Work Items (Read & Write), Code (Read)\n`);
}
console.log(bold('How to use:'));
console.log(`  ${bold('Claude Code:')}  /project:prd-review AB#123`);
console.log(`  ${bold('Claude Code:')}  /project  (then type natural language)`);
console.log(`  ${bold('Cursor IDE:')}   MCP tools auto-loaded (list-work-items, post-comment, etc.)`);
console.log(`  ${bold('CLI:')}          node mcp/ado-server.js  (stdio MCP server)\n`);
console.log(bold('Test MCP server:'));
console.log(`  npx @modelcontextprotocol/inspector node plugins/ide-plugin/mcp/ado-server.js\n`);
