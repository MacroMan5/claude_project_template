# 🚀 Feature Development Prompt (SPARC Methodology)

## Context
You are implementing a new feature using the SPARC (Specification, Pseudocode, Architecture, Refinement, Completion) methodology. This ensures systematic, high-quality development with proper planning and execution.

## Implementation Process

### Phase 1: Specification
Analyze the feature requirements thoroughly:
1. **User Story Analysis**
   - Identify the primary user need
   - Define acceptance criteria
   - Determine success metrics
   - Consider edge cases and error scenarios

2. **Technical Requirements**
   - List functional requirements
   - Define non-functional requirements (performance, security, scalability)
   - Identify system constraints
   - Document API contracts

3. **Dependency Analysis**
   - Map integration points
   - Identify required services/modules
   - Check for potential conflicts
   - Plan data flow

### Phase 2: Pseudocode
Create high-level implementation logic:
1. **Algorithm Design**
   - Write step-by-step logic in plain language
   - Identify key data structures
   - Plan state management
   - Design error handling flow

2. **Interface Definition**
   - Define public APIs
   - Specify input/output formats
   - Document side effects
   - Plan extensibility points

### Phase 3: Architecture
Design the technical architecture:
1. **Component Structure**
   - Create modular, testable components
   - Define clear boundaries
   - Apply SOLID principles
   - Plan for reusability

2. **Data Architecture**
   - Design data models
   - Plan database schema if needed
   - Define data validation rules
   - Consider caching strategies

3. **Integration Architecture**
   - Map service interactions
   - Define communication protocols
   - Plan error recovery
   - Design monitoring points

### Phase 4: Refinement
Implement with quality focus:
1. **Test-Driven Development**
   - Write tests FIRST (red phase)
   - Implement minimum code to pass (green phase)
   - Refactor for quality (refactor phase)
   - Maintain high coverage (80%+ target)

2. **Code Quality**
   - Follow project coding standards
   - Implement proper error handling
   - Add comprehensive logging
   - Include performance considerations

3. **Security Implementation**
   - Validate all inputs
   - Implement proper authentication/authorization
   - Protect against common vulnerabilities
   - Follow security best practices

### Phase 5: Completion
Finalize and validate:
1. **Testing & Validation**
   - Run all unit tests
   - Execute integration tests
   - Perform security scanning
   - Check performance metrics

2. **Documentation**
   - Update API documentation
   - Add inline code comments
   - Update README if needed
   - Document configuration changes

3. **Code Review Preparation**
   - Run linting and formatting
   - Ensure type safety
   - Review test coverage
   - Prepare PR description

## Execution Guidelines

### DO:
- ✅ Read and understand existing code patterns first
- ✅ Follow established project conventions
- ✅ Write tests before implementation
- ✅ Consider performance implications
- ✅ Implement comprehensive error handling
- ✅ Add appropriate logging
- ✅ Validate all user inputs
- ✅ Document complex logic
- ✅ Use meaningful variable/function names
- ✅ Keep functions small and focused

### DON'T:
- ❌ Skip the planning phases
- ❌ Write implementation before tests
- ❌ Ignore existing patterns
- ❌ Add unnecessary complexity
- ❌ Hardcode configuration values
- ❌ Forget error scenarios
- ❌ Skip security considerations
- ❌ Leave TODO comments
- ❌ Commit commented-out code
- ❌ Ignore performance impacts

## Example Workflow

```bash
# 1. Understand the feature
"I need to implement user authentication with JWT tokens"

# 2. Analyze existing code
- Review current auth implementation
- Check for existing JWT utilities
- Understand user model structure

# 3. Write tests first
- Test JWT generation
- Test token validation
- Test refresh flow
- Test error cases

# 4. Implement features
- Create JWT service
- Implement auth middleware
- Add refresh endpoint
- Handle errors properly

# 5. Validate and refine
- Run all tests
- Check security
- Review performance
- Update documentation
```

## Success Criteria

Your implementation should:
1. Pass all tests (unit, integration)
2. Meet performance requirements
3. Follow security best practices
4. Be well-documented
5. Handle errors gracefully
6. Be maintainable and extensible
7. Follow project conventions
8. Have 80%+ test coverage

## Final Checklist

Before marking complete:
- [ ] All tests passing
- [ ] Code reviewed and refactored
- [ ] Documentation updated
- [ ] Security considerations addressed
- [ ] Performance validated
- [ ] Error handling comprehensive
- [ ] Logging implemented
- [ ] Configuration externalized
- [ ] PR description complete
- [ ] No TODO comments remaining