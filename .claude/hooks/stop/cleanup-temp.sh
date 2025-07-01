#!/bin/bash
# Cleanup hook - removes temporary files and performs cleanup
# Runs when Claude session stops

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "cleanup-temp"

TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)

log_info "Starting cleanup process for project: $PROJECT_NAME"

# Cleanup temporary files
cleanup_temp_files() {
    local cleanup_count=0
    
    # Common temporary file patterns
    local temp_patterns=(
        "*.tmp"
        "*.temp"
        ".DS_Store"
        "Thumbs.db"
        "*.pyc"
        "__pycache__"
        "*.log.bak"
        "*.backup"
        ".vscode/settings.json.bak"
    )
    
    for pattern in "${temp_patterns[@]}"; do
        # Find and remove matching files (safely)
        while IFS= read -r -d '' file; do
            if [[ -f "$file" && -w "$file" ]]; then
                rm "$file" 2>/dev/null && ((cleanup_count++))
                log_info "Removed temporary file: $file"
            fi
        done < <(find . -name "$pattern" -type f -print0 2>/dev/null)
    done
    
    echo $cleanup_count
}

# Cleanup old backup files
cleanup_old_backups() {
    local backup_dir="${CLAUDE_LOGS_DIR}/backups"
    local cleanup_count=0
    
    if [[ -d "$backup_dir" ]]; then
        # Remove backups older than 7 days
        while IFS= read -r -d '' file; do
            rm "$file" 2>/dev/null && ((cleanup_count++))
            log_info "Removed old backup: $file"
        done < <(find "$backup_dir" -type f -mtime +7 -print0 2>/dev/null)
    fi
    
    echo $cleanup_count
}

# Cleanup old log files
cleanup_old_logs() {
    local logs_dir="${CLAUDE_LOGS_DIR}"
    local cleanup_count=0
    
    if [[ -d "$logs_dir" ]]; then
        # Compress logs older than 3 days
        while IFS= read -r -d '' file; do
            if [[ "$file" == *.log && ! "$file" == *.gz ]]; then
                gzip "$file" 2>/dev/null && ((cleanup_count++))
                log_info "Compressed old log: $file"
            fi
        done < <(find "$logs_dir" -name "*.log" -type f -mtime +3 -print0 2>/dev/null)
        
        # Remove compressed logs older than 30 days
        while IFS= read -r -d '' file; do
            rm "$file" 2>/dev/null && ((cleanup_count++))
            log_info "Removed old compressed log: $file"
        done < <(find "$logs_dir" -name "*.log.gz" -type f -mtime +30 -print0 2>/dev/null)
    fi
    
    echo $cleanup_count
}

# Cleanup Git-related temporary files
cleanup_git_temp() {
    local cleanup_count=0
    
    if [[ -d ".git" ]]; then
        # Clean Git garbage
        if command_exists "git"; then
            git gc --quiet 2>/dev/null && log_info "Git garbage collection completed"
        fi
        
        # Remove Git temporary files
        local git_temp_patterns=(
            ".git/*.tmp"
            ".git/MERGE_*"
            ".git/CHERRY_PICK_HEAD"
            ".git/REBASE_HEAD"
        )
        
        for pattern in "${git_temp_patterns[@]}"; do
            while IFS= read -r -d '' file; do
                if [[ -f "$file" ]]; then
                    rm "$file" 2>/dev/null && ((cleanup_count++))
                    log_info "Removed Git temporary file: $file"
                fi
            done < <(find . -path "$pattern" -type f -print0 2>/dev/null)
        done
    fi
    
    echo $cleanup_count
}

# Cleanup Node.js and npm cache (if applicable)
cleanup_node_cache() {
    local cleanup_count=0
    
    if [[ -f "package.json" ]] && command_exists "npm"; then
        # Clean npm cache
        npm cache clean --force 2>/dev/null && log_info "npm cache cleaned"
        
        # Remove node_modules/.cache if it exists
        if [[ -d "node_modules/.cache" ]]; then
            rm -rf "node_modules/.cache" 2>/dev/null && ((cleanup_count++))
            log_info "Removed node_modules/.cache"
        fi
    fi
    
    echo $cleanup_count
}

# Cleanup Python cache files
cleanup_python_cache() {
    local cleanup_count=0
    
    # Remove __pycache__ directories
    while IFS= read -r -d '' dir; do
        rm -rf "$dir" 2>/dev/null && ((cleanup_count++))
        log_info "Removed Python cache directory: $dir"
    done < <(find . -name "__pycache__" -type d -print0 2>/dev/null)
    
    # Remove .pyc files
    while IFS= read -r -d '' file; do
        rm "$file" 2>/dev/null && ((cleanup_count++))
        log_info "Removed Python cache file: $file"
    done < <(find . -name "*.pyc" -type f -print0 2>/dev/null)
    
    echo $cleanup_count
}

# Main cleanup execution
log_info "Starting comprehensive cleanup"

TEMP_CLEANED=$(cleanup_temp_files)
BACKUPS_CLEANED=$(cleanup_old_backups)
LOGS_CLEANED=$(cleanup_old_logs)
GIT_CLEANED=$(cleanup_git_temp)
NODE_CLEANED=$(cleanup_node_cache)
PYTHON_CLEANED=$(cleanup_python_cache)

TOTAL_CLEANED=$((TEMP_CLEANED + BACKUPS_CLEANED + LOGS_CLEANED + GIT_CLEANED + NODE_CLEANED + PYTHON_CLEANED))

# Create cleanup summary
CLEANUP_SUMMARY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_NAME",
  "temp_files_cleaned": $TEMP_CLEANED,
  "backups_cleaned": $BACKUPS_CLEANED,
  "logs_cleaned": $LOGS_CLEANED,
  "git_temp_cleaned": $GIT_CLEANED,
  "node_cache_cleaned": $NODE_CLEANED,
  "python_cache_cleaned": $PYTHON_CLEANED,
  "total_items_cleaned": $TOTAL_CLEANED
}
EOF
)

# Log cleanup summary
CLEANUP_LOG_FILE="${CLAUDE_LOGS_DIR}/cleanup_history.jsonl"
ensure_log_dir
echo "$CLEANUP_SUMMARY" >> "$CLEANUP_LOG_FILE"

# Update knowledge graph with cleanup activity
if neo4j_available; then
    NEO4J_SCRIPT="$(dirname "$0")/../utils/neo4j_mcp.py"
    if [[ -x "$NEO4J_SCRIPT" ]]; then
        ACTIVITY_DETAILS="Cleanup completed: $TOTAL_CLEANED items cleaned (Temp: $TEMP_CLEANED, Backups: $BACKUPS_CLEANED, Logs: $LOGS_CLEANED)"
        python3 "$NEO4J_SCRIPT" "log_activity" "cleanup" "$ACTIVITY_DETAILS" 2>/dev/null || log_warn "Neo4j cleanup logging failed"
    fi
fi

if [[ $TOTAL_CLEANED -gt 0 ]]; then
    log_success "Cleanup completed: $TOTAL_CLEANED items cleaned"
else
    log_info "Cleanup completed: No items needed cleaning"
fi

success_with_message "Cleanup process completed successfully"

finalize_hook "cleanup-temp" "completed"