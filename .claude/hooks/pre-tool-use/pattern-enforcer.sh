#!/bin/bash
# Code Pattern Enforcer hook - enforces consistency patterns in large codebases
# Prevents anti-patterns and enforces team coding standards

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "pattern-enforcer"

# Validate parameters - this is a pre-tool-use hook
if [[ $# -lt 1 ]]; then
    log_warn "No parameters provided to pattern enforcer"
    success_with_message "No pattern enforcement needed"
    finalize_hook "pattern-enforcer" "skipped"
    exit 0
fi

TOOL_NAME="$1"
shift
TOOL_ARGS="$@"

# Only enforce patterns for Edit/Write operations
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "MultiEdit" ]]; then
    success_with_message "Pattern enforcement not applicable"
    finalize_hook "pattern-enforcer" "skipped"
    exit 0
fi

# Extract file path from arguments
FILE_PATH=""
CONTENT=""
for arg in $TOOL_ARGS; do
    if [[ -f "$arg" ]] || [[ "$arg" == *"/"* ]]; then
        FILE_PATH="$arg"
        break
    fi
done

if [[ -z "$FILE_PATH" ]]; then
    log_info "No file path found in arguments, skipping pattern enforcement"
    success_with_message "No file to check"
    finalize_hook "pattern-enforcer" "skipped"
    exit 0
fi

# Get project root and detect language
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RELATIVE_PATH=$(realpath --relative-to="$PROJECT_ROOT" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
LANGUAGE=$(detect_language "$FILE_PATH")

log_info "Enforcing code patterns for $RELATIVE_PATH (language: $LANGUAGE)"

# Pattern violation tracking
VIOLATIONS=()
WARNINGS=()
AUTO_FIXES=()

# Function to add violation
add_violation() {
    local severity="$1"
    local message="$2"
    local fix="$3"
    
    case "$severity" in
        "ERROR")
            VIOLATIONS+=("❌ $message")
            ;;
        "WARNING")
            WARNINGS+=("⚠️  $message")
            ;;
        "INFO")
            AUTO_FIXES+=("💡 $message")
            ;;
    esac
    
    if [[ -n "$fix" ]]; then
        AUTO_FIXES+=("🔧 Auto-fix: $fix")
    fi
}

# Function to check JavaScript/TypeScript patterns
check_js_ts_patterns() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    local content=$(cat "$file_path" 2>/dev/null || echo "")
    
    # Check for inline styles in React components
    if [[ "$file_path" == *.jsx ]] || [[ "$file_path" == *.tsx ]]; then
        if echo "$content" | grep -q "style={{" && [[ "$file_path" != *.stories.* ]]; then
            add_violation "WARNING" "Inline styles detected in React component" "Use CSS modules or styled-components"
        fi
        
        # Check for proper component naming (PascalCase)
        local component_name=$(basename "$file_path" | cut -d. -f1)
        if [[ ! "$component_name" =~ ^[A-Z][a-zA-Z0-9]*$ ]] && [[ "$file_path" == *"/components/"* ]]; then
            add_violation "WARNING" "Component file should use PascalCase naming" "Rename to ${component_name^}.tsx"
        fi
        
        # Check for missing key prop in lists
        if echo "$content" | grep -q "\.map(" && ! echo "$content" | grep -q "key="; then
            add_violation "ERROR" "Missing key prop in list rendering" "Add unique key prop to list items"
        fi
        
        # Check for proper prop types or TypeScript interfaces
        if [[ "$file_path" == *.jsx ]] && ! echo "$content" | grep -q "PropTypes"; then
            add_violation "WARNING" "Missing PropTypes in React component" "Add PropTypes or convert to TypeScript"
        fi
    fi
    
    # Check for deep relative imports
    if echo "$content" | grep -E "from ['\"](\.\.[/\\\\]){3,}" >/dev/null; then
        add_violation "ERROR" "Deep relative imports detected" "Use absolute imports (@/components) instead"
    fi
    
    # Check for console.log in production files
    if echo "$content" | grep -q "console\.log" && [[ "$file_path" != *"test"* ]] && [[ "$file_path" != *"spec"* ]]; then
        add_violation "WARNING" "console.log detected in production code" "Remove console.log or use proper logging"
    fi
    
    # Check for TODO/FIXME comments
    local todo_count=$(echo "$content" | grep -c -i "TODO\|FIXME" || echo "0")
    if [[ $todo_count -gt 3 ]]; then
        add_violation "INFO" "High number of TODO/FIXME comments ($todo_count)" "Consider creating issues for todos"
    fi
    
    # Check for proper error handling
    if echo "$content" | grep -q "fetch\|axios" && ! echo "$content" | grep -q "catch\|try"; then
        add_violation "WARNING" "API calls without error handling detected" "Add proper error handling"
    fi
    
    # Check for hardcoded URLs/secrets
    if echo "$content" | grep -E "(http://|https://)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" >/dev/null; then
        add_violation "ERROR" "Hardcoded URLs detected" "Use environment variables or config files"
    fi
    
    # TypeScript specific checks
    if [[ "$file_path" == *.ts ]] || [[ "$file_path" == *.tsx ]]; then
        # Check for 'any' type usage
        local any_count=$(echo "$content" | grep -c ": any\|<any>" || echo "0")
        if [[ $any_count -gt 0 ]]; then
            add_violation "WARNING" "Found $any_count uses of 'any' type" "Use specific types instead of any"
        fi
        
        # Check for missing return types on functions
        if echo "$content" | grep -E "function [a-zA-Z_]+\([^)]*\)\s*{" >/dev/null && ! echo "$content" | grep -E "function [a-zA-Z_]+\([^)]*\):\s*[a-zA-Z]+" >/dev/null; then
            add_violation "INFO" "Functions missing explicit return types" "Add return type annotations"
        fi
    fi
}

