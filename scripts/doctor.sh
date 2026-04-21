#!/usr/bin/env bash
set -euo pipefail

# AI-SDLC Platform — Doctor (Diagnose & Fix)
# Usage: ./doctor.sh [project-path]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "═══════════════════════════════════════"
echo "  AI-SDLC Platform Doctor"
echo "═══════════════════════════════════════"
echo ""

PASS=0; WARN=0; FIX=0

check_ok()   { echo "  [OK]   $1"; PASS=$((PASS + 1)); }
check_warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }
check_fix()  { echo "  [FIX]  $1"; FIX=$((FIX + 1)); }

# ── Prerequisites ─────────────────────────────────────────────────────────────
echo "PREREQUISITES"

if command -v git >/dev/null 2>&1; then
  check_ok "Git $(git --version | cut -d' ' -f3)"
else
  check_fix "Git not found → Install from git-scm.com"
fi

if command -v node >/dev/null 2>&1; then
  check_ok "Node.js $(node --version)"
else
  check_warn "Node.js not found (needed for MCP servers)"
fi

if command -v npx >/dev/null 2>&1; then
  check_ok "npx available"
else
  check_warn "npx not found (needed for MCP servers)"
fi

if command -v cursor >/dev/null 2>&1; then
  check_ok "Cursor IDE found"
else
  check_warn "Cursor IDE not found (optional for Claude Code users)"
fi

echo ""

# ── Platform ──────────────────────────────────────────────────────────────────
echo "PLATFORM"

if [ -f "$PLATFORM_DIR/CLAUDE.md" ]; then
  check_ok "Platform repo at $PLATFORM_DIR"
else
  check_fix "Platform repo not found at $PLATFORM_DIR → Clone ai-sdlc-platform"
fi

if [ -f "$PLATFORM_DIR/mcp.json" ]; then
  check_ok "mcp.json present"
else
  check_fix "mcp.json missing in platform root"
fi

if [ -f "$PLATFORM_DIR/cli/sdlc.sh" ]; then
  check_ok "CLI (sdlc.sh) present"
else
  check_fix "CLI missing → cli/sdlc.sh not found"
fi

if [ -d "$PLATFORM_DIR/.claude/commands" ]; then
  cmd_count=$(ls "$PLATFORM_DIR/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
  check_ok "Slash commands: $cmd_count found"
else
  check_fix "Slash commands directory missing → .claude/commands/"
fi

echo ""

# ── Project Setup ─────────────────────────────────────────────────────────────
echo "PROJECT: $TARGET_DIR"

if [ -d "$TARGET_DIR/.sdlc" ]; then
  check_ok ".sdlc/ state directory exists"
else
  check_fix ".sdlc/ not found → Run: sdlc-setup.sh $TARGET_DIR"
fi

if [ -f "$TARGET_DIR/.mcp.json" ] || [ -L "$TARGET_DIR/.mcp.json" ]; then
  if [ -L "$TARGET_DIR/.mcp.json" ] && [ ! -e "$TARGET_DIR/.mcp.json" ]; then
    check_fix ".mcp.json symlink is broken → Re-run sdlc-setup.sh"
  else
    check_ok "MCP config present (.mcp.json)"
  fi
else
  check_fix ".mcp.json not found → Re-run sdlc-setup.sh"
fi

# Check symlinks
echo ""
echo "SYMLINKS"
broken=0
for dir in "$TARGET_DIR/.claude" "$TARGET_DIR/.cursor"; do
  if [ -d "$dir" ]; then
    for f in "$dir/"* "$dir/commands/"* "$dir/rules/"* "$dir/memory/"*; do
      if [ -L "$f" ] && [ ! -e "$f" ]; then
        echo "  [BROKEN] $f → $(readlink "$f")"
        broken=$((broken + 1))
      fi
    done 2>/dev/null
  fi
done
if [ "$broken" -eq 0 ]; then
  check_ok "All symlinks valid"
else
  check_fix "$broken broken symlinks → Re-run sdlc-setup.sh"
fi

# ── Environment ───────────────────────────────────────────────────────────────
echo ""
echo "ENVIRONMENT"

env_dir="$TARGET_DIR/env"
if [ -f "$env_dir/.env" ]; then
  check_ok "env/.env present"
  # Check critical vars
  for var in ADO_PAT ADO_ORG; do
    if grep -q "^${var}=.\+" "$env_dir/.env" 2>/dev/null; then
      check_ok "$var is set"
    else
      check_warn "$var is empty or missing in env/.env"
    fi
  done
else
  check_warn "env/.env not found → Copy env/.env.example to env/.env"
fi

if [ -f "$env_dir/mcp-start.sh" ] && [ -x "$env_dir/mcp-start.sh" ]; then
  check_ok "mcp-start.sh present and executable"
else
  check_fix "mcp-start.sh missing or not executable → Re-run sdlc-setup.sh"
fi

# ── Git Hooks ─────────────────────────────────────────────────────────────────
echo ""
echo "GIT HOOKS"

if [ -d "$TARGET_DIR/.git" ]; then
  if [ -f "$TARGET_DIR/.git/hooks/pre-commit" ] && [ -x "$TARGET_DIR/.git/hooks/pre-commit" ]; then
    check_ok "pre-commit hook installed"
  else
    check_warn "pre-commit hook not installed → Re-run sdlc-setup.sh"
  fi
  if [ -f "$TARGET_DIR/.git/hooks/commit-msg" ] && [ -x "$TARGET_DIR/.git/hooks/commit-msg" ]; then
    check_ok "commit-msg hook installed"
  else
    check_warn "commit-msg hook not installed → Re-run sdlc-setup.sh"
  fi
else
  check_ok "No .git/ — local directory mode (hooks not applicable)"
fi

# ── Active Context ────────────────────────────────────────────────────────────
echo ""
echo "ACTIVE CONTEXT"

if [ -f "$TARGET_DIR/.sdlc/role" ]; then
  role=$(cat "$TARGET_DIR/.sdlc/role")
  if [ -f "$PLATFORM_DIR/roles/${role}.md" ]; then
    check_ok "Role: $role"
  else
    check_fix "Role '$role' not found in platform roles/"
  fi
else
  check_warn "No role set → Run: sdlc use role <role>"
fi

if [ -f "$TARGET_DIR/.sdlc/stack" ]; then
  check_ok "Stack: $(cat "$TARGET_DIR/.sdlc/stack")"
else
  check_warn "No stack set (required for dev roles)"
fi

if [ -f "$TARGET_DIR/.sdlc/stage" ]; then
  check_ok "Stage: $(cat "$TARGET_DIR/.sdlc/stage")"
else
  check_warn "No stage set → Run: sdlc use stage <stage>"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "  Results: $PASS OK, $WARN warnings, $FIX fixes needed"
echo "═══════════════════════════════════════"

if [ "$FIX" -gt 0 ]; then
  echo ""
  echo "Fix [FIX] items above, then run: ./scripts/verify.sh $TARGET_DIR"
  exit 1
fi
