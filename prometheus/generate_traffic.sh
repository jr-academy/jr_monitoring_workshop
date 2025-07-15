#!/bin/bash

# Traffic generation script for Prometheus monitoring demo
# This script generates various types of traffic to test monitoring capabilities

echo "Starting traffic generation for Prometheus monitoring demo..."

BASE_URL="http://localhost:3001"

# Function to generate random user data
generate_user() {
    local username="prom_user_$(date +%s)_$RANDOM"
    local email="${username}@prometheus.example.com"
    curl -s -X POST "${BASE_URL}/users" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${username}\", \"email\":\"${email}\"}" > /dev/null
}

# Function to generate different types of requests
generate_requests() {
    local count=${1:-100}
    echo "Generating ${count} mixed requests for Prometheus monitoring..."
    
    for i in $(seq 1 $count); do
        # Mix of different endpoints
        case $((i % 8)) in
            0)
                # Health check
                curl -s "${BASE_URL}/health" > /dev/null
                ;;
            1)
                # Get users
                curl -s "${BASE_URL}/users" > /dev/null
                ;;
            2)
                # Create user
                generate_user
                ;;
            3)
                # Delay endpoint with random delay
                delay=$(echo "scale=2; $RANDOM/32767*3" | bc)
                curl -s "${BASE_URL}/delay?seconds=${delay}" > /dev/null
                ;;
            4)
                # Error endpoint with random error rate
                rate=$((RANDOM % 100))
                curl -s "${BASE_URL}/error?rate=${rate}" > /dev/null
                ;;
            5)
                # CPU intensive
                iterations=$((RANDOM % 50000 + 10000))
                curl -s "${BASE_URL}/cpu-intensive?iterations=${iterations}" > /dev/null
                ;;
            6)
                # Memory usage
                size=$((RANDOM % 20 + 5))
                curl -s "${BASE_URL}/memory-usage?size=${size}" > /dev/null
                ;;
            7)
                # Database query
                query_type=$((RANDOM % 2))
                if [ $query_type -eq 0 ]; then
                    curl -s "${BASE_URL}/database-query?type=simple" > /dev/null
                else
                    curl -s "${BASE_URL}/database-query?type=complex" > /dev/null
                fi
                ;;
        esac
        
        # Random delay between requests (0.1 to 2 seconds)
        sleep_time=$(echo "scale=2; $RANDOM/32767*1.9+0.1" | bc)
        sleep $sleep_time
        
        if [ $((i % 10)) -eq 0 ]; then
            echo "Completed ${i}/${count} requests (check Prometheus at http://localhost:9090)"
        fi
    done
}

# Function to generate sustained load with varying patterns
generate_sustained_load() {
    local duration=${1:-300}  # Default 5 minutes
    echo "Generating sustained load for ${duration} seconds (monitor in Grafana at http://localhost:3000)..."
    
    local end_time=$(($(date +%s) + duration))
    local phase=0
    
    while [ $(date +%s) -lt $end_time ]; do
        # Change load pattern every 30 seconds
        if [ $(($(date +%s) % 30)) -eq 0 ]; then
            phase=$(((phase + 1) % 4))
            case $phase in
                0) echo "Phase 1: Normal load pattern" ;;
                1) echo "Phase 2: High CPU load pattern" ;;
                2) echo "Phase 3: High error rate pattern" ;;
                3) echo "Phase 4: Database heavy pattern" ;;
            esac
        fi
        
        # Generate different load patterns
        case $phase in
            0)
                # Normal load
                for j in $(seq 1 3); do
                    (curl -s "${BASE_URL}/" > /dev/null) &
                    (curl -s "${BASE_URL}/health" > /dev/null) &
                done
                ;;
            1)
                # CPU intensive load
                for j in $(seq 1 2); do
                    (curl -s "${BASE_URL}/cpu-intensive?iterations=30000" > /dev/null) &
                done
                ;;
            2)
                # High error rate
                for j in $(seq 1 4); do
                    (curl -s "${BASE_URL}/error?rate=70" > /dev/null) &
                done
                ;;
            3)
                # Database heavy
                for j in $(seq 1 5); do
                    (curl -s "${BASE_URL}/database-query?type=complex" > /dev/null) &
                    (curl -s "${BASE_URL}/users" > /dev/null) &
                done
                ;;
        esac
        
        # Wait for background jobs to complete
        wait
        
        # Short delay between batches
        sleep 1
    done
}

