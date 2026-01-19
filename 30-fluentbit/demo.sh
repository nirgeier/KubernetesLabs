#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFESTS_DIR="$ROOT_DIR/manifests"
SAMPLE_DIR="$ROOT_DIR/sample-app"
NAMESPACE="demo-fluentbit"
RUNTIME_DIR="${TMPDIR:-/tmp}/kuberneteslabs-efk-demo"
PF_PID_FILE="$RUNTIME_DIR/port-forward.pids"
mkdir -p "$RUNTIME_DIR"

# ---------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------

is_port_listening() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
  else
    # Fallback or assume not listening if lsof missing
    return 1
  fi
}

stop_previous_port_forwards() {
  if [ -f "$PF_PID_FILE" ]; then
    echo "Stopping previous port-forwards..."
    while IFS= read -r pid; do
      if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
        kill "${pid}" 2>/dev/null || true
      fi
    done <"$PF_PID_FILE"
    rm -f "$PF_PID_FILE"
  fi
}

start_port_forward() {
  local svc="$1"
  local local_port="$2"
  local remote_port="$3"
  local log_file="$RUNTIME_DIR/port-forward-${svc}-${local_port}.log"

  if is_port_listening "${local_port}"; then
    echo "Port ${local_port} is already in use; skipping port-forward for ${svc}."
    return 0
  fi

  echo "Starting port-forward for ${svc} on ${local_port}..."
  kubectl -n "${NAMESPACE}" port-forward svc/${svc} ${local_port}:${remote_port} >"${log_file}" 2>&1 &
  echo $! >>"$PF_PID_FILE"
}

open_url() {
  local url="$1"
  echo "Opening ${url}..."
  if command -v open >/dev/null 2>&1; then
    open "${url}" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 || true
  else
    echo "Could not open browser automatically."
  fi
}

echo "================================================="
echo "Lab 30 — EFK Stack (Elasticsearch, Fluent Bit, Kibana)"
echo "================================================="

if ! command -v helm &>/dev/null; then
  echo "Error: helm is not installed."
  exit 1
fi

echo "Adding Elastic Helm charts repo..."
helm repo add elastic https://helm.elastic.co >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

echo "Creating namespace $NAMESPACE..."
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "Cleaning up any previous clean installation (as requested)..."
helm uninstall kibana -n $NAMESPACE --wait >/dev/null 2>&1 || true
helm uninstall elasticsearch -n $NAMESPACE --wait >/dev/null 2>&1 || true

# We are not creating the secret manually anymore to allow Helm to manage it.
# We will reset the password via API post-install.

echo "Installing Elasticsearch (this may take a moment)..."
# Using single-node for demo purposes to save resources
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace $NAMESPACE \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.memory="1Gi" \
  --set resources.limits.memory="1Gi" \
  --set volumeClaimTemplate.resources.requests.storage="5Gi" \
  --wait --timeout=300s &

# Preparing Kibana configuration
# Adding enterpriseSearch.host as requested (even if it points to localhost:3002)
cat <<EOF >/tmp/kuberneteslabs-efk-kibana-values.yaml
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
kibanaConfig:
  kibana.yml: |
    enterpriseSearch.host: 'http://localhost:3002'
EOF

# We install Kibana in parallel or after; let's do it in background but wait later
echo "Installing Kibana..."
helm upgrade --install kibana elastic/kibana \
  --namespace $NAMESPACE \
  -f /tmp/kuberneteslabs-efk-kibana-values.yaml \
  --wait --timeout=300s &

wait

echo "Elasticsearch and Kibana installed."

echo "Applying Fluent Bit (daemonset)..."
kubectl apply -f "$MANIFESTS_DIR/00-namespace.yaml"
kubectl apply -f "$MANIFESTS_DIR/01-rbac.yaml"
kubectl apply -f "$MANIFESTS_DIR/02-configmap.yaml"
kubectl apply -f "$MANIFESTS_DIR/03-daemonset.yaml"

echo "Deploying Log Generator..."
kubectl apply -f "$SAMPLE_DIR/log-generator.yaml"

echo "Waiting for Fluent Bit pods..."
kubectl -n $NAMESPACE rollout status daemonset/fluentbit --timeout=60s || true

echo "================================================="
echo "Setup Complete!"
echo "================================================="

# Start port forward automatically
echo "Setting up port-forwards..."
stop_previous_port_forwards
sleep 2
start_port_forward "kibana-kibana" 5601 5601
start_port_forward "elasticsearch-master" 9200 9200

echo "Waiting for Elasticsearch to be reachable..."
for i in {1..30}; do
  if curl -s -k https://localhost:9200 >/dev/null; then
    break
  fi
  sleep 2
done

echo "Resetting 'elastic' user password to 'elastic'..."
# Fetch the auto-generated password
GEN_PASS=$(kubectl -n $NAMESPACE get secret elasticsearch-master-credentials -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "")
if [ -n "$GEN_PASS" ]; then
  # Reset password via API
  curl -s -k -u "elastic:$GEN_PASS" -X POST "https://localhost:9200/_security/user/elastic/_password" \
    -H 'Content-Type: application/json' -d'{"password":"elastic"}' >/dev/null || true

  # Update the Kubernetes Secret so it matches (and avoids confusion)
  kubectl create secret generic elasticsearch-master-credentials \
    --namespace $NAMESPACE \
    --from-literal=password=elastic \
    --from-literal=username=elastic \
    --dry-run=client -o yaml |
    kubectl annotate -f - --local "meta.helm.sh/release-name=elasticsearch" "meta.helm.sh/release-namespace=$NAMESPACE" --dry-run=client -o yaml |
    kubectl label -f - --local "app.kubernetes.io/managed-by=Helm" --dry-run=client -o yaml |
    kubectl apply -f -
else
  echo "Warning: Could not fetch generated password to perform reset."
fi

echo ""
echo "-------------------------------------------------"
echo "CREDENTIALS:"
echo "Username: elastic"
echo "Password: elastic"
echo "-------------------------------------------------"
echo ""

echo "Waiting for Kibana to be reachable..."
# Simple loop to wait for 5601 availability
for i in {1..30}; do
  if nc -z localhost 5601 2>/dev/null || lsof -i :5601 >/dev/null; then
    break
  fi
  sleep 1
done

echo "Opening Kibana in browser..."
open_url "http://localhost:5601"

echo "-------------------------------------------------"
echo "NEXT STEPS:"
echo "1. Log in with the credentials above."
echo "2. Go to Stack Management -> Data Views."
echo "3. Create a Data View for 'fluent-bit*'."
echo "4. Go to Discover to see your logs."
echo "-------------------------------------------------"
echo "To stop the port-forwards later, run:"
echo "xargs kill < $PF_PID_FILE"
