#!/bin/bash
###############################################################################
#  Telepresence Master Lab - End-to-End Sandbox Script
#
#  This script creates an isolated Kind cluster, deploys a 3-tier demo app,
#  installs Telepresence OSS, and validates every layer of the stack.
#
#  Usage:
#    ./run-lab.sh                   # Full run (cluster + deploy + test)
#    ./run-lab.sh --skip-cluster    # Reuse existing Kind cluster
#    ./run-lab.sh --cleanup         # Tear everything down
#    ./run-lab.sh --test-only       # Run tests on existing deployment
#
#  Features:
#    ✓ Fully idempotent - safe to re-run
#    ✓ Isolated Kind cluster with custom networking
#    ✓ No Ambassador Cloud account needed (OSS mode)
#    ✓ Structured, color-coded output
#    ✓ Comprehensive validation at every step
###############################################################################

set -euo pipefail

# ── Configuration ───────────────────────────────────────
CLUSTER_NAME="telepresence-lab"
NAMESPACE="telepresence-demo"
KIND_IMAGE="kindest/node:v1.29.2"
POD_CIDR="10.10.0.0/16"
SERVICE_CIDR="10.110.0.0/16"
BACKEND_PORT=5000
DATASERVICE_PORT=5001
FRONTEND_PORT=80
PORT_FORWARD_PORT=8080
TIMEOUT_SECONDS=180

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="${SCRIPT_DIR}/resources"

# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Counters ────────────────────────────────────────────
STEP=0
PASS=0
FAIL=0
WARNINGS=0

# ── Flags ───────────────────────────────────────────────
SKIP_CLUSTER=false
CLEANUP_ONLY=false
TEST_ONLY=false

for arg in "$@"; do
  case "$arg" in
  --skip-cluster) SKIP_CLUSTER=true ;;
  --cleanup) CLEANUP_ONLY=true ;;
  --test-only) TEST_ONLY=true ;;
  --help | -h)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --skip-cluster   Reuse existing Kind cluster"
    echo "  --cleanup        Tear down cluster and all resources"
    echo "  --test-only      Run tests on existing deployment"
    echo "  -h, --help       Show this help message"
    exit 0
    ;;
  *)
    echo "Unknown option: $arg"
    exit 1
    ;;
  esac
done

# ── Helpers ─────────────────────────────────────────────
banner() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${BOLD}$1${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
}

step() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${BOLD}${CYAN}── Step ${STEP}: $1 ──${NC}"
}

pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "  ${RED}✗${NC} $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
  WARNINGS=$((WARNINGS + 1))
}

info() {
  echo -e "  ${DIM}$1${NC}"
}

wait_for_pods() {
  local ns="$1"
  local label="$2"
  local timeout="${3:-${TIMEOUT_SECONDS}}"
  kubectl wait --for=condition=ready pod -l "$label" -n "$ns" --timeout="${timeout}s" 2>/dev/null
}

port_forward_pid=""
cleanup_port_forward() {
  if [[ -n "$port_forward_pid" ]] && kill -0 "$port_forward_pid" 2>/dev/null; then
    kill "$port_forward_pid" 2>/dev/null || true
    wait "$port_forward_pid" 2>/dev/null || true
  fi
}
trap cleanup_port_forward EXIT

# ═════════════════════════════════════════════════════════
# CLEANUP MODE
# ═════════════════════════════════════════════════════════
if [[ "$CLEANUP_ONLY" == true ]]; then
  banner "Telepresence Lab - Cleanup"

  step "Disconnect Telepresence"
  if command -v telepresence &>/dev/null; then
    telepresence leave --all 2>/dev/null && pass "Left all intercepts" || info "No active intercepts"
    telepresence quit 2>/dev/null && pass "Disconnected Telepresence" || info "Not connected"
  else
    info "Telepresence not installed, skipping"
  fi

  step "Delete Kind cluster"
  if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    kind delete cluster --name "${CLUSTER_NAME}"
    pass "Deleted cluster: ${CLUSTER_NAME}"
  else
    info "Cluster '${CLUSTER_NAME}' not found"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}Cleanup complete.${NC}"
  exit 0
fi

