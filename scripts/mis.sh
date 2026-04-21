#!/usr/bin/env bash
# Module Intelligence System (MIS) — Main Command Wrapper
# Orchestrates all MIS functionality
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PATH="${REPO_PATH:-.}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# ============================================================================
# HELP
# ============================================================================

show_help() {
  cat << 'EOF'
Module Intelligence System (MIS) — Command Reference

Usage: sdlc mis <command> [options]

Commands:

  init [repo-path]
    Initialize module contracts for a repository
    Generates: api-contract.yaml, data-contract.yaml, event-contract.yaml, etc.
    Usage: sdlc mis init .
    Usage: sdlc mis init /path/to/repo

  analyze-change [repo-path] [branch|commit]
    Analyze changes and detect breaking changes
    Compares against contracts
    Output: analysis report with risk score
    Usage: sdlc mis analyze-change . feature/new-api
    Usage: sdlc mis analyze-change . HEAD~1

  validate [repo-path]
    Pre-merge validation against contracts
    Checks: syntax, content, git state, test coverage, etc.
    Output: validation report
    Usage: sdlc mis validate .

  report [repo-path]
    Generate comprehensive impact report
    Shows: affected services, rollback plans, testing checklist
    Output: markdown report in impact-reports/
    Usage: sdlc mis report .

  show [repo-path] [type]
    Display contract information in readable format
    Types: api, data, events, dependencies, breaking, analysis, validation, summary
    Usage: sdlc mis show . api
    Usage: sdlc mis show . data
    Usage: sdlc mis show . summary

Examples:

  # Initialize contracts for current repo
  sdlc mis init

  # Analyze changes on current branch
  sdlc mis analyze-change .

  # Validate before merge
  sdlc mis validate

  # Generate impact report
  sdlc mis report

  # Show API contract
  sdlc mis show . api

  # Show everything
  sdlc mis show . summary

Files Generated:

  .sdlc/module-contracts/
    ├── api-contract.yaml              API endpoint definitions
    ├── data-contract.yaml             Database schema contract
    ├── event-contract.yaml            Kafka event schemas
    ├── dependencies.yaml              External dependencies
    ├── breaking-changes.md            Breaking change policy
    ├── SUMMARY.md                     Getting started guide
    ├── last-change-analysis.json      Last analysis results
    ├── validation-report.json         Last validation results
    └── impact-reports/
        └── YYYYMMDD-HHMMSS-impact-report.md

EOF
}

# ============================================================================
# COMMAND DISPATCHER
# ============================================================================

main() {
  local cmd="$1"
  shift || true

  case "$cmd" in
    init)
      "$SCRIPT_DIR/mis-init.sh" "$@"
      ;;
    analyze-change|analyze)
      "$SCRIPT_DIR/mis-analyze-change.sh" "$@"
      ;;
    validate)
      "$SCRIPT_DIR/mis-validate.sh" "$@"
      ;;
    report)
      "$SCRIPT_DIR/mis-report.sh" "$@"
      ;;
    show)
      "$SCRIPT_DIR/mis-show.sh" "$@"
      ;;
    help|-h|--help)
      show_help
      ;;
    *)
      if [[ -z "$cmd" ]]; then
        show_help
        exit 0
      else
        log_error "Unknown command: $cmd"
        echo ""
        show_help
        exit 1
      fi
      ;;
  esac
}

main "$@"
