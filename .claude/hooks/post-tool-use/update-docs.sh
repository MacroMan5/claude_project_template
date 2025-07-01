#!/bin/bash
# Documentation auto-update hook - updates docs when APIs/functions change
# Keeps documentation in sync with code changes automatically

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "update-docs"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping doc update"
    success_with_message "No doc update needed - file does not exist"
    finalize_hook "update-docs" "skipped"
    exit 0
fi

# Check if this file contains API/function definitions that need documentation
LANGUAGE=$(detect_language "$FILE_PATH")
DOC_UPDATED=false
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

log_info "Checking for documentation updates needed for $FILE_PATH (language: $LANGUAGE)"

# Function to update README.md if it contains API sections
update_readme_if_needed() {
    local readme_path="$PROJECT_DIR/README.md"
    
    if [[ -f "$readme_path" ]]; then
        # Check if README has API documentation sections
        if grep -qi "api\|function\|method\|endpoint" "$readme_path" 2>/dev/null; then
            log_info "README.md contains API documentation - checking if update needed"
            
            # Get the last modified time of the code file and README
            if [[ "$FILE_PATH" -nt "$readme_path" ]]; then
                log_info "Code file is newer than README.md - documentation may need updating"
                echo "# Documentation Update Reminder" >> "$readme_path.update-reminder"
                echo "File $FILE_PATH was modified and may affect API documentation" >> "$readme_path.update-reminder"
                echo "Last updated: $(date)" >> "$readme_path.update-reminder"
                echo "" >> "$readme_path.update-reminder"
                DOC_UPDATED=true
            fi
        fi
    fi
}

# Function to generate API docs for different languages
generate_api_docs() {
    case "$LANGUAGE" in
        "javascript"|"typescript")
            # Check for function exports or API definitions
            if grep -E "(export\s+(function|const|class)|app\.(get|post|put|delete)|router\.)" "$FILE_PATH" >/dev/null 2>&1; then
                log_info "Detected API/function definitions in JavaScript/TypeScript file"
                
                # Try to generate JSDoc if available
                if command_exists "jsdoc"; then
                    local doc_dir="$PROJECT_DIR/docs/api"
                    mkdir -p "$doc_dir"
                    if jsdoc "$FILE_PATH" -d "$doc_dir" 2>/dev/null; then
                        log_success "Generated JSDoc documentation"
                        DOC_UPDATED=true
                    fi
                fi
                
                update_readme_if_needed
            fi
            ;;
            
        "python")
            # Check for function/class definitions or Flask/FastAPI routes
            if grep -E "(def\s+|class\s+|@app\.|@router\.|@api\.)" "$FILE_PATH" >/dev/null 2>&1; then
                log_info "Detected API/function definitions in Python file"
                
                # Try to generate docs with pydoc if available
                if command_exists "pydoc"; then
                    local module_name=$(basename "$FILE_PATH" .py)
                    local doc_dir="$PROJECT_DIR/docs/api"
                    mkdir -p "$doc_dir"
                    if cd "$(dirname "$FILE_PATH")" && pydoc -w "$module_name" 2>/dev/null; then
                        mv "${module_name}.html" "$doc_dir/" 2>/dev/null && {
                            log_success "Generated pydoc documentation"
                            DOC_UPDATED=true
                        }
                    fi
                fi
                
                update_readme_if_needed
            fi
            ;;
            
        "go")
            # Check for function definitions or HTTP handlers
            if grep -E "(func\s+|http\.Handle|mux\.Handle)" "$FILE_PATH" >/dev/null 2>&1; then
                log_info "Detected API/function definitions in Go file"
                
                # Try to generate godoc if in a Go module
                if [[ -f "$PROJECT_DIR/go.mod" ]] && command_exists "go"; then
                    local doc_dir="$PROJECT_DIR/docs/api"
                    mkdir -p "$doc_dir"
                    if cd "$PROJECT_DIR" && go doc -all > "$doc_dir/go-docs.txt" 2>/dev/null; then
                        log_success "Generated Go documentation"
                        DOC_UPDATED=true
                    fi
                fi
                
                update_readme_if_needed
            fi
            ;;
            
        "java")
            # Check for method definitions or Spring annotations
            if grep -E "(public\s+.*\s+\w+\s*\(|@RestController|@RequestMapping)" "$FILE_PATH" >/dev/null 2>&1; then
                log_info "Detected API/method definitions in Java file"
                update_readme_if_needed
            fi
            ;;
            
        "rust")
            # Check for function definitions or web framework annotations
            if grep -E "(fn\s+|#\[get\]|#\[post\]|#\[put\]|#\[delete\])" "$FILE_PATH" >/dev/null 2>&1; then
                log_info "Detected API/function definitions in Rust file"
                
                # Try to generate rustdoc if in a Cargo project
                if [[ -f "$PROJECT_DIR/Cargo.toml" ]] && command_exists "cargo"; then
                    if cd "$PROJECT_DIR" && cargo doc --no-deps 2>/dev/null; then
                        log_success "Generated Rust documentation"
                        DOC_UPDATED=true
                    fi
                fi
                
                update_readme_if_needed
            fi
            ;;
    esac
}

