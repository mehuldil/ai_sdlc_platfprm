#!/usr/bin/env bash
# Backward-compatible wrapper — delegates to CLI
#
# Usage:
#   ./run-as.sh <role> [project-path]    # Set role
#   ./run-as.sh <role> <stack> [path]    # Set role + stack
#
# Examples:
#   ./run-as.sh backend                  # Set role to backend
#   ./run-as.sh backend java         # Set role + stack
#   ./run-as.sh product                  # Set role to product (no stack needed)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI="$(dirname "$SCRIPT_DIR")/cli/sdlc.sh"

if [ ! -f "$CLI" ]; then
  echo "Error: sdlc.sh not found at $CLI"
  exit 1
fi

ROLE="${1:-}"
STACK="${2:-}"

if [ -z "$ROLE" ]; then
  echo "Usage: ./run-as.sh <role> [stack] [project-path]"
  echo ""
  echo "Roles: product, backend, frontend, ui, tpm, qa, performance, boss"
  echo "Stacks: java, kotlin-android, swift-ios, react-native, jmeter, figma-design"
  exit 1
fi

# Set role
bash "$CLI" use role "$ROLE"

# Set stack if provided and not a path
if [ -n "$STACK" ] && [ ! -d "$STACK" ]; then
  bash "$CLI" use stack "$STACK"
fi

echo ""
echo "Ready! Run 'sdlc run' to start the current stage."
