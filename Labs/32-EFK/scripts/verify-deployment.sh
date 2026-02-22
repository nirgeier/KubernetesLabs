#!/bin/bash
# =============================================================================
# Verify that the offline EFK deployment is fully working
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

print_header "Deployment Verification"

PASSED=0
FAILED=0
TOTAL=0

run_test() {
  local NAME="$1"
  local COMMAND="$2"
  TOTAL=$((TOTAL + 1))

  echo -n "  Test ${TOTAL}: ${NAME}... "
  if eval "$COMMAND" &>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
  fi
}

# Harbor tests
print_step "Harbor Registry Tests"
run_test "Harbor pods running" \
  "kubectl get pods -n ${HARBOR_NAMESPACE} --no-headers | grep -v Completed | grep -c Running"

run_test "Harbor API healthy" \
  "curl -sk ${HARBOR_URL}/api/v2.0/health | grep -q healthy"

run_test "Harbor project '${HARBOR_PROJECT}' exists" \
  "curl -sk -u ${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD} ${HARBOR_URL}/api/v2.0/projects?name=${HARBOR_PROJECT} | grep -q ${HARBOR_PROJECT}"

echo ""

# EFK pod tests
print_step "EFK Pod Tests"
run_test "Elasticsearch pod running" \
  "kubectl get pods -n ${EFK_NAMESPACE} -l app=elasticsearch --no-headers | grep -q Running"

run_test "Kibana pod running" \
  "kubectl get pods -n ${EFK_NAMESPACE} -l app=kibana --no-headers | grep -q Running"

run_test "Filebeat pod running" \
  "kubectl get pods -n ${EFK_NAMESPACE} -l app=filebeat --no-headers | grep -q Running"

run_test "Log Generator pods running" \
  "kubectl get pods -n ${EFK_NAMESPACE} -l app=log-generator --no-headers | grep -c Running"

run_test "Log Processor CronJob exists" \
  "kubectl get cronjob -n ${EFK_NAMESPACE} log-processor --no-headers"

echo ""

# Image source tests (verify images come from Harbor)
print_step "Image Source Tests (Harbor)"
run_test "ES image from Harbor" \
  "kubectl get statefulset -n ${EFK_NAMESPACE} elasticsearch -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q '${HARBOR_DOMAIN}'"

run_test "Kibana image from Harbor" \
  "kubectl get deployment -n ${EFK_NAMESPACE} kibana -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q '${HARBOR_DOMAIN}'"

run_test "Filebeat image from Harbor" \
  "kubectl get daemonset -n ${EFK_NAMESPACE} filebeat -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q '${HARBOR_DOMAIN}'"

run_test "Log Generator image from Harbor" \
  "kubectl get deployment -n ${EFK_NAMESPACE} log-generator -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q '${HARBOR_DOMAIN}'"

echo ""

# Data tests
print_step "Data Pipeline Tests"
run_test "Elasticsearch cluster healthy" \
  "kubectl exec -n ${EFK_NAMESPACE} elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health | grep -qE '\"status\":\"(green|yellow)\"'"

run_test "Filebeat index exists" \
  "kubectl exec -n ${EFK_NAMESPACE} elasticsearch-0 -- curl -s http://localhost:9200/_cat/indices | grep -q filebeat"

DOC_COUNT_CMD="kubectl exec -n ${EFK_NAMESPACE} elasticsearch-0 -- curl -s 'http://localhost:9200/filebeat-*/_count' | grep -o '\"count\":[0-9]*' | cut -d: -f2"
run_test "Data indexed in Elasticsearch" \
  "[ \$(${DOC_COUNT_CMD}) -gt 0 ]"

echo ""

# Kibana tests
print_step "Kibana Tests"
KIBANA_POD=$(kubectl get pods -n "${EFK_NAMESPACE}" -l app=kibana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -n "$KIBANA_POD" ]]; then
  KIBANA_INTERNAL="http://localhost:5601"
  run_test "Kibana API responding" \
    "kubectl exec -n ${EFK_NAMESPACE} ${KIBANA_POD} -- curl -s ${KIBANA_INTERNAL}/api/status | grep -q available"

  run_test "Data view exists" \
    "kubectl exec -n ${EFK_NAMESPACE} ${KIBANA_POD} -- curl -s -H 'kbn-xsrf: true' ${KIBANA_INTERNAL}/api/data_views | grep -q filebeat"
else
  echo "  (Kibana pod not found, skipping API tests)"
fi

echo ""

# Ingress test
print_step "Ingress Tests"
run_test "Kibana ingress configured" \
  "kubectl get ingress -n ${EFK_NAMESPACE} kibana --no-headers"

echo ""

# Summary
print_header "Verification Summary"
echo ""
echo "  Total:  ${TOTAL}"
echo -e "  Passed: ${GREEN}${PASSED}${NC}"
if [[ "$FAILED" -gt 0 ]]; then
  echo -e "  Failed: ${RED}${FAILED}${NC}"
else
  echo -e "  Failed: ${FAILED}"
fi
echo ""

if [[ "$FAILED" -eq 0 ]]; then
  print_success "All tests passed! Offline deployment is working correctly."
else
  print_warning "${FAILED} test(s) failed. Check the output above for details."
  exit 1
fi
