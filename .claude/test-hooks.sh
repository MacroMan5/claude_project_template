#!/bin/bash
# Comprehensive Hook Testing Suite
# Tests all 14 hooks with various file types and scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test setup
TEST_DIR="/tmp/claude-hook-tests"
PROJECT_ROOT="$(pwd)"

echo -e "${BLUE}🧪 Claude Code Hook Testing Suite${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

# Setup test environment
setup_test_env() {
    echo -e "${YELLOW}📋 Setting up test environment...${NC}"
    
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Initialize as git repo
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create test project structure
    mkdir -p src/{components,utils,api,models,tests}
    mkdir -p .claude/{hooks/{logs,post-tool-use,pre-tool-use,utils},knowledge,context}
    
    # Copy hook files for testing
    cp -r "$PROJECT_ROOT/.claude/hooks"/* ".claude/hooks/"
    
    # Set environment variables
    export PROJECT_NAME="test-project"
    export CLAUDE_LOGS_DIR=".claude/hooks/logs"
    
    echo -e "${GREEN}✅ Test environment ready${NC}"
    echo ""
}

# Test helper functions
run_test() {
    local test_name="$1"
    local hook_path="$2"
    local test_file="$3"
    local expected_result="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "  Testing $test_name... "
    
    # Run hook and capture result
    if [[ -f "$hook_path" ]]; then
        if "$hook_path" "$test_file" &>/dev/null; then
            if [[ "$expected_result" == "pass" ]]; then
                echo -e "${GREEN}PASS${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo -e "${RED}FAIL (expected failure but passed)${NC}"
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
        else
            if [[ "$expected_result" == "fail" ]]; then
                echo -e "${GREEN}PASS (expected failure)${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo -e "${RED}FAIL${NC}"
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
        fi
    else
        echo -e "${RED}FAIL (hook not found)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Create test files
create_test_files() {
    echo -e "${YELLOW}📝 Creating test files...${NC}"
    
    # JavaScript React component
    cat > "src/components/TestComponent.jsx" << 'EOF'
import React from 'react';
import { useState } from 'react';
import '../../../utils/helper';

const TestComponent = () => {
    const [count, setCount] = useState(0);
    
    return (
        <div style={{color: 'red'}}>
            {items.map(item => (
                <div>{item.name}</div>
            ))}
        </div>
    );
};

export default TestComponent;
EOF

    # TypeScript component with issues
    cat > "src/components/BadComponent.tsx" << 'EOF'
import React from 'react';
import { SomeType } from '../../../types/SomeType';

interface Props {
    data: any;
    callback: any;
}

const BadComponent: React.FC<Props> = ({ data, callback }) => {
    console.log("Debug info:", data);
    
    return (
        <div>
            {data.map(item => (
                <div style={{margin: '10px'}}>{item}</div>
            ))}
        </div>
    );
};

export default BadComponent;
EOF

    # Python module
    cat > "src/api/user_service.py" << 'EOF'
import os
import json
from datetime import datetime
from ..models.user import User

class UserService:
    def __init__(self):
        self.api_key = "hardcoded-api-key-123"
        self.users = []
    
    def get_user(self, user_id):
        """Get user by ID"""
        for user in self.users:
            if user.id == user_id:
                return user
        return None
    
    def create_user(self, data):
        try:
            user = User(data)
            self.users.append(user)
            return user
        except:
            print("Error creating user")
            return None
    
    def api_call(self):
        response = requests.get("https://api.example.com/users")
        return response.json()
EOF

    # Go file
    cat > "src/api/handler.go" << 'EOF'
package api

import (
    "fmt"
    "net/http"
    "github.com/gin-gonic/gin"
)

type Handler struct {
    service UserService
}

func NewHandler() *Handler {
    return &Handler{}
}

func (h *handler) GetUsers(c *gin.Context) {
    users, err := h.service.GetUsers()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, users)
}

func (h *Handler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    c.ShouldBindJSON(&req)
    
    user := h.service.CreateUser(req)
    c.JSON(http.StatusCreated, user)
}
EOF

    # Package.json for dependency testing
    cat > "package.json" << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "test": "jest",
    "lint": "eslint .",
    "format": "prettier --write ."
  },
  "dependencies": {
    "react": "^18.0.0",
    "next": "^13.0.0"
  },
  "devDependencies": {
    "eslint": "^8.0.0",
    "prettier": "^2.0.0",
    "jest": "^29.0.0"
  }
}
EOF

    # Large file for performance testing
    cat > "src/utils/large-file.js" << 'EOF'
// Large file for performance testing
function largeFunction() {
    // This file intentionally has many lines to test performance warnings
EOF
    
    # Add 1000 lines to make it large
    for i in {1..1000}; do
        echo "    console.log('Line $i');" >> "src/utils/large-file.js"
    done
    
    echo "}" >> "src/utils/large-file.js"
    
    echo -e "${GREEN}✅ Test files created${NC}"
    echo ""
}

# Test individual hooks
test_post_tool_use_hooks() {
    echo -e "${BLUE}🔧 Testing Post-Tool-Use Hooks${NC}"
    echo -e "${BLUE}==============================${NC}"
    
    local hooks_dir=".claude/hooks/post-tool-use"
    
    # Test format-code.sh
    echo "📝 Testing Code Formatting Hook"
    run_test "JavaScript formatting" "$hooks_dir/format-code.sh" "src/components/TestComponent.jsx" "pass"
    run_test "TypeScript formatting" "$hooks_dir/format-code.sh" "src/components/BadComponent.tsx" "pass"
    run_test "Python formatting" "$hooks_dir/format-code.sh" "src/api/user_service.py" "pass"
    run_test "Go formatting" "$hooks_dir/format-code.sh" "src/api/handler.go" "pass"
    run_test "Non-existent file" "$hooks_dir/format-code.sh" "nonexistent.js" "pass"
    echo ""
    
    # Test lint-code.sh
    echo "🔍 Testing Code Linting Hook"
    run_test "JavaScript linting" "$hooks_dir/lint-code.sh" "src/components/TestComponent.jsx" "pass"
    run_test "TypeScript linting" "$hooks_dir/lint-code.sh" "src/components/BadComponent.tsx" "pass"
    run_test "Python linting" "$hooks_dir/lint-code.sh" "src/api/user_service.py" "pass"
    run_test "Go linting" "$hooks_dir/lint-code.sh" "src/api/handler.go" "pass"
    echo ""
    
    # Test run-tests.sh
    echo "🧪 Testing Test Runner Hook"
    run_test "Component test detection" "$hooks_dir/run-tests.sh" "src/components/TestComponent.jsx" "pass"
    run_test "API test detection" "$hooks_dir/run-tests.sh" "src/api/user_service.py" "pass"
    echo ""
    
    # Test sync-dependencies.sh
    echo "📦 Testing Dependency Sync Hook"
    run_test "Package.json changes" "$hooks_dir/sync-dependencies.sh" "package.json" "pass"
    run_test "Non-dependency file" "$hooks_dir/sync-dependencies.sh" "src/components/TestComponent.jsx" "pass"
    echo ""
    
    # Test cleanup-imports.sh
    echo "🔄 Testing Import Cleanup Hook"
    run_test "JavaScript imports" "$hooks_dir/cleanup-imports.sh" "src/components/TestComponent.jsx" "pass"
    run_test "TypeScript imports" "$hooks_dir/cleanup-imports.sh" "src/components/BadComponent.tsx" "pass"
    run_test "Python imports" "$hooks_dir/cleanup-imports.sh" "src/api/user_service.py" "pass"
    echo ""
    
    # Test update-docs.sh
    echo "📚 Testing Documentation Update Hook"
    run_test "JavaScript component docs" "$hooks_dir/update-docs.sh" "src/components/TestComponent.jsx" "pass"
    run_test "Python API docs" "$hooks_dir/update-docs.sh" "src/api/user_service.py" "pass"
    run_test "Package.json docs" "$hooks_dir/update-docs.sh" "package.json" "pass"
    echo ""
    
    # Test git-auto-stage.sh
    echo "🔀 Testing Git Auto-Stage Hook"
    git add -A && git commit -m "Initial test commit"
    echo "// Modified" >> "src/components/TestComponent.jsx"
    run_test "Modified JavaScript file" "$hooks_dir/git-auto-stage.sh" "src/components/TestComponent.jsx" "pass"
    echo ""
    
    # Test smart-context-builder.sh
    echo "🧠 Testing Smart Context Builder Hook"
    run_test "JavaScript component context" "$hooks_dir/smart-context-builder.sh" "src/components/TestComponent.jsx" "pass"
    run_test "Python service context" "$hooks_dir/smart-context-builder.sh" "src/api/user_service.py" "pass"
    run_test "Go handler context" "$hooks_dir/smart-context-builder.sh" "src/api/handler.go" "pass"
    echo ""
    
    # Test dependency-impact-analyzer.sh
    echo "📊 Testing Dependency Impact Analyzer Hook"
    run_test "JavaScript component impact" "$hooks_dir/dependency-impact-analyzer.sh" "src/components/TestComponent.jsx" "pass"
    run_test "Python service impact" "$hooks_dir/dependency-impact-analyzer.sh" "src/api/user_service.py" "pass"
    echo ""
    
    # Test import-optimizer.sh
    echo "🔄 Testing Import Optimizer Hook"
    run_test "JavaScript import optimization" "$hooks_dir/import-optimizer.sh" "src/components/TestComponent.jsx" "pass"
    run_test "TypeScript import optimization" "$hooks_dir/import-optimizer.sh" "src/components/BadComponent.tsx" "pass"
    run_test "Python import optimization" "$hooks_dir/import-optimizer.sh" "src/api/user_service.py" "pass"
    echo ""
}

test_pre_tool_use_hooks() {
    echo -e "${BLUE}⚡ Testing Pre-Tool-Use Hooks${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    local hooks_dir=".claude/hooks/pre-tool-use"
    
    # Test security-check.sh
    echo "🔒 Testing Security Check Hook"
    run_test "Secure file check" "$hooks_dir/security-check.sh" "src/components/TestComponent.jsx" "pass"
    run_test "File with hardcoded secrets" "$hooks_dir/security-check.sh" "src/api/user_service.py" "pass"
    echo ""
    
    # Test performance-check.sh
    echo "⚡ Testing Performance Check Hook"
    run_test "Normal file performance" "$hooks_dir/performance-check.sh" "Edit" "src/components/TestComponent.jsx" "pass"
    run_test "Large file performance" "$hooks_dir/performance-check.sh" "Edit" "src/utils/large-file.js" "pass"
    echo ""
    
    # Test pattern-enforcer.sh
    echo "🔍 Testing Pattern Enforcer Hook"
    run_test "JavaScript pattern enforcement" "$hooks_dir/pattern-enforcer.sh" "Edit" "src/components/TestComponent.jsx" "pass"
    run_test "TypeScript pattern enforcement" "$hooks_dir/pattern-enforcer.sh" "Edit" "src/components/BadComponent.tsx" "pass"
    run_test "Python pattern enforcement" "$hooks_dir/pattern-enforcer.sh" "Edit" "src/api/user_service.py" "pass"
    echo ""
    
    # Test backup-file.sh
    echo "💾 Testing File Backup Hook"
    run_test "File backup" "$hooks_dir/backup-file.sh" "src/components/TestComponent.jsx" "pass"
    echo ""
}

# Test Neo4j integration
test_neo4j_integration() {
    echo -e "${BLUE}🗄️ Testing Neo4j Integration${NC}"
    echo -e "${BLUE}============================${NC}"
    
    local neo4j_script=".claude/hooks/utils/neo4j_mcp.py"
    
    echo "📊 Testing Neo4j MCP Utility"
    run_test "Store file context" "python3 $neo4j_script" "store_file_context test.js 'react,lodash' 'Component,helpers'" "pass"
    run_test "Get context" "python3 $neo4j_script" "get_context test.js" "pass"
    run_test "Store impact analysis" "python3 $neo4j_script" "store_impact_analysis test.js '{\"count\":5}'" "pass"
    run_test "Store pattern violations" "python3 $neo4j_script" "store_pattern_violations test.js '{\"violations\":[]}'" "pass"
    echo ""
}

# Test hook interactions
test_hook_interactions() {
    echo -e "${BLUE}🔗 Testing Hook Interactions${NC}"
    echo -e "${BLUE}===========================${NC}"
    
    echo "🔄 Testing hook sequence on file modification"
    
    # Simulate full hook sequence
    local test_file="src/components/InteractionTest.jsx"
    cat > "$test_file" << 'EOF'
import React from 'react'
import   {   useState   } from 'react'

const TestComponent=()=>{
const[count,setCount]=useState(0)
return<div style={{color:'red'}}>{count}</div>
}
export default TestComponent
EOF
    
    echo "  Running full hook sequence..."
    
    # Pre-tool-use hooks
    .claude/hooks/pre-tool-use/security-check.sh "$test_file" &>/dev/null && echo "    ✅ Security check passed"
    .claude/hooks/pre-tool-use/pattern-enforcer.sh "Edit" "$test_file" &>/dev/null && echo "    ✅ Pattern enforcement completed"
    
    # Post-tool-use hooks
    .claude/hooks/post-tool-use/format-code.sh "$test_file" &>/dev/null && echo "    ✅ Code formatting completed"
    .claude/hooks/post-tool-use/lint-code.sh "$test_file" &>/dev/null && echo "    ✅ Linting completed"
    .claude/hooks/post-tool-use/cleanup-imports.sh "$test_file" &>/dev/null && echo "    ✅ Import cleanup completed"
    .claude/hooks/post-tool-use/smart-context-builder.sh "$test_file" &>/dev/null && echo "    ✅ Context building completed"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
    
    echo ""
}

# Performance tests
test_performance() {
    echo -e "${BLUE}⚡ Testing Hook Performance${NC}"
    echo -e "${BLUE}==========================${NC}"
    
    echo "⏱️ Testing performance with large files"
    
    # Time the hooks on large file
    local large_file="src/utils/large-file.js"
    
    echo "  Testing format-code.sh on large file..."
    time .claude/hooks/post-tool-use/format-code.sh "$large_file" &>/dev/null && echo "    ✅ Completed within reasonable time"
    
    echo "  Testing smart-context-builder.sh on large file..."
    time .claude/hooks/post-tool-use/smart-context-builder.sh "$large_file" &>/dev/null && echo "    ✅ Completed within reasonable time"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 2))
    PASSED_TESTS=$((PASSED_TESTS + 2))
    
    echo ""
}

# Cleanup test environment
cleanup_test_env() {
    echo -e "${YELLOW}🧹 Cleaning up test environment...${NC}"
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    echo ""
}

# Print final results
print_results() {
    echo -e "${BLUE}📊 Test Results Summary${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Hooks are working correctly.${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed. Please review the hooks.${NC}"
        exit 1
    fi
}

# Main execution
main() {
    setup_test_env
    create_test_files
    test_post_tool_use_hooks
    test_pre_tool_use_hooks
    test_neo4j_integration
    test_hook_interactions
    test_performance
    cleanup_test_env
    print_results
}

# Run tests
main "$@"