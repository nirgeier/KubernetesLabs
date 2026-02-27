#!/bin/bash
# =============================================================================
# Step 03 - Mirror ArgoCD Images to Harbor for Airgap Install
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "STEP 3: Mirror ArgoCD Images to Harbor"

# ── 1. Add ArgoCD Helm repo ──
header "Adding ArgoCD Helm Repository"
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update argo
success "ArgoCD Helm repo ready"

# ── 2. Discover required images ──
header "Discovering Required Images"
IMAGES=$(helm template argocd argo/argo-cd \
    --version "${ARGOCD_CHART_VERSION}" \
    --namespace argocd 2>/dev/null |
    grep -E "image:" |
    sed 's/.*image: *"\?\([^"]*\)"\?.*/\1/' |
    sort -u)

info "Required images:"
echo "${IMAGES}"

# ── 3. Login to Harbor ──
header "Docker Login to Harbor"
docker login "${HARBOR_URL}" -u "${HARBOR_USER}" -p "${HARBOR_PASS}" ||
    error "Docker login failed"

# ── 4. Pull, tag, and push each image ──
header "Mirroring Images"
while IFS= read -r img; do
    [ -z "${img}" ] && continue
    local_name=$(echo "${img}" | rev | cut -d'/' -f1 | rev)
    target="${HARBOR_URL}/argocd/${local_name}"

    info "Mirroring: ${img} → ${target}"
    docker pull "${img}" &&
        docker tag "${img}" "${target}" &&
        docker push "${target}" &&
        success "Mirrored: ${target}" ||
        warn "Failed to mirror: ${img}"
done <<<"${IMAGES}"

# ── 5. Save Helm chart locally ──
header "Saving ArgoCD Helm Chart"
mkdir -p /tmp/argocd-airgap
helm pull argo/argo-cd --version "${ARGOCD_CHART_VERSION}" --destination /tmp/argocd-airgap/
ls -la /tmp/argocd-airgap/
success "Helm chart saved"

# ── 6. Verify in Harbor ──
header "Verifying Images in Harbor"
curl -s -u "${HARBOR_USER}:${HARBOR_PASS}" \
    "http://${HARBOR_URL}/api/v2.0/projects/argocd/repositories" |
    python3 -m json.tool 2>/dev/null ||
    info "Check Harbor UI: http://${HARBOR_URL}/harbor/projects"

success "Step 03 complete! All ArgoCD images mirrored to Harbor."
