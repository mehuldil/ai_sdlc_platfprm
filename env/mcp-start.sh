#!/usr/bin/env bash
# MCP server launcher — sources shared ADO env before starting any MCP server.
# Used in mcp.json as the command wrapper so tokens are always available.
# Parity with ai-claude-platform/global/env/mcp-start.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
CONFIG_DIR="${HOME}/.sdlc"

# Same merge semantics as cli/lib/config.sh (only non-empty KEY=VAL; later files override).
_merge_env_file() {
  local f="$1"
  [[ -n "$f" && -f "$f" ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue
    [[ "$line" != *=* ]] && continue
    key="${line%%=*}"
    key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
    val="${line#*=}"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
    [[ -z "$val" ]] && continue
    export "${key}=${val}"
  done <"$f"
}

_merge_env_file "${SDL_AZURE_DEVOPS_ENV_FILE:-}"
_merge_env_file "${CONFIG_DIR}/ado.env"
if [[ -n "${SDLC_PLATFORM_DIR:-}" ]]; then
  _merge_env_file "${SDLC_PLATFORM_DIR}/env/.env"
fi
_merge_env_file "$ENV_FILE"

# Map project env var names to MCP server expected names
export ADO_MCP_AUTH_TOKEN="${ADO_PAT:-}"
# WikiJS MCP: prefer WIKIJS_TOKEN; accept WIKI_TOKEN (legacy)
export WIKIJS_API_KEY="${WIKIJS_TOKEN:-${WIKI_TOKEN:-}}"

# Ensure ADO identity vars are exported (sourced from env/.env above)
export ADO_USER_NAME="${ADO_USER_NAME:-}"
export ADO_USER_EMAIL="${ADO_USER_EMAIL:-}"
export ADO_USER_ID="${ADO_USER_ID:-}"
export ADO_ORG="${ADO_ORG:-}"
export ADO_PROJECT="${ADO_PROJECT:-}"

exec "$@"
