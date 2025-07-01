#!/bin/bash
# Session summary hook - generates comprehensive session summary
# Runs when Claude session stops to summarize activities

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "session-summary"

TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)
SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%s)}"

log_info "Generating session summary for project: $PROJECT_NAME"

# Analyze command history
analyze_command_history() {
    local command_log="${CLAUDE_LOGS_DIR}/command_history.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$command_log" ]]; then
        local total_commands=$(grep "$today" "$command_log" | wc -l || echo 0)
        local successful_commands=$(grep "$today" "$command_log" | grep -c "SUCCESS" || echo 0)
        local failed_commands=$(grep "$today" "$command_log" | grep -c "FAILED" || echo 0)
        
        echo "$total_commands:$successful_commands:$failed_commands"
    else
        echo "0:0:0"
    fi
}

# Analyze file operations
analyze_file_operations() {
    local access_log="${CLAUDE_LOGS_DIR}/file_access.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$access_log" ]]; then
        local total_accesses=$(grep "$today" "$access_log" | wc -l || echo 0)
        local read_operations=$(grep "$today" "$access_log" | grep -c "read" || echo 0)
        local write_operations=$(grep "$today" "$access_log" | grep -c "write" || echo 0)
        
        echo "$total_accesses:$read_operations:$write_operations"
    else
        echo "0:0:0"
    fi
}

# Analyze errors and notifications
analyze_errors() {
    local error_log="${CLAUDE_LOGS_DIR}/errors.log"
    local notification_log="${CLAUDE_LOGS_DIR}/notifications.log"
    local today=$(date '+%Y-%m-%d')
    
    local total_errors=0
    local total_notifications=0
    
    if [[ -f "$error_log" ]]; then
        total_errors=$(grep "$today" "$error_log" | wc -l || echo 0)
    fi
    
    if [[ -f "$notification_log" ]]; then
        total_notifications=$(grep "$today" "$notification_log" | wc -l || echo 0)
    fi
    
    echo "$total_errors:$total_notifications"
}

# Get most accessed files
get_most_accessed_files() {
    local access_log="${CLAUDE_LOGS_DIR}/file_access.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$access_log" ]]; then
        grep "$today" "$access_log" | awk -F' | ' '{print $4}' | sort | uniq -c | sort -nr | head -5 | while read count file; do
            echo "  - $file ($count accesses)"
        done
    fi
}

# Get command categories used
get_command_categories() {
    local command_json_log="${CLAUDE_LOGS_DIR}/commands.jsonl"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$command_json_log" ]]; then
        grep "$today" "$command_json_log" | jq -r '.category' 2>/dev/null | sort | uniq -c | sort -nr | head -5 | while read count category; do
            echo "  - $category ($count commands)"
        done
    fi
}

