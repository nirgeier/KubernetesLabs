#!/bin/bash
# =============================================================================
# Package all Helm charts for offline use
# Also downloads the Harbor Helm chart
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/common.sh"
load_env

print_header "Package Helm Charts for Offline Use"

check_prerequisites helm

ensure_dirs "$CHARTS_DIR" "$HARBOR_CHARTS_DIR"

# Package local EFK Helm charts
print_step "Packaging local EFK Helm charts..."
for chart in "${HELM_CHARTS[@]}"; do
  CHART_PATH="${PROJECT_ROOT}/helm/${chart}"
  if [[ -d "$CHART_PATH" ]]; then
    print_info "Packaging: $chart"
    helm package "$CHART_PATH" --destination "$CHARTS_DIR"
    print_success "Packaged: $chart"
  else
    print_warning "Chart directory not found: $CHART_PATH"
  fi
done

echo ""

# Download Harbor Helm chart
print_step "Downloading Harbor Helm chart (v${HARBOR_CHART_VERSION})..."

helm repo add harbor "${HARBOR_CHART_REPO}" 2>/dev/null || true
helm repo update harbor

helm pull harbor/harbor \
  --version "${HARBOR_CHART_VERSION}" \
  --destination "$HARBOR_CHARTS_DIR"

print_success "Harbor chart downloaded"

echo ""

# Download ingress-nginx Helm chart
print_step "Downloading ingress-nginx Helm chart (v${INGRESS_CHART_VERSION})..."

ensure_dirs "$INGRESS_CHARTS_DIR"

helm repo add ingress-nginx "${INGRESS_CHART_REPO}" 2>/dev/null || true
helm repo update ingress-nginx

helm pull ingress-nginx/ingress-nginx \
  --version "${INGRESS_CHART_VERSION}" \
  --destination "$INGRESS_CHARTS_DIR"

print_success "Ingress-nginx chart downloaded"

echo ""
print_header "Packaged Charts Summary"
print_info "EFK charts:"
ls -lh "$CHARTS_DIR"/*.tgz 2>/dev/null || echo "  (none)"
echo ""
print_info "Harbor chart:"
ls -lh "$HARBOR_CHARTS_DIR"/*.tgz 2>/dev/null || echo "  (none)"
echo ""
print_info "Ingress chart:"
ls -lh "$INGRESS_CHARTS_DIR"/*.tgz 2>/dev/null || echo "  (none)"
