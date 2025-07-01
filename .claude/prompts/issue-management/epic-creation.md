# 🎯 Epic Creation & Management Prompt

## **Context**
You are tasked with creating and managing GitHub Epics for complex, multi-issue initiatives. Your goal is to structure large features or improvements into manageable, trackable work packages.

## **Instructions**

### **1. Epic Analysis Phase**
- **Understand Business Value**: What problem does this epic solve? What value does it deliver?
- **Define Success Criteria**: Create measurable, specific outcomes that define completion
- **Assess Complexity**: Evaluate scope, technical difficulty, and resource requirements
- **Identify Stakeholders**: Who are the key stakeholders and decision makers?

### **2. Epic Structure Creation**
- **Title Format**: `[EPIC] [Category] Brief Description`
- **Labels**: Always include `epic`, `enhancement`, appropriate scope labels
- **Milestone**: Create dedicated milestone or assign to existing epic milestone
- **Priority**: Assess business impact and urgency (high/medium/low)

### **3. Sub-Issue Breakdown**
- **Granularity**: Break epic into 5-15 manageable issues
- **Sizing**: Each sub-issue should be 1-5 days of work
- **Dependencies**: Map prerequisite relationships between sub-issues
- **Ownership**: Consider team assignments and expertise areas

### **4. Timeline Planning**
- **Duration Estimate**: Realistic timeframe based on complexity and team capacity
- **Phase Planning**: Group related sub-issues into logical phases/weeks
- **Buffer Time**: Include 20-30% buffer for unexpected complexity
- **Milestone Creation**: Create phase-based milestones with due dates

### **5. Success Tracking**
- **Progress Metrics**: Define how progress will be measured
- **Quality Gates**: Establish review and testing criteria
- **Completion Criteria**: Clear definition of "done" for the epic
- **Acceptance Testing**: Plan for stakeholder validation

## **Epic Template**
```markdown
## 🎯 Epic Overview
**Business Value**: [Why this epic matters to users/business]
**Success Criteria**: [Specific, measurable outcomes]
**Estimated Timeline**: [X weeks, with key milestones]

## 📊 Current State vs Target State
### Current State
- [Current limitations/problems]
- [Baseline metrics if applicable]

### Target State
- [Desired end state]
- [Target metrics/improvements]

## 📋 Implementation Plan
### Phase 1: [Phase Name] (Week 1)
- [ ] Issue #XXX: [Specific deliverable]
- [ ] Issue #XXX: [Specific deliverable]

### Phase 2: [Phase Name] (Week 2)
- [ ] Issue #XXX: [Specific deliverable]
- [ ] Issue #XXX: [Specific deliverable]

## 🎯 Success Metrics
- [ ] [Measurable success criterion 1]
- [ ] [Measurable success criterion 2]
- [ ] [Measurable success criterion 3]

## 🔗 Dependencies & Risks
**Dependencies**:
- [External dependencies or prerequisite work]

**Risks**:
- [Potential risks and mitigation strategies]

## 🚀 Next Steps
- [ ] Create milestone for Phase 1
- [ ] Create and label all sub-issues
- [ ] Assign initial ownership
- [ ] Schedule kickoff meeting
```

## **Labeling Strategy**
- **Epic Label**: `epic` (required for all epics)
- **Scope Labels**: `backend`, `frontend`, `fullstack`
- **Type Labels**: `enhancement`, `refactor`, `infrastructure`
- **Priority**: `priority: high/medium/low`
- **Special Labels**: `performance`, `security`, `testing` as applicable

## **Milestone Strategy**
- **Epic Milestones**: Create dedicated milestone for large epics
- **Phase Milestones**: Weekly or bi-weekly milestones for epic phases
- **Cross-Epic Milestones**: Shared milestones when epics have dependencies

## **Quality Checklist**
- [ ] Business value clearly articulated
- [ ] Success criteria are measurable
- [ ] Sub-issues are appropriately sized
- [ ] Dependencies are identified and managed
- [ ] Timeline includes realistic buffer
- [ ] Stakeholder approval obtained
- [ ] Quality gates defined
- [ ] Progress tracking plan established

## **Common Epic Categories**
- **Feature Epics**: New user-facing functionality
- **Technical Epics**: Infrastructure improvements, refactoring
- **Quality Epics**: Testing improvements, code cleanup
- **Performance Epics**: Optimization initiatives
- **Security Epics**: Security improvements and compliance