#!/bin/bash

################################################################################
# AI-SDLC Platform — Single Entry Point Setup
#
# Usage:
#   ./setup.sh                    # Setup for current directory as project
#   ./setup.sh /path/to/project   # Setup for a specific project
#   ./setup.sh --self              # Setup platform repo itself (dev mode)
#
# What it does (in order):
#   1. Runs cli/sdlc-setup.sh (creates .sdlc/, symlinks, .claude/, .cursor/, MCP)
#   2. Installs IDE plugin (plugins/ide-plugin: npm install + setup.js)
#   3. Creates env/.env from template if missing
#   4. Validates MCP server syntax
#   5. Checks ADO_PAT and tests connection if provided
#   6. Prints summary with next steps
#
# After this script:
#   - All slash commands work (/project:prd-review, /project:grooming, etc.)
#   - MCP tools available (Azure DevOps, Wiki.js, Elasticsearch)
#   - NL routing works ("review this PRD", "create a story", etc.)
#   - CLI commands work (sdlc use, sdlc run, sdlc ado, etc.)
#
# For IDE users (Cursor / Claude Code):
#   Just type "setup" or "set up SDLC" in chat — Claude reads CLAUDE.md
#   and runs this script automatically.
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
fail() { echo -e "  ${RED}✗${NC} $*"; }
step() { echo -e "\n${BOLD}[$((++STEP_NUM))]${NC} $*"; }

STEP_NUM=0
ERRORS=0

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         AI-SDLC Platform — One-Command Setup            ║"
echo "║         AI-SDLC · your-ado-org · YourAzureProject             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Resolve paths ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$SCRIPT_DIR"

# Parse arguments
SELF_MODE=false
PROJECT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --self)
      SELF_MODE=true
      shift
      ;;
    -h|--help)
      echo "Usage: ./setup.sh [OPTIONS] [project-path]"
      echo ""
      echo "Options:"
      echo "  --self       Setup the platform repo itself (dev/testing mode)"
      echo "  -h, --help   Show this help"
      echo ""
      echo "Arguments:"
      echo "  project-path  Target project directory (default: current directory)"
      echo ""
      echo "Examples:"
      echo "  ./setup.sh                     # Setup for current directory"
      echo "  ./setup.sh /path/to/my-app     # Setup for a specific project"
      echo "  ./setup.sh --self              # Setup platform repo itself"
      echo ""
      echo "After setup, in your IDE chat type:"
      echo "  /project:prd-review AB#12345"
      echo "  or just: 'review the PRD for AB#12345'"
      exit 0
      ;;
    *)
      PROJECT_PATH="$1"
      shift
      ;;
  esac
done

if [[ "$SELF_MODE" == "true" ]]; then
  PROJECT_PATH="$PLATFORM_ROOT"
elif [[ -z "$PROJECT_PATH" ]]; then
  PROJECT_PATH="$(pwd)"
fi

# Normalize
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
  fail "Project path not found: $PROJECT_PATH"
  exit 1
}

echo -e "Platform:  ${CYAN}${PLATFORM_ROOT}${NC}"
echo -e "Project:   ${CYAN}${PROJECT_PATH}${NC}"

# ── Step 1: Check prerequisites ──────────────────────────────────────────────
step "Checking prerequisites..."

# Check bash
ok "Bash shell available"

# Check git
if command -v git &>/dev/null; then
  ok "Git installed ($(git --version | head -1))"
else
  warn "Git not found — ADO linking and hooks won't work"
fi

# Check Node.js
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  ok "Node.js installed ($NODE_VER)"
  # Check minimum version (18+)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_MAJOR" -lt 18 ]]; then
    warn "Node.js 18+ recommended (current: $NODE_VER). MCP server may not work."
  fi
else
  fail "Node.js not found — required for MCP server and IDE plugin"
  echo -e "    Install: ${CYAN}https://nodejs.org/${NC} (v18 or later)"
  ERRORS=$((ERRORS + 1))
fi

# Check npm
if command -v npm &>/dev/null; then
  ok "npm installed ($(npm --version))"
else
  fail "npm not found — required for plugin installation"
  ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -gt 0 ]]; then
  fail "Missing $ERRORS prerequisite(s). Fix above issues and re-run."
  exit 1
