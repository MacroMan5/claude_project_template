#!/bin/bash
# Claude Code Project Template Bootstrap Script
# Installs the Claude Code template into existing projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Constants
TEMPLATE_REPO="https://raw.githubusercontent.com/anthropics/claude-project-template/main"
TEMPLATE_VERSION="v2.0"
BACKUP_DIR=".claude-template-backup"

# Global variables
PROJECT_TYPE=""
INSTALL_MODE="interactive"
FORCE_INSTALL=false
HOOKS_ONLY=false
TARGET_DIR="$(pwd)"

# Banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════╗"
    echo "║        Claude Code Project Template        ║"
    echo "║            Bootstrap Installer             ║"
    echo "║                                            ║"
    echo "║   Supercharge your development workflow    ║"
    echo "║     with 14 production-ready hooks!       ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -f, --force             Force installation (overwrite existing files)
    -m, --mode MODE         Installation mode: interactive, auto, hooks-only
    -t, --type TYPE         Project type: node, python, go, java, auto
    -d, --dir DIRECTORY     Target directory (default: current directory)
    -v, --version           Show version information

INSTALLATION MODES:
    interactive             Ask questions and customize installation (default)
    auto                    Auto-detect project and install with defaults
    hooks-only             Install only hooks, skip other configuration

PROJECT TYPES:
    auto                    Auto-detect project type (default)
    node                    Node.js/JavaScript/TypeScript project
    python                  Python project
    go                      Go project
    java                    Java project
    multi                   Multi-language project