# Function to test specific Prometheus metrics
test_prometheus_metrics() {
    echo "Testing specific Prometheus metrics..."
    
    echo "1. Testing request counters..."
    for i in $(seq 1 10); do
        curl -s "${BASE_URL}/" > /dev/null
        curl -s "${BASE_URL}/health" > /dev/null
    done
    
    echo "2. Testing latency histograms..."
    for delay in 0.5 1.0 1.5 2.0; do
        curl -s "${BASE_URL}/delay?seconds=${delay}" > /dev/null
    done
    
    echo "3. Testing error rates..."
    for rate in 10 30 50 80; do
        curl -s "${BASE_URL}/error?rate=${rate}" > /dev/null
    done
    
    echo "4. Testing custom metrics..."
    curl -s "${BASE_URL}/cpu-intensive?iterations=50000" > /dev/null
    curl -s "${BASE_URL}/memory-usage?size=15" > /dev/null
    
    echo "Check metrics at: ${BASE_URL}/metrics"
}

# Function to generate error scenarios
generate_errors() {
    echo "Generating error scenarios for alerting tests..."
    
    for i in $(seq 1 25); do
        # High error rate
        curl -s "${BASE_URL}/error?rate=90" > /dev/null
        sleep 0.2
    done
    
    # Generate some 404s (non-existent endpoints)
    for i in $(seq 1 15); do
        curl -s "${BASE_URL}/nonexistent" > /dev/null
        sleep 0.1
    done
    
    echo "Generated error scenarios - check Prometheus alerts!"
}

# Individual endpoint test functions
test_cpu_intensive() {
    local count=${1:-10}
    echo "Testing CPU-intensive endpoint (${count} requests)..."
    echo "Monitor CPU metrics in Prometheus (http://localhost:9090) and Grafana (http://localhost:3000)..."
    
    for i in $(seq 1 $count); do
        iterations=$((RANDOM % 100000 + 50000))
        echo "Starting CPU test ${i}/${count} (${iterations} iterations)..."
        curl -s "${BASE_URL}/cpu-intensive?iterations=${iterations}" > /dev/null
        echo "CPU test ${i}/${count} completed - check cpu_usage_seconds metric"
        sleep 2
    done
}

test_memory_usage() {
    local count=${1:-10}
    echo "Testing memory usage endpoint (${count} requests)..."
    echo "Monitor memory metrics in Prometheus and Grafana during this test..."
    
    for i in $(seq 1 $count); do
        size=$((RANDOM % 50 + 10))
        echo "Starting memory test ${i}/${count} (${size}MB allocation)..."
        curl -s "${BASE_URL}/memory-usage?size=${size}" > /dev/null
        echo "Memory test ${i}/${count} completed - check memory_usage_bytes metric"
        sleep 1
    done
}

test_database() {
    local count=${1:-10}
    echo "Testing database endpoints (${count} requests)..."
    echo "Monitor database metrics in Prometheus and Grafana during this test..."
    
    for i in $(seq 1 $count); do
        if [ $((i % 2)) -eq 0 ]; then
            echo "Running complex database query ${i}/${count}..."
            curl -s "${BASE_URL}/database-query?type=complex" > /dev/null
        else
            echo "Running simple database query ${i}/${count}..."
            curl -s "${BASE_URL}/database-query?type=simple" > /dev/null
        fi
        echo "Check database_queries_total and database_query_duration_seconds metrics"
        sleep 0.5
    done
}

test_delay() {
    local count=${1:-10}
    echo "Testing delay endpoint (${count} requests)..."
    echo "Monitor response time histograms in Prometheus and Grafana during this test..."
    
    for i in $(seq 1 $count); do
        delay=$(echo "scale=2; $RANDOM/32767*5+0.5" | bc)
        echo "Starting delay test ${i}/${count} (${delay}s delay)..."
        curl -s "${BASE_URL}/delay?seconds=${delay}" > /dev/null
        echo "Delay test ${i}/${count} completed - check http_request_duration_seconds histogram"
        sleep 0.3
    done
}

test_users() {
    local count=${1:-10}
    echo "Testing user endpoints (${count} requests)..."
    echo "Monitor API endpoint metrics in Prometheus and Grafana during this test..."
    
    for i in $(seq 1 $count); do
        if [ $((i % 3)) -eq 0 ]; then
            echo "Creating new user ${i}/${count}..."
            generate_user
        else
            echo "Fetching users ${i}/${count}..."
            curl -s "${BASE_URL}/users" > /dev/null
        fi
        echo "Check http_requests_total metric for /users endpoint"
        sleep 0.3
    done
}

