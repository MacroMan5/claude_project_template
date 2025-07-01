#!/bin/bash
# Code formatting hook - auto-formats code after modifications
# Runs after Edit/Write operations to ensure consistent code style

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "format-code"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip formatting if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping formatting"
    success_with_message "No formatting needed - file does not exist"
    finalize_hook "format-code" "skipped"
    exit 0
fi

# Detect language and format accordingly
LANGUAGE=$(detect_language "$FILE_PATH")
FORMAT_APPLIED=false

log_info "Formatting $FILE_PATH (detected language: $LANGUAGE)"

case "$LANGUAGE" in
    "python")
        if command_exists "black"; then
            log_info "Running Black formatter on $FILE_PATH"
            black "$FILE_PATH" --quiet 2>/dev/null && FORMAT_APPLIED=true
        fi
        
        if command_exists "isort"; then
            log_info "Running isort on $FILE_PATH"
            isort "$FILE_PATH" --quiet 2>/dev/null
        fi
        
        if command_exists "autopep8"; then
            log_info "Running autopep8 on $FILE_PATH"
            autopep8 --in-place "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "javascript"|"typescript")
        if command_exists "prettier"; then
            log_info "Running Prettier on $FILE_PATH"
            prettier --write "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        
        if command_exists "eslint"; then
            log_info "Running ESLint auto-fix on $FILE_PATH"
            eslint --fix "$FILE_PATH" 2>/dev/null
        fi
        ;;
        
    "go")
        if command_exists "gofmt"; then
            log_info "Running gofmt on $FILE_PATH"
            gofmt -w "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        
        if command_exists "goimports"; then
            log_info "Running goimports on $FILE_PATH"
            goimports -w "$FILE_PATH" 2>/dev/null
        fi
        ;;
        
    "rust")
        if command_exists "rustfmt"; then
            log_info "Running rustfmt on $FILE_PATH"
            rustfmt "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "java")
        if command_exists "google-java-format"; then
            log_info "Running google-java-format on $FILE_PATH"
            google-java-format --replace "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "cpp"|"c")
        if command_exists "clang-format"; then
            log_info "Running clang-format on $FILE_PATH"
            clang-format -i "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "ruby")
        if command_exists "rubocop"; then
            log_info "Running RuboCop auto-correct on $FILE_PATH"
            rubocop --auto-correct "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "php")
        if command_exists "php-cs-fixer"; then
            log_info "Running PHP CS Fixer on $FILE_PATH"
            php-cs-fixer fix "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "swift")
        if command_exists "swift-format"; then
            log_info "Running swift-format on $FILE_PATH"
            swift-format --in-place "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "kotlin")
        if command_exists "ktlint"; then
            log_info "Running ktlint format on $FILE_PATH"
            ktlint --format "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    "shell")
        if command_exists "shfmt"; then
            log_info "Running shfmt on $FILE_PATH"
            shfmt -w "$FILE_PATH" 2>/dev/null && FORMAT_APPLIED=true
        fi
        ;;
        
    *)
        log_info "No formatter available for language: $LANGUAGE"
        ;;
esac

# Additional formatting for specific file types
FORMAT_BY_EXTENSION=false

case "$(get_file_extension "$FILE_PATH")" in
    "json")
        if command_exists "jq"; then
            log_info "Formatting JSON file with jq"
            temp_file=$(mktemp)
            jq '.' "$FILE_PATH" > "$temp_file" 2>/dev/null && mv "$temp_file" "$FILE_PATH" && FORMAT_BY_EXTENSION=true
        fi
        ;;
        
    "xml")
        if command_exists "xmllint"; then
            log_info "Formatting XML file with xmllint"
            temp_file=$(mktemp)
            xmllint --format "$FILE_PATH" > "$temp_file" 2>/dev/null && mv "$temp_file" "$FILE_PATH" && FORMAT_BY_EXTENSION=true
        fi
        ;;
        
    "yml"|"yaml")
        if command_exists "yq"; then
            log_info "Formatting YAML file with yq"
            temp_file=$(mktemp)
            yq eval '.' "$FILE_PATH" > "$temp_file" 2>/dev/null && mv "$temp_file" "$FILE_PATH" && FORMAT_BY_EXTENSION=true
        fi
        ;;
esac

# Report results
if $FORMAT_APPLIED || $FORMAT_BY_EXTENSION; then
    log_success "Code formatting applied to $FILE_PATH"
    success_with_message "Code formatting completed successfully"
else
    log_info "No formatting applied to $FILE_PATH (no formatter available or no changes needed)"
    success_with_message "No formatting changes needed"
fi

finalize_hook "format-code" "completed"