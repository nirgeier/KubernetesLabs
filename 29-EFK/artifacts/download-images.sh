#!/bin/bash
# =============================================================================
# Download all container images and save as tar files for offline use
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/common.sh"
load_env

print_header "Download & Save Container Images"

check_prerequisites docker

ensure_dirs "$IMAGES_DIR"

print_info "Images to download:"
for img in "${IMAGES[@]}"; do
  echo "  - $img"
done
echo ""

FAILED=0

for img in "${IMAGES[@]}"; do
  # Create a safe filename from the image name
  SAFE_NAME=$(echo "$img" | sed 's|/|_|g' | sed 's|:|_|g')
  TAR_FILE="${IMAGES_DIR}/${SAFE_NAME}.tar"

  if [[ -f "$TAR_FILE" ]]; then
    print_warning "Already saved: $img -> $(basename "$TAR_FILE")"
    continue
  fi

  print_step "Pulling: $img"
  if docker pull "$img"; then
    print_step "Saving: $img -> $(basename "$TAR_FILE")"
    if docker save "$img" -o "$TAR_FILE"; then
      SIZE=$(du -h "$TAR_FILE" | cut -f1)
      print_success "Saved: $(basename "$TAR_FILE") ($SIZE)"
    else
      print_error "Failed to save: $img"
      FAILED=$((FAILED + 1))
    fi
  else
    print_error "Failed to pull: $img"
    FAILED=$((FAILED + 1))
  fi
  echo ""
done

# Summary
echo ""
print_header "Download Summary"
TOTAL=${#IMAGES[@]}
SUCCEEDED=$((TOTAL - FAILED))
print_info "Total images: $TOTAL"
print_success "Successfully saved: $SUCCEEDED"
if [[ "$FAILED" -gt 0 ]]; then
  print_error "Failed: $FAILED"
fi

echo ""
print_info "Images saved to: $IMAGES_DIR"
ls -lh "$IMAGES_DIR"/*.tar 2>/dev/null || true
