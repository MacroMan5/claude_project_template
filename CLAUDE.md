# 🤖 Claude Code Project Guide

This guide provides essential context and project-specific information for Claude Code.

---

## 🎯 Project Overview

**Project Name**: Claude Project Template  
**Type**: Development Template & Starter Kit  
**Tech Stack**: Multi-language template (Node.js, Python, Docker)  
**Status**: Development Template

### Purpose
This is a comprehensive template for setting up Claude Code projects with:
- Professional command suite
- MCP server configurations  
- Standardized project structure
- Best practices and workflows

---

## 🏗️ Project Structure

```
claude_project_template/
├── .claude/
│   ├── prompts/          # Professional prompt templates
│   └── settings.local.json # Local Claude permissions
├── commands.json         # Professional command suite
├── CLAUDE.md            # This file - project documentation
├── CLAUDE.local.md      # Local tools & personal preferences
└── README.md            # Standard project README
```

---

## 🛠️ Available Commands

### Development Workflows
- **Feature Development**: `Ctrl+Shift+F` - SPARC methodology
- **Testing Suite**: `Ctrl+Shift+U/I/P` - Unit/Integration/UI testing  
- **Code Quality**: `Ctrl+Shift+Q` - Comprehensive quality checks

### Application Commands
- **Run Tests**: `Ctrl+Shift+T`
- **Dev Server**: `Ctrl+Shift+R` 
- **Build**: Docker build via `Ctrl+Shift+B`
- **Lint/Format**: `Ctrl+Shift+L` / `Ctrl+Alt+F`

### Specialized Operations  
- **Architecture Design**: `Ctrl+Shift+A`
- **Security Audit**: `Ctrl+Shift+S`
- **CI/CD Setup**: `Ctrl+Shift+D`
- **Git Workflows**: `Ctrl+Shift+G`

---

## 📚 Project Guidelines

### Code Standards
- Follow language-specific best practices
- Use provided prompt templates for consistency
- Maintain comprehensive test coverage
- Document architectural decisions

### Git Workflow
- Use feature branches for development
- Follow conventional commit messages
- Leverage GitHub MCP for PR management
- Maintain clean commit history

### Testing Strategy
- TDD approach recommended
- Multiple testing levels (unit/integration/UI)
- Performance testing included
- Security scanning integrated

---

## � Customization

This template is designed to be customized for specific projects:

1. **Update commands.json** - Replace template commands with project-specific ones
2. **Configure .claude/settings.local.json** - Adjust permissions for your needs  
3. **Customize prompts** - Modify templates in `.claude/prompts/`
4. **Update this file** - Document your specific project details

---

## 📖 Additional Documentation

- **Tool Configuration**: See `CLAUDE.local.md` for MCP setup and personal preferences
- **Command Reference**: Full command details available in `commands.json`
- **Prompt Templates**: Professional prompts in `.claude/prompts/`

### 🔄 Sequential Thinking
**When to use**: 
- Complex planning (3+ steps)
- Architecture decisions
- Debugging complex issues
- Breaking down large features

**Example**:
```
Use mcp__sequential-thinking__sequentialthinking for:
- Planning feature implementation
- Analyzing system design
- Troubleshooting multi-component issues
```

### 🧠 Neo4j Memory
**When to use**:
- Getting project context for new tasks 
- Store project knowledge
- Track component relationships
- Remember user preferences
- Persist discoveries across sessions
- Every new feature or bug fix should update this memory

**Example**:
```
Use mcp__neo4j-memory__* for:
- Creating entities for new components
- Updating relationships between modules
- Querying existing project knowledge
```

### 🐙 GitHub MCP
**When to use**:
- Repository operations
- Creating issues/PRs
- Managing branches
- Instead of git bash commands when possible
- Automating workflows


### 📁 Filesystem MCP
**When to use**:
- Bulk file operations
- Complex directory operations
- Advanced file searches
- Managing project structure

---

## 🚀 Professional Prompts

Access professional-grade prompts for all development tasks:

