#!/bin/bash
# Security validation hook for file modifications
# Runs before Edit/Write operations to validate content for security issues

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "security-check"

# Validate parameters
validate_params 2 $#

FILE_PATH="$1"
CONTENT="$2"

# Security checks array
SECURITY_VIOLATIONS=()

# Check for hardcoded secrets
check_hardcoded_secrets() {
    local content="$1"
    
    # Common secret patterns
    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]{3,}['\"]"
        "api_key\s*=\s*['\"][^'\"]{10,}['\"]"
        "secret\s*=\s*['\"][^'\"]{8,}['\"]"
        "token\s*=\s*['\"][^'\"]{10,}['\"]"
        "private_key\s*=\s*['\"]-----BEGIN"
        "aws_secret_access_key\s*=\s*['\"][^'\"]{20,}['\"]"
        "database_url\s*=\s*['\"].*://.*:.*@"
        "github_token\s*=\s*['\"]ghp_[^'\"]*['\"]"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        if echo "$content" | grep -iE "$pattern" >/dev/null 2>&1; then
            SECURITY_VIOLATIONS+=("Potential hardcoded secret detected: $pattern")
        fi
    done
}

# Check for dangerous functions
check_dangerous_functions() {
    local content="$1"
    local file_ext=$(get_file_extension "$FILE_PATH")
    
    case "$file_ext" in
        "py")
            # Python dangerous functions
            if echo "$content" | grep -E "(eval|exec|os\.system|subprocess\.call.*shell=True)" >/dev/null 2>&1; then
                SECURITY_VIOLATIONS+=("Dangerous Python function detected - potential code injection risk")
            fi
            ;;
        "js"|"ts")
            # JavaScript dangerous functions
            if echo "$content" | grep -E "(eval|new Function|innerHTML\s*=|document\.write)" >/dev/null 2>&1; then
                SECURITY_VIOLATIONS+=("Dangerous JavaScript function detected - potential XSS risk")
            fi
            ;;
        "sh"|"bash")
            # Shell script dangerous patterns
            if echo "$content" | grep -E "(\$\(.*\$.*\)|`.*\$.*`|rm\s+-rf\s+/)" >/dev/null 2>&1; then
                SECURITY_VIOLATIONS+=("Dangerous shell pattern detected - potential command injection")
            fi
            ;;
    esac
}

# Check for SQL injection patterns
check_sql_injection() {
    local content="$1"
    
    # Basic SQL injection patterns
    if echo "$content" | grep -iE "(SELECT.*FROM.*WHERE.*=.*\+|INSERT.*VALUES.*\+|UPDATE.*SET.*=.*\+)" >/dev/null 2>&1; then
        SECURITY_VIOLATIONS+=("Potential SQL injection vulnerability - use parameterized queries")
    fi
}

# Check for insecure configurations
check_insecure_config() {
    local content="$1"
    
    # Insecure configuration patterns
    local insecure_patterns=(
        "debug\s*=\s*true"
        "ssl\s*=\s*false"
        "verify_ssl\s*=\s*false"
        "allow_all_origins\s*=\s*true"
        "cors_allow_all\s*=\s*true"
    )
    
    for pattern in "${insecure_patterns[@]}"; do
        if echo "$content" | grep -iE "$pattern" >/dev/null 2>&1; then
            SECURITY_VIOLATIONS+=("Insecure configuration detected: $pattern")
        fi
    done
}

# Check for exposed sensitive paths
check_sensitive_paths() {
    local content="$1"
    
    # Sensitive path patterns
    if echo "$content" | grep -E "(/etc/passwd|/etc/shadow|/root/|\.ssh/|\.aws/credentials)" >/dev/null 2>&1; then
        SECURITY_VIOLATIONS+=("Reference to sensitive system path detected")
    fi
}

# Main security validation
log_info "Running security checks on $FILE_PATH"

# Only run checks if content is provided
if [[ -n "$CONTENT" ]]; then
    check_hardcoded_secrets "$CONTENT"
    check_dangerous_functions "$CONTENT"
    check_sql_injection "$CONTENT"
    check_insecure_config "$CONTENT"
    check_sensitive_paths "$CONTENT"
fi

# Evaluate results
if [[ ${#SECURITY_VIOLATIONS[@]} -gt 0 ]]; then
    log_error "Security violations found in $FILE_PATH:"
    for violation in "${SECURITY_VIOLATIONS[@]}"; do
        log_error "  - $violation"
    done
    
    # Create blocking response
    block_with_reason "Security violations detected: $(IFS='; '; echo "${SECURITY_VIOLATIONS[*]}")"
else
    log_success "Security check passed for $FILE_PATH"
    success_with_message "Security validation passed"
fi

finalize_hook "security-check" "completed"