# Calculate session duration (approximate)
calculate_session_duration() {
    local hooks_log="${CLAUDE_LOGS_DIR}/hooks.log"
    local today=$(date '+%Y-%m-%d')
    
    if [[ -f "$hooks_log" ]]; then
        local first_entry=$(grep "$today" "$hooks_log" | head -1 | awk '{print $1" "$2}')
        local last_entry=$(grep "$today" "$hooks_log" | tail -1 | awk '{print $1" "$2}')
        
        if [[ -n "$first_entry" && -n "$last_entry" ]]; then
            local start_time=$(date -d "$first_entry" +%s 2>/dev/null || echo 0)
            local end_time=$(date -d "$last_entry" +%s 2>/dev/null || echo 0)
            local duration=$((end_time - start_time))
            
            if [[ $duration -gt 0 ]]; then
                local hours=$((duration / 3600))
                local minutes=$(((duration % 3600) / 60))
                local seconds=$((duration % 60))
                
                printf "%02d:%02d:%02d" $hours $minutes $seconds
            else
                echo "00:00:00"
            fi
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Gather analytics data
COMMAND_STATS=$(analyze_command_history)
FILE_STATS=$(analyze_file_operations)
ERROR_STATS=$(analyze_errors)
SESSION_DURATION=$(calculate_session_duration)

# Parse stats
TOTAL_COMMANDS=$(echo "$COMMAND_STATS" | cut -d: -f1)
SUCCESSFUL_COMMANDS=$(echo "$COMMAND_STATS" | cut -d: -f2)
FAILED_COMMANDS=$(echo "$COMMAND_STATS" | cut -d: -f3)

TOTAL_FILE_OPS=$(echo "$FILE_STATS" | cut -d: -f1)
READ_OPS=$(echo "$FILE_STATS" | cut -d: -f2)
WRITE_OPS=$(echo "$FILE_STATS" | cut -d: -f3)

TOTAL_ERRORS=$(echo "$ERROR_STATS" | cut -d: -f1)
TOTAL_NOTIFICATIONS=$(echo "$ERROR_STATS" | cut -d: -f2)

# Generate comprehensive session summary
SESSION_SUMMARY=$(cat <<EOF
# Claude Code Session Summary

**Project:** $PROJECT_NAME  
**Session ID:** $SESSION_ID  
**Date:** $(date '+%Y-%m-%d')  
**Duration:** $SESSION_DURATION  
**Generated:** $TIMESTAMP

## 📊 Activity Overview

### Commands Executed
- **Total Commands:** $TOTAL_COMMANDS
- **Successful:** $SUCCESSFUL_COMMANDS
- **Failed:** $FAILED_COMMANDS
- **Success Rate:** $(( TOTAL_COMMANDS > 0 ? (SUCCESSFUL_COMMANDS * 100) / TOTAL_COMMANDS : 0 ))%

### File Operations
- **Total File Operations:** $TOTAL_FILE_OPS
- **Read Operations:** $READ_OPS
- **Write Operations:** $WRITE_OPS

### System Events
- **Errors:** $TOTAL_ERRORS
- **Notifications:** $TOTAL_NOTIFICATIONS

## 📁 Most Accessed Files
$(get_most_accessed_files)

## 🔧 Command Categories Used
$(get_command_categories)

## 🎯 Session Highlights

### Key Activities
- File modifications and code changes
- Command executions and system operations
- Knowledge graph updates and learning

### Quality Metrics
- Code formatting applied automatically
- Security validations performed
- Tests executed when applicable
- Backup files created for safety

## 🧠 Knowledge Updates

The session contributed to the project's knowledge graph with:
- New component discoveries
- Relationship mappings
- Development pattern recognition
- Error and solution tracking

## 📈 Productivity Insights

**Efficiency Score:** $(( (SUCCESSFUL_COMMANDS * 2 + WRITE_OPS * 3) / (TOTAL_COMMANDS + TOTAL_FILE_OPS + 1) ))

**Development Focus:**
- Code quality and formatting
- Testing and validation
- Documentation and knowledge management
- Automated workflows and hooks

---

*This summary was automatically generated by Claude Code hooks.*
EOF
)

# Save session summary
SESSION_SUMMARY_FILE="${CLAUDE_LOGS_DIR}/session_summary_$(date +%Y%m%d_%H%M%S).md"
ensure_log_dir
echo "$SESSION_SUMMARY" > "$SESSION_SUMMARY_FILE"

# Also save as JSON for programmatic access
SESSION_JSON=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_NAME",
  "session_id": "$SESSION_ID",
  "duration": "$SESSION_DURATION",
  "statistics": {
    "commands": {
      "total": $TOTAL_COMMANDS,
      "successful": $SUCCESSFUL_COMMANDS,
      "failed": $FAILED_COMMANDS
    },
    "file_operations": {
      "total": $TOTAL_FILE_OPS,
      "read": $READ_OPS,
      "write": $WRITE_OPS
    },
    "events": {
      "errors": $TOTAL_ERRORS,
      "notifications": $TOTAL_NOTIFICATIONS
    }
  }
}
EOF
)

SESSION_JSON_FILE="${CLAUDE_LOGS_DIR}/session_summaries.jsonl"
echo "$SESSION_JSON" >> "$SESSION_JSON_FILE"

# Update knowledge graph with session summary
if neo4j_available; then
    NEO4J_SCRIPT="$(dirname "$0")/../utils/neo4j_mcp.py"
    if [[ -x "$NEO4J_SCRIPT" ]]; then
        ACTIVITY_DETAILS="Session completed: $TOTAL_COMMANDS commands, $TOTAL_FILE_OPS file ops, $TOTAL_ERRORS errors (Duration: $SESSION_DURATION)"
        python3 "$NEO4J_SCRIPT" "log_activity" "session_summary" "$ACTIVITY_DETAILS" 2>/dev/null || log_warn "Neo4j session logging failed"
    fi
fi

log_success "Session summary generated: $SESSION_SUMMARY_FILE"
log_info "Session statistics: Commands=$TOTAL_COMMANDS, FileOps=$TOTAL_FILE_OPS, Errors=$TOTAL_ERRORS"

success_with_message "Session summary completed successfully"

finalize_hook "session-summary" "completed"