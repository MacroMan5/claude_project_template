# 🏷️ GitHub Issue Labeling System

## **Context**
You are responsible for implementing and maintaining a comprehensive, consistent labeling system for GitHub issues that enables effective project management, filtering, and progress tracking.

## **Core Labeling Taxonomy**

### **Priority Labels** (Required for all issues)
```yaml
priority: high:
  color: "D73A4A"  # Red
  description: "Critical path items, blocks other work, security issues"
  usage: "Use sparingly - max 20% of issues"

priority: medium:
  color: "FBCA04"  # Yellow  
  description: "Important features, planned improvements"
  usage: "Standard priority for most planned work"

priority: low:
  color: "0E8A16"  # Green
  description: "Nice to have, can be deferred, minor improvements"
  usage: "Documentation, minor bugs, future enhancements"
```

### **Type Labels** (Required for all issues)
```yaml
type: bug:
  color: "D73A4A"  # Red
  description: "Something isn't working correctly"
  
type: enhancement:
  color: "A2EEEF"  # Light Blue
  description: "New feature or improvement request"
  
type: testing:
  color: "C5DEF5"  # Light Blue
  description: "Testing related improvements and fixes"
  
type: cleanup:
  color: "F9D0C4"  # Light Pink  
  description: "Code cleanup and refactoring tasks"
  
type: documentation:
  color: "0075CA"  # Blue
  description: "Documentation improvements"
```

### **Scope Labels** (Domain-specific)
```yaml
backend:
  color: "FF6B6B"  # Red
  description: "Backend/API related issues"
  
frontend:
  color: "4ECDC4"  # Teal
  description: "Frontend/UI related issues"
  
database:
  color: "8B5A2B"  # Brown
  description: "Database and data-related issues"
  
infrastructure:
  color: "6C5CE7"  # Purple
  description: "DevOps, deployment, infrastructure"
  
security:
  color: "2D3436"  # Dark Gray
  description: "Security related issues"
```

### **Special Purpose Labels**
```yaml
epic:
  color: "7B68EE"  # Medium Slate Blue
  description: "Large feature or initiative spanning multiple issues"
  
performance:
  color: "FF9500"  # Orange
  description: "Performance optimization and improvements"
  
optimization:
  color: "FFA500"  # Orange Red
  description: "Code and system optimization tasks"
  
breaking-change:
  color: "B60205"  # Dark Red
  description: "Changes that break backward compatibility"
  
good-first-issue:
  color: "7057FF"  # Blue Violet
  description: "Good for newcomers to the project"
```

### **Status Labels** (Workflow tracking)
```yaml
status: in-progress:
  color: "FBCA04"  # Yellow
  description: "Currently being worked on"
  
status: blocked:
  color: "D73A4A"  # Red
  description: "Cannot proceed due to external dependency"
  
status: needs-review:
  color: "0075CA"  # Blue
  description: "Ready for review by maintainers"
  
status: ready-for-test:
  color: "0E8A16"  # Green
  description: "Implementation complete, ready for testing"
```

## **Labeling Rules & Guidelines**

### **Required Label Combinations**
Every issue MUST have:
1. **One Priority Label**: `priority: high/medium/low`
2. **One Type Label**: `type: bug/enhancement/testing/cleanup/documentation`
3. **At least one Scope Label**: `backend/frontend/database/infrastructure/security`

### **Optional but Recommended**
- **Epic Label**: For large multi-issue initiatives
- **Special Purpose Labels**: For performance, optimization, breaking changes
- **Status Labels**: For workflow tracking

### **Labeling Workflow**
1. **Initial Triage**: Apply priority and type labels within 24 hours
2. **Scope Assignment**: Add domain-specific scope labels
3. **Epic Linking**: Add epic label if part of larger initiative
4. **Status Tracking**: Update status labels as work progresses
5. **Final Review**: Ensure all required labels present before closing

## **Label Creation Commands**

### **Priority Labels**
```bash
gh label create "priority: high" --color "D73A4A" --description "Critical path items, blocks other work"
gh label create "priority: medium" --color "FBCA04" --description "Important features, planned improvements"  
gh label create "priority: low" --color "0E8A16" --description "Nice to have, can be deferred"
```

### **Type Labels**
```bash
gh label create "type: testing" --color "C5DEF5" --description "Testing related improvements and fixes"
gh label create "type: cleanup" --color "F9D0C4" --description "Code cleanup and refactoring tasks"
```

### **Scope Labels**
```bash
gh label create "backend" --color "FF6B6B" --description "Backend/API related issues"
gh label create "frontend" --color "4ECDC4" --description "Frontend/UI related issues"
```

### **Special Purpose Labels**
```bash
gh label create "performance" --color "FF9500" --description "Performance optimization and improvements"
gh label create "optimization" --color "FFA500" --description "Code and system optimization tasks"
```

## **Labeling Patterns by Issue Type**

### **Bug Reports**
- `type: bug` + `priority: high/medium/low` + scope label
- Add `status: blocked` if waiting on external fix
- Add `breaking-change` if fix changes public API

### **Feature Requests**
- `type: enhancement` + `priority: medium/low` + scope label
- Add `epic` if large multi-issue feature
- Add `performance` if performance-related improvement

### **Technical Debt**
- `type: cleanup` + `priority: medium/low` + scope label
- Add `performance` or `optimization` as applicable
- Consider grouping under technical debt epic

### **Testing Issues**
- `type: testing` + `priority: high/medium` + scope label
- Add `epic` if part of larger testing initiative
- Use with `type: cleanup` for test refactoring

## **Label Maintenance**

### **Weekly Review**
- Audit issues for missing required labels
- Update priority labels based on changed business needs
- Clean up orphaned status labels
- Ensure epic labels are properly applied

### **Monthly Cleanup**
- Review label usage statistics
- Identify underused or redundant labels
- Standardize label descriptions
- Update label colors for consistency

### **Quality Metrics**
- **Labeling Coverage**: % of issues with all required labels
- **Consistency Score**: % of similar issues with similar labels
- **Response Time**: Time from issue creation to initial labeling

## **Anti-Patterns to Avoid**
- ❌ **Priority Inflation**: Not everything is high priority
- ❌ **Label Proliferation**: Too many similar labels
- ❌ **Inconsistent Application**: Same issue types labeled differently
- ❌ **Stale Status Labels**: Outdated workflow status labels
- ❌ **Missing Scope**: Issues without domain classification

## **Advanced Labeling Strategies**

### **Epic Management**
- Use `epic` label on parent issues
- Reference epic number in sub-issue titles
- Create epic-specific labels for large initiatives

### **Release Planning**
- Create version-specific labels (e.g., `v2.0`, `v2.1`)
- Use milestone + label combination for release tracking
- Apply `breaking-change` labels for upgrade planning

### **Team Coordination**
- Create team-specific labels if needed (e.g., `team: backend`)
- Use `good-first-issue` for contributor onboarding
- Apply `needs-review` for maintainer attention