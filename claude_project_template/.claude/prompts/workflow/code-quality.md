# ✨ Code Quality Automation Prompt

## Context
You are implementing and maintaining high code quality standards through automated tools, best practices, and continuous improvement processes. This includes linting, formatting, type checking, and code complexity management.

## Code Quality Stack

### 1. Code Formatting

#### Python - Black & isort
```yaml
# pyproject.toml
[tool.black]
line-length = 88
target-version = ['py38', 'py39', 'py310', 'py311']
include = '\.pyi?$'
extend-exclude = '''
/(
  # directories
  \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
multi_line_output = 3
include_trailing_comma = true
force_grid_wrap = 0
use_parentheses = true
ensure_newline_before_comments = true
line_length = 88
skip_gitignore = true
skip = [".venv", "build", "dist"]
```

#### JavaScript/TypeScript - Prettier
```json
// .prettierrc.json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "arrowParens": "always",
  "endOfLine": "lf",
  "bracketSpacing": true,
  "jsxBracketSameLine": false
}
```

### 2. Linting Configuration

#### Python - Flake8
```ini
# .flake8
[flake8]
max-line-length = 88
extend-ignore = E203, E266, E501, W503
max-complexity = 10
exclude = 
    .git,
    __pycache__,
    docs/source/conf.py,
    old,
    build,
    dist,
    .venv,
    venv
per-file-ignores = 
    __init__.py:F401
    tests/*:S101
```

#### JavaScript/TypeScript - ESLint
```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "prettier"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint", "react", "react-hooks"],
  "rules": {
    "no-console": ["warn", { "allow": ["warn", "error"] }],
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/no-explicit-any": "warn",
    "react/prop-types": "off"
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  }
}
```

### 3. Type Checking

#### Python - mypy
```ini
# mypy.ini
[mypy]
python_version = 3.9
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
check_untyped_defs = True
disallow_untyped_decorators = False
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
warn_unreachable = True
strict_equality = True

[mypy-tests.*]
ignore_errors = True

[mypy-migrations.*]
ignore_errors = True
```

#### TypeScript - tsconfig
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "jsx": "react",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

## Automated Quality Pipeline

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  # Python formatting
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3
  
  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile", "black"]
  
  # Python linting
  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        additional_dependencies: [flake8-docstrings]
  
  # Security scanning
  - repo: https://github.com/pycqa/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: ["-ll"]
        files: .py$
  
  # JavaScript/TypeScript
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.0.0
    hooks:
      - id: prettier
        types_or: [javascript, typescript, tsx, jsx, json, yaml]
  
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.44.0
    hooks:
      - id: eslint
        files: \.[jt]sx?$
        types: [file]
  
  # Secret detection
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

### CI/CD Quality Gates
```yaml
# .github/workflows/quality.yml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt
      
      - name: Run formatters check
        run: |
          black --check src/ tests/
          isort --check-only src/ tests/
      
      - name: Run linters
        run: |
          flake8 src/ tests/
          pylint src/
      
      - name: Run type checker
        run: |
          mypy src/
      
      - name: Check complexity
        run: |
          radon cc src/ -a -nb
          radon mi src/ -nb
      
      - name: Security scan
        run: |
          bandit -r src/ -ll
          safety check
```

## Code Quality Metrics

