#!/usr/bin/env bash

# Wait for Docker-in-Docker to be ready
echo "==> Waiting for Docker daemon..."
for i in $(seq 1 30); do
  if docker info &>/dev/null; then
    break
  fi
  echo "    Waiting for Docker... ($i/30)"
  sleep 2
done

if ! docker info &>/dev/null; then
  echo "ERROR: Docker daemon not available. Kind cluster will not be created."
  echo "       You can retry manually: bash .devcontainer/post-create.sh"
  exit 0
fi

echo "==> Creating Kind cluster..."
if kind get clusters 2>/dev/null | grep -q "^labs$"; then
  echo "    Kind cluster 'labs' already exists, skipping."
else
  kind create cluster \
    --name labs \
    --config .devcontainer/kind-config.yaml \
    --wait 120s || {
    echo "WARNING: Kind cluster creation failed. You can retry manually."
    exit 0
  }
fi

echo "==> Setting kubectl context..."
kubectl cluster-info --context kind-labs || true

echo ""
echo "============================================"
echo "  KubernetesLabs devcontainer is ready!"
echo "  - Kind cluster 'labs' is running"
echo "  - kubectl, helm, k9s are available"
echo "  - Run: kubewall     (dashboard on port 8443)"
echo "============================================"