fi

# ── Step 1b: Python doc-ingestion libraries (best-effort, non-fatal) ─────────
step "Installing Python doc-ingestion libraries (best-effort)..."

# Resolve python command
_PYTHON_CMD=""
for _py_candidate in python3 python; do
  if command -v "$_py_candidate" &>/dev/null && "$_py_candidate" -V >/dev/null 2>&1; then
    _PYTHON_CMD="$_py_candidate"
    break
  fi
done

if [[ -z "$_PYTHON_CMD" ]]; then
  warn "Python not found — skipping doc-ingestion libraries (sdlc doc convert will not work)"
  warn "Install Python 3, then run: pip install pypdf pdfplumber mammoth python-docx openpyxl python-pptx beautifulsoup4 html2text trafilatura"
else
  DOC_LIBS="pypdf pdfplumber mammoth python-docx openpyxl python-pptx beautifulsoup4 html2text trafilatura"
  echo -e "    Python: $($_PYTHON_CMD --version)"
  echo -e "    Installing: $DOC_LIBS"
  # Use --quiet --disable-pip-version-check so output is clean; allow failures per-library
  if $_PYTHON_CMD -m pip install --quiet --disable-pip-version-check $DOC_LIBS 2>&1 | sed 's/^/    /'; then
    ok "Python doc-ingestion libraries installed (sdlc doc convert ready)"
  else
    warn "Some doc-ingestion libraries failed to install — sdlc doc convert may have limited format support"
    warn "Retry manually: pip install $DOC_LIBS"
  fi
fi
unset _PYTHON_CMD _py_candidate DOC_LIBS

# ── Step 2: Run platform setup (cli/sdlc-setup.sh) ──────────────────────────
step "Running platform setup (creates .sdlc/, symlinks, MCP, commands)..."

SETUP_SCRIPT="${PLATFORM_ROOT}/cli/sdlc-setup.sh"
if [[ -x "$SETUP_SCRIPT" ]]; then
  bash "$SETUP_SCRIPT" "$PROJECT_PATH" 2>&1 | sed 's/^/    /'
  ok "Platform setup complete"
else
  fail "cli/sdlc-setup.sh not found or not executable"
  # Try to make it executable
  chmod +x "$SETUP_SCRIPT" 2>/dev/null && {
    bash "$SETUP_SCRIPT" "$PROJECT_PATH" 2>&1 | sed 's/^/    /'
    ok "Platform setup complete"
  } || {
    fail "Cannot run platform setup. Check cli/sdlc-setup.sh exists."
    ERRORS=$((ERRORS + 1))
  }
fi

# ── Step 3: Install IDE plugin ───────────────────────────────────────────────
step "Installing IDE plugin (npm install + MCP server + commands)..."

PLUGIN_DIR="${PLATFORM_ROOT}/plugins/ide-plugin"
if [[ -d "$PLUGIN_DIR" && -f "$PLUGIN_DIR/package.json" ]]; then
  # Install dependencies
  echo -e "    Installing npm dependencies..."
  (cd "$PLUGIN_DIR" && npm install --production 2>&1 | tail -3 | sed 's/^/    /')
  ok "npm dependencies installed"

  # Run plugin setup script
  if [[ -f "$PLUGIN_DIR/scripts/setup.js" ]]; then
    echo -e "    Running plugin setup..."
    (cd "$PLUGIN_DIR" && node scripts/setup.js 2>&1 | sed 's/^/    /')
    ok "IDE plugin setup complete"
  fi

  # Validate MCP server syntax
  if [[ -f "$PLUGIN_DIR/mcp/ado-server.js" ]]; then
    if node --check "$PLUGIN_DIR/mcp/ado-server.js" 2>/dev/null; then
      ok "MCP server syntax valid"
    else
      warn "MCP server has syntax issues — ADO integration may not work"
    fi
  fi
else
  warn "IDE plugin not found at plugins/ide-plugin/ — skipping plugin install"
fi

# ── Step 4: Setup environment file ───────────────────────────────────────────
step "Configuring environment (env/.env)..."

