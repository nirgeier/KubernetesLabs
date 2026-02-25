#!/usr/bin/env bash
# =============================================================================
# entrypoint.sh - Starts Docker daemon, creates Kind cluster, execs CMD
# =============================================================================
set -e

echo "==> Starting Docker daemon..."
dockerd >/var/log/dockerd.log 2>&1 &

echo "==> Waiting for Docker daemon..."
TRIES=0
until docker info >/dev/null 2>&1; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge 30 ]; then
    echo "ERROR: Docker daemon failed to start after 30s"
    tail -20 /var/log/dockerd.log
    exit 1
  fi
  sleep 1
done
echo "==> Docker daemon is ready."

# Create Kind cluster if not already present
if kind get clusters 2>/dev/null | grep -q "^labs$"; then
  echo "==> Kind cluster 'labs' already exists."
  # Restart any stopped nodes
  NODES=$(docker ps -a --filter "label=io.x-k8s.kind.cluster=labs" --filter "status=exited" -q)
  if [ -n "$NODES" ]; then
    docker start $NODES
  fi
  kubectl wait --for=condition=Ready nodes --all --timeout=120s 2>/dev/null || true
else
  echo "==> Creating Kind cluster 'labs'..."
  kind create cluster \
    --name labs \
    --config /etc/kind-config.yaml \
    --wait 120s || {
    echo "WARNING: Kind cluster creation failed."
  }
fi

echo ""
echo "============================================"
echo "  KubernetesLabs is ready!"
echo "  - Kind cluster 'labs' is running"
echo "  - Labs are in /labs"
echo "  - kubectl, helm, k9s available"
echo "============================================"

exec "$@"
