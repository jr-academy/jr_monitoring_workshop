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
    ('alice_monitor', 'alice@prometheus.com'),
    ('bob_metrics', 'bob@prometheus.com'),
    ('charlie_graphs', 'charlie@prometheus.com'),
    ('dana_dashboard', 'dana@prometheus.com'),
    ('eve_exporter', 'eve@prometheus.com')
ON CONFLICT DO NOTHING;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_request_log_timestamp ON request_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_request_log_endpoint ON request_log(endpoint); 