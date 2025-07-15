from flask import Flask, request, g, jsonify
import random
import os
import time
import psycopg2
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Gauge, Histogram, Summary, Enum
from app_helper import setup_prometheus_metrics
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "changeme")
DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = os.getenv("DB_PORT", "5432")

# Create Flask application
app = Flask(__name__)

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)

# Setup additional Prometheus metrics
setup_prometheus_metrics(app, metrics)

# Prometheus advantage: Built-in metrics with minimal code
# These metrics are exposed directly at /metrics endpoint
metrics.info("app_info", "Application info", version="1.0.3")

# Prometheus advantage: Custom metrics with specific types
endpoint_counter = metrics.counter(
    'webapp_endpoint_counter', 'Number of invocations per endpoint',
    labels={'endpoint': lambda: request.path, 'status': lambda: request.method}
)

# ==========================================
# CUSTOM METRICS EXAMPLES - BUSINESS VALUE
# ==========================================

# 1. COUNTER - Counts events that only increase
orders_total = Counter(
    'ecommerce_orders_total', 
    'Total number of orders processed',
    ['status', 'payment_method', 'region']
)

user_registrations_total = Counter(
    'user_registrations_total',
    'Total number of user registrations',
    ['source', 'plan_type']
)

# 2. GAUGE - Values that can go up and down
active_users_gauge = Gauge(
    'active_users_current',
    'Current number of active users',
    ['user_type']
)

inventory_items_gauge = Gauge(
    'inventory_items_current',
    'Current inventory levels',
    ['product_category', 'warehouse']
)

# 3. HISTOGRAM - Measures distributions (response times, request sizes)
order_value_histogram = Histogram(
    'order_value_dollars',
    'Distribution of order values in dollars',
    buckets=[10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
)

api_processing_time = Histogram(
    'api_processing_duration_seconds',
    'Time spent processing API requests',
    ['endpoint', 'method'],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

# 4. SUMMARY - Percentiles and quantiles
user_session_duration = Summary(
    'user_session_duration_seconds',
    'Duration of user sessions',
    ['user_type']
)

# 5. ENUM - State-based metrics
system_health_enum = Enum(
    'system_health_status',
    'Current system health status',
    states=['healthy', 'degraded', 'critical', 'maintenance']
)

def get_db_connection():
    """Get database connection"""
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )
    return conn

@app.route("/")
def hello():
    """Simple hello endpoint"""
    return {"message": "Hello, World! Monitored by Prometheus", "timestamp": datetime.now().isoformat()}

@app.route("/health")
def health():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        
        # Update system health enum
        system_health_enum.state('healthy')
        
        return {"status": "healthy", "database": "connected"}, 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        
        # Update system health enum to critical
        system_health_enum.state('critical')
        
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}, 500

# ==========================================
# CUSTOM METRICS DEMO ENDPOINTS
# ==========================================

@app.route("/demo/place-order", methods=["POST"])
def place_order():
    """Demo endpoint: Place an order (showcases COUNTER and HISTOGRAM metrics)"""
    try:
        data = request.get_json() or {}
        
        # Simulate order data
        order_value = data.get('amount', random.uniform(15.0, 500.0))
        payment_method = data.get('payment_method', random.choice(['credit_card', 'paypal', 'bank_transfer']))
        region = data.get('region', random.choice(['us-east', 'us-west', 'europe', 'asia']))
        
        # Simulate order processing time
        start_time = time.time()
        processing_delay = random.uniform(0.1, 2.0)
        time.sleep(processing_delay)
        processing_time = time.time() - start_time
        
        # Simulate order success/failure
        success_rate = 0.9  # 90% success rate
        if random.random() < success_rate:
            status = 'completed'
            http_status = 200
            message = "Order placed successfully"
        else:
            status = 'failed'
            http_status = 400
            message = "Order failed to process"
        
        # UPDATE CUSTOM METRICS
        # 1. Counter: Increment total orders
        orders_total.labels(status=status, payment_method=payment_method, region=region).inc()
        
        # 2. Histogram: Record order value distribution
        if status == 'completed':
            order_value_histogram.observe(order_value)
        
        # 3. Histogram: Record API processing time
        api_processing_time.labels(endpoint='/demo/place-order', method='POST').observe(processing_time)
        
        return {
            "message": message,
            "order_id": f"order_{int(time.time())}",
            "amount": round(order_value, 2),
            "payment_method": payment_method,
            "region": region,
            "status": status,
            "processing_time": round(processing_time, 3)
        }, http_status
        
    except Exception as e:
        # Record failed order
        orders_total.labels(status='error', payment_method='unknown', region='unknown').inc()
        return {"error": "Failed to process order", "details": str(e)}, 500

