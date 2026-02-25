#!/bin/bash
set -euo pipefail
# =============================================================================
# Istio + Kiali Lab - Monitoring Script
# Provides comprehensive monitoring of the Istio service mesh and addons
#
# Usage:
#   ./monitor.sh           # Interactive menu
#   ./monitor.sh summary   # Quick summary
#   ./monitor.sh test      # Test all components
#   ./monitor.sh full      # Full detailed report
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Print a cyan section header with a border.
# Args: $1 - Header text.
print_header() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}========================================${NC}"
}

# Print a blue subsection label.
# Args: $1 - Section title.
print_section() {
  echo ""
  echo -e "${BLUE}--- $1 ---${NC}"
}

# Print an info line with a green checkmark.
print_info() { echo -e "${GREEN}✓${NC} $1"; }

# Print a warning line with a yellow symbol.
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Print an error line with a red symbol.
print_error() { echo -e "${RED}✗${NC} $1"; }

# Print a key-value line with magenta key.
# Args: $1 - Label; $2 - Value.
print_value() { echo -e "  ${MAGENTA}$1:${NC} $2"; }

# Ensure kubectl is installed and cluster is reachable. Exits on failure.
check_prerequisites() {
  if ! command -v kubectl >/dev/null 2>&1; then
    print_error "kubectl is not installed"
    exit 1
  fi
  if ! kubectl cluster-info &>/dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
  fi
  print_info "Connected to Kubernetes cluster"
}

