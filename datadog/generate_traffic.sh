#!/bin/bash

# Traffic generation script for Datadog monitoring demo
# This script generates various types of traffic to test monitoring capabilities

echo "Starting traffic generation for Datadog monitoring demo..."

BASE_URL="http://localhost:3001"

# Function to generate random user data
generate_user() {
    local username="user_$(date +%s)_$RANDOM"
    local email="${username}@example.com"
    curl -s -X POST "${BASE_URL}/users" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${username}\", \"email\":\"${email}\"}" > /dev/null
}

# Function to generate different types of requests
generate_requests() {
    local count=${1:-100}
    echo "Generating ${count} mixed requests..."
    
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
            echo "Completed ${i}/${count} requests"
        fi
    done
}

# Function to generate sustained load
generate_sustained_load() {
    local duration=${1:-300}  # Default 5 minutes
    echo "Generating sustained load for ${duration} seconds..."
    
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Generate 5 concurrent requests
        for j in $(seq 1 5); do
            (
                case $((RANDOM % 6)) in
                    0) curl -s "${BASE_URL}/" > /dev/null ;;
                    1) curl -s "${BASE_URL}/health" > /dev/null ;;
                    2) curl -s "${BASE_URL}/users" > /dev/null ;;
                    3) curl -s "${BASE_URL}/delay?seconds=0.5" > /dev/null ;;
                    4) curl -s "${BASE_URL}/error?rate=20" > /dev/null ;;
                    5) 
                        # Randomly choose between simple and complex database queries
                        if [ $((RANDOM % 2)) -eq 0 ]; then
                            curl -s "${BASE_URL}/database-query?type=simple" > /dev/null
                        else
                            curl -s "${BASE_URL}/database-query?type=complex" > /dev/null
                        fi
                        ;;
                esac
            ) &
        done
        
        # Wait for background jobs to complete
        wait
        
        # Short delay between batches
        sleep 0.5
    done
}

# Function to generate error scenarios
generate_errors() {
    echo "Generating error scenarios..."
    
    for i in $(seq 1 20); do
        # High error rate
        curl -s "${BASE_URL}/error?rate=80" > /dev/null
        sleep 0.2
    done
    
    # Generate some 404s (non-existent endpoints)
    for i in $(seq 1 10); do
        curl -s "${BASE_URL}/nonexistent" > /dev/null
        sleep 0.1
    done
}

# Individual endpoint test functions
test_cpu_intensive() {
    local count=${1:-10}
    echo "Testing CPU-intensive endpoint (${count} requests)..."
    echo "Monitor CPU metrics in Datadog during this test..."
    
    for i in $(seq 1 $count); do
        iterations=$((RANDOM % 100000 + 50000))
        echo "Starting CPU test ${i}/${count} (${iterations} iterations)..."
        curl -s "${BASE_URL}/cpu-intensive?iterations=${iterations}" > /dev/null
        echo "CPU test ${i}/${count} completed"
        sleep 2
    done
}

test_memory_usage() {
    local count=${1:-10}
    echo "Testing memory usage endpoint (${count} requests)..."
    echo "Monitor memory metrics in Datadog during this test..."
    
    for i in $(seq 1 $count); do
        size=$((RANDOM % 50 + 10))
        echo "Starting memory test ${i}/${count} (${size}MB allocation)..."
        curl -s "${BASE_URL}/memory-usage?size=${size}" > /dev/null
        echo "Memory test ${i}/${count} completed"
        sleep 1
    done
}

test_database() {
    local count=${1:-10}
    echo "Testing database endpoints (${count} requests)..."
    echo "Monitor database metrics in Datadog during this test..."
    
    for i in $(seq 1 $count); do
        if [ $((i % 2)) -eq 0 ]; then
            echo "Running complex database query ${i}/${count}..."
            curl -s "${BASE_URL}/database-query?type=complex" > /dev/null
        else
            echo "Running simple database query ${i}/${count}..."
            curl -s "${BASE_URL}/database-query?type=simple" > /dev/null
        fi
        sleep 0.5
    done
}

test_delay() {
    local count=${1:-10}
    echo "Testing delay endpoint (${count} requests)..."
    echo "Monitor response time metrics in Datadog during this test..."
    
    for i in $(seq 1 $count); do
        delay=$(echo "scale=2; $RANDOM/32767*5+0.5" | bc)
        echo "Starting delay test ${i}/${count} (${delay}s delay)..."
        curl -s "${BASE_URL}/delay?seconds=${delay}" > /dev/null
        echo "Delay test ${i}/${count} completed"
        sleep 0.3
    done
}

test_users() {
    local count=${1:-10}
    echo "Testing user endpoints (${count} requests)..."
    echo "Monitor API endpoint metrics in Datadog during this test..."
    
    for i in $(seq 1 $count); do
        if [ $((i % 3)) -eq 0 ]; then
            echo "Creating new user ${i}/${count}..."
            generate_user
        else
            echo "Fetching users ${i}/${count}..."
            curl -s "${BASE_URL}/users" > /dev/null
        fi
        sleep 0.3
    done
}

test_errors() {
    local count=${1:-30}  # Increased default from 10 to 30 for better random distribution
    echo "Testing error endpoint (${count} requests)..."
    echo "Monitor error rate metrics in Datadog during this test..."
    echo "The /error endpoint randomly generates 400, 404, or 500 errors with equal probability"
    
    for i in $(seq 1 $count); do
        rate=$((RANDOM % 80 + 20))  # 20-100% error rate
        echo "Testing random errors ${i}/${count} (${rate}% error rate)..."
        curl -s "${BASE_URL}/error?rate=${rate}" > /dev/null
        sleep 0.3
    done
    
    echo ""
    echo "✅ Generated ${count} requests with random error types (400, 404, 500)"
    echo "📊 Check Datadog for error distribution - you should see all 3 error types"
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
        echo "Running full test suite..."
        echo "1. Quick requests..."
        generate_requests 30
        echo "2. Error scenarios..."
        generate_errors
        echo "3. Sustained load (2 minutes)..."
        generate_sustained_load 120
        ;;
    *)
        echo "Usage: $0 {quick|sustained|errors|cpu|memory|database|delay|users|error-test|full} [count]"
        echo ""
        echo "General tests:"
        echo "  quick              - Generate 50 mixed requests"
        echo "  sustained [duration] - Generate sustained load (default: 300 seconds)"
        echo "  errors             - Generate error scenarios"
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
        echo "Examples:"
        echo "  $0 quick           - Quick mixed test"
        echo "  $0 cpu 20          - Run 20 CPU-intensive tests"
        echo "  $0 memory 15       - Run 15 memory tests"
        echo "  $0 database 10     - Run 10 database tests"
        echo "  $0 sustained 600   - 10-minute sustained load"
        echo "  $0 error-test 50   - Generate 50 random error requests"
        echo ""
        echo "Monitor results in Datadog APM and Infrastructure dashboards"
        exit 1
        ;;
esac

echo "Traffic generation completed!" 