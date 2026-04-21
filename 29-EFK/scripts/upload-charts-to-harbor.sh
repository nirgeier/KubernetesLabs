#!/bin/bash
# =============================================================================
# Upload packaged Helm charts to Harbor's OCI registry
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

print_header "Upload Helm Charts to Harbor"

check_prerequisites helm

# Step 1: Login to Harbor OCI registry
print_step "Step 1: Logging in to Harbor OCI registry..."
echo "${HARBOR_ADMIN_PASSWORD}" | helm registry login "${HARBOR_DOMAIN}" \
  --username "${HARBOR_ADMIN_USER}" \
  --password-stdin \
  --insecure 2>/dev/null

if [[ $? -eq 0 ]]; then
  print_success "Logged in to Harbor Helm registry"
else
  print_error "Failed to login to Harbor Helm registry"
  exit 1
fi

echo ""

# Step 2: Ensure project exists
print_step "Step 2: Ensuring chart project exists..."
curl -sk -X POST "${HARBOR_URL}/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}" \
  -d "{\"project_name\": \"${HARBOR_CHART_PROJECT}\", \"public\": true}" \
  2>/dev/null || true
print_success "Project '${HARBOR_CHART_PROJECT}' ready"

echo ""

# Step 3: Push EFK charts
print_step "Step 3: Pushing EFK Helm charts..."

FAILED=0
CHARTS_PUSHED=0

for CHART_TGZ in "${CHARTS_DIR}"/*.tgz; do
  if [[ -f "$CHART_TGZ" ]]; then
    CHART_NAME=$(basename "$CHART_TGZ")
    print_info "Pushing: ${CHART_NAME}"

    if helm push "$CHART_TGZ" "oci://${HARBOR_DOMAIN}/${HARBOR_CHART_PROJECT}" --insecure-skip-tls-verify 2>/dev/null; then
      print_success "Pushed: ${CHART_NAME}"
      CHARTS_PUSHED=$((CHARTS_PUSHED + 1))
    else
      print_error "Failed to push: ${CHART_NAME}"
      FAILED=$((FAILED + 1))
    fi
  fi
done

echo ""

# Step 4: Push Harbor chart if present
for CHART_TGZ in "${HARBOR_CHARTS_DIR}"/*.tgz; do
  if [[ -f "$CHART_TGZ" ]]; then
    CHART_NAME=$(basename "$CHART_TGZ")
    print_info "Pushing Harbor chart: ${CHART_NAME}"

    if helm push "$CHART_TGZ" "oci://${HARBOR_DOMAIN}/${HARBOR_CHART_PROJECT}" --insecure-skip-tls-verify 2>/dev/null; then
      print_success "Pushed: ${CHART_NAME}"
      CHARTS_PUSHED=$((CHARTS_PUSHED + 1))
    else
      print_warning "Failed to push Harbor chart (may not be needed)"
    fi
  fi
done

echo ""

# Summary
print_header "Chart Upload Summary"
print_success "Charts pushed: $CHARTS_PUSHED"
if [[ "$FAILED" -gt 0 ]]; then
  print_error "Failed: $FAILED"
fi
echo ""
print_info "Charts available at: oci://${HARBOR_DOMAIN}/${HARBOR_CHART_PROJECT}/"
print_info "To install from Harbor:"
echo "  helm install <release> oci://${HARBOR_DOMAIN}/${HARBOR_CHART_PROJECT}/<chart>"
