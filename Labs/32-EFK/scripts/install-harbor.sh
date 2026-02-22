#!/bin/bash
# =============================================================================
# Install Harbor registry on Kubernetes
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

print_header "Install Harbor Registry"

check_prerequisites kubectl helm

# Check cluster connectivity
if ! kubectl cluster-info &>/dev/null; then
  print_error "Cannot connect to Kubernetes cluster"
  exit 1
fi

# Step 1: Create namespace
print_step "Step 1: Creating namespace '${HARBOR_NAMESPACE}'..."
kubectl create namespace "${HARBOR_NAMESPACE}" 2>/dev/null || true
print_success "Namespace ready"

echo ""

# Step 2: Load Harbor images if available (offline)
print_step "Step 2: Loading Harbor images from local artifacts..."
if [[ -f "${HARBOR_CHARTS_DIR}/harbor-images.tar" ]]; then
  docker load -i "${HARBOR_CHARTS_DIR}/harbor-images.tar"
  print_success "Harbor images loaded from tar"
else
  print_info "No local harbor images tar found, will pull from registry"
fi

echo ""

# Step 3: Install Harbor via Helm
print_step "Step 3: Installing Harbor via Helm..."

# Determine chart source - use local if available, otherwise pull from repo
HARBOR_CHART_SOURCE=""
LOCAL_CHART=$(find "${HARBOR_CHARTS_DIR}" -name "harbor-*.tgz" 2>/dev/null | head -1)

if [[ -n "$LOCAL_CHART" && -f "$LOCAL_CHART" ]]; then
  print_info "Using local chart: $(basename "$LOCAL_CHART")"
  HARBOR_CHART_SOURCE="$LOCAL_CHART"
else
  print_info "Using chart from repository..."
  helm repo add harbor "${HARBOR_CHART_REPO}" 2>/dev/null || true
  helm repo update harbor
  HARBOR_CHART_SOURCE="harbor/harbor"
fi

# Build the Helm values based on expose type
if [[ "${HARBOR_EXPOSE_TYPE}" == "ingress" ]]; then
  HARBOR_VALUES=$(
    cat <<EOF
expose:
  type: ingress
  tls:
    enabled: ${HARBOR_TLS_ENABLED}
    certSource: auto
    auto:
      commonName: "${HARBOR_DOMAIN}"
  ingress:
    hosts:
      core: ${HARBOR_DOMAIN}
    className: ${INGRESS_CLASS}
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"

externalURL: ${HARBOR_URL}

harborAdminPassword: "${HARBOR_ADMIN_PASSWORD}"

persistence:
  enabled: true
  persistentVolumeClaim:
    registry:
      size: ${HARBOR_STORAGE_SIZE}
    database:
      size: 5Gi
    redis:
      size: 1Gi
    trivy:
      size: 5Gi
EOF
  )
else
  HARBOR_VALUES=$(
    cat <<EOF
expose:
  type: nodePort
  tls:
    enabled: ${HARBOR_TLS_ENABLED}
    certSource: auto
    auto:
      commonName: "${HARBOR_DOMAIN}"
  nodePort:
    ports:
      https:
        nodePort: 30003
      http:
        nodePort: 30002

externalURL: ${HARBOR_URL}

harborAdminPassword: "${HARBOR_ADMIN_PASSWORD}"

persistence:
  enabled: true
  persistentVolumeClaim:
    registry:
      size: ${HARBOR_STORAGE_SIZE}
    database:
      size: 5Gi
    redis:
      size: 1Gi
    trivy:
      size: 5Gi
EOF
  )
fi

# Add storageClass if specified
if [[ -n "${HARBOR_STORAGE_CLASS}" ]]; then
  HARBOR_VALUES+="
    registry:
      storageClass: ${HARBOR_STORAGE_CLASS}
    database:
      storageClass: ${HARBOR_STORAGE_CLASS}
    redis:
      storageClass: ${HARBOR_STORAGE_CLASS}
    trivy:
      storageClass: ${HARBOR_STORAGE_CLASS}"
fi

# Write values to temp file
HARBOR_VALUES_FILE=$(mktemp)
echo "$HARBOR_VALUES" >"$HARBOR_VALUES_FILE"

helm upgrade --install harbor "$HARBOR_CHART_SOURCE" \
  --namespace "${HARBOR_NAMESPACE}" \
  --values "$HARBOR_VALUES_FILE" \
  --wait \
  --timeout 10m

rm -f "$HARBOR_VALUES_FILE"

print_success "Harbor installed successfully"

echo ""

