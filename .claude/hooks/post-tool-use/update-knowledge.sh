#!/bin/bash
# Knowledge graph update hook - updates Neo4j with file changes
# Runs after Edit/Write operations to maintain project knowledge

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "update-knowledge"

# Validate parameters
validate_params 3 $#

FILE_PATH="$1"
ACTION="$2"
TOOL_RESULT="$3"

# Check if Neo4j is available
if ! neo4j_available; then
    log_warn "Neo4j not available, skipping knowledge update"
    success_with_message "Knowledge update skipped - Neo4j not available"
    finalize_hook "update-knowledge" "skipped"
    exit 0
fi

# Skip certain file types
skip_file_patterns=(
    "\.log$"
    "\.tmp$"
    "\.cache"
    "node_modules/"
    "\.git/"
    "__pycache__/"
    "\.pyc$"
    "\.o$"
    "\.exe$"
    "\.dll$"
    "\.so$"
)

for pattern in "${skip_file_patterns[@]}"; do
    if echo "$FILE_PATH" | grep -E "$pattern" >/dev/null 2>&1; then
        log_info "Skipping knowledge update for $FILE_PATH (matches skip pattern: $pattern)"
        success_with_message "Knowledge update skipped - file type excluded"
        finalize_hook "update-knowledge" "skipped"
        exit 0
    fi
done

log_info "Updating knowledge graph for $FILE_PATH (action: $ACTION)"

# Prepare content summary from tool result
CONTENT_SUMMARY=""
if [[ -n "$TOOL_RESULT" ]]; then
    # Extract relevant information from tool result
    CONTENT_SUMMARY=$(echo "$TOOL_RESULT" | head -5 | tr '\n' ' ' | cut -c1-200)
fi

# Call Python MCP integration utility
PYTHON_SCRIPT="$(dirname "$0")/../utils/neo4j_mcp.py"

if [[ -x "$PYTHON_SCRIPT" ]]; then
    log_info "Calling Neo4j MCP integration script"
    
    # Pass parameters to Python script
    if [[ -n "$CONTENT_SUMMARY" ]]; then
        python3 "$PYTHON_SCRIPT" "$ACTION" "$FILE_PATH" "$CONTENT_SUMMARY" 2>/dev/null || log_warn "Neo4j update script failed"
    else
        python3 "$PYTHON_SCRIPT" "$ACTION" "$FILE_PATH" 2>/dev/null || log_warn "Neo4j update script failed"
    fi
    
    log_success "Knowledge graph update completed for $FILE_PATH"
else
    log_error "Neo4j MCP integration script not found or not executable"
fi

# Additional knowledge updates based on file type
LANGUAGE=$(detect_language "$FILE_PATH")

case "$LANGUAGE" in
    "python")
        # For Python files, also check for new imports and classes
        if file_exists "$FILE_PATH"; then
            log_info "Analyzing Python file structure for knowledge updates"
            # Could add more sophisticated analysis here
        fi
        ;;
    "javascript"|"typescript")
        # For JS/TS files, check for exports and imports
        if file_exists "$FILE_PATH"; then
            log_info "Analyzing JavaScript/TypeScript file structure for knowledge updates"
        fi
        ;;
    "go")
        # For Go files, check for package declarations and functions
        if file_exists "$FILE_PATH"; then
            log_info "Analyzing Go file structure for knowledge updates"
        fi
        ;;
esac

# Log development activity
ACTIVITY_DETAILS="Modified $FILE_PATH - Language: $LANGUAGE, Action: $ACTION"
if [[ -x "$PYTHON_SCRIPT" ]]; then
    python3 "$PYTHON_SCRIPT" "log_activity" "$FILE_PATH" "$ACTIVITY_DETAILS" 2>/dev/null || log_warn "Activity logging failed"
fi

success_with_message "Knowledge graph update completed successfully"

finalize_hook "update-knowledge" "completed"