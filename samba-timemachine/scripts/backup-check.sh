#!/bin/bash

# --- Safety & Best Practices ---
set -euo pipefail
IFS=$'\n\t'

# --- Self-Location Logic ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Configuration ---
PARENT_DIR="$SCRIPT_DIR"

# ENVIRONMENT VARIABLE LOGIC:
# Default is now empty. If not set, we skip the curl command.
WEBHOOK_URL="${WEBHOOK_URL:-}"

DAYS=14
LOG_TAG="tm_monitor"

# --- Logging Logic ---

if [ -t 1 ]; then
    IS_INTERACTIVE=true
else
    IS_INTERACTIVE=false
fi

log_info() {
    local msg="$1"
    if [ "$IS_INTERACTIVE" = true ]; then
        echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $msg"
    else
        echo "$msg" | systemd-cat -p info -t "$LOG_TAG"
    fi
}

log_error() {
    local msg="$1"
    if [ "$IS_INTERACTIVE" = true ]; then
        echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $msg" >&2
    else
        echo "$msg" | systemd-cat -p err -t "$LOG_TAG"
    fi
}

# --- Functional Logic ---

trigger_webhook() {
    local clean_name="$1"
    
    # CHECK: If URL is empty, skip the logic
    if [ -z "$WEBHOOK_URL" ]; then
        log_info "Dry Run (No URL set): Stale backup detected for $clean_name"
        return
    fi
    
    if curl --fail --silent --show-error --max-time 10 -L \
         --data-urlencode "alert=stale_sparsebundle" \
         --data-urlencode "directory=$clean_name" \
         --data-urlencode "message=No files modified in the last $DAYS days" \
         "$WEBHOOK_URL" > /dev/null; then
        
        log_info "Webhook triggered successfully for $clean_name"
    else
        log_error "Failed to trigger webhook for $clean_name"
    fi
}

check_sparsebundle() {
    local sb_path="$1"
    
    if [ ! -d "$sb_path" ] || [ ! -r "$sb_path" ]; then
        log_error "Skipping unreadable item: $sb_path"
        return
    fi

    local clean_name
    clean_name=$(basename "$sb_path" .sparsebundle)

    local file_count
    file_count=$(find "$sb_path" -type f -mtime -"$DAYS" 2>/dev/null | wc -l)

    if [ "$file_count" -eq 0 ]; then
        log_info "ALERT: Stale backup found ($file_count recent files): $clean_name"
        trigger_webhook "$clean_name"
    else
        log_info "OK: Backup is active ($file_count recent files): $clean_name"
    fi
}

# --- Main Execution ---

if ! command -v curl &> /dev/null; then
    log_error "Required dependency 'curl' is not installed."
    exit 1
fi

log_info "Script located at: $SCRIPT_DIR"

if [ -n "$WEBHOOK_URL" ]; then
    log_info "Webhook enabled: $WEBHOOK_URL"
else
    log_info "Webhook disabled (WEBHOOK_URL not set)"
fi

log_info "Scanning $PARENT_DIR for .sparsebundle directories..."

found_count=0

while IFS= read -r -d '' sb_dir; do
    found_count=$((found_count + 1))
    check_sparsebundle "$sb_dir"
done < <(find "$PARENT_DIR" -maxdepth 1 -name "*.sparsebundle" -type d -print0)

if [ "$found_count" -eq 0 ]; then
    log_info "No .sparsebundle directories were found in $PARENT_DIR."
else
    log_info "Scan complete. Checked $found_count sparsebundles."
fi
