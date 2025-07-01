# 🐛 Debugging & Root Cause Analysis Prompt

## Context
You are systematically debugging issues using root cause analysis, proper logging, and methodical troubleshooting techniques to identify and fix problems efficiently.

## Debugging Process

### Phase 1: Problem Identification

#### 1.1 Understand the Issue
- **Symptoms**: What is the observed behavior?
- **Expected**: What should happen instead?
- **Scope**: When/where does it occur?
- **Frequency**: Always, sometimes, or rarely?
- **Impact**: Who/what is affected?

#### 1.2 Reproduce the Issue
```bash
# Steps to reproduce
1. Environment setup
2. Preconditions
3. Actions taken
4. Expected vs actual results
```

### Phase 2: Investigation

#### 2.1 Gather Information
```python
# Add strategic logging
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def problematic_function(data):
    logger.debug(f"Input data: {data}")
    logger.debug(f"Data type: {type(data)}")
    logger.debug(f"Data length: {len(data) if hasattr(data, '__len__') else 'N/A'}")
    
    try:
        result = process_data(data)
        logger.debug(f"Processing successful: {result}")
        return result
    except Exception as e:
        logger.error(f"Processing failed: {str(e)}", exc_info=True)
        raise
```

#### 2.2 Check Common Causes
- **Input validation**: Are inputs valid?
- **State issues**: Is state consistent?
- **Race conditions**: Timing dependencies?
- **Resource issues**: Memory, disk, network?
- **Dependencies**: External service failures?

#### 2.3 Use Debugging Tools
```python
# Python debugging
import pdb; pdb.set_trace()  # Breakpoint

# Or use debugpy for remote debugging
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()

# JavaScript debugging
debugger;  // Breakpoint
console.trace();  // Stack trace

# Performance profiling
import cProfile
cProfile.run('function_to_profile()')
```

### Phase 3: Root Cause Analysis

#### 3.1 Five Whys Technique
```yaml
Problem: Application crashes on user login

Why 1: Login handler throws exception
  → Why: Database connection fails
    → Why: Connection pool exhausted
      → Why: Connections not released
        → Why: Missing finally block in DB handler
          
Root Cause: Improper resource management
```

#### 3.2 Hypothesis Testing
```python
# Form hypotheses and test systematically
hypotheses = [
    ("Memory leak in cache", check_memory_usage),
    ("Race condition in auth", test_concurrent_logins),
    ("Invalid data format", validate_input_formats),
    ("Network timeout", test_with_delays)
]

for hypothesis, test_func in hypotheses:
    print(f"Testing: {hypothesis}")
    result = test_func()
    print(f"Result: {'CONFIRMED' if result else 'REJECTED'}")
```

### Phase 4: Fix Implementation

#### 4.1 Minimal Fix First
```python
# Fix only the root cause
# BAD: Rewrite entire module
# GOOD: Add specific error handling

def fixed_function(data):
    # Add guard clause for root cause
    if not validate_input(data):
        raise ValueError(f"Invalid input: {data}")
    
    # Original logic with proper error handling
    try:
        return process_data(data)
    finally:
        # Ensure cleanup happens
        cleanup_resources()
```

#### 4.2 Test the Fix
```python
def test_fix():
    # Test the specific issue
    assert fixed_function(valid_data) == expected_result
    
    # Test edge cases
    with pytest.raises(ValueError):
        fixed_function(invalid_data)
    
    # Test doesn't break existing functionality
    assert fixed_function(other_valid_data) == other_expected
```

### Phase 5: Prevention

#### 5.1 Add Regression Tests
```python
def test_regression_issue_123():
    """Ensure login crash doesn't recur."""
    # Setup conditions that caused the bug
    setup_exhausted_connection_pool()
    
    # Attempt login
    result = login_handler(test_credentials)
    
    # Verify fix works
    assert result.status == "success"
    assert connection_pool.available_connections > 0
```

#### 5.2 Improve Monitoring
```python
# Add metrics for early detection
metrics.gauge('db.connection_pool.available', pool.available)
metrics.counter('auth.login.failures', tags=['reason:connection_error'])

# Add alerts
if pool.available < pool.size * 0.1:  # Less than 10% available
    alerts.send("Low database connections", severity="warning")
```

## Common Debugging Patterns

### Memory Issues
```python
# Memory profiling
from memory_profiler import profile

@profile
def memory_intensive_function():
    # Function code
    pass

# Find memory leaks
import gc
import objgraph

gc.collect()
objgraph.show_most_common_types(limit=10)
```

### Performance Issues
```python
# Time profiling
import time
import functools

def timeit(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        end = time.perf_counter()
        print(f"{func.__name__} took {end - start:.4f} seconds")
        return result
    return wrapper

@timeit
def slow_function():
    # Function code
    pass
```

### Concurrency Issues
```python
# Thread safety debugging
import threading

lock = threading.Lock()
shared_resource = []

def thread_safe_function():
    with lock:
        # Critical section
        shared_resource.append(item)
        
# Detect deadlocks
import threading
import time

def detect_deadlock():
    for thread in threading.enumerate():
        print(f"Thread: {thread.name}, State: {thread.is_alive()}")
```

## Debugging Checklist

### Before Starting
- [ ] Can you reproduce the issue?
- [ ] Do you have error messages/logs?
- [ ] Is this a regression?
- [ ] What changed recently?

### During Investigation
- [ ] Added strategic logging?
- [ ] Checked common causes?
- [ ] Formed hypotheses?
- [ ] Used appropriate tools?
- [ ] Documented findings?

### After Fixing
- [ ] Fixed root cause (not symptoms)?
- [ ] Added regression tests?
- [ ] Updated documentation?
- [ ] Improved monitoring?
- [ ] Communicated solution?

## Debug Output Format

### Issue Report
```markdown
## Issue: [Brief Description]

### Environment
- OS: [Operating System]
- Version: [App Version]
- Dependencies: [Key Dependencies]

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### Error Messages
```
[Error output]
```

### Investigation Notes
- [Finding 1]
- [Finding 2]

### Root Cause
[Identified root cause]

### Solution
[How it was fixed]

### Prevention
[Steps taken to prevent recurrence]
```

## Best Practices

### DO:
- ✅ Reproduce before fixing
- ✅ Use version control for experiments
- ✅ Add logging before debugging
- ✅ Test fixes thoroughly
- ✅ Document the solution
- ✅ Consider side effects
- ✅ Clean up debug code
- ✅ Share knowledge with team
- ✅ Improve tests
- ✅ Monitor after deployment

### DON'T:
- ❌ Make random changes
- ❌ Fix symptoms only
- ❌ Skip reproduction steps
- ❌ Ignore error messages
- ❌ Debug in production
- ❌ Make multiple changes at once
- ❌ Forget to test edge cases
- ❌ Leave debug code in production
- ❌ Skip documentation
- ❌ Repeat the same issue