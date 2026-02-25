#!/bin/bash
# =============================================================================
# Step 02 - Configure Harbor with Ingress (harbor.local)
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "STEP 2: Configure Harbor (harbor.local)"

# ── 1. Verify Harbor health ──
header "Verifying Harbor Health"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${HARBOR_URL}/api/v2.0/health)
if [ "${HTTP_CODE}" != "200" ]; then
    error "Harbor is not healthy (HTTP ${HTTP_CODE}). Check: kubectl get pods -n harbor"
fi
success "Harbor is healthy"

# ── 2. Verify Ingress ──
header "Verifying Ingress Configuration"
kubectl get ingress -n harbor

# ── 3. Create Harbor projects ──
header "Creating Harbor Projects"
for project in argocd library; do
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "http://${HARBOR_URL}/api/v2.0/projects" \
        -H "Content-Type: application/json" \
        -u "${HARBOR_USER}:${HARBOR_PASS}" \
        -d "{\"project_name\": \"${project}\", \"public\": true}")

    if [ "${response}" = "201" ]; then
        success "Created project: ${project}"
    elif [ "${response}" = "409" ]; then
        warn "Project already exists: ${project}"
    else
        warn "Project ${project} returned HTTP ${response}"
    fi
done

# ── 4. Configure Docker insecure registry ──
header "Configuring Docker for Insecure Registry"
info "Ensure harbor.local is in Docker's insecure-registries:"
echo '  { "insecure-registries": ["harbor.local"] }'

# ── 5. Docker login ──
header "Logging in to Harbor"
docker login "${HARBOR_URL}" -u "${HARBOR_USER}" -p "${HARBOR_PASS}" &&
    success "Docker login successful" ||
    warn "Docker login failed - check insecure registry config"

# ── 6. Test push ──
header "Testing Push/Pull"
docker pull busybox:latest 2>/dev/null
docker tag busybox:latest ${HARBOR_URL}/library/busybox:latest
docker push ${HARBOR_URL}/library/busybox:latest &&
    success "Test push successful!" ||
    warn "Test push failed"

success "Step 02 complete!"
