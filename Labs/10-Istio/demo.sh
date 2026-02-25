#!/bin/bash
set -euo pipefail
# =============================================================================
# Istio + Kiali Lab - Main Deployment Script
# Usage:
#   ./demo.sh deploy   - Deploy Istio, addons, Bookinfo, and traffic generator
#   ./demo.sh cleanup  - Remove everything
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${SCRIPT_DIR}"
source "${LAB_DIR}/scripts/common.sh"

# Deploy all components
deploy() {
  print_header "Istio + Kiali Lab Deployment"

  check_prerequisites
  echo ""

  # Step 1: Install Istio (sourced script may overwrite SCRIPT_DIR, so use LAB_DIR)
  source "${LAB_DIR}/scripts/01-install-istio.sh"
  install_istio
  echo ""

  # Step 2: Install observability addons
  source "${LAB_DIR}/scripts/02-install-addons.sh"
  install_addons
  echo ""

  # Step 3: Deploy Bookinfo application
  source "${LAB_DIR}/scripts/03-deploy-bookinfo.sh"
  deploy_bookinfo
  echo ""

  # Step 4: Deploy traffic generator
  source "${LAB_DIR}/scripts/04-traffic-generator.sh"
  deploy_traffic_generator
  echo ""

  # Step 5: Verify
  source "${LAB_DIR}/scripts/05-verify.sh"
  verify_deployment
  echo ""

  # Display access information
  display_access_info
}

# Display access information
display_access_info() {
  echo ""
  echo "=========================================="
  print_success "Istio + Kiali Lab Deployment Complete!"
  echo "=========================================="
  echo ""

  # Get Istio Ingress Gateway external IP (or hostname for LoadBalancer)
  GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [ -z "$GATEWAY_IP" ]; then
    GATEWAY_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  fi

  print_info "Access via Istio Ingress Gateway:"
  echo ""
  echo -e "  Kiali:       ${GREEN}http://kiali.local${NC}"
  echo -e "  Grafana:     ${GREEN}http://grafana.local${NC}"
  echo -e "  Jaeger:      ${GREEN}http://jaeger.local${NC}"
  echo -e "  Prometheus:  ${GREEN}http://prometheus.local${NC}"
  echo -e "  Loki:        ${GREEN}http://loki.local${NC}"
  echo -e "  Bookinfo:    ${GREEN}http://bookinfo.local/productpage${NC}"
  echo ""

  # Check /etc/hosts
  HOSTS_NEEDED=""
  for host in kiali.local grafana.local jaeger.local prometheus.local loki.local bookinfo.local; do
    if ! grep -q "$host" /etc/hosts 2>/dev/null; then
      HOSTS_NEEDED="$HOSTS_NEEDED $host"
    fi
  done

  if [ -n "$HOSTS_NEEDED" ]; then
    print_warning "Add these hosts to /etc/hosts:"
    if [ -n "$GATEWAY_IP" ]; then
      echo "  echo \"${GATEWAY_IP}${HOSTS_NEEDED}\" | sudo tee -a /etc/hosts"
    else
      echo "  # Get gateway IP: kubectl get svc istio-ingressgateway -n istio-system"
      echo "  echo \"<GATEWAY_IP>${HOSTS_NEEDED}\" | sudo tee -a /etc/hosts"
    fi
    echo ""
  else
    print_success "/etc/hosts already configured"
    echo ""
  fi

  print_info "Or access via port-forwarding:"
  echo ""
  echo "  kubectl port-forward svc/kiali -n istio-system 20001:20001 &"
  echo "  kubectl port-forward svc/grafana -n istio-system 3000:3000 &"
  echo "  kubectl port-forward svc/loki -n istio-system 3100:3100 &"
  echo "  kubectl port-forward svc/tracing -n istio-system 16686:80 &"
  echo "  kubectl port-forward svc/prometheus -n istio-system 9090:9090 &"
  echo "  kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80 &"
  echo ""

  print_info "Istio Feature Demos:"
  echo "  ./istio-features/apply-feature.sh list              # List features"
  echo "  ./istio-features/apply-feature.sh 01-traffic-shifting  # Canary deploy"
  echo "  ./istio-features/apply-feature.sh 02-fault-injection   # Chaos testing"
  echo "  ./istio-features/apply-feature.sh 04-request-routing   # A/B testing"
  echo "  ./istio-features/apply-feature.sh 07-mtls-strict       # Security"
  echo "  ./istio-features/apply-feature.sh reset                # Reset all"
  echo ""

  print_info "Monitoring:"
  echo "  ./monitor.sh           # Interactive monitoring menu"
  echo "  ./monitor.sh summary   # Quick status summary"
  echo "  ./monitor.sh test      # Test all components"
  echo "  ./monitor.sh full      # Full detailed report"
  echo ""

  print_info "Useful Commands:"
  echo "  kubectl get pods -n istio-system    # Control plane pods"
  echo "  kubectl get pods -n bookinfo        # Application pods"
  echo "  kubectl get vs,dr -n bookinfo       # Istio routing config"
  echo "  kubectl get cronjob -n traffic-gen  # Traffic generator status"
  echo ""
}

