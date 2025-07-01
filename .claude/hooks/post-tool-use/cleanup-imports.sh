#!/bin/bash
# Import cleanup hook - removes unused imports and sorts import statements
# Keeps code clean by automatically managing imports after edits

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "cleanup-imports"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping import cleanup"
    success_with_message "No import cleanup needed - file does not exist"
    finalize_hook "cleanup-imports" "skipped"
    exit 0
fi

# Detect language and check if it has imports
LANGUAGE=$(detect_language "$FILE_PATH")
CLEANUP_APPLIED=false

log_info "Checking imports in $FILE_PATH (detected language: $LANGUAGE)"

# Function to backup file before cleanup
backup_imports() {
    local backup_dir="$(dirname "$FILE_PATH")/.import-backups"
    mkdir -p "$backup_dir"
    cp "$FILE_PATH" "$backup_dir/$(basename "$FILE_PATH").$(date +%s).bak" 2>/dev/null
}

case "$LANGUAGE" in
    "python")
        # Python import cleanup with isort and autoflake
        if command_exists "isort"; then
            log_info "Sorting Python imports with isort"
            if isort "$FILE_PATH" --quiet 2>/dev/null; then
                log_success "Python imports sorted successfully"
                CLEANUP_APPLIED=true
            fi
        fi
        
        # Remove unused imports with autoflake
        if command_exists "autoflake"; then
            log_info "Removing unused Python imports with autoflake"
            backup_imports
            if autoflake --remove-all-unused-imports --in-place "$FILE_PATH" 2>/dev/null; then
                log_success "Unused Python imports removed"
                CLEANUP_APPLIED=true
            fi
        fi
        
        # Alternative: Manual unused import detection
        if ! command_exists "autoflake" && command_exists "python3"; then
            log_info "Checking for unused imports manually"
            # Simple unused import check (basic implementation)
            python3 -c "
import ast
import sys

with open('$FILE_PATH', 'r') as f:
    content = f.read()

try:
    tree = ast.parse(content)
    imports = []
    used_names = set()
    
    # Collect imports
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports.append(alias.name.split('.')[0])
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports.append(node.module.split('.')[0])
            for alias in node.names:
                imports.append(alias.name)
    
    # Collect used names (simplified)
    for node in ast.walk(tree):
        if isinstance(node, ast.Name):
            used_names.add(node.id)
    
    # Find potentially unused imports
    unused = [imp for imp in imports if imp not in used_names and not imp.startswith('_')]
    if unused:
        print(f'Potentially unused imports: {unused}')
    
except Exception as e:
    pass
" 2>/dev/null
        fi
        ;;
        
    "javascript"|"typescript")
        # JavaScript/TypeScript import cleanup
        
        # Sort imports with eslint if available
        if command_exists "eslint"; then
            log_info "Fixing JavaScript/TypeScript imports with ESLint"
            if eslint --fix --quiet "$FILE_PATH" 2>/dev/null; then
                log_success "JavaScript/TypeScript imports fixed with ESLint"
                CLEANUP_APPLIED=true
            fi
        fi
        
        # Use typescript compiler to check unused imports
        if [[ "$LANGUAGE" == "typescript" ]] && command_exists "tsc"; then
            log_info "Checking TypeScript for unused imports"
            # TypeScript compiler can detect unused imports
            tsc --noEmit --noUnusedLocals "$FILE_PATH" 2>/dev/null | grep -i "unused" && {
                log_warn "TypeScript detected unused imports - consider manual cleanup"
            }
        fi
        
        # Manual import sorting (basic)
        if ! command_exists "eslint"; then
            log_info "Performing basic import sorting"
            # Simple sort of import statements at the top of the file
            python3 -c "
import re

with open('$FILE_PATH', 'r') as f:
    lines = f.readlines()

imports = []
other_lines = []
import_section = True

for line in lines:
    if re.match(r'^(import|from)\s+', line.strip()):
        if import_section:
            imports.append(line)
        else:
            other_lines.append(line)
    elif line.strip() == '':
        if import_section and imports:
            other_lines.append(line)
        elif import_section:
            imports.append(line)
        else:
            other_lines.append(line)
    else:
        import_section = False
        other_lines.append(line)

if imports:
    imports.sort()
    with open('$FILE_PATH', 'w') as f:
        f.writelines(imports)
        f.writelines(other_lines)
    print('Imports sorted')
" 2>/dev/null && {
                log_success "Basic import sorting completed"
                CLEANUP_APPLIED=true
            }
        fi
        ;;
        
    "go")
        # Go import cleanup
        if command_exists "goimports"; then
            log_info "Cleaning Go imports with goimports"
            backup_imports
            if goimports -w "$FILE_PATH" 2>/dev/null; then
                log_success "Go imports cleaned successfully"
                CLEANUP_APPLIED=true
            fi
        elif command_exists "go"; then
            log_info "Formatting Go imports with go fmt"
            if go fmt "$FILE_PATH" 2>/dev/null; then
                log_success "Go imports formatted"
                CLEANUP_APPLIED=true
            fi
        fi
        ;;
        
    "rust")
        # Rust doesn't have automatic unused import removal, but we can check
        if command_exists "cargo"; then
            local project_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            if [[ -f "$project_root/Cargo.toml" ]]; then
                log_info "Checking Rust file with cargo check"
                cd "$project_root" && cargo check --quiet 2>/dev/null | grep -i "unused" && {
                    log_warn "Rust detected unused imports - consider manual cleanup"
                }
            fi
        fi
        ;;
        
    "java")
        # Java import organization
        if command_exists "google-java-format"; then
            log_info "Organizing Java imports with google-java-format"
            backup_imports
            if google-java-format --replace "$FILE_PATH" 2>/dev/null; then
                log_success "Java imports organized"
                CLEANUP_APPLIED=true
            fi
        fi
        ;;
        
    "swift")
        # Swift import cleanup (basic check)
        if command_exists "swiftlint"; then
            log_info "Checking Swift imports with SwiftLint"
            swiftlint --quiet "$FILE_PATH" 2>/dev/null | grep -i "import" && {
                log_info "SwiftLint detected import issues"
            }
        fi
        ;;
        
    *)
        log_info "Import cleanup not available for language: $LANGUAGE"
        ;;
esac

# Additional cleanup for common file types
case "$(get_file_extension "$FILE_PATH")" in
    "css"|"scss")
        # CSS import cleanup (basic)
        if grep -q "@import" "$FILE_PATH" 2>/dev/null; then
            log_info "CSS file contains @import statements"
            # Basic @import sorting
            python3 -c "
import re

with open('$FILE_PATH', 'r') as f:
    content = f.read()

imports = re.findall(r'^@import.*?;$', content, re.MULTILINE)
other_content = re.sub(r'^@import.*?;$', '', content, flags=re.MULTILINE)

if imports:
    imports.sort()
    new_content = '\\n'.join(imports) + '\\n' + other_content
    with open('$FILE_PATH', 'w') as f:
        f.write(new_content)
    print('CSS imports sorted')
" 2>/dev/null && {
                log_success "CSS imports sorted"
                CLEANUP_APPLIED=true
            }
        fi
        ;;
esac

# Report results
if $CLEANUP_APPLIED; then
    log_success "Import cleanup completed for $FILE_PATH"
    success_with_message "Imports cleaned and organized"
else
    log_info "No import cleanup performed for $FILE_PATH"
    success_with_message "No import cleanup needed or tools unavailable"
fi

finalize_hook "cleanup-imports" "completed"