# 📚 API Documentation Generation Prompt

## Context
You are creating comprehensive API documentation that helps developers understand, integrate, and use APIs effectively. This includes endpoint documentation, authentication details, examples, and error handling.

## Documentation Standards

### OpenAPI/Swagger Specification
```yaml
openapi: 3.0.0
info:
  title: API Name
  description: |
    Comprehensive API documentation for [Service Name].
    
    ## Overview
    Brief description of what the API does and its main features.
    
    ## Authentication
    This API uses JWT Bearer authentication. Include the token in the Authorization header:
    ```
    Authorization: Bearer <your-token>
    ```
  version: 1.0.0
  contact:
    name: API Support
    email: api@example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.example.com/v1
    description: Production server
  - url: https://staging-api.example.com/v1
    description: Staging server
  - url: http://localhost:8000/v1
    description: Local development

security:
  - bearerAuth: []

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## API Endpoint Documentation

### RESTful Endpoint Structure
```yaml
paths:
  /users:
    get:
      summary: List users
      description: |
        Retrieve a paginated list of users. Supports filtering, sorting, and searching.
      operationId: listUsers
      tags:
        - Users
      parameters:
        - name: page
          in: query
          description: Page number (1-based)
          required: false
          schema:
            type: integer
            default: 1
            minimum: 1
        - name: limit
          in: query
          description: Items per page
          required: false
          schema:
            type: integer
            default: 20
            minimum: 1
            maximum: 100
        - name: search
          in: query
          description: Search users by name or email
          required: false
          schema:
            type: string
        - name: sort
          in: query
          description: Sort field and order
          required: false
          schema:
            type: string
            enum: [name, -name, created_at, -created_at]
            default: -created_at
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
              example:
                data:
                  - id: "123e4567-e89b-12d3-a456-426614174000"
                    email: "user@example.com"
                    name: "John Doe"
                    role: "user"
                    created_at: "2024-01-15T10:30:00Z"
                pagination:
                  page: 1
                  limit: 20
                  total: 100
                  pages: 5
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'
    
    post:
      summary: Create user
      description: Create a new user account
      operationId: createUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            example:
              email: "newuser@example.com"
              password: "SecurePass123!"
              name: "Jane Smith"
              role: "user"
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
          headers:
            Location:
              description: URL of the created resource
              schema:
                type: string
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          description: Email already exists
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
```

## Schema Definitions

### Data Models
```yaml
components:
  schemas:
    User:
      type: object
      required:
        - id
        - email
        - name
        - role
        - created_at
      properties:
        id:
          type: string
          format: uuid
          description: Unique user identifier
          example: "123e4567-e89b-12d3-a456-426614174000"
        email:
          type: string
          format: email
          description: User's email address
          example: "user@example.com"
        name:
          type: string
          description: User's full name
          minLength: 1
          maxLength: 100
          example: "John Doe"
        role:
          type: string
          enum: [admin, user, guest]
          description: User's role in the system
          example: "user"
        created_at:
          type: string
          format: date-time
          description: Account creation timestamp
          example: "2024-01-15T10:30:00Z"
        updated_at:
          type: string
          format: date-time
          description: Last update timestamp
          example: "2024-01-20T15:45:00Z"
    
    CreateUserRequest:
      type: object
      required:
        - email
        - password
        - name
      properties:
        email:
          type: string
          format: email
          description: User's email address
        password:
          type: string
          format: password
          minLength: 8
          description: User's password (min 8 chars)
        name:
          type: string
          minLength: 1
          maxLength: 100
          description: User's full name
        role:
          type: string
          enum: [admin, user]
          default: user
          description: User's role
    
    Error:
      type: object
      required:
        - error
        - message
      properties:
        error:
          type: string
          description: Error code
          example: "VALIDATION_ERROR"
        message:
          type: string
          description: Human-readable error message
          example: "Email address is already in use"
        details:
          type: object
          description: Additional error details
          additionalProperties: true
    
    Pagination:
      type: object
      required:
        - page
        - limit
        - total
        - pages
      properties:
        page:
          type: integer
          description: Current page number
          minimum: 1
        limit:
          type: integer
          description: Items per page
          minimum: 1
        total:
          type: integer
          description: Total number of items
          minimum: 0
        pages:
          type: integer
          description: Total number of pages
          minimum: 0
```

## Authentication Documentation

### JWT Authentication
```markdown
## Authentication

This API uses JWT (JSON Web Token) authentication. To access protected endpoints:

### 1. Obtain a Token

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "your-password"
}
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 2. Use the Token

Include the token in subsequent requests:
```http
GET /api/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### 3. Refresh Expired Tokens

```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```
```

## Error Handling

