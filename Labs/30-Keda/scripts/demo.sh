#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# demo.sh — KEDA interactive demo script
#
# Runs all KEDA lab examples in order with clear explanations.
#
# Usage:
#   ./scripts/demo.sh              # Run full interactive demo
#   ./scripts/demo.sh deploy       # Apply all manifests only
#   ./scripts/demo.sh redis-demo   # Run the Redis scale-to-zero demo
#   ./scripts/demo.sh job-demo     # Run the ScaledJob batch demo
#   ./scripts/demo.sh cleanup      # Remove all demo resources
#   ./scripts/demo.sh status       # Show status of all KEDA resources
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="keda-demo"
MANIFESTS_DIR="$(cd "$(dirname "$0")/../manifests" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

_info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
_step() {
  echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${NC}"
  echo -e "${BOLD}${CYAN}  $*${NC}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${NC}"
}
_pause() {
  echo -e "${YELLOW}  Press ENTER to continue...${NC}"
  read -r
}

# ── Preflight ─────────────────────────────────────────────────────────────
preflight() {
  if ! kubectl get namespace keda &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC}  KEDA is not installed. Run './scripts/install.sh' first."
    exit 1
  fi

  if ! kubectl get pods -n keda -l app=keda-operator --no-headers 2>/dev/null | grep -q Running; then
    echo -e "${YELLOW}[WARN]${NC}  KEDA operator is not running. Run './scripts/install.sh' first."
    exit 1
  fi
}

# ── Deploy all base resources ──────────────────────────────────────────────
deploy() {
  _step "Deploying base resources..."

  _info "Creating namespace '${NAMESPACE}'..."
  kubectl apply -f "${MANIFESTS_DIR}/00-namespace.yaml"

  _info "Deploying nginx-demo workload..."
  kubectl apply -f "${MANIFESTS_DIR}/01-demo-deployment.yaml"
  kubectl rollout status deployment/nginx-demo -n "${NAMESPACE}"

  _info "Applying CPU ScaledObject..."
  kubectl apply -f "${MANIFESTS_DIR}/02-scaled-object-cpu.yaml"

  _info "Applying Cron ScaledObject..."
  kubectl apply -f "${MANIFESTS_DIR}/03-scaled-object-cron.yaml"

  _info "Deploying Redis stack..."
  kubectl apply -f "${MANIFESTS_DIR}/04-redis-stack.yaml"
  kubectl rollout status deployment/redis -n "${NAMESPACE}"

  _info "Applying Redis ScaledObject (scale-to-zero)..."
  kubectl apply -f "${MANIFESTS_DIR}/05-scaled-object-redis.yaml"

  _info "Applying ScaledJob..."
  kubectl apply -f "${MANIFESTS_DIR}/09-scaled-job.yaml"

  echo ""
  _info "All resources deployed successfully."
  status
}

# ── Status ─────────────────────────────────────────────────────────────────
status() {
  _step "KEDA Resource Status"

  echo ""
  echo -e "${BOLD}ScaledObjects:${NC}"
  kubectl get scaledobjects -n "${NAMESPACE}" 2>/dev/null || echo "  (none)"

  echo ""
  echo -e "${BOLD}ScaledJobs:${NC}"
  kubectl get scaledjobs -n "${NAMESPACE}" 2>/dev/null || echo "  (none)"

  echo ""
  echo -e "${BOLD}HPA (KEDA-managed):${NC}"
  kubectl get hpa -n "${NAMESPACE}" 2>/dev/null || echo "  (none)"

  echo ""
  echo -e "${BOLD}Pods:${NC}"
  kubectl get pods -n "${NAMESPACE}" 2>/dev/null || echo "  (none)"

  echo ""
  echo -e "${BOLD}Jobs:${NC}"
  kubectl get jobs -n "${NAMESPACE}" 2>/dev/null || echo "  (none)"
}