# Step 4: Wait for Harbor to be ready
print_step "Step 4: Waiting for Harbor pods to be ready..."
kubectl wait --for=condition=ready pod -l app=harbor -n "${HARBOR_NAMESPACE}" --timeout=600s 2>/dev/null || {
  print_warning "Some Harbor pods may still be starting. Checking status..."
  kubectl get pods -n "${HARBOR_NAMESPACE}"
}

echo ""

# Step 5: Verify access
print_step "Step 5: Verifying Harbor access..."

# Get the node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")

HARBOR_READY=0
for i in $(seq 1 30); do
  if curl -sk "${HARBOR_URL}/api/v2.0/health" 2>/dev/null | grep -q "healthy"; then
    HARBOR_READY=1
    break
  fi
  echo "  Waiting for Harbor API... (attempt $i/30)"
  sleep 10
done

if [[ "$HARBOR_READY" -eq 1 ]]; then
  print_success "Harbor is healthy and accessible"
else
  print_warning "Harbor may not be fully ready yet"
  print_info "Check pods: kubectl get pods -n ${HARBOR_NAMESPACE}"
fi

echo ""

# Step 6: Create projects
print_step "Step 6: Creating Harbor projects..."

for PROJECT in "${HARBOR_PROJECT}" "${HARBOR_CHART_PROJECT}"; do
  curl -sk -X POST "${HARBOR_URL}/api/v2.0/projects" \
    -H "Content-Type: application/json" \
    -u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}" \
    -d "{\"project_name\": \"${PROJECT}\", \"public\": true}" \
    2>/dev/null || true
  print_success "Project '${PROJECT}' created/verified"
done

echo ""

# Summary
print_header "Harbor Installation Complete"
echo ""
print_info "Harbor URL: ${HARBOR_URL}"
print_info "Admin User: ${HARBOR_ADMIN_USER}"
print_info "Admin Password: ${HARBOR_ADMIN_PASSWORD}"
echo ""

# Step 7: Configure Docker daemon DNS for Harbor and EFK ingress hosts
print_step "Step 7: Configuring DNS for ingress hosts..."
if [[ -n "$NODE_IP" ]]; then
  # Add all ingress hosts to the Docker host's /etc/hosts via nsenter
  # This is needed on environments like OrbStack where Docker's DNS
  # can't resolve custom hostnames
  INGRESS_HOSTS=("${HARBOR_DOMAIN}" "${ELASTICSEARCH_INGRESS_HOST:-elasticsearch.local}" "${KIBANA_INGRESS_HOST:-kibana.local}")
  for HOST in "${INGRESS_HOSTS[@]}"; do
    docker run --rm --privileged --pid=host debian:latest \
      nsenter -t 1 -m -u -n -i sh -c \
      "grep -q '${HOST}' /etc/hosts 2>/dev/null || echo '${NODE_IP} ${HOST}' >> /etc/hosts" \
      2>/dev/null && print_success "Docker host DNS configured for ${HOST}" ||
      print_warning "Could not auto-configure Docker DNS for ${HOST}"
  done
fi

echo ""
print_info "DNS Configuration:"
echo "  Add to /etc/hosts (or DNS):"
if [[ -n "$NODE_IP" ]]; then
  echo "    ${NODE_IP} ${HARBOR_DOMAIN} ${ELASTICSEARCH_INGRESS_HOST:-elasticsearch.local} ${KIBANA_INGRESS_HOST:-kibana.local}"
else
  echo "    <node-ip> ${HARBOR_DOMAIN} ${ELASTICSEARCH_INGRESS_HOST:-elasticsearch.local} ${KIBANA_INGRESS_HOST:-kibana.local}"
fi
echo ""
print_info "Docker Configuration (for self-signed certs):"
echo "  Option 1: Add to /etc/docker/daemon.json:"
echo "    {\"insecure-registries\": [\"${HARBOR_DOMAIN}\"]}"
echo ""
echo "  Option 2: Copy Harbor CA cert:"
echo "    mkdir -p /etc/docker/certs.d/${HARBOR_DOMAIN}/"
echo "    kubectl get secret harbor-ingress -n ${HARBOR_NAMESPACE} \\"
echo "      -o jsonpath='{.data.ca\\.crt}' | base64 -d \\"
echo "      > /etc/docker/certs.d/${HARBOR_DOMAIN}/ca.crt"
echo ""
print_info "Next steps:"
echo "  1. Configure DNS/hosts for ${HARBOR_DOMAIN}"
echo "  2. Configure Docker to trust Harbor"
echo "  3. Run: ./scripts/retag-and-push-images.sh"
echo "  4. Run: ./scripts/upload-charts-to-harbor.sh"
echo "  5. Run: ./scripts/offline-install.sh"
