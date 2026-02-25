#!/bin/bash

# Istio and Kiali Demo Script
# This script automates the installation and setup of Istio and Kiali
# Follows the steps from the KubernetesLabs Istio guide

set -euo pipefail # Exit on any error/undefined variable; fail pipelines

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WORK_DIR="$SCRIPT_DIR"

RUNTIME_DIR="${TMPDIR:-/tmp}/kuberneteslabs-istio-basic-setup"
PF_PID_FILE="$RUNTIME_DIR/port-forward.pids"
TRAFFIC_PID_FILE="$RUNTIME_DIR/traffic.pid"
TRAFFIC_LOG_FILE="$RUNTIME_DIR/traffic.log"

ISTIO_DOWNLOAD_DIR=""

# Remove temporary Istio download directory on exit (used by trap).
cleanup_temp_dirs() {
  if [ -n "${ISTIO_DOWNLOAD_DIR}" ] && [ -d "${ISTIO_DOWNLOAD_DIR}" ]; then
    rm -rf "${ISTIO_DOWNLOAD_DIR}" >/dev/null 2>&1 || true
  fi
}

trap cleanup_temp_dirs EXIT

# Return whether a Kubernetes CRD exists (exit 0 if yes).
# Args: $1 - CRD name (e.g. virtualservices.networking.istio.io).
crd_exists() {
  local crd_name="$1"
  kubectl get crd "${crd_name}" >/dev/null 2>&1
}

# Remove prior demo resources: port-forwards, Bookinfo in default, Istio config, demo namespace workloads.
cleanup_previous_demo() {
  echo "Step 00: Cleaning previous demo resources (if any)..."

  # Stop any prior port-forwards started by this script.
  stop_previous_port_forwards

  # Clean Bookinfo app resources in default namespace.
  kubectl delete -n default deployment/productpage-v1 deployment/details-v1 deployment/ratings-v1 \
    deployment/reviews-v1 deployment/reviews-v2 deployment/reviews-v3 --ignore-not-found >/dev/null 2>&1 || true
  kubectl delete -n default svc/productpage svc/details svc/ratings svc/reviews --ignore-not-found >/dev/null 2>&1 || true
  kubectl delete -n default sa/bookinfo-productpage sa/bookinfo-details sa/bookinfo-ratings sa/bookinfo-reviews --ignore-not-found >/dev/null 2>&1 || true

  # Clean Istio config resources only if the CRDs exist.
  if crd_exists virtualservices.networking.istio.io; then
    kubectl delete -n default virtualservice/reviews-vs virtualservice/bookinfo --ignore-not-found >/dev/null 2>&1 || true
  fi
  if crd_exists destinationrules.networking.istio.io; then
    kubectl delete -n default destinationrule/productpage destinationrule/reviews destinationrule/ratings destinationrule/details --ignore-not-found >/dev/null 2>&1 || true
  fi
  if crd_exists gateways.networking.istio.io; then
    kubectl delete -n default gateway/bookinfo-gateway --ignore-not-found >/dev/null 2>&1 || true
  fi

  # Clean demo namespace workloads (keep namespace; it may be used for other labs).
  if kubectl get ns demo >/dev/null 2>&1; then
    kubectl delete -n demo deployment/nginx deployment/httpd svc/nginx svc/httpd --ignore-not-found >/dev/null 2>&1 || true
  fi

  echo "Cleanup complete."
  echo
}

# Return whether a TCP port is in LISTEN state (uses lsof if available).
# Args: $1 - Port number. Returns: 0 if listening, 1 otherwise.
is_port_listening() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
  else
    return 1
  fi
}

# Stop port-forwards and traffic generator started by this script (using saved PIDs).
stop_previous_port_forwards() {
  mkdir -p "$RUNTIME_DIR" >/dev/null 2>&1 || true

  if [ -f "$TRAFFIC_PID_FILE" ]; then
    if kill -0 "$(cat "$TRAFFIC_PID_FILE" 2>/dev/null)" 2>/dev/null; then
      kill "$(cat "$TRAFFIC_PID_FILE" 2>/dev/null)" 2>/dev/null || true
    fi
    rm -f "$TRAFFIC_PID_FILE" "$TRAFFIC_LOG_FILE" >/dev/null 2>&1 || true
  fi

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

# Start kubectl port-forward in background; skip if local port already in use. Append PID to PF_PID_FILE.
# Args: $1 - namespace; $2 - service name; $3 - local port; $4 - remote port.
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

  if command -v nohup >/dev/null 2>&1; then
    nohup kubectl -n "${namespace}" port-forward "svc/${svc}" "${local_port}:${remote_port}" >"${log_file}" 2>&1 &
  else
    kubectl -n "${namespace}" port-forward "svc/${svc}" "${local_port}:${remote_port}" >"${log_file}" 2>&1 &
  fi
  echo $! >>"$PF_PID_FILE"
}

