#!/bin/bash
set -euo pipefail
# =============================================================================
# Verify all components are running correctly
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Verify Istio control plane, ingress gateway, addons, Bookinfo, traffic
# generator, and Prometheus metrics. Prints pass/fail summary.
verify_deployment() {
  print_header "Verifying Istio + Kiali Deployment"

  local errors=0

  # Check Istio control plane
  print_step "Checking Istio control plane..."
  ISTIOD_STATUS=$(kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ "$ISTIOD_STATUS" = "Running" ]; then
    print_success "Istiod: Running"
  else
    print_error "Istiod: ${ISTIOD_STATUS:-Not Found}"
    errors=$((errors + 1))
  fi

  # Check Ingress Gateway
  GW_STATUS=$(kubectl get pods -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ "$GW_STATUS" = "Running" ]; then
    print_success "Ingress Gateway: Running"
  else
    # Try the Helm chart label
    GW_STATUS=$(kubectl get pods -n istio-system -l istio=ingressgateway -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$GW_STATUS" = "Running" ]; then
      print_success "Ingress Gateway: Running"
    else
      print_error "Ingress Gateway: ${GW_STATUS:-Not Found}"
      errors=$((errors + 1))
    fi
  fi

  # Check addons
  print_step "Checking observability addons..."
  for addon in prometheus grafana kiali jaeger; do
    STATUS=$(kubectl get pods -n istio-system -l app=$addon -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$STATUS" = "Running" ]; then
      print_success "$addon: Running"
    else
      print_error "$addon: ${STATUS:-Not Found}"
      errors=$((errors + 1))
    fi
  done

  # Check Bookinfo
  print_step "Checking Bookinfo application..."
  for app in productpage details reviews ratings; do
    STATUS=$(kubectl get pods -n bookinfo -l app=$app -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$STATUS" = "Running" ]; then
      # Check sidecar injection
      CONTAINERS=$(kubectl get pods -n bookinfo -l app=$app -o jsonpath='{.items[0].spec.containers[*].name}' 2>/dev/null)
      if echo "$CONTAINERS" | grep -q "istio-proxy"; then
        print_success "$app: Running (sidecar injected)"
      else
        print_warning "$app: Running (NO sidecar!)"
      fi
    else
      print_error "$app: ${STATUS:-Not Found}"
      errors=$((errors + 1))
    fi
  done

  # Check traffic generator
  print_step "Checking traffic generator..."
  CRONJOB=$(kubectl get cronjob -n traffic-gen traffic-generator -o jsonpath='{.metadata.name}' 2>/dev/null)
  if [ -n "$CRONJOB" ]; then
    print_success "Traffic generator CronJob: Active"
  else
    print_warning "Traffic generator: Not found"
  fi

  # Check Istio metrics in Prometheus
  print_step "Checking Istio metrics..."
  PROM_POD=$(kubectl get pods -n istio-system -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$PROM_POD" ]; then
    METRIC_COUNT=$(kubectl exec -n istio-system "$PROM_POD" -- wget -qO- 'http://localhost:9090/api/v1/query?query=count(istio_requests_total)' 2>/dev/null | grep -o '"value"' | wc -l | tr -d ' ')
    if [ "$METRIC_COUNT" -gt 0 ]; then
      print_success "Istio metrics available in Prometheus"
    else
      print_warning "No Istio metrics yet (traffic may need more time)"
    fi
  fi

  echo ""
  if [ "$errors" -eq 0 ]; then
    print_header "VERIFICATION PASSED - All components healthy"
  else
    print_header "VERIFICATION COMPLETED - $errors issue(s) found"
  fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_prerequisites
  verify_deployment
fi