@app.route("/demo/user-activity", methods=["POST"])
def user_activity():
    """Demo endpoint: Simulate user activity (showcases GAUGE and SUMMARY metrics)"""
    try:
        data = request.get_json() or {}
        
        action = data.get('action', random.choice(['login', 'logout', 'register']))
        user_type = data.get('user_type', random.choice(['free', 'premium', 'enterprise']))
        source = data.get('source', random.choice(['web', 'mobile', 'api']))
        
        if action == 'register':
            # UPDATE METRICS: New user registration
            plan_type = 'trial' if user_type == 'free' else user_type
            user_registrations_total.labels(source=source, plan_type=plan_type).inc()
            
            # Increment active users
            active_users_gauge.labels(user_type=user_type).inc()
            
            return {
                "message": f"User registered successfully",
                "user_type": user_type,
                "source": source,
                "action": action
            }
            
        elif action == 'login':
            # Simulate session duration
            session_duration = random.uniform(60, 3600)  # 1 minute to 1 hour
            
            # UPDATE METRICS: Record session duration
            user_session_duration.labels(user_type=user_type).observe(session_duration)
            
            # Increment active users
            active_users_gauge.labels(user_type=user_type).inc()
            
            return {
                "message": f"User logged in",
                "user_type": user_type,
                "session_duration": round(session_duration, 2),
                "action": action
            }
            
        elif action == 'logout':
            # UPDATE METRICS: Decrement active users
            current_value = active_users_gauge.labels(user_type=user_type)._value._value
            if current_value > 0:
                active_users_gauge.labels(user_type=user_type).dec()
            
            return {
                "message": f"User logged out",
                "user_type": user_type,
                "action": action
            }
            
    except Exception as e:
        return {"error": "Failed to process user activity", "details": str(e)}, 500

@app.route("/demo/inventory-update", methods=["POST"])
def inventory_update():
    """Demo endpoint: Update inventory (showcases GAUGE metrics)"""
    try:
        data = request.get_json() or {}
        
        product_category = data.get('category', random.choice(['electronics', 'clothing', 'books', 'home']))
        warehouse = data.get('warehouse', random.choice(['warehouse_a', 'warehouse_b', 'warehouse_c']))
        change = data.get('change', random.randint(-50, 100))  # Can be negative (sales) or positive (restock)
        
        # UPDATE METRICS: Adjust inventory levels
        current_inventory = inventory_items_gauge.labels(
            product_category=product_category, 
            warehouse=warehouse
        )
        
        # Get current value (starting from 1000 if first time)
        try:
            current_value = current_inventory._value._value
            if current_value is None:
                current_value = 1000  # Initial inventory
        except:
            current_value = 1000
        
        new_value = max(0, current_value + change)  # Don't go below 0
        inventory_items_gauge.labels(product_category=product_category, warehouse=warehouse).set(new_value)
        
        return {
            "message": "Inventory updated",
            "product_category": product_category,
            "warehouse": warehouse,
            "change": change,
            "previous_inventory": current_value,
            "new_inventory": new_value
        }
        
    except Exception as e:
        return {"error": "Failed to update inventory", "details": str(e)}, 500

