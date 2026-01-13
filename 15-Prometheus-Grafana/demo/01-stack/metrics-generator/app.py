from prometheus_client import start_http_server, Counter, Gauge
import random
import time

# Simple mock metrics exporter
REQUESTS = Counter('demo_http_requests_total', 'Total HTTP requests', ['pod'])
CPU_USAGE = Gauge('demo_container_cpu_usage_seconds_total', 'Synthetic CPU seconds', ['pod'])
MEM_USAGE = Gauge('demo_container_memory_bytes', 'Synthetic memory usage bytes', ['pod'])

PODS = ['demo-pod-1', 'demo-pod-2', 'demo-pod-3']

def main():
    start_http_server(8000)
    while True:
        for p in PODS:
            # increment requests by a random small amount
            REQUESTS.labels(pod=p).inc(random.randint(0, 5))
            # set CPU usage (seconds) to a small random value
            CPU_USAGE.labels(pod=p).set(random.random() * 0.5)
            # set memory usage bytes
            MEM_USAGE.labels(pod=p).set(random.randint(10*1024*1024, 120*1024*1024))
        time.sleep(5)

if __name__ == '__main__':
    main()
