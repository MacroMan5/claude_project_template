#!/usr/bin/env python3
"""
GitHub MCP Integration for Claude Code Hooks
Provides utilities for automated GitHub operations
"""

import os
import sys
import json
import subprocess
import re
from typing import Dict, List, Optional, Any
from pathlib import Path

class GitHubMCPIntegrator:
    def __init__(self):
        self.project_name = os.getenv('PROJECT_NAME', os.path.basename(os.getcwd()))
        self.logs_dir = os.getenv('CLAUDE_LOGS_DIR', '.claude/hooks/logs')
        self.github_token = os.getenv('GITHUB_TOKEN')
        self.repo_owner = self._get_repo_owner()
        self.repo_name = self._get_repo_name()
        
    def log(self, message: str, level: str = "INFO"):
        """Log message to hooks log file"""
        timestamp = subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], 
                                 capture_output=True, text=True).stdout.strip()
        log_entry = f"{timestamp} - [{level}] GitHub MCP: {message}\n"
        
        os.makedirs(self.logs_dir, exist_ok=True)
        with open(f"{self.logs_dir}/hooks.log", "a") as f:
            f.write(log_entry)
    
    def _get_repo_owner(self) -> Optional[str]:
        """Get repository owner from git remote"""
        try:
            result = subprocess.run(['git', 'remote', 'get-url', 'origin'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                url = result.stdout.strip()
                # Parse GitHub URL
                if 'github.com' in url:
                    if url.startswith('git@'):
                        # SSH format: git@github.com:owner/repo.git
                        parts = url.split(':')[1].split('/')
                        return parts[0]
                    else:
                        # HTTPS format: https://github.com/owner/repo.git
                        parts = url.split('/')
                        return parts[-2]
        except:
            pass
        return None
    
    def _get_repo_name(self) -> Optional[str]:
        """Get repository name from git remote"""
        try:
            result = subprocess.run(['git', 'remote', 'get-url', 'origin'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                url = result.stdout.strip()
                # Parse GitHub URL
                if 'github.com' in url:
                    if url.startswith('git@'):
                        # SSH format: git@github.com:owner/repo.git
                        parts = url.split(':')[1].split('/')
                        return parts[1].replace('.git', '')
                    else:
                        # HTTPS format: https://github.com/owner/repo.git
                        parts = url.split('/')
                        return parts[-1].replace('.git', '')
        except:
            pass
        return None
    
    def is_github_available(self) -> bool:
        """Check if GitHub integration is available"""
        return (self.github_token is not None and 
                self.repo_owner is not None and 
                self.repo_name is not None)
    
    def execute_mcp_call(self, tool_name: str, params: Dict[str, Any]) -> Optional[Dict]:
        """Execute GitHub MCP tool call"""
        if not self.is_github_available():
            self.log("GitHub not available, skipping MCP call", "WARN")
            return None
            
        try:
            # Add repository info to params
            params.update({
                "owner": self.repo_owner,
                "repo": self.repo_name
            })
            
            # For now, log the MCP call - in real implementation, this would call the MCP server
            self.log(f"GitHub MCP Call: {tool_name} with params: {json.dumps(params, indent=2)}")
            
            # Simulate MCP call response
            return {"status": "success", "tool": tool_name}
            
        except Exception as e:
            self.log(f"GitHub MCP call failed: {str(e)}", "ERROR")
            return None
    
    def extract_todos_from_file(self, file_path: str) -> List[Dict[str, Any]]:
        """Extract TODO comments from file"""
        if not os.path.exists(file_path):
            return []
        
        todos = []
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            
            for line_num, line in enumerate(lines, 1):
                # Look for TODO, FIXME, HACK, NOTE patterns
                todo_patterns = [
                    r'#\s*TODO:?\s*(.+)',
                    r'//\s*TODO:?\s*(.+)',
                    r'/\*\s*TODO:?\s*(.+?)\*/',
                    r'#\s*FIXME:?\s*(.+)',
                    r'//\s*FIXME:?\s*(.+)',
                    r'#\s*HACK:?\s*(.+)',
                    r'//\s*HACK:?\s*(.+)',
                    r'#\s*NOTE:?\s*(.+)',
                    r'//\s*NOTE:?\s*(.+)'
                ]
                
                for pattern in todo_patterns:
                    match = re.search(pattern, line, re.IGNORECASE)
                    if match:
                        todo_text = match.group(1).strip()
                        todo_type = "TODO"
                        
                        if "FIXME" in line.upper():
                            todo_type = "FIXME"
                        elif "HACK" in line.upper():
                            todo_type = "HACK"
                        elif "NOTE" in line.upper():
                            todo_type = "NOTE"
                        
                        todos.append({
                            "type": todo_type,
                            "text": todo_text,
                            "file": file_path,
                            "line": line_num,
                            "context": line.strip()
                        })
                        break
        except Exception as e:
            self.log(f"Error extracting TODOs from {file_path}: {str(e)}", "ERROR")
        
        return todos
    
    def create_issues_from_todos(self, file_path: str):
        """Create GitHub issues from TODO comments in file"""
        todos = self.extract_todos_from_file(file_path)
        
        for todo in todos:
            # Skip if it's just a note
            if todo["type"] == "NOTE":
                continue
            
            title = f"{todo['type']}: {todo['text'][:50]}{'...' if len(todo['text']) > 50 else ''}"
            
            body = f"""**File:** `{todo['file']}`  
**Line:** {todo['line']}  
**Type:** {todo['type']}

**Description:**
{todo['text']}

**Context:**
```
{todo['context']}
```

---
*This issue was automatically created by Claude Code hooks.*"""
            
            labels = ["todo", "auto-generated"]
            if todo["type"] == "FIXME":
                labels.append("bug")
            elif todo["type"] == "HACK":
                labels.append("technical-debt")
            
            issue_params = {
                "title": title,
                "body": body,
                "labels": labels
            }
            
            self.execute_mcp_call("mcp__github__create_issue", issue_params)
    
    def create_pr_for_feature_branch(self, branch_name: str, base_branch: str = "main"):
        """Create draft PR for feature branch if it has significant changes"""
        try:
            # Check if branch exists
            result = subprocess.run(['git', 'rev-parse', '--verify', branch_name], 
                                  capture_output=True)
            if result.returncode != 0:
                return
            
            # Get commit count difference
            result = subprocess.run(['git', 'rev-list', '--count', f'{base_branch}..{branch_name}'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                commit_count = int(result.stdout.strip())
                
                # Create PR if branch has 3+ commits
                if commit_count >= 3:
                    # Get branch summary
                    result = subprocess.run(['git', 'log', '--oneline', f'{base_branch}..{branch_name}'], 
                                          capture_output=True, text=True)
                    commits = result.stdout.strip().split('\n') if result.returncode == 0 else []
                    
                    title = f"Draft: {branch_name.replace('-', ' ').title()}"
                    
                    body = f"""**Branch:** `{branch_name}`  
**Commits:** {commit_count}

**Recent Changes:**
"""
                    for commit in commits[:5]:  # Show first 5 commits
                        body += f"- {commit}\n"
                    
                    if len(commits) > 5:
                        body += f"- ... and {len(commits) - 5} more commits\n"
                    
                    body += "\n---\n*This draft PR was automatically created by Claude Code hooks.*"
                    
                    pr_params = {
                        "title": title,
                        "body": body,
                        "head": branch_name,
                        "base": base_branch,
                        "draft": True
                    }
                    
                    self.execute_mcp_call("mcp__github__create_pull_request", pr_params)
                    
        except Exception as e:
            self.log(f"Error creating PR for branch {branch_name}: {str(e)}", "ERROR")
    
    def notify_team_of_changes(self, file_path: str, change_type: str):
        """Notify team of significant changes via GitHub issues"""
        # Only notify for critical files
        critical_patterns = [
            r'.*/(api|routes?)/',
            r'.*/models?/',
            r'.*/schema/',
            r'.*/(config|settings)',
            r'package\.json$',
            r'requirements\.txt$',
            r'go\.mod$',
            r'Dockerfile$',
            r'docker-compose\.ya?ml$'
        ]
        
        is_critical = any(re.search(pattern, file_path) for pattern in critical_patterns)
        
        if is_critical:
            title = f"Critical File Modified: {os.path.basename(file_path)}"
            
            body = f"""**File:** `{file_path}`  
**Change Type:** {change_type}  
**Project:** {self.project_name}

A critical file has been modified. Please review the changes to ensure they don't break existing functionality.

**Why this is flagged as critical:**
- This file appears to be part of core infrastructure, API, or configuration

---
*This notification was automatically created by Claude Code hooks.*"""
            
            issue_params = {
                "title": title,
                "body": body,
                "labels": ["critical-change", "review-needed", "auto-generated"]
            }
            
            self.execute_mcp_call("mcp__github__create_issue", issue_params)
    
    def update_pr_description(self, pr_number: int, file_path: str, change_summary: str):
        """Update PR description with recent changes"""
        # This would typically fetch the existing PR and append to its description
        self.log(f"Would update PR #{pr_number} with changes to {file_path}: {change_summary}")
    
    def assign_reviewers_based_on_ownership(self, file_path: str):
        """Assign reviewers based on file ownership patterns"""
        # This would analyze git blame and assign appropriate reviewers
        self.log(f"Would assign reviewers for {file_path} based on ownership patterns")

def main():
    """Main function for command-line usage"""
    if len(sys.argv) < 2:
        print("Usage: github_mcp.py <action> [args...]")
        sys.exit(1)
    
    action = sys.argv[1]
    integrator = GitHubMCPIntegrator()
    
    if action == "create_todos_issues" and len(sys.argv) > 2:
        file_path = sys.argv[2]
        integrator.create_issues_from_todos(file_path)
    elif action == "notify_critical_change" and len(sys.argv) > 3:
        file_path = sys.argv[2]
        change_type = sys.argv[3]
        integrator.notify_team_of_changes(file_path, change_type)
    elif action == "create_feature_pr" and len(sys.argv) > 2:
        branch_name = sys.argv[2]
        base_branch = sys.argv[3] if len(sys.argv) > 3 else "main"
        integrator.create_pr_for_feature_branch(branch_name, base_branch)
    else:
        integrator.log(f"Unknown action: {action}", "ERROR")

if __name__ == "__main__":
    main()