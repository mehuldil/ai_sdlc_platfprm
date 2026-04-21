#!/usr/bin/env bash
# AI-SDLC IDE Plugin — One-command setup
# Usage: ./plugins/ide-plugin/setup.sh  (from repo root)
#   or:  ./setup.sh                      (from plugins/ide-plugin/)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Installing dependencies..."
npm install --production

echo "Running setup..."
node scripts/setup.js
