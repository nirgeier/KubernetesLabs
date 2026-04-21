#!/bin/bash
set -euo pipefail

CLUSTER_NAME="raftt-lab"

echo "============================================"
echo "  Raftt Lab 38 - Cleanup"
echo "============================================"

# Stop Raftt if running
echo ""
echo "--- Stopping Raftt Dev-Mode ---"
if command -v raftt &>/dev/null; then
  raftt down 2>/dev/null || echo "Raftt was not running."
else
  echo "Raftt CLI not installed, skipping."
fi

# Kill port-forwards
echo ""
echo "--- Killing port-forward processes ---"
pkill -f "port-forward.*raftt-lab" 2>/dev/null || echo "No port-forward processes found."

# Delete kind cluster
echo ""
echo "--- Deleting kind cluster: ${CLUSTER_NAME} ---"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  kind delete cluster --name "${CLUSTER_NAME}"
  echo "Cluster '${CLUSTER_NAME}' deleted."
else
  echo "Cluster '${CLUSTER_NAME}' does not exist, skipping."
fi

echo ""
echo "============================================"
echo "  Cleanup Complete!"
echo "============================================"