ENV_DIR="${PROJECT_PATH}/env"
ENV_FILE="${ENV_DIR}/.env"
ENV_TEMPLATE="${PLATFORM_ROOT}/env/env.template"
GLOBAL_ADO_ENV="${HOME}/.sdlc/ado.env"

_sdlc_env_has_pat() {
  [[ -f "$1" ]] && grep -q 'ADO_PAT=.\+' "$1" 2>/dev/null
}

_any_ado_pat_configured() {
  _sdlc_env_has_pat "$ENV_FILE" && return 0
  _sdlc_env_has_pat "$GLOBAL_ADO_ENV" && return 0
  _sdlc_env_has_pat "${PLATFORM_ROOT}/env/.env" && return 0
  [[ -n "${SDL_AZURE_DEVOPS_ENV_FILE:-}" ]] && _sdlc_env_has_pat "${SDL_AZURE_DEVOPS_ENV_FILE}" && return 0
  return 1
}

mkdir -p "$ENV_DIR"

if [[ -f "$ENV_FILE" ]]; then
  ok "env/.env already exists"
  if _sdlc_env_has_pat "$ENV_FILE"; then
    ok "ADO_PAT is set in repo env/.env"
  elif _any_ado_pat_configured; then
    ok "ADO_PAT is set globally (~/.sdlc/ado.env, platform env/.env, or SDL_AZURE_DEVOPS_ENV_FILE) — repo env/.env can stay minimal"
  else
    warn "ADO_PAT is empty — add PAT to env/.env or create ~/.sdlc/ado.env (see Getting Started)"
  fi
elif [[ -f "$ENV_TEMPLATE" ]]; then
  cp "$ENV_TEMPLATE" "$ENV_FILE"
  ok "Created env/.env from template"
  if _any_ado_pat_configured; then
    ok "ADO credentials already available from global or platform env"
  else
    warn "ACTION NEEDED: set ADO_PAT in ~/.sdlc/ado.env (all repos) or in this repo's env/.env"
  fi
else
  # Create minimal env file
  cat > "$ENV_FILE" << 'ENVEOF'
# Azure DevOps Configuration
ADO_ORG=your-ado-org
ADO_PROJECT=YourAzureProject
ADO_PROJECT_ID=
ADO_USER_NAME=
ADO_USER_EMAIL=
ADO_PAT=

# Optional: MCP Integrations
WIKIJS_TOKEN=
ES_URL=
ES_USER=
ES_PWD=
ENVEOF
  ok "Created minimal env/.env"
  if _any_ado_pat_configured; then
    ok "ADO credentials already available from global or platform env"
  else
    warn "ACTION NEEDED: set ADO_PAT in ~/.sdlc/ado.env (all repos) or in this repo's env/.env"
  fi
fi

if _any_ado_pat_configured; then
  ADO_CONFIGURED=true
else
  ADO_CONFIGURED=false
fi

# Also sync env to plugin if plugin exists
PLUGIN_ENV="${PLATFORM_ROOT}/plugins/ide-plugin/env/.env"
if [[ -d "${PLATFORM_ROOT}/plugins/ide-plugin/env" && -f "$ENV_FILE" ]]; then
  if [[ ! -f "$PLUGIN_ENV" ]] || [[ "$ENV_FILE" -nt "$PLUGIN_ENV" ]]; then
    cp "$ENV_FILE" "$PLUGIN_ENV" 2>/dev/null || true
    ok "Synced env/.env → plugins/ide-plugin/env/.env"
  fi
fi

# ── Step 5: Add CLI to PATH (optional) ──────────────────────────────────────
step "Setting up CLI access..."

CLI_DIR="${PLATFORM_ROOT}/cli"
SDLC_SH="${CLI_DIR}/sdlc.sh"

