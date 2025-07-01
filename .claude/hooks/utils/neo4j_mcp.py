#!/usr/bin/env python3
"""
Neo4j MCP Integration for Claude Code Hooks
Provides utilities for updating the knowledge graph automatically
"""

import os
import sys
import json
import subprocess
import re
from typing import Dict, List, Optional, Any
from pathlib import Path

class Neo4jMCPIntegrator:
    def __init__(self):
        self.project_name = os.getenv('PROJECT_NAME', os.path.basename(os.getcwd()))
        self.logs_dir = os.getenv('CLAUDE_LOGS_DIR', '.claude/hooks/logs')
        
    def log(self, message: str, level: str = "INFO"):
        """Log message to hooks log file"""
        timestamp = subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], 
                                 capture_output=True, text=True).stdout.strip()
        log_entry = f"{timestamp} - [{level}] Neo4j MCP: {message}\n"
        
        os.makedirs(self.logs_dir, exist_ok=True)
        with open(f"{self.logs_dir}/hooks.log", "a") as f:
            f.write(log_entry)
    
    def is_neo4j_available(self) -> bool:
        """Check if Neo4j is available"""
        try:
            result = subprocess.run(['nc', '-z', 'localhost', '7687'], 
                                  capture_output=True, timeout=5)
            return result.returncode == 0
        except:
            return False
    
    def execute_mcp_call(self, tool_name: str, params: Dict[str, Any]) -> Optional[Dict]:
        """Execute MCP tool call"""
        if not self.is_neo4j_available():
            self.log("Neo4j not available, skipping MCP call", "WARN")
            return None
            
        try:
            # For now, log the MCP call - in real implementation, this would call the MCP server
            self.log(f"MCP Call: {tool_name} with params: {json.dumps(params)}")
            
            # Simulate MCP call response
            return {"status": "success", "tool": tool_name}
            
        except Exception as e:
            self.log(f"MCP call failed: {str(e)}", "ERROR")
            return None
    
    def extract_component_info(self, file_path: str, content: str = None) -> Dict[str, Any]:
        """Extract component information from file"""
        if content is None and os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        
        if not content:
            return {}
            
        info = {
            "name": os.path.basename(file_path),
            "path": file_path,
            "type": self.detect_component_type(file_path, content),
            "language": self.detect_language(file_path),
            "observations": []
        }
        
        # Extract classes, functions, etc.
        if info["language"] == "python":
            info["observations"].extend(self.extract_python_elements(content))
        elif info["language"] in ["javascript", "typescript"]:
            info["observations"].extend(self.extract_js_elements(content))
        elif info["language"] == "go":
            info["observations"].extend(self.extract_go_elements(content))
        
        return info
    
    def detect_component_type(self, file_path: str, content: str) -> str:
        """Detect the type of component"""
        filename = os.path.basename(file_path).lower()
        
        if 'test' in filename or 'spec' in filename:
            return "test"
        elif filename.endswith('.md'):
            return "documentation"
        elif filename in ['dockerfile', 'docker-compose.yml', 'docker-compose.yaml']:
            return "infrastructure"
        elif filename in ['package.json', 'requirements.txt', 'go.mod', 'cargo.toml']:
            return "configuration"
        elif 'api' in filename or 'route' in filename:
            return "api"
        elif 'model' in filename or 'schema' in filename:
            return "model"
        elif 'service' in filename:
            return "service"
        elif 'util' in filename or 'helper' in filename:
            return "utility"
        else:
            return "component"
    
    def detect_language(self, file_path: str) -> str:
        """Detect programming language from file extension"""
        ext = os.path.splitext(file_path)[1].lower()
        
        lang_map = {
            '.py': 'python',
            '.js': 'javascript',
            '.jsx': 'javascript',
            '.ts': 'typescript',
            '.tsx': 'typescript',
            '.go': 'go',
            '.rs': 'rust',
            '.java': 'java',
            '.cpp': 'cpp',
            '.cc': 'cpp',
            '.cxx': 'cpp',
            '.c': 'c',
            '.sh': 'shell',
            '.bash': 'shell',
            '.rb': 'ruby',
            '.php': 'php',
            '.swift': 'swift',
            '.kt': 'kotlin'
        }
        
        return lang_map.get(ext, 'unknown')
    
    def extract_python_elements(self, content: str) -> List[str]:
        """Extract Python classes and functions"""
        elements = []
        
        # Find classes
        class_pattern = r'class\s+(\w+)(?:\([^)]*\))?:'
        classes = re.findall(class_pattern, content)
        for class_name in classes:
            elements.append(f"Defines class: {class_name}")
        
        # Find functions
        func_pattern = r'def\s+(\w+)\s*\([^)]*\):'
        functions = re.findall(func_pattern, content)
        for func_name in functions:
            if not func_name.startswith('_'):  # Skip private functions
                elements.append(f"Defines function: {func_name}")
        
        # Find imports
        import_pattern = r'(?:from\s+(\S+)\s+)?import\s+([^\n]+)'
        imports = re.findall(import_pattern, content)
        for from_mod, import_items in imports:
            if from_mod:
                elements.append(f"Imports from {from_mod}: {import_items}")
            else:
                elements.append(f"Imports: {import_items}")
        
        return elements
    
    def extract_js_elements(self, content: str) -> List[str]:
        """Extract JavaScript/TypeScript elements"""
        elements = []
        
        # Find function declarations
        func_pattern = r'function\s+(\w+)\s*\('
        functions = re.findall(func_pattern, content)
        for func_name in functions:
            elements.append(f"Defines function: {func_name}")
        
        # Find arrow functions assigned to variables
        arrow_pattern = r'(?:const|let|var)\s+(\w+)\s*=\s*(?:\([^)]*\)|[^=])*=>'
        arrow_funcs = re.findall(arrow_pattern, content)
        for func_name in arrow_funcs:
            elements.append(f"Defines arrow function: {func_name}")
        
        # Find class declarations
        class_pattern = r'class\s+(\w+)(?:\s+extends\s+\w+)?'
        classes = re.findall(class_pattern, content)
        for class_name in classes:
            elements.append(f"Defines class: {class_name}")
        
        # Find exports
        export_pattern = r'export\s+(?:default\s+)?(?:class|function|const|let|var)?\s*(\w+)'
        exports = re.findall(export_pattern, content)
        for export_name in exports:
            elements.append(f"Exports: {export_name}")
        
        return elements
    
    def extract_go_elements(self, content: str) -> List[str]:
        """Extract Go elements"""
        elements = []
        
        # Find function declarations
        func_pattern = r'func\s+(?:\([^)]*\)\s+)?(\w+)\s*\('
        functions = re.findall(func_pattern, content)
        for func_name in functions:
            elements.append(f"Defines function: {func_name}")
        
        # Find struct declarations
        struct_pattern = r'type\s+(\w+)\s+struct'
        structs = re.findall(struct_pattern, content)
        for struct_name in structs:
            elements.append(f"Defines struct: {struct_name}")
        
        # Find interface declarations
        interface_pattern = r'type\s+(\w+)\s+interface'
        interfaces = re.findall(interface_pattern, content)
        for interface_name in interfaces:
            elements.append(f"Defines interface: {interface_name}")
        
        return elements
    
    def create_or_update_entity(self, file_path: str, action: str = "create", content: str = None):
        """Create or update entity in Neo4j knowledge graph"""
        component_info = self.extract_component_info(file_path, content)
        
        if not component_info:
            self.log(f"No component info extracted for {file_path}", "WARN")
            return
        
        if action == "create":
            # Create new entity
            entity_data = {
                "name": component_info["name"],
                "entityType": component_info["type"],
                "observations": [
                    f"File path: {component_info['path']}",
                    f"Language: {component_info['language']}",
                    f"Component type: {component_info['type']}"
                ] + component_info["observations"]
            }
            
            self.execute_mcp_call("mcp__memory__create_entities", {"entities": [entity_data]})
            
        elif action == "edit":
            # Add observation to existing entity
            observation = f"Modified {file_path} - {len(component_info['observations'])} elements detected"
            if component_info["observations"]:
                observation += f": {', '.join(component_info['observations'][:3])}"
            
            self.execute_mcp_call("mcp__memory__add_observations", {
                "observations": [{
                    "entityName": component_info["name"],
                    "contents": [observation]
                }]
            })
    
    def create_relationships(self, file_path: str, content: str = None):
        """Create relationships between components"""
        if content is None and os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        
        if not content:
            return
        
        file_name = os.path.basename(file_path)
        relationships = []
        
        # Find import relationships
        if file_path.endswith('.py'):
            import_pattern = r'from\s+([^\s]+)\s+import'
            imports = re.findall(import_pattern, content)
            for imported in imports:
                if not imported.startswith('.'):  # Skip relative imports for now
                    relationships.append({
                        "from": file_name,
                        "to": imported,
                        "relationType": "imports"
                    })
        
        if relationships:
            self.execute_mcp_call("mcp__memory__create_relations", {"relations": relationships})
    
    def log_development_activity(self, action: str, file_path: str, details: str = ""):
        """Log development activity to knowledge graph"""
        activity_entity = {
            "name": f"Activity_{action}_{os.path.basename(file_path)}_{int(subprocess.run(['date', '+%s'], capture_output=True, text=True).stdout.strip())}",
            "entityType": "activity",
            "observations": [
                f"Action: {action}",
                f"File: {file_path}",
                f"Project: {self.project_name}",
                f"Details: {details}",
                f"Timestamp: {subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], capture_output=True, text=True).stdout.strip()}"
            ]
        }
        
        self.execute_mcp_call("mcp__memory__create_entities", {"entities": [activity_entity]})

    def store_file_context(self, file_path: str, imports: str, exports: str):
        """Store file context for smart context builder"""
        try:
            # Create knowledge cache directory
            cache_dir = os.path.join(os.getcwd(), '.claude', 'knowledge')
            os.makedirs(cache_dir, exist_ok=True)
            
            context_data = {
                'file': file_path,
                'imports': imports.split() if imports else [],
                'exports': exports.split() if exports else [],
                'timestamp': subprocess.run(['date', '+%Y-%m-%d %H:%M:%S'], capture_output=True, text=True).stdout.strip()
            }
            
            cache_file = os.path.join(cache_dir, f"{file_path.replace('/', '_')}_context.json")
            with open(cache_file, 'w') as f:
                json.dump(context_data, f, indent=2)
            
            self.log(f"Stored context for {file_path}")
            return True
        except Exception as e:
            self.log(f"Error storing context: {e}", "ERROR")
            return False

    def store_impact_analysis(self, file_path: str, impact_data: str):
        """Store dependency impact analysis"""
        try:
            cache_dir = os.path.join(os.getcwd(), '.claude', 'knowledge') 
            os.makedirs(cache_dir, exist_ok=True)
            
            cache_file = os.path.join(cache_dir, f"{file_path.replace('/', '_')}_impact.json")
            with open(cache_file, 'w') as f:
                f.write(impact_data)
            
            self.log(f"Stored impact analysis for {file_path}")
            return True
        except Exception as e:
            self.log(f"Error storing impact analysis: {e}", "ERROR")
            return False

    def store_pattern_violations(self, file_path: str, pattern_data: str):
        """Store pattern enforcement violations"""
        try:
            cache_dir = os.path.join(os.getcwd(), '.claude', 'knowledge')
            os.makedirs(cache_dir, exist_ok=True)
            
            cache_file = os.path.join(cache_dir, f"{file_path.replace('/', '_')}_violations.json")
            with open(cache_file, 'w') as f:
                f.write(pattern_data)
            
            self.log(f"Stored pattern violations for {file_path}")
            return True
        except Exception as e:
            self.log(f"Error storing pattern violations: {e}", "ERROR") 
            return False

    def store_optimization_metrics(self, file_path: str, metrics_data: str):
        """Store import optimization metrics"""
        try:
            cache_dir = os.path.join(os.getcwd(), '.claude', 'knowledge')
            os.makedirs(cache_dir, exist_ok=True)
            
            cache_file = os.path.join(cache_dir, f"{file_path.replace('/', '_')}_optimization.json")
            with open(cache_file, 'w') as f:
                f.write(metrics_data)
            
            self.log(f"Stored optimization metrics for {file_path}")
            return True
        except Exception as e:
            self.log(f"Error storing optimization metrics: {e}", "ERROR")
            return False

    def get_context(self, file_path: str) -> Optional[str]:
        """Retrieve smart context for a file"""
        try:
            cache_dir = os.path.join(os.getcwd(), '.claude', 'knowledge')
            
            context_parts = []
            
            # Get file context
            context_file = os.path.join(cache_dir, f"{file_path.replace('/', '_')}_context.json")
            if os.path.exists(context_file):
                with open(context_file, 'r') as f:
                    data = json.load(f)
                    if data.get('imports'):
                        context_parts.append(f"Imports: {', '.join(data['imports'])}")
                    if data.get('exports'):
                        context_parts.append(f"Exports: {', '.join(data['exports'])}")
            
            # Get recent impact analysis
            impact_file = os.path.join(cache_dir, f"{file_path.replace('/', '_')}_impact.json")
            if os.path.exists(impact_file):
                with open(impact_file, 'r') as f:
                    data = json.load(f)
                    if data.get('count', 0) > 0:
                        context_parts.append(f"Impact: {data['count']} dependent files")
            
            return '\n'.join(context_parts) if context_parts else None
        except Exception as e:
            self.log(f"Error getting context: {e}", "ERROR")
            return None

