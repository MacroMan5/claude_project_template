#!/bin/bash
# Test runner hook - runs relevant tests after code modifications
# Runs after Edit/Write operations to ensure changes don't break functionality

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "run-tests"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_info "File $FILE_PATH does not exist, skipping tests"
    success_with_message "No tests needed - file does not exist"
    finalize_hook "run-tests" "skipped"
    exit 0
fi

# Function to find and run Python tests
run_python_tests() {
    local file_path="$1"
    local test_files=()
    
    # Look for test files related to the modified file
    local base_name=$(basename "$file_path" .py)
    local dir_name=$(dirname "$file_path")
    
    # Common test file patterns
    local test_patterns=(
        "test_${base_name}.py"
        "${base_name}_test.py" 
        "tests/test_${base_name}.py"
        "tests/${base_name}_test.py"
        "test/${base_name}_test.py"
    )
    
    for pattern in "${test_patterns[@]}"; do
        if [[ -f "$pattern" ]]; then
            test_files+=("$pattern")
        fi
    done
    
    # If no specific test files found, look for test directories
    if [[ ${#test_files[@]} -eq 0 ]]; then
        if [[ -d "tests" ]]; then
            log_info "Running all tests in tests/ directory"
            if command_exists "pytest"; then
                pytest tests/ -v --tb=short 2>/dev/null || log_warn "Some tests failed"
            elif command_exists "python"; then
                python -m unittest discover tests/ 2>/dev/null || log_warn "Some tests failed"
            fi
            return
        fi
    fi
    
    # Run specific test files
    for test_file in "${test_files[@]}"; do
        log_info "Running tests from $test_file"
        if command_exists "pytest"; then
            pytest "$test_file" -v --tb=short 2>/dev/null || log_warn "Tests failed in $test_file"
        elif command_exists "python"; then
            python -m unittest "$test_file" 2>/dev/null || log_warn "Tests failed in $test_file"
        fi
    done
}

# Function to run JavaScript/TypeScript tests
run_js_tests() {
    local file_path="$1"
    local base_name=$(basename "$file_path")
    local base_name_no_ext="${base_name%.*}"
    
    # Look for test files
    local test_patterns=(
        "${base_name_no_ext}.test.js"
        "${base_name_no_ext}.test.ts"
        "${base_name_no_ext}.spec.js"
        "${base_name_no_ext}.spec.ts"
        "tests/${base_name_no_ext}.test.js"
        "tests/${base_name_no_ext}.test.ts"
        "__tests__/${base_name_no_ext}.test.js"
        "__tests__/${base_name_no_ext}.test.ts"
    )
    
    local test_files=()
    for pattern in "${test_patterns[@]}"; do
        if [[ -f "$pattern" ]]; then
            test_files+=("$pattern")
        fi
    done
    
    if [[ ${#test_files[@]} -gt 0 ]]; then
        for test_file in "${test_files[@]}"; do
            log_info "Running tests from $test_file"
            if command_exists "npm"; then
                npm test "$test_file" 2>/dev/null || log_warn "Tests failed in $test_file"
            elif command_exists "jest"; then
                jest "$test_file" 2>/dev/null || log_warn "Tests failed in $test_file"
            fi
        done
    else
        # Run all tests if no specific test file found
        if [[ -f "package.json" ]] && command_exists "npm"; then
            log_info "Running npm test suite"
            npm test 2>/dev/null || log_warn "Some npm tests failed"
        fi
    fi
}

# Function to run Go tests
run_go_tests() {
    local file_path="$1"
    local dir_name=$(dirname "$file_path")
    local base_name=$(basename "$file_path" .go)
    
    # Look for test files in the same directory
    local test_file="${dir_name}/${base_name}_test.go"
    
    if [[ -f "$test_file" ]]; then
        log_info "Running Go tests from $test_file"
        if command_exists "go"; then
            go test "$test_file" "$file_path" 2>/dev/null || log_warn "Go tests failed"
        fi
    else
        # Run all tests in the package
        log_info "Running all Go tests in package"
        if command_exists "go"; then
            (cd "$dir_name" && go test 2>/dev/null) || log_warn "Some Go tests failed"
        fi
    fi
}

# Function to run Rust tests
run_rust_tests() {
    local file_path="$1"
    
    # Check if this is a Rust project
    if [[ -f "Cargo.toml" ]] && command_exists "cargo"; then
        log_info "Running Cargo tests"
        cargo test 2>/dev/null || log_warn "Some Cargo tests failed"
    fi
}

# Function to run Java tests
run_java_tests() {
    local file_path="$1"
    
    # Maven project
    if [[ -f "pom.xml" ]] && command_exists "mvn"; then
        log_info "Running Maven tests"
        mvn test -q 2>/dev/null || log_warn "Some Maven tests failed"
    # Gradle project
    elif [[ -f "build.gradle" ]] && command_exists "gradle"; then
        log_info "Running Gradle tests"
        gradle test -q 2>/dev/null || log_warn "Some Gradle tests failed"
    fi
}

# Determine test strategy based on file type and project structure
LANGUAGE=$(detect_language "$FILE_PATH")
TESTS_RUN=false

log_info "Determining test strategy for $FILE_PATH (language: $LANGUAGE)"

# Skip test files themselves
if echo "$FILE_PATH" | grep -E "(test|spec)" >/dev/null 2>&1; then
    log_info "Skipping test execution for test file itself"
    success_with_message "Skipped - target file is a test file"
    finalize_hook "run-tests" "skipped"
    exit 0
fi

# Run tests based on language
case "$LANGUAGE" in
    "python")
        run_python_tests "$FILE_PATH"
        TESTS_RUN=true
        ;;
    "javascript"|"typescript")
        run_js_tests "$FILE_PATH"
        TESTS_RUN=true
        ;;
    "go")
        run_go_tests "$FILE_PATH"
        TESTS_RUN=true
        ;;
    "rust")
        run_rust_tests "$FILE_PATH"
        TESTS_RUN=true
        ;;
    "java")
        run_java_tests "$FILE_PATH"
        TESTS_RUN=true
        ;;
    *)
        log_info "No test runner configured for language: $LANGUAGE"
        ;;
esac

# Run any general project tests if available
if ! $TESTS_RUN; then
    # Check for common test commands
    if [[ -f "Makefile" ]] && grep -q "test:" Makefile; then
        log_info "Running Makefile test target"
        make test 2>/dev/null || log_warn "Make tests failed"
        TESTS_RUN=true
    elif [[ -f "package.json" ]] && command_exists "npm"; then
        if grep -q '"test"' package.json; then
            log_info "Running npm test"
            npm test 2>/dev/null || log_warn "npm tests failed"
            TESTS_RUN=true
        fi
    fi
fi

# Report results
if $TESTS_RUN; then
    log_success "Test execution completed for $FILE_PATH"
    success_with_message "Tests executed successfully"
else
    log_info "No tests executed for $FILE_PATH"
    success_with_message "No applicable tests found"
fi

finalize_hook "run-tests" "completed"