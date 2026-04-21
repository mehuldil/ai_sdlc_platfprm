#!/bin/bash

################################################################################
# Atomic File I/O Library
# Provides file-locking and atomic write primitives for multi-user safety.
#
# ARCHITECTURE DECISION:
#   In a multi-user, multi-role system where backend, frontend, QA, perf,
#   and TPM roles can execute stages concurrently, ALL shared state files
#   under .sdlc/ MUST use these primitives to prevent:
#   - Lost updates (two writers overwriting each other)
#   - Corrupted JSON (interleaved writes)
#   - Phantom reads (reading partial writes)
#   - Orphaned temp files (crash during write)
#
# USAGE:
#   source scripts/lib/atomic-io.sh
#   atomic_write ".sdlc/state.json" '{"key": "value"}'
#   atomic_append ".sdlc/metrics/gate-metrics.jsonl" '{"gate": "G1"}'
#   locked_read ".sdlc/state.json" result_var
#   atomic_json_update ".sdlc/state.json" '.metadata.sync_status = "synced"'
#
# CONCURRENCY MODEL:
#   - flock(1) advisory locks on .sdlc/.locks/{filename}.lock
#   - Shared locks (LOCK_SH) for reads
#   - Exclusive locks (LOCK_EX) for writes
#   - Lock timeout: 30 seconds (configurable via ATOMIC_IO_TIMEOUT)
#   - Stale lock detection: locks older than 5 minutes are force-released
#
# ATOMICITY GUARANTEE:
#   - Write to temp file (same filesystem)
#   - fsync temp file
#   - Rename temp → target (atomic on POSIX)
#   - Only then release lock
################################################################################

set -euo pipefail

# Configuration
ATOMIC_IO_TIMEOUT="${ATOMIC_IO_TIMEOUT:-30}"
ATOMIC_IO_LOCK_DIR="${ATOMIC_IO_LOCK_DIR:-.sdlc/.locks}"
ATOMIC_IO_STALE_SECONDS="${ATOMIC_IO_STALE_SECONDS:-300}"

# Ensure lock directory exists
mkdir -p "$ATOMIC_IO_LOCK_DIR"

# ============================================================================
# Internal: Get lock file path for a given file
# ============================================================================
_lock_path() {
    local file_path="$1"
    local safe_name
    safe_name=$(echo "$file_path" | tr '/' '_' | tr ' ' '_')
    echo "${ATOMIC_IO_LOCK_DIR}/${safe_name}.lock"
}

# ============================================================================
# Internal: Clean stale locks (older than ATOMIC_IO_STALE_SECONDS)
# ============================================================================
_clean_stale_locks() {
    find "$ATOMIC_IO_LOCK_DIR" -name "*.lock" -type f -mmin "+$((ATOMIC_IO_STALE_SECONDS / 60))" -delete 2>/dev/null || true
}

# ============================================================================
# atomic_write: Atomically write content to a file
#
# Uses: exclusive flock + temp file + rename pattern
# Args: $1 = file path, $2 = content string
# Returns: 0 on success, 1 on lock timeout, 2 on write failure
# ============================================================================
atomic_write() {
    local file_path="$1"
    local content="$2"
    local lock_file
    lock_file=$(_lock_path "$file_path")

    # Ensure parent directory exists
    mkdir -p "$(dirname "$file_path")"

    # Clean stale locks periodically
    _clean_stale_locks

    # Acquire exclusive lock with timeout
    (
        if ! flock -w "$ATOMIC_IO_TIMEOUT" 9; then
            echo "[atomic-io] ERROR: Lock timeout on $file_path after ${ATOMIC_IO_TIMEOUT}s" >&2
            return 1
        fi

        # Write to temp file on same filesystem (ensures atomic rename)
        local temp_file="${file_path}.tmp.$$"
        if ! echo "$content" > "$temp_file"; then
            rm -f "$temp_file"
            echo "[atomic-io] ERROR: Failed to write temp file for $file_path" >&2
            return 2
        fi

        # Sync to disk before rename
        sync "$temp_file" 2>/dev/null || true

        # Atomic rename (POSIX guarantee: same-filesystem rename is atomic)
        if ! mv "$temp_file" "$file_path"; then
            rm -f "$temp_file"
            echo "[atomic-io] ERROR: Failed to rename temp to $file_path" >&2
            return 2
        fi

    ) 9>"$lock_file"
}

# ============================================================================
# atomic_append: Atomically append a line to a file (for JSONL, logs)
#
# Uses: exclusive flock + single echo (append-mode is near-atomic on Linux
#       for writes < PIPE_BUF=4096 bytes, but flock guarantees it)
# Args: $1 = file path, $2 = line content
# Returns: 0 on success, 1 on lock timeout
# ============================================================================
atomic_append() {
    local file_path="$1"
    local content="$2"
    local lock_file
    lock_file=$(_lock_path "$file_path")

    mkdir -p "$(dirname "$file_path")"
    _clean_stale_locks

    (
        if ! flock -w "$ATOMIC_IO_TIMEOUT" 9; then
            echo "[atomic-io] ERROR: Lock timeout on append to $file_path" >&2
            return 1
        fi

        echo "$content" >> "$file_path"

    ) 9>"$lock_file"
}