test_errors() {
    local count=${1:-30}  # Increased default from 10 to 30 for better random distribution
    echo "Testing error endpoint (${count} requests)..."
    echo "Monitor error rate metrics and alerts in Prometheus and Grafana during this test..."
    echo "The /error endpoint randomly generates 400, 404, or 500 errors with equal probability"
    
    for i in $(seq 1 $count); do
        rate=$((RANDOM % 80 + 20))  # 20-100% error rate
        echo "Testing random errors ${i}/${count} (${rate}% error rate)..."
        curl -s "${BASE_URL}/error?rate=${rate}" > /dev/null
        sleep 0.3
    done
    
    echo ""
    echo "✅ Generated ${count} requests with random error types (400, 404, 500)"
    echo "📊 Check Prometheus/Grafana for error distribution by status code:"
    echo "   • http_requests_total{status=\"400\"}"
    echo "   • http_requests_total{status=\"404\"}"
    echo "   • http_requests_total{status=\"500\"}"
    echo "🔍 If you still only see 500s, try running again with more requests:"
    echo "    $0 error-test 50"
}



# Main execution
case "${1}" in
    "quick")
        echo "Running quick test (50 requests)..."
        generate_requests 50
        ;;
    "sustained")
        duration=${2:-300}
        echo "Running sustained load test for ${duration} seconds..."
        generate_sustained_load $duration
        ;;
    "errors")
        echo "Running error generation test..."
        generate_errors
        ;;
    "metrics")
        echo "Testing Prometheus metrics..."
        test_prometheus_metrics
        ;;
    "cpu")
        count=${2:-10}
        test_cpu_intensive $count
        ;;
    "memory")
        count=${2:-10}
        test_memory_usage $count
        ;;
    "database"|"db")
        count=${2:-10}
        test_database $count
        ;;
    "delay")
        count=${2:-10}
        test_delay $count
        ;;
    "users")
        count=${2:-10}
        test_users $count
        ;;
    "error-test")
        count=${2:-30}
        test_errors $count
        ;;
    "full")
        echo "Running full Prometheus test suite..."
        echo "1. Testing metrics..."
        test_prometheus_metrics
        echo "2. Quick requests..."
        generate_requests 30
        echo "3. Error scenarios..."
        generate_errors
        echo "4. Sustained load (2 minutes)..."
        generate_sustained_load 120
        ;;
    *)
        echo "Usage: $0 {quick|sustained|errors|metrics|cpu|memory|database|delay|users|error-test|full} [count]"
        echo ""
        echo "General tests:"
        echo "  quick              - Generate 50 mixed requests"
        echo "  sustained [duration] - Generate sustained load (default: 300 seconds)"
        echo "  errors             - Generate error scenarios for alerting"
        echo "  metrics            - Test specific Prometheus metrics"
        echo "  full               - Run complete test suite"
        echo ""
        echo "Specific endpoint tests:"
        echo "  cpu [count]        - Test CPU-intensive endpoint (default: 10)"
        echo "  memory [count]     - Test memory usage endpoint (default: 10)"
        echo "  database [count]   - Test database queries (default: 10)"
        echo "  delay [count]      - Test delay endpoint (default: 10)"
        echo "  users [count]      - Test user endpoints (default: 10)"
        echo "  error-test [count] - Test random error codes (400/404/500) (default: 30)"
        echo ""
        echo "Monitoring URLs:"
        echo "  Prometheus: http://localhost:9090"
        echo "  Grafana:    http://localhost:3000 (admin/foobar)"
        echo "  App metrics: http://localhost:3001/metrics"
        echo ""
        echo "Examples:"
        echo "  $0 quick           - Quick mixed test"
        echo "  $0 cpu 20          - Run 20 CPU-intensive tests"
        echo "  $0 memory 15       - Run 15 memory tests with metric hints"
        echo "  $0 database 10     - Run 10 database tests"
        echo "  $0 sustained 600   - 10-minute sustained load with phases"
        echo "  $0 metrics         - Test core Prometheus metrics"
        exit 1
        ;;
esac

echo "Traffic generation completed! Check your monitoring dashboards." 