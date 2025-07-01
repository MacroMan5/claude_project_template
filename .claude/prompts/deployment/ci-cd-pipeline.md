# 🚀 CI/CD Pipeline Configuration Prompt

## Context
You are setting up a comprehensive CI/CD pipeline that automates building, testing, and deployment processes while maintaining security, quality, and reliability standards.

## Pipeline Architecture

### Overview
```yaml
Pipeline Flow:
  1. Source Control → 
  2. Build & Compile →
  3. Unit Tests →
  4. Code Quality →
  5. Security Scan →
  6. Integration Tests →
  7. Build Artifacts →
  8. Deploy Staging →
  9. E2E Tests →
  10. Deploy Production →
  11. Monitor & Alert
```

## Pipeline Implementation

### 1. Source Control Integration

#### GitHub Actions Example
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18.x'
  PYTHON_VERSION: '3.11'

jobs:
  # Job definitions below...
```

#### GitLab CI Example
```yaml
stages:
  - build
  - test
  - security
  - deploy
  - monitor

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""

before_script:
  - echo "Starting pipeline for $CI_COMMIT_REF_NAME"
```

### 2. Build Stage

#### Multi-Language Build
```yaml
build:
  name: Build Application
  runs-on: ubuntu-latest
  
  strategy:
    matrix:
      include:
        - language: node
          version: 18
        - language: python
          version: 3.11
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Node.js
      if: matrix.language == 'node'
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.version }}
        cache: 'npm'
        
    - name: Setup Python
      if: matrix.language == 'python'
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.version }}
        
    - name: Install dependencies
      run: |
        if [ "${{ matrix.language }}" == "node" ]; then
          npm ci --prefer-offline
        else
          pip install -r requirements.txt
        fi
        
    - name: Build
      run: |
        if [ "${{ matrix.language }}" == "node" ]; then
          npm run build
        else
          python setup.py build
        fi
        
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-${{ matrix.language }}
        path: |
          dist/
          build/
```

### 3. Testing Stage

#### Comprehensive Test Suite
```yaml
test:
  name: Run Tests
  needs: build
  runs-on: ubuntu-latest
  
  services:
    postgres:
      image: postgres:14
      env:
        POSTGRES_PASSWORD: postgres
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
        
    redis:
      image: redis:7
      options: >-
        --health-cmd "redis-cli ping"
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  
  steps:
    - name: Checkout
      uses: actions/checkout@v3
      
    - name: Download artifacts
      uses: actions/download-artifact@v3
      
    - name: Run unit tests
      run: |
        npm test -- --coverage --maxWorkers=2
      env:
        CI: true
        
    - name: Run integration tests
      run: |
        npm run test:integration
      env:
        DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        REDIS_URL: redis://localhost:6379
        
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        token: ${{ secrets.CODECOV_TOKEN }}
        files: ./coverage/lcov.info
        flags: unittests
        
    - name: Test Report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: Test Results
        path: 'test-results/**/*.xml'
        reporter: jest-junit
```

### 4. Code Quality Stage

#### Quality Gates
```yaml
quality:
  name: Code Quality Checks
  needs: build
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout
      uses: actions/checkout@v3
      
    - name: Lint Code
      run: |
        npm run lint
        # or
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        
    - name: Type Check
      run: |
        npm run type-check
        # or
        mypy --strict --ignore-missing-imports src/
        
    - name: Code Formatting
      run: |
        npm run format:check
        # or
        black --check .
        
    - name: Complexity Analysis
      run: |
        npx eslint . --format json --output-file eslint-report.json
        # or
        radon cc . -a -nb
        
    - name: SonarQube Scan
      uses: SonarSource/sonarqube-scan-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

### 5. Security Scanning

#### Security Pipeline
```yaml
security:
  name: Security Scans
  needs: build
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout
      uses: actions/checkout@v3
      
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
        
    - name: Upload Trivy results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
        
    - name: Dependency Check
      run: |
        npm audit --production
        # or
        pip-audit --desc
        
    - name: Secret Scanning
      uses: trufflesecurity/trufflehog@main
      with:
        path: ./
        base: ${{ github.event.repository.default_branch }}
        head: HEAD
        
    - name: SAST Scan
      uses: returntocorp/semgrep-action@v1
      with:
        config: >-
          p/security-audit
          p/owasp-top-ten
          p/nodejs
          p/python
```

### 6. Build & Push Docker Images

#### Container Pipeline
```yaml
docker:
  name: Build and Push Docker Image
  needs: [test, quality, security]
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout
      uses: actions/checkout@v3
      
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
      
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: myapp/backend
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=sha
          
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        build-args: |
          BUILD_VERSION=${{ github.sha }}
          BUILD_DATE=${{ steps.meta.outputs.created }}
```

### 7. Deployment Stages

