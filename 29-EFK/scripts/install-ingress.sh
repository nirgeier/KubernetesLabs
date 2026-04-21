#!/bin/bash
# =============================================================================
# Install nginx ingress controller from local artifacts (offline)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

print_header "Install Nginx Ingress Controller"

check_prerequisites kubectl helm docker

# Step 1: Load ingress images from tar (offline)
print_step "Step 1: Loading ingress controller images..."
INGRESS_TAR="${INGRESS_CHARTS_DIR}/ingress-images.tar"

if [[ -f "$INGRESS_TAR" ]]; then
  docker load -i "$INGRESS_TAR"
  print_success "Ingress images loaded from tar"
else
  print_warning "No local tar found at $INGRESS_TAR"
  print_info "Assuming images are already available (online mode)"
fi

echo ""

# Step 2: Determine chart source
print_step "Step 2: Preparing Helm chart..."

INGRESS_CHART_SOURCE=""
LOCAL_CHART=$(find "${INGRESS_CHARTS_DIR}" -name "ingress-nginx-*.tgz" 2>/dev/null | head -1)

if [[ -n "$LOCAL_CHART" && -f "$LOCAL_CHART" ]]; then
  print_info "Using local chart: $(basename "$LOCAL_CHART")"
  INGRESS_CHART_SOURCE="$LOCAL_CHART"
else
  print_info "Using chart from repository..."
  helm repo add ingress-nginx "${INGRESS_CHART_REPO}" 2>/dev/null || true
  helm repo update ingress-nginx
  INGRESS_CHART_SOURCE="ingress-nginx/ingress-nginx"
fi

echo ""

# Step 3: Install ingress controller
print_step "Step 3: Installing ingress controller..."

# Airgap flags: clear image digests so the chart uses plain tag references
# (matching what docker load produces), and force IfNotPresent to avoid any
# registry pull attempts.
helm upgrade --install ingress-nginx "$INGRESS_CHART_SOURCE" \
  --namespace "${INGRESS_NAMESPACE}" \
  --create-namespace \
  --set controller.watchIngressWithoutClass=true \
  --set controller.image.pullPolicy=IfNotPresent \
  --set controller.image.digest="" \
  --set controller.admissionWebhooks.patch.image.pullPolicy=IfNotPresent \
  --set controller.admissionWebhooks.patch.image.digest="" \
  --wait \
  --timeout 5m

print_success "Ingress controller installed"

echo ""

# Step 4: Wait for external IP
print_step "Step 4: Waiting for ingress controller external IP..."

for i in $(seq 1 30); do
  EXTERNAL_IP=$(kubectl get svc -n "${INGRESS_NAMESPACE}" ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [[ -n "$EXTERNAL_IP" ]]; then
    break
  fi
  # Also check hostname (some environments use hostname instead of IP)
  EXTERNAL_IP=$(kubectl get svc -n "${INGRESS_NAMESPACE}" ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [[ -n "$EXTERNAL_IP" ]]; then
    break
  fi
  echo "  Waiting for external IP... (attempt $i/30)"
  sleep 5
done

if [[ -z "$EXTERNAL_IP" ]]; then
  # Fall back to node IP
  EXTERNAL_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
fi

echo ""
print_header "Ingress Controller Ready"
echo ""
print_info "External IP: ${EXTERNAL_IP:-unknown}"
print_info "Namespace: ${INGRESS_NAMESPACE}"
echo ""
print_info "DNS Configuration - add to /etc/hosts:"
if [[ -n "$EXTERNAL_IP" ]]; then
  echo "  ${EXTERNAL_IP} ${HARBOR_INGRESS_HOST} ${KIBANA_INGRESS_HOST}"
else
  echo "  <external-ip> ${HARBOR_INGRESS_HOST} ${KIBANA_INGRESS_HOST}"
fi
echo ""
print_info "Next steps:"
echo "  1. Configure /etc/hosts as shown above"
echo "  2. Run: ./scripts/install-harbor.sh"
