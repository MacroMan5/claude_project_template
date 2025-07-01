#!/bin/bash
# Session knowledge update hook - persists session knowledge to Neo4j
# Runs when Claude session stops to ensure knowledge persistence

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "update-session-knowledge"

TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)
SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%s)}"

# Check if Neo4j is available
if ! neo4j_available; then
    log_warn "Neo4j not available, skipping session knowledge update"
    success_with_message "Session knowledge update skipped - Neo4j not available"
    finalize_hook "update-session-knowledge" "skipped"
    exit 0
fi

log_info "Updating session knowledge for project: $PROJECT_NAME"

# Create session entity with comprehensive metadata
create_session_entity() {
    local neo4j_script="$(dirname "$0")/../utils/neo4j_mcp.py"
    
    if [[ ! -x "$neo4j_script" ]]; then
        log_error "Neo4j MCP script not found or not executable"
        return 1
    fi
    
    # Gather session metadata
    local session_start_time=$(get_session_start_time)
    local session_end_time="$TIMESTAMP"
    local total_commands=$(get_command_count)
    local files_modified=$(get_modified_files_count)
    local errors_encountered=$(get_error_count)
    
    # Create session entity with rich metadata
    local session_details="Session: $SESSION_ID | Project: $PROJECT_NAME | Duration: $session_start_time to $session_end_time | Commands: $total_commands | Files: $files_modified | Errors: $errors_encountered"
    
    python3 "$neo4j_script" "log_activity" "session_complete" "$session_details" 2>/dev/null || log_warn "Session entity creation failed"
    
    log_info "Session entity created with metadata"
}

# Get session start time
get_session_start_time() {
    local hooks_log="${CLAUDE_LOGS_DIR}/hooks.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$hooks_log" ]]; then
        grep "$today" "$hooks_log" | head -1 | awk '{print $1" "$2}' || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get command count for this session
get_command_count() {
    local command_log="${CLAUDE_LOGS_DIR}/command_history.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$command_log" ]]; then
        grep "$today" "$command_log" | wc -l || echo 0
    else
        echo 0
    fi
}

# Get modified files count
get_modified_files_count() {
    local access_log="${CLAUDE_LOGS_DIR}/file_access.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$access_log" ]]; then
        grep "$today" "$access_log" | grep -c "write" || echo 0
    else
        echo 0
    fi
}

# Get error count
get_error_count() {
    local error_log="${CLAUDE_LOGS_DIR}/errors.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$error_log" ]]; then
        grep "$today" "$error_log" | wc -l || echo 0
    else
        echo 0
    fi
}

# Create relationships between session and files
create_session_file_relationships() {
    local neo4j_script="$(dirname "$0")/../utils/neo4j_mcp.py"
    local access_log="${CLAUDE_LOGS_DIR}/file_access.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$access_log" && -x "$neo4j_script" ]]; then
        # Get unique files accessed in this session
        local accessed_files=$(grep "$today" "$access_log" | awk -F' | ' '{print $4}' | sort -u)
        
        while IFS= read -r file_path; do
            if [[ -n "$file_path" && "$file_path" != "unknown" ]]; then
                local relationship_details="Session accessed file: $file_path during session $SESSION_ID"
                python3 "$neo4j_script" "log_activity" "$file_path" "$relationship_details" 2>/dev/null || log_warn "File relationship creation failed for $file_path"
            fi
        done <<< "$accessed_files"
        
        log_info "Session-file relationships created"
    fi
}

# Summarize development patterns learned
summarize_development_patterns() {
    local command_json_log="${CLAUDE_LOGS_DIR}/commands.jsonl"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$command_json_log" ]]; then
        # Analyze command patterns
        local most_used_category=$(grep "$today" "$command_json_log" | jq -r '.category' 2>/dev/null | sort | uniq -c | sort -nr | head -1 | awk '{print $2}' || echo "unknown")
        local command_diversity=$(grep "$today" "$command_json_log" | jq -r '.category' 2>/dev/null | sort -u | wc -l || echo 0)
        
        # Analyze file operation patterns
        local file_types_accessed=$(grep "$today" "${CLAUDE_LOGS_DIR}/file_access.log" 2>/dev/null | awk -F' | ' '{print $4}' | grep -o '\.[^.]*$' | sort | uniq -c | sort -nr | head -3 | tr '\n' ' ' || echo "none")
        
        local pattern_summary="Development patterns: Primary category=$most_used_category, Command diversity=$command_diversity, File types=$file_types_accessed"
        
        local neo4j_script="$(dirname "$0")/../utils/neo4j_mcp.py"
        if [[ -x "$neo4j_script" ]]; then
            python3 "$neo4j_script" "log_activity" "development_patterns" "$pattern_summary" 2>/dev/null || log_warn "Pattern summary logging failed"
        fi
        
        log_info "Development patterns summarized: $most_used_category (diversity: $command_diversity)"
    fi
}

