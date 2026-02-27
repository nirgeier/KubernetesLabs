#!/bin/bash
# =============================================================================
# Install EFK stack from Harbor registry (offline / air-gapped)
# All images are pulled from the local Harbor registry
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

print_header "Offline EFK Installation (from Harbor)"

check_prerequisites kubectl helm

# Check cluster
if ! kubectl cluster-info &>/dev/null; then
  print_error "Cannot connect to Kubernetes cluster"
  exit 1
fi

OVERRIDES_DIR="${PROJECT_ROOT}/helm/harbor-overrides"

# Step 0: Generate override values
print_step "Step 0: Generating Harbor override values..."
bash "${SCRIPT_DIR}/generate-harbor-values.sh"
echo ""

# Step 1: Verify Harbor is accessible
print_step "Step 1: Verifying Harbor registry is accessible..."
if curl -sk "${HARBOR_URL}/api/v2.0/health" 2>/dev/null | grep -q "healthy"; then
  print_success "Harbor is healthy at ${HARBOR_URL}"
else
  print_error "Harbor is not accessible at ${HARBOR_URL}"
  print_info "Make sure Harbor is installed and ${HARBOR_DOMAIN} resolves correctly"
  exit 1
fi

echo ""

# Step 2: Deploy Elasticsearch
print_step "Step 2: Deploying Elasticsearch (from Harbor)..."
helm upgrade --install elasticsearch "${PROJECT_ROOT}/helm/elasticsearch" \
  --namespace "${EFK_NAMESPACE}" \
  --create-namespace \
  --values "${OVERRIDES_DIR}/elasticsearch-values.yaml" \
  --wait \
  --timeout 5m
print_success "Elasticsearch deployed"

# Wait for ES to be ready
print_info "Waiting for Elasticsearch to be fully ready..."
sleep 30

echo ""

# Step 3: Deploy Kibana
print_step "Step 3: Deploying Kibana (from Harbor)..."
helm upgrade --install kibana "${PROJECT_ROOT}/helm/kibana" \
  --namespace "${EFK_NAMESPACE}" \
  --values "${OVERRIDES_DIR}/kibana-values.yaml" \
  --wait \
  --timeout 5m
print_success "Kibana deployed"

echo ""

# Step 4: Deploy Filebeat
print_step "Step 4: Deploying Filebeat (from Harbor)..."
helm upgrade --install filebeat "${PROJECT_ROOT}/helm/filebeat" \
  --namespace "${EFK_NAMESPACE}" \
  --values "${OVERRIDES_DIR}/filebeat-values.yaml" \
  --wait \
  --timeout 5m
print_success "Filebeat deployed"

echo ""

# Step 5: Deploy Log Generator
print_step "Step 5: Deploying Log Generator (from Harbor)..."
helm upgrade --install log-generator "${PROJECT_ROOT}/helm/log-generator" \
  --namespace "${EFK_NAMESPACE}" \
  --values "${OVERRIDES_DIR}/log-generator-values.yaml" \
  --wait \
  --timeout 5m
print_success "Log Generator deployed"

echo ""

# Step 6: Deploy Log Processor
print_step "Step 6: Deploying Log Processor (from Harbor)..."
helm upgrade --install log-processor "${PROJECT_ROOT}/helm/log-processor" \
  --namespace "${EFK_NAMESPACE}" \
  --values "${OVERRIDES_DIR}/log-processor-values.yaml" \
  --wait \
  --timeout 5m
print_success "Log Processor deployed"

echo ""

# Step 7: Wait for all pods
print_step "Step 7: Waiting for all pods to be ready..."
wait_for_pod "app=elasticsearch" "${EFK_NAMESPACE}" 300
wait_for_pod "app=kibana" "${EFK_NAMESPACE}" 300
wait_for_pod "app=filebeat" "${EFK_NAMESPACE}" 300
wait_for_pod "app=log-generator" "${EFK_NAMESPACE}" 300
print_success "All pods are ready"

echo ""

# Step 8: Wait for initial log processing
print_step "Step 8: Waiting for initial log processing..."
kubectl wait --for=condition=complete --timeout=600s \
  -n "${EFK_NAMESPACE}" job/log-processor-initial 2>/dev/null || {
  print_warning "Initial job still running, continuing..."
}
sleep 10

# Check data
DOC_COUNT=$(kubectl exec -n "${EFK_NAMESPACE}" elasticsearch-0 -- \
  curl -s 'http://localhost:9200/filebeat-*/_count' 2>/dev/null |
  grep -o '"count":[0-9]*' | cut -d: -f2 || echo "0")
if [[ "${DOC_COUNT}" -gt 0 ]]; then
  print_success "Found ${DOC_COUNT} documents in Elasticsearch"
else
  print_warning "No data yet - dashboards may need manual refresh"
fi

echo ""

# Summary
print_header "Offline EFK Installation Complete"
echo ""
print_info "All images pulled from: ${HARBOR_DOMAIN}/${HARBOR_PROJECT}/"
echo ""
print_info "Components:"
echo "  - Elasticsearch : ${HARBOR_ES_IMAGE}:${ES_TAG}"
echo "  - Filebeat      : ${HARBOR_FILEBEAT_IMAGE}:${FILEBEAT_TAG}"
echo "  - Kibana        : ${HARBOR_KIBANA_IMAGE}:${KIBANA_TAG}"
echo "  - Log Generator : ${HARBOR_LOG_GENERATOR_IMAGE}:${LOG_GENERATOR_TAG}"
echo "  - Log Processor : ${HARBOR_LOG_PROCESSOR_IMAGE}:${LOG_PROCESSOR_TAG}"
echo "  - Curl (jobs)   : ${HARBOR_CURL_IMAGE}:${CURL_TAG}"
echo ""
print_info "Dashboards (deployed via Kibana chart):"
echo "  - Error Analysis Dashboard"
echo "  - General Logs Dashboard"
echo "  - Warning Analysis Dashboard"
echo "  - Component Activity Dashboard"
echo "  - Performance Overview Dashboard"
echo "  - HTTP Access Dashboard"
echo "  - K8s Monitoring Dashboard"
echo "  - APM Dashboard"
echo ""
print_info "Access Kibana: http://${KIBANA_INGRESS_HOST}"
echo ""
print_info "Verify pods:"
echo "  kubectl get pods -n ${EFK_NAMESPACE}"
