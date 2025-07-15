# Datadog Monitoring Workshop

This module provides hands-on experience with Datadog Application Performance Monitoring (APM) and StatsD monitoring using a Flask application.

## Overview

The workshop includes:
- Flask application with various monitoring endpoints
- Datadog Agent configuration for APM and StatsD
- Traffic generation scripts for testing
- Comprehensive tutorial for learning Datadog concepts

## Prerequisites

- Docker and Docker Compose
- Basic understanding of Python and web applications
- Datadog account (free trial available)

## Quick Start

### 1. Environment Setup

```bash
# Clone the repository and navigate to the datadog module
cd DevOpsNotes/WK7_Monitoring/datadog

# Set up your Datadog API key
cp .env.example .env
# Edit .env and add your DATADOG_API_KEY
```

### 2. Start the Infrastructure

```bash
# Start Datadog Agent
docker-compose up -d

# Build and start the Flask application
docker-compose -f docker-compose-app.yml up --build
```

### 3. Verify Setup

```bash
# Check if services are running
docker-compose ps

# Test the application
curl http://localhost:5000/health
```

## Application Endpoints

The Flask application provides several endpoints for monitoring demonstration:

### Core Endpoints
- `GET /` - Welcome page
- `GET /health` - Health check endpoint

### Performance Testing Endpoints
- `GET /cpu-intensive?iterations=<count>` - CPU load simulation
- `GET /memory-usage?size=<mb>` - Memory allocation testing
- `GET /delay?seconds=<time>` - Response time simulation
- `GET /database-query?type=<simple|complex>` - Database operation simulation
- `GET /error?code=<400|404|500>` - Error simulation

### Business Logic Endpoints
- `GET /users` - User list (with database queries)
- `POST /users` - Create user (with validation)

## Traffic Generation

Use the included script to generate realistic traffic patterns:

```bash
# Make the script executable
chmod +x generate_traffic.sh

# Generate mixed traffic (default)
./generate_traffic.sh

# Test specific endpoints
./generate_traffic.sh cpu 20        # CPU-intensive requests
./generate_traffic.sh memory 15     # Memory usage requests  
./generate_traffic.sh database 10   # Database query requests
./generate_traffic.sh delay 12      # Delayed response requests
./generate_traffic.sh users 25      # User management requests
./generate_traffic.sh errors 20     # Error simulation requests

# Sustained load testing
./generate_traffic.sh sustained 300 # 5 minutes of continuous traffic
```

## Tutorial: Learning Datadog Monitoring

### Module 1: Environment Setup (15 minutes)

**Objective**: Set up Datadog monitoring infrastructure

1. **Start the monitoring stack**
   ```bash
   docker-compose up -d
   docker-compose -f docker-compose-app.yml up --build
   ```

2. **Verify Datadog connection**
   - Check the Datadog Agent logs
   - Confirm metrics are flowing to Datadog

3. **Access Datadog Dashboard**
   - Navigate to your Datadog account
   - Locate the APM section

### Module 2: Basic APM Concepts (20 minutes)

**Objective**: Understand application traces and spans

1. **Generate basic traffic**
   ```bash
   ./generate_traffic.sh users 10
   ```

2. **Explore APM Dashboard**
   - View service map
   - Examine individual traces
   - Understand span hierarchy

3. **Assessment**: Identify the slowest endpoint

### Module 3: Performance Monitoring (25 minutes)

**Objective**: Monitor CPU, memory, and response times

1. **CPU Monitoring**
   ```bash
   ./generate_traffic.sh cpu 15
   ```
   - Observe CPU metrics in Datadog
   - Correlate with trace performance

2. **Memory Monitoring**
   ```bash
   ./generate_traffic.sh memory 10
   ```
   - Monitor memory allocation patterns
   - Identify memory-intensive operations

3. **Response Time Analysis**
   ```bash
   ./generate_traffic.sh delay 12
   ```
   - Analyze latency distributions
   - Set up latency percentile alerts

### Module 4: Database Performance (20 minutes)

**Objective**: Monitor database query performance

1. **Simple vs Complex Queries**
   ```bash
   ./generate_traffic.sh database 20
   ```
   - Compare query execution times
   - Identify slow database operations

2. **Database Connection Monitoring**
   - Monitor connection pools
   - Track query patterns

### Module 5: Error Tracking (20 minutes)

**Objective**: Monitor and alert on application errors

1. **Generate Error Traffic**
   ```bash
   ./generate_traffic.sh errors 25
   ```

2. **Error Analysis**
   - Categorize error types
   - Create error rate alerts
   - Set up error tracking

### Module 6: Alerting (20 minutes)

**Objective**: Create effective monitoring alerts

1. **Create Performance Alerts**
   - CPU usage thresholds
   - Response time SLAs
   - Error rate monitoring

2. **Test Alert Conditions**
   ```bash
   ./generate_traffic.sh sustained 180
   ```

### Module 7: Incident Simulation (25 minutes)

**Objective**: Simulate and resolve performance incidents

1. **Create Sustained Load**
   ```bash
   ./generate_traffic.sh sustained 300
   ```

2. **Incident Response**
   - Identify performance bottlenecks
   - Use APM to trace issues
   - Implement fixes

