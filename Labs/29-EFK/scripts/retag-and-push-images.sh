#!/bin/bash
# =============================================================================
# Load saved images, retag them for Harbor, and push to Harbor registry
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env

print_header "Retag & Push Images to Harbor"

check_prerequisites docker

# Build the source -> harbor mapping
declare -A IMAGE_MAP
IMAGE_MAP["${ES_IMAGE}:${ES_TAG}"]="${HARBOR_ES_IMAGE}:${ES_TAG}"
IMAGE_MAP["${FILEBEAT_IMAGE}:${FILEBEAT_TAG}"]="${HARBOR_FILEBEAT_IMAGE}:${FILEBEAT_TAG}"
IMAGE_MAP["${KIBANA_IMAGE}:${KIBANA_TAG}"]="${HARBOR_KIBANA_IMAGE}:${KIBANA_TAG}"
IMAGE_MAP["${LOG_GENERATOR_IMAGE}:${LOG_GENERATOR_TAG}"]="${HARBOR_LOG_GENERATOR_IMAGE}:${LOG_GENERATOR_TAG}"
IMAGE_MAP["${CURL_IMAGE}:${CURL_TAG}"]="${HARBOR_CURL_IMAGE}:${CURL_TAG}"

# Step 1: Load images from tar files
print_step "Step 1: Loading images from tar files..."
if [[ -d "$IMAGES_DIR" ]]; then
  for TAR_FILE in "$IMAGES_DIR"/*.tar; do
    if [[ -f "$TAR_FILE" ]]; then
      print_info "Loading: $(basename "$TAR_FILE")"
      docker load -i "$TAR_FILE"
    fi
  done
  print_success "All EFK images loaded"
else
  print_warning "No images directory found at $IMAGES_DIR"
  print_info "Assuming images are already present in Docker"
fi

# Load Harbor images if present
if [[ -f "${HARBOR_CHARTS_DIR}/harbor-images.tar" ]]; then
  print_info "Loading Harbor images..."
  docker load -i "${HARBOR_CHARTS_DIR}/harbor-images.tar"
  print_success "Harbor images loaded"
fi

echo ""

# Step 2: Login to Harbor
print_step "Step 2: Logging in to Harbor registry..."
if echo "${HARBOR_ADMIN_PASSWORD}" | docker login "${HARBOR_DOMAIN}" \
  --username "${HARBOR_ADMIN_USER}" --password-stdin 2>/dev/null; then
  print_success "Logged in to Harbor"
else
  print_error "Failed to login to Harbor at ${HARBOR_DOMAIN}"
  print_info "Make sure Harbor is running and ${HARBOR_DOMAIN} is reachable"
  print_info "If using self-signed certs, add Harbor CA to Docker's trusted certs:"
  print_info "  /etc/docker/certs.d/${HARBOR_DOMAIN}/ca.crt"
  exit 1
fi

echo ""

# Step 3: Create Harbor project if it doesn't exist
print_step "Step 3: Ensuring Harbor project '${HARBOR_PROJECT}' exists..."
# Use Harbor API to create project (ignore if already exists)
curl -sk -X POST "${HARBOR_URL}/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}" \
  -d "{\"project_name\": \"${HARBOR_PROJECT}\", \"public\": true}" \
  2>/dev/null || true
print_success "Project '${HARBOR_PROJECT}' ready"

echo ""

# Step 4: Retag and push images
print_step "Step 4: Retagging and pushing images to Harbor..."
echo ""

FAILED=0

for SRC_IMAGE in "${!IMAGE_MAP[@]}"; do
  DEST_IMAGE="${IMAGE_MAP[$SRC_IMAGE]}"

  print_info "Retagging: ${SRC_IMAGE}"
  print_info "       -> ${DEST_IMAGE}"

  if docker tag "$SRC_IMAGE" "$DEST_IMAGE"; then
    print_info "Pushing: ${DEST_IMAGE}"
    if docker push "$DEST_IMAGE"; then
      print_success "Pushed: ${DEST_IMAGE}"
    else
      print_error "Failed to push: ${DEST_IMAGE}"
      FAILED=$((FAILED + 1))
    fi
  else
    print_error "Failed to retag: ${SRC_IMAGE} -> ${DEST_IMAGE}"
    FAILED=$((FAILED + 1))
  fi
  echo ""
done

# Summary
print_header "Push Summary"
TOTAL=${#IMAGE_MAP[@]}
SUCCEEDED=$((TOTAL - FAILED))
print_info "Total images: $TOTAL"
print_success "Successfully pushed: $SUCCEEDED"
if [[ "$FAILED" -gt 0 ]]; then
  print_error "Failed: $FAILED"
  exit 1
fi

echo ""
print_info "All images available at ${HARBOR_DOMAIN}/${HARBOR_PROJECT}/"
print_info "Image mappings:"
for SRC_IMAGE in "${!IMAGE_MAP[@]}"; do
  echo "  ${SRC_IMAGE} -> ${IMAGE_MAP[$SRC_IMAGE]}"
done