# Function to check Python patterns
check_python_patterns() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    local content=$(cat "$file_path" 2>/dev/null || echo "")
    
    # Check for proper imports organization
    if echo "$content" | grep -E "^import.*" >/dev/null && echo "$content" | grep -E "^from.*" >/dev/null; then
        local import_section=$(echo "$content" | sed -n '/^import\|^from/p')
        if ! echo "$import_section" | grep -E "^import.*" | head -1 >/dev/null || ! echo "$import_section" | grep -E "^from.*" | tail -1 >/dev/null; then
            add_violation "INFO" "Imports not properly organized" "Group standard library, third-party, and local imports"
        fi
    fi
    
    # Check for missing docstrings in functions/classes
    if echo "$content" | grep -E "^def |^class " >/dev/null; then
        local functions_classes=$(echo "$content" | grep -c -E "^def |^class " || echo "0")
        local docstrings=$(echo "$content" | grep -c '"""' || echo "0")
        if [[ $functions_classes -gt $((docstrings / 2)) ]]; then
            add_violation "WARNING" "Missing docstrings in functions/classes" "Add docstrings for public APIs"
        fi
    fi
    
    # Check for hardcoded values
    if echo "$content" | grep -E "password\s*=\s*['\"][^'\"]+['\"]|api_key\s*=\s*['\"][^'\"]+['\"]" >/dev/null; then
        add_violation "ERROR" "Hardcoded credentials detected" "Use environment variables"
    fi
    
    # Check for proper exception handling
    if echo "$content" | grep -q "except:" && ! echo "$content" | grep -q "except Exception:"; then
        add_violation "WARNING" "Bare except clause detected" "Catch specific exceptions"
    fi
    
    # Check for print statements in production code
    if echo "$content" | grep -q "print(" && [[ "$file_path" != *"test"* ]]; then
        add_violation "WARNING" "print() statements in production code" "Use logging instead of print"
    fi
}

# Function to check Go patterns
check_go_patterns() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    local content=$(cat "$file_path" 2>/dev/null || echo "")
    
    # Check for proper error handling
    if echo "$content" | grep -q "_, err :=" && ! echo "$content" | grep -q "if err != nil"; then
        add_violation "ERROR" "Error not handled properly" "Check and handle all errors"
    fi
    
    # Check for proper package naming
    local package_name=$(echo "$content" | grep -E "^package " | cut -d' ' -f2)
    if [[ -n "$package_name" ]] && [[ "$package_name" =~ [A-Z] ]]; then
        add_violation "WARNING" "Package name contains uppercase letters" "Use lowercase package names"
    fi
    
    # Check for proper function naming (exported functions should be capitalized)
    if echo "$content" | grep -E "^func [a-z]" >/dev/null && [[ "$file_path" != *"_test.go" ]]; then
        add_violation "INFO" "Unexported functions detected" "Consider if functions should be exported"
    fi
}

