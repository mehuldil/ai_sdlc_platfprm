#!/usr/bin/env bash
set -euo pipefail

# AI-SDLC Platform — Verification Report
# Usage: ./verify.sh [project-path]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

PASS=0; FAIL=0

check() {
    if [ "$1" = "true" ]; then
        echo "  [✓] $2"
        PASS=$((PASS + 1))
    else
        echo "  [✗] $2"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══════════════════════════════════════"
echo "  AI-SDLC Platform Verification Report"
echo "═══════════════════════════════════════"
echo ""

# ── Platform Structure ────────────────────────────────────────────────────────
echo "PLATFORM STRUCTURE"
check "$([ -f "$PLATFORM_DIR/CLAUDE.md" ] && echo true || echo false)" "CLAUDE.md present"
check "$([ -f "$PLATFORM_DIR/mcp.json" ] && echo true || echo false)" "mcp.json present"
check "$([ -f "$PLATFORM_DIR/cli/sdlc.sh" ] && echo true || echo false)" "CLI (sdlc.sh) present"
check "$([ -f "$PLATFORM_DIR/cli/sdlc-setup.sh" ] && echo true || echo false)" "Setup script present"

roles=$(ls "$PLATFORM_DIR/roles/"*.md 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$roles" -gt 0 ] && echo true || echo false)" "Roles loaded ($roles files)"

stages=$(ls -d "$PLATFORM_DIR/stages/"[0-9]* 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$stages" -eq 15 ] && echo true || echo false)" "Stages loaded ($stages/15)"

agents=$(find "$PLATFORM_DIR/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$agents" -gt 0 ] && echo true || echo false)" "Agents loaded ($agents files)"

skills=$(find "$PLATFORM_DIR/skills" -maxdepth 2 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$skills" -gt 0 ] && echo true || echo false)" "Skills loaded ($skills files)"

templates=$(ls "$PLATFORM_DIR/templates/"*.md 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$templates" -gt 0 ] && echo true || echo false)" "Templates loaded ($templates files)"
echo ""

# ── Slash Commands ────────────────────────────────────────────────────────────
echo "SLASH COMMANDS"
commands=$(ls "$PLATFORM_DIR/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$commands" -gt 0 ] && echo true || echo false)" "Commands available ($commands files in .claude/commands/)"
for cmd in prd-review pre-grooming grooming sdlc rpi-research rpi-plan rpi-implement code-review; do
  check "$([ -f "$PLATFORM_DIR/.claude/commands/$cmd.md" ] && echo true || echo false)" "/project:$cmd"
done
echo ""

# ── Cross-Reference Validation (Command → Roles, Agents, Templates) ────────
echo "CROSS-REFERENCE VALIDATION"
BROKEN_REFS=0
BROKEN_DETAILS=""

# Scan all .claude/commands/*.md files for references
if [ -d "$PLATFORM_DIR/.claude/commands" ]; then
  for cmd_file in "$PLATFORM_DIR/.claude/commands/"*.md; do
    if [ -f "$cmd_file" ]; then
      cmd_name=$(basename "$cmd_file" .md)
      
      # Extract all role/ agent/ template/ references from the command file
      # Pattern: roles/xxx.md, agents/yyy.md, templates/zzz.md (including subdirs like agents/shared/)
      references=$(grep -oE '(roles/[a-zA-Z0-9_-]+\.md|agents/[a-zA-Z0-9_/-]+\.md|templates/[a-zA-Z0-9_-]+\.md)' "$cmd_file" 2>/dev/null | sort -u || true)
      
      if [ -n "$references" ]; then
        while IFS= read -r ref; do
          # Construct full path and verify it exists
          ref_path="$PLATFORM_DIR/$ref"
          
          if [ ! -f "$ref_path" ]; then
            BROKEN_REFS=$((BROKEN_REFS + 1))
            BROKEN_DETAILS="${BROKEN_DETAILS}    [✗] /project:${cmd_name} → ${ref} (not found)
"
          fi
        done <<< "$references"
      fi
    fi
  done
fi

if [ "$BROKEN_REFS" -eq 0 ]; then
  check "true" "Command cross-references valid (all roles/agents/templates exist)"
else
  check "false" "Command cross-references valid ($BROKEN_REFS broken references found)"
  if [ -n "$BROKEN_DETAILS" ]; then
    printf "%s" "$BROKEN_DETAILS"
  fi
fi
echo ""

# ── Settings ──────────────────────────────────────────────────────────────────
echo "SETTINGS"
settings="$PLATFORM_DIR/.claude/settings.json"
if [ -f "$settings" ]; then
  check "true" "settings.json present"
  check "$(grep -q 'tokenLimits' "$settings" && echo true || echo false)" "tokenLimits configured"
  check "$(grep -q 'modelSelection' "$settings" && echo true || echo false)" "modelSelection configured"
  check "$(grep -q 'quotaEnforcement' "$settings" && echo true || echo false)" "quotaEnforcement configured"
  check "$(grep -q '"skills"' "$settings" && echo true || echo false)" "skills budgets configured"
  check "$(grep -q '"rules"' "$settings" && echo true || echo false)" "operational rules configured"
else
  check "false" "settings.json present"
fi
echo ""

# ── MCP Servers ───────────────────────────────────────────────────────────────
echo "MCP SERVERS"
mcp="$PLATFORM_DIR/mcp.json"
if [ -f "$mcp" ]; then
  check "$(grep -q 'AzureDevOps' "$mcp" && echo true || echo false)" "AzureDevOps MCP server"
  check "$(grep -q 'wikijs' "$mcp" && echo true || echo false)" "WikiJS MCP server"
  check "$(grep -q 'elasticsearch' "$mcp" && echo true || echo false)" "Elasticsearch MCP server"
fi
check "$([ -f "$PLATFORM_DIR/env/mcp-start.sh" ] && echo true || echo false)" "mcp-start.sh launcher"
echo ""

# ── Project Setup (if path provided) ─────────────────────────────────────────
if [ "$TARGET_DIR" != "$PLATFORM_DIR" ]; then
  echo "PROJECT: $TARGET_DIR"
  check "$([ -d "$TARGET_DIR/.sdlc" ] && echo true || echo false)" ".sdlc/ state directory"
  check "$([ -d "$TARGET_DIR/.sdlc/memory" ] && echo true || echo false)" ".sdlc/memory/ shared memory"
  check "$([ -f "$TARGET_DIR/.mcp.json" ] || [ -L "$TARGET_DIR/.mcp.json" ] && echo true || echo false)" ".mcp.json linked"
  check "$([ -d "$TARGET_DIR/.claude" ] && echo true || echo false)" ".claude/ directory"
  check "$([ -d "$TARGET_DIR/.cursor" ] && echo true || echo false)" ".cursor/ directory"

  # Check commands symlinked
  proj_cmds=$(ls "$TARGET_DIR/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
  check "$([ "$proj_cmds" -gt 0 ] && echo true || echo false)" "Slash commands linked ($proj_cmds)"

  # Check hooks
  if [ -d "$TARGET_DIR/.git" ]; then
    check "$([ -x "$TARGET_DIR/.git/hooks/pre-commit" ] && echo true || echo false)" "pre-commit hook installed"
    check "$([ -x "$TARGET_DIR/.git/hooks/commit-msg" ] && echo true || echo false)" "commit-msg hook installed"
  fi

  # Check env
  check "$([ -f "$TARGET_DIR/env/.env" ] && echo true || echo false)" "env/.env present"
  check "$([ -f "$TARGET_DIR/env/mcp-start.sh" ] && echo true || echo false)" "env/mcp-start.sh present"
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "  Run ./scripts/doctor.sh to diagnose and fix issues."
  exit 1
else
  echo ""
  echo "  All checks passed!"
fi