#### Progressive Deployment
```yaml
deploy-staging:
  name: Deploy to Staging
  needs: docker
  runs-on: ubuntu-latest
  environment: staging
  
  steps:
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/app \
          app=myapp/backend:${{ github.sha }} \
          --namespace=staging
          
    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/app \
          --namespace=staging \
          --timeout=300s
          
    - name: Run smoke tests
      run: |
        npm run test:smoke -- --url=https://staging.myapp.com
        
deploy-production:
  name: Deploy to Production
  needs: deploy-staging
  runs-on: ubuntu-latest
  environment: production
  
  steps:
    - name: Blue-Green Deployment
      run: |
        # Deploy to green environment
        kubectl set image deployment/app-green \
          app=myapp/backend:${{ github.sha }} \
          --namespace=production
          
        # Wait for green to be ready
        kubectl wait --for=condition=ready pod \
          -l app=app-green \
          --namespace=production \
          --timeout=300s
          
        # Switch traffic to green
        kubectl patch service app \
          -p '{"spec":{"selector":{"version":"green"}}}' \
          --namespace=production
          
        # Keep blue as backup
        kubectl annotate deployment app-blue \
          backup-version=${{ github.sha }} \
          --namespace=production
```

### 8. Infrastructure as Code

#### Terraform Pipeline
```yaml
terraform:
  name: Infrastructure Management
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
        
    - name: Terraform Init
      run: terraform init
      working-directory: ./infrastructure
      
    - name: Terraform Format
      run: terraform fmt -check
      working-directory: ./infrastructure
      
    - name: Terraform Validate
      run: terraform validate
      working-directory: ./infrastructure
      
    - name: Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: ./infrastructure
      env:
        TF_VAR_environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
        
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve tfplan
      working-directory: ./infrastructure
```

## Monitoring & Observability

### Pipeline Metrics
```yaml
monitoring:
  name: Post-Deployment Monitoring
  needs: deploy-production
  runs-on: ubuntu-latest
  
  steps:
    - name: Check Application Health
      run: |
        for i in {1..10}; do
          response=$(curl -s -o /dev/null -w "%{http_code}" https://myapp.com/health)
          if [ $response -eq 200 ]; then
            echo "Health check passed"
            exit 0
          fi
          echo "Health check attempt $i failed"
          sleep 30
        done
        exit 1
        
    - name: Performance Test
      run: |
        artillery run --target https://myapp.com performance-test.yml
        
    - name: Send Metrics
      run: |
        curl -X POST https://api.datadog.com/api/v1/series \
          -H "Content-Type: application/json" \
          -H "DD-API-KEY: ${{ secrets.DATADOG_API_KEY }}" \
          -d '{
            "series": [{
              "metric": "deployment.success",
              "points": [['"$(date +%s)"', 1]],
              "tags": ["env:production", "version:'"${{ github.sha }}"'"]
            }]
          }'
```

## Environment Configuration

### Multi-Environment Setup
```yaml
# .github/environments/staging.yml
name: staging
url: https://staging.myapp.com
protection_rules:
  required_reviewers: 1
  
# .github/environments/production.yml  
name: production
url: https://myapp.com
protection_rules:
  required_reviewers: 2
  wait_timer: 30
```

### Secrets Management
```yaml
Secret Categories:
  build_secrets:
    - NPM_TOKEN
    - DOCKER_USERNAME
    - DOCKER_PASSWORD
    
  test_secrets:
    - TEST_DATABASE_URL
    - CODECOV_TOKEN
    
  deployment_secrets:
    - KUBERNETES_CONFIG
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    
  monitoring_secrets:
    - DATADOG_API_KEY
    - SENTRY_DSN
    - SLACK_WEBHOOK
```

## Best Practices

### Pipeline Optimization
```yaml
Optimization Strategies:
  caching:
    - Docker layer caching
    - Dependency caching
    - Build artifact caching
    
  parallelization:
    - Matrix builds
    - Parallel test execution
    - Independent job stages
    
  conditional_execution:
    - Skip unchanged components
    - Run heavy tests on schedule
    - Deploy only from main branch
```

### Rollback Strategy
```yaml
Rollback Procedures:
  automatic:
    - Failed health checks
    - Error rate threshold
    - Performance degradation
    
  manual:
    - One-click rollback
    - Version pinning
    - Database migration rollback
```

## Pipeline Configuration Files

### Example GitHub Actions Workflow
```yaml
# .github/workflows/main.yml
name: Main Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # All job definitions from above sections
```

### Example GitLab CI Configuration
```yaml
# .gitlab-ci.yml
image: docker:latest

services:
  - docker:dind

stages:
  - build
  - test
  - security
  - deploy

# All stage definitions from above sections
```

## Success Metrics

Your CI/CD pipeline should achieve:
1. **Build Success Rate**: > 95%
2. **Deployment Frequency**: Multiple times per day
3. **Lead Time**: < 1 hour from commit to production
4. **MTTR**: < 30 minutes
5. **Test Coverage**: > 80%
6. **Security Scan Pass Rate**: 100% for critical issues
7. **Pipeline Execution Time**: < 15 minutes
8. **Rollback Time**: < 5 minutes

## Troubleshooting

### Common Issues
```yaml
Pipeline Failures:
  build_failures:
    - Check dependency versions
    - Verify build cache
    - Review error logs
    
  test_failures:
    - Check test dependencies
    - Verify test data
    - Review flaky tests
    
  deployment_failures:
    - Verify credentials
    - Check resource limits
    - Review deployment logs
```