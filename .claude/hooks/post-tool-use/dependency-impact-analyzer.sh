#!/bin/bash
# Dependency Impact Analyzer hook - analyzes what files are affected by changes
# Critical for large codebases to understand change impact

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Initialize hook
init_hook "dependency-impact-analyzer"

# Validate parameters
validate_params 1 $#

FILE_PATH="$1"

# Skip if file doesn't exist
if ! file_exists "$FILE_PATH"; then
    log_warn "File $FILE_PATH does not exist, skipping impact analysis"
    success_with_message "No impact analysis needed - file does not exist"
    finalize_hook "dependency-impact-analyzer" "skipped"
    exit 0
fi

# Get project root and relative path
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RELATIVE_PATH=$(realpath --relative-to="$PROJECT_ROOT" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
LANGUAGE=$(detect_language "$FILE_PATH")

log_info "Analyzing dependency impact for $RELATIVE_PATH (language: $LANGUAGE)"

# Function to find all files that import the changed file
find_dependent_files() {
    local file_path="$1"
    local base_name=$(basename "$file_path")
    local name_without_ext=$(echo "$base_name" | cut -d. -f1)
    local dependents=()
    
    case "$LANGUAGE" in
        "javascript"|"typescript")
            # Search for various import patterns
            local import_patterns=(
                "from ['\"].*${name_without_ext}['\"]"
                "from ['\"].*/${base_name}['\"]"
                "import.*['\"].*${name_without_ext}['\"]"
                "require(['\"].*${name_without_ext}['\"])"
                "import(['\"].*${name_without_ext}['\"])"
            )
            
            for pattern in "${import_patterns[@]}"; do
                local matches=$(grep -r -l -E "$pattern" "$PROJECT_ROOT" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" --include="*.vue" 2>/dev/null | grep -v "$FILE_PATH")
                if [[ -n "$matches" ]]; then
                    dependents+=($matches)
                fi
            done
            ;;
            
        "python")
            # Search for Python import patterns
            local import_patterns=(
                "from.*${name_without_ext}.*import"
                "import.*${name_without_ext}"
                "from.*${base_name%.*}.*import"
            )
            
            for pattern in "${import_patterns[@]}"; do
                local matches=$(grep -r -l -E "$pattern" "$PROJECT_ROOT" --include="*.py" 2>/dev/null | grep -v "$FILE_PATH")
                if [[ -n "$matches" ]]; then
                    dependents+=($matches)
                fi
            done
            ;;
            
        "go")
            # Search for Go import patterns
            local package_path=$(dirname "$RELATIVE_PATH")
            local matches=$(grep -r -l "\".*${package_path}\"" "$PROJECT_ROOT" --include="*.go" 2>/dev/null | grep -v "$FILE_PATH")
            if [[ -n "$matches" ]]; then
                dependents+=($matches)
            fi
            ;;
            
        "java")
            # Search for Java import patterns
            local class_name="$name_without_ext"
            local matches=$(grep -r -l "import.*${class_name}" "$PROJECT_ROOT" --include="*.java" 2>/dev/null | grep -v "$FILE_PATH")
            if [[ -n "$matches" ]]; then
                dependents+=($matches)
            fi
            ;;
            
        "rust")
            # Search for Rust use statements
            local matches=$(grep -r -l "use.*${name_without_ext}" "$PROJECT_ROOT" --include="*.rs" 2>/dev/null | grep -v "$FILE_PATH")
            if [[ -n "$matches" ]]; then
                dependents+=($matches)
            fi
            ;;
    esac
    
    # Remove duplicates and convert to relative paths
    local unique_dependents=($(printf '%s\n' "${dependents[@]}" | sort -u))
    local relative_dependents=()
    
    for dep in "${unique_dependents[@]}"; do
        if [[ -f "$dep" ]]; then
            local rel_dep=$(realpath --relative-to="$PROJECT_ROOT" "$dep" 2>/dev/null || echo "$dep")
            relative_dependents+=("$rel_dep")
        fi
    done
    
    echo "${relative_dependents[@]}"
}

# Function to analyze the type of changes
analyze_change_type() {
    local file_path="$1"
    local change_types=()
    
    # Check if file has exports/public API
    case "$LANGUAGE" in
        "javascript"|"typescript")
            if grep -q "export\|module.exports" "$file_path" 2>/dev/null; then
                change_types+=("API_CHANGE")
            fi
            if grep -q "interface\|type.*=" "$file_path" 2>/dev/null; then
                change_types+=("TYPE_CHANGE")
            fi
            ;;
        "python")
            if grep -q "def\|class" "$file_path" 2>/dev/null; then
                change_types+=("API_CHANGE")
            fi
            ;;
        "go")
            if grep -q "func.*{" "$file_path" 2>/dev/null; then
                change_types+=("API_CHANGE")
            fi
            ;;
        "java")
            if grep -q "public.*class\|public.*interface\|public.*method" "$file_path" 2>/dev/null; then
                change_types+=("API_CHANGE")
            fi
            ;;
    esac
    
    # Check for configuration changes
    case "$RELATIVE_PATH" in
        *package.json|*requirements.txt|*go.mod|*Cargo.toml|*pom.xml)
            change_types+=("DEPENDENCY_CHANGE")
            ;;
        *.config.*|*webpack*|*babel*|*tsconfig*|*jest*|*.env*)
            change_types+=("CONFIG_CHANGE")
            ;;
        *test*|*spec*)
            change_types+=("TEST_CHANGE")
            ;;
    esac
    
    echo "${change_types[@]}"
}

