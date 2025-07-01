# 🚀 Claude Project Template

Professional template for AI-assisted development with Claude Code, featuring comprehensive MCP tools, development workflows, and best practices.

## ✨ Features

- **🤖 Claude Code Ready** - Pre-configured for AI-assisted development
- **🛠️ Professional Commands** - 30+ shortcuts for common development tasks
- **🔄 MCP Tools Integration** - Sequential thinking, Neo4j memory, GitHub automation
- **📋 Professional Prompts** - 18 specialized prompts for different development phases
- **🎯 Multi-Language Support** - Templates for Node.js, Python, Go, Rust projects
- **🔒 Security First** - Built-in security scanning and best practices
- **� Quality Assurance** - Automated testing, linting, and code quality checks

## 🚀 Quick Start

### 1. Use This Template
```bash
# Clone the template
git clone https://github.com/your-org/claude-project-template.git
cd claude-project-template

# Run setup script for new project
./new-project-setup.sh
```

### 2. Open in Claude Code
```bash
# Open your new project in VS Code with Claude
code ../your-new-project
```

### 3. Start Developing
- Press `Ctrl+Shift+F` to start feature development
- Press `Ctrl+Shift+T` to run tests
- Press `Ctrl+Shift+A` for architecture planning
- **⚡ Quick Commands**: 80+ predefined commands with keyboard shortcuts
- **🎯 Zero Configuration**: Works out of the box with minimal setup

## 🏁 Quick Start

### 1. Clone the Template

```bash
# Clone this template
git clone https://github.com/yourusername/claude_project_template.git my-new-project
cd my-new-project

# Remove template git history
rm -rf .git
git init

# Create your own repository
git add .
git commit -m "Initial commit from Claude Code template"
```

### 2. Set Environment Variables

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Required for GitHub MCP
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-pat-here"

# Optional: Override project name (defaults to directory name)
export PROJECT_NAME="my-project"
```

### 3. Start Neo4j (Required for Knowledge Graph)

```bash
# Using Docker
docker run -d \
  --name neo4j \
  -p 7687:7687 \
  -p 7474:7474 \
  -e NEO4J_AUTH=none \
  neo4j:latest

# Or using Docker Compose (if you have one)
docker-compose up -d neo4j
```

### 4. Customize Configuration

1. **Update CLAUDE.md**:
   - Replace `[Your Project Name]` placeholders
   - Add project-specific commands
   - Update tech stack information

2. **Fill in CLAUDE.local.md**:
   - Add your personal preferences
   - Set local environment variables
   - Document project-specific context

3. **Update commands.json**:
   - Replace `[YOUR_*_COMMAND]` placeholders
   - Add project-specific commands
   - Customize keyboard shortcuts

## 📁 Project Structure

```
my-project/
├── .claude/                 # Claude Code configuration
│   └── prompts/            # Professional prompt library
│       ├── development/    # Feature dev, debugging, refactoring
│       ├── testing/        # TDD, integration, UI testing
│       ├── architecture/   # System design, API, database
│       ├── security/       # Audits, auth, compliance
│       ├── deployment/     # CI/CD, Docker, Kubernetes
│       ├── documentation/  # API docs, user guides
│       └── workflow/       # Git, quality, automation
├── .claudeignore           # Optimize token usage
├── .mcp.json              # MCP server configurations
├── CLAUDE.md              # Global project rules
├── CLAUDE.local.md        # Personal preferences (git ignored)
├── commands.json          # Command definitions
└── README.md              # This file
```

## 🧠 Neo4j Memory Persistence

Each project maintains its own Neo4j knowledge graph:

### How It Works
- Volume name: `{project_name}_neo4j_mcp_data`
- Data persists across Claude sessions
- No authentication for local development
- Automatic project isolation

### Common Operations
```cypher
# View all stored knowledge
MATCH (n) RETURN n

# Find specific components
MATCH (n) WHERE n.name CONTAINS 'auth' RETURN n

# See relationships
MATCH (a)-[r]->(b) RETURN a, r, b
```

### Troubleshooting Neo4j
```bash
# Check if Neo4j is running
docker ps | grep neo4j

# View Neo4j logs
docker logs neo4j

# Access Neo4j Browser (optional)
open http://localhost:7474

# Reset project memory (warning: deletes all knowledge)
docker volume rm $(basename $PWD)_neo4j_mcp_data
```

## 📚 Using Professional Prompts

### Quick Access
Use the `@` symbol to access prompts:
```bash
@.claude/prompts/development/feature-development.md
@.claude/prompts/testing/unit-testing.md
@.claude/prompts/security/security-audit.md
```

### Keyboard Shortcuts
- `Ctrl+Shift+F` - Feature Development (SPARC)
- `Ctrl+Shift+U` - TDD Unit Testing
- `Ctrl+Shift+A` - System Architecture
- `Ctrl+Shift+S` - Security Audit
- `Ctrl+Shift+G` - Git Workflow

See `commands.json` for all shortcuts.

## 🔧 MCP Tools Reference

### Sequential Thinking
Use for complex planning and multi-step problems:
```
mcp__sequential-thinking__sequentialthinking
```

### Neo4j Memory
Store and retrieve project knowledge:
```
mcp__neo4j-memory__create_entities
mcp__neo4j-memory__read_graph
mcp__neo4j-memory__search_nodes
```

### GitHub Operations
Manage repository without leaving Claude:
```
mcp__github__create_issue
mcp__github__create_pull_request
mcp__github__search_repositories
```

### Filesystem
Advanced file operations:
```
mcp__filesystem__read_multiple_files
mcp__filesystem__search_files
mcp__filesystem__edit_file
```

## 📝 Best Practices

### 1. Start Each Session
- Check Neo4j memory: `mcp__neo4j-memory__read_graph`
- Review CLAUDE.local.md for context
- Use Sequential Thinking for planning

### 2. During Development
- Update Neo4j with discoveries
- Use appropriate professional prompts
- Follow TDD practices
- Maintain code quality

### 3. End of Session
- Update memory with progress
- Document decisions in CLAUDE.local.md
- Create todos for next session

## 🚨 Important Notes

### Security
- **Never commit CLAUDE.local.md** (it's in .gitignore)
- Don't store secrets in configuration files
- Use environment variables for sensitive data

### Performance
- .claudeignore optimizes token usage
- Keep large binary files out of the project
- Use MCP tools for bulk operations

### Customization
- This is a template - modify everything!
- Add your own prompts to .claude/prompts/
- Extend commands.json with project commands
- Update MCP configuration as needed

## 🤝 Contributing

To improve this template:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📄 License

This template is open source and available under the MIT License.

## 🆘 Troubleshooting

### MCP Not Working
```bash
# Check Docker is running
docker version

# Restart MCP servers
# (Restart Claude Code)
```

### Neo4j Connection Issues
```bash
# Check Neo4j is accessible
nc -zv localhost 7687

# Restart Neo4j
docker restart neo4j
```

### Missing Dependencies
```bash
# Ensure Docker is installed
which docker

# Check environment variables
echo $GITHUB_PERSONAL_ACCESS_TOKEN
```

---

**Ready to start?** Open this project in Claude Code and let the AI assist you! 🎉