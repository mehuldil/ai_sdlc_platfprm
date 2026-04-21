#!/bin/bash

################################################################################
# AI-SDLC AI-SDLC Platform Setup
# One-time initialization for new projects
# Creates .sdlc/ directory, symlinks to platform, env/, and memory/
################################################################################

set -e

# ============================================================================
# Colors
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

log_step() {
  echo -e "${BLUE}→${NC} $*"
}

die() {
  log_error "$@"
  exit 1
}

# Compute relative path from $1 (source directory) to $2 (target)
# Uses realpath --relative-to if available, falls back to python (python3/python/py -3)
_relative_path() {
  local source_dir="$1"
  local target="$2"

  # Try realpath --relative-to first
  if command -v realpath &>/dev/null; then
    if realpath --relative-to="$source_dir" "$target" 2>/dev/null; then
      return 0
    fi
  fi

  # Fallback to python runtimes
  if command -v python3 &>/dev/null && python3 -V >/dev/null 2>&1; then
    python3 -c "import os.path; print(os.path.relpath('$target', '$source_dir'))" 2>/dev/null && return 0
  fi
  if command -v python &>/dev/null && python -V >/dev/null 2>&1; then
    python -c "import os.path; print(os.path.relpath('$target', '$source_dir'))" 2>/dev/null && return 0
  fi
  if command -v py &>/dev/null && py -3 -V >/dev/null 2>&1; then
    py -3 -c "import os.path; print(os.path.relpath('$target', '$source_dir'))" 2>/dev/null && return 0
  fi

  # Last resort: return absolute path
  echo "$target"
}

# True when a real terminal is attached (interactive read prompts).
# Cursor agent runs without a TTY: use AskQuestion in chat, then pass answers via SDL_SETUP_* (see --help).
_setup_stdin_is_tty() {
  [[ -t 0 ]] || [[ "${SDL_FORCE_INTERACTIVE:-0}" == "1" ]]
}

# ============================================================================
# Parse Arguments
# ============================================================================
GLOBAL_MODE=false
CLEAN_MODE=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)
      GLOBAL_MODE=true
      shift
      ;;
    clean)
      CLEAN_MODE=true
      shift
      ;;
    -h|--help)
      cat << 'EOF'
AI-SDLC SDLC Setup - Initialize project for AI-native workflow

Usage: sdlc-setup [options] [project-path]

Arguments:
  [project-path]  Target project directory (default: current directory)

Options:
  --global        Machine-wide setup (symlinks in home directory)
  clean           Remove AI configs (keeps memory/, env/)

Examples:
  sdlc-setup /path/to/project
  sdlc-setup .
  sdlc-setup ~/workspace/my-app
  sdlc-setup --global                # Machine-wide setup
  sdlc-setup clean                   # Remove AI configs, keep data
  sdlc-setup clean /path/to/project  # Clean specific project

Setup creates:
  .sdlc/              - State directory (role, stack, stage config)
  .claude/            - Symlinks to platform (for Claude)
  .cursor/            - Symlinks to platform (for Cursor)
  env/                - Environment files (.env template)
  memory/             - Project-local shared memory

Non-TTY (e.g. Cursor agent): stdin prompts are not used. The assistant should AskQuestion,
then re-run or export:
  SDL_SETUP_ROLE=<1-8 or name>   product|backend|frontend|ui|tpm|qa|performance|boss
  SDL_SETUP_STACK=<0-6 or name>  0=skip; java-tej|kotlin-android|swift-ios|react-native|jmeter|figma-design
  SDL_SETUP_ADO=1|2              1=write env/.env now; 2=skip (optional; omit if not configuring ADO)
  ADO_ORG=... ADO_PROJECT=... ADO_USER_EMAIL=... ADO_USER_NAME=... ADO_PAT=...  (when SDL_SETUP_ADO=1)

  SDL_SETUP_SKIP_QUESTIONS=1     Skip role/stack/ADO entirely (CI / unattended)
  SDL_FORCE_INTERACTIVE=1        Prefer terminal prompts when stdin can support read

EOF
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

PROJECT_PATH="${1:-.}"

# ============================================================================
# Clean Mode: Remove AI configs, preserve memory/ and env/
# ============================================================================
if [[ "$CLEAN_MODE" == "true" ]]; then
  if [[ ! -d "$PROJECT_PATH" ]]; then
    die "Project path not found: $PROJECT_PATH"
  fi
  PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

  log_step "Cleaning AI configs from: ${CYAN}${PROJECT_PATH}${NC}"
  log_warn "Preserving: memory/, env/, .sdlc/memory/"

  # Remove symlinks only (not actual data)
  for dir in ".claude/platform" ".claude/commands" ".claude/agents" ".claude/templates" ".claude/rules" ".claude/skills" \
             ".cursor/platform" ".cursor/rules"; do
    target="${PROJECT_PATH}/${dir}"
    if [[ -L "$target" || -d "$target" ]]; then
      rm -rf "$target" 2>/dev/null || true
      log_info "Removed: $dir"
    fi
  done

  # Remove symlinked files
  for f in ".claude/settings.json" ".claude/.mcp.json" ".mcp.json" ".cursor/mcp.json" "workflow-state.md"; do
    target="${PROJECT_PATH}/${f}"
    if [[ -L "$target" ]]; then
      rm -f "$target" 2>/dev/null || true
      log_info "Removed symlink: $f"
    fi
  done

  # Remove git hooks installed by setup
  for hook in ".git/hooks/pre-commit" ".git/hooks/commit-msg"; do
    target="${PROJECT_PATH}/${hook}"
    if [[ -f "$target" ]] && grep -q "ai-sdlc-platform" "$target" 2>/dev/null; then
      rm -f "$target" 2>/dev/null || true
      log_info "Removed hook: $hook"
    fi
  done

  # Remove .sdlc state (but keep memory)
  if [[ -d "${PROJECT_PATH}/.sdlc" ]]; then
    for f in "${PROJECT_PATH}/.sdlc/role" "${PROJECT_PATH}/.sdlc/stack" "${PROJECT_PATH}/.sdlc/state.json" "${PROJECT_PATH}/.sdlc/config.json"; do
      rm -f "$f" 2>/dev/null || true
    done
    log_info "Cleared .sdlc/ state files (memory preserved)"
  fi

  log_success "Clean complete. Re-run setup to reinitialize."
  exit 0
