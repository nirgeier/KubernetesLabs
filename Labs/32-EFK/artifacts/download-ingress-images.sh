#!/bin/bash
# =============================================================================
# Download ingress-nginx controller images for offline installation
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/common.sh"
load_env

print_header "Download Ingress Controller Images"

check_prerequisites docker

ensure_dirs "$INGRESS_CHARTS_DIR"

INGRESS_IMAGES=(
  "${INGRESS_CONTROLLER_IMAGE}:${INGRESS_CONTROLLER_TAG}"
  "${INGRESS_WEBHOOK_IMAGE}:${INGRESS_WEBHOOK_TAG}"
)

INGRESS_TAR="${INGRESS_CHARTS_DIR}/ingress-images.tar"

print_info "Ingress controller images to download:"
for img in "${INGRESS_IMAGES[@]}"; do
  echo "  - $img"
done
echo ""

FAILED=0

for img in "${INGRESS_IMAGES[@]}"; do
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
print_step "Saving ingress controller images to tar..."
docker save "${INGRESS_IMAGES[@]}" -o "$INGRESS_TAR"

SIZE=$(du -h "$INGRESS_TAR" | cut -f1)
print_success "Ingress images saved: $(basename "$INGRESS_TAR") ($SIZE)"