# Function to calculate impact severity
calculate_impact_severity() {
    local dependent_count=$1
    local change_types=("$@")
    
    local severity="LOW"
    
    # Base severity on number of dependents
    if [[ $dependent_count -gt 20 ]]; then
        severity="CRITICAL"
    elif [[ $dependent_count -gt 10 ]]; then
        severity="HIGH"
    elif [[ $dependent_count -gt 3 ]]; then
        severity="MEDIUM"
    fi
    
    # Increase severity based on change type
    for change_type in "${change_types[@]}"; do
        case "$change_type" in
            "API_CHANGE"|"TYPE_CHANGE")
                if [[ "$severity" == "LOW" ]]; then severity="MEDIUM"; fi
                if [[ "$severity" == "MEDIUM" ]]; then severity="HIGH"; fi
                ;;
            "DEPENDENCY_CHANGE"|"CONFIG_CHANGE")
                if [[ "$severity" == "LOW" ]]; then severity="MEDIUM"; fi
                ;;
        esac
    done
    
    echo "$severity"
}

# Function to store impact analysis in Neo4j
store_impact_analysis() {
    local file_path="$1"
    local dependents=("$@")
    
    if command_exists "python3" && [[ ${#dependents[@]} -gt 0 ]]; then
        # Create impact analysis data
        local impact_data="{"
        impact_data+="\"file\": \"$file_path\","
        impact_data+="\"dependents\": [\"$(IFS='","'; echo "${dependents[*]}")\"],"
        impact_data+="\"timestamp\": \"$(date -Iseconds)\","
        impact_data+="\"count\": ${#dependents[@]}"
        impact_data+="}"
        
        python3 "$(dirname "$0")/../utils/neo4j_mcp.py" store_impact_analysis "$file_path" "$impact_data" 2>/dev/null || true
        log_info "Stored impact analysis in Neo4j knowledge graph"
    fi
}

# Function to suggest actions based on impact
suggest_actions() {
    local file_path="$1"
    local dependent_count=$2
    local severity="$3"
    local change_types=("$@")
    
    echo ""
    echo "## 💡 Suggested Actions:"
    
    case "$severity" in
        "CRITICAL")
            echo "🚨 CRITICAL IMPACT - This change affects $dependent_count files!"
            echo "   • Run full test suite before committing"
            echo "   • Consider gradual rollout or feature flags"
            echo "   • Notify team leads about this change"
            echo "   • Update documentation and migration guides"
            ;;
        "HIGH")
            echo "⚠️  HIGH IMPACT - This change affects $dependent_count files"
            echo "   • Run comprehensive tests on affected modules"
            echo "   • Check for breaking changes in API"
            echo "   • Update relevant documentation"
            ;;
        "MEDIUM")
            echo "⚡ MEDIUM IMPACT - This change affects $dependent_count files"
            echo "   • Run tests for affected components"
            echo "   • Verify no breaking changes introduced"
            ;;
        "LOW")
            echo "✅ LOW IMPACT - Limited scope change ($dependent_count files)"
            echo "   • Standard testing should be sufficient"
            ;;
    esac
    
    # Type-specific suggestions
    for change_type in "${change_types[@]}"; do
        case "$change_type" in
            "API_CHANGE")
                echo "   • Review API contract changes carefully"
                echo "   • Consider backwards compatibility"
                ;;
            "TYPE_CHANGE")
                echo "   • Type check all affected TypeScript files"
                echo "   • Update type documentation"
                ;;
            "DEPENDENCY_CHANGE")
                echo "   • Check for version conflicts"
                echo "   • Update lockfiles appropriately"
                ;;
            "CONFIG_CHANGE")
                echo "   • Test in all environments"
                echo "   • Update deployment procedures if needed"
                ;;
        esac
    done
    
    echo ""
}

# Main impact analysis execution
case "$LANGUAGE" in
    "javascript"|"typescript"|"python"|"go"|"java"|"rust")
        log_info "Finding files that depend on $RELATIVE_PATH..."
        
        # Find all dependent files
        dependents=($(find_dependent_files "$FILE_PATH"))
        dependent_count=${#dependents[@]}
        
        if [[ $dependent_count -eq 0 ]]; then
            log_info "No dependencies found for $RELATIVE_PATH"
            success_with_message "No impact detected - isolated change"
        else
            log_info "Found $dependent_count files that depend on $RELATIVE_PATH"
            
            # Analyze change types
            change_types=($(analyze_change_type "$FILE_PATH"))
            
            # Calculate impact severity
            severity=$(calculate_impact_severity $dependent_count "${change_types[@]}")
            
            # Display impact analysis
            echo ""
            echo "## 📊 Dependency Impact Analysis for $RELATIVE_PATH"
            echo ""
            echo "**Impact Severity:** $severity"
            echo "**Files Affected:** $dependent_count"
            echo "**Change Types:** ${change_types[*]:-"IMPLEMENTATION_CHANGE"}"
            echo ""
            
            if [[ $dependent_count -le 10 ]]; then
                echo "**Affected Files:**"
                for dep in "${dependents[@]}"; do
                    echo "  - $dep"
                done
            else
                echo "**Affected Files (first 10):**"
                for i in {0..9}; do
                    if [[ -n "${dependents[$i]}" ]]; then
                        echo "  - ${dependents[$i]}"
                    fi
                done
                echo "  ... and $((dependent_count - 10)) more files"
            fi
            
            # Store in Neo4j
            store_impact_analysis "$RELATIVE_PATH" "${dependents[@]}"
            
            # Provide suggestions
            suggest_actions "$RELATIVE_PATH" $dependent_count "$severity" "${change_types[@]}"
            
            success_with_message "$severity impact: $dependent_count files affected"
        fi
        ;;
    *)
        log_info "Impact analysis not applicable for file type: $LANGUAGE"
        success_with_message "Impact analysis skipped for file type"
        ;;
esac

finalize_hook "dependency-impact-analyzer" "completed"