#!/bin/bash
# =============================================================================
# Master orchestration script for EFK offline deployment with Harbor
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/common.sh"
load_env

usage() {
  echo "Usage: $0 <command>"
  echo ""
  echo "Commands:"
  echo "  prepare       Download all artifacts for offline use (run with internet)"
  echo "  install       Full offline installation (Ingress + Harbor + EFK)"
  echo "  ingress       Install nginx ingress controller"
  echo "  harbor        Install Harbor registry only"
  echo "  push          Load images, retag, and push to Harbor"
  echo "  efk           Install EFK stack from Harbor"
  echo "  verify        Verify the deployment is working"
  echo "  cleanup       Remove EFK stack (keeps Harbor)"
  echo "  cleanup-all   Remove everything including Harbor"
  echo "  status        Show deployment status"
  echo ""
  echo "Typical workflow:"
  echo "  1. $0 prepare     # On internet-connected machine"
  echo "  2. # Transfer artifacts/ to air-gapped environment"
  echo "  3. $0 install     # On air-gapped machine"
  echo ""
  echo "Configuration: .env"
  exit 1
}

# ---- Commands ---------------------------------------------------------------

cmd_prepare() {
  print_header "Preparing Offline Artifacts"
  bash "${PROJECT_ROOT}/artifacts/download-all.sh"
}

cmd_ingress() {
  print_header "Installing Ingress Controller"
  bash "${PROJECT_ROOT}/scripts/install-ingress.sh"
}

cmd_harbor() {
  print_header "Installing Harbor"
  bash "${PROJECT_ROOT}/scripts/install-harbor.sh"
}

cmd_push() {
  print_header "Pushing Content to Harbor"

  print_step "Pushing container images..."
  bash "${PROJECT_ROOT}/scripts/retag-and-push-images.sh"

  echo ""

  print_step "Pushing Helm charts..."
  bash "${PROJECT_ROOT}/scripts/upload-charts-to-harbor.sh"
}

cmd_efk() {
  print_header "Installing EFK from Harbor"
  bash "${PROJECT_ROOT}/scripts/offline-install.sh"
}

cmd_install() {
  print_header "Full Offline Installation"
  echo ""
  print_info "This will: Ingress -> Harbor -> Push images/charts -> Install EFK"
  echo ""

  # Step 0: Install Ingress Controller
  cmd_ingress
  echo ""

  # Step 1: Install Harbor
  cmd_harbor
  echo ""

  # Step 2: Push content to Harbor
  cmd_push
  echo ""

  # Step 3: Install EFK
  cmd_efk
  echo ""

  # Step 4: Verify
  cmd_verify
}

cmd_verify() {
  print_header "Verifying Deployment"
  bash "${PROJECT_ROOT}/scripts/verify-deployment.sh"
}

cmd_status() {
  print_header "Deployment Status"

  echo ""
  print_step "Harbor namespace:"
  kubectl get pods -n "${HARBOR_NAMESPACE}" 2>/dev/null || echo "  Harbor not installed"

  echo ""
  print_step "EFK namespace:"
  kubectl get pods -n "${EFK_NAMESPACE}" 2>/dev/null || echo "  EFK not installed"

  echo ""
  print_step "Helm releases:"
  helm list -n "${HARBOR_NAMESPACE}" 2>/dev/null || true
  helm list -n "${EFK_NAMESPACE}" 2>/dev/null || true

  echo ""
  print_step "Ingress:"
  kubectl get ingress -n "${EFK_NAMESPACE}" 2>/dev/null || true
}

cmd_cleanup() {
  print_warning "Cleaning up EFK stack..."

  helm uninstall log-processor -n "${EFK_NAMESPACE}" 2>/dev/null || true
  helm uninstall log-generator -n "${EFK_NAMESPACE}" 2>/dev/null || true
  helm uninstall filebeat -n "${EFK_NAMESPACE}" 2>/dev/null || true
  helm uninstall kibana -n "${EFK_NAMESPACE}" 2>/dev/null || true
  helm uninstall elasticsearch -n "${EFK_NAMESPACE}" 2>/dev/null || true

  kubectl delete jobs -n "${EFK_NAMESPACE}" -l app=log-processor 2>/dev/null || true
  kubectl delete jobs -n "${EFK_NAMESPACE}" -l app=kibana-dashboard-importer 2>/dev/null || true
  kubectl delete namespace "${EFK_NAMESPACE}" 2>/dev/null || true

  print_success "EFK cleanup complete"
}

cmd_cleanup_all() {
  cmd_cleanup

  print_warning "Cleaning up Harbor..."
  helm uninstall harbor -n "${HARBOR_NAMESPACE}" 2>/dev/null || true
  kubectl delete namespace "${HARBOR_NAMESPACE}" 2>/dev/null || true

  print_warning "Cleaning up Ingress Controller..."
  helm uninstall ingress-nginx -n "${INGRESS_NAMESPACE}" 2>/dev/null || true
  kubectl delete namespace "${INGRESS_NAMESPACE}" 2>/dev/null || true

  print_success "Full cleanup complete"
}

# ---- Main -------------------------------------------------------------------

case "${1:-}" in
prepare) cmd_prepare ;;
install) cmd_install ;;
ingress) cmd_ingress ;;
harbor) cmd_harbor ;;
push) cmd_push ;;
efk) cmd_efk ;;
verify) cmd_verify ;;
cleanup) cmd_cleanup ;;
cleanup-all) cmd_cleanup_all ;;
status) cmd_status ;;
*) usage ;;
esac
