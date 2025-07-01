#!/bin/bash
# Error handling hook - special handling for error notifications
# Runs on error notifications for enhanced error processing

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "handle-error"

# Validate parameters
validate_params 2 $#

ERROR_TYPE="$1"
ERROR_MESSAGE="$2"

TIMESTAMP=$(get_timestamp)
PROJECT_NAME=$(get_project_name)

# Create error-specific log
ERROR_LOG_FILE="${CLAUDE_LOGS_DIR}/errors.log"
ensure_log_dir

LOG_ENTRY="$TIMESTAMP | $PROJECT_NAME | $ERROR_TYPE | $ERROR_MESSAGE"
echo "$LOG_ENTRY" >> "$ERROR_LOG_FILE"

# Analyze error type and severity
analyze_error() {
    local error_type="$1"
    local error_msg="$2"
    
    local severity="medium"
    local category="general"
    
    # Determine severity
    if echo "$error_msg" | grep -qiE "(critical|fatal|severe|corruption|loss)"; then
        severity="high"
    elif echo "$error_msg" | grep -qiE "(warning|minor|notice)"; then
        severity="low"
    fi
    
    # Determine category
    if echo "$error_msg" | grep -qiE "(permission|access|denied|unauthorized)"; then
        category="permissions"
    elif echo "$error_msg" | grep -qiE "(network|connection|timeout|unreachable)"; then
        category="network"
    elif echo "$error_msg" | grep -qiE "(syntax|parse|compile|invalid)"; then
        category="syntax"
    elif echo "$error_msg" | grep -qiE "(memory|disk|space|resource)"; then
        category="resources"
    elif echo "$error_msg" | grep -qiE "(file|directory|path|not found)"; then
        category="filesystem"
    elif echo "$error_msg" | grep -qiE "(git|repository|branch|merge)"; then
        category="git"
    elif echo "$error_msg" | grep -qiE "(test|testing|assertion|failed)"; then
        category="testing"
    fi
    
    echo "$severity:$category"
}

ERROR_ANALYSIS=$(analyze_error "$ERROR_TYPE" "$ERROR_MESSAGE")
SEVERITY=$(echo "$ERROR_ANALYSIS" | cut -d: -f1)
CATEGORY=$(echo "$ERROR_ANALYSIS" | cut -d: -f2)

# Create detailed error entry
DETAILED_ERROR_ENTRY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_NAME",
  "error_type": "$ERROR_TYPE",
  "error_message": "$ERROR_MESSAGE",
  "severity": "$SEVERITY",
  "category": "$CATEGORY",
  "session_id": "${CLAUDE_SESSION_ID:-unknown}"
}
EOF
)

# Log to JSON format
JSON_ERROR_LOG="${CLAUDE_LOGS_DIR}/errors.jsonl"
echo "$DETAILED_ERROR_ENTRY" >> "$JSON_ERROR_LOG"

# Error-specific actions based on category
handle_error_category() {
    local category="$1"
    local severity="$2"
    local error_msg="$3"
    
    case "$category" in
        "permissions")
            log_warn "Permission error detected - check file/directory permissions"
            # Could suggest chmod/chown commands
            ;;
        "network")
            log_warn "Network error detected - check connectivity"
            # Could suggest network diagnostics
            ;;
        "syntax")
            log_warn "Syntax error detected - code formatting may help"
            # Could trigger additional syntax checking
            ;;
        "resources")
            log_warn "Resource error detected - check disk space and memory"
            # Could check system resources
            ;;
        "filesystem")
            log_warn "Filesystem error detected - check file paths"
            # Could verify file existence
            ;;
        "git")
            log_warn "Git error detected - check repository status"
            # Could run git status
            ;;
        "testing")
            log_warn "Test error detected - check test configuration"
            # Could suggest test debugging
            ;;
    esac
}

# GitHub issue creation for high-severity errors
create_error_issue() {
    local error_type="$1"
    local error_msg="$2"
    local severity="$3"
    
    if [[ "$severity" == "high" ]] && github_token_available; then
        local github_script="$(dirname "$0")/../utils/github_mcp.py"
        if [[ -x "$github_script" ]]; then
            log_info "Creating GitHub issue for high-severity error"
            
            # This would create an issue - for now just log
            local issue_title="High-Severity Error: $error_type"
            local issue_body="**Error Type:** $error_type\n**Message:** $error_msg\n**Project:** $PROJECT_NAME\n**Timestamp:** $TIMESTAMP"
            
            log_info "Would create GitHub issue: $issue_title"
        fi
    fi
}

# Update knowledge graph with error patterns
if neo4j_available; then
    NEO4J_SCRIPT="$(dirname "$0")/../utils/neo4j_mcp.py"
    if [[ -x "$NEO4J_SCRIPT" ]]; then
        ACTIVITY_DETAILS="Error occurred: $ERROR_TYPE - $ERROR_MESSAGE (Severity: $SEVERITY, Category: $CATEGORY)"
        python3 "$NEO4J_SCRIPT" "log_activity" "error" "$ACTIVITY_DETAILS" 2>/dev/null || log_warn "Neo4j error logging failed"
    fi
fi

# Execute error handling actions
log_error "Error handled: $ERROR_TYPE - $ERROR_MESSAGE (Severity: $SEVERITY, Category: $CATEGORY)"

handle_error_category "$CATEGORY" "$SEVERITY" "$ERROR_MESSAGE"
create_error_issue "$ERROR_TYPE" "$ERROR_MESSAGE" "$SEVERITY"

# Provide recovery suggestions based on error patterns
suggest_recovery() {
    local category="$1"
    local error_msg="$2"
    
    case "$category" in
        "permissions")
            log_info "Recovery suggestion: Try 'chmod +x file' or check file ownership"
            ;;
        "network")
            log_info "Recovery suggestion: Check internet connection or proxy settings"
            ;;
        "syntax")
            log_info "Recovery suggestion: Run code formatter or check language syntax"
            ;;
        "filesystem")
            log_info "Recovery suggestion: Verify file paths and create missing directories"
            ;;
        "git")
            log_info "Recovery suggestion: Run 'git status' and resolve any conflicts"
            ;;
        "testing")
            log_info "Recovery suggestion: Check test configuration and dependencies"
            ;;
    esac
}

suggest_recovery "$CATEGORY" "$ERROR_MESSAGE"

success_with_message "Error handling completed"

finalize_hook "handle-error" "completed"