#!/usr/bin/env bash
################################################################################
# Batch SDLC setup for many application repositories
#
# Runs the platform ./setup.sh once per path listed in a manifest file (one
# absolute or relative path per line). Use when you have many microservice
# repos and want to avoid typing ./setup.sh for each by hand.
#
# Usage:
#   ./scripts/setup-repos-from-manifest.sh [OPTIONS] [MANIFEST]
#
#   MANIFEST defaults to ./repos.manifest in the current working directory if
#   omitted.
#
# Options:
#   --continue          Continue after a failed repo (default: stop on first failure)
#   --skip-module-init  Set SDL_SKIP_MODULE_INIT=1 for every run (faster bulk bootstrap)
#   -h, --help          Show this help
#
# Manifest format:
#   - One path per line; empty lines ignored
#   - Lines starting with # are comments
#   - Inline # starts a comment (avoid # in paths)
#   - Relative paths are resolved relative to the manifest file's directory
#
# Examples:
#   ./scripts/setup-repos-from-manifest.sh ~/work/services.manifest
#   ./scripts/setup-repos-from-manifest.sh --continue --skip-module-init repos.manifest
#
# After bulk setup: cd into each repo and run `sdlc doctor` (and fill env/.env).
################################################################################

set -euo pipefail

CONTINUE=0
SKIP_MODULE_INIT=0
MANIFEST=""

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-repos-from-manifest.sh [OPTIONS] [MANIFEST]

  MANIFEST   Path to file with one repo root per line (default: ./repos.manifest)

Options:
  --continue          Continue after a failed repo (default: stop on first failure)
  --skip-module-init  Set SDL_SKIP_MODULE_INIT=1 for each setup (faster bulk runs)
  -h, --help          Show this help

See also: User_Manual/Getting_Started.md — "Many microservice repositories"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue)
      CONTINUE=1
      shift
      ;;
    --skip-module-init)
      SKIP_MODULE_INIT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$MANIFEST" ]]; then
        echo "Unexpected extra argument: $1" >&2
        exit 2
      fi
      MANIFEST="$1"
      shift
      ;;
  esac
done

if [[ -z "${MANIFEST:-}" ]]; then
  MANIFEST="repos.manifest"
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest not found: $MANIFEST" >&2
  echo "Create it with one repository root path per line, or pass the path to this script." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP_SH="${PLATFORM_ROOT}/setup.sh"

if [[ ! -f "$SETUP_SH" ]]; then
  echo "setup.sh not found at $SETUP_SH (run this script from a platform checkout)." >&2
  exit 1
fi

MANIFEST_DIR="$(cd "$(dirname "$MANIFEST")" && pwd)"
MANIFEST_ABS="${MANIFEST_DIR}/$(basename "$MANIFEST")"

if [[ "$SKIP_MODULE_INIT" -eq 1 ]]; then
  export SDL_SKIP_MODULE_INIT=1
else
  unset SDL_SKIP_MODULE_INIT 2>/dev/null || true
fi

echo "Platform:  $PLATFORM_ROOT"
echo "Manifest:  $MANIFEST_ABS"
echo "Continue:  $CONTINUE  Skip module init: $SKIP_MODULE_INIT"
echo ""

failures=0
line_no=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))
  # Strip inline comment and trim
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  repo_path="$line"
  if [[ "$repo_path" != /* ]]; then
    repo_path="${MANIFEST_DIR}/${repo_path}"
  fi

  if [[ ! -d "$repo_path" ]]; then
    echo "[line $line_no] SKIP — not a directory: $line" >&2
    failures=$((failures + 1))
    if [[ "$CONTINUE" -eq 0 ]]; then
      exit 1
    fi
    continue
  fi

  repo_abs="$(cd "$repo_path" && pwd)"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "[$line_no] $repo_abs"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if (cd "$PLATFORM_ROOT" && bash "$SETUP_SH" "$repo_abs"); then
    echo "[OK] $repo_abs"
  else
    echo "[FAIL] $repo_abs" >&2
    failures=$((failures + 1))
    if [[ "$CONTINUE" -eq 0 ]]; then
      exit 1
    fi
  fi
  echo ""
done < "$MANIFEST_ABS"

if [[ "$failures" -gt 0 ]]; then
  echo "Finished with $failures failure(s)." >&2
  exit 1
fi

echo "All listed repositories were processed successfully."