# ============================================================================
# locked_read: Read file content under shared lock
#
# Uses: shared flock (multiple readers allowed, blocks writers)
# Args: $1 = file path
# Output: File content to stdout
# Returns: 0 on success, 1 on lock timeout, 2 if file not found
# ============================================================================
locked_read() {
    local file_path="$1"
    local lock_file
    lock_file=$(_lock_path "$file_path")

    if [ ! -f "$file_path" ]; then
        echo "[atomic-io] WARN: File not found: $file_path" >&2
        return 2
    fi

    _clean_stale_locks

    (
        if ! flock -s -w "$ATOMIC_IO_TIMEOUT" 9; then
            echo "[atomic-io] ERROR: Shared lock timeout on $file_path" >&2
            return 1
        fi

        cat "$file_path"

    ) 9>"$lock_file"
}

# ============================================================================
# atomic_json_update: Atomically update a JSON file using a jq filter
#
# Uses: exclusive lock + jq transform + atomic rename
# Args: $1 = file path, $2 = jq filter expression
# Returns: 0 on success, 1 on lock timeout, 2 on jq failure
#
# Example: atomic_json_update ".sdlc/state.json" '.metadata.sync_status = "synced"'
# ============================================================================
atomic_json_update() {
    local file_path="$1"
    local jq_filter="$2"
    local lock_file
    lock_file=$(_lock_path "$file_path")

    if [ ! -f "$file_path" ]; then
        echo "[atomic-io] ERROR: Cannot update non-existent file: $file_path" >&2
        return 2
    fi

    _clean_stale_locks

    (
        if ! flock -w "$ATOMIC_IO_TIMEOUT" 9; then
            echo "[atomic-io] ERROR: Lock timeout on JSON update to $file_path" >&2
            return 1
        fi

        local temp_file="${file_path}.tmp.$$"

        if ! jq "$jq_filter" "$file_path" > "$temp_file" 2>/dev/null; then
            rm -f "$temp_file"
            echo "[atomic-io] ERROR: jq filter failed on $file_path: $jq_filter" >&2
            return 2
        fi

        # Validate output is valid JSON
        if ! jq empty "$temp_file" 2>/dev/null; then
            rm -f "$temp_file"
            echo "[atomic-io] ERROR: jq produced invalid JSON for $file_path" >&2
            return 2
        fi

        sync "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$file_path"

    ) 9>"$lock_file"
}

# ============================================================================
# atomic_json_array_push: Atomically append an element to a JSON array
#
# Uses: exclusive lock + jq + atomic rename
# Args: $1 = file path, $2 = jq path to array, $3 = JSON element to push
# Returns: 0 on success
#
# Example: atomic_json_array_push ".sdlc/mcp-queue/ado-pending.json" \
#          ".pending_operations" '{"id":"123","op":"create"}'
# ============================================================================
atomic_json_array_push() {
    local file_path="$1"
    local array_path="$2"
    local element="$3"
    local lock_file
    lock_file=$(_lock_path "$file_path")

    mkdir -p "$(dirname "$file_path")"

    # Initialize file if doesn't exist
    if [ ! -f "$file_path" ]; then
        echo "{\"pending_operations\":[]}" > "$file_path"
    fi

    _clean_stale_locks

    (
        if ! flock -w "$ATOMIC_IO_TIMEOUT" 9; then
            echo "[atomic-io] ERROR: Lock timeout on array push to $file_path" >&2
            return 1
        fi

        local temp_file="${file_path}.tmp.$$"

        if ! jq "${array_path} += [${element}]" "$file_path" > "$temp_file" 2>/dev/null; then
            rm -f "$temp_file"
            echo "[atomic-io] ERROR: Array push failed on $file_path" >&2
            return 2
        fi

        jq empty "$temp_file" 2>/dev/null || { rm -f "$temp_file"; return 2; }
        sync "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$file_path"

    ) 9>"$lock_file"
}

# ============================================================================
# cleanup_temp_files: Remove orphaned temp files from crashes
#
# Call this during startup or periodically
# ============================================================================
cleanup_temp_files() {
    local search_dir="${1:-.sdlc}"
    find "$search_dir" -name "*.tmp.*" -type f -mmin "+10" -delete 2>/dev/null || true
    echo "[atomic-io] Cleaned orphaned temp files in $search_dir"
}

# ============================================================================
# rotate_file: Rotate a file when it exceeds a size limit
#
# Args: $1 = file path, $2 = max size in KB (default: 1024 = 1MB)
# Creates: file.1, file.2, etc. (keeps last 5 rotations)
# ============================================================================
rotate_file() {
    local file_path="$1"
    local max_kb="${2:-1024}"
    local lock_file
    lock_file=$(_lock_path "$file_path")

    if [ ! -f "$file_path" ]; then
        return 0
    fi

    local file_kb
    file_kb=$(du -k "$file_path" | cut -f1)

    if [ "$file_kb" -lt "$max_kb" ]; then
        return 0
    fi

    (
        if ! flock -w "$ATOMIC_IO_TIMEOUT" 9; then
            return 1
        fi

        # Rotate: file.4 → file.5, file.3 → file.4, etc.
        for i in 4 3 2 1; do
            if [ -f "${file_path}.$i" ]; then
                mv "${file_path}.$i" "${file_path}.$((i+1))"
            fi
        done

        mv "$file_path" "${file_path}.1"
        touch "$file_path"

        echo "[atomic-io] Rotated $file_path (was ${file_kb}KB, max ${max_kb}KB)"

    ) 9>"$lock_file"
}

echo "[atomic-io] Library loaded (timeout=${ATOMIC_IO_TIMEOUT}s, lock_dir=${ATOMIC_IO_LOCK_DIR})"
