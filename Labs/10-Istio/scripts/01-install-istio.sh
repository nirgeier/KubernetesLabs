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

  # Remove existing Istio resources not managed by Helm (istio-base) to avoid
  # "invalid ownership metadata" when a prior install used istioctl or left
  # resources without Helm annotations
  print_step "Checking for conflicting Istio resources..."

  for crd in $(kubectl get crd -o name 2>/dev/null | grep istio.io || true); do
    release=$(kubectl get "$crd" -o jsonpath='{.metadata.annotations["meta.helm.sh/release-name"]}' 2>/dev/null || true)
    if [ "$release" != "istio-base" ]; then
      print_info "Removing $crd (not managed by Helm istio-base)"
      kubectl delete "$crd" --ignore-not-found --wait=false 2>/dev/null || true
    fi
  done

  for webhook in $(kubectl get validatingwebhookconfiguration -o name 2>/dev/null | grep -i istio || true); do
    release=$(kubectl get "$webhook" -o jsonpath='{.metadata.annotations["meta.helm.sh/release-name"]}' 2>/dev/null || true)
    if [ "$release" != "istio-base" ]; then
      print_info "Removing $webhook (not managed by Helm istio-base)"
      kubectl delete "$webhook" --ignore-not-found 2>/dev/null || true
    fi
  done

  for webhook in $(kubectl get mutatingwebhookconfiguration -o name 2>/dev/null | grep -i istio || true); do
    release=$(kubectl get "$webhook" -o jsonpath='{.metadata.annotations["meta.helm.sh/release-name"]}' 2>/dev/null || true)
    if [ "$release" != "istio-base" ]; then
      print_info "Removing $webhook (not managed by Helm istio-base)"
      kubectl delete "$webhook" --ignore-not-found 2>/dev/null || true
    fi
  done

  # Allow removal to complete before Helm install
  sleep 3

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

  # Remove cluster-scoped resources that istiod would manage but exist without
  # Helm ownership (e.g. from a previous istioctl install)
  print_step "Checking for conflicting Istiod cluster resources..."
  for role in $(kubectl get clusterrole -o name 2>/dev/null | grep -i istio || true); do
    release=$(kubectl get "$role" -o jsonpath='{.metadata.annotations["meta.helm.sh/release-name"]}' 2>/dev/null || true)
    if [ "$release" != "istiod" ]; then
      print_info "Removing $role (not managed by Helm istiod)"
      kubectl delete "$role" --ignore-not-found 2>/dev/null || true
    fi
  done
  for binding in $(kubectl get clusterrolebinding -o name 2>/dev/null | grep -i istio || true); do
    release=$(kubectl get "$binding" -o jsonpath='{.metadata.annotations["meta.helm.sh/release-name"]}' 2>/dev/null || true)
    if [ "$release" != "istiod" ]; then
      print_info "Removing $binding (not managed by Helm istiod)"
      kubectl delete "$binding" --ignore-not-found 2>/dev/null || true
    fi
  done
  sleep 2

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
