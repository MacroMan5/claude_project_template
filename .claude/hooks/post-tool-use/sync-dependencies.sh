#!/bin/bash
# Package dependency sync hook - auto-install dependencies after package file changes
# Keeps dependencies in sync automatically for faster development

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "sync-dependencies"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping dependency sync"
    success_with_message "No dependency sync needed - file does not exist"
    finalize_hook "sync-dependencies" "skipped"
    exit 0
fi

# Check if this is a package dependency file
FILENAME=$(basename "$FILE_PATH")
SYNC_NEEDED=false
PACKAGE_MANAGER=""

case "$FILENAME" in
    "package.json")
        PACKAGE_MANAGER="npm"
        SYNC_NEEDED=true
        ;;
    "package-lock.json")
        PACKAGE_MANAGER="npm"
        SYNC_NEEDED=true
        ;;
    "yarn.lock")
        PACKAGE_MANAGER="yarn"
        SYNC_NEEDED=true
        ;;
    "requirements.txt")
        PACKAGE_MANAGER="pip"
        SYNC_NEEDED=true
        ;;
    "Pipfile"|"Pipfile.lock")
        PACKAGE_MANAGER="pipenv"
        SYNC_NEEDED=true
        ;;
    "Cargo.toml"|"Cargo.lock")
        PACKAGE_MANAGER="cargo"
        SYNC_NEEDED=true
        ;;
    "go.mod"|"go.sum")
        PACKAGE_MANAGER="go"
        SYNC_NEEDED=true
        ;;
    *)
        log_info "File $FILENAME is not a dependency file, skipping sync"
        success_with_message "No dependency sync needed for this file type"
        finalize_hook "sync-dependencies" "skipped"
        exit 0
        ;;
esac

if ! $SYNC_NEEDED; then
    finalize_hook "sync-dependencies" "skipped"
    exit 0
fi

log_info "Detected $PACKAGE_MANAGER dependency file change: $FILENAME"

# Change to the directory containing the dependency file
PACKAGE_DIR=$(dirname "$FILE_PATH")
cd "$PACKAGE_DIR" || {
    log_error "Failed to change to directory: $PACKAGE_DIR"
    finalize_hook "sync-dependencies" "failed"
    exit 1
}

# Run appropriate package manager command
case "$PACKAGE_MANAGER" in
    "npm")
        if command_exists "npm"; then
            log_info "Running npm install in $PACKAGE_DIR"
            if npm install 2>/dev/null; then
                log_success "Dependencies synced successfully with npm"
                success_with_message "Dependencies updated with npm install"
            else
                log_warn "npm install failed - check package.json syntax"
                success_with_message "Dependency sync failed - check package.json"
            fi
        else
            log_warn "npm not found, skipping dependency sync"
        fi
        ;;
        
    "yarn")
        if command_exists "yarn"; then
            log_info "Running yarn install in $PACKAGE_DIR"
            if yarn install 2>/dev/null; then
                log_success "Dependencies synced successfully with yarn"
                success_with_message "Dependencies updated with yarn install"
            else
                log_warn "yarn install failed - check package.json syntax"
                success_with_message "Dependency sync failed - check package.json"
            fi
        else
            log_warn "yarn not found, falling back to npm"
            if command_exists "npm"; then
                npm install 2>/dev/null && log_success "Dependencies synced with npm (yarn fallback)"
            fi
        fi
        ;;
        
    "pip")
        if command_exists "pip"; then
            log_info "Running pip install -r requirements.txt in $PACKAGE_DIR"
            if pip install -r requirements.txt 2>/dev/null; then
                log_success "Dependencies synced successfully with pip"
                success_with_message "Dependencies updated with pip install"
            else
                log_warn "pip install failed - check requirements.txt syntax"
                success_with_message "Dependency sync failed - check requirements.txt"
            fi
        else
            log_warn "pip not found, skipping dependency sync"
        fi
        ;;
        
    "pipenv")
        if command_exists "pipenv"; then
            log_info "Running pipenv install in $PACKAGE_DIR"
            if pipenv install 2>/dev/null; then
                log_success "Dependencies synced successfully with pipenv"
                success_with_message "Dependencies updated with pipenv install"
            else
                log_warn "pipenv install failed - check Pipfile syntax"
                success_with_message "Dependency sync failed - check Pipfile"
            fi
        else
            log_warn "pipenv not found, skipping dependency sync"
        fi
        ;;
        
    "cargo")
        if command_exists "cargo"; then
            log_info "Running cargo build in $PACKAGE_DIR"
            if cargo build 2>/dev/null; then
                log_success "Dependencies synced successfully with cargo"
                success_with_message "Dependencies updated with cargo build"
            else
                log_warn "cargo build failed - check Cargo.toml syntax"
                success_with_message "Dependency sync failed - check Cargo.toml"
            fi
        else
            log_warn "cargo not found, skipping dependency sync"
        fi
        ;;
        
    "go")
        if command_exists "go"; then
            log_info "Running go mod tidy in $PACKAGE_DIR"
            if go mod tidy 2>/dev/null; then
                log_success "Dependencies synced successfully with go mod"
                success_with_message "Dependencies updated with go mod tidy"
            else
                log_warn "go mod tidy failed - check go.mod syntax"
                success_with_message "Dependency sync failed - check go.mod"
            fi
        else
            log_warn "go not found, skipping dependency sync"
        fi
        ;;
esac

finalize_hook "sync-dependencies" "completed"