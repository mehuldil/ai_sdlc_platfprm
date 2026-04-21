#!/usr/bin/env bash
# Sync Azure DevOps canonical tree → local GitHub mirror checkout (neutral URLs + overlays).
# Usage: bash scripts/mirror-public/sync-to-public-mirror.sh [DEST_DIR]
# Default DEST: ../AI_SDLC_Platform relative to parent of repo root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXCLUDES="$SCRIPT_DIR/rsync-excludes.txt"
DEST="${1:-}"
if [[ -z "$DEST" ]]; then
  DEST="$(cd "$REPO_ROOT/.." && pwd)/AI_SDLC_Platform"
fi
DEST="$(cd "$(dirname "$DEST")" && pwd)/$(basename "$DEST")"

PUBLIC_MIRROR_GITHUB_CLONE="${PUBLIC_MIRROR_GITHUB_CLONE:-https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git}"

DRY_RUN="${PUBLIC_MIRROR_DRY_RUN:-}"
RSYNC_OPTS=(-a --delete)
if [[ "${DRY_RUN:-}" == "1" ]]; then
  RSYNC_OPTS+=(--dry-run -v)
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync not found." >&2
  echo "  Windows: powershell -File scripts/mirror-public/sync-to-public-mirror.ps1 -Dest \"<path>\"" >&2
  echo "  Then:    bash scripts/mirror-public/finish-public-mirror.sh \"<path>\"" >&2
  exit 1
fi

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "ERROR: repo root not found: $REPO_ROOT" >&2
  exit 1
fi

if [[ ! -d "$DEST" ]]; then
  echo "ERROR: mirror destination directory does not exist: $DEST" >&2
  echo "Clone the GitHub repo first, e.g. git clone $PUBLIC_MIRROR_GITHUB_CLONE" >&2
  exit 1
fi

if [[ ! -f "$EXCLUDES" ]]; then
  echo "ERROR: missing $EXCLUDES" >&2
  exit 1
fi

echo "Source (Azure canonical): $REPO_ROOT"
echo "Dest (public mirror):     $DEST"
echo ""

mkdir -p "$DEST"

rsync "${RSYNC_OPTS[@]}" \
  --exclude-from="$EXCLUDES" \
  "$REPO_ROOT/" "$DEST/"

if [[ "${DRY_RUN:-}" == "1" ]]; then
  echo "Dry run only — no neutralize or overlays applied."
  exit 0
fi

export PUBLIC_MIRROR_GITHUB_CLONE
bash "$SCRIPT_DIR/finish-public-mirror.sh" "$DEST"

echo ""
echo "Done. Next in the mirror repo:"
echo "  cd \"$DEST\""
echo "  git status"
echo "  node User_Manual/build-manual-html.mjs   # regenerates manual.html from neutralized Markdown"
echo "  git add -A && git commit -m \"...\" && git push origin main"
