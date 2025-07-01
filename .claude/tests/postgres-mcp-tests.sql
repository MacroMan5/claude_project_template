-- PostgreSQL MCP Integration Tests
-- Test file for validating PostgreSQL MCP server functionality
-- Run these tests after PostgreSQL MCP server is activated in Claude Code

-- ==================================================
-- 1. CONNECTION TEST
-- ==================================================
-- Test: Basic connectivity and version check
SELECT 'PostgreSQL MCP Connection Test' as test_name, version() as result;

-- ==================================================
-- 2. SCHEMA MANAGEMENT TESTS
-- ==================================================

-- Test: Create a test table
DROP TABLE IF EXISTS mcp_test_users;
CREATE TABLE mcp_test_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Test: Alter table structure
ALTER TABLE mcp_test_users ADD COLUMN last_login TIMESTAMP;

-- Test: Create an index
CREATE INDEX idx_users_email ON mcp_test_users(email);

-- ==================================================
-- 3. CRUD OPERATIONS TESTS
-- ==================================================

-- Test: INSERT operations
INSERT INTO mcp_test_users (username, email) VALUES 
    ('alice', 'alice@example.com'),
    ('bob', 'bob@example.com'),
    ('charlie', 'charlie@example.com');

-- Test: SELECT operations
SELECT 'Basic SELECT test' as test_name, COUNT(*) as user_count FROM mcp_test_users;

-- Test: SELECT with WHERE clause
SELECT username, email FROM mcp_test_users WHERE username = 'alice';

-- Test: SELECT with JOIN (create related table first)
CREATE TABLE mcp_test_posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES mcp_test_users(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO mcp_test_posts (user_id, title, content) VALUES 
    (1, 'Alice First Post', 'This is Alice first post content'),
    (2, 'Bob Introduction', 'Hello from Bob'),
    (1, 'Alice Second Post', 'Another post from Alice');

-- Test: JOIN query
SELECT u.username, p.title, p.created_at 
FROM mcp_test_users u 
JOIN mcp_test_posts p ON u.id = p.user_id 
ORDER BY p.created_at DESC;

-- Test: UPDATE operations
UPDATE mcp_test_users SET last_login = CURRENT_TIMESTAMP WHERE username = 'alice';

-- Test: Complex UPDATE with subquery
UPDATE mcp_test_users 
SET is_active = false 
WHERE id IN (SELECT user_id FROM mcp_test_posts WHERE title LIKE '%Introduction%');

-- Test: DELETE operations
DELETE FROM mcp_test_posts WHERE title = 'Alice Second Post';

-- ==================================================
-- 4. AGGREGATION AND ANALYTICS TESTS
-- ==================================================

-- Test: COUNT and GROUP BY
SELECT u.username, COUNT(p.id) as post_count
FROM mcp_test_users u
LEFT JOIN mcp_test_posts p ON u.id = p.user_id
GROUP BY u.username, u.id
ORDER BY post_count DESC;

-- Test: DATE functions
SELECT 
    DATE_TRUNC('day', created_at) as day,
    COUNT(*) as posts_per_day
FROM mcp_test_posts 
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY day;

-- ==================================================
-- 5. ERROR HANDLING TESTS
-- ==================================================

-- Test: Invalid syntax (should fail gracefully)
-- SELECT * FROM non_existent_table;

-- Test: Constraint violation (should fail gracefully)
-- INSERT INTO mcp_test_users (username, email) VALUES ('alice', 'duplicate@example.com');

-- ==================================================
-- 6. PERFORMANCE TESTS
-- ==================================================

-- Test: Large dataset operations
INSERT INTO mcp_test_users (username, email)
SELECT 
    'user_' || generate_series,
    'user_' || generate_series || '@example.com'
FROM generate_series(100, 199);

-- Test: Query performance with WHERE clause
SELECT COUNT(*) FROM mcp_test_users WHERE username LIKE 'user_%';

-- ==================================================
-- 7. DATABASE INTROSPECTION TESTS
-- ==================================================

-- Test: List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'mcp_test_%';

-- Test: Describe table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'mcp_test_users'
ORDER BY ordinal_position;

-- Test: Check indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'mcp_test_users';

-- ==================================================
-- 8. CLEANUP (Optional)
-- ==================================================

-- Uncomment to clean up test data:
-- DROP TABLE IF EXISTS mcp_test_posts;
-- DROP TABLE IF EXISTS mcp_test_users;

-- ==================================================
-- EXPECTED RESULTS SUMMARY
-- ==================================================

SELECT 'PostgreSQL MCP Tests Summary' as summary,
       (SELECT COUNT(*) FROM mcp_test_users) as total_users,
       (SELECT COUNT(*) FROM mcp_test_posts) as total_posts,
       'Tests completed successfully' as status;