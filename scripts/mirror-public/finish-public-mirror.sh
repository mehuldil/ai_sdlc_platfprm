#!/usr/bin/env bash
# After file copy (rsync or robocopy), apply neutralize + overlays + final neutralize.
# Usage: bash scripts/mirror-public/finish-public-mirror.sh /path/to/public-checkout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAYS="$SCRIPT_DIR/overlays"
# shellcheck source=neutralize-public-mirror.sh
source "$SCRIPT_DIR/neutralize-public-mirror.sh"

DEST="${1:?usage: finish-public-mirror.sh /path/to/public-mirror-dir}"
[[ -d "$DEST" ]] || {
  echo "ERROR: not a directory: $DEST" >&2
  exit 1
}

PUBLIC_MIRROR_GITHUB_CLONE="${PUBLIC_MIRROR_GITHUB_CLONE:-https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git}"
export PUBLIC_MIRROR_GITHUB_CLONE

neutralize_public_mirror "$DEST"

if [[ -d "$OVERLAYS" ]] && [[ -n "$(find "$OVERLAYS" -type f ! -path '*/.git*' 2>/dev/null | head -1)" ]]; then
  (cd "$OVERLAYS" && find . -type f ! -path './.git*') | while IFS= read -r rel; do
    rel="${rel#./}"
    [[ -z "$rel" ]] && continue
    mkdir -p "$DEST/$(dirname "$rel")"
    cp -f "$OVERLAYS/$rel" "$DEST/$rel"
    echo "Overlay: $rel"
  done
fi

neutralize_public_mirror "$DEST"

echo ""
echo "Done. Regenerate offline manual if needed:"
echo "  cd \"$DEST\" && node User_Manual/build-manual-html.mjs"
