#!/usr/bin/env node

/**
 * Azure DevOps MCP Server (MCP SDK v1.x compliant)
 *
 * Protocol: JSON-RPC 2.0 over stdio
 * Compatible with: Claude Code, Cursor IDE, MCP Inspector, any MCP client
 *
 * Tools provided:
 *   - list-work-items    List/search work items with filters
 *   - get-work-item      Get full details of a work item
 *   - create-work-item   Create new work items
 *   - update-work-item   Update work item fields
 *   - post-comment       Post comment on a work item
 *
 * Requires: ADO_ORG, ADO_PROJECT, ADO_PAT environment variables
 */

import fs from 'fs';
import os from 'os';
import path from 'path';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import axios from 'axios';

/**
 * Load KEY=VAL lines into process.env (only when the variable is unset or empty).
 * Matches bash "source" enough for ADO_* and integration tokens.
 */
function mergeEnvFile(filePath) {
  if (!filePath || !fs.existsSync(filePath)) return;
  const text = fs.readFileSync(filePath, 'utf8');
  for (const line of text.split(/\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('=');
    if (eq <= 0) continue;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    const cur = process.env[key];
    if (cur === undefined || cur === '') {
      process.env[key] = val;
    }
  }
}

const globalAdo = path.join(os.homedir(), '.sdlc', 'ado.env');
mergeEnvFile(process.env.SDL_AZURE_DEVOPS_ENV_FILE);
mergeEnvFile(globalAdo);

// ─── Configuration ──────────────────────────────────────────────────────────

const ADO_ORG     = process.env.ADO_ORG || 'your-ado-org';
const ADO_PROJECT = process.env.ADO_PROJECT || 'YourAzureProject';
const ADO_PAT     = process.env.ADO_PAT || '';

if (!ADO_PAT) {
  console.error('WARNING: ADO_PAT not set. MCP server will start but ADO calls will fail.');
  console.error('Set ADO_PAT in ~/.sdlc/ado.env or env/.env (see User_Manual/Getting_Started.md).');
}

const ADO_BASE = `https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis`;

const http = axios.create({
  auth: { username: '', password: ADO_PAT },
  headers: { 'Content-Type': 'application/json-patch+json' },
});

// ─── ADO Helpers ────────────────────────────────────────────────────────────

function buildWiql(filters = {}) {
  const conds = [`[System.State] <> 'Closed'`];
  if (filters.type)       conds.push(`[System.WorkItemType] = '${filters.type}'`);
  if (filters.state)      conds.push(`[System.State] = '${filters.state}'`);
  if (filters.assignedTo) conds.push(`[System.AssignedTo] = '${filters.assignedTo}'`);
  if (filters.tags?.length) {
    conds.push(`(${filters.tags.map(t => `[System.Tags] CONTAINS '${t}'`).join(' OR ')})`);
  }
  if (filters.title) conds.push(`[System.Title] CONTAINS '${filters.title}'`);
  return `SELECT [System.Id],[System.Title],[System.State] FROM workitems WHERE ${conds.join(' AND ')} ORDER BY [System.ChangedDate] DESC`;
}

async function fetchItem(id) {
  const r = await http.get(`${ADO_BASE}/wit/workitems/${id}?api-version=7.0&$expand=relations`);
  const f = r.data.fields;
  return {
    id: r.data.id, url: r.data.url,
    type: f['System.WorkItemType'], title: f['System.Title'], state: f['System.State'],
    assignedTo: f['System.AssignedTo']?.displayName || null,
    createdBy: f['System.CreatedBy']?.displayName || null,
    createdDate: f['System.CreatedDate'], changedDate: f['System.ChangedDate'],
    storyPoints: f['Microsoft.VSTS.Scheduling.StoryPoints'] || null,
    priority: f['Microsoft.VSTS.Common.Priority'] || null,
    tags: (f['System.Tags'] || '').split('; ').filter(Boolean),
    description: f['System.Description'] || '',
    acceptanceCriteria: f['Microsoft.VSTS.Common.AcceptanceCriteria'] || '',
    relations: r.data.relations || [],
    adoLink: `https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_workitems/edit/${r.data.id}`,
  };
}

// ─── Tool Definitions ───────────────────────────────────────────────────────

const TOOLS = [
  {
    name: 'list-work-items',
    description: 'List/search Azure DevOps work items. Returns up to 50 non-closed items. Filter by type, state, assignedTo, tags, or title.',
    inputSchema: {
      type: 'object',
      properties: {
        type:       { type: 'string', description: 'Work item type (Epic, Feature, User Story, Task, Bug)' },
        state:      { type: 'string', description: 'State filter (New, Active, Resolved)' },
        assignedTo: { type: 'string', description: 'Assigned to (display name)' },
        tags:       { type: 'array', items: { type: 'string' }, description: 'Tag filters' },
        title:      { type: 'string', description: 'Title contains filter' },
      },
    },
  },
  {
    name: 'get-work-item',
    description: 'Get full details of a single Azure DevOps work item by ID. Returns all fields, relations, acceptance criteria, tags, and ADO link.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Work item ID (e.g. "12345" or "AB#12345")' },
      },
      required: ['id'],
    },
  },
  {
    name: 'create-work-item',
    description: 'Create a new Azure DevOps work item (Epic, Feature, User Story, Task, Bug). Optionally link to parent.',
    inputSchema: {
      type: 'object',
      properties: {
        type:        { type: 'string', default: 'User Story', description: 'Work item type' },
        title:       { type: 'string', description: 'Title' },
        description: { type: 'string', description: 'HTML description' },
        assignedTo:  { type: 'string', description: 'Assigned to (display name)' },
        storyPoints: { type: 'number', description: 'Story points' },
        tags:        { type: 'array', items: { type: 'string' }, description: 'Tags' },
        parentId:    { type: 'number', description: 'Parent work item ID to link' },
      },
      required: ['title'],
    },
  },
  {
    name: 'update-work-item',
    description: 'Update fields on an existing Azure DevOps work item (state, assignedTo, tags, storyPoints, description).',
    inputSchema: {
      type: 'object',
      properties: {
        id:          { type: 'number', description: 'Work item ID' },
        state:       { type: 'string', description: 'New state' },
        assignedTo:  { type: 'string', description: 'New assignee' },
        storyPoints: { type: 'number', description: 'New story points' },
        tags:        { type: 'array', items: { type: 'string' }, description: 'Replace all tags' },
        description: { type: 'string', description: 'New description (HTML)' },
      },
      required: ['id'],
    },
  },
  {
    name: 'post-comment',
    description: 'Post a comment on an Azure DevOps work item. Use for gap analysis, review feedback, prevention items, etc.',
    inputSchema: {
      type: 'object',
      properties: {
        id:      { type: 'number', description: 'Work item ID' },
        comment: { type: 'string', description: 'Comment text (supports HTML)' },
      },
      required: ['id', 'comment'],
    },
  },
];

