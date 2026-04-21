#!/bin/bash
# =============================================================================
# Common functions and variables for Harbor + ArgoCD Airgap Tasks
# =============================================================================

# ── Configuration ──
export HARBOR_URL="harbor.local"
export HARBOR_USER="admin"
export HARBOR_PASS="Harbor12345"
export ARGOCD_CHART_VERSION="7.7.12"
export REPO_BASE="/tmp/gitops-lab"
export BARE_REPO="${REPO_BASE}/helm-apps.git"
export WORK_DIR="${REPO_BASE}/helm-apps-workspace"
export CHART_NAME="my-web-app"

# ── Color definitions ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; exit 1; }
header()  { echo -e "\n${CYAN}=== $* ===${NC}"; }
banner()  { echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"; \
            echo -e "${BOLD}${CYAN}║  $*${NC}"; \
            echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"; }

wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    local start=$(date +%s)

    info "Waiting for all pods in ${namespace} to be Ready (timeout: ${timeout}s)..."
    while true; do
        local not_ready=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | \
            grep -v "Running\|Completed" | wc -l | tr -d ' ')

        if [ "${not_ready}" = "0" ] && [ "$(kubectl get pods -n ${namespace} --no-headers 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
            success "All pods in ${namespace} are Ready"
            return 0
        fi

        local elapsed=$(( $(date +%s) - start ))
        if [ ${elapsed} -ge ${timeout} ]; then
            warn "Timeout waiting for pods in ${namespace}"
            kubectl get pods -n "${namespace}"
            return 1
        fi

        sleep 5
    done
}

get_node_ip() {
    kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
}