### Complexity Analysis
```python
# Using radon for Python
"""
Cyclomatic Complexity:
- A: 1-5 (Simple, low risk)
- B: 6-10 (More complex, moderate risk)
- C: 11-20 (Complex, high risk)
- D: 21-50 (More complex, very high risk)
- E: >50 (Unstable, extreme risk)

Maintainability Index:
- A: 100-20 (Very high maintainability)
- B: 19-10 (Medium maintainability)
- C: 9-0 (Extremely low maintainability)
"""

# Example complexity reduction
# BAD: High complexity
def process_data(data, options):
    if data is None:
        return None
    if options.get('validate'):
        if not validate_data(data):
            if options.get('strict'):
                raise ValueError("Invalid data")
            else:
                data = clean_data(data)
    if options.get('transform'):
        if options.get('transform_type') == 'upper':
            data = data.upper()
        elif options.get('transform_type') == 'lower':
            data = data.lower()
        elif options.get('transform_type') == 'title':
            data = data.title()
    # More nested conditions...
    return data

# GOOD: Reduced complexity
def process_data(data, options):
    if data is None:
        return None
    
    data = _validate_if_needed(data, options)
    data = _transform_if_needed(data, options)
    return data

def _validate_if_needed(data, options):
    if not options.get('validate'):
        return data
    
    if validate_data(data):
        return data
    
    if options.get('strict'):
        raise ValueError("Invalid data")
    
    return clean_data(data)

def _transform_if_needed(data, options):
    if not options.get('transform'):
        return data
    
    transform_map = {
        'upper': str.upper,
        'lower': str.lower,
        'title': str.title
    }
    
    transform_func = transform_map.get(options.get('transform_type'))
    return transform_func(data) if transform_func else data
```

### Code Coverage Configuration
```ini
# .coveragerc
[run]
source = src/
omit = 
    */tests/*
    */test_*
    */__init__.py
    */migrations/*
    */config.py

[report]
precision = 2
show_missing = True
skip_covered = False

[html]
directory = htmlcov

[xml]
output = coverage.xml
```

## Error Categorization Framework

### Systematic Error Analysis
```yaml
Error Categories:
  Category A (Build Blockers):
    priority: 1
    description: "Syntax errors, missing imports, type errors breaking CI"
    examples:
      - MyPy type annotation errors
      - Import resolution failures
      - TypeScript compilation errors
      - Critical flake8 violations
    
  Category B (Style/Readability):
    priority: 2
    description: "PEP 8 violations, unused imports, missing docstrings"
    examples:
      - Code formatting issues
      - Unused variables/imports
      - Missing type hints
      - Docstring format violations
    
  Category C (Performance/Optimization):
    priority: 3
    description: "Complex functions, security suggestions, technical debt"
    examples:
      - High complexity methods
      - Security improvement opportunities
      - Performance optimization candidates
      - Code smell patterns
```

### Zero-Error Validation Process
```bash
# Final validation pipeline - must pass with zero errors
mypy src/ --strict
flake8 src/ --max-line-length=88 
pylint src/ --fail-under=8.0
bandit src/ -r
black --check src/
isort --check-only src/

# Frontend validation
cd web/ && npm run lint && tsc --noEmit

# Test validation
pytest tests/ --cov=src --cov-fail-under=80
```

## Quality Improvement Strategies

### 1. Refactoring Patterns
```python
# Extract Method
# Before
def calculate_order_total(order):
    subtotal = 0
    for item in order.items:
        subtotal += item.price * item.quantity
    
    tax = subtotal * 0.08
    shipping = 10 if subtotal < 100 else 0
    discount = subtotal * 0.1 if order.customer.is_premium else 0
    
    return subtotal + tax + shipping - discount

# After
def calculate_order_total(order):
    subtotal = _calculate_subtotal(order.items)
    tax = _calculate_tax(subtotal)
    shipping = _calculate_shipping(subtotal)
    discount = _calculate_discount(subtotal, order.customer)
    
    return subtotal + tax + shipping - discount

def _calculate_subtotal(items):
    return sum(item.price * item.quantity for item in items)

def _calculate_tax(subtotal):
    return subtotal * TAX_RATE

def _calculate_shipping(subtotal):
    return 0 if subtotal >= FREE_SHIPPING_THRESHOLD else SHIPPING_COST

def _calculate_discount(subtotal, customer):
    return subtotal * PREMIUM_DISCOUNT if customer.is_premium else 0
```

### 2. Code Smell Detection
```python
# Common code smells and fixes

# Long Method
# BAD
def process_user_registration(email, password, profile_data):
    # 100+ lines of code doing everything
    pass

# GOOD
def process_user_registration(email, password, profile_data):
    user = create_user(email, password)
    profile = create_profile(user, profile_data)
    send_welcome_email(user)
    log_registration(user)
    return user

# Feature Envy
# BAD
def calculate_charge(order):
    base_price = order.item.price * order.quantity
    discount = order.customer.discount_rate * base_price
    tax = order.customer.tax_rate * (base_price - discount)
    return base_price - discount + tax

# GOOD
class Order:
    def calculate_charge(self):
        base_price = self.base_price()
        discount = self.customer.calculate_discount(base_price)
        tax = self.customer.calculate_tax(base_price - discount)
        return base_price - discount + tax
```

