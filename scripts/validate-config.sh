#!/bin/bash
################################################################################
# AI-SDLC Platform — Environment Configuration Validator
# Validates env/.env is correctly populated before first use.
# Referenced by: README.md, env/env.template, rules/user-config.md
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PLATFORM_DIR/env/.env"

pass=0
warn=0
fail=0

ok()   { echo -e "  ${GREEN}✓${NC} $1"; pass=$((pass + 1)); }
skip() { echo -e "  ${YELLOW}⚠${NC}  $1 (optional — skipped)"; warn=$((warn + 1)); }
err()  { echo -e "  ${RED}✗${NC} $1"; fail=$((fail + 1)); }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  AI-SDLC Platform — Config Validator         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Step 1: env file exists ──────────────────────────────────────────────────
echo "1. Checking env/.env file..."
if [[ ! -f "$ENV_FILE" ]]; then
  err "env/.env not found."
  echo ""
  echo "  Create it from the platform template (in this repo or your project after sdlc-setup):"
  echo "    cp env/env.template env/.env"
  echo "  If you only have env/.env.example in the project:"
  echo "    cp env/.env.example env/.env"
  echo ""
  echo -e "${RED}Cannot continue without env/.env. Exiting.${NC}"
  exit 1
fi
ok "env/.env exists"

# Source the env file (values are KEY=VALUE, no export needed)
set -a
source "$ENV_FILE"
set +a

# ── Step 2: Required ADO fields ─────────────────────────────────────────────
echo ""
echo "2. Validating Azure DevOps configuration..."

if [[ -n "$ADO_ORG" ]]; then ok "ADO_ORG = $ADO_ORG"; else err "ADO_ORG is empty"; fi
if [[ -n "$ADO_PROJECT" ]]; then ok "ADO_PROJECT = $ADO_PROJECT"; else err "ADO_PROJECT is empty"; fi

if [[ -n "$ADO_PROJECT_ID" ]]; then
  # UUID format check (8-4-4-4-12 hex chars)
  if [[ "$ADO_PROJECT_ID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
    ok "ADO_PROJECT_ID = $ADO_PROJECT_ID"
  else
    err "ADO_PROJECT_ID is not a valid UUID: $ADO_PROJECT_ID"
  fi
else
  err "ADO_PROJECT_ID is empty"
fi

if [[ -n "$ADO_USER_EMAIL" ]]; then
  if [[ "$ADO_USER_EMAIL" == *@* ]]; then
    ok "ADO_USER_EMAIL = $ADO_USER_EMAIL"
  else
    err "ADO_USER_EMAIL does not look like an email: $ADO_USER_EMAIL"
  fi
else
  err "ADO_USER_EMAIL is empty"
fi

if [[ -n "$ADO_PAT" ]]; then
  local_len=${#ADO_PAT}
  if (( local_len >= 40 )); then
    ok "ADO_PAT = ${ADO_PAT:0:6}...${ADO_PAT: -4} (${local_len} chars)"
  else
    err "ADO_PAT looks too short ($local_len chars — expected ≥40)"
  fi
else
  err "ADO_PAT is empty"
fi

# ── Step 3: Optional fields ──────────────────────────────────────────────────
echo ""
echo "3. Checking optional configuration..."

if [[ -n "$WIKIJS_TOKEN" ]]; then ok "WIKIJS_TOKEN is set (Wiki MCP)"; else skip "WIKIJS_TOKEN (Wiki MCP)"; fi
if [[ -n "$WIKI_TOKEN" ]]; then ok "WIKI_TOKEN is set (legacy)"; else skip "WIKI_TOKEN"; fi
if [[ -n "$ES_URL" ]]; then ok "ES_URL is set (Elasticsearch MCP)"; else skip "ES_URL (Elasticsearch MCP)"; fi
if [[ -n "$REDIS_URL" ]]; then ok "REDIS_URL = $REDIS_URL"; else skip "REDIS_URL"; fi
if [[ -n "$OPENAI_KEY" ]]; then ok "OPENAI_KEY is set"; else skip "OPENAI_KEY"; fi

# ── Step 3b: MCP config (parity with ai-claude-platform) ─────────────────────
# BUG FIX #9: Replace fragile grep && ok || err chains with proper if/then/else
echo ""
echo "3b. Checking MCP configuration..."
MCP_JSON="$PLATFORM_DIR/mcp.json"
if [[ -f "$MCP_JSON" ]]; then
  ok "mcp.json exists"
  if grep -q '"AzureDevOps"' "$MCP_JSON"; then
    ok "mcp.json: AzureDevOps server"
  else
    err "mcp.json missing AzureDevOps"
  fi
  if grep -q '"wikijs"' "$MCP_JSON"; then
    ok "mcp.json: wikijs server"
  else
    err "mcp.json missing wikijs"
  fi
  if grep -q '"elasticsearch"' "$MCP_JSON"; then
    ok "mcp.json: elasticsearch server"
  else
    err "mcp.json missing elasticsearch"
  fi
else
  err "mcp.json not found at platform root"
fi

# ── Step 4: Platform integrity ───────────────────────────────────────────────
echo ""
echo "4. Checking platform structure..."

for dir in rules stacks templates memory stages roles agents skills workflows cli docs; do
  if [[ -d "$PLATFORM_DIR/$dir" ]]; then
    ok "$dir/ directory exists"
  else
    err "$dir/ directory missing"
  fi
done

# ── Step 5: CLI availability ─────────────────────────────────────────────────
ech