# Report Istiod, ingress gateway, sidecar injection, and Helm releases in istio-system.
check_istio() {
  print_header "ISTIO CONTROL PLANE"

  print_section "Istiod Status"
  ISTIOD_STATUS=$(kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  ISTIOD_VERSION=$(kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null | awk -F: '{print $NF}')
  if [ "$ISTIOD_STATUS" = "Running" ]; then
    print_info "Istiod: Running (${ISTIOD_VERSION:-unknown})"
  else
    print_error "Istiod: ${ISTIOD_STATUS:-Not Found}"
  fi

  print_section "Ingress Gateway"
  GW_STATUS=$(kubectl get pods -n istio-system -l istio=ingressgateway -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ -z "$GW_STATUS" ]; then
    GW_STATUS=$(kubectl get pods -n istio-system -l app=istio-ingressgateway -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  fi
  if [ "$GW_STATUS" = "Running" ]; then
    print_info "Ingress Gateway: Running"
  else
    print_error "Ingress Gateway: ${GW_STATUS:-Not Found}"
  fi

  print_section "Sidecar Injection"
  INJECTION=$(kubectl get namespace bookinfo -o jsonpath='{.metadata.labels.istio-injection}' 2>/dev/null)
  if [ "$INJECTION" = "enabled" ]; then
    print_info "bookinfo namespace: injection enabled"
  else
    print_warning "bookinfo namespace: injection ${INJECTION:-not configured}"
  fi

  print_section "Installed Helm Releases"
  helm list -n istio-system 2>/dev/null | grep -E '(NAME|istio)' || echo "  No Istio Helm releases found"
}

# List pods in istio-system, bookinfo, and traffic-gen (including cronjobs/jobs).
check_pods() {
  print_header "POD STATUS"

  print_section "istio-system namespace"
  kubectl get pods -n istio-system -o wide 2>/dev/null

  print_section "bookinfo namespace"
  kubectl get pods -n bookinfo -o wide 2>/dev/null

  print_section "traffic-gen namespace"
  kubectl get pods,cronjobs,jobs -n traffic-gen 2>/dev/null
}

# Report status of Prometheus, Grafana, Jaeger, Kiali and list addon services.
check_addons() {
  print_header "OBSERVABILITY ADDONS"

  for addon in prometheus grafana jaeger kiali loki; do
    STATUS=$(kubectl get pods -n istio-system -l app=$addon -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$STATUS" = "Running" ]; then
      print_info "${addon}: Running"
    else
      print_error "${addon}: ${STATUS:-Not Found}"
    fi
  done

  print_section "Addon Services"
  kubectl get svc -n istio-system -l 'app in (prometheus,grafana,kiali,jaeger,loki)' 2>/dev/null ||
    kubectl get svc -n istio-system 2>/dev/null | grep -E '(NAME|prometheus|grafana|kiali|tracing|jaeger|zipkin|loki)'
}

# Report Bookinfo services, deployments, sidecar status, and Istio config (VS/DR/GW).
check_bookinfo() {
  print_header "BOOKINFO APPLICATION"

  print_section "Services"
  kubectl get svc -n bookinfo 2>/dev/null

  print_section "Deployments & Sidecar Status"
  for app in productpage details reviews ratings; do
    PODS=$(kubectl get pods -n bookinfo -l app=$app -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.version}{" "}{.status.phase}{" containers="}{range .spec.containers[*]}{.name}{","}{end}{"\n"}{end}' 2>/dev/null)
    if [ -n "$PODS" ]; then
      while IFS= read -r line; do
        POD_NAME=$(echo "$line" | awk '{print $1}')
        VERSION=$(echo "$line" | awk '{print $2}')
        PHASE=$(echo "$line" | awk '{print $3}')
        HAS_SIDECAR=$(echo "$line" | grep -c "istio-proxy" || true)
        if [ "${HAS_SIDECAR:-0}" -gt 0 ]; then
          print_info "$app ($VERSION): $PHASE [sidecar ✓]"
        else
          print_warning "$app ($VERSION): $PHASE [NO sidecar]"
        fi
      done <<<"$PODS"
    else
      print_error "$app: Not found"
    fi
  done

  print_section "Istio Configuration"
  echo ""
  echo "  VirtualServices:"
  kubectl get virtualservices -n bookinfo 2>/dev/null | sed 's/^/    /'
  echo ""
  echo "  DestinationRules:"
  kubectl get destinationrules -n bookinfo 2>/dev/null | sed 's/^/    /'
  echo ""
  echo "  Gateways:"
  kubectl get gateways -n bookinfo 2>/dev/null | sed 's/^/    /'
}

# Query Prometheus for Bookinfo request rate, 5xx rate, and traffic generator status.
check_traffic() {
  print_header "MESH TRAFFIC METRICS"

  PROM_POD=$(kubectl get pods -n istio-system -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -z "$PROM_POD" ]; then
    print_error "Prometheus not found - cannot query metrics"
    return
  fi

  print_section "Request Rates (last 5m)"
  TOTAL_RPS=$(kubectl exec -n istio-system "$PROM_POD" -- wget -qO- 'http://localhost:9090/api/v1/query?query=sum(rate(istio_requests_total{reporter="destination",destination_service_namespace="bookinfo"}[5m]))' 2>/dev/null | grep -o '"value":\[.*\]' | grep -o '\[[^]]*\]' | grep -o '"[0-9.]*"$' | tr -d '"')
  if [ -n "$TOTAL_RPS" ] && [ "$TOTAL_RPS" != "0" ]; then
    print_value "Total request rate" "${TOTAL_RPS} req/s"
  else
    print_warning "No request metrics yet (traffic may need more time)"
  fi

  print_section "Error Rates (last 5m)"
  ERROR_RPS=$(kubectl exec -n istio-system "$PROM_POD" -- wget -qO- 'http://localhost:9090/api/v1/query?query=sum(rate(istio_requests_total{reporter="destination",destination_service_namespace="bookinfo",response_code=~"5.."}[5m]))' 2>/dev/null | grep -o '"value":\[.*\]' | grep -o '\[[^]]*\]' | grep -o '"[0-9.]*"$' | tr -d '"')
  if [ -n "$ERROR_RPS" ] && [ "$ERROR_RPS" != "0" ]; then
    print_value "5xx error rate" "${ERROR_RPS} req/s"
  else
    print_info "No 5xx errors detected"
  fi

  print_section "Traffic Generator"
  CRONJOB=$(kubectl get cronjob -n traffic-gen traffic-generator -o jsonpath='{.spec.schedule}' 2>/dev/null)
  LAST_JOB=$(kubectl get jobs -n traffic-gen --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null)
  if [ -n "$CRONJOB" ]; then
    print_value "Schedule" "$CRONJOB"
    if [ -n "$LAST_JOB" ]; then
      print_value "Latest job" "$LAST_JOB"
    fi
  else
    print_warning "Traffic generator not found"
  fi
}

# Show PeerAuthentication policies and per-namespace mTLS mode (bookinfo, istio-system).
check_mtls() {
  print_header "mTLS STATUS"

  print_section "PeerAuthentication Policies"
  kubectl get peerauthentication --all-namespaces 2>/dev/null || echo "  No PeerAuthentication policies found"

  print_section "Namespace mTLS Mode"
  for ns in bookinfo istio-system; do
    PA_MODE=$(kubectl get peerauthentication -n "$ns" -o jsonpath='{.items[0].spec.mtls.mode}' 2>/dev/null)
    if [ -n "$PA_MODE" ]; then
      print_value "$ns" "$PA_MODE"
    else
      print_value "$ns" "PERMISSIVE (default)"
    fi
  done
}

# Run connectivity checks: Istiod, gateway, addons, Bookinfo pods, productpage HTTP, traffic gen.
# Prints passed/failed counts.
test_pipeline() {
  print_header "COMPONENT CONNECTIVITY TEST"

  local passed=0
  local failed=0

  print_section "Step 1: Istio Control Plane"
  ISTIOD=$(kubectl get pods -n istio-system -l app=istiod --no-headers 2>/dev/null | grep -c Running || true)
  if [ "$ISTIOD" -gt 0 ]; then
    print_info "Istiod is running"
    passed=$((passed + 1))
  else
    print_error "Istiod is not running"
    failed=$((failed + 1))
  fi

  print_section "Step 2: Ingress Gateway"
  GW=$(kubectl get pods -n istio-system -l istio=ingressgateway --no-headers 2>/dev/null | grep -c Running || true)
  if [ "$GW" -eq 0 ]; then
    GW=$(kubectl get pods -n istio-system -l app=istio-ingressgateway --no-headers 2>/dev/null | grep -c Running || true)
  fi
  if [ "$GW" -gt 0 ]; then
    print_info "Ingress Gateway is running"
    passed=$((passed + 1))
  else
    print_error "Ingress Gateway is not running"
    failed=$((failed + 1))
  fi

  print_section "Step 3: Observability Addons"
  for addon in prometheus grafana kiali jaeger loki; do
    RUNNING=$(kubectl get pods -n istio-system -l app=$addon --no-headers 2>/dev/null | grep -c Running || true)
    if [ "$RUNNING" -gt 0 ]; then
      print_info "$addon is running"
      passed=$((passed + 1))
    else
      print_error "$addon is not running"
      failed=$((failed + 1))
    fi
  done

  print_section "Step 4: Bookinfo Application"
  for app in productpage details reviews ratings; do
    RUNNING=$(kubectl get pods -n bookinfo -l app=$app --no-headers 2>/dev/null | grep -c Running || true)
    if [ "$RUNNING" -gt 0 ]; then
      print_info "$app is running ($RUNNING pod(s))"
      passed=$((passed + 1))
    else
      print_error "$app is not running"
      failed=$((failed + 1))
    fi
  done

  print_section "Step 5: Productpage Connectivity"
  PRODUCTPAGE_POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$PRODUCTPAGE_POD" ]; then
    HTTP_CODE=$(kubectl exec -n bookinfo "$PRODUCTPAGE_POD" -c productpage -- curl -s -o /dev/null -w "%{http_code}" http://productpage:9080/productpage 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
      print_info "Productpage responds HTTP 200"
      passed=$((passed + 1))
    else
      print_warning "Productpage returned HTTP $HTTP_CODE"
      failed=$((failed + 1))
    fi
  else
    print_error "Cannot find productpage pod"
    failed=$((failed + 1))
  fi

  print_section "Step 6: Traffic Generator"
  TG=$(kubectl get cronjob -n traffic-gen traffic-generator --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [ "$TG" -gt 0 ]; then
    print_info "Traffic generator CronJob is active"
    passed=$((passed + 1))
  else
    print_warning "Traffic generator not found"
    failed=$((failed + 1))
  fi

  echo ""
  print_header "TEST RESULTS: $passed passed, $failed failed"
}

# Print a short status table and port-forward / feature-demo commands.
show_summary() {
  print_header "QUICK SUMMARY"

  echo ""
  print_section "Component Status"

  ISTIOD=$(kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  print_value "Istiod" "${ISTIOD:-Not Found}"

  for addon in kiali prometheus grafana jaeger loki; do
    STATUS=$(kubectl get pods -n istio-system -l app=$addon -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    print_value "$addon" "${STATUS:-Not Found}"
  done

  BOOKINFO_PODS=$(kubectl get pods -n bookinfo --no-headers 2>/dev/null | grep -c Running || true)
  print_value "Bookinfo pods running" "${BOOKINFO_PODS:-0}"

  SIDECAR_PODS=$(kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.spec.containers[*].name}{"\n"}{end}' 2>/dev/null | grep -c istio-proxy || true)
  print_value "Pods with sidecar" "${SIDECAR_PODS:-0}"

  echo ""
  print_section "Port-Forward Commands"
  echo "  kubectl port-forward svc/kiali -n istio-system 20001:20001 &"
  echo "  kubectl port-forward svc/grafana -n istio-system 3000:3000 &"
  echo "  kubectl port-forward svc/tracing -n istio-system 16686:80 &"
  echo "  kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80 &"
  echo ""
  print_section "Feature Demos"
  echo "  ./istio-features/apply-feature.sh list"
}

# Print the interactive monitoring menu (numbered options and exit).
show_menu() {
  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║     Istio + Kiali Monitoring Menu             ║${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
  echo ""
  echo "  1) Show Summary"
  echo "  2) Check Istio Control Plane"
  echo "  3) Check All Pods"
  echo "  4) Check Observability Addons"
  echo "  5) Check Bookinfo Application"
  echo "  6) Check Mesh Traffic Metrics"
  echo "  7) Check mTLS Status"
  echo "  8) Test All Components"
  echo "  9) Full Report (All Checks)"
  echo "  0) Exit"
  echo ""
}

# Entry point: run full/test/summary report or start interactive menu.
# Args: $@ - Optional mode: full, test, summary, or none for menu.
main() {
  clear
  print_header "ISTIO + KIALI LAB MONITORING"
  check_prerequisites

  local mode="${1:-}"
  if [ "$mode" = "full" ] || [ "$mode" = "-f" ] || [ "$mode" = "--full" ]; then
    show_summary
    check_istio
    check_pods
    check_addons
    check_bookinfo
    check_traffic
    check_mtls
    test_pipeline
    exit 0
  fi

  if [ "$mode" = "test" ] || [ "$mode" = "-t" ] || [ "$mode" = "--test" ]; then
    test_pipeline
    exit 0
  fi

  if [ "$mode" = "summary" ] || [ "$mode" = "-s" ] || [ "$mode" = "--summary" ]; then
    show_summary
    exit 0
  fi

  # Interactive mode
  while true; do
    show_menu
    read -p "Select option: " choice

    case $choice in
    1) show_summary ;;
    2) check_istio ;;
    3) check_pods ;;
    4) check_addons ;;
    5) check_bookinfo ;;
    6) check_traffic ;;
    7) check_mtls ;;
    8) test_pipeline ;;
    9)
      show_summary
      check_istio
      check_pods
      check_addons
      check_bookinfo
      check_traffic
      check_mtls
      test_pipeline
      ;;
    0)
      echo ""
      print_info "Goodbye!"
      echo ""
      exit 0
      ;;
    *) print_error "Invalid option" ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
    clear
  done
}

main "$@"
