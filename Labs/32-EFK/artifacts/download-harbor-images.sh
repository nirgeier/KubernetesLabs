#!/bin/bash
# =============================================================================
# Download Harbor's own container images for offline installation
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/common.sh"
load_env

print_header "Download Harbor Container Images"

check_prerequisites docker helm

ensure_dirs "$HARBOR_CHARTS_DIR"

# Harbor images needed for v1.14.0 (based on the Helm chart)
HARBOR_IMAGES=(
  "goharbor/harbor-core:v2.10.0"
  "goharbor/harbor-db:v2.10.0"
  "goharbor/harbor-jobservice:v2.10.0"
  "goharbor/harbor-portal:v2.10.0"
  "goharbor/harbor-registryctl:v2.10.0"
  "goharbor/registry-photon:v2.10.0"
  "goharbor/trivy-adapter-photon:v2.10.0"
  "goharbor/redis-photon:v2.10.0"
  "goharbor/nginx-photon:v2.10.0"
)

HARBOR_TAR="${HARBOR_CHARTS_DIR}/harbor-images.tar"

print_info "Harbor images to download:"
for img in "${HARBOR_IMAGES[@]}"; do
  echo "  - $img"
done
echo ""

FAILED=0

for img in "${HARBOR_IMAGES[@]}"; do
  print_step "Pulling: $img"
  if ! docker pull "$img"; then
    print_error "Failed to pull: $img"
    FAILED=$((FAILED + 1))
  fi
done

if [[ "$FAILED" -gt 0 ]]; then
  print_error "Failed to pull $FAILED images. Aborting save."
  exit 1
fi

echo ""
print_step "Saving all Harbor images to a single tar..."
docker save "${HARBOR_IMAGES[@]}" -o "$HARBOR_TAR"

SIZE=$(du -h "$HARBOR_TAR" | cut -f1)
print_success "Harbor images saved: $(basename "$HARBOR_TAR") ($SIZE)"