fi

# ============================================================================
# Global Mode: Use home directory
# ============================================================================
if [[ "$GLOBAL_MODE" == "true" ]]; then
  PROJECT_PATH="$HOME"
  log_step "Global mode: installing to ${CYAN}${PROJECT_PATH}${NC}"
fi

# Normalize project path
if [[ ! -d "$PROJECT_PATH" ]]; then
  die "Project path not found: $PROJECT_PATH"
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

log_step "Initializing AI-SDLC for project: ${CYAN}${PROJECT_PATH}${NC}"
echo ""

# ============================================================================
# Find SDLC Platform Root
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDLC_PLATFORM="${SCRIPT_DIR%/cli}"

if [[ ! -d "$SDLC_PLATFORM/roles" ]]; then
  die "Cannot find SDLC platform. Expected: $SDLC_PLATFORM"
fi

log_step "SDLC Platform: ${CYAN}${SDLC_PLATFORM}${NC}"
echo ""

# ============================================================================
# Create .sdlc directory
# ============================================================================
SDLC_DIR="${PROJECT_PATH}/.sdlc"
log_step "Creating .sdlc state directory..."

if [[ -d "$SDLC_DIR" ]]; then
  log_warn "Directory already exists (preserving): $SDLC_DIR"
else
  mkdir -p "$SDLC_DIR"
  log_success "Created: $SDLC_DIR"
fi

# ============================================================================
# Create memory directory (project-local shared state)
# ============================================================================
MEMORY_DIR="${SDLC_DIR}/memory"
log_step "Creating memory directory for shared decisions..."

if [[ -d "$MEMORY_DIR" ]]; then
  log_warn "Memory directory exists (preserving)"
else
  mkdir -p "$MEMORY_DIR"
  log_success "Created: $MEMORY_DIR"
fi

# Create initial memory index
if [[ ! -f "$MEMORY_DIR/README.md" ]]; then
  cat > "$MEMORY_DIR/README.md" << 'EOF'
# Shared Memory

This directory stores shared decisions, context, and workflow state across all roles and sessions.

## Files
- `*-intake.md` - Requirement intake decisions
- `*-prd.md` - PRD review outcomes
- `*-design.md` - Architecture/design decisions
- `*-implementation.md` - Implementation choices
- `*-testing.md` - Test strategy and results
- `*-release.md` - Release readiness assessments

All files are committed to git and synced across the team.
EOF
  log_success "Created: $MEMORY_DIR/README.md"
fi

# ============================================================================
# Create .claude/ and .cursor/ symlinks
# ============================================================================
log_step "Setting up editor symlinks (additive, non-destructive)..."

CLAUDE_DIR="${PROJECT_PATH}/.claude"
CURSOR_DIR="${PROJECT_PATH}/.cursor"

mkdir -p "$CLAUDE_DIR" "$CURSOR_DIR"

# Link to platform (read-only reference)
ln -sf "$(_relative_path "$CLAUDE_DIR" "$SDLC_PLATFORM")" "$CLAUDE_DIR/platform" 2>/dev/null || true
ln -sf "$(_relative_path "$CURSOR_DIR" "$SDLC_PLATFORM")" "$CURSOR_DIR/platform" 2>/dev/null || true

# Link to project memory
ln -sf "$(_relative_path "$CLAUDE_DIR" "$MEMORY_DIR")" "$CLAUDE_DIR/memory" 2>/dev/null || true
ln -sf "$(_relative_path "$CURSOR_DIR" "$MEMORY_DIR")" "$CURSOR_DIR/memory" 2>/dev/null || true

