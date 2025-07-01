#!/bin/bash
# Command logging hook - logs executed bash commands
# Runs after Bash tool execution for audit and learning purposes

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "log-command"

# Validate parameters
validate_params 2 $#

COMMAND="$1"
RESULT="$2"

# Create command log entry
TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)

# Prepare log entry
LOG_ENTRY="$TIMESTAMP | $PROJECT_NAME | $COMMAND"

# Add result status
if [[ -n "$RESULT" ]]; then
    # Check if command was successful (basic heuristic)
    if echo "$RESULT" | grep -qiE "(error|failed|permission denied|command not found)"; then
        STATUS="FAILED"
    else
        STATUS="SUCCESS"
    fi
else
    STATUS="UNKNOWN"
fi

LOG_ENTRY="$LOG_ENTRY | $STATUS"

# Log to command history file
COMMAND_LOG_FILE="${CLAUDE_LOGS_DIR}/command_history.log"
ensure_log_dir

echo "$LOG_ENTRY" >> "$COMMAND_LOG_FILE"

# Also log to main hooks log
log_info "Command executed: $COMMAND (Status: $STATUS)"

# Extract useful information for learning
extract_command_patterns() {
    local cmd="$1"
    
    # Identify command categories
    if echo "$cmd" | grep -qE "^(git|gh)"; then
        echo "git_operation"
    elif echo "$cmd" | grep -qE "^(npm|yarn|pip|cargo|go get)"; then
        echo "package_management"
    elif echo "$cmd" | grep -qE "^(docker|docker-compose)"; then
        echo "containerization"
    elif echo "$cmd" | grep -qE "^(make|cmake|mvn|gradle)"; then
        echo "build_system"
    elif echo "$cmd" | grep -qE "^(pytest|npm test|go test|cargo test)"; then
        echo "testing"
    elif echo "$cmd" | grep -qE "^(ls|find|grep|cat|head|tail)"; then
        echo "file_exploration"
    elif echo "$cmd" | grep -qE "^(mkdir|touch|rm|mv|cp)"; then
        echo "file_management"
    else
        echo "general"
    fi
}

COMMAND_CATEGORY=$(extract_command_patterns "$COMMAND")

# Create detailed log entry with category
DETAILED_LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_NAME",
  "command": "$COMMAND",
  "category": "$COMMAND_CATEGORY",
  "status": "$STATUS",
  "result_length": ${#RESULT}
}
EOF
)

# Log to JSON format for potential analysis
JSON_LOG_FILE="${CLAUDE_LOGS_DIR}/commands.jsonl"
echo "$DETAILED_LOG_ENTRY" >> "$JSON_LOG_FILE"

# Update Neo4j knowledge graph with command usage patterns
if neo4j_available; then
    NEO4J_SCRIPT="$(dirname "$0")/../utils/neo4j_mcp.py"
    if [[ -x "$NEO4J_SCRIPT" ]]; then
        ACTIVITY_DETAILS="Command executed: $COMMAND (Category: $COMMAND_CATEGORY, Status: $STATUS)"
        python3 "$NEO4J_SCRIPT" "log_activity" "command_execution" "$ACTIVITY_DETAILS" 2>/dev/null || log_warn "Neo4j activity logging failed"
    fi
fi

log_success "Command logged: $COMMAND"
success_with_message "Command logging completed"

finalize_hook "log-command" "completed"