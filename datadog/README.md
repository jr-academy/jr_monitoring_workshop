# Datadog Monitoring Workshop

This module demonstrates comprehensive monitoring with **Datadog** using a Flask application. You'll learn how to set up Datadog APM (Application Performance Monitoring), StatsD metrics, and infrastructure monitoring.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Components](#components)
- [Setup Instructions](#setup-instructions)
- [Running the Application](#running-the-application)
- [Generating Traffic](#generating-traffic)
- [Monitoring Features](#monitoring-features)
- [Troubleshooting](#troubleshooting)
- [Learning Objectives](#learning-objectives)

## Overview

This workshop module provides a hands-on experience with Datadog monitoring, featuring:

- **Flask Application**: Python web app instrumented with Datadog APM
- **StatsD Metrics**: Custom business and performance metrics
- **Database Monitoring**: PostgreSQL monitoring with Datadog agent
- **Infrastructure Monitoring**: System-level metrics collection

## Prerequisites

### Software Requirements
- Docker and Docker Compose
- Datadog account (free trial available at [datadoghq.com](https://datadoghq.com))
- curl (for traffic generation)
- bc (basic calculator, for shell scripts)

### System Requirements
- 4GB RAM minimum
- 10GB free disk space

## Quick Start

1. **Get your Datadog API key:**
   ```bash
   # Visit https://app.datadoghq.com/organization-settings/api-keys
   # Create a new API key or copy an existing one
   ```

2. **Set up environment:**
   ```bash
   cd datadog/
   cp env.template .env
   # Edit .env and add your DD_API_KEY
   ```

3. **Start all services:**
   ```bash
   docker-compose up -d
   # All services will start in correct order with health checks
   ```

4. **Generate traffic:**
   ```bash
   ./generate_traffic.sh quick
   ```

5. **View in Datadog:**
   - Go to [Datadog APM](https://app.datadoghq.com/apm/home)
   - Check [Infrastructure](https://app.datadoghq.com/infrastructure)

## Components

### Application Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flask App     │────│   Datadog       │────│   Datadog       │
│   (Port 3001)   │    │   Agent         │    │   Platform      │
│                 │    │   (Port 8126)   │    │   (Cloud)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   StatsD        │
│   (Port 5432)   │    │   (Port 8125)   │
└─────────────────┘    └─────────────────┘
```

### Services Included

| Service | Purpose | Port |
|---------|---------|------|
| **webapp** | Flask application with Datadog instrumentation | 3001 |
| **datadog** | Datadog agent for APM and metrics collection | 8126, 8125 |
| **postgres** | PostgreSQL database with monitoring setup | 5432 |

## Setup Instructions

### Step 1: Environment Configuration

```bash
# Copy environment template
cp env.template .env

# Edit the .env file with your Datadog configuration
DD_API_KEY=your_actual_api_key_here
DD_SITE=datadoghq.com  # or your specific Datadog site
```

### Step 2: Start All Services

```bash
# Start all services (Datadog agent, PostgreSQL, and Flask app)
docker-compose up -d

# Check all services are healthy (may take 2-3 minutes)
docker-compose ps
```

Expected output (all services should show "Up" status):
```
Name                 Command               State                    Ports
datadog-agent        agent run                Up      0.0.0.0:8125->8125/udp, 0.0.0.0:8126->8126/tcp
datadog-postgres     docker-entrypoint.sh     Up      0.0.0.0:5432->5432/tcp
datadog-webapp       python flask_app.py      Up      0.0.0.0:3001->3001/tcp
```

### Step 3: Verify Application

```bash
# Check application health
curl http://localhost:3001/health

# View metrics endpoint (should show Flask metrics)
curl http://localhost:3001/metrics || echo "No Prometheus metrics (this is expected for Datadog module)"
```

## Running the Application

### Manual Testing

Test individual endpoints:

```bash
# Health check
curl http://localhost:3001/health

# Get users
curl http://localhost:3001/users

# Create a user
curl -X POST http://localhost:3001/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","email":"test@example.com"}'

# Test delay endpoint
curl "http://localhost:3001/delay?seconds=2"

# Test error endpoint
curl "http://localhost:3001/error?rate=50"
```

### Application Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Simple hello message |
| `/health` | GET | Health check with database connectivity |
| `/users` | GET | Retrieve all users |
| `/users` | POST | Create a new user |
| `/delay` | GET | Artificial delay for latency testing |
| `/error` | GET | Generate errors for error rate testing |
| `/cpu-intensive` | GET | CPU-heavy operation |
| `/memory-usage` | GET | Memory allocation testing |
| `/database-query` | GET | Database query performance testing |

## Generating Traffic

### Using the Traffic Generator

```bash
# Quick test (50 requests)
./generate_traffic.sh quick

# Sustained load (5 minutes)
./generate_traffic.sh sustained 300

# Error scenarios
./generate_traffic.sh errors

# Complete test suite
./generate_traffic.sh full
```

### Custom Traffic Generation

```bash
# High frequency requests
for i in {1..100}; do
  curl -s http://localhost:3001/health > /dev/null &
  if (( i % 10 == 0 )); then wait; fi
done

# Mixed load testing
while true; do
  curl -s "http://localhost:3001/delay?seconds=1" &
  curl -s "http://localhost:3001/error?rate=30" &
  curl -s "http://localhost:3001/users" &
  sleep 2
done
```

## Monitoring Features

### Datadog APM Features

1. **Request Tracing**
   - End-to-end request traces
   - Database query visibility
   - Performance bottleneck identification

2. **Custom Metrics via StatsD**
   - Request counts by endpoint
   - Response time histograms
   - Error rate tracking
   - Business value metrics

3. **Infrastructure Monitoring**
   - Container resource usage
   - Database performance
   - System-level metrics

### Key Metrics to Monitor

| Metric | Type | Description |
|--------|------|-------------|
| `request_count` | Counter | Total HTTP requests |
| `request_latency_seconds_hist` | Histogram | Request response times |
| `error_count` | Counter | HTTP errors (4xx, 5xx) |
| `business_value` | Gauge | Custom business metrics |
| `database_queries_total` | Counter | Database operations |

### Datadog Dashboards

After generating traffic, check these Datadog sections:

1. **APM Service Overview**
   - Go to APM → Services → flask-webapp
   - View request volume, latency, and errors

2. **Infrastructure**
   - Check container metrics
   - Monitor PostgreSQL performance

3. **Custom Dashboards**
   - Create dashboards using StatsD metrics
   - Build alerts on error rates

## Troubleshooting

### Common Issues

#### Datadog Agent Not Connecting
```bash
# Check agent status
docker exec datadog-agent agent status

# Verify API key
docker logs datadog-agent | grep -i "api key"

# Check agent health
curl http://localhost:8126/info
```

#### Application Not Starting
```bash
# Check logs
docker-compose logs webapp

# Verify database connection
docker exec datadog-postgres pg_isready -U root

# Check network connectivity
docker-compose ps
```

#### Services Not Starting
If services fail to start:
```bash
# Check logs for specific service
docker-compose logs <service_name>

# Restart all services
docker-compose down
docker-compose up -d

# Check status
docker-compose ps
```

#### No Metrics in Datadog
```bash
# Verify StatsD is receiving metrics
docker logs datadog-agent | grep -i statsd

# Check if traces are being sent
docker logs webapp | grep -i datadog

# Test metrics endpoint manually
curl http://localhost:3001/health
# Then check Datadog APM within 1-2 minutes
```

### Debug Commands

```bash
# View all running containers
docker ps

# Check container logs
docker logs datadog-agent
docker logs datadog-webapp
docker logs datadog-postgres

# Restart services
docker-compose restart

# Clean restart
docker-compose down
docker-compose -f docker-compose-infra.yml down
docker-compose -f docker-compose-infra.yml up -d
docker-compose up -d
```

## Learning Objectives

By completing this workshop, you will learn:

1. **Datadog APM Setup**
   - How to instrument a Python application
   - APM agent configuration
   - Trace collection and analysis

2. **Custom Metrics with StatsD**
   - Implementing counters, histograms, and gauges
   - Business metric tracking
   - Performance measurement

3. **Infrastructure Monitoring**
   - Container and system monitoring
   - Database performance tracking
   - Resource usage analysis

4. **Observability Best Practices**
   - Monitoring strategy design
   - Alert configuration
   - Dashboard creation

### Next Steps

- Explore Datadog's alerting capabilities
- Create custom dashboards for your use case
- Set up log aggregation with Datadog Logs
- Experiment with Datadog Synthetics for uptime monitoring

## Resources

- [Datadog Documentation](https://docs.datadoghq.com/)
- [Python APM Documentation](https://docs.datadoghq.com/tracing/setup_overview/setup/python/)
- [StatsD Documentation](https://docs.datadoghq.com/developers/dogstatsd/)
- [Database Monitoring](https://docs.datadoghq.com/database_monitoring/) 