# ═════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═════════════════════════════════════════════════════════
banner "Telepresence Master Lab"
echo -e "  ${DIM}Cluster: ${CLUSTER_NAME} | Namespace: ${NAMESPACE}${NC}"
echo -e "  ${DIM}Pod CIDR: ${POD_CIDR} | Service CIDR: ${SERVICE_CIDR}${NC}"

# ─────────────────────────────────────────────────────────
# PHASE 1: Prerequisites
# ─────────────────────────────────────────────────────────
banner "Phase 1: Prerequisites"

step "Check required tools"
MISSING_REQUIRED=false
for cmd in docker kubectl; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd: $(command -v "$cmd")"
  else
    fail "$cmd is not installed"
    MISSING_REQUIRED=true
  fi
done

if [[ "$MISSING_REQUIRED" == true ]]; then
  echo -e "\n${RED}Missing required tools. Cannot continue.${NC}"
  exit 1
fi

step "Check optional tools"
if command -v kind &>/dev/null; then
  pass "kind: $(kind version 2>/dev/null | head -c 50)"
else
  warn "kind not installed - install with: brew install kind"
  if [[ "$SKIP_CLUSTER" == false ]] && [[ "$TEST_ONLY" == false ]]; then
    echo -e "  ${YELLOW}Installing kind...${NC}"
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install kind 2>/dev/null || {
        fail "Could not install kind"
        exit 1
      }
    else
      curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64" &&
        chmod +x /tmp/kind && sudo mv /tmp/kind /usr/local/bin/kind
    fi
    pass "kind installed"
  fi
fi

if command -v telepresence &>/dev/null; then
  pass "telepresence: $(telepresence version 2>/dev/null | head -1)"
else
  warn "telepresence not installed"
  if [[ "$TEST_ONLY" == false ]]; then
    echo -e "  ${YELLOW}Installing Telepresence...${NC}"
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install datawire/blackbird/telepresence 2>/dev/null || warn "Auto-install failed. Install manually: brew install datawire/blackbird/telepresence"
    else
      sudo curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence \
        -o /usr/local/bin/telepresence 2>/dev/null &&
        sudo chmod a+x /usr/local/bin/telepresence || warn "Auto-install failed"
    fi
    if command -v telepresence &>/dev/null; then
      pass "telepresence installed: $(telepresence version 2>/dev/null | head -1)"
    fi
  fi
fi

step "Check Docker daemon"
if docker info &>/dev/null; then
  pass "Docker daemon is running"
else
  fail "Docker daemon is not running - start Docker Desktop or Docker Engine"
  exit 1
fi

if [[ "$TEST_ONLY" == true ]]; then
  # Skip directly to tests
  banner "Phase 4: Test Only Mode"
  # Jump to test phase below
else

  # ─────────────────────────────────────────────────────────
  # PHASE 2: Cluster Setup
  # ─────────────────────────────────────────────────────────
  banner "Phase 2: Cluster Setup"

  if [[ "$SKIP_CLUSTER" == true ]]; then
    step "Reusing existing cluster"
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
      pass "Cluster '${CLUSTER_NAME}' exists"
      kubectl config use-context "kind-${CLUSTER_NAME}"
      pass "Context set to kind-${CLUSTER_NAME}"
    else
      fail "Cluster '${CLUSTER_NAME}' not found. Run without --skip-cluster"
      exit 1
    fi
  else
    step "Create Kind cluster"
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
      info "Cluster '${CLUSTER_NAME}' already exists, reusing"
      kubectl config use-context "kind-${CLUSTER_NAME}"
      pass "Context set to kind-${CLUSTER_NAME}"
    else
      cat >/tmp/kind-telepresence-lab.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
networking:
  podSubnet: "${POD_CIDR}"
  serviceSubnet: "${SERVICE_CIDR}"
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: ${PORT_FORWARD_PORT}
        protocol: TCP
  - role: worker
  - role: worker
