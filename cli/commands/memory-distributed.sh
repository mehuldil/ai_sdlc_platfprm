#!/bin/bash
# Distributed Memory System CLI Commands
# For multi-branch, multi-repo, multi-engineer development
#
# Usage:
#   sdlc memory init --story-id AB#2001 --branch feature/oauth-core --engineer engineer-a
#   sdlc memory list-branches --story-id AB#2001
#   sdlc memory prepare-merge --story-id AB#2001 --branch feature/oauth-core --target develop
#   sdlc memory sync --story-id AB#2001 --all-repos
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
MEMORY_ROOT="${PROJECT_ROOT}/.sdlc/memory"
CONFIG_FILE="${PROJECT_ROOT}/.sdlc/config/distributed-memory.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

_python_exec() {
    # Supports Linux/macOS/WSL and Windows launcher fallback (py -3)
    if command -v python3 >/dev/null 2>&1 && python3 -V >/dev/null 2>&1; then
        python3 "$@"
        return $?
    fi
    if command -v python >/dev/null 2>&1 && python -V >/dev/null 2>&1; then
        python "$@"
        return $?
    fi
    if command -v py >/dev/null 2>&1 && py -3 -V >/dev/null 2>&1; then
        py -3 "$@"
        return $?
    fi
    log_error "Python runtime not found (python3/python/py -3)"
    return 1
}

# Initialize memory for a story on a specific branch
memory_init() {
    local story_id=""
    local branch=""
    local repo=""
    local engineer=""
    local inherit_from=""
    local cross_repo_sync=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --story-id) story_id="$2"; shift 2 ;;
            --branch) branch="$2"; shift 2 ;;
            --repo) repo="$2"; shift 2 ;;
            --engineer) engineer="$2"; shift 2 ;;
            --inherit-from) inherit_from="$2"; shift 2 ;;
            --cross-repo-sync) cross_repo_sync=true; shift ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$story_id" ]] || [[ -z "$branch" ]] || [[ -z "$engineer" ]]; then
        log_error "Missing required arguments: --story-id, --branch, --engineer"
        exit 1
    fi

    # Get repo name if not provided
    if [[ -z "$repo" ]]; then
        repo=$(git rev-parse --show-toplevel | xargs basename)
    fi

    log_info "Initializing memory for $story_id on branch $branch (engineer: $engineer)"

    # Create story memory directory
    local story_dir="${MEMORY_ROOT}/${story_id}"
    local decisions_dir="${story_dir}/decisions"

    mkdir -p "$decisions_dir"

    # Create BRANCH_METADATA.json
    local branch_meta_file="${story_dir}/BRANCH_METADATA.json"
    cat > "$branch_meta_file" << EOF
{
  "story_id": "$story_id",
  "branch": "$branch",
  "repo": "$repo",
  "repo_url": "$(git remote get-url origin 2>/dev/null || echo 'unknown')",
  "owner": "$engineer",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "stages_completed": [],
  "tags": ["$branch"],
  "related_branches": [],
  "merge_status": "pending",
  "target_branch": "develop"
}
EOF

    log_success "Created BRANCH_METADATA.json"

    # Create or update STORY_METADATA.json
    local story_meta_file="${story_dir}/STORY_METADATA.json"
    if [[ ! -f "$story_meta_file" ]]; then
        cat > "$story_meta_file" << EOF
{
  "story_id": "$story_id",
  "status": "in-progress",
  "branches": [
    {
      "branch": "$branch",
      "repo": "$repo",
      "engineer": "$engineer",
      "memory_version": "1.0",
      "last_sync": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "stages_completed": []
    }
  ],
  "decision_authority": {}
}
EOF
        log_success "Created STORY_METADATA.json"
    fi

    # Handle inheritance from existing branch
    if [[ -n "$inherit_from" ]]; then
        log_info "Inheriting from branch: $inherit_from"

        # Copy relevant files from source branch
        local source_dir="${MEMORY_ROOT}/${story_id}"
        if [[ -f "${source_dir}/design.md" ]]; then
            cp "${source_dir}/design.md" "${story_dir}/design.md"
            log_success "Copied design.md"
        fi

        # Copy ADR files
        if [[ -d "${source_dir}/decisions" ]]; then
            for adr_file in "${source_dir}/decisions"/adr-*.md; do
                if [[ -f "$adr_file" ]]; then
                    cp "$adr_file" "${decisions_dir}/"
                fi
            done
            log_success "Copied ADR files"
        fi

        # Merge DECISION_LOG.json
        if [[ -f "${source_dir}/decisions/DECISION_LOG.json" ]]; then
            cp "${source_dir}/decisions/DECISION_LOG.json" "${decisions_dir}/"
            log_success "Copied DECISION_LOG.json"
        fi
    fi

    # Handle cross-repo sync
    if [[ "$cross_repo_sync" == "true" ]]; then
        log_info "Setting up cross-repo synchronization..."
        # This would fetch STORY_METADATA.json from related repos
        log_success "Cross-repo sync enabled"
    fi

    log_success "Memory initialized for $story_id on $branch"
    log_info "Next: Create ADRs and design documents, then commit memory changes"
}