@app.route("/demo/system-status", methods=["POST"])
def system_status():
    """Demo endpoint: Update system status (showcases ENUM metrics)"""
    try:
        data = request.get_json() or {}
        
        status = data.get('status', random.choice(['healthy', 'degraded', 'critical', 'maintenance']))
        
        # UPDATE METRICS: Set system health status
        system_health_enum.state(status)
        
        return {
            "message": f"System status updated to: {status}",
            "status": status,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        system_health_enum.state('critical')
        return {"error": "Failed to update system status", "details": str(e)}, 500

@app.route("/demo/metrics-info")
def metrics_info():
    """Info endpoint: Explains the custom metrics being demonstrated"""
    return {
        "custom_metrics_demo": {
            "description": "This Flask app demonstrates Prometheus custom metrics with business value",
            "endpoints": {
                "/demo/place-order": {
                    "method": "POST",
                    "description": "Simulates e-commerce orders",
                    "metrics_updated": [
                        "ecommerce_orders_total (Counter) - tracks order success/failure by payment method and region",
                        "order_value_dollars (Histogram) - distribution of order values",
                        "api_processing_duration_seconds (Histogram) - API response times"
                    ],
                    "business_value": "Track revenue, payment method popularity, regional performance"
                },
                "/demo/user-activity": {
                    "method": "POST", 
                    "description": "Simulates user registration, login, logout",
                    "metrics_updated": [
                        "user_registrations_total (Counter) - new user signups by source and plan",
                        "active_users_current (Gauge) - current active users by type",
                        "user_session_duration_seconds (Summary) - session length percentiles"
                    ],
                    "business_value": "Monitor user engagement, acquisition sources, session quality"
                },
                "/demo/inventory-update": {
                    "method": "POST",
                    "description": "Simulates inventory changes",
                    "metrics_updated": [
                        "inventory_items_current (Gauge) - current stock levels by category and warehouse"
                    ],
                    "business_value": "Monitor stock levels, prevent stockouts, optimize warehouse distribution"
                },
                "/demo/system-status": {
                    "method": "POST",
                    "description": "Updates system health status",
                    "metrics_updated": [
                        "system_health_status (Enum) - current system state"
                    ],
                    "business_value": "Monitor system reliability, track uptime/downtime patterns"
                }
            },
            "metric_types_explained": {
                "Counter": "Always increases - perfect for counting events (orders, registrations, errors)",
                "Gauge": "Can go up/down - perfect for current values (active users, inventory, temperature)",
                "Histogram": "Measures distributions - perfect for response times, request sizes, order values",
                "Summary": "Calculates percentiles - perfect for SLA monitoring (95th percentile response time)",
                "Enum": "Tracks states - perfect for system status, deployment stages"
            },
            "prometheus_queries": {
                "total_orders_by_region": "sum by (region) (ecommerce_orders_total)",
                "order_success_rate": "rate(ecommerce_orders_total{status=\"completed\"}[5m]) / rate(ecommerce_orders_total[5m])",
                "average_order_value": "rate(order_value_dollars_sum[5m]) / rate(order_value_dollars_count[5m])",
                "95th_percentile_session": "user_session_duration_seconds{quantile=\"0.95\"}",
                "current_active_users": "sum by (user_type) (active_users_current)",
                "low_inventory_alert": "inventory_items_current < 100"
            }
        }
    }

@app.route("/users")
def get_users():
    """Get users from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, email FROM users ORDER BY id")
        users = cursor.fetchall()
        cursor.close()
        conn.close()
        
        user_list = [{"id": user[0], "username": user[1], "email": user[2]} for user in users]
        return {"users": user_list, "count": len(user_list)}
    except Exception as e:
        logger.error(f"Error fetching users: {e}")
        return {"error": "Failed to fetch users", "details": str(e)}, 500

@app.route("/users", methods=["POST"])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        username = data.get("username")
        email = data.get("email")
        
        if not username or not email:
            return {"error": "Username and email are required"}, 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO users (username, email) VALUES (%s, %s) RETURNING id",
            (username, email)
        )
        user_id = cursor.fetchone()[0]
        conn.commit()
        cursor.close()
        conn.close()
        
        return {"message": "User created", "user_id": user_id, "username": username, "email": email}, 201
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        return {"error": "Failed to create user", "details": str(e)}, 500

@app.route("/delay")
def delay():
    """Endpoint that introduces artificial delay for testing"""
    delay_seconds = request.args.get("seconds", 1, type=float)
    # Simulate processing time
    time.sleep(delay_seconds)
    
    return {"message": f"Delayed response after {delay_seconds} seconds", "delay": delay_seconds}

@app.route("/error")
def error():
    """Endpoint that generates errors for testing monitoring"""
    error_rate = request.args.get("rate", 50, type=int)  # Default 50% error rate
    
    if random.randint(1, 100) <= error_rate:
        # Generate different types of errors
        error_type = random.choice(["400", "404", "500"])
        if error_type == "400":
            return {"error": "Bad request simulation"}, 400
        elif error_type == "404":
            return {"error": "Resource not found simulation"}, 404
        else:
            return {"error": "Internal server error simulation"}, 500
    else:
        return {"message": "Success! No error generated this time"}

@app.route("/cpu-intensive")
def cpu_intensive():
    """CPU-intensive endpoint for testing performance monitoring"""
    iterations = request.args.get("iterations", 100000, type=int)
    
    # Simulate CPU-intensive work
    start_time = time.time()
    result = 0
    for i in range(iterations):
        result += i ** 2
    
    end_time = time.time()
    execution_time = end_time - start_time
    
    # Store execution time for metrics
    request.cpu_execution_time = execution_time
    
    return {
        "message": "CPU-intensive operation completed",
        "iterations": iterations,
        "result": result,
        "execution_time": execution_time
    }

@app.route("/memory-usage")
def memory_usage():
    """Endpoint that uses memory for testing resource monitoring"""
    size_mb = request.args.get("size", 10, type=int)
    
    # Allocate memory (size in MB)
    data = bytearray(size_mb * 1024 * 1024)
    
    # Hold the memory for a short time
    time.sleep(1)
    
    return {
        "message": f"Allocated {size_mb} MB of memory",
        "size_bytes": len(data)
    }

@app.route("/database-query")
def database_query():
    """Endpoint that performs database queries for testing DB monitoring"""
    query_type = request.args.get("type", "simple")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        if query_type == "complex":
            # Complex query for testing
            cursor.execute("""
                SELECT u.username, COUNT(*) as user_count 
                FROM users u 
                GROUP BY u.username 
                ORDER BY user_count DESC 
                LIMIT 10
            """)
        else:
            # Simple query
            cursor.execute("SELECT COUNT(*) FROM users")
        
        result = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return {"query_type": query_type, "result": result}
    except Exception as e:
        logger.error(f"Database query error: {e}")
        return {"error": "Database query failed", "details": str(e)}, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3001, debug=True) 