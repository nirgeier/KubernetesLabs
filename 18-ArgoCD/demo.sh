#!/bin/bash
# =============================================================================
# ArgoCD Full Demo Script
# Installs ArgoCD via Helm, configures Ingress, deploys Guestbook + App of Apps
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/nirgeier/KubernetesLabs"
ARGOCD_NS="argocd"
ARGOCD_HOST="argocd.local"

# ---- Colors ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error() {
  echo -e "${RED}[ERROR]${NC}   $*" >&2
  exit 1
}
header() { echo -e "\n${CYAN}=== $* ===${NC}"; }

# =============================================================================
# Helpers
# =============================================================================
check_prerequisites() {
  header "Checking Prerequisites"
  command -v kubectl >/dev/null 2>&1 || error "kubectl not found. Install it first."
  command -v helm >/dev/null 2>&1 || error "helm not found. Install it first."
  kubectl cluster-info &>/dev/null || error "Cannot reach Kubernetes cluster."
  success "All prerequisites satisfied."
}

wait_for_pods() {
  local ns="$1"
  local label="$2"
  local timeout="${3:-180}"
  info "Waiting for pods [${label}] in namespace [${ns}] (timeout: ${timeout}s) ..."
  kubectl wait pod \
    --for=condition=Ready \
    --selector="${label}" \
    --namespace="${ns}" \
    --timeout="${timeout}s"
}

get_admin_password() {
  kubectl -n "${ARGOCD_NS}" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d
}

# =============================================================================
# 01 - Install ArgoCD via Helm
# =============================================================================
install_argocd() {
  header "01 - Installing ArgoCD"

  kubectl create namespace "${ARGOCD_NS}" --dry-run=client -o yaml | kubectl apply -f -

  helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
  helm repo update argo

  # Install (or upgrade) ArgoCD
  # --set server.insecure=true  → disable HTTPS on argocd-server (Ingress handles TLS termination)
  helm upgrade --install argocd argo/argo-cd \
    --namespace "${ARGOCD_NS}" \
    --set server.insecure=true \
    --set redis-ha.enabled=false \
    --set controller.replicas=1 \
    --set server.replicas=1 \
    --set repoServer.replicas=1 \
    --set applicationSet.replicas=1 \
    --atomic \
    --timeout 5m \
    --wait

  success "ArgoCD installed via Helm."
}

# =============================================================================
# 02 - Configure Nginx Ingress for ArgoCD
# =============================================================================
configure_ingress() {
  header "02 - Configuring Ingress for ArgoCD"

  kubectl apply -f "${SCRIPT_DIR}/manifests/argocd-ingress.yaml"

  # Add argocd.local to /etc/hosts if missing (requires sudo)
  if ! grep -q "${ARGOCD_HOST}" /etc/hosts 2>/dev/null; then
    # Try to detect the ingress IP
    INGRESS_IP=$(kubectl get nodes \
      -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "127.0.0.1")
    warn "Add the following to /etc/hosts to reach the ArgoCD UI:"
    echo "  ${INGRESS_IP}  ${ARGOCD_HOST}"
    warn "(Run: echo '${INGRESS_IP}  ${ARGOCD_HOST}' | sudo tee -a /etc/hosts)"
  else
    success "${ARGOCD_HOST} already in /etc/hosts."
  fi

  success "Ingress applied."
}

# =============================================================================
# 03 - Print Admin Credentials
# =============================================================================
print_credentials() {
  header "03 - Admin Credentials"
  local password
  password=$(get_admin_password)
  echo ""
  echo "  ArgoCD URL : http://${ARGOCD_HOST}"
  echo "  Username   : admin"
  echo "  Password   : ${password}"
  echo ""
  echo "  Port-forward fallback:"
  echo "    kubectl port-forward svc/argocd-server -n ${ARGOCD_NS} 8080:80"
  echo "    open http://localhost:8080"
  echo ""
}

# =============================================================================
# 04 - Deploy Guestbook Application
# =============================================================================
deploy_guestbook() {
  header "04 - Deploying Guestbook Demo App"

  kubectl apply -f "${SCRIPT_DIR}/apps/guestbook.yaml"

  info "Waiting for Guestbook to sync (up to 3 minutes)..."
  for i in $(seq 1 36); do
    STATUS=$(kubectl get application guestbook -n "${ARGOCD_NS}" \
      -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    SYNC=$(kubectl get application guestbook -n "${ARGOCD_NS}" \
      -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")

    if [[ "${STATUS}" == "Healthy" && "${SYNC}" == "Synced" ]]; then
      success "Guestbook: Health=${STATUS}, Sync=${SYNC}"
      return 0
    fi
    echo -n "."
    sleep 5
  done
  echo ""
  warn "Guestbook did not reach Healthy+Synced within timeout. Check ArgoCD UI."
}

# =============================================================================
# 05 - Deploy App of Apps (manages EFK stack)
# =============================================================================
deploy_app_of_apps() {
  header "05 - Deploying App of Apps"

  kubectl apply -f "${SCRIPT_DIR}/apps/app-of-apps.yaml"

  info "App of Apps applied. Child apps will be synced by ArgoCD automatically."
  info "Monitor progress at: http://${ARGOCD_HOST}"
  success "App of Apps deployed."
}

# =============================================================================
# 06 - Status Summary
# =============================================================================
status_summary() {
  header "Status Summary"
  kubectl get applications -n "${ARGOCD_NS}" 2>/dev/null || true
  echo ""
  kubectl get ingress -n "${ARGOCD_NS}" 2>/dev/null || true
}

# =============================================================================
# Cleanup
# =============================================================================
cleanup() {
  header "Cleanup - Removing ArgoCD and all applications"

  # Delete all ArgoCD Applications first (cascade delete)
  kubectl delete applications --all -n "${ARGOCD_NS}" --ignore-not-found 2>/dev/null || true

  # Delete namespaces managed by App of Apps
  kubectl delete namespace efk guestbook --ignore-not-found 2>/dev/null || true

  # Uninstall ArgoCD Helm release
  helm uninstall argocd --namespace "${ARGOCD_NS}" 2>/dev/null || true

  # Remove namespace
  kubectl delete namespace "${ARGOCD_NS}" --ignore-not-found

  success "Cleanup complete."
}

# =============================================================================
# Main
# =============================================================================
usage() {
  echo ""
  echo "Usage: $0 [deploy|cleanup|status|credentials]"
  echo ""
  echo "  deploy       - Full installation: ArgoCD + Ingress + Guestbook + App of Apps"
  echo "  cleanup      - Remove all ArgoCD resources and managed applications"
  echo "  status       - Show current state of all applications"
  echo "  credentials  - Print admin username and password"
  echo ""
}

case "${1:-deploy}" in
deploy)
  check_prerequisites
  install_argocd
  configure_ingress
  print_credentials
  deploy_guestbook
  deploy_app_of_apps
  status_summary
  success "Demo deployment complete!"
  ;;
cleanup)
  cleanup
  ;;
status)
  status_summary
  ;;
credentials)
  print_credentials
  ;;
*)
  usage
  exit 1
  ;;
esac