# Link slash commands (Claude Code: /project:xxx)
# One relpath per directory (not per file) — avoids hundreds of python/realpath subprocesses.
if [[ -d "$SDLC_PLATFORM/.claude/commands" ]]; then
  mkdir -p "$CLAUDE_DIR/commands"
  REL_CLAUDE_CMDS="$(_relative_path "$CLAUDE_DIR/commands" "$SDLC_PLATFORM/.claude/commands")"
  for cmd in "$SDLC_PLATFORM/.claude/commands/"*.md; do
    if [[ -f "$cmd" ]]; then
      ln -sf "${REL_CLAUDE_CMDS}/$(basename "$cmd")" "$CLAUDE_DIR/commands/$(basename "$cmd")" 2>/dev/null || true
    fi
  done
  CMD_COUNT=$(ls "$SDLC_PLATFORM/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
  log_success "Linked $CMD_COUNT slash commands → .claude/commands/"
fi

# Link settings.json (permissions, tokenLimits, modelSelection, quotaEnforcement)
if [[ -f "$SDLC_PLATFORM/.claude/settings.json" ]]; then
  ln -sf "$(_relative_path "$CLAUDE_DIR" "$SDLC_PLATFORM/.claude/settings.json")" "$CLAUDE_DIR/settings.json" 2>/dev/null || true
  log_success "Linked settings.json → .claude/ (token limits, model selection, permissions)"
fi

# Link commands as Cursor rules (prefix: command-*)
if [[ -d "$SDLC_PLATFORM/.claude/commands" ]]; then
  mkdir -p "$CURSOR_DIR/rules"
  REL_CURSOR_CMDS="$(_relative_path "$CURSOR_DIR/rules" "$SDLC_PLATFORM/.claude/commands")"
  for cmd in "$SDLC_PLATFORM/.claude/commands/"*.md; do
    if [[ -f "$cmd" ]]; then
      ln -sf "${REL_CURSOR_CMDS}/$(basename "$cmd")" "$CURSOR_DIR/rules/command-$(basename "$cmd")" 2>/dev/null || true
    fi
  done
  log_success "Linked commands → .cursor/rules/command-* (Cursor access)"
fi

# Link platform rules → .cursor/rules/ only (Claude Code uses hand-crafted condensed .claude/rules/)
if [[ -d "$SDLC_PLATFORM/rules" ]]; then
  mkdir -p "$CURSOR_DIR/rules"
  REL_CURSOR_RULES="$(_relative_path "$CURSOR_DIR/rules" "$SDLC_PLATFORM/rules")"
  RULES_COUNT=0
  for rule in "$SDLC_PLATFORM/rules/"*.md; do
    if [[ -f "$rule" ]]; then
      ln -sf "${REL_CURSOR_RULES}/$(basename "$rule")" "$CURSOR_DIR/rules/rule-$(basename "$rule")" 2>/dev/null || true
      RULES_COUNT=$((RULES_COUNT + 1))
    fi
  done
  log_success "Linked $RULES_COUNT rules → .cursor/rules/rule-* (symlinks to canonical rules/)"
fi

# Canonical agents/, skills/, templates/ → single symlinks (avoids .claude/agents/agents/… drift and missing domain agents)
if [[ -d "$SDLC_PLATFORM/agents" ]]; then
  rm -rf "${CLAUDE_DIR}/agents" 2>/dev/null || true
  ln -sfn "$(_relative_path "$CLAUDE_DIR" "$SDLC_PLATFORM/agents")" "${CLAUDE_DIR}/agents" 2>/dev/null || true
  log_success "Linked agents/ → .claude/agents (full tree: shared, backend, frontend, qa, …)"
fi

if [[ -d "$SDLC_PLATFORM/skills" ]]; then
  rm -rf "${CLAUDE_DIR}/skills" 2>/dev/null || true
  ln -sfn "$(_relative_path "$CLAUDE_DIR" "$SDLC_PLATFORM/skills")" "${CLAUDE_DIR}/skills" 2>/dev/null || true
  log_success "Linked skills/ → .claude/skills (full tree)"
fi

# Templates: single symlink to canonical templates/ (includes story-templates/ subtree)
if [[ -d "$SDLC_PLATFORM/templates" ]]; then
  rm -rf "${CLAUDE_DIR}/templates" 2>/dev/null || true
  ln -sfn "$(_relative_path "$CLAUDE_DIR" "$SDLC_PLATFORM/templates")" "${CLAUDE_DIR}/templates" 2>/dev/null || true
  REL_CURSOR_TMPL="$(_relative_path "$CURSOR_DIR/rules" "$SDLC_PLATFORM/templates")"
  TMPL_TOP=0
  for tmpl in "$SDLC_PLATFORM/templates/"*.md; do
    if [[ -f "$tmpl" ]]; then
      ln -sf "${REL_CURSOR_TMPL}/$(basename "$tmpl")" "$CURSOR_DIR/rules/template-$(basename "$tmpl")" 2>/dev/null || true
      TMPL_TOP=$((TMPL_TOP + 1))
    fi
  done
  log_success "Linked templates/ → .claude/templates; $TMPL_TOP top-level → .cursor/rules/template-*"
fi

log_success "Created: .claude/ symlinks (agents + skills + templates + commands) and .cursor/ symlinks (rules + template-* for top-level templates)"

# ============================================================================
# MCP — Cursor / Claude Code (Azure DevOps, etc.)
# ============================================================================
log_step "Configuring MCP (Model Context Protocol)..."

ENV_DIR="${PROJECT_PATH}/env"
mkdir -p "$ENV_DIR"

if [[ -f "$SDLC_PLATFORM/env/mcp-start.sh" ]]; then
  if [[ ! -e "${ENV_DIR}/mcp-start.sh" ]]; then
    ln -sf "$(_relative_path "$ENV_DIR" "$SDLC_PLATFORM/env/mcp-start.sh")" "${ENV_DIR}/mcp-start.sh" 2>/dev/null \
      || cp "$SDLC_PLATFORM/env/mcp-start.sh" "${ENV_DIR}/mcp-start.sh"
    chmod +x "${ENV_DIR}/mcp-start.sh" 2>/dev/null || true
    log_success "Installed env/mcp-start.sh (MCP launcher)"
  else
    log_info "env/mcp-start.sh already present (preserving)"
  fi
fi

if [[ -f "$SDLC_PLATFORM/mcp.json" ]]; then
  ln -sf "$(_relative_path "$PROJECT_PATH" "$SDLC_PLATFORM/mcp.json")" "${PROJECT_PATH}/.mcp.json" 2>/dev/null || true
  ln -sf "$(_relative_path "$CLAUDE_DIR" "$SDLC_PLATFORM/mcp.json")" "${CLAUDE_DIR}/.mcp.json" 2>/dev/null || true
  log_success "Linked .mcp.json → platform (Azure DevOps + Wiki.js + Elasticsearch MCP)"
else
  log_warn "Platform mcp.json not found — MCP not linked"
fi

if [[ -f "$SDLC_PLATFORM/.cursor/mcp.json" ]]; then
  mkdir -p "${CURSOR_DIR}"
  ln -sf "$(_relative_path "$CURSOR_DIR" "$SDLC_PLATFORM/.cursor/mcp.json")" "${CURSOR_DIR}/mcp.json" 2>/dev/null || true
  log_success "Linked .cursor/mcp.json → platform (Cursor project MCP)"
fi

# ============================================================================
# Create workflow-state.md for tracking progress
# ============================================================================
log_step "Initializing workflow state tracker..."

WORKFLOW_STATE="${PROJECT_PATH}/workflow-state.md"
if [[ ! -f "$WORKFLOW_STATE" ]]; then
  cat > "$WORKFLOW_STATE" << 'EOF'
# Workflow State

## Current Session
- Role: (not set)
- Stage: (not set)
- Started: (not started)
- Last Updated: (not set)

## Stage Checklist
- [ ] 01-requirement-intake
- [ ] 02-prd-review
- [ ] 03-pre-grooming
- [ ] 04-grooming
- [ ] 05-system-design
- [ ] 06-design-review
- [ ] 07-task-breakdown
- [ ] 08-implementation
- [ ] 09-code-review
- [ ] 10-test-design
- [ ] 11-test-execution
- [ ] 12-commit-push
- [ ] 13-documentation
- [ ] 14-release-signoff
- [ ] 15-summary-close

## Decision Log
- *Add decisions here as they are made during each stage*

## Blockers & Notes
- *Track any blockers or important context*
EOF
  log_success "Created: $WORKFLOW_STATE"
else
  log_warn "Workflow state already exists (preserving)"
fi

# ============================================================================
# Update .gitignore (granular: track .sdlc/module + team semantic JSONL; ignore sqlite)
# ============================================================================
log_step "Updating .gitignore..."

GITIGNORE="${PROJECT_PATH}/.gitignore"

_migrate_gitignore_remove_blanket_sdlc() {
  local g="$1"
  if [[ ! -f "$g" ]]; then
    return 0
  fi
  if grep -qE '^\.sdlc/?$' "$g" 2>/dev/null; then
    local tmp="${g}.sdlc-migrate.$$"
    grep -vE '^\.sdlc/?$' "$g" > "$tmp" && mv "$tmp" "$g"
    log_info "Removed blanket .sdlc/ line — module KB and memory exports can be committed"
  fi
}

_migrate_gitignore_remove_blanket_sdlc "$GITIGNORE"

if [[ ! -f "$GITIGNORE" ]]; then
  cat > "$GITIGNORE" << 'EOF'
# SDLC Platform (granular — .sdlc/module + .sdlc/memory/*.md + semantic-memory-team.jsonl are tracked)
.sdlc/config/
.sdlc/state.json
.sdlc/logs/
.sdlc/**/*.sqlite3
.sdlc/**/*.sqlite3-journal
env/.env
env/.env.local
.mcp.json

# Dependencies
node_modules/
vendor/
build/
dist/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF
  log_success "Created: $GITIGNORE"
else
  if ! grep -q "# SDLC Platform" "$GITIGNORE" 2>/dev/null; then
    cat >> "$GITIGNORE" << 'EOF'

# SDLC Platform (granular — .sdlc/module + team semantic export are tracked)
.sdlc/config/
.sdlc/state.json
.sdlc/logs/
.sdlc/**/*.sqlite3
.sdlc/**/*.sqlite3-journal
env/.env
env/.env.local
.mcp.json
EOF
    log_success "Updated: $GITIGNORE"
  else
    if ! grep -q "^\.sdlc/config/" "$GITIGNORE" 2>/dev/null; then
      cat >> "$GITIGNORE" << 'EOF'

# SDLC granular rules (tracked: module KB, semantic-memory-team.jsonl, memory/*.md)
.sdlc/config/
.sdlc/state.json
.sdlc/logs/
.sdlc/**/*.sqlite3
.sdlc/**/*.sqlite3-journal
EOF
      log_success "Appended granular SDLC rules to: $GITIGNORE"
    else
      log_info ".gitignore already has granular SDLC entries"
    fi
  fi
fi

# ============================================================================
# Install git hooks (if .git/ exists)
# ============================================================================
log_step "Checking git hooks..."

if [[ -d "${PROJECT_PATH}/.git" ]]; then
  mkdir -p "${PROJECT_PATH}/.git/hooks"

  # pre-commit hook — secrets check + formatting validation
  HOOK_FILE="${PROJECT_PATH}/.git/hooks/pre-commit"
  if [[ -f "${SDLC_PLATFORM}/hooks/pre-commit.sh" ]]; then
    cat > "$HOOK_FILE" << 'HOOK_EOF'
#!/usr/bin/env bash
set -euo pipefail

# pre-commit hook — installed by ai-sdlc-platform/cli/sdlc-setup.sh
# Runs secrets check + formatting validation before each commit

PLATFORM_DIR="$(cd "$(git rev-parse --show-toplevel)/.." && pwd)"
HOOK_SCRIPT=""

# Find the platform hooks directory
for candidate in "$PLATFORM_DIR/ai-sdlc-platform/hooks/pre-commit.sh" \
                 "$(dirname "$PLATFORM_DIR")/ai-sdlc-platform/hooks/pre-commit.sh"; do
  if [[ -f "$candidate" ]]; then
    HOOK_SCRIPT="$candidate"
    break
  fi
done

# Also check SDLC_PLATFORM_DIR from env
if [[ -z "$HOOK_SCRIPT" && -f "${SDLC_PLATFORM_DIR:-}/hooks/pre-commit.sh" ]]; then
  HOOK_SCRIPT="${SDLC_PLATFORM_DIR}/hooks/pre-commit.sh"
fi

if [[ -n "$HOOK_SCRIPT" ]]; then
  bash "$HOOK_SCRIPT"
else
  # Inline minimal secrets check
  SECRETS_PATTERN='(password|secret|api[_-]?key|token|private[_-]?key)\s*[:=]\s*["\x27]?[A-Za-z0-9+/=]{8,}'
  if git diff --cached --diff-filter=ACM -U0 | grep -iEq "$SECRETS_PATTERN"; then
    echo "⚠️  Potential secrets detected in staged changes!"
    echo "   Review staged files before committing."
    exit 1
  fi
fi
HOOK_EOF
    chmod +x "$HOOK_FILE"
    log_success "Installed: .git/hooks/pre-commit (secrets + formatting check)"
  else
    log_warn "Platform hooks/pre-commit.sh not found — skipping hook installation"
  fi

  # commit-msg hook — enforce ADO work item reference (C4: End-to-end tracing)
  COMMIT_MSG_HOOK="${PROJECT_PATH}/.git/hooks/commit-msg"
  cat > "$COMMIT_MSG_HOOK" << 'HOOK_EOF'
#!/usr/bin/env bash
# commit-msg hook — ENFORCE ADO work item reference (C4: End-to-end tracing)
# Blocks commits without AB#XXXX pattern, unless [no-ref] tag is used for infrastructure commits
MSG_FILE="$1"
MSG=$(cat "$MSG_FILE")

# Allow skip with [no-ref] tag for infrastructure/tooling commits
if echo "$MSG" | grep -qE '\[no-ref\]'; then
  # Log the skip to tracing log
  if [[ -d ".sdlc/memory" ]]; then
    {
      echo "$(date +'%Y-%m-%d %H:%M:%S') [SKIP-REF] commit-msg hook: [no-ref] tag found"
      echo "  Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
      echo "  Message: $(echo "$MSG" | head -1)"
    } >> .sdlc/memory/tracing-log.md
  fi
  exit 0
fi

# ENFORCE: Check for AB#XXXX pattern
if ! echo "$MSG" | grep -qE 'AB#[0-9]+'; then
  echo ""
  echo "✗ BLOCKED: Commit must reference an ADO work item with AB#<id>"
  echo "  Add the work item ID to your commit message, e.g.:"
  echo "    git commit -m 'Feature description AB#12345'"
  echo ""
  echo "  For infrastructure/tooling commits, use [no-ref] tag:"
  echo "    git commit -m '[no-ref] Update CI/CD pipeline'"
  echo ""
  exit 1
fi
HOOK_EOF
  chmod +x "$COMMIT_MSG_HOOK"
  log_success "Installed: .git/hooks/commit-msg (ENFORCE ADO link + C4 tracing)"

  # post-merge / post-checkout / post-commit — module KB + semantic team JSONL (fetch/pull parity)
  POST_MERGE="${PROJECT_PATH}/.git/hooks/post-merge"
  cat > "$POST_MERGE" << 'PM_EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel)"
for PLAT in "$REPO/ai-sdlc-platform" "$REPO/../ai-sdlc-platform"; do
  if [[ -f "$PLAT/scripts/sdlc-auto-sync.sh" ]]; then
    bash "$PLAT/scripts/sdlc-auto-sync.sh" post-merge
    exit 0
  fi
done
exit 0
PM_EOF
  chmod +x "$POST_MERGE"
  log_success "Installed: .git/hooks/post-merge (module + semantic import after pull)"

  POST_CHECKOUT="${PROJECT_PATH}/.git/hooks/post-checkout"
  cat > "$POST_CHECKOUT" << 'PCO_EOF'
#!/usr/bin/env bash
set -euo pipefail
# $1=prev HEAD $2=new HEAD $3=1 iff branch checkout
[[ "${3:-0}" == "1" ]] || exit 0
REPO="$(git rev-parse --show-toplevel)"
for PLAT in "$REPO/ai-sdlc-platform" "$REPO/../ai-sdlc-platform"; do
  if [[ -f "$PLAT/scripts/sdlc-auto-sync.sh" ]]; then
    bash "$PLAT/scripts/sdlc-auto-sync.sh" post-checkout
    exit 0
  fi
done
exit 0
PCO_EOF
  chmod +x "$POST_CHECKOUT"
  log_success "Installed: .git/hooks/post-checkout (sync after branch switch)"

  PC="${PROJECT_PATH}/.git/hooks/post-commit"
  if [[ ! -f "$PC" ]]; then
    cat > "$PC" << 'PCS_EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel)"
for PLAT in "$REPO/ai-sdlc-platform" "$REPO/../ai-sdlc-platform"; do
  if [[ -f "$PLAT/scripts/sdlc-auto-sync.sh" ]]; then
    bash "$PLAT/scripts/sdlc-auto-sync.sh" post-commit
    exit 0
  fi
done
exit 0
PCS_EOF
    chmod +x "$PC"
    log_success "Installed: .git/hooks/post-commit (async backup when --no-verify used)"
  else
    if ! grep -q "sdlc-auto-sync.sh" "$PC" 2>/dev/null; then
      cat >> "$PC" << 'PC_APPEND'

# --- AI-SDLC: async module + semantic export (backup if pre-commit skipped) ---
REPO="$(git rev-parse --show-toplevel)"
for PLAT in "$REPO/ai-sdlc-platform" "$REPO/../ai-sdlc-platform"; do
  [[ -f "$PLAT/scripts/sdlc-auto-sync.sh" ]] && bash "$PLAT/scripts/sdlc-auto-sync.sh" post-commit && break
done
PC_APPEND
      chmod +x "$PC"
      log_success "Appended SDLC post-commit to existing .git/hooks/post-commit"
    fi
  fi

else
  log_info "No .git/ directory found — skipping hook installation (local mode)"
fi

# ============================================================================
# Create env/ directory with .env template
# ============================================================================
log_step "Setting up environment directory..."

ENV_DIR="${PROJECT_PATH}/env"
mkdir -p "$ENV_DIR"
log_success "Created: $ENV_DIR/"

# Prefer canonical template from platform package (same keys as validate-config.sh expects)
PLATFORM_ENV_TEMPLATE="${SDLC_PLATFORM}/env/env.template"
if [[ -f "$PLATFORM_ENV_TEMPLATE" && ! -f "${ENV_DIR}/env.template" ]]; then
  cp "$PLATFORM_ENV_TEMPLATE" "${ENV_DIR}/env.template"
  log_success "Copied env.template from platform → ${ENV_DIR}/env.template"
fi

ENV_TEMPLATE="${ENV_DIR}/.env.example"
if [[ ! -f "$ENV_TEMPLATE" ]]; then
  cat > "$ENV_TEMPLATE" << 'EOF'
# AI-SDLC SDLC Environment
# Copy this file to .env and fill in values

# Project Configuration
PROJECT_NAME=
PROJECT_ROOT=.
ORG_NAME=your-ado-org
ADO_PROJECT=YourAzureProject
SDLC_PLATFORM_ROOT=
SDLC_MEMORY_AUTO_SYNC=true

# Azure DevOps (required for MCP + sdlc ado)
ADO_ORG=your-ado-org
ADO_PROJECT_ID=
ADO_USER_EMAIL=
ADO_USER_NAME=
ADO_USER_ID=
ADO_PAT=

# Wiki (optional)
WIKIJS_TOKEN=
WIKI_TOKEN=

# Elasticsearch (optional)
ES_URL=
ES_USER=
ES_PWD=

# Infrastructure (optional)
REDIS_URL=redis://localhost:6379
OPENAI_KEY=
LOG_LEVEL=INFO
TOKEN_LOG_FILE=env/.token-usage.log
EOF
  log_success "Created: $ENV_TEMPLATE"
fi

# ============================================================================
# Role / stack / ADO — TTY: read prompts; non-TTY: SDL_SETUP_* (AskQuestion in Cursor, then export)
# ============================================================================
SELECTED_ROLE=""
SELECTED_STACK=""

ROLES=("product" "backend" "frontend" "ui" "tpm" "qa" "performance" "boss")
ROLE_DESC=(
  "Product Manager — requirements, PRDs, grooming, release sign-off"
  "Backend Developer — Java/TEJ, APIs, system design, implementation"
  "Frontend Developer — Android/iOS/RN, mobile UI, implementation"
  "UI Designer — Figma, design system, component specs"
  "Technical Program Manager — cross-team coordination, sprint planning"
  "QA Engineer — test design, test execution, defect management"
  "Performance Engineer — load testing, JMeter, NFR validation"
  "Boss/Leader — reports, dashboards, release oversight"
)
STACKS=("java-tej" "kotlin-android" "swift-ios" "react-native" "jmeter" "figma-design")
STACK_DESC=(
  "Java 17 + RestExpress (TEJ) microservices"
  "Kotlin + Android MVVM"
  "Swift + iOS async/await"
  "React Native + TypeScript"
  "JMeter load testing"
  "Figma design system"
)

_setup_resolve_role_name() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || return 1
  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    local idx=$((raw - 1))
    (( idx >= 0 && idx < ${#ROLES[@]} )) || return 1
    echo "${ROLES[$idx]}"
    return 0
  fi
  local r
  for r in "${ROLES[@]}"; do
    [[ "$r" == "$raw" ]] && echo "$r" && return 0
  done
  return 1
}

_setup_resolve_stack_name() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || return 1
  if [[ "$raw" == "0" ]]; then
    echo ""
    return 0
  fi
  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    local idx=$((raw - 1))
    (( idx >= 0 && idx < ${#STACKS[@]} )) || return 1
    echo "${STACKS[$idx]}"
    return 0
  fi
  local s
  for s in "${STACKS[@]}"; do
    [[ "$s" == "$raw" ]] && echo "$s" && return 0
  done
  return 1
}

_setup_write_ado_env_file() {
  local ado_org="$1" ado_project="$2" ado_email="$3" ado_name="$4" ado_pat="$5"
  local ENV_FILE="${ENV_DIR}/.env"
  if [[ ! -f "$ENV_FILE" ]]; then
    cp "${ENV_DIR}/.env.example" "$ENV_FILE" 2>/dev/null || true
  fi
  if [[ -n "$ado_org" && -n "$ado_pat" ]]; then
    sed -i "s|^ADO_ORG=.*|ADO_ORG=${ado_org}|" "$ENV_FILE" 2>/dev/null || true
    sed -i "s|^ADO_PROJECT=.*|ADO_PROJECT=${ado_project}|" "$ENV_FILE" 2>/dev/null || true
    sed -i "s|^ADO_USER_EMAIL=.*|ADO_USER_EMAIL=${ado_email}|" "$ENV_FILE" 2>/dev/null || true
    sed -i "s|^ADO_USER_NAME=.*|ADO_USER_NAME=${ado_name}|" "$ENV_FILE" 2>/dev/null || true
    sed -i "s|^ADO_PAT=.*|ADO_PAT=${ado_pat}|" "$ENV_FILE" 2>/dev/null || true
    log_success "ADO configuration saved to env/.env"
  else
    log_warn "Incomplete ADO config. Fill in env/.env manually."
  fi
}

# Apply role, stack, ADO from environment (set after AskQuestion in Cursor). Returns 0 if anything applied.
_setup_apply_from_env() {
  local did=0
  local resolved="" stack_r=""

  if [[ -n "${SDL_SETUP_ROLE:-}" ]]; then
    if resolved=$(_setup_resolve_role_name "${SDL_SETUP_ROLE}"); then
      SELECTED_ROLE="$resolved"
      echo "$SELECTED_ROLE" > "${SDLC_DIR}/role"
      log_success "Role set to: ${SELECTED_ROLE} (from SDL_SETUP_ROLE)"
      did=1
      if [[ -n "${SDL_SETUP_STACK:-}" ]]; then
        if stack_r=$(_setup_resolve_stack_name "${SDL_SETUP_STACK}"); then
          if [[ -n "$stack_r" ]]; then
            SELECTED_STACK="$stack_r"
            echo "$SELECTED_STACK" > "${SDLC_DIR}/stack"
            log_success "Stack set to: ${SELECTED_STACK} (from SDL_SETUP_STACK)"
          else
            log_info "Stack skipped (SDL_SETUP_STACK=0). Set later: sdlc use <role> --stack=<stack>"
          fi
          did=1
        else
          log_warn "Invalid SDL_SETUP_STACK — use 0-${#STACKS[@]} or: ${STACKS[*]}"
        fi
      elif [[ "$SELECTED_ROLE" == "backend" || "$SELECTED_ROLE" == "frontend" || "$SELECTED_ROLE" == "qa" || "$SELECTED_ROLE" == "performance" ]]; then
        log_info "Dev role without SDL_SETUP_STACK — set later: sdlc use ${SELECTED_ROLE} --stack=<stack>"
      fi
    else
      log_warn "Invalid SDL_SETUP_ROLE — use 1-${#ROLES[@]} or: ${ROLES[*]}"
    fi
  fi

  local want_ado=""
  case "${SDL_SETUP_ADO:-}" in
    1|yes|true|y|Y) want_ado=1 ;;
    2|no|false|n|N|'') want_ado=0 ;;
    *)
      log_warn "Unknown SDL_SETUP_ADO=${SDL_SETUP_ADO} — use 1 or 2"
      want_ado=0
      ;;
  esac

  if [[ "$want_ado" == "1" ]]; then
    _setup_write_ado_env_file "${ADO_ORG:-}" "${ADO_PROJECT:-}" "${ADO_USER_EMAIL:-}" "${ADO_USER_NAME:-}" "${ADO_PAT:-}"
    did=1
  fi

  [[ "$did" -eq 1 ]] && return 0
  return 1
}

if [[ "${SDL_SETUP_SKIP_QUESTIONS:-0}" == "1" ]]; then
  log_info "SDL_SETUP_SKIP_QUESTIONS=1 — skipping role/stack/ADO (configure later: sdlc use, env/.env)"
elif _setup_stdin_is_tty; then
  echo ""
  log_step "${CYAN}═══════════════════════════════════════════════════${NC}"
  log_step "${CYAN}  Select Your Role${NC}"
  log_step "${CYAN}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo "  Which role will you be working as?"
  echo ""

  for i in "${!ROLES[@]}"; do
    echo -e "  $((i+1))) ${GREEN}${ROLES[$i]}${NC} — ${ROLE_DESC[$i]}"
  done
  echo ""
  read -rp "Enter role number (1-${#ROLES[@]}): " role_choice

  if [[ "$role_choice" =~ ^[0-9]+$ ]] && (( role_choice >= 1 && role_choice <= ${#ROLES[@]} )); then
    SELECTED_ROLE="${ROLES[$((role_choice-1))]}"
  else
    log_warn "Invalid selection. You can set your role later with: sdlc use <role>"
  fi

  if [[ -n "$SELECTED_ROLE" ]]; then
    echo "$SELECTED_ROLE" > "${SDLC_DIR}/role"
    log_success "Role set to: ${SELECTED_ROLE}"

    if [[ "$SELECTED_ROLE" == "backend" || "$SELECTED_ROLE" == "frontend" || "$SELECTED_ROLE" == "qa" || "$SELECTED_ROLE" == "performance" ]]; then
      echo ""
      log_step "Which tech stack will you be working with?"
      echo ""
      for i in "${!STACKS[@]}"; do
        echo -e "  $((i+1))) ${GREEN}${STACKS[$i]}${NC} — ${STACK_DESC[$i]}"
      done
      echo "  0) Skip (no stack needed now)"
      echo ""
      read -rp "Enter stack number (0-${#STACKS[@]}): " stack_choice

      if [[ "$stack_choice" =~ ^[0-9]+$ ]] && (( stack_choice >= 1 && stack_choice <= ${#STACKS[@]} )); then
        SELECTED_STACK="${STACKS[$((stack_choice-1))]}"
        echo "$SELECTED_STACK" > "${SDLC_DIR}/stack"
        log_success "Stack set to: ${SELECTED_STACK}"
      elif [[ "$stack_choice" == "0" ]]; then
        log_info "Stack skipped. Set later with: sdlc use <role> --stack=<stack>"
      fi
    fi
  fi

  echo ""
  log_step "Do you want to configure Azure DevOps (ADO) now?"
  echo ""
  echo "  1) Yes — I have my ADO PAT ready"
  echo "  2) No  — I'll configure later"
  echo ""
  read -rp "Enter choice (1-2): " ado_choice

  if [[ "$ado_choice" == "1" ]]; then
    echo ""
    read -rp "  ADO Organization (e.g., your-ado-org): " ado_org
    read -rp "  ADO Project (e.g., YourAzureProject): " ado_project
    read -rp "  ADO User Email: " ado_email
    read -rp "  ADO User Name: " ado_name
    read -rsp "  ADO Personal Access Token (PAT): " ado_pat
    echo ""
    _setup_write_ado_env_file "$ado_org" "$ado_project" "$ado_email" "$ado_name" "$ado_pat"
  else
    log_info "ADO config skipped. Set up later: copy env/.env.example → env/.env"
  fi
elif _setup_apply_from_env; then
  log_success "Applied role/stack/ADO from environment (Cursor agent / SDL_SETUP_*)."
else
  echo ""
  log_step "Non-TTY session: use AskQuestion in Cursor for role, stack, and ADO, then re-run with exports"
  log_info "Example: export SDL_SETUP_ROLE=backend SDL_SETUP_STACK=1 SDL_SETUP_ADO=1 ADO_ORG=... ADO_PAT=... && bash cli/sdlc-setup.sh ."
  log_info "See: sdlc-setup.sh --help (Non-TTY). Or SDL_SETUP_SKIP_QUESTIONS=1 for CI."
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
log_step "${CYAN}═══════════════════════════════════════════════════${NC}"
log_step "${CYAN}  AI-SDLC Platform Setup Complete${NC}"
log_step "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "  Project:    ${PROJECT_PATH}"
echo "  Platform:   ${SDLC_PLATFORM}"
if [[ -n "$SELECTED_ROLE" ]]; then
  echo "  Role:       ${SELECTED_ROLE}"
fi
if [[ -n "${SELECTED_STACK:-}" ]]; then
  echo "  Stack:      ${SELECTED_STACK}"
fi
echo ""
echo "  Created:"
echo "    .sdlc/           State directory (role, stack, stage)"
echo "    .sdlc/memory/    Shared memory"
echo "    .claude/         Claude Code symlinks + commands"
echo "    .cursor/         Cursor symlinks + rules"
echo "    .mcp.json        MCP config (ADO + Wiki.js + Elasticsearch)"
echo "    env/             Environment config (.env template)"
echo "    workflow-state   Stage tracker"
echo ""
echo "  Next steps:"
echo "    1. Initialize Module System:"
echo "       sdlc module init .               (scan repo, generate contracts + knowledge)"
echo "       cp hooks/module-pre-commit.sh .git/hooks/pre-commit"
echo "       cp hooks/module-post-commit.sh .git/hooks/post-commit"
echo "       chmod +x .git/hooks/pre-commit .git/hooks/post-commit"
echo ""
echo "    2. Fill in env/.env with your ADO credentials"
echo "       cat env/.env.example             (see required fields)"
echo "       vim env/.env                     (edit with your values)"
echo ""
echo "    3. Verify setup:"
echo "       sdlc doctor                      (run diagnostics)"
echo "       sdlc module show                 (preview contracts + knowledge)"
echo ""
echo "    4. Start working:"
echo "       sdlc use <role>                  (set your role)"
echo "       sdlc module load                 (smart context for AI)"
echo "       sdlc run <stage>                 (start workflow)"
echo ""
echo "  Stacks supported: Java, Kotlin/Android, Swift/iOS, React Native, Node.js, C/C++"
echo ""
echo "  Documentation:"
echo "    USER-MANUAL/                        (quick start guides)"
echo "    sdlc module show help               (all module commands)"
echo ""
log_success "Setup complete. Run 'sdlc module init .' to initialize!"
