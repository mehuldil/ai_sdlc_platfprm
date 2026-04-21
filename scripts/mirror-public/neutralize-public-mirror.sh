#!/usr/bin/env bash
# Public mirror brand neutralization — delegates to Python (fast on Windows).
# Usage: source neutralize-public-mirror.sh && neutralize_public_mirror /path/to/dest
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$SCRIPT_DIR/neutralize_public_mirror.py"

neutralize_public_mirror() {
  local DEST="${1:?usage: neutralize_public_mirror /path/to/mirror}"
  export PUBLIC_MIRROR_GITHUB_CLONE="${PUBLIC_MIRROR_GITHUB_CLONE:-https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git}"
  if command -v python3 >/dev/null 2>&1; then
    python3 "$PY" "$DEST"
  elif command -v py >/dev/null 2>&1; then
    py -3 "$PY" "$DEST"
  else
    echo "ERROR: python3 not found; install Python 3 to run neutralize_public_mirror.py" >&2
    return 1
  fi
}