### Quick Access Commands
```bash
# Development
@.claude/prompts/development/feature-development.md
@.claude/prompts/development/debugging.md

# Testing
@.claude/prompts/testing/unit-testing.md
@.claude/prompts/testing/integration-testing.md

# Architecture
@.claude/prompts/architecture/system-design.md
@.claude/prompts/architecture/api-design.md

# Security
@.claude/prompts/security/security-audit.md
@.claude/prompts/security/authentication.md

# See all prompts in .claude/prompts/
```

---

## 📋 Development Standards

### Code Style
- **Formatting**: Use automated formatters (Black, Prettier, etc.)
- **Linting**: Zero tolerance for linting errors
- **Type Safety**: Full type annotations required
- **Documentation**: Docstrings for all public functions

### Git Workflow
- **Branch** : Use Main branch for production, develop for staging, and feature branches for development
- **Branches naming**: feature/*, bugfix/*, hotfix/* # Add more as needed 
- **Commits**: Use conventional commits (feat:, fix:, docs:, etc.)
- **PRs**: Require reviews and passing CI, always test before trying to merge 

### Testing Requirements
- **Coverage**: Minimum 80% code coverage
- **Types**: Unit, integration, and E2E tests
- **TDD**: Write tests first for new features
- **CI**: All tests must pass before merging to develop or main branches

### Security Practices
- **Secrets**: Never commit sensitive data (Use secrets management tools, environment variables or .env files)
- **Dependencies**: Regular security scans (dependabot, snyk, etc.)
- **Input**: Validate all user inputs
- **Auth**: Use secure authentication methods

---

## 🏗️ Project Structure
```
project/
├── .claude/           # Claude Code configuration
│   └── prompts/       # Professional prompt library
├── src/               # Source code
├── tests/             # Test files
├── docs/              # Documentation
├── scripts/           # Utility scripts
└── config/            # Configuration files
Makefile               # Build and task automation or similar for your project 
README.md              # Project overview and setup instructions

```

---

## ⚠️ Important Rules

### DO:
- ✅ Use MCP tools proactively
- ✅ Follow existing code patterns
- ✅ Write tests for new code
- ✅ Update documentation
- ✅ Check for security issues
- ✅ Optimize for performance
- ✅ Use type annotations

### DON'T:
- ❌ Commit sensitive data
- ❌ Skip tests
- ❌ Ignore linting errors
- ❌ Use deprecated APIs
- ❌ Hard-code configuration
- ❌ Create files unless necessary
- ❌ Make breaking changes without discussion

---

## 🔧 Commands Reference

Access the full command suite via `commands.json`:
- 80+ predefined commands
- Keyboard shortcuts for common tasks
- Integration with professional prompts
- Automated workflows

---

## 📝 Context Management

### Session Start Checklist
1. Check Neo4j memory for existing context
2. Review recent changes in the codebase
3. Understand current task requirements
4. Plan approach using Sequential Thinking

### During Development
1. Update Neo4j memory with discoveries
2. Use appropriate professional prompts
3. Follow TDD practices
4. Maintain code quality standards

### Session End
1. Update memory with progress
2. Document any decisions made
3. Create todos for next steps
4. Ensure all tests pass

---

## 🚨 Quick Reference

### File Locations
- **Source Code**: `src/` or `app/`
- **Tests**: `tests/` or `spec/`
- **Config**: `config/` or root directory
- **Scripts**: `scripts/` or `tools/`
- **Docs**: `docs/` or `documentation/`

### Common Patterns
- **API Routes**: [Your API pattern]
- **Database Models**: [Your model pattern]
- **Component Structure**: [Your component pattern]
- **Test Structure**: [Your test pattern]

---

## 🎯 Current Priorities

1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

---

## 📚 Additional Resources

- [Project Documentation](./docs/)
- [API Reference](./docs/api/)
- [Contributing Guide](./CONTRIBUTING.md)
- [Architecture Decisions](./docs/architecture/)

---

**Remember**: This is a living document. Update it as the project evolves!