# Cleanup all components
cleanup() {
  print_header "Cleaning Up Istio + Kiali Lab"

  # Remove traffic generator
  print_step "Removing traffic generator..."
  kubectl delete namespace traffic-gen 2>/dev/null || true
  print_success "Traffic generator removed"

  # Remove Bookinfo
  print_step "Removing Bookinfo application..."
  kubectl delete -f "${LAB_DIR}/manifests/bookinfo-gateway.yaml" -n bookinfo 2>/dev/null || true
  kubectl delete -f "${LAB_DIR}/manifests/destination-rules.yaml" -n bookinfo 2>/dev/null || true
  kubectl delete -f "${LAB_DIR}/manifests/bookinfo.yaml" -n bookinfo 2>/dev/null || true
  kubectl delete namespace bookinfo 2>/dev/null || true
  print_success "Bookinfo removed"

  # Remove Istio feature demos (if any applied)
  print_step "Cleaning up Istio feature demos..."
  kubectl delete peerauthentication --all -n bookinfo 2>/dev/null || true
  kubectl delete peerauthentication --all -n istio-system 2>/dev/null || true

  # Remove addons and Istio gateway routes
  print_step "Removing observability addons and gateway routes..."
  kubectl delete -f "${LAB_DIR}/manifests/observability-routes.yaml" 2>/dev/null || true
  kubectl delete -f "${LAB_DIR}/manifests/addons/" 2>/dev/null || true
  print_success "Addons and gateway routes removed"

  # Remove Istio
  print_step "Removing Istio..."
  helm uninstall istio-ingressgateway -n istio-system 2>/dev/null || true
  helm uninstall istiod -n istio-system 2>/dev/null || true
  helm uninstall istio-base -n istio-system 2>/dev/null || true
  print_success "Istio Helm releases removed"

  # Clean up namespace
  print_step "Removing istio-system namespace..."
  kubectl delete namespace istio-system 2>/dev/null || true

  # Clean up Istio CRDs
  print_step "Removing Istio CRDs..."
  for crd in $(kubectl get crd -o name 2>/dev/null | grep 'istio.io' || true); do
    kubectl delete "$crd" --ignore-not-found 2>/dev/null || true
  done

  # Clean up cluster-wide resources (addon ClusterRoles/ClusterRoleBindings)
  kubectl delete clusterrole istio-prometheus kiali loki-clusterrole 2>/dev/null || true
  kubectl delete clusterrolebinding istio-prometheus kiali loki-clusterrolebinding 2>/dev/null || true

  echo ""
  print_success "Cleanup complete! All Istio + Kiali resources removed."
}

# Parse command line arguments
case "${1}" in
deploy)
  deploy
  ;;
cleanup)
  cleanup
  ;;
*)
  echo "Usage: $0 {deploy|cleanup}"
  echo ""
  echo "Commands:"
  echo "  deploy  - Deploy Istio + Kiali + Bookinfo + traffic generator"
  echo "  cleanup - Remove all resources"
  exit 1
  ;;
esac