if [[ -f "$SDLC_SH" ]]; then
  chmod +x "$SDLC_SH" 2>/dev/null || true
  ok "CLI script ready: ${CLI_DIR}/sdlc.sh"

  # Make native ADO helpers executable (no-admin alternatives for Windows/Mac)
  if [[ -f "${PLATFORM_ROOT}/scripts/ado-mac.sh" ]]; then
    chmod +x "${PLATFORM_ROOT}/scripts/ado-mac.sh" 2>/dev/null || true
    ok "ADO helper ready: scripts/ado-mac.sh (macOS/Linux — no setup required)"
  fi
  if [[ -f "${PLATFORM_ROOT}/scripts/ado.ps1" ]]; then
    ok "ADO helper ready: scripts/ado.ps1  (Windows — no admin, no bash required)"
  fi

  # Check if already in PATH
  if command -v sdlc &>/dev/null; then
    ok "sdlc command already in PATH"
  else
    echo -e "    ${YELLOW}To use 'sdlc' from anywhere, add to your shell profile:${NC}"
    echo -e "    ${CYAN}export PATH=\"\$PATH:${CLI_DIR}\"${NC}"
    echo -e "    ${CYAN}alias sdlc='${SDLC_SH}'${NC}"
  fi
fi

# ── Step 6: Test ADO connection (if configured) ─────────────────────────────
step "Validating setup..."