// ─── Tool Handlers ──────────────────────────────────────────────────────────

const handlers = {
  'list-work-items': async (args) => {
    const wiql = buildWiql(args);
    const r = await http.post(`${ADO_BASE}/wit/wiql?api-version=7.0`, { query: wiql });
    const ids = (r.data.workItems || []).slice(0, 50);
    const items = await Promise.all(ids.map(wi => fetchItem(wi.id)));
    return { success: true, count: items.length, items };
  },

  'get-work-item': async (args) => {
    const numId = String(args.id).replace(/\D/g, '');
    const item = await fetchItem(numId);
    return { success: true, workItem: item };
  },

  'create-work-item': async (args) => {
    const patch = [
      { op: 'add', path: '/fields/System.Title', value: args.title },
      { op: 'add', path: '/fields/System.Description', value: args.description || '' },
      { op: 'add', path: '/fields/System.State', value: 'New' },
    ];
    if (args.storyPoints)  patch.push({ op: 'add', path: '/fields/Microsoft.VSTS.Scheduling.StoryPoints', value: args.storyPoints });
    if (args.assignedTo)   patch.push({ op: 'add', path: '/fields/System.AssignedTo', value: args.assignedTo });
    if (args.tags?.length) patch.push({ op: 'add', path: '/fields/System.Tags', value: args.tags.join('; ') });
    if (args.parentId)     patch.push({ op: 'add', path: '/relations/-', value: { rel: 'System.LinkTypes.Hierarchy-reverse', url: `${ADO_BASE}/wit/workitems/${args.parentId}` } });
    const r = await http.patch(`${ADO_BASE}/wit/workitems/$${args.type || 'User Story'}?api-version=7.0`, patch);
    return { success: true, id: r.data.id, type: args.type || 'User Story', title: args.title, adoLink: `https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_workitems/edit/${r.data.id}` };
  },

  'update-work-item': async (args) => {
    const patch = [];
    if (args.state)                  patch.push({ op: 'add', path: '/fields/System.State', value: args.state });
    if (args.assignedTo)             patch.push({ op: 'add', path: '/fields/System.AssignedTo', value: args.assignedTo });
    if (args.storyPoints !== undefined) patch.push({ op: 'add', path: '/fields/Microsoft.VSTS.Scheduling.StoryPoints', value: args.storyPoints });
    if (args.tags)                   patch.push({ op: 'add', path: '/fields/System.Tags', value: args.tags.join('; ') });
    if (args.description)            patch.push({ op: 'add', path: '/fields/System.Description', value: args.description });
    if (patch.length === 0) return { success: false, error: 'No fields to update' };
    const r = await http.patch(`${ADO_BASE}/wit/workitems/${args.id}?api-version=7.0`, patch);
    return { success: true, id: r.data.id, message: 'Work item updated' };
  },

  'post-comment': async (args) => {
    const r = await http.post(
      `${ADO_BASE}/wit/workitems/${args.id}/comments?api-version=7.1-preview.3`,
      { text: args.comment },
      { headers: { 'Content-Type': 'application/json' } }
    );
    return { success: true, commentId: r.data.id, workItemId: args.id, message: 'Comment posted' };
  },
};

// ─── MCP Server ─────────────────────────────────────────────────────────────

const server = new Server(
  { name: 'ado-server', version: '1.1.0' },
  { capabilities: { tools: {} } }
);

// Handle: tools/list
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

// Handle: tools/call
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const handler = handlers[name];
  if (!handler) {
    return { content: [{ type: 'text', text: JSON.stringify({ success: false, error: `Unknown tool: ${name}` }) }] };
  }
  try {
    const result = await handler(args || {});
    return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
  } catch (e) {
    return { content: [{ type: 'text', text: JSON.stringify({ success: false, error: e.message }) }] };
  }
});

// ─── Start ──────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport();
await server.connect(transport);
