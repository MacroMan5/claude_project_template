#!/bin/bash
# Git auto-stage hook - stages formatted files for clean commits
# Automatically stages files after they've been formatted, but never commits

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "git-auto-stage"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping git staging"
    success_with_message "No git staging needed - file does not exist"
    finalize_hook "git-auto-stage" "skipped"
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_info "Not in a git repository, skipping auto-staging"
    success_with_message "Not in git repository - no staging performed"
    finalize_hook "git-auto-stage" "skipped"
    exit 0
fi

# Get the relative path from git root
GIT_ROOT=$(git rev-parse --show-toplevel)
RELATIVE_PATH=$(realpath --relative-to="$GIT_ROOT" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

log_info "Checking if $RELATIVE_PATH needs git staging"

# Check if file has been modified (is dirty)
if git diff --quiet "$RELATIVE_PATH" 2>/dev/null; then
    log_info "File $RELATIVE_PATH has no changes, skipping staging"
    success_with_message "No changes to stage"
    finalize_hook "git-auto-stage" "skipped"
    exit 0
fi

# Check if this is a file we should auto-stage
SHOULD_STAGE=false
LANGUAGE=$(detect_language "$FILE_PATH")

# Only auto-stage code files that are likely to have been formatted
case "$LANGUAGE" in
    "javascript"|"typescript"|"python"|"go"|"rust"|"java"|"cpp"|"c"|"ruby"|"php"|"swift"|"kotlin")
        SHOULD_STAGE=true
        ;;
    *)
        # Check file extensions for other stageable files
        case "$(get_file_extension "$FILE_PATH")" in
            "json"|"yaml"|"yml"|"md"|"css"|"scss"|"sass"|"less"|"html")
                SHOULD_STAGE=true
                ;;
        esac
        ;;
esac

# Skip certain file types that shouldn't be auto-staged
case "$(basename "$FILE_PATH")" in
    ".env"|".env.local"|".env.production"|"*.log"|"*.tmp"|"*.cache")
        SHOULD_STAGE=false
        ;;
esac

if ! $SHOULD_STAGE; then
    log_info "File type not suitable for auto-staging: $LANGUAGE"
    success_with_message "File type not auto-staged"
    finalize_hook "git-auto-stage" "skipped"
    exit 0
fi

# Check git status to understand the file state
GIT_STATUS=$(git status --porcelain "$RELATIVE_PATH" 2>/dev/null)

if [[ -z "$GIT_STATUS" ]]; then
    log_info "File $RELATIVE_PATH is not tracked or has no changes"
    success_with_message "File not tracked or unchanged"
    finalize_hook "git-auto-stage" "skipped"
    exit 0
fi

# Parse git status
STATUS_CODE="${GIT_STATUS:0:2}"

case "$STATUS_CODE" in
    " M"|"?M")
        # File is modified but not staged
        log_info "Staging modified file: $RELATIVE_PATH"
        if git add "$RELATIVE_PATH" 2>/dev/null; then
            log_success "Successfully staged $RELATIVE_PATH"
            success_with_message "File staged for commit"
        else
            log_warn "Failed to stage $RELATIVE_PATH"
            success_with_message "Failed to stage file"
        fi
        ;;
    "M "|"MM")
        # File is already staged, or staged with additional modifications
        log_info "File $RELATIVE_PATH is already staged or partially staged"
        # Re-stage to include latest changes
        if git add "$RELATIVE_PATH" 2>/dev/null; then
            log_success "Updated staging for $RELATIVE_PATH"
            success_with_message "Staging updated with latest changes"
        else
            log_warn "Failed to update staging for $RELATIVE_PATH"
            success_with_message "Failed to update staging"
        fi
        ;;
    "??")
        # Untracked file - only stage if it's a clear code file
        case "$LANGUAGE" in
            "javascript"|"typescript"|"python"|"go"|"rust"|"java"|"cpp"|"c")
                log_info "Staging new code file: $RELATIVE_PATH"
                if git add "$RELATIVE_PATH" 2>/dev/null; then
                    log_success "Successfully staged new file $RELATIVE_PATH"
                    success_with_message "New file staged for commit"
                else
                    log_warn "Failed to stage new file $RELATIVE_PATH"
                    success_with_message "Failed to stage new file"
                fi
                ;;
            *)
                log_info "Not auto-staging untracked non-code file: $RELATIVE_PATH"
                success_with_message "Untracked file not auto-staged"
                ;;
        esac
        ;;
    *)
        log_info "File $RELATIVE_PATH has status '$STATUS_CODE' - no action needed"
        success_with_message "No staging action needed"
        ;;
esac

# Provide helpful information about staged changes
STAGED_FILES=$(git diff --cached --name-only | wc -l)
if [[ $STAGED_FILES -gt 0 ]]; then
    log_info "Total staged files: $STAGED_FILES"
    if [[ $STAGED_FILES -lt 10 ]]; then
        log_info "Staged files: $(git diff --cached --name-only | tr '\n' ' ')"
    fi
fi

finalize_hook "git-auto-stage" "completed"