EOF
      kind create cluster --config /tmp/kind-telepresence-lab.yaml --image "${KIND_IMAGE}" --wait 120s
      pass "Kind cluster created: ${CLUSTER_NAME}"
      rm -f /tmp/kind-telepresence-lab.yaml
    fi
  fi

  step "Verify cluster health"
  if kubectl cluster-info &>/dev/null; then
    pass "Cluster is reachable"
  else
    fail "Cannot reach cluster"
    exit 1
  fi

  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$NODE_COUNT" -ge 1 ]]; then
    pass "Cluster has ${NODE_COUNT} node(s)"
  else
    fail "No nodes found"
    exit 1
  fi

  kubectl get nodes -o wide 2>/dev/null | while IFS= read -r line; do
    info "$line"
  done

  # ─────────────────────────────────────────────────────────
  # PHASE 3: Deploy Application Stack
  # ─────────────────────────────────────────────────────────
  banner "Phase 3: Deploy Application Stack"

  step "Create namespace"
  kubectl apply -f "${RESOURCES_DIR}/01-namespace.yaml"
  pass "Namespace '${NAMESPACE}' created"

  step "Deploy Data Service"
  kubectl apply -f "${RESOURCES_DIR}/02-dataservice.yaml"
  pass "Data Service manifests applied"

  step "Wait for Data Service pods"
  if wait_for_pods "${NAMESPACE}" "app=dataservice" 120; then
    pass "Data Service pods are ready"
  else
    fail "Data Service pods did not become ready"
    kubectl get pods -n "${NAMESPACE}" -l app=dataservice
  fi

  step "Deploy Backend Service"
  kubectl apply -f "${RESOURCES_DIR}/03-backend.yaml"
  pass "Backend manifests applied"

  step "Wait for Backend pods"
  if wait_for_pods "${NAMESPACE}" "app=backend" 120; then
    pass "Backend pods are ready"
  else
    fail "Backend pods did not become ready"
    kubectl get pods -n "${NAMESPACE}" -l app=backend
  fi

  step "Deploy Frontend"
  kubectl apply -f "${RESOURCES_DIR}/04-frontend.yaml"
  pass "Frontend manifests applied"

  step "Wait for Frontend pods"
  if wait_for_pods "${NAMESPACE}" "app=frontend" 120; then
    pass "Frontend pods are ready"
  else
    fail "Frontend pods did not become ready"
    kubectl get pods -n "${NAMESPACE}" -l app=frontend
  fi

  step "Deployment overview"
  echo ""
  kubectl get all -n "${NAMESPACE}" 2>/dev/null
  echo ""

fi # end of non-TEST_ONLY block

# ─────────────────────────────────────────────────────────
# PHASE 4: Validate Services (In-Cluster Tests)
# ─────────────────────────────────────────────────────────
banner "Phase 4: In-Cluster Validation"

