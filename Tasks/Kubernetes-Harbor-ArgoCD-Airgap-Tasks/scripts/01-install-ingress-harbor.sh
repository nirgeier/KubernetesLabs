#!/bin/bash
# =============================================================================
# Step 01 - Install Nginx Ingress Controller + Harbor Registry
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "STEP 1: Install Nginx Ingress Controller + Harbor"

# ── 1. Add Helm repositories ──
header "Adding Helm Repositories"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo add harbor https://helm.goharbor.io 2>/dev/null || true
helm repo update
success "Helm repositories added and updated"

# ── 2. Install Nginx Ingress Controller ──
header "Installing Nginx Ingress Controller"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.service.nodePorts.http=30080 \
    --set controller.service.nodePorts.https=30443 \
    --set controller.admissionWebhooks.enabled=false \
    --wait --timeout 5m

kubectl get pods -n ingress-nginx
success "Nginx Ingress Controller installed"

# ── 3. Get Node IP ──
NODE_IP=$(get_node_ip)
info "Node IP: ${NODE_IP}"

# ── 4. Install Harbor ──
header "Installing Harbor Registry"
helm upgrade --install harbor harbor/harbor \
    --namespace harbor \
    --create-namespace \
    --set expose.type=ingress \
    --set expose.ingress.className=nginx \
    --set expose.ingress.hosts.core=harbor.local \
    --set expose.tls.enabled=false \
    --set externalURL=http://harbor.local \
    --set harborAdminPassword="${HARBOR_PASS}" \
    --set persistence.enabled=false \
    --wait --timeout 10m

kubectl get pods -n harbor
success "Harbor registry installed"

# ── 5. Configure /etc/hosts ──
header "Configuring /etc/hosts"
if ! grep -q "harbor.local" /etc/hosts; then
    echo "${NODE_IP}  harbor.local" | sudo tee -a /etc/hosts
    success "Added harbor.local to /etc/hosts"
else
    warn "harbor.local already exists in /etc/hosts"
fi

# ── 6. Verify ──
header "Verifying Harbor Access"
sleep 10
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://harbor.local/api/v2.0/health 2>/dev/null || echo "000")
if [ "${HTTP_CODE}" = "200" ]; then
    success "Harbor is healthy (HTTP ${HTTP_CODE})"
else
    warn "Harbor returned HTTP ${HTTP_CODE} - it may still be starting up"
fi

echo ""
info "Harbor UI:       http://harbor.local"
info "Harbor Admin:    ${HARBOR_USER} / ${HARBOR_PASS}"
success "Step 01 complete!"
