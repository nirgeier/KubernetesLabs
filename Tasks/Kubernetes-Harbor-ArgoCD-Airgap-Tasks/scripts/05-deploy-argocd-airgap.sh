#!/bin/bash
# =============================================================================
# Step 05 - Deploy ArgoCD (Offline Install Using Harbor)
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "STEP 5: Deploy ArgoCD (Offline/Airgap Mode)"

NODE_IP=$(get_node_ip)

# ── 1. Determine chart source ──
header "Locating ArgoCD Helm Chart"
ARGOCD_CHART_FILE="/tmp/argocd-airgap/argo-cd-${ARGOCD_CHART_VERSION}.tgz"
if [ -f "${ARGOCD_CHART_FILE}" ]; then
    CHART_SRC="${ARGOCD_CHART_FILE}"
    CHART_VERSION_FLAG=""
    success "Using local chart: ${ARGOCD_CHART_FILE}"
else
    CHART_SRC="argo/argo-cd"
    CHART_VERSION_FLAG="--version ${ARGOCD_CHART_VERSION}"
    warn "Local chart not found, using Helm repo"
fi

# ── 2. Create airgap values file ──
header "Creating Airgap Values File"
cat >/tmp/argocd-airgap-values.yaml <<EOF
global:
  image:
    repository: ${HARBOR_URL}/argocd/argocd
    tag: "v2.13.3"
server:
  insecure: true
  ingress:
    enabled: true
    ingressClassName: nginx
    hostname: argocd.local
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
redis:
  image:
    repository: ${HARBOR_URL}/argocd/redis
    tag: "7.4.2-alpine"
dex:
  image:
    repository: ${HARBOR_URL}/argocd/dex
    tag: "v2.41.1"
EOF
success "Values file created"

# ── 3. Install ArgoCD ──
header "Installing ArgoCD"
helm upgrade --install argocd ${CHART_SRC} \
    ${CHART_VERSION_FLAG} \
    --namespace argocd \
    --create-namespace \
    -f /tmp/argocd-airgap-values.yaml \
    --wait --timeout 10m
success "ArgoCD installed"

# ── 4. Verify images ──
header "Verifying Container Images"
kubectl get pods -n argocd
echo ""
info "Images in use:"
kubectl get pods -n argocd -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | sort -u

# ── 5. Configure argocd.local ──
header "Configuring argocd.local"
if ! grep -q "argocd.local" /etc/hosts; then
    echo "${NODE_IP}  argocd.local" | sudo tee -a /etc/hosts
    success "Added argocd.local to /etc/hosts"
else
    warn "argocd.local already in /etc/hosts"
fi

# ── 6. Retrieve credentials ──
header "ArgoCD Credentials"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)

info "URL:        http://argocd.local"
info "Username:   admin"
info "Password:   ${ARGOCD_PASSWORD}"

# ── 7. CLI login ──
if command -v argocd &>/dev/null; then
    header "ArgoCD CLI Login"
    argocd login argocd.local \
        --username admin \
        --password "${ARGOCD_PASSWORD}" \
        --insecure &&
        success "CLI login successful" ||
        warn "CLI login failed"
fi

success "Step 05 complete!"