# Check for OpenAPI/Swagger specs
update_openapi_docs() {
    if [[ -f "$PROJECT_DIR/openapi.yaml" ]] || [[ -f "$PROJECT_DIR/swagger.yaml" ]]; then
        local spec_file=""
        [[ -f "$PROJECT_DIR/openapi.yaml" ]] && spec_file="$PROJECT_DIR/openapi.yaml"
        [[ -f "$PROJECT_DIR/swagger.yaml" ]] && spec_file="$PROJECT_DIR/swagger.yaml"
        
        if [[ -n "$spec_file" && "$FILE_PATH" -nt "$spec_file" ]]; then
            log_info "API file is newer than OpenAPI spec - may need updating"
            echo "# OpenAPI Update Reminder" >> "$spec_file.update-reminder"
            echo "File $FILE_PATH was modified and may affect API specification" >> "$spec_file.update-reminder"
            echo "Last updated: $(date)" >> "$spec_file.update-reminder"
            DOC_UPDATED=true
        fi
    fi
}

# Check for package.json changes that affect API
update_package_docs() {
    if [[ "$(basename "$FILE_PATH")" == "package.json" ]]; then
        local readme_path="$PROJECT_DIR/README.md"
        if [[ -f "$readme_path" ]]; then
            # Check if package.json has script changes
            if grep -E "(\"scripts\"|\"dependencies\"|\"devDependencies\")" "$FILE_PATH" >/dev/null 2>&1; then
                log_info "package.json scripts or dependencies changed - README may need updating"
                echo "# Package Update Reminder" >> "$readme_path.update-reminder"
                echo "package.json was modified - check if installation/usage instructions need updating" >> "$readme_path.update-reminder"
                echo "Last updated: $(date)" >> "$readme_path.update-reminder"
                DOC_UPDATED=true
            fi
        fi
    fi
}

# Only run for relevant file types
case "$LANGUAGE" in
    "javascript"|"typescript"|"python"|"go"|"java"|"rust")
        generate_api_docs
        update_openapi_docs
        ;;
    *)
        # Check for special files
        case "$(basename "$FILE_PATH")" in
            "package.json"|"requirements.txt"|"Cargo.toml"|"go.mod")
                update_package_docs
                ;;
            *)
                log_info "File type doesn't typically require documentation updates"
                ;;
        esac
        ;;
esac

# Report results
if $DOC_UPDATED; then
    log_success "Documentation update completed for $FILE_PATH"
    success_with_message "Documentation updated - check docs/ directory or .update-reminder files"
else
    log_info "No documentation updates needed for $FILE_PATH"
    success_with_message "No documentation updates required"
fi

finalize_hook "update-docs" "completed"