# Count what's installed
CMD_COUNT=$(ls "${PROJECT_PATH}/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
RULE_COUNT=$(ls "${PROJECT_PATH}/.claude/rules/"*.md 2>/dev/null | wc -l | tr -d ' ')
SDLC_DIR_EXISTS=false
[[ -d "${PROJECT_PATH}/.sdlc" ]] && SDLC_DIR_EXISTS=true

ok "Slash commands: ${CMD_COUNT} available"
ok "Platform rules: ${RULE_COUNT} loaded"
ok ".sdlc/ directory: ${SDLC_DIR_EXISTS}"
[[ -f "${PROJECT_PATH}/.mcp.json" ]] && ok "MCP config linked" || warn "MCP config missing"
[[ -d "${PLATFORM_ROOT}/plugins/ide-plugin/node_modules" ]] && ok "IDE plugin installed" || warn "IDE plugin not installed"

# Test ADO if configured (first non-empty value wins: repo → SDL_AZURE_DEVOPS_ENV_FILE → platform → ~/.sdlc)
_sdlc_pick_env_val() {
  local key="$1" f val=""
  shift
  for f in "$@"; do
    [[ -n "$f" && -f "$f" ]] || continue
    val="$(grep -E "^[[:space:]]*${key}=" "$f" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '\r')"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
    [[ -n "$val" ]] && { echo "$val"; return 0; }
  done
  echo ""
}

if [[ "${ADO_CONFIGURED:-false}" == "true" ]]; then
  echo -e "    Testing ADO connection..."
  ADO_PAT="$(_sdlc_pick_env_val ADO_PAT "$ENV_FILE" "${SDL_AZURE_DEVOPS_ENV_FILE:-}" "${PLATFORM_ROOT}/env/.env" "$GLOBAL_ADO_ENV")"
  ADO_ORG="$(_sdlc_pick_env_val ADO_ORG "$ENV_FILE" "${SDL_AZURE_DEVOPS_ENV_FILE:-}" "${PLATFORM_ROOT}/env/.env" "$GLOBAL_ADO_ENV")"
  ADO_PROJECT="$(_sdlc_pick_env_val ADO_PROJECT "$ENV_FILE" "${SDL_AZURE_DEVOPS_ENV_FILE:-}" "${PLATFORM_ROOT}/env/.env" "$GLOBAL_ADO_ENV")"
  export ADO_PAT ADO_ORG ADO_PROJECT
  if [[ -n "$ADO_PAT" && -n "$ADO_ORG" ]]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u ":${ADO_PAT}" \
      "https://dev.azure.com/${ADO_ORG}/_apis/projects?api-version=7.0" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
      ok "ADO connection successful (HTTP 200)"
    elif [[ "$HTTP_CODE" == "401" ]]; then
      warn "ADO returned 401 — PAT may be expired or invalid"
    else
      warn "ADO returned HTTP ${HTTP_CODE} — check credentials"
    fi
  fi
fi

# ── Step 7: Setup Documentation Automation ───────────────────────────────────
step "Installing documentation automation (registries, versioning, hooks)..."

DOC_SETUP_SCRIPT="${PLATFORM_ROOT}/setup-documentation.sh"
if [[ -f "$DOC_SETUP_SCRIPT" && -x "$DOC_SETUP_SCRIPT" ]]; then
  bash "$DOC_SETUP_SCRIPT" --silent 2>&1 | sed 's/^/    /'
  ok "Documentation automation installed"
elif [[ -f "$DOC_SETUP_SCRIPT" ]]; then
  chmod +x "$DOC_SETUP_SCRIPT"
  bash "$DOC_SETUP_SCRIPT" --silent 2>&1 | sed 's/^/    /'
  ok "Documentation automation installed"
else
  warn "setup-documentation.sh not found — skipping documentation automation"
fi

# ── Step 8: Git hooks — auto-install, never fail setup ───────────────────────
step "Git hooks (auto-install if missing)..."

VERIFY_SCRIPT="${PLATFORM_ROOT}/scripts/verify-git-hooks.sh"
INSTALL_DOC="${PLATFORM_ROOT}/setup-documentation.sh"
SDL_SETUP="${PLATFORM_ROOT}/cli/sdlc-setup.sh"
BOOTSTRAP="${PLATFORM_ROOT}/scripts/bootstrap-sdlc-features.sh"

if [[ -f "$VERIFY_SCRIPT" ]]; then
  chmod +x "$VERIFY_SCRIPT" 2>/dev/null || true
fi

_install_hooks_retry() {
  if [[ -f "$INSTALL_DOC" ]]; then
    chmod +x "$INSTALL_DOC" 2>/dev/null || true
    (cd "$PLATFORM_ROOT" && bash "$INSTALL_DOC" --silent) 2>&1 | sed 's/^/    /' || true
  fi
  if [[ -f "$SDL_SETUP" ]] && [[ -d "$PROJECT_PATH/.git" ]]; then
    chmod +x "$SDL_SETUP" 2>/dev/null || true
    bash "$SDL_SETUP" "$PROJECT_PATH" 2>&1 | sed 's/^/    /' || true
  fi
}

if [[ -f "$VERIFY_SCRIPT" ]]; then
  if ! bash "$VERIFY_SCRIPT" "$PROJECT_PATH"; then
    warn "Hooks not detected — installing automatically..."
    _install_hooks_retry
    if bash "$VERIFY_SCRIPT" "$PROJECT_PATH"; then
      ok "Git hooks installed and verified"
    else
      warn "Hooks could not be verified — run: sdlc doctor (setup continues)"
    fi
  else
    ok "Git hooks OK"
  fi
else
  warn "scripts/verify-git-hooks.sh missing"
fi

# ── Step 9: Semantic memory, module KB, NL stack (best-effort) ────────────────
step "Initializing SDLC memory & module features (best-effort)..."

if [[ -f "$BOOTSTRAP" ]]; then
  chmod +x "$BOOTSTRAP" 2>/dev/null || true
  _boot_rc=0
  _boot_out=$(bash "$BOOTSTRAP" "$PROJECT_PATH" "$PLATFORM_ROOT" 2>&1) || _boot_rc=$?
  echo "$_boot_out" | sed 's/^/    /'
  if [[ "${_boot_rc:-0}" -eq 0 ]]; then
    ok "Memory / module bootstrap finished"
  else
    warn "Bootstrap reported warnings — check output above (non-fatal)"
  fi
  unset _boot_out _boot_rc
else
  warn "bootstrap-sdlc-features.sh not found — skipped"
fi

# ── Step 10: Multi-Repository Auto-Detection ─────────────────────────────────
step "Detecting other repositories (multi-repo support)..."

# Source the repos library for auto-detection
if [[ -f "${PLATFORM_ROOT}/cli/lib/repos.sh" ]]; then
  # Quick init of repos.json
  REPOS_FILE="${HOME}/.sdlc/repos.json"
  mkdir -p "${HOME}/.sdlc"
  
  if [[ ! -f "$REPOS_FILE" ]]; then
    echo '{"version": "2.0.0", "last_updated": "", "repos": [], "default_repo": ""}' > "$REPOS_FILE"
  fi
  
  # Auto-detect function (embedded to avoid dependency issues)
  _auto_detect_repos() {
    local search_dirs=("${HOME}/projects" "${HOME}/workspace" "${HOME}/code" "${HOME}/src" "${SDL_PROJECTS_ROOT:-}")
    local platform_parent=$(dirname "$PLATFORM_ROOT")
    [[ -d "$platform_parent" ]] && [[ "$platform_parent" != "$HOME" ]] && search_dirs+=("$platform_parent")
    
    local found=0
    for dir in "${search_dirs[@]}"; do
      [[ -z "$dir" ]] && continue
      [[ -d "$dir" ]] || continue
      
      while IFS= read -r -d '' repo_path; do
        local repo_name=$(basename "$repo_path")
        [[ "$repo_name" == .* ]] && continue
        [[ "$repo_path" == "$PLATFORM_DIR" ]] && continue
        [[ "$repo_path" == "$PROJECT_PATH" ]] && continue
        
        # Check if it's a project repo
        local is_project=false
        [[ -f "$repo_path/pom.xml" ]] && is_project=true
        [[ -f "$repo_path/build.gradle" ]] && is_project=true
        [[ -f "$repo_path/package.json" ]] && is_project=true
        [[ -f "$repo_path/go.mod" ]] && is_project=true
        [[ -d "$repo_path/.git" ]] && is_project=true
        
        if [[ "$is_project" == "true" ]]; then
          local repo_id=$(basename "$repo_path" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
          # Check if already registered
          if ! grep -q "\"$repo_id\"" "$REPOS_FILE" 2>/dev/null; then
            local stack="unknown"
            [[ -f "$repo_path/pom.xml" ]] && stack="java-tej"
            [[ -f "$repo_path/package.json" ]] && stack="javascript"
            [[ -f "$repo_path/go.mod" ]] && stack="go"
            
            local tmp=$(mktemp)
            jq ".repos += [{id: \"$repo_id\", name: \"$repo_name\", path: \"$repo_path\", type: \"microservice\", stack: \"$stack\", detected: \"true\", dependencies: [], dependents: [], team: \"default\", ado_project: \"\", active: false}] | .last_updated = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$REPOS_FILE" > "$tmp"
            mv "$tmp" "$REPOS_FILE"
            ((found++))
            echo "  Found: $repo_name ($stack)"
          fi
        fi
      done < <(find "$dir" -maxdepth 1 -type d -print0 2>/dev/null)
    done
    
    echo "$found"
  }
  
  FOUND_COUNT=$(_auto_detect_repos)
  
  # Also register current project
  CURRENT_REPO_ID=$(basename "$PROJECT_PATH" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
  if ! grep -q "\"$CURRENT_REPO_ID\"" "$REPOS_FILE" 2>/dev/null; then
    CURRENT_STACK="unknown"
    [[ -f "$PROJECT_PATH/pom.xml" ]] && CURRENT_STACK="java-tej"
    [[ -f "$PROJECT_PATH/package.json" ]] && CURRENT_STACK="javascript"
    [[ -f "$PROJECT_PATH/build.gradle" ]] && CURRENT_STACK="java-tej"
    
    tmp=$(mktemp)
    jq ".repos += [{id: \"$CURRENT_REPO_ID\", name: \"$CURRENT_REPO_ID\", path: \"$PROJECT_PATH\", type: \"microservice\", stack: \"$CURRENT_STACK\", detected: \"true\", dependencies: [], dependents: [], team: \"default\", ado_project: \"\", active: true}] | .default_repo = \"$CURRENT_REPO_ID\"" "$REPOS_FILE" > "$tmp"
    mv "$tmp" "$REPOS_FILE"
    ((FOUND_COUNT++))
    echo "  Registered current: $CURRENT_REPO_ID ($CURRENT_STACK)"
  fi
  
  if [[ "$FOUND_COUNT" -gt 0 ]]; then
    ok "Found and registered $FOUND_COUNT repositories"
    ok "Use: sdlc repos list  |  sdlc repos switch <id>"
  else
    ok "Multi-repo support ready (no additional repos found)"
  fi
  
  unset _auto_detect_repos FOUND_COUNT CURRENT_REPO_ID CURRENT_STACK
else
  warn "repos.sh not found — multi-repo auto-detection skipped"
fi

# ── Step 11: Same validation as CI (--quick) — no extra commands for developers ──
step "Validating platform (CI --quick, same as pipeline lint gate)..."

CI_SCRIPT="${PLATFORM_ROOT}/scripts/ci-sdlc-platform.sh"
if [[ -f "$CI_SCRIPT" ]]; then
  chmod +x "$CI_SCRIPT" 2>/dev/null || true
  if bash "$CI_SCRIPT" --quick; then
    ok "CI --quick validation passed (rules, commands, hooks script, bash -n, semantic py_compile)"
  else
    warn "CI --quick reported issues — fix before pushing; full check: bash scripts/ci-sdlc-platform.sh"
  fi
else
  warn "scripts/ci-sdlc-platform.sh not found — skipped"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    Setup Complete!                       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "${ADO_CONFIGURED:-false}" != "true" ]]; then
  echo -e "${YELLOW}⚠ ACTION REQUIRED:${NC}"
  echo -e "  1. Get your ADO PAT: Azure DevOps → User Settings → Personal Access Tokens"
  echo -e "  2. Put secrets in ONE place (recommended for many repos): ${CYAN}~/.sdlc/ado.env${NC}"
  echo -e "     Or edit this repo: ${CYAN}env/.env${NC}"
  echo -e "  3. Set:  ${CYAN}ADO_PAT=...${NC} plus ${CYAN}ADO_ORG${NC} / ${CYAN}ADO_PROJECT${NC} if not detected from git"
  echo ""
fi

echo -e "${GREEN}What's ready:${NC}"
echo -e "  • ${CMD_COUNT} slash commands   → /project:prd-review, /project:grooming, etc."
echo -e "  • ${RULE_COUNT} platform rules  → Quality gates, standards, guardrails"
echo -e "  • MCP tools           → Azure DevOps, Wiki.js, Elasticsearch"
echo -e "  • IDE plugin          → Natural language routing + memory"
echo -e "  • CLI commands        → sdlc use, sdlc run, sdlc ado  (bash/Git Bash)"
echo -e "  • ${BOLD}Multi-repo${NC}        → sdlc repos list, sdlc repos switch (auto-detected)"
echo -e "  • ${BOLD}Windows ADO${NC}       → powershell -File scripts\\ado.ps1 (no admin, no bash)"
echo -e "  • ${BOLD}macOS/Linux ADO${NC}   → bash scripts/ado-mac.sh (no full setup needed)"
echo -e "  • Documentation automation → Auto-generate registries, semantic versioning"
echo -e "  • ${BOLD}Git hooks${NC} → auto-installed when possible"
echo -e "  • ${BOLD}Module + memory${NC} → bootstrap run (set ${CYAN}SDL_SKIP_MODULE_INIT=1${NC} to skip heavy scan)"
echo -e "  • ${BOLD}Doc ingestion${NC}  → Python libs installed (sdlc doc convert .docx/.xlsx/.pptx/.html/.pdf)"
echo -e "  • ${BOLD}CI validation${NC} → ran automatically (${CYAN}scripts/ci-sdlc-platform.sh --quick${NC}); PR/branch builds use GitHub Actions or ${CYAN}azure-pipelines.yml${NC}"
echo ""
echo -e "${GREEN}Try it now:${NC}"
echo -e "  ${CYAN}In IDE chat:${NC}"
echo -e "    /project:prd-review AB#12345"
echo -e "    'Review the PRD for AB#12345 from backend perspective'"
echo -e "    'Create a master story for multi-language signup'"
echo ""
echo -e "  ${CYAN}In terminal:${NC}"
echo -e "    sdlc use backend --stack=java-tej"
echo -e "    sdlc run 01-requirement-intake"
echo -e "    sdlc context"
echo -e "    sdlc repos list              # Show all your repos"
echo -e "    sdlc repos switch <repo-id>  # Switch to another repo"
echo ""
echo -e "${GREEN}Need help?${NC}"
echo -e "  • README.md             — Platform overview"
echo -e "  • GETTING-STARTED.md    — Detailed walkthrough"
echo -e "  • sdlc doctor           — Diagnose issues"
echo -e "  • sdlc help             — Full command reference"
echo ""