def main():
    """Main function for command-line usage"""
    if len(sys.argv) < 2:
        print("Usage: neo4j_mcp.py <action> [args...]")
        sys.exit(1)
    
    action = sys.argv[1]
    integrator = Neo4jMCPIntegrator()
    
    try:
        if action in ["create", "edit"] and len(sys.argv) >= 3:
            file_path = sys.argv[2]
            content = sys.argv[3] if len(sys.argv) > 3 else None
            integrator.create_or_update_entity(file_path, action, content)
            integrator.create_relationships(file_path, content)
        
        elif action == "store_file_context" and len(sys.argv) >= 5:
            file_path, imports, exports = sys.argv[2], sys.argv[3], sys.argv[4]
            result = integrator.store_file_context(file_path, imports, exports)
            print("success" if result else "failed")
        
        elif action == "store_impact_analysis" and len(sys.argv) >= 4:
            file_path, impact_data = sys.argv[2], sys.argv[3]
            result = integrator.store_impact_analysis(file_path, impact_data)
            print("success" if result else "failed")
        
        elif action == "store_pattern_violations" and len(sys.argv) >= 4:
            file_path, pattern_data = sys.argv[2], sys.argv[3]
            result = integrator.store_pattern_violations(file_path, pattern_data)
            print("success" if result else "failed")
        
        elif action == "store_optimization_metrics" and len(sys.argv) >= 4:
            file_path, metrics_data = sys.argv[2], sys.argv[3]
            result = integrator.store_optimization_metrics(file_path, metrics_data)
            print("success" if result else "failed")
        
        elif action == "get_context" and len(sys.argv) >= 3:
            file_path = sys.argv[2]
            context = integrator.get_context(file_path)
            print(context if context else "None")
        
        elif action == "log_activity" and len(sys.argv) >= 3:
            file_path = sys.argv[2]
            details = sys.argv[3] if len(sys.argv) > 3 else "File operation"
            integrator.log_development_activity(action, file_path, details)
        
        else:
            integrator.log(f"Unknown action or insufficient arguments: {action}", "ERROR")
            print(f"Unknown action: {action}")
    
    except Exception as e:
        integrator.log(f"Error executing command {action}: {e}", "ERROR")
        print(f"Error: {e}")

if __name__ == "__main__":
    main()