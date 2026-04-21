#!/bin/bash
# =============================================================================
# Download busybox and push it to Harbor (harbor.local)
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "Download & Push busybox to Harbor"

# ── 1. Verify Harbor is accessible ──
header "Verifying Harbor Health"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${HARBOR_URL}/api/v2.0/health")
if [ "${HTTP_CODE}" != "200" ]; then
    error "Harbor is not healthy (HTTP ${HTTP_CODE}). Is Harbor running?"
fi
success "Harbor is healthy"

# ── 2. Login to Harbor ──
header "Logging in to Harbor"
docker login "${HARBOR_URL}" -u "${HARBOR_USER}" -p "${HARBOR_PASS}" ||
    error "Docker login to ${HARBOR_URL} failed"
success "Docker login successful"

# ── 3. Ensure 'library' project exists ──
header "Ensuring 'library' project exists in Harbor"
response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://${HARBOR_URL}/api/v2.0/projects" \
    -H "Content-Type: application/json" \
    -u "${HARBOR_USER}:${HARBOR_PASS}" \
    -d '{"project_name": "library", "public": true}')

if [ "${response}" = "201" ]; then
    success "Created project: library"
elif [ "${response}" = "409" ]; then
    info "Project 'library' already exists"
else
    warn "Create project returned HTTP ${response}"
fi

# ── 4. Pull busybox ──
header "Pulling busybox:latest"
docker pull busybox:latest
success "busybox:latest pulled"

# ── 5. Tag for Harbor ──
header "Tagging busybox for Harbor"
docker tag busybox:latest "${HARBOR_URL}/library/busybox:latest"
success "Tagged as ${HARBOR_URL}/library/busybox:latest"

# ── 6. Push to Harbor ──
header "Pushing busybox to Harbor"
docker push "${HARBOR_URL}/library/busybox:latest" ||
    error "Failed to push busybox to Harbor"
success "busybox pushed to ${HARBOR_URL}/library/busybox:latest"

# ── 7. Verify in Harbor ──
header "Verifying busybox in Harbor"
curl -s -u "${HARBOR_USER}:${HARBOR_PASS}" \
    "http://${HARBOR_URL}/api/v2.0/projects/library/repositories" |
    python3 -m json.tool 2>/dev/null ||
    info "Check Harbor UI: http://${HARBOR_URL}/harbor/projects"

success "Done! busybox is available at ${HARBOR_URL}/library/busybox:latest"
