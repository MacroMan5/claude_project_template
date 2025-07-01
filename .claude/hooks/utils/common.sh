#!/bin/bash
# Common utility functions for Claude Code hooks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${CLAUDE_LOGS_DIR}/hooks.log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${CLAUDE_LOGS_DIR}/hooks.log"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "${CLAUDE_LOGS_DIR}/hooks.log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${CLAUDE_LOGS_DIR}/hooks.log"
}

# Ensure log directory exists
ensure_log_dir() {
    mkdir -p "${CLAUDE_LOGS_DIR}"
}

# Get project name
get_project_name() {
    echo "${PROJECT_NAME:-$(basename $(pwd))}"
}

# Check if file exists and is readable
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Get file extension
get_file_extension() {
    echo "${1##*.}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create JSON response for hooks
create_json_response() {
    local block="$1"
    local reason="$2"
    local continue_val="${3:-true}"
    
    cat <<EOF
{
    "block": $block,
    "reason": "$reason",
    "continue": $continue_val
}
EOF
}

# Block execution with reason
block_with_reason() {
    local reason="$1"
    log_error "Blocked: $reason"
    create_json_response true "$reason" false
    exit 2
}

# Success with message
success_with_message() {
    local message="$1"
    log_success "$message"
    create_json_response false "$message" true
    exit 0
}

# Check if Neo4j is available
neo4j_available() {
    nc -z localhost 7687 >/dev/null 2>&1
}

# Check if GitHub token is set
github_token_available() {
    [[ -n "$GITHUB_TOKEN" ]]
}

# Get timestamp for logging
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Initialize hook execution
init_hook() {
    local hook_name="$1"
    ensure_log_dir
    log_info "$(get_timestamp) - Executing hook: $hook_name"
}

# Finalize hook execution
finalize_hook() {
    local hook_name="$1"
    local status="$2"
    log_info "$(get_timestamp) - Hook completed: $hook_name (status: $status)"
}

# Validate hook parameters
validate_params() {
    local required_count="$1"
    local actual_count="$2"
    
    if [[ $actual_count -lt $required_count ]]; then
        log_error "Insufficient parameters. Required: $required_count, Got: $actual_count"
        exit 1
    fi
}

# Safe file operations
safe_backup_file() {
    local file_path="$1"
    local backup_dir="${CLAUDE_LOGS_DIR}/backups"
    
    if file_exists "$file_path"; then
        mkdir -p "$backup_dir"
        local backup_name="$(basename "$file_path").$(date +%s)"
        cp "$file_path" "$backup_dir/$backup_name"
        log_info "Backed up $file_path to $backup_dir/$backup_name"
    fi
}

# Language detection
detect_language() {
    local file_path="$1"
    local extension=$(get_file_extension "$file_path")
    
    case "$extension" in
        "py") echo "python" ;;
        "js"|"jsx") echo "javascript" ;;
        "ts"|"tsx") echo "typescript" ;;
        "go") echo "go" ;;
        "rs") echo "rust" ;;
        "java") echo "java" ;;
        "cpp"|"cc"|"cxx") echo "cpp" ;;
        "c") echo "c" ;;
        "sh"|"bash") echo "shell" ;;
        "rb") echo "ruby" ;;
        "php") echo "php" ;;
        "swift") echo "swift" ;;
        "kt") echo "kotlin" ;;
        *) echo "unknown" ;;
    esac
}

# Export functions for use in other scripts
export -f log_info log_success log_warn log_error
export -f ensure_log_dir get_project_name file_exists get_file_extension command_exists
export -f create_json_response block_with_reason success_with_message
export -f neo4j_available github_token_available get_timestamp
export -f init_hook finalize_hook validate_params safe_backup_file detect_language