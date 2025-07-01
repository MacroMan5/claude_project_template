# 🔗 Integration Testing Prompt

## Context
You are writing comprehensive integration tests that verify component interactions, API contracts, database operations, and system integrations. These tests ensure that different parts of the system work correctly together.

## Integration Testing Strategy

### Test Scope Definition
```yaml
Integration Test Boundaries:
  internal_integrations:
    - Service-to-service communication
    - Database interactions
    - Cache layer integration
    - Message queue operations
    
  external_integrations:
    - Third-party APIs
    - Payment gateways
    - Email services
    - Cloud storage
    
  cross_layer_testing:
    - API to Database
    - Frontend to Backend
    - Microservices communication
```

## Test Environment Setup

### Docker Compose Configuration
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  app:
    build: .
    environment:
      - NODE_ENV=test
      - DATABASE_URL=postgres://test:test@postgres:5432/testdb
      - REDIS_URL=redis://redis:6379
      - RABBITMQ_URL=amqp://rabbitmq:5672
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_USER=test
      - POSTGRES_PASSWORD=test
      - POSTGRES_DB=testdb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test"]
      interval: 5s
      timeout: 5s
      retries: 5
      
  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
      
  rabbitmq:
    image: rabbitmq:3-management
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
```

## API Integration Tests

### RESTful API Testing
```javascript
describe('User API Integration Tests', () => {
  let app
  let db
  let authToken
  
  beforeAll(async () => {
    // Setup test environment
    app = await createTestApp()
    db = await setupTestDatabase()
    
    // Seed test data
    await seedTestUsers(db)
    
    // Get auth token for protected routes
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password123' })
    
    authToken = response.body.token
  })
  
  afterAll(async () => {
    await cleanupTestDatabase(db)
    await app.close()
  })
  
  describe('GET /api/users', () => {
    it('should return paginated users list', async () => {
      const response = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 })
      
      expect(response.status).toBe(200)
      expect(response.body).toMatchObject({
        data: expect.arrayContaining([
          expect.objectContaining({
            id: expect.any(String),
            email: expect.any(String),
            name: expect.any(String),
            createdAt: expect.any(String)
          })
        ]),
        pagination: {
          page: 1,
          limit: 10,
          total: expect.any(Number),
          pages: expect.any(Number)
        }
      })
    })
    
    it('should filter users by search query', async () => {
      const response = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ search: 'john' })
      
      expect(response.status).toBe(200)
      expect(response.body.data).toHaveLength(
        expect.any(Number)
      )
      response.body.data.forEach(user => {
        expect(user.name.toLowerCase()).toContain('john')
      })
    })
    
    it('should return 401 without authentication', async () => {
      const response = await request(app)
        .get('/api/users')
      
      expect(response.status).toBe(401)
      expect(response.body.error).toBe('Unauthorized')
    })
  })
  
  describe('POST /api/users', () => {
    it('should create a new user', async () => {
      const newUser = {
        email: 'newuser@example.com',
        password: 'SecurePass123!',
        name: 'New User'
      }
      
      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newUser)
      
      expect(response.status).toBe(201)
      expect(response.body).toMatchObject({
        id: expect.any(String),
        email: newUser.email,
        name: newUser.name
      })
      expect(response.body.password).toBeUndefined()
      
      // Verify user was created in database
      const dbUser = await db.query(
        'SELECT * FROM users WHERE email = $1',
        [newUser.email]
      )
      expect(dbUser.rows).toHaveLength(1)
    })
    
    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ email: 'invalid' })
      
      expect(response.status).toBe(400)
      expect(response.body.errors).toMatchObject({
        email: 'Invalid email format',
        password: 'Password is required',
        name: 'Name is required'
      })
    })
  })
})
```

### GraphQL Integration Testing
```javascript
describe('GraphQL Integration Tests', () => {
  const graphqlRequest = (query, variables = {}) => {
    return request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ query, variables })
  }
  
  it('should fetch user with posts', async () => {
    const query = `
      query GetUser($id: ID!) {
        user(id: $id) {
          id
          name
          email
          posts {
            id
            title
            content
            createdAt
          }
        }
      }
    `
    
    const response = await graphqlRequest(query, { id: '123' })
    
    expect(response.status).toBe(200)
    expect(response.body.data.user).toMatchObject({
      id: '123',
      name: expect.any(String),
      posts: expect.arrayContaining([
        expect.objectContaining({
          id: expect.any(String),
          title: expect.any(String)
        })
      ])
    })
  })
  
  it('should handle mutations with side effects', async () => {
    const mutation = `
      mutation CreatePost($input: CreatePostInput!) {
        createPost(input: $input) {
          id
          title
          content
          author {
            id
            name
          }
        }
      }
    `
    
    const input = {
      title: 'Integration Test Post',
      content: 'Testing GraphQL mutations',
      authorId: '123'
    }
    
    const response = await graphqlRequest(mutation, { input })
    
    expect(response.status).toBe(200)
    expect(response.body.data.createPost).toMatchObject({
      title: input.title,
      content: input.content,
      author: {
        id: input.authorId
      }
    })
    
    // Verify side effects
    expect(mockEmailService.send).toHaveBeenCalledWith({
      to: expect.any(String),
      subject: 'New post created',
      template: 'new-post'
    })
  })
})
```

## Database Integration Tests

### Transaction Testing
```javascript
describe('Database Transaction Tests', () => {
  let db
  
  beforeEach(async () => {
    db = await getTestDatabase()
    await db.query('BEGIN')
  })
  
  afterEach(async () => {
    await db.query('ROLLBACK')
  })
  
  it('should handle complex transactions', async () => {
    const orderService = new OrderService(db)
    
    // Create order with multiple items
    const order = await orderService.createOrder({
      userId: 'user123',
      items: [
        { productId: 'prod1', quantity: 2, price: 10.00 },
        { productId: 'prod2', quantity: 1, price: 25.00 }
      ]
    })
    
    // Verify order created
    expect(order.id).toBeDefined()
    expect(order.total).toBe(45.00)
    expect(order.status).toBe('pending')
    
    // Verify inventory updated
    const inventory = await db.query(
      'SELECT * FROM inventory WHERE product_id IN ($1, $2)',
      ['prod1', 'prod2']
    )
    
    expect(inventory.rows[0].quantity).toBe(8) // Was 10
    expect(inventory.rows[1].quantity).toBe(4) // Was 5
    
    // Test rollback on insufficient inventory
    await expect(
      orderService.createOrder({
        userId: 'user123',
        items: [{ productId: 'prod1', quantity: 100 }]
      })
    ).rejects.toThrow('Insufficient inventory')
    
    // Verify no partial updates
    const inventoryAfterError = await db.query(
      'SELECT * FROM inventory WHERE product_id = $1',
      ['prod1']
    )
    expect(inventoryAfterError.rows[0].quantity).toBe(8)
  })
})
```

### Migration Testing
```javascript
describe('Database Migration Tests', () => {
  it('should run all migrations successfully', async () => {
    const migrator = new Migrator({
      databaseUrl: process.env.TEST_DATABASE_URL,
      migrationsPath: './migrations'
    })
    
    // Run migrations
    const results = await migrator.up()
    
    expect(results).toHaveLength(
      fs.readdirSync('./migrations').length
    )
    
    // Verify schema
    const tables = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `)
    
    expect(tables.rows.map(r => r.table_name)).toContain(
      'users',
      'posts',
      'comments',
      'migrations'
    )
  })
  
  it('should handle rollback correctly', async () => {
    const migrator = new Migrator({
      databaseUrl: process.env.TEST_DATABASE_URL
    })
    
    // Run migrations
    await migrator.up()
    
    // Rollback last migration
    await migrator.down()
    
    // Verify rollback
    const lastMigration = await db.query(
      'SELECT * FROM migrations ORDER BY id DESC LIMIT 1'
    )
    expect(lastMigration.rows[0].rolled_back_at).toBeDefined()
  })
})
```

## Message Queue Integration

### RabbitMQ Testing
```javascript
describe('Message Queue Integration', () => {
  let connection
  let channel
  
  beforeAll(async () => {
    connection = await amqp.connect(process.env.RABBITMQ_URL)
    channel = await connection.createChannel()
    
    // Setup test queues
    await channel.assertQueue('test.orders', { durable: true })
    await channel.assertQueue('test.notifications', { durable: true })
  })
  
  afterAll(async () => {
    await channel.close()
    await connection.close()
  })
  
  it('should process order messages', async () => {
    const orderProcessor = new OrderProcessor(channel)
    const processed = []
    
    // Setup consumer
    await orderProcessor.start('test.orders', async (order) => {
      processed.push(order)
    })
    
    // Publish test messages
    const testOrders = [
      { id: '1', type: 'purchase', amount: 100 },
      { id: '2', type: 'refund', amount: 50 }
    ]
    
    for (const order of testOrders) {
      await channel.sendToQueue(
        'test.orders',
        Buffer.from(JSON.stringify(order))
      )
    }
    
    // Wait for processing
    await waitFor(() => processed.length === 2, 5000)
    
    expect(processed).toEqual(testOrders)
  })
  
  it('should handle message failures with retry', async () => {
    let attempts = 0
    const processor = new OrderProcessor(channel, {
      maxRetries: 3,
      retryDelay: 100
    })
    
    await processor.start('test.orders', async (order) => {
      attempts++
      if (attempts < 3) {
        throw new Error('Processing failed')
      }
      return { processed: true }
    })
    
    await channel.sendToQueue(
      'test.orders',
      Buffer.from(JSON.stringify({ id: '3' }))
    )
    
    await waitFor(() => attempts === 3, 5000)
    expect(attempts).toBe(3)
  })
})
```

## External Service Integration

### Third-Party API Mocking
```javascript
describe('External API Integration', () => {
  beforeEach(() => {
    // Mock external APIs
    nock('https://api.stripe.com')
      .post('/v1/charges')
      .reply(200, {
        id: 'ch_test123',
        amount: 2000,
        currency: 'usd',
        status: 'succeeded'
      })
      
    nock('https://api.sendgrid.com')
      .post('/v3/mail/send')
      .reply(202, { message: 'Accepted' })
  })
  
  afterEach(() => {
    nock.cleanAll()
  })
  
  it('should process payment and send receipt', async () => {
    const paymentService = new PaymentService()
    
    const result = await paymentService.processPayment({
      amount: 20.00,
      currency: 'usd',
      source: 'tok_visa',
      customer: {
        email: 'customer@example.com',
        name: 'Test Customer'
      }
    })
    
    expect(result).toMatchObject({
      success: true,
      chargeId: 'ch_test123',
      receiptSent: true
    })
    
    // Verify API calls were made
    expect(nock.isDone()).toBe(true)
  })
  
  it('should handle API failures gracefully', async () => {
    nock.cleanAll()
    nock('https://api.stripe.com')
      .post('/v1/charges')
      .reply(500, { error: 'Internal Server Error' })
    
    const paymentService = new PaymentService()
    
    await expect(
      paymentService.processPayment({
        amount: 20.00,
        source: 'tok_visa'
      })
    ).rejects.toThrow('Payment processing failed')
  })
})
```

## Performance Testing

### Load Testing Integration Points
```javascript
describe('Performance Integration Tests', () => {
  it('should handle concurrent requests', async () => {
    const concurrentUsers = 100
    const requestsPerUser = 10
    
    const requests = []
    for (let i = 0; i < concurrentUsers; i++) {
      for (let j = 0; j < requestsPerUser; j++) {
        requests.push(
          request(app)
            .get('/api/products')
            .set('Authorization', `Bearer ${authToken}`)
        )
      }
    }
    
    const startTime = Date.now()
    const responses = await Promise.all(requests)
    const duration = Date.now() - startTime
    
    // Verify all requests succeeded
    responses.forEach(response => {
      expect(response.status).toBe(200)
    })
    
    // Verify performance
    expect(duration).toBeLessThan(5000) // 5 seconds
    
    // Check database connection pool
    const poolStats = await db.pool.stats()
    expect(poolStats.waitingCount).toBe(0)
  })
})
```

## Test Data Management

### Data Fixtures
```javascript
// fixtures/users.js
export const testUsers = [
  {
    id: 'user1',
    email: 'john@example.com',
    password: bcrypt.hashSync('password123', 10),
    name: 'John Doe',
    role: 'admin'
  },
  {
    id: 'user2',
    email: 'jane@example.com',
    password: bcrypt.hashSync('password123', 10),
    name: 'Jane Smith',
    role: 'user'
  }
]

// fixtures/seed.js
export async function seedDatabase(db) {
  // Clear existing data
  await db.query('TRUNCATE users, posts, comments CASCADE')
  
  // Insert test users
  for (const user of testUsers) {
    await db.query(
      'INSERT INTO users (id, email, password, name, role) VALUES ($1, $2, $3, $4, $5)',
      [user.id, user.email, user.password, user.name, user.role]
    )
  }
  
  // Insert related data
  await seedPosts(db)
  await seedComments(db)
}
```

## Test Utilities

### Helper Functions
```javascript
// test-utils/integration-helpers.js
export const integrationHelpers = {
  // Wait for condition
  async waitFor(condition, timeout = 5000) {
    const startTime = Date.now()
    while (Date.now() - startTime < timeout) {
      if (await condition()) return true
      await new Promise(resolve => setTimeout(resolve, 100))
    }
    throw new Error('Timeout waiting for condition')
  },
  
  // Create authenticated request
  authenticatedRequest(app, token) {
    return {
      get: (url) => request(app).get(url).set('Authorization', `Bearer ${token}`),
      post: (url) => request(app).post(url).set('Authorization', `Bearer ${token}`),
      put: (url) => request(app).put(url).set('Authorization', `Bearer ${token}`),
      delete: (url) => request(app).delete(url).set('Authorization', `Bearer ${token}`)
    }
  },
  
  // Database helpers
  async cleanDatabase(db) {
    const tables = await db.query(`
      SELECT tablename FROM pg_tables 
      WHERE schemaname = 'public'
    `)
    
    for (const { tablename } of tables.rows) {
      if (tablename !== 'migrations') {
        await db.query(`TRUNCATE ${tablename} CASCADE`)
      }
    }
  },
  
  // Mock external services
  mockExternalServices() {
    return {
      stripe: {
        charges: {
          create: jest.fn().mockResolvedValue({ id: 'ch_test123' })
        }
      },
      sendgrid: {
        send: jest.fn().mockResolvedValue({ messageId: 'test123' })
      },
      s3: {
        upload: jest.fn().mockResolvedValue({ Location: 'https://s3.test/file' })
      }
    }
  }
}
```

## Best Practices

### DO:
- ✅ Test real integrations, not mocks
- ✅ Use test containers for databases
- ✅ Clean up test data after each test
- ✅ Test error scenarios
- ✅ Verify side effects
- ✅ Use realistic test data
- ✅ Test concurrent operations
- ✅ Monitor test performance
- ✅ Use transactions for isolation
- ✅ Test timeout scenarios

### DON'T:
- ❌ Share test data between tests
- ❌ Depend on test execution order
- ❌ Use production services
- ❌ Ignore flaky tests
- ❌ Mock everything
- ❌ Skip error testing
- ❌ Use hardcoded waits
- ❌ Test implementation details
- ❌ Leave test data in database
- ❌ Ignore performance issues

## Running Integration Tests

```bash
# Run all integration tests
npm run test:integration

# Run specific integration test
npm run test:integration -- --testNamePattern="User API"

# Run with coverage
npm run test:integration -- --coverage

# Run in watch mode
npm run test:integration -- --watch

# Run with specific environment
NODE_ENV=test npm run test:integration
```