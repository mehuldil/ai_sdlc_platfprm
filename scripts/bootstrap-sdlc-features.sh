#!/usr/bin/env bash
# bootstrap-sdlc-features.sh — Initialize semantic/module memory dirs and optional module scan
# Usage: bootstrap-sdlc-features.sh <project-root> <platform-root>
# Env: SDL_SKIP_MODULE_INIT=1  to skip module-init (large repos)
#      SDL_SKIP_DOC_LIBS=1     to skip Python doc-ingestion library install

set -euo pipefail

PROJ="${1:?project root}"
PLAT="${2:?platform root}"
PROJ="$(cd "$PROJ" && pwd)"
PLAT="$(cd "$PLAT" && pwd)"

mkdir -p "$PROJ/.sdlc/memory" "$PROJ/.sdlc/rpi" "$PROJ/.sdlc/module" 2>/dev/null || true
# NOTE: `.sdlc/module-kb/` deprecated — superseded by `.sdlc/module/` (contracts + knowledge).
# Any existing empty `.sdlc/module-kb/` is removed by `sdlc memory doctor`.
mkdir -p "$PROJ/.sdlc/memory/semantic" 2>/dev/null || true

# ── Python doc-ingestion libraries (best-effort) ──────────────────────────────
if [[ "${SDL_SKIP_DOC_LIBS:-}" != "1" ]]; then
  _pybin=""
  for _c in python3 python; do
    if command -v "$_c" &>/dev/null && "$_c" -V >/dev/null 2>&1; then
      _pybin="$_c"
      break
    fi
  done

  if [[ -n "$_pybin" ]]; then
    _DOC_LIBS="pypdf pdfplumber mammoth python-docx openpyxl python-pptx beautifulsoup4 html2text trafilatura"
    echo "[bootstrap-sdlc-features] installing Python doc-ingestion libs..."
    if "$_pybin" -m pip install --quiet --disable-pip-version-check $_DOC_LIBS 2>&1; then
      echo "[bootstrap-sdlc-features] doc-ingestion libs OK (sdlc doc convert ready)"
    else
      echo "[bootstrap-sdlc-features] WARN: some doc-ingestion libs failed — sdlc doc convert may have limited format support"
    fi
    unset _DOC_LIBS
  else
    echo "[bootstrap-sdlc-features] WARN: Python not found — skipping doc-ingestion libs (set SDL_SKIP_DOC_LIBS=1 to suppress)"
  fi
  unset _pybin _c
else
  echo "[bootstrap-sdlc-features] SDL_SKIP_DOC_LIBS=1 — skipping Python doc-ingestion libs"
fi

# Pointer file: optional path to active Master Story markdown (one line)
if [[ ! -f "$PROJ/.sdlc/memory/active-master-story.path" ]]; then
  printf '%s\n' "# Set to the repo-relative path of your Master Story .md (optional, for test-skip sync)" > "$PROJ/.sdlc/memory/active-master-story.path.example"
fi

# Semantic memory DB — initialize when running from platform (script lives under platform)
if command -v python3 &>/dev/null && [[ -f "$PLAT/scripts/semantic-memory.py" ]]; then
  (cd "$PLAT" && python3 scripts/semantic-memory.py status >/dev/null 2>&1) || true
fi

# Module system (contracts + knowledge) — full repo scan (once per repo)
if [[ "${SDL_SKIP_MODULE_INIT:-}" == "1" ]]; then
  echo "[bootstrap-sdlc-features] SDL_SKIP_MODULE_INIT=1 — skipping module-init"
elif [[ -f "$PROJ/.sdlc/module/meta.json" ]]; then
  echo "[bootstrap-sdlc-features] module system already present — skipping module-init"
elif [[ -d "$PROJ/.git" ]] && [[ -f "$PLAT/scripts/module-init.sh" ]]; then
  bash "$PLAT/scripts/module-init.sh" "$PROJ" 2>&1 | tail -n 15 || true
fi

echo "[bootstrap-sdlc-features] OK: $PROJ"
