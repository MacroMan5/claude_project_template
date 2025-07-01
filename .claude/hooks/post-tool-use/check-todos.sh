#!/bin/bash
# TODO scanner and GitHub issue creator hook
# Runs after Edit/Write operations to scan for TODOs and create GitHub issues

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "check-todos"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_info "File $FILE_PATH does not exist, skipping TODO check"
    success_with_message "No TODO check needed - file does not exist"
    finalize_hook "check-todos" "skipped"
    exit 0
fi

# Skip binary files and certain extensions
skip_patterns=(
    "\.jpg$"
    "\.png$"
    "\.gif$"
    "\.pdf$"
    "\.exe$"
    "\.dll$"
    "\.so$"
    "\.zip$"
    "\.tar"
    "\.gz$"
)

for pattern in "${skip_patterns[@]}"; do
    if echo "$FILE_PATH" | grep -iE "$pattern" >/dev/null 2>&1; then
        log_info "Skipping TODO check for binary file: $FILE_PATH"
        success_with_message "TODO check skipped - binary file"
        finalize_hook "check-todos" "skipped"
        exit 0
    fi
done

log_info "Scanning $FILE_PATH for TODO comments"

# Count TODOs found
TODO_COUNT=0
FIXME_COUNT=0
HACK_COUNT=0

# Scan for TODO patterns
scan_todos() {
    local file_path="$1"
    
    # TODO patterns
    TODO_COUNT=$(grep -icE "#\s*TODO|//\s*TODO|/\*\s*TODO" "$file_path" 2>/dev/null || echo 0)
    FIXME_COUNT=$(grep -icE "#\s*FIXME|//\s*FIXME|/\*\s*FIXME" "$file_path" 2>/dev/null || echo 0)
    HACK_COUNT=$(grep -icE "#\s*HACK|//\s*HACK|/\*\s*HACK" "$file_path" 2>/dev/null || echo 0)
    
    local total=$((TODO_COUNT + FIXME_COUNT + HACK_COUNT))
    
    if [[ $total -gt 0 ]]; then
        log_info "Found $total TODO-style comments in $file_path (TODO: $TODO_COUNT, FIXME: $FIXME_COUNT, HACK: $HACK_COUNT)"
        return 0
    else
        log_info "No TODO comments found in $file_path"
        return 1
    fi
}

# GitHub integration for creating issues
create_github_issues() {
    local file_path="$1"
    
    if ! github_token_available; then
        log_warn "GitHub token not available, skipping issue creation"
        return 1
    fi
    
    local github_script="$(dirname "$0")/../utils/github_mcp.py"
    
    if [[ -x "$github_script" ]]; then
        log_info "Creating GitHub issues from TODOs in $file_path"
        python3 "$github_script" "create_todos_issues" "$file_path" 2>/dev/null || log_warn "GitHub issue creation failed"
        return $?
    else
        log_error "GitHub MCP integration script not found or not executable"
        return 1
    fi
}

# Main TODO scanning
if scan_todos "$FILE_PATH"; then
    # TODOs found, optionally create GitHub issues
    
    # Check if this is a significant number of new TODOs (more than 2)
    TOTAL_TODOS=$((TODO_COUNT + FIXME_COUNT + HACK_COUNT))
    
    if [[ $TOTAL_TODOS -gt 2 ]]; then
        log_info "Significant number of TODOs found ($TOTAL_TODOS), attempting to create GitHub issues"
        if create_github_issues "$FILE_PATH"; then
            log_success "GitHub issues created for TODOs in $FILE_PATH"
        else
            log_warn "Failed to create GitHub issues for TODOs"
        fi
    else
        log_info "TODOs found but not creating GitHub issues (count: $TOTAL_TODOS <= 2)"
    fi
    
    # Log TODO summary
    if [[ $TODO_COUNT -gt 0 ]]; then
        log_info "TODO summary for $FILE_PATH: $TODO_COUNT TODOs, $FIXME_COUNT FIXMEs, $HACK_COUNT HACKs"
    fi
    
    success_with_message "TODO scan completed - found $TOTAL_TODOS items"
else
    success_with_message "TODO scan completed - no items found"
fi

finalize_hook "check-todos" "completed"