# ── Redis scale-to-zero demo ───────────────────────────────────────────────
redis_demo() {
  _step "Redis Scale-to-Zero Demo"

  _info "Verifying redis-worker starts at 0 replicas..."
  REPLICAS=$(kubectl get deployment redis-worker -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
  echo "  redis-worker replicas: ${REPLICAS}"

  echo ""
  _info "Checking current queue length (should be 0)..."
  QUEUE_LEN=$(kubectl exec deployment/redis -n "${NAMESPACE}" -- redis-cli LLEN jobs:queue 2>/dev/null || echo "error")
  echo "  jobs:queue length: ${QUEUE_LEN}"

  echo ""
  _info "Pushing 50 jobs to jobs:queue..."
  kubectl exec deployment/redis -n "${NAMESPACE}" -- \
    redis-cli RPUSH jobs:queue \
    job-01 job-02 job-03 job-04 job-05 \
    job-06 job-07 job-08 job-09 job-10 \
    job-11 job-12 job-13 job-14 job-15 \
    job-16 job-17 job-18 job-19 job-20 \
    job-21 job-22 job-23 job-24 job-25 \
    job-26 job-27 job-28 job-29 job-30 \
    job-31 job-32 job-33 job-34 job-35 \
    job-36 job-37 job-38 job-39 job-40 \
    job-41 job-42 job-43 job-44 job-45 \
    job-46 job-47 job-48 job-49 job-50 >/dev/null

  _info "Queue now has $(kubectl exec deployment/redis -n "${NAMESPACE}" -- redis-cli LLEN jobs:queue) items."

  echo ""
  _info "Watching pods scale up (KEDA polls every 5s)..."
  _info "Expected: 50 / 5 = 10 replicas"
  echo "  (Press Ctrl+C to stop watching — jobs will continue)"
  echo ""

  for i in $(seq 1 24); do
    PODS=$(kubectl get pods -n "${NAMESPACE}" -l app=redis-worker --no-headers 2>/dev/null | wc -l | tr -d ' ')
    QUEUE=$(kubectl exec deployment/redis -n "${NAMESPACE}" -- redis-cli LLEN jobs:queue 2>/dev/null || echo "?")
    printf "  [%02d/24] Worker pods: %-4s  Queue length: %s\n" "$i" "$PODS" "$QUEUE"
    [ "$QUEUE" = "0" ] && break
    sleep 5
  done

  echo ""
  _info "Queue drained. Waiting for scale-to-zero (cooldown: 30s)..."
  sleep 35

  PODS=$(kubectl get pods -n "${NAMESPACE}" -l app=redis-worker --no-headers 2>/dev/null | wc -l | tr -d ' ')
  echo "  redis-worker pods after cooldown: ${PODS}"
  _info "Scale-to-zero demo complete."
}

# ── ScaledJob batch demo ───────────────────────────────────────────────────
job_demo() {
  _step "ScaledJob Batch Processing Demo"

  _info "Pushing 25 tasks to batch:queue..."
  kubectl exec deployment/redis -n "${NAMESPACE}" -- \
    redis-cli RPUSH batch:queue \
    task-01 task-02 task-03 task-04 task-05 \
    task-06 task-07 task-08 task-09 task-10 \
    task-11 task-12 task-13 task-14 task-15 \
    task-16 task-17 task-18 task-19 task-20 \
    task-21 task-22 task-23 task-24 task-25 >/dev/null

  _info "Queue has $(kubectl exec deployment/redis -n "${NAMESPACE}" -- redis-cli LLEN batch:queue) tasks."
  _info "Expected: 25 / 5 = 5 Jobs will be created."

  echo ""
  _info "Watching Jobs (KEDA polls every 10s)..."
  for i in $(seq 1 18); do
    JOBS=$(kubectl get jobs -n "${NAMESPACE}" -l app=batch-processor \
      --no-headers 2>/dev/null | wc -l | tr -d ' ')
    COMPLETE=$(kubectl get jobs -n "${NAMESPACE}" -l app=batch-processor \
      --no-headers 2>/dev/null | grep -c "1/1" || true)
    QUEUE=$(kubectl exec deployment/redis -n "${NAMESPACE}" -- redis-cli LLEN batch:queue 2>/dev/null || echo "?")
    printf "  [%02d/18] Jobs: %-3s  Completed: %-3s  Queue: %s\n" "$i" "$JOBS" "$COMPLETE" "$QUEUE"
    [ "$QUEUE" = "0" ] && sleep 10 && break
    sleep 10
  done

  echo ""
  _info "Final Job list:"
  kubectl get jobs -n "${NAMESPACE}" 2>/dev/null
  _info "ScaledJob demo complete."
}

# ── Full demo ─────────────────────────────────────────────────────────────
full_demo() {
  preflight
  _step "KEDA Lab 30 — Full Demo"
  echo ""
  echo "This demo will:"
  echo "  1. Deploy base workloads (nginx-demo, Redis)"
  echo "  2. Apply ScaledObjects (CPU, Cron, Redis)"
  echo "  3. Apply ScaledJob"
  echo "  4. Run the Redis scale-to-zero demo"
  echo "  5. Run the ScaledJob batch demo"
  echo ""
  _pause

  deploy
  echo ""
  _pause

  redis_demo
  echo ""
  _pause

  job_demo
  echo ""
  _info "=== Full demo complete ==="
  _info "Run './scripts/demo.sh status' to inspect all resources."
  _info "Run './scripts/demo.sh cleanup' when finished."
}

# ── Cleanup ───────────────────────────────────────────────────────────────
cleanup() {
  _step "Cleaning up demo resources..."

  _info "Removing ScaledObjects and ScaledJobs..."
  kubectl delete scaledobjects --all -n "${NAMESPACE}" --ignore-not-found
  kubectl delete scaledjobs --all -n "${NAMESPACE}" --ignore-not-found

  _info "Removing Jobs..."
  kubectl delete jobs --all -n "${NAMESPACE}" --ignore-not-found

  _info "Deleting namespace '${NAMESPACE}'..."
  kubectl delete namespace "${NAMESPACE}" --ignore-not-found

  _info "Cleanup complete."
}

# ── Entrypoint ────────────────────────────────────────────────────────────
case "${1:-full}" in
deploy)
  preflight
  deploy
  ;;
redis-demo)
  preflight
  redis_demo
  ;;
job-demo)
  preflight
  job_demo
  ;;
status) status ;;
cleanup) cleanup ;;
full | "") full_demo ;;
*)
  echo "Usage: $0 [deploy|redis-demo|job-demo|status|cleanup|full]"
  exit 1
  ;;
esac