### Standard Error Responses
```yaml
components:
  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          examples:
            validation_error:
              value:
                error: "VALIDATION_ERROR"
                message: "Invalid request data"
                details:
                  email: "Invalid email format"
                  password: "Password too short"
    
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "UNAUTHORIZED"
            message: "Authentication required"
    
    Forbidden:
      description: Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "FORBIDDEN"
            message: "You don't have permission to access this resource"
    
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "NOT_FOUND"
            message: "The requested resource was not found"
    
    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "INTERNAL_ERROR"
            message: "An unexpected error occurred"
```

## Code Examples

### Multiple Language Examples
````markdown
## Code Examples

### JavaScript/Node.js
```javascript
const axios = require('axios');

const API_BASE_URL = 'https://api.example.com/v1';
const token = 'your-jwt-token';

// Configure axios defaults
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

// Get users
async function getUsers(page = 1, limit = 20) {
  try {
    const response = await api.get('/users', {
      params: { page, limit }
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching users:', error.response?.data);
    throw error;
  }
}

// Create user
async function createUser(userData) {
  try {
    const response = await api.post('/users', userData);
    return response.data;
  } catch (error) {
    if (error.response?.status === 409) {
      console.error('User already exists');
    }
    throw error;
  }
}
```

### Python
```python
import requests
from typing import Dict, Optional

class APIClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        })
    
    def get_users(self, page: int = 1, limit: int = 20) -> Dict:
        """Fetch paginated users list."""
        response = self.session.get(
            f'{self.base_url}/users',
            params={'page': page, 'limit': limit}
        )
        response.raise_for_status()
        return response.json()
    
    def create_user(self, user_data: Dict) -> Dict:
        """Create a new user."""
        response = self.session.post(
            f'{self.base_url}/users',
            json=user_data
        )
        response.raise_for_status()
        return response.json()

# Usage
client = APIClient('https://api.example.com/v1', 'your-token')
users = client.get_users(page=1, limit=50)
```

### cURL
```bash
# Get users
curl -X GET "https://api.example.com/v1/users?page=1&limit=20" \
  -H "Authorization: Bearer your-jwt-token" \
  -H "Accept: application/json"

# Create user
curl -X POST "https://api.example.com/v1/users" \
  -H "Authorization: Bearer your-jwt-token" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "SecurePass123!",
    "name": "New User"
  }'
```
````

## API Documentation Best Practices

### Documentation Structure
```markdown
# API Documentation

## Table of Contents
1. [Getting Started](#getting-started)
2. [Authentication](#authentication)
3. [Rate Limiting](#rate-limiting)
4. [Endpoints](#endpoints)
5. [Error Handling](#error-handling)
6. [Webhooks](#webhooks)
7. [Code Examples](#code-examples)
8. [Changelog](#changelog)

## Getting Started

### Base URL
```
https://api.example.com/v1
```

### Content Type
All requests and responses use `application/json`.

### Versioning
The API version is included in the URL path. Current version: `v1`.

## Rate Limiting

API requests are limited to:
- 1000 requests per hour for authenticated users
- 100 requests per hour for unauthenticated users

Rate limit headers:
- `X-RateLimit-Limit`: Request limit
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset timestamp

## Pagination

List endpoints support pagination:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

Response includes pagination metadata:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}
```
```

## Interactive Documentation

### Swagger UI Integration
```html
<!DOCTYPE html>
<html>
<head>
  <title>API Documentation</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
  <script>
    window.onload = function() {
      window.ui = SwaggerUIBundle({
        url: "/openapi.json",
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIBundle.SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout",
        tryItOutEnabled: true,
        requestInterceptor: (request) => {
          // Add auth token to try-it-out requests
          const token = localStorage.getItem('api_token');
          if (token) {
            request.headers['Authorization'] = `Bearer ${token}`;
          }
          return request;
        }
      });
    };
  </script>
</body>
</html>
```

## Documentation Generation Tools

### Generate from Code
```python
# FastAPI automatic documentation
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(
    title="My API",
    description="API description",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

class UserResponse(BaseModel):
    """User response model."""
    id: str
    email: str
    name: str
    
    class Config:
        schema_extra = {
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "email": "user@example.com",
                "name": "John Doe"
            }
        }

@app.get(
    "/users",
    response_model=List[UserResponse],
    summary="List users",
    description="Get paginated list of users with optional filtering",
    responses={
        200: {"description": "Successful response"},
        401: {"description": "Authentication required"}
    }
)
async def list_users(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    search: Optional[str] = Query(None, description="Search term")
):
    """
    List all users with pagination support.
    
    - **page**: Page number (starting from 1)
    - **limit**: Number of items per page
    - **search**: Optional search term for filtering
    """
    # Implementation
    pass
```

## Checklist

- [ ] API overview and purpose documented
- [ ] Authentication method explained
- [ ] All endpoints documented with examples
- [ ] Request/response schemas defined
- [ ] Error responses documented
- [ ] Rate limiting explained
- [ ] Code examples in multiple languages
- [ ] Versioning strategy documented
- [ ] Changelog maintained
- [ ] Interactive documentation available