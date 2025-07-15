from flask import request
from datadog import DogStatsd
import time

# Initialize Datadog Statsd client
# StatsD is a simple protocol for sending metrics over UDP
# It's lightweight and doesn't block application execution
statsd = DogStatsd(host="datadog", port=8125)

# Define metric names
REQUEST_LATENCY_METRIC_NAME = "request_latency_seconds_hist"
REQUEST_COUNT = "request_count"
ERROR_COUNT = "error_count"
BUSINESS_METRIC = "business_value"
DB_QUERY_COUNT = "database_queries_total"
MEMORY_USAGE_METRIC = "memory_usage_bytes"
CPU_USAGE_METRIC = "cpu_usage_seconds"


def start_timer():
    """Start a timer at the beginning of the request"""
    request.start_time = time.time()


def stop_timer(response):
    """Calculate the request latency and send it to Datadog"""
    # StatsD advantage: Easy to create histograms for latency distribution
    resp_time = time.time() - request.start_time
    statsd.histogram(
        REQUEST_LATENCY_METRIC_NAME,
        resp_time,
        tags=[
            "service:webapp",
            f"endpoint:{request.path}",
            f"method:{request.method}",
            f"status:{response.status_code}",
        ],
    )
    return response


def record_request_data(response):
    """Increment the request count and send it to Datadog"""
    # StatsD advantage: Simple counters with automatic rates
    statsd.increment(
        REQUEST_COUNT,
        tags=[
            "service:webapp",
            f"method:{request.method}",
            f"endpoint:{request.path}",
            f"status:{response.status_code}",
        ],
    )
    
    # Track errors separately
    if 400 <= response.status_code < 600:
        statsd.increment(
            ERROR_COUNT,
            tags=[
                "service:webapp",
                f"method:{request.method}",
                f"endpoint:{request.path}",
                f"status:{response.status_code}",
            ],
        )
    
    # Track database queries
    if request.path in ["/users", "/database-query", "/health"]:
        statsd.increment(
            DB_QUERY_COUNT,
            tags=[
                "service:webapp",
                f"endpoint:{request.path}",
                f"method:{request.method}",
            ],
        )
    
    # StatsD advantage: Easy to track business metrics
    # For example, if this was an e-commerce site:
    if request.path == "/delay":
        # Simulate a business metric (e.g., processing time as a business value)
        business_value = float(getattr(request, "business_value", 1.0))
        statsd.gauge(
            BUSINESS_METRIC,
            business_value,
            tags=["service:webapp", "metric_type:performance"]
        )
    
    # Track memory usage for memory-intensive endpoints
    if request.path == "/memory-usage":
        size_mb = request.args.get("size", 10, type=int)
        memory_bytes = size_mb * 1024 * 1024
        statsd.gauge(
            MEMORY_USAGE_METRIC,
            memory_bytes,
            tags=["service:webapp", "operation:memory_allocation"]
        )
    
    # Track CPU usage for CPU-intensive endpoints
    if request.path == "/cpu-intensive":
        execution_time = getattr(request, "cpu_execution_time", 0)
        statsd.gauge(
            CPU_USAGE_METRIC,
            execution_time,
            tags=["service:webapp", "operation:cpu_intensive"]
        )
    
    return response


def setup_datadog_metrics(app):
    """Setup Datadog monitoring for the Flask application"""
    # Register functions to be called before and after each request
    app.before_request(start_timer)
    # Register stop_timer first to have it execute before record_request_data
    app.after_request(stop_timer)
    app.after_request(record_request_data) 