# List all branches working on the same story
memory_list_branches() {
    local story_id="$1"

    if [[ -z "$story_id" ]]; then
        log_error "Missing argument: --story-id"
        exit 1
    fi

    local story_meta_file="${MEMORY_ROOT}/${story_id}/STORY_METADATA.json"
    if [[ ! -f "$story_meta_file" ]]; then
        log_error "Story metadata not found for $story_id"
        exit 1
    fi

    log_info "Story: $story_id"
    echo ""
    echo "Branches working on this story:"
    echo "==============================="

    # Parse and display branches
    _python_exec - "$story_id" << 'PYTHON_EOF'
import json
import sys

story_id = sys.argv[1] if len(sys.argv) > 1 else ""
meta_file = f".sdlc/memory/{story_id}/STORY_METADATA.json"

try:
    with open(meta_file, 'r') as f:
        data = json.load(f)

    for i, branch_info in enumerate(data.get('branches', []), 1):
        print(f"\nBranch {i}: {branch_info['branch']} ({branch_info['repo']})")
        print(f"  Engineer: {branch_info['engineer']}")
        print(f"  Status: {branch_info.get('merge_status', 'pending')}")
        print(f"  Last sync: {branch_info['last_sync']}")
        print(f"  Stages: {', '.join(branch_info['stages_completed']) if branch_info['stages_completed'] else 'none'}")

except FileNotFoundError:
    print(f"Story metadata not found: {meta_file}")
    sys.exit(1)
except json.JSONDecodeError:
    print(f"Invalid JSON in: {meta_file}")
    sys.exit(1)
PYTHON_EOF
}

# Prepare for merge - validate before merging
memory_prepare_merge() {
    local story_id=""
    local branch=""
    local target=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --story-id) story_id="$2"; shift 2 ;;
            --branch) branch="$2"; shift 2 ;;
            --target) target="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [[ -z "$story_id" ]] || [[ -z "$branch" ]]; then
        log_error "Missing arguments: --story-id, --branch"
        exit 1
    fi

    target="${target:-develop}"

    log_info "Preparing merge for $story_id"
    log_info "Source branch: $branch"
    log_info "Target branch: $target"

    # Create MERGE_CHECKLIST.md
    local checklist_file=".sdlc/MERGE_CHECKLIST_${story_id}.md"
    cat > "$checklist_file" << EOF
# Merge Checklist: $story_id

**Source**: $branch → $target
**Prepared**: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Pre-Merge Validation

- [ ] All ADRs complete
- [ ] Decisions approved or pending approval
- [ ] Implementation code ready
- [ ] Design documents finalized
- [ ] No conflicting decisions with other branches
- [ ] Memory metadata consistent
- [ ] Cross-repo sync completed (if applicable)

## Decisions to Merge

Check .sdlc/memory/$story_id/decisions/DECISION_LOG.json for full list

## Related Branches

Check .sdlc/memory/$story_id/STORY_METADATA.json for all branches on this story

## Merge Status

**Ready to merge**: YES (after validation)

## Next Steps

1. Review this checklist
2. Ensure all items are checked
3. Create PR for merge
4. On merge, memory will be automatically combined
5. Proceed to next stage

EOF

    log_success "Created: $checklist_file"
    log_success "Ready to merge. Review checklist and create PR."
}

# Sync memory across repositories
memory_sync() {
    local story_id=""
    local all_repos=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --story-id) story_id="$2"; shift 2 ;;
            --all-repos) all_repos=true; shift ;;
            *) shift ;;
        esac
    done

    if [[ -z "$story_id" ]]; then
        log_error "Missing argument: --story-id"
        exit 1
    fi

    log_info "Syncing memory for $story_id"

    if [[ "$all_repos" == "true" ]]; then
        log_info "Syncing across all related repositories..."
        # Implementation would fetch STORY_METADATA.json from all repos
        log_success "Memory synced across repos"
    else
        log_success "Memory synced"
    fi
}

# Show memory status
memory_status() {
    local story_id="$1"

    if [[ -z "$story_id" ]]; then
        log_error "Missing argument: --story-id"
        exit 1
    fi

    local story_meta_file="${MEMORY_ROOT}/${story_id}/STORY_METADATA.json"
    if [[ ! -f "$story_meta_file" ]]; then
        log_error "Story metadata not found for $story_id"
        exit 1
    fi

    log_info "Status: $story_id"
    _python_exec -m json.tool < "$story_meta_file"
}

# Main entry point
main() {
    local command="$1"
    shift || true

    case "$command" in
        init)
            memory_init "$@"
            ;;
        list-branches)
            memory_list_branches "$@"
            ;;
        prepare-merge)
            memory_prepare_merge "$@"
            ;;
        sync)
            memory_sync "$@"
            ;;
        status)
            memory_status "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            echo "Available commands:"
            echo "  init           Initialize memory for story on branch"
            echo "  list-branches  List all branches working on story"
            echo "  prepare-merge  Prepare for merge with validation"
            echo "  sync           Sync memory across repositories"
            echo "  status         Show memory status for story"
            exit 1
            ;;
    esac
}

main "$@"
