#!/bin/bash
set -euo pipefail
# =============================================================================
# Install Istio Observability Addons (Kiali, Prometheus, Grafana, Jaeger)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/common.sh"

install_addons() {
  print_header "Installing Istio Observability Addons"

  # Install Prometheus
  print_step "Installing Prometheus..."
  kubectl apply -f "${LAB_DIR}/manifests/addons/prometheus.yaml"
  print_success "Prometheus manifest applied"

  # Install Grafana
  print_step "Installing Grafana..."
  kubectl apply -f "${LAB_DIR}/manifests/addons/grafana.yaml"
  print_success "Grafana manifest applied"

  # Install Jaeger
  print_step "Installing Jaeger..."
  kubectl apply -f "${LAB_DIR}/manifests/addons/jaeger.yaml"
  print_success "Jaeger manifest applied"

  # Install Kiali
  print_step "Installing Kiali..."
  kubectl apply -f "${LAB_DIR}/manifests/addons/kiali.yaml"
  print_success "Kiali manifest applied"

  # Wait for addons to be ready
  print_step "Waiting for addons to be ready..."
  wait_for_pods "app=prometheus" "istio-system" 180
  wait_for_pods "app=grafana" "istio-system" 180
  wait_for_pods "app=jaeger" "istio-system" 180
  wait_for_pods "app=kiali" "istio-system" 180

  # Install Ingress for all services
  print_step "Installing Ingress resources for all services..."
  kubectl apply -f "${LAB_DIR}/manifests/ingress.yaml"
  print_success "Ingress resources applied"

  echo ""
  print_success "All observability addons installed!"
  echo ""
  kubectl get pods -n istio-system
  echo ""
  print_info "Ingress URLs:"
  echo "  - http://kiali.local"
  echo "  - http://grafana.local"
  echo "  - http://jaeger.local"
  echo "  - http://prometheus.local"
  echo "  - http://bookinfo.local/productpage"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_prerequisites
  install_addons
fi