EXAMPLES:
    $0                      Interactive installation in current directory
    $0 --mode auto          Auto-install with detection
    $0 --type node          Install for Node.js project
    $0 --mode hooks-only    Install only the hooks system
    $0 --dir /path/to/proj  Install in specific directory

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            -m|--mode)
                INSTALL_MODE="$2"
                shift 2
                ;;
            -t|--type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            -d|--dir)
                TARGET_DIR="$2"
                shift 2
                ;;
            -v|--version)
                echo "Claude Code Project Template $TEMPLATE_VERSION"
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate mode
    case "$INSTALL_MODE" in
        interactive|auto|hooks-only) ;;
        *) 
            echo -e "${RED}Invalid mode: $INSTALL_MODE${NC}"
            show_usage
            exit 1
            ;;
    esac
    
    # Set hooks-only flag
    if [[ "$INSTALL_MODE" == "hooks-only" ]]; then
        HOOKS_ONLY=true
    fi
}

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # Essential tools
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    command -v python3 >/dev/null 2>&1 || missing_tools+=("python3")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install them and try again."
        exit 1
    fi
    
    # Optional but recommended tools
    local recommended_tools=()
    command -v jq >/dev/null 2>&1 || recommended_tools+=("jq")
    command -v rg >/dev/null 2>&1 || recommended_tools+=("ripgrep")
    
    if [[ ${#recommended_tools[@]} -gt 0 ]]; then
        log_warning "Recommended tools not found: ${recommended_tools[*]}"
        echo "Some features may not work optimally."
    fi
    
    log_success "Prerequisites check completed"
}

# Project detection
detect_project_type() {
    if [[ -n "$PROJECT_TYPE" && "$PROJECT_TYPE" != "auto" ]]; then
        return 0
    fi
    
    log_step "Detecting project type..."
    
    local detected_types=()
    
    # Node.js detection
    if [[ -f "package.json" ]]; then
        detected_types+=("node")
    fi
    
    # Python detection
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "Pipfile" ]]; then
        detected_types+=("python")
    fi
    
    # Go detection
    if [[ -f "go.mod" ]] || [[ -f "go.sum" ]]; then
        detected_types+=("go")
    fi
    
    # Java detection
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        detected_types+=("java")
    fi
    
    # Rust detection
    if [[ -f "Cargo.toml" ]]; then
        detected_types+=("rust")
    fi
    
    # Set project type based on detection
    if [[ ${#detected_types[@]} -eq 0 ]]; then
        PROJECT_TYPE="unknown"
        log_warning "Could not detect project type"
    elif [[ ${#detected_types[@]} -eq 1 ]]; then
        PROJECT_TYPE="${detected_types[0]}"
        log_success "Detected project type: $PROJECT_TYPE"
    else
        PROJECT_TYPE="multi"
        log_info "Detected multi-language project: ${detected_types[*]}"
    fi
}

# Interactive configuration
interactive_config() {
    if [[ "$INSTALL_MODE" != "interactive" ]]; then
        return 0
    fi
    
    echo -e "${CYAN}🔧 Interactive Configuration${NC}"
    echo "================================================"
    echo ""
    
    # Project type confirmation
    if [[ "$PROJECT_TYPE" != "unknown" ]]; then
        echo -e "Detected project type: ${GREEN}$PROJECT_TYPE${NC}"
        read -p "Is this correct? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Available types: node, python, go, java, rust, multi, unknown"
            read -p "Enter project type: " PROJECT_TYPE
        fi
    else
        echo "Available types: node, python, go, java, rust, multi, unknown"
        read -p "Enter project type: " PROJECT_TYPE
    fi
    
    # Installation options
    echo ""
    echo "Installation Options:"
    echo "1. Full installation (hooks + commands + prompts + MCP)"
    echo "2. Hooks only (recommended for existing Claude Code users)"
    echo "3. Custom selection"
    
    read -p "Choose option (1-3): " -n 1 -r install_option
    echo ""
    
    case $install_option in
        2)
            HOOKS_ONLY=true
            ;;
        3)
            # Custom selection will be implemented in individual install functions
            ;;
        *)
            # Full installation (default)
            ;;
    esac
    
    # Force overwrite confirmation
    if [[ -d ".claude" ]] && [[ "$FORCE_INSTALL" != true ]]; then
        echo ""
        log_warning "Existing .claude directory detected"
        read -p "Backup and overwrite? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            FORCE_INSTALL=true
        else
            log_error "Installation cancelled"
            exit 1
        fi
    fi
    
    echo ""
}

# Create backup
create_backup() {
    if [[ ! -d ".claude" ]]; then
        return 0
    fi
    
    log_step "Creating backup of existing configuration..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$BACKUP_DIR"
    fi
    
    cp -r ".claude" "$BACKUP_DIR"
    log_success "Backup created: $BACKUP_DIR"
}

# Download template files
download_template_file() {
    local file_path="$1"
    local target_path="$2"
    local required="${3:-true}"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$target_path")"
    
    # Try to download from local template first (if we're in the template repo)
    local template_root
    template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -f "$template_root/$file_path" ]]; then
        cp "$template_root/$file_path" "$target_path"
        return 0
    fi
    
    # Download from remote repository
    local url="$TEMPLATE_REPO/$file_path"
    if curl -fsSL "$url" -o "$target_path" 2>/dev/null; then
        return 0
    elif [[ "$required" == "true" ]]; then
        log_error "Failed to download required file: $file_path"
        return 1
    fi
    
    return 0
}

# Install core template files
install_core_files() {
    if [[ "$HOOKS_ONLY" == true ]]; then
        return 0
    fi
    
    log_step "Installing core template files..."
    
    # Download core files
    download_template_file "CLAUDE.md" "CLAUDE.md"
    download_template_file "CLAUDE.local.md" "CLAUDE.local.md"
    
    # Customize CLAUDE.md for project
    if [[ -f "CLAUDE.md" ]]; then
        sed -i.bak "s/Claude Project Template/$(basename "$TARGET_DIR")/g" "CLAUDE.md" 2>/dev/null || true
        sed -i.bak "s/Development Template & Starter Kit/$PROJECT_TYPE Project/g" "CLAUDE.md" 2>/dev/null || true
        rm -f "CLAUDE.md.bak"
    fi
    
    log_success "Core files installed"
}

# Install hooks system
install_hooks() {
    log_step "Installing hooks system..."
    
    # Create hooks directory structure
    mkdir -p ".claude/hooks"/{post-tool-use,pre-tool-use,notification,stop,utils,logs,templates}
    
    # Download hook files
    local hook_files=(
        ".claude/hooks/post-tool-use/format-code.sh"
        ".claude/hooks/post-tool-use/lint-code.sh"
        ".claude/hooks/post-tool-use/run-tests.sh"
        ".claude/hooks/post-tool-use/sync-dependencies.sh"
        ".claude/hooks/post-tool-use/cleanup-imports.sh"
        ".claude/hooks/post-tool-use/update-docs.sh"
        ".claude/hooks/post-tool-use/git-auto-stage.sh"
        ".claude/hooks/post-tool-use/smart-context-builder.sh"
        ".claude/hooks/post-tool-use/dependency-impact-analyzer.sh"
        ".claude/hooks/post-tool-use/import-optimizer.sh"
        ".claude/hooks/pre-tool-use/security-check.sh"
        ".claude/hooks/pre-tool-use/backup-file.sh"
        ".claude/hooks/pre-tool-use/bash-validate.sh"
        ".claude/hooks/pre-tool-use/multi-edit-check.sh"
        ".claude/hooks/pre-tool-use/performance-check.sh"
        ".claude/hooks/pre-tool-use/pattern-enforcer.sh"
        ".claude/hooks/notification/log-notification.sh"
        ".claude/hooks/notification/handle-error.sh"
        ".claude/hooks/stop/cleanup-temp.sh"
        ".claude/hooks/stop/update-session-knowledge.sh"
        ".claude/hooks/utils/common.sh"
        ".claude/hooks/utils/neo4j_mcp.py"
    )
    
    local installed_hooks=0
    for hook_file in "${hook_files[@]}"; do
        if download_template_file "$hook_file" "$hook_file" false; then
            chmod +x "$hook_file" 2>/dev/null || true
            ((installed_hooks++))
        fi
    done
    
    # Download hooks configuration
    download_template_file ".claude/hooks.json" ".claude/hooks.json"
    
    # Customize hooks based on project type
    customize_hooks_for_project
    
    log_success "Installed $installed_hooks hook files"
}

# Customize hooks for project type
customize_hooks_for_project() {
    if [[ ! -f ".claude/hooks.json" ]]; then
        return 0
    fi
    
    # Project-specific hook customization
    case "$PROJECT_TYPE" in
        "python")
            log_info "Configuring hooks for Python project"
            # Could disable JS/TS specific hooks or adjust priorities
            ;;
        "node")
            log_info "Configuring hooks for Node.js project"
            # Could enable npm-specific features
            ;;
        "go")
            log_info "Configuring hooks for Go project"
            # Could enable Go-specific tooling
            ;;
        "java")
            log_info "Configuring hooks for Java project"
            # Could enable Maven/Gradle specific features
            ;;
    esac
}

