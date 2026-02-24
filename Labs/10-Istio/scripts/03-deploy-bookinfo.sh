#!/bin/bash
set -euo pipefail
# =============================================================================
# Deploy Bookinfo Sample Application
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/common.sh"

deploy_bookinfo() {
  print_header "Deploying Bookinfo Sample Application"

  # Create namespace with istio injection
  print_step "Creating bookinfo namespace with sidecar injection..."
  kubectl apply -f "${LAB_DIR}/manifests/namespace.yaml"
  print_success "Namespace created with istio-injection=enabled"

  # Deploy Bookinfo application
  print_step "Deploying Bookinfo microservices..."
  kubectl apply -f "${LAB_DIR}/manifests/bookinfo.yaml" -n bookinfo
  print_success "Bookinfo application deployed"

  # Deploy Gateway and VirtualService for ingress
  print_step "Configuring Istio Gateway..."
  kubectl apply -f "${LAB_DIR}/manifests/bookinfo-gateway.yaml" -n bookinfo
  print_success "Gateway configured"

  # Apply DestinationRules
  print_step "Applying DestinationRules..."
  kubectl apply -f "${LAB_DIR}/manifests/destination-rules.yaml" -n bookinfo
  print_success "DestinationRules applied"

  # Wait for pods
  print_step "Waiting for Bookinfo pods to be ready..."
  wait_for_pods "app=productpage" "bookinfo" 300
  wait_for_pods "app=details" "bookinfo" 300
  wait_for_pods "app=reviews" "bookinfo" 300
  wait_for_pods "app=ratings" "bookinfo" 300

  echo ""
  print_success "Bookinfo application deployed and ready!"
  echo ""
  kubectl get pods -n bookinfo

  # Verify the application works
  echo ""
  print_step "Verifying application connectivity..."
  sleep 5
  PRODUCTPAGE_POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}')
  RESULT=$(kubectl exec -n bookinfo "$PRODUCTPAGE_POD" -c productpage -- curl -s -o /dev/null -w "%{http_code}" http://productpage:9080/productpage 2>/dev/null)
  if [ "$RESULT" = "200" ]; then
    print_success "Bookinfo productpage is responding (HTTP 200)"
  else
    print_warning "Productpage returned HTTP $RESULT - it may need more time to initialize"
  fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_prerequisites
  deploy_bookinfo
fi
