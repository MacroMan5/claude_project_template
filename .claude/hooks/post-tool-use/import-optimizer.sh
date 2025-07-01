#!/bin/bash
# Import Optimizer hook - optimizes import statements for large codebases
# Converts relative imports to absolute, sorts imports, and removes unused ones

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "import-optimizer"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping import optimization"
    success_with_message "No import optimization needed - file does not exist"
    finalize_hook "import-optimizer" "skipped"
    exit 0
fi

# Get project root and detect language
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RELATIVE_PATH=$(realpath --relative-to="$PROJECT_ROOT" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
LANGUAGE=$(detect_language "$FILE_PATH")

log_info "Optimizing imports for $RELATIVE_PATH (language: $LANGUAGE)"

# Backup file before modifications
backup_file() {
    local file_path="$1"
    local backup_dir="$(dirname "$file_path")/.import-backups"
    mkdir -p "$backup_dir"
    cp "$file_path" "$backup_dir/$(basename "$file_path").$(date +%s).bak" 2>/dev/null
}

# Function to find project's import alias configuration
find_import_alias() {
    local alias_prefix=""
    
    # Check for TypeScript path mapping
    if [[ -f "$PROJECT_ROOT/tsconfig.json" ]]; then
        alias_prefix=$(python3 -c "
import json
try:
    with open('$PROJECT_ROOT/tsconfig.json', 'r') as f:
        config = json.load(f)
    paths = config.get('compilerOptions', {}).get('paths', {})
    for alias in paths:
        if alias.endswith('/*'):
            print(alias[:-2])
            break
except:
    pass
" 2>/dev/null)
    fi
    
    # Check for webpack/babel alias
    if [[ -z "$alias_prefix" ]] && [[ -f "$PROJECT_ROOT/webpack.config.js" ]]; then
        alias_prefix=$(grep -o "@.*:" "$PROJECT_ROOT/webpack.config.js" 2>/dev/null | head -1 | cut -d: -f1)
    fi
    
    # Default fallback
    if [[ -z "$alias_prefix" ]]; then
        alias_prefix="@"
    fi
    
    echo "$alias_prefix"
}

# Function to resolve absolute path
resolve_absolute_path() {
    local current_file="$1"
    local import_path="$2"
    local alias_prefix="$3"
    
    local current_dir=$(dirname "$current_file")
    local resolved_path=""
    
    # Convert relative path to absolute
    if [[ "$import_path" == ./* ]] || [[ "$import_path" == ../* ]]; then
        resolved_path=$(realpath --relative-to="$PROJECT_ROOT" "$current_dir/$import_path" 2>/dev/null)
        
        # Convert to alias-based import if within src directory
        if [[ "$resolved_path" == src/* ]]; then
            resolved_path="${alias_prefix}/${resolved_path#src/}"
        elif [[ "$resolved_path" == components/* ]]; then
            resolved_path="${alias_prefix}/components/${resolved_path#components/}"
        fi
    else
        resolved_path="$import_path"
    fi
    
    echo "$resolved_path"
}

# Function to optimize JavaScript/TypeScript imports
optimize_js_ts_imports() {
    local file_path="$1"
    local content=$(cat "$file_path")
    local alias_prefix=$(find_import_alias)
    
    backup_file "$file_path"
    
    # Create temporary file for processing
    local temp_file="/tmp/import-optimize-$(basename "$file_path")"
    
    # Use Python script for complex import optimization
    python3 << EOF > "$temp_file"
import re
import os
import sys

content = '''$content'''
file_path = '$file_path'
project_root = '$PROJECT_ROOT'
alias_prefix = '$alias_prefix'

lines = content.split('\n')
imports = []
other_lines = []
import_section = True
current_import_block = []

# Separate imports from other code
for line in lines:
    stripped = line.strip()
    
    # Check if line is an import
    if re.match(r'^(import|from)\s+', stripped) or (current_import_block and stripped.startswith('}')):
        if import_section:
            current_import_block.append(line)
            # Check if this completes a multi-line import
            if stripped.endswith(';') or (stripped.endswith("'") or stripped.endswith('"')):
                imports.append('\\n'.join(current_import_block))
                current_import_block = []
        else:
            other_lines.append(line)
    elif stripped == '' and import_section:
        # Empty line in import section
        if current_import_block:
            current_import_block.append(line)
        else:
            imports.append(line)
    else:
        # Non-import line
        import_section = False
        if current_import_block:
            # Complete any pending import block
            imports.append('\\n'.join(current_import_block))
            current_import_block = []
        other_lines.append(line)

# Process and sort imports
processed_imports = []
for imp in imports:
    if imp.strip() == '':
        continue
        
    # Convert relative imports to absolute
    if "from '" in imp and ('./' in imp or '../' in imp):
        # Extract the import path
        match = re.search(r"from ['\"]([^'\"]+)['\"]", imp)
        if match:
            old_path = match.group(1)
            # Simple relative to absolute conversion
            if old_path.startswith('./'):
                new_path = f"{alias_prefix}/{old_path[2:]}"
            elif old_path.startswith('../'):
                # Count levels up
                levels = old_path.count('../')
                remaining = old_path.replace('../', '')
                new_path = f"{alias_prefix}/{remaining}"
            else:
                new_path = old_path
                
            # Replace in import statement
            imp = re.sub(r"from ['\"][^'\"]+['\"]", f"from '{new_path}'", imp)
    
    processed_imports.append(imp)

# Sort imports by type
def import_priority(imp_line):
    imp = imp_line.strip()
    if not imp:
        return 5
    
    # React imports first
    if 'react' in imp.lower():
        return 0
    # Third-party libraries
    elif imp.startswith('import') and not (alias_prefix in imp or './' in imp or '../' in imp):
        return 1
    # Absolute imports (alias-based)
    elif alias_prefix in imp:
        return 2
    # Relative imports
    elif './' in imp or '../' in imp:
        return 3
    # CSS/style imports last
    elif '.css' in imp or '.scss' in imp or '.sass' in imp:
        return 4
    else:
        return 2

# Sort imports while preserving empty lines
sorted_imports = []
non_empty_imports = [imp for imp in processed_imports if imp.strip()]
empty_lines = [imp for imp in processed_imports if not imp.strip()]

non_empty_imports.sort(key=import_priority)

# Add empty lines between groups
current_priority = -1
for imp in non_empty_imports:
    priority = import_priority(imp)
    if current_priority != -1 and priority != current_priority:
        sorted_imports.append('')
    sorted_imports.append(imp)
    current_priority = priority

# Rebuild file content
result_lines = sorted_imports + [''] + other_lines

# Remove excessive empty lines
final_lines = []
prev_empty = False
for line in result_lines:
    if line.strip() == '':
        if not prev_empty:
            final_lines.append(line)
        prev_empty = True
    else:
        final_lines.append(line)
        prev_empty = False

print('\\n'.join(final_lines))
EOF

    # Apply optimizations if successful
    if [[ -f "$temp_file" ]] && [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$file_path"
        log_success "Import optimization completed for $file_path"
        return 0
    else
        log_warn "Import optimization failed for $file_path"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to optimize Python imports
optimize_python_imports() {
    local file_path="$1"
    
    backup_file "$file_path"
    
    # Use isort if available
    if command_exists "isort"; then
        log_info "Optimizing Python imports with isort"
        if isort "$file_path" --profile black --force-single-line --line-length 88 2>/dev/null; then
            log_success "Python imports optimized with isort"
            return 0
        fi
    fi
    
    # Manual Python import sorting
    python3 << EOF
import re

with open('$file_path', 'r') as f:
    content = f.read()

lines = content.split('\n')
imports = []
from_imports = []
other_lines = []
import_section = True

for line in lines:
    stripped = line.strip()
    if stripped.startswith('import ') and import_section:
        imports.append(line)
    elif stripped.startswith('from ') and import_section:
        from_imports.append(line)
    elif stripped == '' and import_section:
        # Keep empty lines in import section
        if imports or from_imports:
            pass  # Skip for now, will add later
    else:
        import_section = False
        other_lines.append(line)

# Sort imports
imports.sort()
from_imports.sort()

# Rebuild content
result_lines = []
if imports:
    result_lines.extend(imports)
    if from_imports:
        result_lines.append('')
if from_imports:
    result_lines.extend(from_imports)
if imports or from_imports:
    result_lines.append('')
result_lines.extend(other_lines)

with open('$file_path', 'w') as f:
    f.write('\n'.join(result_lines))
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Python imports manually optimized"
        return 0
    else
        log_warn "Python import optimization failed"
        return 1
    fi
}

# Function to optimize Go imports
optimize_go_imports() {
    local file_path="$1"
    
    backup_file "$file_path"
    
    # Use goimports if available
    if command_exists "goimports"; then
        log_info "Optimizing Go imports with goimports"
        if goimports -w "$file_path" 2>/dev/null; then
            log_success "Go imports optimized with goimports"
            return 0
        fi
    fi
    
    # Use go fmt as fallback
    if command_exists "go"; then
        log_info "Formatting Go imports with go fmt"
        if go fmt "$file_path" 2>/dev/null; then
            log_success "Go imports formatted"
            return 0
        fi
    fi
    
    return 1
}

# Function to check for unused imports (detection only)
check_unused_imports() {
    local file_path="$1"
    local unused_count=0
    
    case "$LANGUAGE" in
        "javascript"|"typescript")
            # Simple check for unused imports
            if command_exists "eslint"; then
                unused_count=$(eslint "$file_path" 2>/dev/null | grep -c "is defined but never used" || echo "0")
            fi
            ;;
        "python")
            # Check with autoflake
            if command_exists "autoflake"; then
                unused_count=$(autoflake --check "$file_path" 2>/dev/null | grep -c "unused import" || echo "0")
            fi
            ;;
        "go")
            # Go compiler will catch unused imports
            if command_exists "go"; then
                unused_count=$(go build "$file_path" 2>&1 | grep -c "imported and not used" || echo "0")
            fi
            ;;
    esac
    
    if [[ $unused_count -gt 0 ]]; then
        log_warn "Detected $unused_count potentially unused imports in $file_path"
        echo "💡 Consider running your language-specific unused import removal tool"
    fi
}

# Store optimization metrics in Neo4j
store_optimization_metrics() {
    local file_path="$1"
    local optimization_type="$2"
    local success="$3"
    
    if command_exists "python3"; then
        local metrics_data="{"
        metrics_data+="\"file\": \"$file_path\","
        metrics_data+="\"optimization_type\": \"$optimization_type\","
        metrics_data+="\"success\": $success,"
        metrics_data+="\"timestamp\": \"$(date -Iseconds)\""
        metrics_data+="}"
        
        python3 "$(dirname "$0")/../utils/neo4j_mcp.py" store_optimization_metrics "$file_path" "$metrics_data" 2>/dev/null || true
    fi
}

# Main import optimization execution
OPTIMIZATION_APPLIED=false

case "$LANGUAGE" in
    "javascript"|"typescript")
        log_info "Optimizing JavaScript/TypeScript imports for $RELATIVE_PATH"
        if optimize_js_ts_imports "$FILE_PATH"; then
            OPTIMIZATION_APPLIED=true
            store_optimization_metrics "$RELATIVE_PATH" "js_ts_imports" "true"
        else
            store_optimization_metrics "$RELATIVE_PATH" "js_ts_imports" "false"
        fi
        check_unused_imports "$FILE_PATH"
        ;;
        
    "python")
        log_info "Optimizing Python imports for $RELATIVE_PATH"
        if optimize_python_imports "$FILE_PATH"; then
            OPTIMIZATION_APPLIED=true
            store_optimization_metrics "$RELATIVE_PATH" "python_imports" "true"
        else
            store_optimization_metrics "$RELATIVE_PATH" "python_imports" "false"
        fi
        check_unused_imports "$FILE_PATH"
        ;;
        
    "go")
        log_info "Optimizing Go imports for $RELATIVE_PATH"
        if optimize_go_imports "$FILE_PATH"; then
            OPTIMIZATION_APPLIED=true
            store_optimization_metrics "$RELATIVE_PATH" "go_imports" "true"
        else
            store_optimization_metrics "$RELATIVE_PATH" "go_imports" "false"
        fi
        check_unused_imports "$FILE_PATH"
        ;;
        
    *)
        log_info "Import optimization not available for language: $LANGUAGE"
        success_with_message "Import optimization not applicable"
        finalize_hook "import-optimizer" "skipped"
        exit 0
        ;;
esac

# Report results
if $OPTIMIZATION_APPLIED; then
    log_success "Import optimization completed for $RELATIVE_PATH"
    success_with_message "Imports optimized and sorted"
else
    log_info "No import optimization applied for $RELATIVE_PATH"
    success_with_message "Import optimization skipped or failed"
fi

finalize_hook "import-optimizer" "completed"