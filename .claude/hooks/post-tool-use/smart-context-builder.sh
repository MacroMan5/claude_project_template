#!/bin/bash
# Smart Context Builder hook - builds intelligent context for large codebases
# Uses Neo4j to store and retrieve file relationships and patterns

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "smart-context-builder"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping context building"
    success_with_message "No context building needed - file does not exist"
    finalize_hook "smart-context-builder" "skipped"
    exit 0
fi

# Get project root and relative path
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RELATIVE_PATH=$(realpath --relative-to="$PROJECT_ROOT" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
LANGUAGE=$(detect_language "$FILE_PATH")

log_info "Building smart context for $RELATIVE_PATH (language: $LANGUAGE)"

# Function to find related files based on patterns
find_related_files() {
    local file_path="$1"
    local base_name=$(basename "$file_path" | cut -d. -f1)
    local dir_name=$(dirname "$file_path")
    
    echo "# Related Files for $RELATIVE_PATH" > "/tmp/context-${base_name}.md"
    echo "" >> "/tmp/context-${base_name}.md"
    
    # Find test files
    local test_files=$(find "$PROJECT_ROOT" -name "*${base_name}*test*" -o -name "*${base_name}*spec*" 2>/dev/null | head -5)
    if [[ -n "$test_files" ]]; then
        echo "## Test Files:" >> "/tmp/context-${base_name}.md"
        echo "$test_files" | while read -r test_file; do
            echo "- $(realpath --relative-to="$PROJECT_ROOT" "$test_file")" >> "/tmp/context-${base_name}.md"
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
    
    # Find type definition files
    local type_files=$(find "$PROJECT_ROOT" -name "*${base_name}*.d.ts" -o -name "*${base_name}*types*" 2>/dev/null | head -5)
    if [[ -n "$type_files" ]]; then
        echo "## Type Definitions:" >> "/tmp/context-${base_name}.md"
        echo "$type_files" | while read -r type_file; do
            echo "- $(realpath --relative-to="$PROJECT_ROOT" "$type_file")" >> "/tmp/context-${base_name}.md"
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
    
    # Find style files
    local style_files=$(find "$PROJECT_ROOT" -name "*${base_name}*.css" -o -name "*${base_name}*.scss" -o -name "*${base_name}*.module.*" 2>/dev/null | head -5)
    if [[ -n "$style_files" ]]; then
        echo "## Style Files:" >> "/tmp/context-${base_name}.md"
        echo "$style_files" | while read -r style_file; do
            echo "- $(realpath --relative-to="$PROJECT_ROOT" "$style_file")" >> "/tmp/context-${base_name}.md"
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
    
    # Find story/documentation files
    local doc_files=$(find "$PROJECT_ROOT" -name "*${base_name}*.stories.*" -o -name "*${base_name}*.mdx" -o -name "*${base_name}*.md" 2>/dev/null | head -5)
    if [[ -n "$doc_files" ]]; then
        echo "## Documentation:" >> "/tmp/context-${base_name}.md"
        echo "$doc_files" | while read -r doc_file; do
            echo "- $(realpath --relative-to="$PROJECT_ROOT" "$doc_file")" >> "/tmp/context-${base_name}.md"
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
}

# Function to analyze file dependencies
analyze_dependencies() {
    local file_path="$1"
    local imports=()
    local exports=()
    
    case "$LANGUAGE" in
        "javascript"|"typescript")
            # Extract imports
            imports=($(grep -E "^import.*from|^const.*require\(" "$file_path" 2>/dev/null | sed 's/.*from ['"'"'"]//' | sed 's/['"'"'"].*//' | head -10))
            
            # Extract exports
            exports=($(grep -E "^export.*|export default" "$file_path" 2>/dev/null | head -5))
            ;;
        "python")
            # Extract imports
            imports=($(grep -E "^(import|from).*" "$file_path" 2>/dev/null | head -10))
            
            # Extract class/function definitions
            exports=($(grep -E "^(class|def).*:" "$file_path" 2>/dev/null | head -5))
            ;;
        "go")
            # Extract imports
            imports=($(grep -E "^import.*" "$file_path" 2>/dev/null | head -10))
            
            # Extract function definitions
            exports=($(grep -E "^func.*" "$file_path" 2>/dev/null | head -5))
            ;;
    esac
    
    # Store in Neo4j if available
    if command_exists "python3" && [[ ${#imports[@]} -gt 0 ]]; then
        python3 "$(dirname "$0")/../utils/neo4j_mcp.py" store_file_context "$RELATIVE_PATH" "${imports[*]}" "${exports[*]}" 2>/dev/null || true
    fi
}

# Function to find files that import the current file
find_dependents() {
    local file_path="$1"
    local base_name=$(basename "$file_path" | cut -d. -f1)
    local dependents=()
    
    # Search for files that import this file
    case "$LANGUAGE" in
        "javascript"|"typescript")
            # Look for imports of this file
            dependents=($(grep -r "from.*${base_name}" "$PROJECT_ROOT" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" 2>/dev/null | cut -d: -f1 | sort -u | head -10))
            ;;
        "python")
            # Look for imports of this module
            dependents=($(grep -r "import.*${base_name}\|from.*${base_name}" "$PROJECT_ROOT" --include="*.py" 2>/dev/null | cut -d: -f1 | sort -u | head -10))
            ;;
        "go")
            # Look for imports of this package
            dependents=($(grep -r "\".*${base_name}\"" "$PROJECT_ROOT" --include="*.go" 2>/dev/null | cut -d: -f1 | sort -u | head -10))
            ;;
    esac
    
    if [[ ${#dependents[@]} -gt 0 ]]; then
        echo "## Files that depend on this:" >> "/tmp/context-${base_name}.md"
        for dep in "${dependents[@]}"; do
            if [[ "$dep" != "$FILE_PATH" ]]; then
                echo "- $(realpath --relative-to="$PROJECT_ROOT" "$dep" 2>/dev/null || echo "$dep")" >> "/tmp/context-${base_name}.md"
            fi
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
    
    # Store dependency graph in Neo4j
    if command_exists "python3" && [[ ${#dependents[@]} -gt 0 ]]; then
        python3 "$(dirname "$0")/../utils/neo4j_mcp.py" store_dependencies "$RELATIVE_PATH" "${dependents[*]}" 2>/dev/null || true
    fi
}

# Function to get recently modified files in same area
get_recent_changes() {
    local file_path="$1"
    local dir_name=$(dirname "$file_path")
    
    # Get recently modified files in same directory and subdirectories
    local recent_files=$(find "$dir_name" -type f -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rs" | xargs ls -t 2>/dev/null | head -10)
    
    if [[ -n "$recent_files" ]]; then
        echo "## Recently Modified in $(dirname "$RELATIVE_PATH"):" >> "/tmp/context-${base_name}.md"
        echo "$recent_files" | while read -r recent_file; do
            if [[ "$recent_file" != "$FILE_PATH" ]]; then
                echo "- $(realpath --relative-to="$PROJECT_ROOT" "$recent_file" 2>/dev/null || echo "$recent_file")" >> "/tmp/context-${base_name}.md"
            fi
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
}

# Function to identify patterns based on file location
identify_patterns() {
    local file_path="$1"
    local patterns=()
    
    # Identify patterns based on directory structure
    if [[ "$file_path" == *"/components/"* ]]; then
        patterns+=("React Component")
    elif [[ "$file_path" == *"/pages/"* ]] || [[ "$file_path" == *"/routes/"* ]]; then
        patterns+=("Route/Page Component")
    elif [[ "$file_path" == *"/api/"* ]] || [[ "$file_path" == *"/controllers/"* ]]; then
        patterns+=("API Endpoint")
    elif [[ "$file_path" == *"/models/"* ]] || [[ "$file_path" == *"/entities/"* ]]; then
        patterns+=("Data Model")
    elif [[ "$file_path" == *"/utils/"* ]] || [[ "$file_path" == *"/helpers/"* ]]; then
        patterns+=("Utility/Helper")
    elif [[ "$file_path" == *"/hooks/"* ]]; then
        patterns+=("React Hook")
    elif [[ "$file_path" == *"/services/"* ]]; then
        patterns+=("Service Layer")
    elif [[ "$file_path" == *"/types/"* ]] || [[ "$file_path" == *.d.ts ]]; then
        patterns+=("Type Definitions")
    fi
    
    # Store patterns in Neo4j
    if [[ ${#patterns[@]} -gt 0 ]] && command_exists "python3"; then
        python3 "$(dirname "$0")/../utils/neo4j_mcp.py" store_patterns "$RELATIVE_PATH" "${patterns[*]}" 2>/dev/null || true
    fi
    
    if [[ ${#patterns[@]} -gt 0 ]]; then
        echo "## Identified Patterns:" >> "/tmp/context-${base_name}.md"
        for pattern in "${patterns[@]}"; do
            echo "- $pattern" >> "/tmp/context-${base_name}.md"
        done
        echo "" >> "/tmp/context-${base_name}.md"
    fi
}

# Function to get context from Neo4j memory
get_neo4j_context() {
    local file_path="$1"
    
    if command_exists "python3"; then
        local context=$(python3 "$(dirname "$0")/../utils/neo4j_mcp.py" get_context "$RELATIVE_PATH" 2>/dev/null || echo "")
        
        if [[ -n "$context" ]] && [[ "$context" != "None" ]]; then
            echo "## Knowledge Graph Context:" >> "/tmp/context-${base_name}.md"
            echo "$context" >> "/tmp/context-${base_name}.md"
            echo "" >> "/tmp/context-${base_name}.md"
        fi
    fi
}

# Main context building execution
BASE_NAME=$(basename "$FILE_PATH" | cut -d. -f1)

# Only build context for code files
case "$LANGUAGE" in
    "javascript"|"typescript"|"python"|"go"|"java"|"rust"|"cpp"|"c")
        log_info "Building context for code file: $RELATIVE_PATH"
        
        # Build comprehensive context
        find_related_files "$FILE_PATH"
        analyze_dependencies "$FILE_PATH"
        find_dependents "$FILE_PATH"
        get_recent_changes "$FILE_PATH"
        identify_patterns "$FILE_PATH"
        get_neo4j_context "$FILE_PATH"
        
        # Create context summary
        if [[ -f "/tmp/context-${BASE_NAME}.md" ]]; then
            local context_size=$(wc -l < "/tmp/context-${BASE_NAME}.md")
            if [[ $context_size -gt 10 ]]; then
                log_success "Smart context built: $context_size lines of context for $RELATIVE_PATH"
                
                # Store context file in project
                local context_dir="$PROJECT_ROOT/.claude/context"
                mkdir -p "$context_dir"
                cp "/tmp/context-${BASE_NAME}.md" "$context_dir/$(basename "$RELATIVE_PATH")-context.md"
                
                success_with_message "Context built: $context_size lines (.claude/context/$(basename "$RELATIVE_PATH")-context.md)"
            else
                log_info "Minimal context found for $RELATIVE_PATH"
                success_with_message "Basic context built"
            fi
            
            # Cleanup temp file
            rm -f "/tmp/context-${BASE_NAME}.md"
        else
            log_info "No additional context needed for $RELATIVE_PATH"
            success_with_message "No context building needed"
        fi
        ;;
    *)
        log_info "Context building not applicable for file type: $LANGUAGE"
        success_with_message "Context building skipped for file type"
        ;;
esac

finalize_hook "smart-context-builder" "completed"