#!/bin/bash
# Backup file hook - creates backup before modifications
# Runs before Edit/Write operations to preserve original content

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "backup-file"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Only backup if file exists
if file_exists "$FILE_PATH"; then
    safe_backup_file "$FILE_PATH"
    log_success "Backup created for $FILE_PATH"
else
    log_info "No backup needed - $FILE_PATH does not exist (new file)"
fi

success_with_message "Backup operation completed"

finalize_hook "backup-file" "completed"