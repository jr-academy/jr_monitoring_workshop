# Prometheus + Grafana Monitoring Workshop

This module demonstrates comprehensive monitoring with **Prometheus** and **Grafana** using a Flask application. You'll learn how to set up Prometheus metrics collection, create Grafana dashboards, and implement a complete observability stack.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Components](#components)
- [Setup Instructions](#setup-instructions)
- [Running the Application](#running-the-application)
- [Generating Traffic](#generating-traffic)
- [Monitoring Features](#monitoring-features)
- [Grafana Dashboards](#grafana-dashboards)
- [Prometheus Queries](#prometheus-queries)
- [Troubleshooting](#troubleshooting)
- [Learning Objectives](#learning-objectives)

## Overview

This workshop module provides a hands-on experience with Prometheus and Grafana monitoring, featuring:

- **Flask Application**: Python web app instrumented with Prometheus metrics
- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization and dashboarding platform
- **Database Monitoring**: PostgreSQL monitoring with exporters
- **System Monitoring**: Node exporter for system metrics
- **StatsD Integration**: Custom metrics via StatsD exporter

## Prerequisites

### Software Requirements
- Docker and Docker Compose
- curl (for traffic generation)
- bc (basic calculator, for shell scripts)

### System Requirements
- 6GB RAM minimum (more components than Datadog module)
- 15GB free disk space
- Available ports: 3000 (Grafana), 3001 (App), 5432 (PostgreSQL), 9090 (Prometheus)

## Quick Start

1. **Start all services:**
   ```bash
   cd prometheus/
   docker-compose up -d
   # All services start in correct order with health checks (2-3 minutes)
   ```

2. **Generate traffic:**
   ```bash
   ./generate_traffic.sh quick
   ```

3. **View monitoring:**
   - **Prometheus**: http://localhost:9090
   - **Grafana**: http://localhost:3000 (admin/foobar)
   - **App Metrics**: http://localhost:3001/metrics 

## Troubleshooting

### Common Issues

#### Services Not Starting
If services fail to start or have dependency errors:
```bash
# Check logs for specific service
docker-compose logs <service_name>

# Restart all services
docker-compose down
docker-compose up -d

# Check status (all should show "Up")
docker-compose ps
```

#### Prometheus Not Scraping Targets
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.'

# Check if application metrics endpoint is accessible
curl http://localhost:3001/metrics

# Verify network connectivity
docker network inspect prometheus_default
```

#### Application Health Check
```bash
# Check application logs
docker-compose logs webapp

# Verify all services are running
docker-compose ps

# Check database connectivity
docker exec prometheus-postgres pg_isready -U root

# Test application endpoints
curl http://localhost:3001/health
curl http://localhost:3001/metrics
```

#### Clean Restart
For a complete reset:
```bash
docker-compose down -v
# Wait a moment, then restart:
docker-compose up -d
# Wait 2-3 minutes for all services to be healthy
``` 