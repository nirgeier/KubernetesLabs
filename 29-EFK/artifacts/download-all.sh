#!/bin/bash
# =============================================================================
# Download ALL artifacts needed for offline/air-gapped installation
# This is the master download script that calls all sub-scripts
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/common.sh"
load_env

print_header "Download All Offline Artifacts"

print_info "Artifacts directory: ${ARTIFACTS_DIR}"
ensure_dirs "$ARTIFACTS_DIR" "$IMAGES_DIR" "$CHARTS_DIR" "$HARBOR_CHARTS_DIR"

echo ""

# Step 1: Download images
print_step "Step 1/4: Downloading container images..."
bash "${SCRIPT_DIR}/download-images.sh"
echo ""

# Step 2: Package Helm charts
print_step "Step 2/4: Packaging Helm charts..."
bash "${SCRIPT_DIR}/download-charts.sh"
echo ""

# Step 3: Download Harbor images
print_step "Step 3/4: Downloading Harbor container images..."
bash "${SCRIPT_DIR}/download-harbor-images.sh"
echo ""

# Step 4: Download Ingress controller images
print_step "Step 4/4: Downloading Ingress controller images..."
bash "${SCRIPT_DIR}/download-ingress-images.sh"
echo ""

# Final summary
print_header "All Artifacts Downloaded"
echo ""
print_info "Directory structure:"
find "$ARTIFACTS_DIR" -type f | sort | while read -r f; do
  SIZE=$(du -h "$f" | cut -f1)
  REL=$(echo "$f" | sed "s|${ARTIFACTS_DIR}/||")
  echo "  ${REL} (${SIZE})"
done

TOTAL_SIZE=$(du -sh "$ARTIFACTS_DIR" | cut -f1)
echo ""
print_success "Total artifact size: $TOTAL_SIZE"
echo ""
print_info "Next steps:"
echo "  1. Transfer the artifacts/ directory to the air-gapped environment"
echo "  2. Run: ./scripts/install-harbor.sh        # Install Harbor registry"
echo "  3. Run: ./scripts/retag-and-push-images.sh  # Push images to Harbor"
echo "  4. Run: ./scripts/offline-install.sh         # Install EFK from Harbor"
