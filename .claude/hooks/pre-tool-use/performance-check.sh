#!/bin/bash
# Performance warning hook - warns about potential performance issues
# Prevents expensive operations on large files or complex operations

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "performance-check"

# Validate parameters - this is a pre-tool-use hook, so parameters vary by tool
if [[ $# -lt 1 ]]; then
    log_warn "No parameters provided to performance check"
    success_with_message "No performance check needed"
    finalize_hook "performance-check" "skipped"
    exit 0
fi

TOOL_NAME="$1"
shift
TOOL_ARGS="$@"

log_info "Performance check for tool: $TOOL_NAME"

# Function to get file size in bytes
get_file_size() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to check if file is binary
is_binary_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        file "$file_path" | grep -q "text" && return 1 || return 0
    fi
    return 1
}

# Function to count lines in file
count_lines() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        wc -l < "$file_path" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Define size thresholds (in bytes)
LARGE_FILE_THRESHOLD=1048576    # 1MB
HUGE_FILE_THRESHOLD=10485760    # 10MB
LARGE_LINE_COUNT=5000
HUGE_LINE_COUNT=20000

# Performance checks based on tool type
case "$TOOL_NAME" in
    "Edit"|"MultiEdit")
        # Extract file path from arguments
        FILE_PATH=""
        for arg in $TOOL_ARGS; do
            if [[ -f "$arg" ]]; then
                FILE_PATH="$arg"
                break
            fi
        done
        
        if [[ -n "$FILE_PATH" ]]; then
            FILE_SIZE=$(get_file_size "$FILE_PATH")
            LINE_COUNT=$(count_lines "$FILE_PATH")
            
            log_info "Checking file: $FILE_PATH (size: $FILE_SIZE bytes, lines: $LINE_COUNT)"
            
            # Check for very large files
            if [[ $FILE_SIZE -gt $HUGE_FILE_THRESHOLD ]]; then
                log_warn "⚠️  PERFORMANCE WARNING: File is very large ($(($FILE_SIZE / 1024 / 1024))MB)"
                echo "🐌 Editing this file may be slow. Consider:"
                echo "   • Breaking it into smaller files"
                echo "   • Using stream processing for data files"
                echo "   • Editing only specific sections"
                echo ""
            elif [[ $FILE_SIZE -gt $LARGE_FILE_THRESHOLD ]]; then
                log_warn "⚠️  Performance notice: Large file ($(($FILE_SIZE / 1024))KB)"
                echo "💡 Tip: Large file editing may take extra time"
                echo ""
            fi
            
            # Check for files with many lines
            if [[ $LINE_COUNT -gt $HUGE_LINE_COUNT ]]; then
                log_warn "⚠️  PERFORMANCE WARNING: File has many lines ($LINE_COUNT)"
                echo "🐌 Editing may be slow. Consider:"
                echo "   • Using line-range editing"
                echo "   • Splitting into smaller files"
                echo "   • Using specialized tools for large datasets"
                echo ""
            elif [[ $LINE_COUNT -gt $LARGE_LINE_COUNT ]]; then
                log_warn "⚠️  Performance notice: File has many lines ($LINE_COUNT)"
                echo "💡 Tip: Consider using offset/limit parameters for partial reading"
                echo ""
            fi
            
            # Check if it's a binary file
            if is_binary_file "$FILE_PATH"; then
                log_warn "⚠️  WARNING: Attempting to edit binary file"
                echo "🚫 Binary files should not be edited as text:"
                echo "   • Use appropriate binary editors"
                echo "   • Consider if this is the correct file"
                echo "   • Data corruption may occur"
                echo ""
            fi
            
            # Check for specific file types that are typically large
            case "$(get_file_extension "$FILE_PATH")" in
                "log"|"csv"|"json"|"xml"|"sql")
                    if [[ $FILE_SIZE -gt $LARGE_FILE_THRESHOLD ]]; then
                        log_warn "⚠️  Large data file detected: $(get_file_extension "$FILE_PATH")"
                        echo "💡 Consider using specialized tools:"
                        echo "   • jq for large JSON files"
                        echo "   • awk/sed for log files"
                        echo "   • Database tools for SQL files"
                        echo ""
                    fi
                    ;;
            esac
        fi
        ;;
        
    "Read")
        # Extract file path from arguments
        FILE_PATH=""
        for arg in $TOOL_ARGS; do
            if [[ -f "$arg" ]]; then
                FILE_PATH="$arg"
                break
            fi
        done
        
        if [[ -n "$FILE_PATH" ]]; then
            FILE_SIZE=$(get_file_size "$FILE_PATH")
            LINE_COUNT=$(count_lines "$FILE_PATH")
            
            # Only warn for extremely large files on read
            if [[ $FILE_SIZE -gt $HUGE_FILE_THRESHOLD ]]; then
                log_warn "⚠️  Reading very large file ($(($FILE_SIZE / 1024 / 1024))MB)"
                echo "💡 Consider using offset/limit parameters"
                echo ""
            fi
            
            if [[ $LINE_COUNT -gt $HUGE_LINE_COUNT ]]; then
                log_warn "⚠️  Reading file with many lines ($LINE_COUNT)"
                echo "💡 Consider using offset/limit or line range"
                echo ""
            fi
        fi
        ;;
        
    "Bash")
        # Check for potentially expensive bash commands
        COMMAND_LINE="$TOOL_ARGS"
        
        # Check for commands that might be slow or resource-intensive
        case "$COMMAND_LINE" in
            *"find / "*|*"find /home "*|*"find /usr "*|*"find /var "*)
                log_warn "⚠️  PERFORMANCE WARNING: System-wide find command"
                echo "🐌 This command may take a very long time:"
                echo "   • Consider limiting search scope"
                echo "   • Use more specific paths"
                echo "   • Add size or time limits"
                echo ""
                ;;
            *"grep -r "*|*"rg "*|*"ag "*)
                if [[ "$COMMAND_LINE" == *"/"* ]] && [[ "$COMMAND_LINE" != *"./"* ]]; then
                    log_warn "⚠️  Performance notice: Recursive search command"
                    echo "💡 Large directory searches may take time"
                    echo ""
                fi
                ;;
            *"tar "*|*"zip "*|*"unzip "*|*"7z "*)
                log_warn "⚠️  Performance notice: Archive operation"
                echo "💡 Archive operations may take time for large files"
                echo ""
                ;;
            *"npm install"*|*"yarn install"*|*"pip install"*)
                log_warn "⚠️  Performance notice: Package installation"
                echo "💡 Package installation may take several minutes"
                echo ""
                ;;
            *"docker build"*|*"docker run"*)
                log_warn "⚠️  Performance notice: Docker operation"
                echo "💡 Docker operations may take time"
                echo ""
                ;;
            *"rsync"*|*"cp -r"*|*"mv "*" "*)
                log_warn "⚠️  Performance notice: File operation"
                echo "💡 Large file operations may take time"
                echo ""
                ;;
        esac
        ;;
        
    "Glob"|"Grep")
        # Check for potentially expensive search patterns
        if [[ "$TOOL_ARGS" == *"**"* ]] || [[ "$TOOL_ARGS" == *"*/*"* ]]; then
            log_warn "⚠️  Performance notice: Recursive pattern"
            echo "💡 Recursive searches may take time in large directories"
            echo ""
        fi
        ;;
esac

# Additional system-level performance checks
AVAILABLE_MEMORY=$(free -m 2>/dev/null | awk 'NR==2{printf "%.0f", $7}' || echo "unknown")
DISK_USAGE=$(df . 2>/dev/null | awk 'NR==2{print $5}' | sed 's/%//' || echo "unknown")

if [[ "$AVAILABLE_MEMORY" != "unknown" ]] && [[ $AVAILABLE_MEMORY -lt 500 ]]; then
    log_warn "⚠️  SYSTEM WARNING: Low available memory (${AVAILABLE_MEMORY}MB)"
    echo "🐌 System performance may be affected"
    echo ""
fi

if [[ "$DISK_USAGE" != "unknown" ]] && [[ $DISK_USAGE -gt 90 ]]; then
    log_warn "⚠️  SYSTEM WARNING: Disk usage high (${DISK_USAGE}%)"
    echo "💾 Consider cleaning up disk space"
    echo ""
fi

log_info "Performance check completed for $TOOL_NAME"
success_with_message "Performance check completed"
finalize_hook "performance-check" "completed"