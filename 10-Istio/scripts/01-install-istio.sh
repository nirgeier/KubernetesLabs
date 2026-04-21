#!/bin/bash
set -euo pipefail
# =============================================================================
# Install Istio Service Mesh via Helm
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

install_istio() {
  print_header "Installing Istio Service Mesh via Helm"

  # Add Istio Helm repository
  print_step "Adding Istio Helm repository..."
  helm repo add istio https://istio-release.storage.googleapis.com/charts
  helm repo update

  # Install Istio base (CRDs)
  print_step "Installing Istio base (CRDs)..."
  helm upgrade --install istio-base istio/base \
    --namespace istio-system \
    --create-namespace \
    --set defaultRevision=default \
    --wait \
    --timeout 3m

  if [ $? -ne 0 ]; then
    print_error "Failed to install Istio base CRDs"
    exit 1
  fi
  print_success "Istio CRDs installed"

  # Install Istiod (control plane)
  print_step "Installing Istiod (control plane)..."
  helm upgrade --install istiod istio/istiod \
    --namespace istio-system \
    --set meshConfig.accessLogFile=/dev/stdout \
    --set meshConfig.enableTracing=true \
    --set meshConfig.defaultConfig.tracing.sampling=100.0 \
    --set meshConfig.defaultConfig.holdApplicationUntilProxyStarts=true \
    --set pilot.traceSampling=100.0 \
    --wait \
    --timeout 5m

  if [ $? -ne 0 ]; then
    print_error "Failed to install Istiod"
    exit 1
  fi
  print_success "Istiod installed"

  # Install Istio Ingress Gateway
  print_step "Installing Istio Ingress Gateway..."
  helm upgrade --install istio-ingressgateway istio/gateway \
    --namespace istio-system \
    --wait \
    --timeout 5m

  if [ $? -ne 0 ]; then
    print_error "Failed to install Istio Ingress Gateway"
    exit 1
  fi
  print_success "Istio Ingress Gateway installed"

  # Verify installation
  print_step "Verifying Istio installation..."
  kubectl get pods -n istio-system
  echo ""
  print_success "Istio service mesh installed successfully!"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_prerequisites
  install_istio
fi
