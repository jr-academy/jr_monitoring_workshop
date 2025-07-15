-- init_db/schema.sql
-- Create application tables
CREATE TABLE IF NOT EXISTS request_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    source_ip VARCHAR(50),
    endpoint VARCHAR(100),
    status_code INT,
    message TEXT
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users for testing
INSERT INTO users (username, email) VALUES 
    ('john_doe', 'john@example.com'),
    ('jane_smith', 'jane@example.com'),
    ('admin_user', 'admin@example.com'),
    ('test_user', 'test@example.com')
ON CONFLICT DO NOTHING;

-- Create a Datadog user for monitoring
CREATE USER datadog WITH password 'datadog';

-- Grant necessary permissions to the Datadog user
ALTER ROLE datadog INHERIT;
CREATE SCHEMA IF NOT EXISTS datadog;
GRANT USAGE ON SCHEMA datadog TO datadog;
GRANT USAGE ON SCHEMA public TO datadog;
GRANT pg_monitor TO datadog;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
GRANT SELECT ON pg_stat_statements TO datadog;

-- Grant select permissions on application tables for monitoring
GRANT SELECT ON users TO datadog;
GRANT SELECT ON request_log TO datadog;

-- Create a function to explain a statement for Datadog database monitoring
CREATE OR REPLACE FUNCTION datadog.explain_statement(
   l_query TEXT,
   OUT explain JSON
)
RETURNS SETOF JSON AS
$$
DECLARE
curs REFCURSOR;
plan JSON;

BEGIN
   OPEN curs FOR EXECUTE pg_catalog.concat('EXPLAIN (FORMAT JSON) ', l_query);
   FETCH curs INTO plan;
   CLOSE curs;
   RETURN QUERY SELECT plan;
END;
$$
LANGUAGE 'plpgsql'
RETURNS NULL ON NULL INPUT
SECURITY DEFINER; 