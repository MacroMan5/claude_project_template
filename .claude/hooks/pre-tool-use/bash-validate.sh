#!/bin/bash
# Bash command validation hook
# Runs before Bash tool execution to validate commands for safety

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "bash-validate"

# Validate parameters
validate_params 1 $#

COMMAND="$1"

# Dangerous command patterns
DANGEROUS_PATTERNS=(
    "rm\s+-rf\s+/"
    "rm\s+-rf\s+\*"
    "dd\s+if=.*of=/dev/"
    "mkfs\."
    "fdisk"
    "parted"
    ":(){ :|:& };:"
    "shutdown"
    "reboot"
    "halt"
    "init\s+0"
    "init\s+6"
    "systemctl\s+(poweroff|reboot|halt)"
)

# Suspicious patterns that need attention
SUSPICIOUS_PATTERNS=(
    "curl.*\|.*sh"
    "wget.*\|.*sh"
    "chmod\s+777"
    "chown\s+.*root"
    "sudo\s+su"
    "passwd\s+"
    "userdel"
    "usermod"
)

# Check for dangerous patterns
log_info "Validating command: $COMMAND"

VIOLATIONS=()

# Check dangerous patterns
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -E "$pattern" >/dev/null 2>&1; then
        VIOLATIONS+=("DANGEROUS: Command matches pattern '$pattern'")
    fi
done

# Check suspicious patterns
for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -E "$pattern" >/dev/null 2>&1; then
        VIOLATIONS+=("SUSPICIOUS: Command matches pattern '$pattern'")
    fi
done

# Check for system directory modifications
if echo "$COMMAND" | grep -E "(^|\s)(rm|mv|cp|chmod|chown).*(/bin|/sbin|/usr|/etc|/boot|/sys|/proc)" >/dev/null 2>&1; then
    VIOLATIONS+=("DANGEROUS: Command attempts to modify system directories")
fi

# Evaluate results
if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    # Check if any violation is dangerous (not just suspicious)
    has_dangerous=false
    for violation in "${VIOLATIONS[@]}"; do
        if [[ "$violation" == DANGEROUS:* ]]; then
            has_dangerous=true
            break
        fi
    done
    
    log_error "Command validation issues found:"
    for violation in "${VIOLATIONS[@]}"; do
        log_error "  - $violation"
    done
    
    if $has_dangerous; then
        block_with_reason "Dangerous command blocked: $(IFS='; '; echo "${VIOLATIONS[*]}")"
    else
        log_warn "Suspicious command detected but allowing execution"
        success_with_message "Command validated with warnings: $(IFS='; '; echo "${VIOLATIONS[*]}")"
    fi
else
    log_success "Command validation passed"
    success_with_message "Command is safe to execute"
fi

finalize_hook "bash-validate" "completed"