#!/bin/bash
# Multi-file edit validation hook
# Runs before MultiEdit operations to validate the scope and safety

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "multi-edit-check"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Multi-edit specific checks
VIOLATIONS=()

# Check if too many files are being modified at once
count_editable_files() {
    local base_dir=$(dirname "$FILE_PATH")
    local file_count=0
    
    # Count files that might be affected by multi-edit
    if [[ -d "$base_dir" ]]; then
        file_count=$(find "$base_dir" -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.java" 2>/dev/null | wc -l)
    fi
    
    echo $file_count
}

# Check for critical file modifications
check_critical_files() {
    local file_path="$1"
    
    # Critical file patterns
    local critical_patterns=(
        "package\.json$"
        "requirements\.txt$"
        "go\.mod$"
        "Cargo\.toml$"
        "pom\.xml$"
        "build\.gradle$"
        "Dockerfile$"
        "docker-compose\.ya?ml$"
        "\.env$"
        "config\.ya?ml$"
        "settings\.py$"
    )
    
    for pattern in "${critical_patterns[@]}"; do
        if echo "$file_path" | grep -E "$pattern" >/dev/null 2>&1; then
            VIOLATIONS+=("CRITICAL: Multi-edit operation targets critical file: $file_path")
            return
        fi
    done
}

# Check for system file modifications
check_system_files() {
    local file_path="$1"
    
    if echo "$file_path" | grep -E "^(/etc|/usr|/bin|/sbin|/boot|/sys|/proc)" >/dev/null 2>&1; then
        VIOLATIONS+=("DANGEROUS: Multi-edit operation targets system file: $file_path")
    fi
}

# Check if modification scope is reasonable
check_modification_scope() {
    local file_count=$(count_editable_files)
    
    if [[ $file_count -gt 50 ]]; then
        VIOLATIONS+=("WARNING: Multi-edit operation affects directory with $file_count files - consider smaller scope")
    fi
}

# Main validation
log_info "Validating multi-edit operation on $FILE_PATH"

check_critical_files "$FILE_PATH"
check_system_files "$FILE_PATH"
check_modification_scope

# Evaluate results
if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    # Check for dangerous violations
    has_dangerous=false
    has_critical=false
    
    for violation in "${VIOLATIONS[@]}"; do
        if [[ "$violation" == DANGEROUS:* ]]; then
            has_dangerous=true
        elif [[ "$violation" == CRITICAL:* ]]; then
            has_critical=true
        fi
    done
    
    log_error "Multi-edit validation issues found:"
    for violation in "${VIOLATIONS[@]}"; do
        log_error "  - $violation"
    done
    
    if $has_dangerous; then
        block_with_reason "Dangerous multi-edit operation blocked: $(IFS='; '; echo "${VIOLATIONS[*]}")"
    elif $has_critical; then
        log_warn "Critical file modification detected - proceed with caution"
        success_with_message "Multi-edit validated with critical file warning: $(IFS='; '; echo "${VIOLATIONS[*]}")"
    else
        log_warn "Multi-edit operation has warnings but is allowed"
        success_with_message "Multi-edit validated with warnings: $(IFS='; '; echo "${VIOLATIONS[*]}")"
    fi
else
    log_success "Multi-edit validation passed"
    success_with_message "Multi-edit operation is safe to proceed"
fi

finalize_hook "multi-edit-check" "completed"