# Open URL in default browser (macOS open or Linux xdg-open). No-op if neither available.
# Args: $1 - URL to open.
open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "${url}" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 || true
  fi
}

# Start a background loop that curls productpage and reviews; store PID in TRAFFIC_PID_FILE.
# No-op if curl missing or generator already running.
start_traffic_generator() {
  if ! command -v curl >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "$TRAFFIC_PID_FILE" ] && kill -0 "$(cat "$TRAFFIC_PID_FILE" 2>/dev/null)" 2>/dev/null; then
    return 0
  fi
  nohup bash -lc 'while true; do curl -fsS http://127.0.0.1:8080/productpage >/dev/null; curl -fsS http://127.0.0.1:8080/api/v1/products/0/reviews >/dev/null; sleep 1; done' >"$TRAFFIC_LOG_FILE" 2>&1 &
  echo $! >"$TRAFFIC_PID_FILE"
}

echo "========================================"
echo "Istio and Kiali Demo Installation Script"
echo "========================================"
echo

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v kubectl &>/dev/null; then
  echo "Error: kubectl is not installed or not in PATH"
  exit 1
fi

if ! command -v helm &>/dev/null; then
  echo "Error: helm is not installed or not in PATH"
  exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
  echo "Error: Cannot connect to Kubernetes cluster"
  exit 1
fi

echo "Prerequisites check passed."
echo

cleanup_previous_demo

# Step 01: Install Istio
echo "Step 01: Installing Istio..."
echo "Downloading Istio..."
ISTIO_DOWNLOAD_DIR=$(mktemp -d)
cd "$ISTIO_DOWNLOAD_DIR"
curl -fsSL https://istio.io/downloadIstio | sh - >/dev/null 2>&1

# Find the istio directory
ISTIO_DIR=$(ls -dt "$ISTIO_DOWNLOAD_DIR"/istio-* 2>/dev/null | head -1 || true)
if [ -z "${ISTIO_DIR:-}" ]; then
  echo "Error: Could not find Istio directory"
  exit 1
fi

ISTIO_HOME="$ISTIO_DIR"
export PATH="$ISTIO_HOME/bin:$PATH"

echo "Installing Istio with demo profile..."
istioctl install --set profile=demo -y

echo "Istio installation completed."
echo

# Step 02: Verify Istio installation
echo "Step 02: Verifying Istio installation..."
kubectl get pods -n istio-system
echo

# Step 03: Install Kiali
echo "Step 03: Installing Kiali..."
if kubectl get deployment -n istio-system kiali >/dev/null 2>&1 || kubectl get deployment -n istio-system kiali-server >/dev/null 2>&1; then
  echo "Kiali already appears to be installed; skipping Helm install."
else
  helm repo add kiali https://kiali.org/helm-charts
  helm repo update

  helm upgrade --install kiali-server \
    kiali/kiali-server \
    --namespace istio-system \
    --set auth.strategy="anonymous"
fi

echo "Kiali installation completed."
echo

# Step 04: Verify Kiali installation
echo "Step 04: Verifying Kiali installation..."
kubectl get pods -n istio-system
echo

# Step 05: Enable Istio Injection
echo "Step 05: Enabling Istio injection in all non-system namespaces..."

for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
  case "$ns" in kube-system | kube-public | kube-node-lease | istio-system) continue ;; esac
  kubectl label namespace "$ns" istio-injection=enabled --overwrite
done

echo "Injection enabled."
echo

# Step 06: Deploy Sample Application
echo "Step 06: Deploying Bookinfo sample application..."
kubectl apply -f "$ISTIO_HOME/samples/bookinfo/platform/kube/bookinfo.yaml"
echo "Sample application deployed."
echo

# Step 07: Verify Sample Application
echo "Step 07: Verifying sample application..."
kubectl get pods
kubectl wait --for=condition=available --timeout=180s deployment/productpage-v1
kubectl wait --for=condition=available --timeout=180s deployment/details-v1
kubectl wait --for=condition=available --timeout=180s deployment/reviews-v1
kubectl wait --for=condition=available --timeout=180s deployment/reviews-v2
kubectl wait --for=condition=available --timeout=180s deployment/reviews-v3
kubectl wait --for=condition=available --timeout=180s deployment/ratings-v1
echo

