Prometheus + Grafana Demo (Lab 15)

Quick demo that installs the `kube-prometheus-stack` and a Grafana release, provisions a Prometheus datasource and uploads a demo dashboard showing cluster CPU, memory, pod counts and HTTP requests.

Usage

1. Make the script executable:

```bash
chmod +x demo.sh
```

2. Run the demo script (requires `kubectl` and `helm`):

```bash
./demo.sh
```

3. Open Grafana on http://localhost:3000 (username: `admin`, password: `admin`)

Notes

- The script port-forwards the Grafana and Prometheus services to localhost for convenience.
- The dashboard is uploaded to Grafana via the HTTP API; the script uses a temporary admin password `admin` for demo ease. Change for production.
