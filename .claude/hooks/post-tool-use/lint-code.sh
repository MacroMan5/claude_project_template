#!/bin/bash
# Code linting hook - runs linters after code modifications
# Runs after Edit/Write operations to catch issues early

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "lint-code"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip linting if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping linting"
    success_with_message "No linting needed - file does not exist"
    finalize_hook "lint-code" "skipped"
    exit 0
fi

# Detect language and lint accordingly
LANGUAGE=$(detect_language "$FILE_PATH")
LINT_APPLIED=false
ISSUES_FOUND=false

log_info "Linting $FILE_PATH (detected language: $LANGUAGE)"

case "$LANGUAGE" in
    "python")
        # PyLint
        if command_exists "pylint"; then
            log_info "Running PyLint on $FILE_PATH"
            if ! pylint "$FILE_PATH" --score=no --reports=no 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # Flake8
        if command_exists "flake8"; then
            log_info "Running Flake8 on $FILE_PATH"
            if ! flake8 "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # MyPy for type checking
        if command_exists "mypy"; then
            log_info "Running MyPy on $FILE_PATH"
            if ! mypy "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "javascript"|"typescript")
        # ESLint
        if command_exists "eslint"; then
            log_info "Running ESLint on $FILE_PATH"
            if ! eslint "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # TypeScript compiler check for TS files
        if [[ "$LANGUAGE" == "typescript" ]] && command_exists "tsc"; then
            log_info "Running TypeScript compiler check on $FILE_PATH"
            if ! tsc --noEmit "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "go")
        # Go vet
        if command_exists "go"; then
            log_info "Running go vet on $FILE_PATH"
            if ! go vet "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # golangci-lint
        if command_exists "golangci-lint"; then
            log_info "Running golangci-lint on $FILE_PATH"
            if ! golangci-lint run "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "rust")
        # Clippy
        if command_exists "cargo"; then
            log_info "Running Cargo clippy"
            if ! cargo clippy --quiet 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        ;;
        
    "java")
        # Checkstyle
        if command_exists "checkstyle"; then
            log_info "Running Checkstyle on $FILE_PATH"
            if ! checkstyle "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # SpotBugs for Java projects
        if [[ -f "pom.xml" ]] && command_exists "mvn"; then
            log_info "Running SpotBugs via Maven"
            mvn spotbugs:check -q 2>/dev/null || ISSUES_FOUND=true
        fi
        ;;
        
    "cpp"|"c")
        # clang-tidy
        if command_exists "clang-tidy"; then
            log_info "Running clang-tidy on $FILE_PATH"
            if ! clang-tidy "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # cppcheck
        if command_exists "cppcheck"; then
            log_info "Running cppcheck on $FILE_PATH"
            if ! cppcheck "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "ruby")
        # RuboCop
        if command_exists "rubocop"; then
            log_info "Running RuboCop on $FILE_PATH"
            if ! rubocop "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        ;;
        
    "php")
        # PHP_CodeSniffer
        if command_exists "phpcs"; then
            log_info "Running PHP_CodeSniffer on $FILE_PATH"
            if ! phpcs "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        
        # PHPStan
        if command_exists "phpstan"; then
            log_info "Running PHPStan on $FILE_PATH"
            if ! phpstan analyse "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "swift")
        # SwiftLint
        if command_exists "swiftlint"; then
            log_info "Running SwiftLint on $FILE_PATH"
            if ! swiftlint lint "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        ;;
        
    "kotlin")
        # detekt
        if command_exists "detekt"; then
            log_info "Running detekt on $FILE_PATH"
            if ! detekt --input "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        ;;
        
    "shell")
        # ShellCheck
        if command_exists "shellcheck"; then
            log_info "Running ShellCheck on $FILE_PATH"
            if ! shellcheck "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
            LINT_APPLIED=true
        fi
        ;;
        
    *)
        log_info "No linter available for language: $LANGUAGE"
        ;;
esac

# Additional linting for specific file types
case "$(get_file_extension "$FILE_PATH")" in
    "json")
        # JSON syntax validation
        if command_exists "jq"; then
            log_info "Validating JSON syntax with jq"
            if ! jq '.' "$FILE_PATH" >/dev/null 2>&1; then
                log_warn "JSON syntax errors found in $FILE_PATH"
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "yml"|"yaml")
        # YAML syntax validation
        if command_exists "yamllint"; then
            log_info "Running yamllint on $FILE_PATH"
            if ! yamllint "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        elif command_exists "yq"; then
            log_info "Validating YAML syntax with yq"
            if ! yq eval '.' "$FILE_PATH" >/dev/null 2>&1; then
                log_warn "YAML syntax errors found in $FILE_PATH"
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "xml")
        # XML syntax validation
        if command_exists "xmllint"; then
            log_info "Validating XML syntax with xmllint"
            if ! xmllint --noout "$FILE_PATH" 2>/dev/null; then
                log_warn "XML syntax errors found in $FILE_PATH"
                ISSUES_FOUND=true
            fi
        fi
        ;;
        
    "dockerfile"|"Dockerfile")
        # Dockerfile linting
        if command_exists "hadolint"; then
            log_info "Running Hadolint on $FILE_PATH"
            if ! hadolint "$FILE_PATH" 2>/dev/null; then
                ISSUES_FOUND=true
            fi
        fi
        ;;
esac

# Report results
if $LINT_APPLIED; then
    if $ISSUES_FOUND; then
        log_warn "Linting completed for $FILE_PATH - issues found (check output above)"
        success_with_message "Linting completed - please review issues"
    else
        log_success "Linting completed for $FILE_PATH - no issues found"
        success_with_message "Linting passed successfully"
    fi
else
    log_info "No linting performed for $FILE_PATH (no linters available)"
    success_with_message "No linting tools available for this file type"
fi

finalize_hook "lint-code" "completed"