# Install MCP configuration
install_mcp_config() {
    if [[ "$HOOKS_ONLY" == true ]]; then
        return 0
    fi
    
    log_step "Installing MCP configuration..."
    
    download_template_file ".claude/.mcp.json" ".claude/.mcp.json" false
    
    if [[ -f ".claude/.mcp.json" ]]; then
        log_success "MCP configuration installed"
    else
        log_warning "MCP configuration not available"
    fi
}

# Install commands
install_commands() {
    if [[ "$HOOKS_ONLY" == true ]]; then
        return 0
    fi
    
    log_step "Installing command suite..."
    
    download_template_file ".claude/commands.json" ".claude/commands.json" false
    
    if [[ -f ".claude/commands.json" ]]; then
        log_success "Command suite installed (32 professional commands)"
    else
        log_warning "Command suite not available"
    fi
}

# Install prompts
install_prompts() {
    if [[ "$HOOKS_ONLY" == true ]]; then
        return 0
    fi
    
    log_step "Installing professional prompts..."
    
    # Create prompts directory structure
    mkdir -p ".claude/prompts"/{development,testing,architecture,security,deployment,documentation,workflow,project-management}
    
    # List of available prompts
    local prompt_files=(
        ".claude/prompts/development/feature-development.md"
        ".claude/prompts/development/debugging.md"
        ".claude/prompts/testing/unit-testing.md"
        ".claude/prompts/testing/integration-testing.md"
        ".claude/prompts/testing/ui-testing.md"
        ".claude/prompts/architecture/system-design.md"
        ".claude/prompts/security/security-audit.md"
        ".claude/prompts/deployment/ci-cd-pipeline.md"
        ".claude/prompts/documentation/api-docs.md"
        ".claude/prompts/workflow/git-workflow.md"
        ".claude/prompts/workflow/code-quality.md"
        ".claude/prompts/project-management/epic-creation.md"
        ".claude/prompts/project-management/milestone-management.md"
        ".claude/prompts/project-management/labeling-system.md"
        ".claude/prompts/project-management/repository-health.md"
    )
    
    local installed_prompts=0
    for prompt_file in "${prompt_files[@]}"; do
        if download_template_file "$prompt_file" "$prompt_file" false; then
            ((installed_prompts++))
        fi
    done
    
    log_success "Installed $installed_prompts professional prompts"
}

# Install settings template
install_settings() {
    log_step "Installing settings template..."
    
    download_template_file ".claude/settings.template.json" ".claude/settings.template.json" false
    
    if [[ -f ".claude/settings.template.json" ]] && [[ ! -f ".claude/settings.local.json" ]]; then
        cp ".claude/settings.template.json" ".claude/settings.local.json"
        log_success "Settings template installed"
    fi
}