# Create knowledge graph insights
create_insights() {
    local insights_file="${CLAUDE_LOGS_DIR}/session_insights.txt"
    local today=$(date '+%Y-%m-%d')
    
    # Generate insights based on session data
    local insights="Session Insights for $today:\n"
    
    # Command efficiency insights
    local total_commands=$(get_command_count)
    local successful_commands=$(grep "$today" "${CLAUDE_LOGS_DIR}/command_history.log" 2>/dev/null | grep -c "SUCCESS" || echo 0)
    
    if [[ $total_commands -gt 0 ]]; then
        local success_rate=$(( (successful_commands * 100) / total_commands ))
        insights+="\n- Command success rate: $success_rate% ($successful_commands/$total_commands)"
        
        if [[ $success_rate -gt 90 ]]; then
            insights+="\n- High efficiency session - commands executed smoothly"
        elif [[ $success_rate -lt 70 ]]; then
            insights+="\n- Low efficiency session - consider reviewing command patterns"
        fi
    fi
    
    # File operation insights
    local write_ops=$(get_modified_files_count)
    local read_ops=$(grep "$today" "${CLAUDE_LOGS_DIR}/file_access.log" 2>/dev/null | grep -c "read" || echo 0)
    
    if [[ $write_ops -gt 0 && $read_ops -gt 0 ]]; then
        local read_write_ratio=$(( read_ops / (write_ops + 1) ))
        insights+="\n- Read/Write ratio: ${read_write_ratio}:1"
        
        if [[ $read_write_ratio -gt 3 ]]; then
            insights+="\n- Research-heavy session - lots of exploration before changes"
        elif [[ $read_write_ratio -lt 2 ]]; then
            insights+="\n- Action-heavy session - rapid development and changes"
        fi
    fi
    
    # Error insights
    local error_count=$(get_error_count)
    if [[ $error_count -eq 0 ]]; then
        insights+="\n- Error-free session - excellent execution"
    elif [[ $error_count -lt 3 ]]; then
        insights+="\n- Low error session - good troubleshooting"
    else
        insights+="\n- High error session - consider reviewing approach"
    fi
    
    # Save insights
    echo -e "$insights" > "$insights_file"
    
    # Add to knowledge graph
    local neo4j_script="$(dirname "$0")/../utils/neo4j_mcp.py"
    if [[ -x "$neo4j_script" ]]; then
        python3 "$neo4j_script" "log_activity" "session_insights" "$insights" 2>/dev/null || log_warn "Insights logging failed"
    fi
    
    log_info "Session insights generated and stored"
}

# Update project knowledge with session contributions
update_project_knowledge() {
    local neo4j_script="$(dirname "$0")/../utils/neo4j_mcp.py"
    
    if [[ -x "$neo4j_script" ]]; then
        # Update project entity with session contribution
        local project_update="Session $SESSION_ID contributed: $(get_command_count) commands, $(get_modified_files_count) file modifications, knowledge updates on $TIMESTAMP"
        python3 "$neo4j_script" "log_activity" "$PROJECT_NAME" "$project_update" 2>/dev/null || log_warn "Project knowledge update failed"
        
        log_info "Project knowledge updated with session contributions"
    fi
}

# Main knowledge update execution
log_info "Starting comprehensive session knowledge update"

create_session_entity
create_session_file_relationships
summarize_development_patterns
create_insights
update_project_knowledge

# Create final session knowledge summary
SESSION_KNOWLEDGE_SUMMARY=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "project": "$PROJECT_NAME",
  "timestamp": "$TIMESTAMP",
  "knowledge_updates": {
    "session_entity_created": true,
    "file_relationships_mapped": true,
    "development_patterns_analyzed": true,
    "insights_generated": true,
    "project_knowledge_updated": true
  },
  "statistics": {
    "commands_executed": $(get_command_count),
    "files_modified": $(get_modified_files_count),
    "errors_encountered": $(get_error_count)
  }
}
EOF
)

# Save knowledge update summary
KNOWLEDGE_SUMMARY_FILE="${CLAUDE_LOGS_DIR}/knowledge_updates.jsonl"
echo "$SESSION_KNOWLEDGE_SUMMARY" >> "$KNOWLEDGE_SUMMARY_FILE"

log_success "Session knowledge update completed successfully"
log_info "Knowledge summary: Session entity created, relationships mapped, patterns analyzed"

success_with_message "Session knowledge persistence completed"

finalize_hook "update-session-knowledge" "completed"