# 🌳 Git Workflow Automation Prompt

## Context
You are managing Git operations efficiently, following best practices for version control, branching strategies, commit conventions, and collaboration workflows.

## Git Workflow Standards

### Branching Strategy

#### Git Flow Model
```
main (production)
  └── develop (integration)
       ├── feature/user-authentication
       ├── feature/payment-integration
       ├── bugfix/login-error
       ├── hotfix/security-patch
       └── release/v2.0.0
```

#### Branch Naming Conventions
```yaml
Feature Branches:
  pattern: feature/[ticket-id]-[brief-description]
  examples:
    - feature/PROJ-123-user-authentication
    - feature/PROJ-456-payment-gateway
    
Bugfix Branches:
  pattern: bugfix/[ticket-id]-[brief-description]
  examples:
    - bugfix/PROJ-789-login-validation
    - bugfix/PROJ-012-email-formatting
    
Hotfix Branches:
  pattern: hotfix/[ticket-id]-[brief-description]
  examples:
    - hotfix/PROJ-345-security-vulnerability
    - hotfix/PROJ-678-critical-crash
    
Release Branches:
  pattern: release/v[major].[minor].[patch]
  examples:
    - release/v2.0.0
    - release/v2.1.0
```

### Commit Message Convention

#### Conventional Commits Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Commit Types
```yaml
feat:     New feature
fix:      Bug fix
docs:     Documentation changes
style:    Code style changes (formatting, etc)
refactor: Code refactoring
perf:     Performance improvements
test:     Test additions or modifications
build:    Build system changes
ci:       CI/CD configuration changes
chore:    Maintenance tasks
revert:   Revert previous commit
```

#### Examples
```bash
# Feature commit
feat(auth): implement JWT authentication

- Add JWT token generation
- Implement token validation middleware
- Add refresh token mechanism

Closes #123

# Bug fix commit
fix(api): resolve null pointer in user service

The user service was throwing NPE when email was null.
Added proper null checking and validation.

Fixes #456

# Breaking change
feat(api)!: change user API response format

BREAKING CHANGE: The user API now returns a nested
structure instead of flat fields. Clients need to
update their parsing logic.

Migration guide: docs/migrations/v2.md
```

## Git Operations

### 1. Feature Development Workflow

```bash
# Start new feature
git checkout develop
git pull origin develop
git checkout -b feature/PROJ-123-new-feature

# Work on feature
git add .
git commit -m "feat(module): implement new feature"

# Keep feature branch updated
git checkout develop
git pull origin develop
git checkout feature/PROJ-123-new-feature
git rebase develop

# Push feature
git push origin feature/PROJ-123-new-feature
```

### 2. Interactive Rebase for Clean History

```bash
# Squash commits before PR
git rebase -i HEAD~5

# Rebase options:
# pick - use commit
# reword - use commit, but edit message
# squash - use commit, but meld into previous
# fixup - like squash, but discard message
# drop - remove commit

# Example .git/rebase-todo:
pick abc1234 feat: initial implementation
squash def5678 fix: typo
squash ghi9012 refactor: improve performance
reword jkl3456 feat: add validation
drop mno7890 debug: remove console.log
```

### 3. Handling Merge Conflicts

```bash
# Update branch and resolve conflicts
git checkout feature/my-feature
git pull origin develop

# If conflicts occur
git status
# Edit conflicted files
git add <resolved-files>
git commit

# Or abort merge
git merge --abort
```

### 4. Git Hooks

#### Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run linting
npm run lint
if [ $? -ne 0 ]; then
  echo "Linting failed. Please fix errors before committing."
  exit 1
fi

# Run tests
npm test
if [ $? -ne 0 ]; then
  echo "Tests failed. Please fix failing tests before committing."
  exit 1
fi

# Check for sensitive data
git diff --cached --name-only | xargs grep -E "(password|secret|key).*=.*['\"].*['\"]"
if [ $? -eq 0 ]; then
  echo "Possible sensitive data detected. Please review before committing."
  exit 1
fi
```

#### Commit Message Hook
```bash
#!/bin/sh
# .git/hooks/commit-msg

# Check commit message format
commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
  echo "Invalid commit message format!"
  echo "Format: <type>(<scope>): <subject>"
  echo "Example: feat(auth): add login functionality"
  exit 1
fi
```

### 5. Advanced Git Commands

#### Cherry-picking
```bash
# Apply specific commit to current branch
git cherry-pick <commit-hash>

# Cherry-pick range
git cherry-pick <start-commit>..<end-commit>

# Cherry-pick without committing
git cherry-pick -n <commit-hash>
```

#### Stashing
```bash
# Save work in progress
git stash save "WIP: feature implementation"

# List stashes
git stash list

# Apply specific stash
git stash apply stash@{2}

# Apply and remove stash
git stash pop

# Create branch from stash
git stash branch feature/new-feature stash@{1}
```

#### Bisect for Bug Finding
```bash
# Start bisect
git bisect start
git bisect bad HEAD
git bisect good v1.0.0

