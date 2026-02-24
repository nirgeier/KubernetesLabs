#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# install.sh — Install KEDA via Helm
#
# Usage:
#   ./scripts/install.sh            # Install KEDA
#   ./scripts/install.sh uninstall  # Uninstall KEDA
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

KEDA_NAMESPACE="keda"
KEDA_RELEASE="keda"
KEDA_REPO="https://kedacore.github.io/charts"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

_info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
_warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Verify prerequisites ───────────────────────────────────────────────────
check_prerequisites() {
  _info "Checking prerequisites..."
  for cmd in kubectl helm; do
    if ! command -v "$cmd" &>/dev/null; then
      _error "'$cmd' is not installed or not in PATH."
      exit 1
    fi
  done

  if ! kubectl cluster-info &>/dev/null; then
    _error "kubectl is not connected to a cluster. Configure your kubeconfig first."
    exit 1
  fi

  _info "Prerequisites OK — kubectl and helm are available."
}

# ── Install KEDA ───────────────────────────────────────────────────────────
install_keda() {
  _info "Adding KEDA Helm repository..."
  helm repo add kedacore "$KEDA_REPO" 2>/dev/null || true
  helm repo update kedacore

  _info "Latest available KEDA chart:"
  helm search repo kedacore/keda --output table

  _info "Installing KEDA into namespace '${KEDA_NAMESPACE}'..."
  helm upgrade --install "$KEDA_RELEASE" kedacore/keda \
    --namespace "$KEDA_NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout 5m

  _info "KEDA installation complete. Verifying pods..."
  kubectl get pods -n "$KEDA_NAMESPACE"

  echo ""
  _info "Verifying KEDA CRDs..."
  kubectl get crd | grep keda.sh

  echo ""
  _info "Verifying Metrics API registration..."
  kubectl get apiservice | grep external.metrics ||
    _warn "Metrics API not yet registered — wait a few seconds and retry."

  echo ""
  _info "=== KEDA is ready ==="
  echo "  Namespace:    ${KEDA_NAMESPACE}"
  echo "  Next steps:   kubectl apply -f manifests/00-namespace.yaml"
  echo "                kubectl apply -f manifests/01-demo-deployment.yaml"
  echo "                Run: ./scripts/demo.sh"
}

# ── Uninstall KEDA ─────────────────────────────────────────────────────────
uninstall_keda() {
  _warn "Uninstalling KEDA..."

  helm uninstall "$KEDA_RELEASE" --namespace "$KEDA_NAMESPACE" 2>/dev/null || true
  kubectl delete namespace "$KEDA_NAMESPACE" --ignore-not-found

  _info "Removing KEDA CRDs..."
  for crd in \
    scaledobjects.keda.sh \
    scaledjobs.keda.sh \
    triggerauthentications.keda.sh \
    clustertriggerauthentications.keda.sh; do
    kubectl delete crd "$crd" --ignore-not-found
  done

  _info "KEDA has been removed."
}

# ── Main ───────────────────────────────────────────────────────────────────
check_prerequisites

case "${1:-install}" in
install) install_keda ;;
uninstall) uninstall_keda ;;
*)
  echo "Usage: $0 [install|uninstall]"
  exit 1
  ;;
esac
