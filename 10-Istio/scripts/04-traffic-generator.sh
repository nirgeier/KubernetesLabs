#!/bin/bash
set -euo pipefail
# =============================================================================
# Deploy Traffic Generator
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/common.sh"

deploy_traffic_generator() {
  print_header "Deploying Traffic Generator"

  # Create traffic-gen namespace
  print_step "Creating traffic-gen namespace..."
  kubectl create namespace traffic-gen 2>/dev/null || true

  # Deploy traffic generator CronJob
  print_step "Deploying traffic generator CronJob..."
  kubectl apply -f "${LAB_DIR}/manifests/traffic-generator.yaml"
  print_success "Traffic generator deployed"

  echo ""
  print_info "Traffic generator will send requests to Bookinfo every minute"
  print_info "This generates live traffic visible in Kiali, Grafana, and Jaeger"
  echo ""

  kubectl get cronjob -n traffic-gen
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_prerequisites
  deploy_traffic_generator
fi