# Test and mark commits
git bisect good  # Current commit is good
git bisect bad   # Current commit is bad

# Find the culprit
git bisect run npm test

# End bisect
git bisect reset
```

## Pull Request Workflow

### PR Creation Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing unit tests pass locally

## Screenshots (if applicable)
[Add screenshots here]

## Related Issues
Closes #123
```

### PR Review Guidelines
```yaml
Code Review Checklist:
  functionality:
    - Does the code do what it's supposed to?
    - Are edge cases handled?
    - Is error handling appropriate?
    
  code_quality:
    - Is the code readable and maintainable?
    - Are functions/classes appropriately sized?
    - Is there code duplication?
    
  testing:
    - Are there sufficient tests?
    - Do tests cover edge cases?
    - Are tests maintainable?
    
  security:
    - No hardcoded secrets
    - Input validation present
    - No SQL injection vulnerabilities
    
  performance:
    - No obvious performance issues
    - Appropriate algorithm choices
    - Database queries optimized
```

## Git Aliases

### Useful Git Aliases
```bash
# ~/.gitconfig
[alias]
    # Shortcuts
    co = checkout
    br = branch
    ci = commit
    st = status
    
    # Pretty log
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    
    # Show branches with last commit
    branches = branch -v
    
    # Interactive add
    ai = add --interactive
    
    # Amend last commit
    amend = commit --amend --no-edit
    
    # Undo last commit (keep changes)
    undo = reset HEAD~1 --soft
    
    # Show files in last commit
    last = log -1 HEAD --stat
    
    # Find commits by message
    find = log --grep
    
    # Show who changed what
    who = shortlog -sn
    
    # Cleanup merged branches
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|develop' | xargs -n 1 git branch -d"
```

## Git Troubleshooting

### Common Issues and Solutions

#### 1. Accidentally Committed to Wrong Branch
```bash
# Move commits to correct branch
git checkout correct-branch
git cherry-pick wrong-branch~3..wrong-branch
git checkout wrong-branch
git reset --hard HEAD~3
```

#### 2. Need to Change Last Commit
```bash
# Change last commit message
git commit --amend -m "New message"

# Add forgotten file to last commit
git add forgotten-file.js
git commit --amend --no-edit
```

#### 3. Remove Sensitive Data
```bash
# Remove file from history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive-file" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (coordinate with team)
git push origin --force --all
```

#### 4. Recover Deleted Branch
```bash
# Find the commit
git reflog

# Recreate branch
git checkout -b recovered-branch <commit-hash>
```

## Git Best Practices

### DO:
- ✅ Commit early and often
- ✅ Write descriptive commit messages
- ✅ Keep commits atomic (one change per commit)
- ✅ Review your changes before committing
- ✅ Pull before pushing
- ✅ Use branches for features
- ✅ Keep main/develop branches stable
- ✅ Tag releases properly
- ✅ Clean up old branches
- ✅ Use .gitignore effectively

### DON'T:
- ❌ Commit large binary files
- ❌ Commit sensitive information
- ❌ Force push to shared branches
- ❌ Commit broken code
- ❌ Mix feature changes in one commit
- ❌ Use generic commit messages
- ❌ Work directly on main branch
- ❌ Ignore merge conflicts
- ❌ Rewrite public history
- ❌ Commit node_modules or build files

## Automation Scripts

### Git Workflow Automation
```bash
#!/bin/bash
# git-feature.sh - Automate feature branch workflow

feature_name=$1
ticket_id=$2

if [ -z "$feature_name" ] || [ -z "$ticket_id" ]; then
  echo "Usage: ./git-feature.sh <feature-name> <ticket-id>"
  exit 1
fi

# Create feature branch
git checkout develop
git pull origin develop
git checkout -b "feature/${ticket_id}-${feature_name}"

echo "Feature branch created: feature/${ticket_id}-${feature_name}"
echo "You can now start working on your feature!"
```

### Release Automation
```bash
#!/bin/bash
# git-release.sh - Automate release process

version=$1

if [ -z "$version" ]; then
  echo "Usage: ./git-release.sh <version>"
  exit 1
fi

# Create release branch
git checkout develop
git pull origin develop
git checkout -b "release/v${version}"

# Update version files
npm version $version --no-git-tag-version

# Commit version bump
git add .
git commit -m "chore: bump version to ${version}"

# Create PR
gh pr create --base main --head "release/v${version}" \
  --title "Release v${version}" \
  --body "Release version ${version}"

echo "Release branch created and PR opened!"
```

## Git Configuration

### Recommended Git Config
```ini
# ~/.gitconfig
[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = vim
    autocrlf = input
    whitespace = trailing-space,space-before-tab

[pull]
    rebase = true

[fetch]
    prune = true

[diff]
    tool = vimdiff

[merge]
    tool = vimdiff
    conflictstyle = diff3

[push]
    default = current

[rerere]
    enabled = true

[commit]
    gpgsign = true
    template = ~/.gitmessage

[init]
    defaultBranch = main
```