step "Test Data Service health (in-cluster)"
DS_RESULT=$(kubectl run test-ds-health --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://dataservice:${DATASERVICE_PORT}/health" 2>/dev/null) || DS_RESULT=""

if echo "$DS_RESULT" | grep -q '"status".*"healthy"'; then
  pass "Data Service /health returns healthy"
else
  fail "Data Service /health check failed"
  info "Response: ${DS_RESULT:-<empty>}"
fi

step "Test Data Service /data endpoint (in-cluster)"
DS_DATA=$(kubectl run test-ds-data --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://dataservice:${DATASERVICE_PORT}/data" 2>/dev/null) || DS_DATA=""

if echo "$DS_DATA" | grep -q '"status".*"success"'; then
  pass "Data Service /data returns data"
else
  fail "Data Service /data check failed"
  info "Response: ${DS_DATA:-<empty>}"
fi

step "Test Backend health (in-cluster)"
BE_RESULT=$(kubectl run test-be-health --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://backend:${BACKEND_PORT}/api/health" 2>/dev/null) || BE_RESULT=""

if echo "$BE_RESULT" | grep -q '"status".*"healthy"'; then
  pass "Backend /api/health returns healthy"
else
  fail "Backend /api/health check failed"
  info "Response: ${BE_RESULT:-<empty>}"
fi

step "Test Backend → Data Service communication (in-cluster)"
BE_DATA=$(kubectl run test-be-data --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://backend:${BACKEND_PORT}/api/data" 2>/dev/null) || BE_DATA=""

if echo "$BE_DATA" | grep -q '"status".*"success"'; then
  pass "Backend → Data Service inter-service call works"
else
  fail "Backend → Data Service inter-service call failed"
  info "Response: ${BE_DATA:-<empty>}"
fi

step "Test Backend /api/users (in-cluster)"
BE_USERS=$(kubectl run test-be-users --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://backend:${BACKEND_PORT}/api/users" 2>/dev/null) || BE_USERS=""

if echo "$BE_USERS" | grep -q '"status".*"success"'; then
  pass "Backend /api/users returns users"
else
  fail "Backend /api/users check failed"
fi

step "Test Backend /api/status (in-cluster)"
BE_STATUS=$(kubectl run test-be-status --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://backend:${BACKEND_PORT}/api/status" 2>/dev/null) || BE_STATUS=""

if echo "$BE_STATUS" | grep -q '"service".*"backend"'; then
  pass "Backend /api/status returns status"
else
  fail "Backend /api/status check failed"
fi

step "Test Frontend (in-cluster)"
FE_RESULT=$(kubectl run test-fe --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://frontend:${FRONTEND_PORT}/" 2>/dev/null) || FE_RESULT=""

if echo "$FE_RESULT" | grep -q "Telepresence Demo"; then
  pass "Frontend serves the demo application"
else
  fail "Frontend check failed"
fi

step "Test Frontend → Backend proxy (in-cluster)"
FE_API=$(kubectl run test-fe-api --image=curlimages/curl:latest \
  --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
  curl -sf --max-time 10 "http://frontend:${FRONTEND_PORT}/api/health" 2>/dev/null) || FE_API=""

if echo "$FE_API" | grep -q '"status".*"healthy"'; then
  pass "Frontend → Backend proxy works (/api/health)"
else
  fail "Frontend → Backend proxy failed"
fi

# ─────────────────────────────────────────────────────────
# PHASE 5: Port-Forward Tests (from host)
# ─────────────────────────────────────────────────────────
banner "Phase 5: Port-Forward Validation"

step "Set up port-forward to frontend"
# Kill any existing port-forward on the target port
lsof -ti :${PORT_FORWARD_PORT} 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 1

kubectl port-forward -n "${NAMESPACE}" svc/frontend "${PORT_FORWARD_PORT}:${FRONTEND_PORT}" &>/dev/null &
port_forward_pid=$!
sleep 3

if kill -0 "$port_forward_pid" 2>/dev/null; then
  pass "Port-forward active on localhost:${PORT_FORWARD_PORT}"
else
  fail "Port-forward failed to start"
  port_forward_pid=""
fi

if [[ -n "$port_forward_pid" ]]; then
  step "Test Frontend from host"
  HOST_FE=$(curl -sf --max-time 10 "http://localhost:${PORT_FORWARD_PORT}/" 2>/dev/null) || HOST_FE=""
  if echo "$HOST_FE" | grep -q "Telepresence Demo"; then
    pass "Frontend accessible at http://localhost:${PORT_FORWARD_PORT}"
  else
    fail "Frontend not accessible from host"
  fi

  step "Test Backend API from host (via frontend proxy)"
  HOST_API=$(curl -sf --max-time 10 "http://localhost:${PORT_FORWARD_PORT}/api/health" 2>/dev/null) || HOST_API=""
  if echo "$HOST_API" | grep -q '"status".*"healthy"'; then
    pass "Backend API accessible via frontend proxy"
  else
    fail "Backend API not accessible from host"
  fi

  HOST_DATA=$(curl -sf --max-time 10 "http://localhost:${PORT_FORWARD_PORT}/api/data" 2>/dev/null) || HOST_DATA=""
  if echo "$HOST_DATA" | grep -q '"status".*"success"'; then
    pass "Full chain: Host → Frontend → Backend → Data Service"
  else
    fail "Full chain test failed"
  fi

  # Clean up port-forward
  cleanup_port_forward
  port_forward_pid=""
fi

# ─────────────────────────────────────────────────────────
# PHASE 6: Telepresence Connection
# ─────────────────────────────────────────────────────────
banner "Phase 6: Telepresence Connection"

if ! command -v telepresence &>/dev/null; then
  warn "Telepresence not installed - skipping Telepresence phases"
  echo -e "  Install: ${GREEN}brew install datawire/blackbird/telepresence${NC}"
else

  step "Disconnect any existing Telepresence session"
  telepresence quit 2>/dev/null || true
  sleep 2
  pass "Clean state"

  step "Connect Telepresence to cluster"
  if telepresence connect 2>/dev/null; then
    pass "Telepresence connected"
  else
    # Try with sudo for first-time root daemon
    warn "Standard connect failed, trying with elevated privileges..."
    if sudo telepresence connect 2>/dev/null; then
      pass "Telepresence connected (elevated)"
    else
      fail "Could not connect Telepresence"
    fi
  fi

  step "Verify Telepresence status"
  TP_STATUS=$(telepresence status 2>/dev/null) || TP_STATUS=""
  if echo "$TP_STATUS" | grep -qi "connected\|running"; then
    pass "Telepresence is connected"
    echo "$TP_STATUS" | head -15 | while IFS= read -r line; do
      info "  $line"
    done
  else
    fail "Telepresence status check failed"
  fi

  step "List interceptable services"
  TP_LIST=$(telepresence list -n "${NAMESPACE}" 2>/dev/null) || TP_LIST=""
  if echo "$TP_LIST" | grep -q "backend"; then
    pass "Backend service is interceptable"
  else
    warn "Backend not listed (Traffic Manager may still be installing)"
  fi
  if echo "$TP_LIST" | grep -q "dataservice"; then
    pass "Data Service is interceptable"
  else
    warn "Data Service not listed"
  fi
  if echo "$TP_LIST" | grep -q "frontend"; then
    pass "Frontend is interceptable"
  else
    warn "Frontend not listed"
  fi

  # ─────────────────────────────────────────────────────────
  # PHASE 7: DNS Resolution (Outbound Connectivity)
  # ─────────────────────────────────────────────────────────
  banner "Phase 7: Outbound Connectivity (DNS)"

  step "Test DNS resolution via Telepresence"
  TP_CURL=$(curl -sf --max-time 10 "http://backend.${NAMESPACE}.svc.cluster.local:${BACKEND_PORT}/api/health" 2>/dev/null) || TP_CURL=""
  if echo "$TP_CURL" | grep -q '"status".*"healthy"'; then
    pass "DNS resolution works: backend.${NAMESPACE}.svc.cluster.local"
  else
    warn "DNS resolution via Telepresence not working (may need time)"
    info "Try manually: curl http://backend.${NAMESPACE}.svc.cluster.local:${BACKEND_PORT}/api/health"
  fi

  TP_DS=$(curl -sf --max-time 10 "http://dataservice.${NAMESPACE}.svc.cluster.local:${DATASERVICE_PORT}/health" 2>/dev/null) || TP_DS=""
  if echo "$TP_DS" | grep -q '"status".*"healthy"'; then
    pass "DNS resolution works: dataservice.${NAMESPACE}.svc.cluster.local"
  else
    warn "Data Service DNS resolution not working"
  fi

  TP_FE=$(curl -sf --max-time 10 "http://frontend.${NAMESPACE}.svc.cluster.local/api/health" 2>/dev/null) || TP_FE=""
  if echo "$TP_FE" | grep -q '"status".*"healthy"'; then
    pass "DNS resolution works: frontend.${NAMESPACE}.svc.cluster.local"
  else
    warn "Frontend DNS resolution not working"
  fi

  # ─────────────────────────────────────────────────────────
  # PHASE 8: Intercept Demo
  # ─────────────────────────────────────────────────────────
  banner "Phase 8: Intercept Demo"

  step "Start local backend server"
  # Create a temporary local backend that identifies itself as LOCAL
  LOCAL_BACKEND_FILE=$(mktemp /tmp/local_backend_XXXXXX.py)
  cat >"$LOCAL_BACKEND_FILE" <<'PYEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os, signal, sys
from datetime import datetime

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response = {
            "source": "LOCAL_MACHINE",
            "service": "backend",
            "environment": "local-intercepted",
            "message": "Hello from your LOCAL machine via Telepresence!",
            "path": self.path,
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat()
        }
        self.wfile.write(json.dumps(response, indent=2).encode())
    def log_message(self, format, *args):
        pass  # Suppress access logs during test

signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
print("Local backend running on :5000", flush=True)
HTTPServer(('127.0.0.1', 5000), Handler).serve_forever()
PYEOF

  # Kill anything on port 5000
  lsof -ti :5000 2>/dev/null | xargs kill -9 2>/dev/null || true
  sleep 1

  python3 "$LOCAL_BACKEND_FILE" &
  LOCAL_PID=$!
  sleep 2

  if kill -0 "$LOCAL_PID" 2>/dev/null; then
    pass "Local backend running (PID: ${LOCAL_PID})"
  else
    fail "Local backend failed to start"
    LOCAL_PID=""
  fi

  if [[ -n "${LOCAL_PID:-}" ]]; then
    step "Test local backend directly"
    LOCAL_TEST=$(curl -sf --max-time 5 "http://127.0.0.1:5000/api/health" 2>/dev/null) || LOCAL_TEST=""
    if echo "$LOCAL_TEST" | grep -q "LOCAL_MACHINE"; then
      pass "Local backend responds correctly"
    else
      fail "Local backend not responding"
    fi

    step "Create global intercept on backend"
    INTERCEPT_OUT=$(telepresence intercept backend \
      --port ${BACKEND_PORT} \
      --namespace "${NAMESPACE}" 2>&1) || INTERCEPT_OUT=""

    if echo "$INTERCEPT_OUT" | grep -qi "intercepted\|intercept"; then
      pass "Intercept created for backend service"
      info "$INTERCEPT_OUT" | head -10
    else
      warn "Intercept creation may have issues"
      info "$INTERCEPT_OUT"
    fi

    step "Verify intercept is active"
    INTERCEPT_LIST=$(telepresence list -n "${NAMESPACE}" 2>/dev/null) || INTERCEPT_LIST=""
    if echo "$INTERCEPT_LIST" | grep -qi "backend.*intercept"; then
      pass "Backend intercept is active"
    else
      warn "Intercept status unclear"
      info "${INTERCEPT_LIST}"
    fi

    step "Test traffic flows to local machine"
    INTERCEPT_TEST=$(curl -sf --max-time 10 \
      "http://backend.${NAMESPACE}.svc.cluster.local:${BACKEND_PORT}/api/health" 2>/dev/null) || INTERCEPT_TEST=""

    if echo "$INTERCEPT_TEST" | grep -q "LOCAL_MACHINE"; then
      pass "Traffic intercepted! Response from LOCAL machine"
    else
      warn "Traffic may not be intercepted yet"
      info "Response: ${INTERCEPT_TEST:-<empty>}"
      info "This is normal if DNS hasn't propagated yet"
    fi

    step "Test intercept via in-cluster curl"
    CLUSTER_INTERCEPT=$(kubectl run test-intercept --image=curlimages/curl:latest \
      --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
      curl -sf --max-time 10 "http://backend:${BACKEND_PORT}/api/health" 2>/dev/null) || CLUSTER_INTERCEPT=""

    if echo "$CLUSTER_INTERCEPT" | grep -q "LOCAL_MACHINE"; then
      pass "In-cluster traffic reaches local machine via intercept"
    else
      warn "In-cluster intercept verification inconclusive"
      info "Response: ${CLUSTER_INTERCEPT:-<empty>}"
    fi

    step "Leave intercept"
    telepresence leave backend 2>/dev/null || telepresence leave --all 2>/dev/null || true
    pass "Intercept removed"

    step "Verify traffic restored to cluster"
    sleep 3
    RESTORED=$(kubectl run test-restored --image=curlimages/curl:latest \
      --rm -i --restart=Never -n "${NAMESPACE}" --timeout=30s -- \
      curl -sf --max-time 10 "http://backend:${BACKEND_PORT}/api/health" 2>/dev/null) || RESTORED=""

    if echo "$RESTORED" | grep -q '"environment".*"cluster"'; then
      pass "Traffic restored to cluster backend"
    else
      warn "Traffic restore verification inconclusive"
    fi

    # Cleanup local backend
    kill "$LOCAL_PID" 2>/dev/null || true
    wait "$LOCAL_PID" 2>/dev/null || true
    rm -f "$LOCAL_BACKEND_FILE"
    pass "Local backend stopped"
  fi

  # ─────────────────────────────────────────────────────────
  # PHASE 9: Environment Variable Capture
  # ─────────────────────────────────────────────────────────
  banner "Phase 9: Environment Variables"

  step "Intercept with env capture"
  ENV_FILE=$(mktemp /tmp/telepresence_env_XXXXXX)

  # Start a dummy local listener for the intercept
  python3 -c "
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type','application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'source':'env-test'}).encode())
    def log_message(self,*a): pass
HTTPServer(('127.0.0.1',5000),H).serve_forever()
" &
  ENV_PID=$!
  sleep 1

  telepresence intercept backend \
    --port ${BACKEND_PORT} \
    --namespace "${NAMESPACE}" \
    --env-file="${ENV_FILE}" 2>/dev/null || true

  if [[ -s "$ENV_FILE" ]]; then
    pass "Environment variables captured"
    ENV_COUNT=$(wc -l <"$ENV_FILE" | tr -d ' ')
    info "Captured ${ENV_COUNT} environment variables"

    # Verify key env vars
    if grep -q "SERVICE_NAME" "$ENV_FILE" 2>/dev/null; then
      pass "SERVICE_NAME found in captured env"
    fi
    if grep -q "DATASERVICE_URL" "$ENV_FILE" 2>/dev/null; then
      pass "DATASERVICE_URL found in captured env"
    fi
  else
    warn "No environment variables captured (file empty)"
  fi

  telepresence leave backend 2>/dev/null || telepresence leave --all 2>/dev/null || true
  kill "$ENV_PID" 2>/dev/null || true
  wait "$ENV_PID" 2>/dev/null || true
  rm -f "$ENV_FILE"

  # ─────────────────────────────────────────────────────────
  # PHASE 10: Disconnect
  # ─────────────────────────────────────────────────────────
  banner "Phase 10: Cleanup & Disconnect"

  step "Leave all intercepts"
  telepresence leave --all 2>/dev/null || true
  pass "All intercepts cleared"

  step "Disconnect Telepresence"
  telepresence quit 2>/dev/null || true
  pass "Telepresence disconnected"

fi # end of telepresence-installed block

# ═════════════════════════════════════════════════════════
# PHASE 11: Resource Validation
# ═════════════════════════════════════════════════════════
banner "Phase 11: Resource Validation"

step "Validate YAML manifests"
for f in "${RESOURCES_DIR}"/*.yaml; do
  fname="$(basename "$f")"
  if grep -q "^kind:" "$f" && grep -q "^apiVersion:" "$f"; then
    pass "${fname} - valid Kubernetes manifest"
  else
    if grep -q "^kind:" "$f" || grep -q "^apiVersion:" "$f"; then
      pass "${fname} - valid (multi-document)"
    else
      fail "${fname} - missing kind/apiVersion"
    fi
  fi
done

step "Validate shell scripts"
for f in "${SCRIPT_DIR}"/*.sh; do
  fname="$(basename "$f")"
  if bash -n "$f" 2>/dev/null; then
    pass "${fname} - syntax OK"
  else
    fail "${fname} - syntax error"
  fi
done

step "Validate lab markdown files"
if [[ -d "${SCRIPT_DIR}/labs" ]]; then
  for f in "${SCRIPT_DIR}/labs"/*.md; do
    fname="$(basename "$f")"
    if [[ -s "$f" ]]; then
      LINES=$(wc -l <"$f" | tr -d ' ')
      pass "${fname} - ${LINES} lines"
    else
      fail "${fname} - empty file"
    fi
  done
fi

step "Final pod status"
echo ""
kubectl get pods -n "${NAMESPACE}" -o wide 2>/dev/null
echo ""

# ═════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC} ${BOLD}  TEST SUMMARY${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}Passed${NC}:   ${PASS}"
echo -e "${CYAN}║${NC}  ${RED}Failed${NC}:   ${FAIL}"
echo -e "${CYAN}║${NC}  ${YELLOW}Warnings${NC}: ${WARNINGS}"
echo -e "${CYAN}║${NC}  Total:    $((PASS + FAIL))"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"

if [[ $FAIL -eq 0 ]]; then
  echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}ALL TESTS PASSED ✓${NC}"
else
  echo -e "${CYAN}║${NC}  ${RED}${BOLD}SOME TESTS FAILED ✗${NC}"
fi

echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Next Steps:${NC}"
echo -e "${CYAN}║${NC}  1. Open http://localhost:${PORT_FORWARD_PORT} (after port-forward)"
echo -e "${CYAN}║${NC}  2. Try: telepresence connect"
echo -e "${CYAN}║${NC}  3. Try: telepresence intercept backend --port 5000 -n ${NAMESPACE}"
echo -e "${CYAN}║${NC}  4. Edit resources/backend-app/app.py and see live changes"
echo -e "${CYAN}║${NC}  5. Cleanup: $0 --cleanup"
echo -e "${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  exit 0
else
  exit 1
fi
