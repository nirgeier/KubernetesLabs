#!/bin/bash

# Raftt Lab 38 - Comprehensive Test Script
# Tests all lab content: prerequisites, manifests, Docker image, cluster deployment,
# API endpoints, the deliberate bug, file structure, and cleanup script.

set -e

###############################################################################
# Colors and helpers
###############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
SKIPPED=0

CLUSTER_NAME="raftt-lab"
NAMESPACE="raftt-lab"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT_FWD_PID=""
LOCAL_SERVER_PID=""
TEST_PORT=13579
CLUSTER_PORT=13580

pass() {
  PASSED=$((PASSED + 1))
  echo -e "  ${GREEN}✓ PASS${NC}: $1"
}

fail() {
  FAILED=$((FAILED + 1))
  echo -e "  ${RED}✗ FAIL${NC}: $1"
}

skip() {
  SKIPPED=$((SKIPPED + 1))
  echo -e "  ${YELLOW}⊘ SKIP${NC}: $1"
}

section() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

cleanup_on_exit() {
  # Kill port-forward if running
  if [ -n "$PORT_FWD_PID" ] && kill -0 "$PORT_FWD_PID" 2>/dev/null; then
    kill "$PORT_FWD_PID" 2>/dev/null || true
    wait "$PORT_FWD_PID" 2>/dev/null || true
  fi
  # Kill local server if running
  if [ -n "$LOCAL_SERVER_PID" ] && kill -0 "$LOCAL_SERVER_PID" 2>/dev/null; then
    kill "$LOCAL_SERVER_PID" 2>/dev/null || true
    wait "$LOCAL_SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup_on_exit EXIT

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Raftt Lab 38 - Comprehensive Tests${NC}"
echo -e "${GREEN}========================================${NC}"

###############################################################################
# Section 1: File Structure & Manifest Validation
###############################################################################
section "1. File Structure & Manifest Validation"

# Required files
for f in README.md raftt.yaml setup.sh cleanup.sh \
  app/server.js app/package.json app/Dockerfile app/.dockerignore \
  resources/kind-config.yaml resources/01-namespace.yaml \
  resources/02-deployment.yaml resources/03-service.yaml; do
  if [ -f "${SCRIPT_DIR}/${f}" ]; then
    pass "File exists: ${f}"
  else
    fail "File missing: ${f}"
  fi
done

# Scripts are executable
for f in setup.sh cleanup.sh; do
  if [ -x "${SCRIPT_DIR}/${f}" ]; then
    pass "${f} is executable"
  else
    fail "${f} is NOT executable"
  fi
done

# Validate YAML syntax (if python3 available)
if command -v python3 &>/dev/null; then
  for f in raftt.yaml resources/kind-config.yaml resources/01-namespace.yaml \
    resources/02-deployment.yaml resources/03-service.yaml; do
    if python3 -c "import yaml; yaml.safe_load(open('${SCRIPT_DIR}/${f}'))" 2>/dev/null; then
      pass "Valid YAML: ${f}"
    else
      fail "Invalid YAML: ${f}"
    fi
  done
else
  skip "python3 not available - skipping YAML validation"
fi

# Validate package.json
if command -v node &>/dev/null; then
  if node -e "JSON.parse(require('fs').readFileSync('${SCRIPT_DIR}/app/package.json'))" 2>/dev/null; then
    pass "Valid JSON: app/package.json"
  else
    fail "Invalid JSON: app/package.json"
  fi
  # Check required dependencies
  if node -e "const p=JSON.parse(require('fs').readFileSync('${SCRIPT_DIR}/app/package.json')); if(!p.dependencies.express) process.exit(1);" 2>/dev/null; then
    pass "package.json has express dependency"
  else
    fail "package.json missing express dependency"
  fi
  if node -e "const p=JSON.parse(require('fs').readFileSync('${SCRIPT_DIR}/app/package.json')); if(!p.devDependencies.nodemon) process.exit(1);" 2>/dev/null; then
    pass "package.json has nodemon devDependency"
  else
    fail "package.json missing nodemon devDependency"
  fi
fi

###############################################################################
# Section 2: Manifest Content Validation
###############################################################################
section "2. Kubernetes Manifest Content"

# Namespace manifest
if grep -q "name: raftt-lab" "${SCRIPT_DIR}/resources/01-namespace.yaml"; then
  pass "Namespace manifest targets 'raftt-lab'"
else
  fail "Namespace manifest does not target 'raftt-lab'"
fi

# Deployment manifest checks
DEPLOY="${SCRIPT_DIR}/resources/02-deployment.yaml"
if grep -q "namespace: raftt-lab" "$DEPLOY"; then
  pass "Deployment is in namespace 'raftt-lab'"
else
  fail "Deployment is NOT in namespace 'raftt-lab'"
fi
if grep -q "image: raftt-lab-backend:latest" "$DEPLOY"; then
  pass "Deployment uses correct image"
else
  fail "Deployment does NOT use correct image"
fi
if grep -q "imagePullPolicy: Never" "$DEPLOY"; then
  pass "Deployment has imagePullPolicy: Never (required for kind)"
else
  fail "Deployment missing imagePullPolicy: Never"
fi
if grep -q "containerPort: 3000" "$DEPLOY"; then
  pass "Deployment exposes port 3000"
else
  fail "Deployment does NOT expose port 3000"
fi
if grep -q "containerPort: 9229" "$DEPLOY"; then
  pass "Deployment exposes debug port 9229"
else
  fail "Deployment does NOT expose debug port 9229"
fi
if grep -q "readinessProbe" "$DEPLOY"; then
  pass "Deployment has readinessProbe"
else
  fail "Deployment missing readinessProbe"
fi
if grep -q "livenessProbe" "$DEPLOY"; then
  pass "Deployment has livenessProbe"
else
  fail "Deployment missing livenessProbe"
fi
if grep -q "resources:" "$DEPLOY"; then
  pass "Deployment has resource requests/limits"
else
  fail "Deployment missing resource requests/limits"
fi

# Service manifest checks
SVC="${SCRIPT_DIR}/resources/03-service.yaml"
if grep -q "port: 3000" "$SVC" && grep -q "port: 9229" "$SVC"; then
  pass "Service exposes both 3000 and 9229"
else
  fail "Service missing expected ports"
fi

# Raftt config checks
RAFTT="${SCRIPT_DIR}/raftt.yaml"
if grep -q "context: kind-raftt-lab" "$RAFTT"; then
  pass "raftt.yaml targets kind-raftt-lab context"
else
  fail "raftt.yaml does NOT target kind-raftt-lab context"
fi
if grep -q "node_modules" "$RAFTT"; then
  pass "raftt.yaml excludes node_modules from sync"
else
  fail "raftt.yaml does NOT exclude node_modules"
fi
if grep -q "nodemon" "$RAFTT"; then
  pass "raftt.yaml uses nodemon for hot-reload"
else
  fail "raftt.yaml does NOT use nodemon"
fi
if grep -q "legacy-watch" "$RAFTT"; then
  pass "raftt.yaml uses --legacy-watch (required for kind)"
else
  fail "raftt.yaml missing --legacy-watch"
fi
if grep -q "9229" "$RAFTT"; then
  pass "raftt.yaml exposes debug port 9229"
else
  fail "raftt.yaml does NOT expose debug port 9229"
fi

# Dockerfile checks
DOCKERFILE="${SCRIPT_DIR}/app/Dockerfile"
if grep -q "FROM node:20-alpine" "$DOCKERFILE"; then
  pass "Dockerfile uses node:20-alpine base"
else
  fail "Dockerfile does NOT use expected base image"
fi
if grep -q "EXPOSE 3000 9229" "$DOCKERFILE"; then
  pass "Dockerfile exposes ports 3000 and 9229"
else
  fail "Dockerfile does NOT expose expected ports"
fi

# kind config checks
KIND_CFG="${SCRIPT_DIR}/resources/kind-config.yaml"
if grep -q "containerPort: 30000" "$KIND_CFG"; then
  pass "kind config maps port 30000"
else
  fail "kind config missing port mapping"
fi

###############################################################################
# Section 3: Prerequisites Check
###############################################################################
section "3. Prerequisites"

for cmd in docker kind kubectl node npm; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd is installed ($(command -v "$cmd"))"
  else
    fail "$cmd is NOT installed"
  fi
done

###############################################################################
# Section 4: Docker Image Build
###############################################################################
section "4. Docker Image Build"

if docker build -t raftt-lab-backend:test "${SCRIPT_DIR}/app" >/dev/null 2>&1; then
  pass "Docker image builds successfully"
else
  fail "Docker image build FAILED"
fi

# Check image exists
if docker image inspect raftt-lab-backend:test >/dev/null 2>&1; then
  pass "Docker image 'raftt-lab-backend:test' exists"
else
  fail "Docker image 'raftt-lab-backend:test' not found"
fi

# Clean up test image tag
docker rmi raftt-lab-backend:test >/dev/null 2>&1 || true

###############################################################################
# Section 5: Local Node.js App Tests (no cluster needed)
###############################################################################
section "5. Local Node.js Application Tests"

# Install dependencies if needed
if [ ! -d "${SCRIPT_DIR}/app/node_modules" ]; then
  echo "  Installing npm dependencies..."
  (cd "${SCRIPT_DIR}/app" && npm install --silent) 2>/dev/null
fi

# Start the server locally
PORT=$TEST_PORT NODE_ENV=test LOG_LEVEL=debug node "${SCRIPT_DIR}/app/server.js" &
LOCAL_SERVER_PID=$!
sleep 2

if kill -0 "$LOCAL_SERVER_PID" 2>/dev/null; then
  pass "Local server started on port ${TEST_PORT}"
else
  fail "Local server failed to start"
fi

# --- GET /status ---
echo ""
echo -e "  ${YELLOW}Testing GET /status${NC}"
STATUS=$(curl -s -w "\n%{http_code}" "http://localhost:${TEST_PORT}/status")
STATUS_CODE=$(echo "$STATUS" | tail -1)
STATUS_BODY=$(echo "$STATUS" | sed '$d')

if [ "$STATUS_CODE" = "200" ]; then
  pass "GET /status returns HTTP 200"
else
  fail "GET /status returned HTTP ${STATUS_CODE} (expected 200)"
fi

if echo "$STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['service']=='raftt-lab-backend'" 2>/dev/null; then
  pass "GET /status → service = 'raftt-lab-backend'"
else
  fail "GET /status → service field mismatch"
fi

if echo "$STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['status']=='healthy'" 2>/dev/null; then
  pass "GET /status → status = 'healthy'"
else
  fail "GET /status → status field mismatch"
fi

if echo "$STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert isinstance(d['uptime'], (int, float))" 2>/dev/null; then
  pass "GET /status → uptime is a number"
else
  fail "GET /status → uptime is not a number"
fi

if echo "$STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'MB' in d['memory']['rss']" 2>/dev/null; then
  pass "GET /status → memory.rss contains 'MB'"
else
  fail "GET /status → memory.rss format incorrect"
fi

if echo "$STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'MB' in d['memory']['heapUsed']" 2>/dev/null; then
  pass "GET /status → memory.heapUsed contains 'MB'"
else
  fail "GET /status → memory.heapUsed format incorrect"
fi

# --- GET /info ---
echo ""
echo -e "  ${YELLOW}Testing GET /info${NC}"
INFO=$(curl -s -w "\n%{http_code}" "http://localhost:${TEST_PORT}/info")
INFO_CODE=$(echo "$INFO" | tail -1)
INFO_BODY=$(echo "$INFO" | sed '$d')

if [ "$INFO_CODE" = "200" ]; then
  pass "GET /info returns HTTP 200"
else
  fail "GET /info returned HTTP ${INFO_CODE}"
fi

if echo "$INFO_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['version']=='1.0.0'" 2>/dev/null; then
  pass "GET /info → version = '1.0.0'"
else
  fail "GET /info → version mismatch"
fi

if echo "$INFO_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['nodeEnv']=='test'" 2>/dev/null; then
  pass "GET /info → nodeEnv reflects NODE_ENV env var"
else
  fail "GET /info → nodeEnv does not reflect env var"
fi

if echo "$INFO_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['logLevel']=='debug'" 2>/dev/null; then
  pass "GET /info → logLevel reflects LOG_LEVEL env var"
else
  fail "GET /info → logLevel does not reflect env var"
fi

# --- POST /calculate: all operations ---
echo ""
echo -e "  ${YELLOW}Testing POST /calculate - arithmetic operations${NC}"

# Addition
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":10,"b":5,"operation":"add"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==15" 2>/dev/null; then
  pass "POST /calculate → 10 + 5 = 15"
else
  fail "POST /calculate → addition failed"
fi

# Subtraction
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":10,"b":3,"operation":"subtract"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==7" 2>/dev/null; then
  pass "POST /calculate → 10 - 3 = 7"
else
  fail "POST /calculate → subtraction failed"
fi

# Multiplication
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":4,"b":5,"operation":"multiply"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==20" 2>/dev/null; then
  pass "POST /calculate → 4 × 5 = 20"
else
  fail "POST /calculate → multiplication failed"
fi

# Division (valid)
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":10,"b":2,"operation":"divide"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==5" 2>/dev/null; then
  pass "POST /calculate → 10 ÷ 2 = 5"
else
  fail "POST /calculate → division failed"
fi

# Division with decimals
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":7,"b":2,"operation":"divide"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==3.5" 2>/dev/null; then
  pass "POST /calculate → 7 ÷ 2 = 3.5 (decimal division)"
else
  fail "POST /calculate → decimal division failed"
fi

# Negative numbers
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":-10,"b":3,"operation":"add"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==-7" 2>/dev/null; then
  pass "POST /calculate → -10 + 3 = -7 (negative numbers)"
else
  fail "POST /calculate → negative number handling failed"
fi

# Zero values
RESULT=$(curl -s -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":0,"b":0,"operation":"add"}')
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==0" 2>/dev/null; then
  pass "POST /calculate → 0 + 0 = 0 (zero values)"
else
  fail "POST /calculate → zero value handling failed"
fi

# --- POST /calculate: the deliberate bug (Module 3) ---
echo ""
echo -e "  ${YELLOW}Testing POST /calculate - division by zero bug (Module 3)${NC}"

DIV_ZERO=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":10,"b":0,"operation":"divide"}')
DIV_ZERO_CODE=$(echo "$DIV_ZERO" | tail -1)
DIV_ZERO_BODY=$(echo "$DIV_ZERO" | sed '$d')

if [ "$DIV_ZERO_CODE" = "500" ]; then
  pass "Divide-by-zero returns HTTP 500 (the deliberate bug)"
else
  fail "Divide-by-zero returned HTTP ${DIV_ZERO_CODE} (expected 500)"
fi

if echo "$DIV_ZERO_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'divide by zero' in d['message'].lower()" 2>/dev/null; then
  pass "Divide-by-zero error message mentions 'divide by zero'"
else
  fail "Divide-by-zero error message is incorrect"
fi

if echo "$DIV_ZERO_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['error']=='Internal Server Error'" 2>/dev/null; then
  pass "Divide-by-zero error type is 'Internal Server Error'"
else
  fail "Divide-by-zero error type is incorrect"
fi

# --- POST /calculate: input validation ---
echo ""
echo -e "  ${YELLOW}Testing POST /calculate - input validation${NC}"

# Missing fields
MISSING=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":10}')
MISSING_CODE=$(echo "$MISSING" | tail -1)
if [ "$MISSING_CODE" = "400" ]; then
  pass "Missing fields returns HTTP 400"
else
  fail "Missing fields returned HTTP ${MISSING_CODE} (expected 400)"
fi

# Empty body
EMPTY=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{}')
EMPTY_CODE=$(echo "$EMPTY" | tail -1)
if [ "$EMPTY_CODE" = "400" ]; then
  pass "Empty body returns HTTP 400"
else
  fail "Empty body returned HTTP ${EMPTY_CODE} (expected 400)"
fi

# Unknown operation
UNKNOWN=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${TEST_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":1,"b":2,"operation":"modulo"}')
UNKNOWN_CODE=$(echo "$UNKNOWN" | tail -1)
UNKNOWN_BODY=$(echo "$UNKNOWN" | sed '$d')
if [ "$UNKNOWN_CODE" = "400" ]; then
  pass "Unknown operation 'modulo' returns HTTP 400"
else
  fail "Unknown operation returned HTTP ${UNKNOWN_CODE} (expected 400)"
fi

if echo "$UNKNOWN_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'modulo' in d['message']" 2>/dev/null; then
  pass "Unknown operation error mentions the operation name"
else
  fail "Unknown operation error does not mention the operation name"
fi

# --- GET /info: FEATURE_FLAG_V2 env var (Module 4) ---
echo ""
echo -e "  ${YELLOW}Testing environment variable behavior (Module 4)${NC}"

# Without FEATURE_FLAG_V2 set, field should be absent
if echo "$INFO_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'featureFlagV2' not in d" 2>/dev/null; then
  pass "GET /info → featureFlagV2 absent when env var not set"
else
  fail "GET /info → featureFlagV2 should not be present without env var"
fi

# Stop the local server
kill "$LOCAL_SERVER_PID" 2>/dev/null || true
wait "$LOCAL_SERVER_PID" 2>/dev/null || true
LOCAL_SERVER_PID=""

# Start server WITH FEATURE_FLAG_V2 to test Module 4 behavior
FEATURE_FLAG_V2=true PORT=$TEST_PORT NODE_ENV=development LOG_LEVEL=verbose \
  node "${SCRIPT_DIR}/app/server.js" &
LOCAL_SERVER_PID=$!
sleep 2

INFO_V2=$(curl -s "http://localhost:${TEST_PORT}/info")
if echo "$INFO_V2" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['featureFlagV2']=='true'" 2>/dev/null; then
  pass "GET /info → featureFlagV2 = 'true' when env var is set"
else
  fail "GET /info → featureFlagV2 not reflected from env var"
fi

if echo "$INFO_V2" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['logLevel']=='verbose'" 2>/dev/null; then
  pass "GET /info → logLevel = 'verbose' (env var override)"
else
  fail "GET /info → logLevel env var override not working"
fi

if echo "$INFO_V2" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['nodeEnv']=='development'" 2>/dev/null; then
  pass "GET /info → nodeEnv = 'development' (env var override)"
else
  fail "GET /info → nodeEnv env var override not working"
fi

# Stop the local server
kill "$LOCAL_SERVER_PID" 2>/dev/null || true
wait "$LOCAL_SERVER_PID" 2>/dev/null || true
LOCAL_SERVER_PID=""

###############################################################################
# Section 6: Cluster Deployment Tests
###############################################################################
section "6. Cluster Deployment Tests"

# Check if cluster exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  pass "kind cluster '${CLUSTER_NAME}' exists"
else
  skip "kind cluster '${CLUSTER_NAME}' not running - run setup.sh first"
  echo ""
  echo -e "${YELLOW}  Skipping cluster tests. Run ./setup.sh to create the cluster.${NC}"
  # Jump to summary
  section "Test Summary"
  TOTAL=$((PASSED + FAILED + SKIPPED))
  echo ""
  echo -e "  ${GREEN}Passed${NC}:  ${PASSED}"
  echo -e "  ${RED}Failed${NC}:  ${FAILED}"
  echo -e "  ${YELLOW}Skipped${NC}: ${SKIPPED}"
  echo -e "  Total:   ${TOTAL}"
  echo ""
  if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}Some tests FAILED!${NC}"
    exit 1
  else
    echo -e "${GREEN}All tests PASSED!${NC}"
    exit 0
  fi
fi

kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null 2>&1

# Namespace exists
if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  pass "Namespace '${NAMESPACE}' exists"
else
  fail "Namespace '${NAMESPACE}' does not exist"
fi

# Deployment exists and is available
if kubectl get deployment backend -n "${NAMESPACE}" >/dev/null 2>&1; then
  pass "Deployment 'backend' exists"
else
  fail "Deployment 'backend' does not exist"
fi

AVAILABLE=$(kubectl get deployment backend -n "${NAMESPACE}" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAILABLE" = "1" ]; then
  pass "Deployment 'backend' has 1 available replica"
else
  fail "Deployment 'backend' has ${AVAILABLE:-0} available replicas (expected 1)"
fi

# Service exists
if kubectl get service backend -n "${NAMESPACE}" >/dev/null 2>&1; then
  pass "Service 'backend' exists"
else
  fail "Service 'backend' does not exist"
fi

# Check service ports
SVC_PORTS=$(kubectl get service backend -n "${NAMESPACE}" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null)
if echo "$SVC_PORTS" | grep -q "3000"; then
  pass "Service exposes port 3000"
else
  fail "Service does not expose port 3000"
fi
if echo "$SVC_PORTS" | grep -q "9229"; then
  pass "Service exposes debug port 9229"
else
  fail "Service does not expose debug port 9229"
fi

# Pod is running and ready
POD_STATUS=$(kubectl get pods -l app=backend -n "${NAMESPACE}" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" = "Running" ]; then
  pass "Backend Pod is Running"
else
  fail "Backend Pod status is '${POD_STATUS:-unknown}' (expected Running)"
fi

POD_READY=$(kubectl get pods -l app=backend -n "${NAMESPACE}" -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$POD_READY" = "True" ]; then
  pass "Backend Pod is Ready"
else
  fail "Backend Pod is not Ready"
fi

# Check container image
POD_IMAGE=$(kubectl get pods -l app=backend -n "${NAMESPACE}" -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null)
if [ "$POD_IMAGE" = "raftt-lab-backend:latest" ]; then
  pass "Pod runs correct image: ${POD_IMAGE}"
else
  fail "Pod runs wrong image: ${POD_IMAGE} (expected raftt-lab-backend:latest)"
fi

# Check environment variables on the pod
POD_NODE_ENV=$(kubectl exec -n "${NAMESPACE}" deploy/backend -- printenv NODE_ENV 2>/dev/null || echo "")
if [ "$POD_NODE_ENV" = "production" ]; then
  pass "Pod NODE_ENV = 'production' (pre-Raftt default)"
else
  fail "Pod NODE_ENV = '${POD_NODE_ENV}' (expected 'production')"
fi

# Check resource limits are set
CPU_LIMIT=$(kubectl get pods -l app=backend -n "${NAMESPACE}" -o jsonpath='{.items[0].spec.containers[0].resources.limits.cpu}' 2>/dev/null)
if [ -n "$CPU_LIMIT" ]; then
  pass "Pod has CPU limit set: ${CPU_LIMIT}"
else
  fail "Pod has no CPU limit"
fi

MEM_LIMIT=$(kubectl get pods -l app=backend -n "${NAMESPACE}" -o jsonpath='{.items[0].spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [ -n "$MEM_LIMIT" ]; then
  pass "Pod has memory limit set: ${MEM_LIMIT}"
else
  fail "Pod has no memory limit"
fi

###############################################################################
# Section 7: In-Cluster API Endpoint Tests
###############################################################################
section "7. In-Cluster API Tests (via port-forward)"

# Start port-forward
kubectl port-forward -n "${NAMESPACE}" svc/backend ${CLUSTER_PORT}:3000 >/dev/null 2>&1 &
PORT_FWD_PID=$!
sleep 3

# Verify port-forward by checking if the port is listening
if curl -s --max-time 2 "http://localhost:${CLUSTER_PORT}/status" >/dev/null 2>&1; then
  pass "Port-forward established on port ${CLUSTER_PORT}"
else
  fail "Port-forward failed to start"
fi

# --- Cluster: GET /status ---
echo ""
echo -e "  ${YELLOW}Cluster: GET /status${NC}"
C_STATUS=$(curl -s -w "\n%{http_code}" "http://localhost:${CLUSTER_PORT}/status" 2>/dev/null)
C_STATUS_CODE=$(echo "$C_STATUS" | tail -1)
C_STATUS_BODY=$(echo "$C_STATUS" | sed '$d')

if [ "$C_STATUS_CODE" = "200" ]; then
  pass "Cluster GET /status returns HTTP 200"
else
  fail "Cluster GET /status returned HTTP ${C_STATUS_CODE}"
fi

if echo "$C_STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['service']=='raftt-lab-backend'" 2>/dev/null; then
  pass "Cluster GET /status → service = 'raftt-lab-backend'"
else
  fail "Cluster GET /status → service field mismatch"
fi

if echo "$C_STATUS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['status']=='healthy'" 2>/dev/null; then
  pass "Cluster GET /status → status = 'healthy'"
else
  fail "Cluster GET /status → status field mismatch"
fi

# --- Cluster: GET /info ---
echo ""
echo -e "  ${YELLOW}Cluster: GET /info${NC}"
C_INFO=$(curl -s "http://localhost:${CLUSTER_PORT}/info" 2>/dev/null)

if echo "$C_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['nodeEnv']=='production'" 2>/dev/null; then
  pass "Cluster GET /info → nodeEnv = 'production' (default, pre-Raftt)"
else
  fail "Cluster GET /info → nodeEnv mismatch"
fi

if echo "$C_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['logLevel']=='info'" 2>/dev/null; then
  pass "Cluster GET /info → logLevel = 'info' (default, pre-Raftt)"
else
  fail "Cluster GET /info → logLevel mismatch"
fi

# --- Cluster: POST /calculate ---
echo ""
echo -e "  ${YELLOW}Cluster: POST /calculate${NC}"

# Valid operations
C_ADD=$(curl -s -X POST "http://localhost:${CLUSTER_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":100,"b":25,"operation":"add"}')
if echo "$C_ADD" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==125" 2>/dev/null; then
  pass "Cluster POST /calculate → 100 + 25 = 125"
else
  fail "Cluster POST /calculate → addition failed"
fi

C_MUL=$(curl -s -X POST "http://localhost:${CLUSTER_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":6,"b":7,"operation":"multiply"}')
if echo "$C_MUL" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['result']==42" 2>/dev/null; then
  pass "Cluster POST /calculate → 6 × 7 = 42"
else
  fail "Cluster POST /calculate → multiplication failed"
fi

# The bug - in cluster
C_BUG=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${CLUSTER_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":10,"b":0,"operation":"divide"}')
C_BUG_CODE=$(echo "$C_BUG" | tail -1)
if [ "$C_BUG_CODE" = "500" ]; then
  pass "Cluster divide-by-zero returns HTTP 500 (bug confirmed in cluster)"
else
  fail "Cluster divide-by-zero returned HTTP ${C_BUG_CODE} (expected 500)"
fi

# Validation - in cluster
C_VAL=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:${CLUSTER_PORT}/calculate" \
  -H 'Content-Type: application/json' -d '{"a":1}')
C_VAL_CODE=$(echo "$C_VAL" | tail -1)
if [ "$C_VAL_CODE" = "400" ]; then
  pass "Cluster validation → missing fields returns HTTP 400"
else
  fail "Cluster validation → returned HTTP ${C_VAL_CODE} (expected 400)"
fi

# Stop port-forward
kill "$PORT_FWD_PID" 2>/dev/null || true
wait "$PORT_FWD_PID" 2>/dev/null || true
PORT_FWD_PID=""

###############################################################################
# Section 8: In-Cluster Service Discovery Test
###############################################################################
section "8. In-Cluster Service Discovery"

# Use kubectl exec on the backend pod to test service DNS resolution inside the cluster
DNS_RESULT=$(kubectl exec -n "${NAMESPACE}" deploy/backend -- \
  wget -qO- --timeout=10 "http://backend.${NAMESPACE}.svc.cluster.local:3000/status" 2>/dev/null || echo "")

if echo "$DNS_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['service']=='raftt-lab-backend'" 2>/dev/null; then
  pass "In-cluster DNS resolves backend.${NAMESPACE}.svc.cluster.local"
else
  # Fallback: try with the short DNS name
  DNS_SHORT=$(kubectl exec -n "${NAMESPACE}" deploy/backend -- \
    wget -qO- --timeout=10 "http://backend:3000/status" 2>/dev/null || echo "")
  if echo "$DNS_SHORT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['service']=='raftt-lab-backend'" 2>/dev/null; then
    pass "In-cluster DNS resolves backend:3000 (short name)"
  else
    fail "In-cluster DNS resolution failed"
  fi
fi

###############################################################################
# Section 9: README & Documentation Checks
###############################################################################
section "9. README & Documentation Coverage"

README="${SCRIPT_DIR}/README.md"

# Check that all lab modules are documented
for keyword in "Module 1" "Module 2" "Module 3" "Module 4"; do
  if grep -q "$keyword" "$README"; then
    pass "README contains ${keyword}"
  else
    fail "README missing ${keyword}"
  fi
done

# Check for key sections
for keyword in "Prerequisites" "Installation" "Troubleshooting" "Clean Up" "Architecture Overview"; do
  if grep -q "$keyword" "$README"; then
    pass "README contains section: ${keyword}"
  else
    fail "README missing section: ${keyword}"
  fi
done

# Check for Mermaid diagrams
MERMAID_COUNT=$(grep -c '```mermaid' "$README" || true)
if [ "$MERMAID_COUNT" -ge 2 ]; then
  pass "README has ${MERMAID_COUNT} Mermaid diagrams"
else
  fail "README has only ${MERMAID_COUNT} Mermaid diagram(s) (expected ≥ 2)"
fi

# Check for key technical details mentioned in the lab prompt
for keyword in "nodemon" "node_modules" "9229" "--inspect" "--legacy-watch" "raftt.yaml" "raftt up" "raftt dev"; do
  if grep -qF -- "$keyword" "$README"; then
    pass "README mentions: ${keyword}"
  else
    fail "README does not mention: ${keyword}"
  fi
done

# Check mkdocs registration
MKDOCS="${SCRIPT_DIR}/../../mkdocs.yml"
if grep -q "38 Raftt" "$MKDOCS" 2>/dev/null; then
  pass "Lab registered in mkdocs.yml"
else
  fail "Lab NOT registered in mkdocs.yml"
fi

# Check index.md registration
INDEX="${SCRIPT_DIR}/../index.md"
if grep -q "38-Raftt" "$INDEX" 2>/dev/null; then
  pass "Lab registered in Labs/index.md"
else
  fail "Lab NOT registered in Labs/index.md"
fi

###############################################################################
# Section 10: Raftt Configuration Completeness
###############################################################################
section "10. Raftt Config Completeness"

# Verify the raftt.yaml maps all required fields from the lab prompt
RAFTT="${SCRIPT_DIR}/raftt.yaml"

if python3 -c "
import yaml
with open('${RAFTT}') as f:
    cfg = yaml.safe_load(f)
assert cfg['version'] == '1'
assert cfg['name'] == 'raftt-lab'
assert cfg['context'] == 'kind-raftt-lab'
assert cfg['namespace'] == 'raftt-lab'
svc = cfg['services']['backend']
assert svc['deployment'] == 'backend'
assert any(s['local'] == './app' and s['remote'] == '/usr/src/app' for s in svc['sync'])
assert any('node_modules' in s.get('exclude', []) for s in svc['sync'])
assert any(p['local'] == 3000 and p['remote'] == 3000 for p in svc['ports'])
assert any(p['local'] == 9229 and p['remote'] == 9229 for p in svc['ports'])
assert svc['env']['NODE_ENV'] == 'development'
assert svc['env']['LOG_LEVEL'] == 'debug'
print('OK')
" 2>/dev/null; then
  pass "raftt.yaml is fully valid and complete"
else
  fail "raftt.yaml validation failed"
fi

###############################################################################
# Summary
###############################################################################
section "Test Summary"

TOTAL=$((PASSED + FAILED + SKIPPED))
echo ""
echo -e "  ${GREEN}Passed${NC}:  ${PASSED}"
echo -e "  ${RED}Failed${NC}:  ${FAILED}"
echo -e "  ${YELLOW}Skipped${NC}: ${SKIPPED}"
echo -e "  Total:   ${TOTAL}"
echo ""
if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}Some tests FAILED!${NC}"
  exit 1
else
  echo -e "${GREEN}All tests PASSED!${NC}"
  exit 0
fi