# Function to check general patterns across all languages
check_general_patterns() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    local content=$(cat "$file_path" 2>/dev/null || echo "")
    local file_size=$(wc -c < "$file_path" 2>/dev/null || echo "0")
    local line_count=$(wc -l < "$file_path" 2>/dev/null || echo "0")
    
    # Check file size
    if [[ $file_size -gt 50000 ]]; then  # 50KB
        add_violation "WARNING" "Large file detected ($(($file_size / 1024))KB)" "Consider splitting into smaller modules"
    fi
    
    # Check line count
    if [[ $line_count -gt 500 ]]; then
        add_violation "WARNING" "Long file detected ($line_count lines)" "Consider breaking into smaller files"
    fi
    
    # Check for trailing whitespace
    if grep -q " $" "$file_path" 2>/dev/null; then
        add_violation "INFO" "Trailing whitespace detected" "Remove trailing whitespace"
    fi
    
    # Check for mixed line endings
    if command_exists "file" && file "$file_path" | grep -q "CRLF"; then
        add_violation "INFO" "Windows line endings detected" "Use Unix line endings (LF)"
    fi
    
    # Check for tabs vs spaces (if it's a code file)
    if echo "$content" | grep -q $'\t' && echo "$content" | grep -q "^    "; then
        add_violation "WARNING" "Mixed tabs and spaces for indentation" "Use consistent indentation (spaces recommended)"
    fi
}

# Function to check project structure patterns
check_project_structure() {
    local file_path="$1"
    
    # Check if files are in appropriate directories
    case "$RELATIVE_PATH" in
        *"/test/"*|*"/tests/"*)
            if [[ "$file_path" != *"test"* ]] && [[ "$file_path" != *"spec"* ]]; then
                add_violation "WARNING" "Non-test file in test directory" "Move to appropriate directory"
            fi
            ;;
        *"/components/"*)
            if [[ "$LANGUAGE" == "javascript" || "$LANGUAGE" == "typescript" ]]; then
                if [[ "$file_path" != *.jsx ]] && [[ "$file_path" != *.tsx ]] && [[ "$file_path" != *.vue ]]; then
                    add_violation "INFO" "Non-component file in components directory" "Consider appropriate directory"
                fi
            fi
            ;;
        *"/utils/"*|*"/helpers/"*)
            if echo "$content" | grep -q "export default" && [[ "$LANGUAGE" == "javascript" || "$LANGUAGE" == "typescript" ]]; then
                add_violation "INFO" "Default export in utility file" "Consider named exports for utilities"
            fi
            ;;
    esac
}

# Main pattern enforcement execution
case "$LANGUAGE" in
    "javascript"|"typescript")
        check_js_ts_patterns "$FILE_PATH"
        ;;
    "python")
        check_python_patterns "$FILE_PATH"
        ;;
    "go")
        check_go_patterns "$FILE_PATH"
        ;;
esac

# Always check general patterns
check_general_patterns "$FILE_PATH"
check_project_structure "$FILE_PATH"

# Store patterns in Neo4j for learning
if command_exists "python3" && [[ ${#VIOLATIONS[@]} -gt 0 || ${#WARNINGS[@]} -gt 0 ]]; then
    local pattern_data="{"
    pattern_data+="\"file\": \"$RELATIVE_PATH\","
    pattern_data+="\"violations\": [\"$(IFS='","'; echo "${VIOLATIONS[*]}")\"],"
    pattern_data+="\"warnings\": [\"$(IFS='","'; echo "${WARNINGS[*]}")\"],"
    pattern_data+="\"timestamp\": \"$(date -Iseconds)\""
    pattern_data+="}"
    
    python3 "$(dirname "$0")/../utils/neo4j_mcp.py" store_pattern_violations "$RELATIVE_PATH" "$pattern_data" 2>/dev/null || true
fi

# Report results
TOTAL_ISSUES=$((${#VIOLATIONS[@]} + ${#WARNINGS[@]}))

if [[ $TOTAL_ISSUES -gt 0 ]]; then
    echo ""
    echo "## 🔍 Code Pattern Analysis for $RELATIVE_PATH"
    echo ""
    
    if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
        echo "**❌ Violations (${#VIOLATIONS[@]}):**"
        for violation in "${VIOLATIONS[@]}"; do
            echo "  $violation"
        done
        echo ""
    fi
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "**⚠️  Warnings (${#WARNINGS[@]}):**"
        for warning in "${WARNINGS[@]}"; do
            echo "  $warning"
        done
        echo ""
    fi
    
    if [[ ${#AUTO_FIXES[@]} -gt 0 ]]; then
        echo "**💡 Suggestions:**"
        for fix in "${AUTO_FIXES[@]}"; do
            echo "  $fix"
        done
        echo ""
    fi
    
    if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
        log_warn "Pattern enforcement found ${#VIOLATIONS[@]} violations and ${#WARNINGS[@]} warnings"
        success_with_message "Pattern violations detected - please review"
    else
        log_info "Pattern enforcement found ${#WARNINGS[@]} warnings"
        success_with_message "Pattern warnings noted"
    fi
else
    log_success "No pattern violations detected in $RELATIVE_PATH"
    success_with_message "Pattern enforcement passed"
fi

finalize_hook "pattern-enforcer" "completed"