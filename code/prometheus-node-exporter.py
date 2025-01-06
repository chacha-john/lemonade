import os
import time
import requests
from prometheus_client import start_http_server, Gauge

# Environment variables
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASSWORD = os.getenv("RABBITMQ_PASSWORD", "guest")
RABBITMQ_API_URL = f"http://{RABBITMQ_HOST}:15672/api/queues"
EXPORTER_PORT = int(os.getenv("EXPORTER_PORT", 9100))
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", 10))

# Prometheus metrics
gauges = {
    "messages": Gauge("rabbitmq_individual_queue_messages", "Total count of messages in RabbitMQ queues", ["host", "vhost", "name"]),
    "messages_ready": Gauge("rabbitmq_individual_queue_messages_ready", "Count of ready messages in RabbitMQ queues", ["host", "vhost", "name"]),
    "messages_unacknowledged": Gauge("rabbitmq_individual_queue_messages_unacknowledged", "Count of unacknowledged messages in RabbitMQ queues", ["host", "vhost", "name"]),
}

def fetch_rabbitmq_metrics():
    """Fetch queue metrics from RabbitMQ management API."""
    try:
        response = requests.get(RABBITMQ_API_URL, auth=(RABBITMQ_USER, RABBITMQ_PASSWORD))
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching RabbitMQ metrics: {e}")
        return []

def update_metrics():
    """Update Prometheus metrics with data from RabbitMQ."""
    for queue in fetch_rabbitmq_metrics():
        labels = {"host": RABBITMQ_HOST, "vhost": queue.get("vhost", "unknown"), "name": queue.get("name", "unknown")}
        for metric, gauge in gauges.items():
            gauge.labels(**labels).set(queue.get(metric, 0))

def main():
    """Main function to start the exporter."""
    print(f"Starting RabbitMQ Prometheus Exporter on port {EXPORTER_PORT}")
    start_http_server(EXPORTER_PORT)
    while True:
        update_metrics()
        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