### 3. Documentation Standards
```python
"""Module-level docstring explaining the purpose of this module.

This module provides functionality for processing user orders,
including validation, calculation, and persistence.
"""

from typing import List, Optional, Dict
from dataclasses import dataclass


@dataclass
class Order:
    """Represents a customer order.
    
    Attributes:
        id: Unique order identifier
        customer_id: ID of the customer placing the order
        items: List of order items
        status: Current order status
        
    Example:
        >>> order = Order(
        ...     id="123",
        ...     customer_id="456",
        ...     items=[OrderItem(...)],
        ...     status="pending"
        ... )
    """
    id: str
    customer_id: str
    items: List['OrderItem']
    status: str = "pending"
    
    def calculate_total(self) -> float:
        """Calculate the total order amount.
        
        Returns:
            float: Total order amount including tax and shipping
            
        Raises:
            ValueError: If order has no items
        """
        if not self.items:
            raise ValueError("Cannot calculate total for empty order")
        
        return sum(item.total for item in self.items)
```

## Automated Fix Scripts

### Python Quality Fixer
```bash
#!/bin/bash
# auto_fix_quality.sh

echo "🔧 Starting automated quality fixes..."

# Format code
echo "📐 Formatting code with Black and isort..."
black src/ tests/ --line-length 88
isort src/ tests/ --profile black

# Fix simple linting issues
echo "🧹 Auto-fixing simple linting issues..."
autopep8 --in-place --recursive --aggressive --aggressive src/

# Generate type stubs
echo "📝 Generating type stubs..."
stubgen -p src -o stubs/

# Update docstrings
echo "📚 Checking docstrings..."
pydocstyle src/ --add-ignore=D104,D100

# Remove unused imports
echo "🗑️ Removing unused imports..."
autoflake --in-place --remove-unused-variables --recursive src/

# Sort imports
echo "📦 Organizing imports..."
isort src/ tests/ --profile black

echo "✅ Quality fixes complete!"
```

### JavaScript/TypeScript Quality Fixer
```bash
#!/bin/bash
# fix_js_quality.sh

echo "🔧 Fixing JavaScript/TypeScript quality issues..."

# Format with Prettier
echo "💅 Formatting with Prettier..."
npx prettier --write "src/**/*.{js,jsx,ts,tsx,json,css,scss,md}"

# Fix ESLint issues
echo "🔍 Fixing ESLint issues..."
npx eslint --fix "src/**/*.{js,jsx,ts,tsx}"

# Type checking
echo "📝 Running TypeScript compiler..."
npx tsc --noEmit

echo "✅ JavaScript/TypeScript fixes complete!"
```

## Quality Monitoring Dashboard

### Metrics to Track
```yaml
Code Quality Metrics:
  coverage:
    target: ">= 80%"
    current: "85%"
    trend: "increasing"
    
  complexity:
    cyclomatic_complexity: "< 10"
    cognitive_complexity: "< 15"
    
  duplication:
    target: "< 5%"
    current: "3%"
    
  technical_debt:
    target: "< 5 days"
    current: "3.2 days"
    
  code_smells:
    target: 0
    current: 12
    severity: "minor"
```

## Best Practices Checklist

### Code Quality Standards
- [ ] Consistent code formatting enforced
- [ ] Linting rules configured and passing
- [ ] Type annotations/checking enabled
- [ ] Complexity thresholds defined
- [ ] Documentation standards established
- [ ] Test coverage targets met
- [ ] Security scanning integrated
- [ ] Pre-commit hooks configured
- [ ] CI/CD quality gates implemented
- [ ] Regular code reviews conducted
- [ ] Technical debt tracked
- [ ] Performance metrics monitored
- [ ] Accessibility standards followed
- [ ] Error handling comprehensive
- [ ] Logging standards implemented