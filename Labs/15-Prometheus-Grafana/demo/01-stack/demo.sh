#!/bin/bash

# Prometheus + Grafana demo installer and helper (Lab 15)
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WORK_DIR="$SCRIPT_DIR"

RUNTIME_DIR="${TMPDIR:-/tmp}/kuberneteslabs-prom-grafana-demo"
PF_PID_FILE="$RUNTIME_DIR/port-forward.pids"

mkdir -p "$RUNTIME_DIR"

is_port_listening() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
  else
    return 1
  fi
}

stop_previous_port_forwards() {
  if [ -f "$PF_PID_FILE" ]; then
    while IFS= read -r pid; do
      if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
        kill "${pid}" 2>/dev/null || true
      fi
    done <"$PF_PID_FILE"
    rm -f "$PF_PID_FILE"
  fi
  rm -f "$RUNTIME_DIR"/port-forward-*.log >/dev/null 2>&1 || true
}

start_port_forward() {
  local namespace="$1"
  local svc="$2"
  local local_port="$3"
  local remote_port="$4"
  local log_file="$RUNTIME_DIR/port-forward-${namespace}-${svc}-${local_port}.log"

  if is_port_listening "${local_port}"; then
    echo "Port ${local_port} is already in use; skipping port-forward for ${namespace}/svc/${svc}."
    return 0
  fi

  kubectl -n "${namespace}" port-forward svc/${svc} ${local_port}:${remote_port} >"${log_file}" 2>&1 &
  echo $! >>"$PF_PID_FILE"
}

open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "${url}" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 || true
  fi
}

echo "========================================"
echo "Prometheus + Grafana Demo (Lab 15)"
echo "========================================"

if ! command -v kubectl &>/dev/null; then
  echo "Error: kubectl is required"
  exit 1
fi
if ! command -v helm &>/dev/null; then
  echo "Error: helm is required"
  exit 1
fi

echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

NS=monitoring
echo "Installing kube-prometheus-stack into namespace '${NS}'..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace ${NS} --create-namespace >/dev/null

echo "Installing standalone grafana (so we can provision dashboards)"
# We'll set a known admin password for demo convenience (admin/admin)
helm upgrade --install grafana grafana/grafana --namespace ${NS} --set adminPassword=admin --set service.type=ClusterIP >/dev/null

echo "Waiting for Prometheus and Grafana pods to be ready (this may take a minute)..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n ${NS} || true

echo "Creating port-forwards for Grafana and Prometheus..."
stop_previous_port_forwards
start_port_forward ${NS} grafana 3000 80
start_port_forward ${NS} prometheus-operated 9090 9090

sleep 2

if command -v curl >/dev/null 2>&1; then
  # Wait for Grafana to respond
  echo "Waiting for Grafana API to become reachable on http://127.0.0.1:3000..."
  for i in {1..30}; do
    if curl -fsS -u admin:admin http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
      echo "Grafana reachable"
      break
    fi
    sleep 2
  done

  echo "Provisioning Prometheus datasource into Grafana..."
  cat <<EOF >/tmp/grafana-ds.json
{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://prometheus-operated:9090",
  "isDefault": true
}
EOF

  curl -sS -u admin:admin -H "Content-Type: application/json" -X POST http://127.0.0.1:3000/api/datasources -d @/tmp/grafana-ds.json || true

  echo "Uploading demo dashboard(s) to Grafana..."
  if [ -d "$WORK_DIR/grafana-dashboards" ]; then
    urls=()
    for f in "$WORK_DIR"/grafana-dashboards/*.json; do
      [ -e "$f" ] || continue
      echo "Uploading $f"
      resp=$(curl -sS -u admin:admin -H "Content-Type: application/json" -X POST http://127.0.0.1:3000/api/dashboards/db -d @"$f" 2>/dev/null || true)
      # Try to extract the URL from the response
      url=$(echo "$resp" | jq -r '.url // empty' 2>/dev/null || true)
      if [ -n "$url" ]; then
        full="http://127.0.0.1:3000${url}"
        urls+=("$full")
        echo "Uploaded -> $full"
        open_url "$full"
      else
        echo "$resp" | jq -r '.message // .' 2>/dev/null || echo "$resp"
      fi
    done
    if [ ${#urls[@]} -gt 0 ]; then
      echo "Opened dashboards in browser (or attempted). If not, visit:"
      for u in "${urls[@]}"; do echo "  $u"; done
    fi
  else
    echo "Dashboard folder not found: $WORK_DIR/grafana-dashboards"
  fi
fi

echo
echo "Access Grafana: http://localhost:3000 (admin/admin)"
echo "Access Prometheus: http://localhost:9090"
echo
echo "Port-forward logs: $RUNTIME_DIR"
echo "To stop port-forwards: xargs kill < $PF_PID_FILE || true"
