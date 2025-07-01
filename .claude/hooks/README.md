# 🪝 Claude Code Hooks

This directory contains intelligent hooks that automatically execute during Claude's lifecycle events.

## 📁 Directory Structure

```
.claude/hooks/
├── pre-tool-use/      # Execute before Claude uses tools
├── post-tool-use/     # Execute after Claude completes tool usage
├── notification/      # Handle Claude notifications
├── stop/             # Execute when Claude session ends
├── utils/            # Shared utilities and MCP integrations
├── templates/        # Language-specific hook templates
├── logs/            # Hook execution logs
└── hooks.json       # Main configuration file
```

## 🔧 Hook Types

### PreToolUse Hooks
- **security-check.sh**: Validate file content for security issues
- **backup-file.sh**: Create backup before modifications
- **bash-validate.sh**: Validate shell commands before execution
- **multi-edit-check.sh**: Validate multi-file operations

### PostToolUse Hooks
- **format-code.sh**: Auto-format code (Black, Prettier, gofmt)
- **run-tests.sh**: Execute relevant tests after changes
- **update-knowledge.sh**: Update Neo4j knowledge graph
- **check-todos.sh**: Scan for TODOs and create GitHub issues

### Notification Hooks
- **log-notification.sh**: Log all Claude notifications
- **handle-error.sh**: Special handling for error notifications

### Stop Hooks
- **cleanup-temp.sh**: Clean temporary files
- **session-summary.sh**: Generate session summary
- **update-session-knowledge.sh**: Persist session knowledge

## 🛠️ Utilities

### MCP Integrations
- **neo4j_mcp.py**: Neo4j knowledge graph operations
- **github_mcp.py**: GitHub repository automation
- **filesystem_mcp.py**: Advanced file operations

### Shared Functions
- **common.sh**: Shared shell functions
- **validators.py**: Code validation utilities
- **formatters.sh**: Multi-language code formatters

## 🎯 Usage

Hooks are automatically executed by Claude Code based on the configuration in `hooks.json`. No manual intervention required.

### Environment Variables
- `CLAUDE_HOOKS_DIR`: Hook scripts directory
- `CLAUDE_LOGS_DIR`: Hook logs directory
- `PROJECT_NAME`: Current project name
- `GITHUB_TOKEN`: GitHub access token

## 🔍 Debugging

View hook execution logs:
```bash
tail -f .claude/hooks/logs/hooks.log
```

Test individual hooks:
```bash
.claude/hooks/post-tool-use/format-code.sh "src/main.py"
```

## 🚀 Extending Hooks

1. Create new hook script in appropriate directory
2. Make executable: `chmod +x your-hook.sh`
3. Add configuration to `hooks.json`
4. Test with sample inputs

Happy hooking! 🎣