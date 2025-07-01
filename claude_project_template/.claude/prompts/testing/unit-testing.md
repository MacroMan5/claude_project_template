# 🧪 Unit Testing Prompt (TDD London School)

## Context
You are writing comprehensive unit tests following Test-Driven Development (TDD) principles, specifically the London School approach with behavior verification and proper mocking strategies.

## TDD Process

### Red-Green-Refactor Cycle

#### 1. RED Phase (Write Failing Tests)
**IMPORTANT**: Write tests BEFORE implementation!

```python
# Example structure
def test_feature_should_behavior_when_condition():
    # Arrange
    mock_dependency = Mock()
    system_under_test = Component(mock_dependency)
    
    # Act
    result = system_under_test.method(input_data)
    
    # Assert
    assert result == expected_output
    mock_dependency.verify_was_called_with(expected_args)
```

**Test Categories to Include**:
1. **Happy Path Tests**
   - Normal, expected usage
   - Valid inputs
   - Successful outcomes

2. **Edge Cases**
   - Boundary values
   - Empty collections
   - Null/undefined inputs
   - Maximum/minimum values

3. **Error Scenarios**
   - Invalid inputs
   - Missing dependencies
   - Network failures
   - Timeout scenarios

4. **State Verification**
   - Object state changes
   - Side effects
   - Database updates
   - Event emissions

#### 2. GREEN Phase (Minimal Implementation)
Write ONLY enough code to make tests pass:
- No premature optimization
- No extra features
- Simple, direct implementation
- Focus on correctness

#### 3. REFACTOR Phase (Improve Quality)
With tests as safety net:
- Extract methods/classes
- Remove duplication
- Improve naming
- Apply design patterns
- Optimize performance

## Unit Test Structure

### Test Organization
```
tests/
├── unit/
│   ├── test_[module]_[feature].py
│   ├── test_[module]_edge_cases.py
│   └── test_[module]_errors.py
├── fixtures/
│   └── [shared test data]
└── mocks/
    └── [reusable mocks]
```

### Test Naming Conventions
```python
# Pattern: test_[unit]_should_[behavior]_when_[condition]
def test_user_service_should_return_user_when_valid_id_provided()
def test_auth_middleware_should_reject_when_token_expired()
def test_calculator_should_throw_error_when_dividing_by_zero()
```

## Mocking Strategies

### When to Mock
- External services (APIs, databases)
- File system operations
- Time-dependent functionality
- Random number generation
- Complex dependencies

### Mock Types
```python
# 1. Simple Mock
mock_service = Mock()
mock_service.get_user.return_value = {"id": 1, "name": "Test"}

# 2. Mock with Side Effects
mock_api = Mock()
mock_api.call.side_effect = [Success(), NetworkError(), Success()]

# 3. Partial Mock (Spy)
real_service = UserService()
spy = Mock(wraps=real_service)
spy.internal_method = Mock(return_value="mocked")

# 4. Property Mock
type(mock_obj).property_name = PropertyMock(return_value="value")
```

## Test Patterns

### 1. Arrange-Act-Assert (AAA)
```python
def test_example():
    # Arrange - Set up test data and mocks
    test_data = create_test_data()
    mock_repo = Mock()
    service = Service(mock_repo)
    
    # Act - Execute the method under test
    result = service.process(test_data)
    
    # Assert - Verify outcomes
    assert result.status == "success"
    mock_repo.save.assert_called_once_with(test_data)
```

### 2. Given-When-Then (BDD Style)
```python
def test_order_processing():
    # Given - Initial context
    given_an_order_with_items(3)
    and_inventory_is_available()
    
    # When - Action occurs
    when_order_is_processed()
    
    # Then - Expected outcome
    then_order_status_should_be("confirmed")
    and_inventory_should_be_reduced_by(3)
```

### 3. Parameterized Tests
```python
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (-1, 1),
    (10, 3628800),
])
def test_factorial(input, expected):
    assert factorial(input) == expected
```

## Coverage Standards

### Target Metrics
- **Line Coverage**: 80% minimum
- **Branch Coverage**: 75% minimum
- **Real Execution**: 60% minimum (not just mocks)

### Coverage Focus Areas
1. **Business Logic**: 100% coverage target
2. **Error Handling**: All error paths tested
3. **Edge Cases**: Comprehensive boundary testing
4. **Integration Points**: Proper mock verification

### What NOT to Test
- Third-party library internals
- Language features
- Simple getters/setters (unless logic exists)
- Framework functionality

## Test Quality Checklist

### Each Test Should Be:
- **Fast**: < 100ms execution time
- **Isolated**: No dependencies on other tests
- **Repeatable**: Same result every run
- **Self-Validating**: Clear pass/fail
- **Thorough**: Tests one specific behavior

### Good Test Characteristics:
- ✅ Descriptive names
- ✅ Single assertion focus
- ✅ No magic numbers
- ✅ Clear arrangement
- ✅ Obvious intent
- ✅ Minimal mocking
- ✅ No test interdependencies

### Bad Test Smells:
- ❌ Testing multiple behaviors
- ❌ Complex setup
- ❌ Unclear assertions
- ❌ Over-mocking
- ❌ Testing implementation details
- ❌ Flaky/intermittent failures
- ❌ Slow execution

## Example Test Suite

```python
class TestUserService:
    """Comprehensive test suite for UserService."""
    
    @pytest.fixture
    def mock_repository(self):
        """Provide mock user repository."""
        return Mock(spec=UserRepository)
    
    @pytest.fixture
    def service(self, mock_repository):
        """Provide UserService instance with mocked dependencies."""
        return UserService(mock_repository)
    
    def test_create_user_should_save_when_valid_data(self, service, mock_repository):
        """Test successful user creation."""
        # Arrange
        user_data = {"name": "John", "email": "john@example.com"}
        mock_repository.save.return_value = User(id=1, **user_data)
        
        # Act
        result = service.create_user(user_data)
        
        # Assert
        assert result.id == 1
        assert result.name == "John"
        mock_repository.save.assert_called_once()
    
    def test_create_user_should_raise_when_email_exists(self, service, mock_repository):
        """Test duplicate email handling."""
        # Arrange
        mock_repository.find_by_email.return_value = existing_user
        
        # Act & Assert
        with pytest.raises(DuplicateEmailError):
            service.create_user({"email": "existing@example.com"})
    
    @pytest.mark.parametrize("invalid_email", [
        "",
        "not-an-email",
        "@example.com",
        "user@",
        None,
    ])
    def test_create_user_should_reject_invalid_emails(self, service, invalid_email):
        """Test email validation."""
        with pytest.raises(ValidationError):
            service.create_user({"email": invalid_email})
```

## Testing Commands

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/test_user_service.py

# Run tests matching pattern
pytest -k "test_create_user"

# Run with verbose output
pytest -v

# Run failed tests only
pytest --lf
```

### Coverage Analysis
```bash
# Generate coverage report
coverage run -m pytest
coverage report
coverage html

# Check coverage thresholds
coverage report --fail-under=80
```

## Final Notes

Remember:
1. **Write tests first** - Always RED before GREEN
2. **Test behavior, not implementation** - Focus on what, not how
3. **Keep tests simple** - Complex tests hide bugs
4. **One assertion per test** - Clear failure identification
5. **Mock external dependencies** - Keep tests fast and isolated
6. **Review test code** - Tests are code too
7. **Maintain tests** - Refactor as code evolves