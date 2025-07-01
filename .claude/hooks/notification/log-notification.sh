#!/bin/bash
# Notification logging hook - logs all Claude notifications
# Runs on all notification events for comprehensive logging

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "log-notification"

# Validate parameters
validate_params 2 $#

NOTIFICATION_TYPE="$1"
MESSAGE="$2"

TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)

# Create notification log entry
NOTIFICATION_LOG_FILE="${CLAUDE_LOGS_DIR}/notifications.log"
ensure_log_dir

LOG_ENTRY="$TIMESTAMP | $PROJECT_NAME | $NOTIFICATION_TYPE | $MESSAGE"
echo "$LOG_ENTRY" >> "$NOTIFICATION_LOG_FILE"

# Create detailed JSON log entry
DETAILED_LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_NAME",
  "notification_type": "$NOTIFICATION_TYPE",
  "message": "$MESSAGE",
  "session_id": "${CLAUDE_SESSION_ID:-unknown}"
}
EOF
)

# Log to JSON format
JSON_LOG_FILE="${CLAUDE_LOGS_DIR}/notifications.jsonl"
echo "$DETAILED_LOG_ENTRY" >> "$JSON_LOG_FILE"

# Categorize notification types
categorize_notification() {
    local type="$1"
    local msg="$2"
    
    case "$type" in
        "error"|"ERROR")
            echo "error"
            ;;
        "warning"|"WARNING"|"warn"|"WARN")
            echo "warning"
            ;;
        "info"|"INFO"|"information")
            echo "info"
            ;;
        "success"|"SUCCESS"|"complete"|"COMPLETE")
            echo "success"
            ;;
        "progress"|"PROGRESS"|"update"|"UPDATE")
            echo "progress"
            ;;
        *)
            # Try to infer from message content
            if echo "$msg" | grep -qiE "(error|failed|exception)"; then
                echo "error"
            elif echo "$msg" | grep -qiE "(warning|caution|attention)"; then
                echo "warning"
            elif echo "$msg" | grep -qiE "(success|complete|done|finished)"; then
                echo "success"
            elif echo "$msg" | grep -qiE "(progress|processing|working)"; then
                echo "progress"
            else
                echo "general"
            fi
            ;;
    esac
}

CATEGORY=$(categorize_notification "$NOTIFICATION_TYPE" "$MESSAGE")

# Update knowledge graph with notification patterns
if neo4j_available; then
    NEO4J_SCRIPT="$(dirname "$0")/../utils/neo4j_mcp.py"
    if [[ -x "$NEO4J_SCRIPT" ]]; then
        ACTIVITY_DETAILS="Notification: $NOTIFICATION_TYPE - $MESSAGE (Category: $CATEGORY)"
        python3 "$NEO4J_SCRIPT" "log_activity" "notification" "$ACTIVITY_DETAILS" 2>/dev/null || log_warn "Neo4j notification logging failed"
    fi
fi

# Special handling for certain notification types
case "$CATEGORY" in
    "error")
        log_error "Notification (ERROR): $MESSAGE"
        # Could trigger additional error handling here
        ;;
    "warning")
        log_warn "Notification (WARNING): $MESSAGE"
        ;;
    "success")
        log_success "Notification (SUCCESS): $MESSAGE"
        ;;
    *)
        log_info "Notification ($NOTIFICATION_TYPE): $MESSAGE"
        ;;
esac

success_with_message "Notification logged successfully"

finalize_hook "log-notification" "completed"