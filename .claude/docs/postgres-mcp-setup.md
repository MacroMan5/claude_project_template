# PostgreSQL MCP Integration Setup Guide

## 🎯 Overview

This guide covers the complete setup and usage of PostgreSQL MCP server integration for the Claude Project Template. The PostgreSQL MCP enables direct database operations, schema management, and data analysis within Claude Code.

## ✅ Prerequisites

- Docker installed and running
- PostgreSQL database accessible (local or remote)
- Claude Code with MCP support
- Environment variable configuration capability

## 🚀 Quick Setup

### 1. Database Setup

For testing/development, start a PostgreSQL container:

```bash
# Start PostgreSQL test database
docker run -d --name postgres-mcp-test \
  -e POSTGRES_PASSWORD=dev \
  -p 5432:5432 \
  postgres:13

# Or for custom port (if 5432 is occupied)
docker run -d --name postgres-mcp-test \
  -e POSTGRES_PASSWORD=dev \
  -p 5433:5432 \
  postgres:13
```

### 2. Environment Configuration

Set the PostgreSQL connection string:

```bash
# For localhost database (standard port)
export POSTGRES_CONNECTION_STRING="postgresql://postgres:dev@host.docker.internal:5432/postgres"

# For custom port (e.g., 5433)
export POSTGRES_CONNECTION_STRING="postgresql://postgres:dev@host.docker.internal:5433/postgres"

# For remote database
export POSTGRES_CONNECTION_STRING="postgresql://username:password@hostname:5432/database"
```

Add to your shell profile for persistence:

```bash
# Add to ~/.bashrc, ~/.zshrc, or equivalent
echo 'export POSTGRES_CONNECTION_STRING="postgresql://postgres:dev@host.docker.internal:5432/postgres"' >> ~/.bashrc
source ~/.bashrc
```

### 3. MCP Configuration Verification

The PostgreSQL MCP server is pre-configured in `.claude/.mcp.json`:

```json
{
  "postgres": {
    "command": "docker",
    "args": [
      "run", "-i", "--rm", "--network", "host",
      "-e", "POSTGRES_CONNECTION_STRING",
      "mcp/postgres",
      "${POSTGRES_CONNECTION_STRING:-postgresql://postgres:dev@host.docker.internal:5432/postgres}"
    ],
    "env": {
      "_COMMENT": "Set POSTGRES_CONNECTION_STRING for custom database connections"
    }
  }
}
```

### 4. Activation

Restart Claude Code to load the PostgreSQL MCP server.

## 🧪 Testing the Integration

### Manual Testing

Run the integration test script:

```bash
# Run comprehensive tests
./.claude/tests/test-postgres-mcp.sh
```

### Expected MCP Tools

After restart, these tools should be available:

- `mcp__postgres__query` - Execute SQL queries
- `mcp__postgres__schema` - Schema introspection
- `mcp__postgres__list_tables` - List database tables
- Additional PostgreSQL-specific operations

## 💡 Usage Examples

### Basic CRUD Operations

```sql
-- Create a table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert data
INSERT INTO users (username, email) VALUES 
    ('alice', 'alice@example.com'),
    ('bob', 'bob@example.com');

-- Query data
SELECT * FROM users WHERE username = 'alice';

-- Update data
UPDATE users SET email = 'newalice@example.com' WHERE username = 'alice';

-- Delete data
DELETE FROM users WHERE username = 'bob';
```

### Schema Management

```sql
-- Add column
ALTER TABLE users ADD COLUMN last_login TIMESTAMP;

-- Create index
CREATE INDEX idx_users_email ON users(email);

-- Drop table
DROP TABLE IF EXISTS old_table;
```

### Data Analysis

```sql
-- Aggregations
SELECT 
    DATE_TRUNC('day', created_at) as day,
    COUNT(*) as users_per_day
FROM users 
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY day;

-- Joins and complex queries
SELECT u.username, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.username, u.id
ORDER BY post_count DESC;
```

## 🔧 Configuration Options

### Connection String Formats

```bash
# Basic format
postgresql://username:password@hostname:port/database

# With SSL
postgresql://username:password@hostname:port/database?sslmode=require

# Local socket (Unix systems)
postgresql:///database?host=/var/run/postgresql

# Multiple hosts (failover)
postgresql://user:pass@host1:5432,host2:5432/database
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_CONNECTION_STRING` | Full PostgreSQL connection string | `postgresql://postgres:dev@host.docker.internal:5432/postgres` |
| `POSTGRES_HOST` | Database hostname | `host.docker.internal` |
| `POSTGRES_PORT` | Database port | `5432` |
| `POSTGRES_USER` | Username | `postgres` |
| `POSTGRES_PASSWORD` | Password | `dev` |
| `POSTGRES_DB` | Database name | `postgres` |

