#!/bin/bash
# File access tracking hook - tracks file read patterns
# Runs after Read tool execution to understand file access patterns

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "track-access"

# Validate parameters
validate_params 2 $#

FILE_PATH="$1"
ACCESS_TYPE="$2"

TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)

# Create access log entry
ACCESS_LOG_FILE="${CLAUDE_LOGS_DIR}/file_access.log"
ensure_log_dir

LOG_ENTRY="$TIMESTAMP | $PROJECT_NAME | $ACCESS_TYPE | $FILE_PATH"
echo "$LOG_ENTRY" >> "$ACCESS_LOG_FILE"

# Track access patterns
track_access_patterns() {
    local file_path="$1"
    local access_type="$2"
    
    # Determine file category
    local file_category="unknown"
    local extension=$(get_file_extension "$file_path")
    
    case "$extension" in
        "py"|"js"|"ts"|"go"|"java"|"cpp"|"c"|"rs") file_category="source_code" ;;
        "json"|"yml"|"yaml"|"toml"|"ini") file_category="configuration" ;;
        "md"|"txt"|"rst") file_category="documentation" ;;
        "log") file_category="logs" ;;
        "test"|"spec") file_category="tests" ;;
        *) 
            if echo "$file_path" | grep -qE "(test|spec)"; then
                file_category="tests"
            elif echo "$file_path" | grep -qE "(config|settings)"; then
                file_category="configuration"
            elif echo "$file_path" | grep -qE "(doc|readme)"; then
                file_category="documentation"
            fi
            ;;
    esac
    
    # Create detailed access entry
    local detailed_entry=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_NAME",
  "file_path": "$file_path",
  "access_type": "$access_type",
  "file_category": "$file_category",
  "file_extension": "$extension"
}
EOF
    )
    
    # Log to JSON format
    local json_log_file="${CLAUDE_LOGS_DIR}/file_access.jsonl"
    echo "$detailed_entry" >> "$json_log_file"
    
    log_info "File access tracked: $file_path ($file_category)"
}

# Update knowledge graph with access patterns
update_knowledge_with_access() {
    local file_path="$1"
    local access_type="$2"
    
    if neo4j_available; then
        local neo4j_script="$(dirname "$0")/../utils/neo4j_mcp.py"
        if [[ -x "$neo4j_script" ]]; then
            local activity_details="File accessed: $file_path (Type: $access_type)"
            python3 "$neo4j_script" "log_activity" "$file_path" "$activity_details" 2>/dev/null || log_warn "Neo4j access logging failed"
        fi
    fi
}

# Detect frequently accessed files
detect_frequent_access() {
    local file_path="$1"
    local access_log_file="${CLAUDE_LOGS_DIR}/file_access.log"
    
    if [[ -f "$access_log_file" ]]; then
        # Count accesses to this file in the last day
        local today=$(date '+%Y-%m-%d')
        local access_count=$(grep "$today" "$access_log_file" | grep -c "$file_path" || echo 0)
        
        if [[ $access_count -gt 5 ]]; then
            log_info "Frequent access detected: $file_path accessed $access_count times today"
            
            # Could trigger additional actions for frequently accessed files
            # For example, suggest caching or optimization
        fi
    fi
}

# Main tracking logic
track_access_patterns "$FILE_PATH" "$ACCESS_TYPE"
update_knowledge_with_access "$FILE_PATH" "$ACCESS_TYPE"
detect_frequent_access "$FILE_PATH"

log_success "File access tracking completed for $FILE_PATH"
success_with_message "File access tracking completed"

finalize_hook "track-access" "completed"