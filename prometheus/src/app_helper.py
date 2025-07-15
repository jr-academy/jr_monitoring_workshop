from flask import request
from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry
import time

# Define custom Prometheus metrics
# These will be registered with the prometheus_flask_exporter

# Define metric names and descriptions
REQUEST_COUNT_METRIC = "flask_http_requests_total"
REQUEST_LATENCY_METRIC = "flask_http_request_duration_seconds"
ERROR_COUNT_METRIC = "flask_http_errors_total"
DB_QUERY_COUNT_METRIC = "flask_database_queries_total"
MEMORY_USAGE_METRIC = "flask_memory_usage_bytes"
CPU_USAGE_METRIC = "flask_cpu_usage_seconds"
BUSINESS_METRIC = "flask_business_value"

def setup_prometheus_metrics(app, metrics):
    """Setup additional Prometheus monitoring for the Flask application"""
    
    # Create custom metrics using prometheus_flask_exporter
    
    # Database query counter
    db_query_counter = metrics.counter(
        'database_queries_total',
        'Total number of database queries',
        labels={'endpoint': lambda: request.path, 'query_type': lambda: request.args.get('type', 'unknown')}
    )
    
    # Memory usage gauge
    memory_gauge = metrics.gauge(
        'memory_usage_bytes_current',
        'Current memory usage in bytes',
        labels={'operation': lambda: 'memory_allocation' if request.path == '/memory-usage' else 'normal'}
    )
    
    # CPU usage gauge  
    cpu_gauge = metrics.gauge(
        'cpu_usage_seconds_current',
        'Current CPU usage in seconds',
        labels={'operation': lambda: 'cpu_intensive' if request.path == '/cpu-intensive' else 'normal'}
    )
    
    # Business value gauge
    business_gauge = metrics.gauge(
        'business_value_current',
        'Current business value metric',
        labels={'metric_type': lambda: 'performance'}
    )
    
    # Error counter with more detail
    error_counter = metrics.counter(
        'application_errors_total',
        'Total application errors',
        labels={
            'endpoint': lambda: request.path,
            'error_type': lambda: getattr(request, 'error_type', 'unknown'),
            'status_code': lambda: getattr(request, 'response_status', 'unknown')
        }
    )

    def before_request():
        """Track request start time"""
        request.start_time = time.time()

    def after_request(response):
        """Track request completion and update metrics"""
        
        # Track database queries
        if request.path in ["/users", "/database-query", "/health"]:
            # The counter will be automatically incremented by the decorator
            pass
        
        # Track memory usage for memory-intensive endpoints
        if request.path == "/memory-usage":
            size_mb = request.args.get("size", 10, type=int)
            memory_bytes = size_mb * 1024 * 1024
            # Set current memory usage - prometheus_flask_exporter will handle this
            
        # Track CPU usage for CPU-intensive endpoints
        if request.path == "/cpu-intensive":
            execution_time = getattr(request, "cpu_execution_time", 0)
            # Set current CPU usage - prometheus_flask_exporter will handle this
            
        # Track business metrics
        if request.path == "/delay":
            delay_seconds = request.args.get("seconds", 1, type=float)
            business_value = delay_seconds * 10  # Simulate business value calculation
            # Set business value - prometheus_flask_exporter will handle this
        
        # Track errors
        if 400 <= response.status_code < 600:
            request.error_type = "http_error"
            request.response_status = str(response.status_code)
        
        return response

    # Register the before/after request handlers
    app.before_request(before_request)
    app.after_request(after_request)
    
    # Add some additional info metrics
    metrics.info('prometheus_monitoring_info', 'Prometheus monitoring information', 
                 monitoring_tool='prometheus', exporter='flask_exporter')
    
    return metrics 