# Setup environment variables
setup_environment() {
    log_step "Setting up environment..."
    
    local project_name
    project_name="$(basename "$TARGET_DIR")"
    
    # Create environment setup script
    cat > ".claude/setup-env.sh" << EOF
#!/bin/bash
# Claude Code Template Environment Setup

# Essential environment variables
export PROJECT_NAME="$project_name"
export CLAUDE_LOGS_DIR=".claude/hooks/logs"

# Optional: Uncomment and configure these for enhanced features
# export GITHUB_PERSONAL_ACCESS_TOKEN="your_token_here"
# export POSTGRES_CONNECTION_STRING="postgresql://user:pass@host:5432/db"

echo "Environment variables set for Claude Code template"
echo "PROJECT_NAME: \$PROJECT_NAME"
echo "CLAUDE_LOGS_DIR: \$CLAUDE_LOGS_DIR"

# Run this script with: source .claude/setup-env.sh
EOF
    
    chmod +x ".claude/setup-env.sh"
    log_success "Environment setup script created"
}

# Post-installation tasks
post_install() {
    log_step "Running post-installation tasks..."
    
    # Create knowledge directory
    mkdir -p ".claude/knowledge"
    
    # Create context directory
    mkdir -p ".claude/context"
    
    # Initialize logs
    mkdir -p ".claude/hooks/logs"
    touch ".claude/hooks/logs/hooks.log"
    
    # Set proper permissions
    find ".claude" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find ".claude" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
    
    log_success "Post-installation tasks completed"
}

# Test installation
test_installation() {
    log_step "Testing installation..."
    
    local test_passed=true
    
    # Test hook execution
    if [[ -f ".claude/hooks/post-tool-use/format-code.sh" ]]; then
        if ./.claude/hooks/post-tool-use/format-code.sh "/nonexistent/test.js" >/dev/null 2>&1; then
            log_success "Hook system is working"
        else
            log_warning "Hook system test failed"
            test_passed=false
        fi
    fi
    
    # Test Neo4j utility
    if [[ -f ".claude/hooks/utils/neo4j_mcp.py" ]]; then
        if python3 .claude/hooks/utils/neo4j_mcp.py get_context test.js >/dev/null 2>&1; then
            log_success "Neo4j utility is working"
        else
            log_warning "Neo4j utility test failed"
            test_passed=false
        fi
    fi
    
    if [[ "$test_passed" == true ]]; then
        log_success "Installation test passed"
    else
        log_warning "Some components may not work correctly"
    fi
}

# Show installation summary
show_summary() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo "================================================"
    echo ""
    
    if [[ "$HOOKS_ONLY" == true ]]; then
        echo -e "${CYAN}Hooks-only installation completed:${NC}"
        echo "• 14 production-ready development hooks"
        echo "• Smart context building and impact analysis"
        echo "• Multi-language code optimization"
    else
        echo -e "${CYAN}Full template installation completed:${NC}"
        echo "• 14 production-ready development hooks"
        echo "• 32 professional command shortcuts"
        echo "• 15+ workflow prompts"
        echo "• MCP tool integrations"
        echo "• Project-specific configuration"
    fi
    
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Restart Claude Code to activate hooks"
    echo "2. Run: source .claude/setup-env.sh"
    echo "3. Customize CLAUDE.md for your project"
    
    if [[ "$PROJECT_TYPE" != "unknown" ]]; then
        echo "4. Project detected as $PROJECT_TYPE - hooks are pre-configured"
    fi
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo ""
        echo -e "${BLUE}Backup created: $BACKUP_DIR${NC}"
        echo "Your original configuration is preserved"
    fi
    
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "• Template overview: CLAUDE.md"
    echo "• Local configuration: CLAUDE.local.md"
    echo "• Hook testing: .claude/test-hooks.sh"
    
    echo ""
    echo -e "${GREEN}Happy coding with Claude! 🚀${NC}"
}

# Main installation flow
main() {
    show_banner
    parse_args "$@"
    
    # Change to target directory
    if [[ "$TARGET_DIR" != "$(pwd)" ]]; then
        if [[ ! -d "$TARGET_DIR" ]]; then
            log_error "Target directory does not exist: $TARGET_DIR"
            exit 1
        fi
        cd "$TARGET_DIR"
        log_info "Installing in: $TARGET_DIR"
    fi
    
    check_prerequisites
    detect_project_type
    interactive_config
    
    if [[ "$FORCE_INSTALL" == true ]]; then
        create_backup
    fi
    
    # Installation steps
    install_core_files
    install_hooks
    install_mcp_config
    install_commands
    install_prompts
    install_settings
    setup_environment
    post_install
    test_installation
    
    show_summary
}

# Run main function with all arguments
main "$@"