# Step 08: Expose the Application
echo "Step 08: Exposing the application via Istio gateway..."
kubectl apply -f "$ISTIO_HOME/samples/bookinfo/networking/bookinfo-gateway.yaml"
echo "Application exposed."
echo

# Step 09: Apply DestinationRules (subsets)
echo "Step 09: Applying Bookinfo destination rules..."
kubectl apply -f "$ISTIO_HOME/samples/bookinfo/networking/destination-rule-all.yaml"
echo "Destination rules applied."
echo

# Step 11: Create VirtualService Demo
echo "Step 11: Creating demo VirtualService for reviews service (route to v2)..."
kubectl apply -f "$WORK_DIR/reviews-vs.yaml"
echo "VirtualService created."
echo

# Step 14: Create Demo Namespace
echo "Step 14: Creating demo namespace..."
kubectl apply -f "$WORK_DIR/demo-namespace.yaml"
echo "Demo namespace created."
echo

# Step 15: Deploy Nginx
echo "Step 15: Deploying Nginx with curl loop..."
kubectl apply -f "$WORK_DIR/nginx-demo.yaml"
echo "Nginx deployed."
echo

# Step 16: Deploy HTTPD
echo "Step 16: Deploying HTTPD with curl loop..."
kubectl apply -f "$WORK_DIR/httpd-demo.yaml"
echo "HTTPD deployed."
echo

# Step 17: Verify Demo
echo "Step 17: Verifying demo deployment..."
kubectl get pods -n demo
kubectl wait --for=condition=available --timeout=180s deployment/nginx -n demo
kubectl wait --for=condition=available --timeout=180s deployment/httpd -n demo
echo

echo "========================================"
echo "Demo setup completed successfully!"
echo "========================================"
echo
echo "Next steps:"
echo "1. To access the Bookinfo application:"
echo "   kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80"
echo "   Then visit http://localhost:8080/productpage"
echo
echo "2. To access Kiali dashboard:"
echo "   kubectl port-forward -n istio-system svc/kiali 20001:20001"
echo "   Then visit http://localhost:20001"
echo
echo "3. To access demo services:"
echo "   kubectl port-forward -n demo svc/nginx 8081:80"
echo "   kubectl port-forward -n demo svc/httpd 8082:80"
echo "   Nginx: http://localhost:8081"
echo "   HTTPD: http://localhost:8082"
echo
echo "4. Check curl logs:"
echo "   kubectl logs -n demo deployment/nginx -c nginx --tail=50"
echo "   kubectl logs -n demo deployment/httpd -c httpd --tail=50"
echo
echo "5. To verify the VirtualService routing:"
echo "   Refresh the productpage multiple times and check the reviews section"
echo "   (reviews v1: no stars, v2: black stars, v3: red stars)"
echo
echo "Cleanup: Run 'istioctl uninstall --purge -y' and 'kubectl delete ns istio-system demo' when done."

echo
echo "========================================"
echo "Starting Port-Forwards (Automatic)"
echo "========================================"

stop_previous_port_forwards

start_port_forward istio-system kiali 20001 20001
start_port_forward istio-system istio-ingressgateway 8080 80

start_port_forward demo nginx 8081 80
start_port_forward demo httpd 8082 80

start_traffic_generator

sleep 2

if command -v curl >/dev/null 2>&1; then
  curl -fsSI http://127.0.0.1:20001/kiali/ >/dev/null 2>&1 && echo "Kiali: reachable on http://localhost:20001/kiali/" || echo "Kiali: not reachable yet (check .port-forward-istio-system-kiali-20001.log)"
  curl -fsS http://127.0.0.1:8080/productpage >/dev/null 2>&1 && echo "Bookinfo: reachable on http://localhost:8080/productpage" || echo "Bookinfo: not reachable yet (check .port-forward-istio-system-istio-ingressgateway-8080.log)"
fi

open_url "http://localhost:20001/kiali/"
open_url "http://localhost:8080/productpage"

open_url "http://localhost:8081"
open_url "http://localhost:8082"

echo
echo "Runtime dir: $RUNTIME_DIR"
echo "Port-forward PIDs recorded in $PF_PID_FILE"
echo "Traffic PID recorded in $TRAFFIC_PID_FILE"
echo "To stop them: xargs kill < $PF_PID_FILE; kill \"$(cat $TRAFFIC_PID_FILE 2>/dev/null)\""