## 🛡️ Security Considerations

### Connection Security

- **Environment Variables**: Never hardcode credentials in files
- **SSL/TLS**: Use `sslmode=require` for production connections
- **Network Security**: Restrict database access to necessary IPs
- **User Permissions**: Use least-privilege database users

### Best Practices

```bash
# Use environment variables for sensitive data
export POSTGRES_CONNECTION_STRING="postgresql://user:${DB_PASSWORD}@host:5432/db"

# For production, use SSL
export POSTGRES_CONNECTION_STRING="postgresql://user:pass@host:5432/db?sslmode=require"

# Read-only user for analysis
export POSTGRES_CONNECTION_STRING="postgresql://readonly_user:pass@host:5432/db"
```

## 🔍 Troubleshooting

### Common Issues

1. **Connection Refused**
   ```bash
   # Check database is running
   docker ps | grep postgres
   
   # Check port accessibility
   telnet localhost 5432
   ```

2. **Permission Denied**
   ```bash
   # Verify credentials
   psql -h localhost -U postgres -d postgres
   ```

3. **Docker Network Issues**
   ```bash
   # Use host.docker.internal for Docker Desktop
   # Use localhost for Linux Docker
   # Use docker inspect to find container IP
   ```

4. **MCP Tools Not Available**
   - Restart Claude Code
   - Verify `.mcp.json` configuration
   - Check environment variables are set
   - Ensure Docker image is available: `docker images | grep mcp/postgres`

### Debug Commands

```bash
# Test direct connection
docker exec postgres-container psql -U postgres -c "SELECT version();"

# Test MCP Docker image
docker run --rm -i --network host \
  -e POSTGRES_CONNECTION_STRING="$POSTGRES_CONNECTION_STRING" \
  mcp/postgres "$POSTGRES_CONNECTION_STRING"

# View MCP server logs
# (Check Claude Code logs for MCP initialization messages)
```

## 📊 Performance Considerations

### Query Optimization

- Use EXPLAIN ANALYZE for query performance analysis
- Create appropriate indexes for frequently queried columns
- Limit result sets with LIMIT clauses
- Use prepared statements for repeated queries

### Connection Management

- PostgreSQL MCP creates new connections per operation
- For high-frequency operations, consider connection pooling
- Monitor connection limits in production environments

## 🎯 Integration with Hooks System

The PostgreSQL MCP integrates with the Claude template hooks system:

### Post-Tool-Use Hooks

Automatically triggered after database operations:

- **Knowledge Updates**: Schema changes logged to Neo4j memory
- **Backup Creation**: Critical operations backed up
- **Performance Monitoring**: Query execution time tracking

### Pre-Tool-Use Hooks

Security validation before database operations:

- **SQL Injection Detection**: Query pattern analysis
- **Permission Validation**: User privilege checks
- **Data Safety**: Backup verification before destructive operations

## 📈 Advanced Usage

### Database Migrations

```sql
-- Create migration tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Check current schema version
SELECT version FROM schema_migrations ORDER BY applied_at DESC LIMIT 1;
```

### Data Export/Import

```sql
-- Export data
COPY users TO '/tmp/users.csv' WITH CSV HEADER;

-- Import data
COPY users FROM '/tmp/users.csv' WITH CSV HEADER;
```

### Database Monitoring

```sql
-- Active connections
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Database size
SELECT pg_database_size('postgres') / 1024 / 1024 as size_mb;

-- Table statistics
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del 
FROM pg_stat_user_tables;
```

## ✅ Validation Checklist

- [ ] PostgreSQL database accessible
- [ ] Environment variables configured
- [ ] Claude Code restarted with MCP server
- [ ] MCP tools (mcp__postgres__*) available
- [ ] Basic CRUD operations successful
- [ ] Schema management operations working
- [ ] Error handling provides meaningful feedback
- [ ] Security considerations implemented
- [ ] Performance acceptable for use case
- [ ] Integration with hooks system functional

## 📚 References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Claude Code MCP Integration](https://docs.anthropic.com/en/docs/claude-code/mcp)
- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)

---

**PostgreSQL MCP Integration**: ✅ Complete and Ready for Production Use