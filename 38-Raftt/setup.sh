#!/bin/bash
set -euo pipefail

CLUSTER_NAME="raftt-lab"
NAMESPACE="raftt-lab"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Raftt Lab 38 - Setup"
echo "============================================"

# Check prerequisites
echo ""
echo "--- Checking prerequisites ---"

for cmd in docker kind kubectl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is not installed. Please install it first."
    exit 1
  fi
done
echo "All prerequisites found."

# Create kind cluster (skip if exists)
echo ""
echo "--- Creating kind cluster: ${CLUSTER_NAME} ---"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists, skipping creation."
else
  kind create cluster --name "${CLUSTER_NAME}" --config "${SCRIPT_DIR}/resources/kind-config.yaml"
  echo "Cluster '${CLUSTER_NAME}' created."
fi

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Build and load Docker image
echo ""
echo "--- Building Docker image ---"
docker build -t raftt-lab-backend:latest "${SCRIPT_DIR}/app"

echo ""
echo "--- Loading image into kind ---"
kind load docker-image raftt-lab-backend:latest --name "${CLUSTER_NAME}"

# Deploy resources
echo ""
echo "--- Deploying Kubernetes resources ---"
kubectl apply -f "${SCRIPT_DIR}/resources/01-namespace.yaml"
kubectl apply -f "${SCRIPT_DIR}/resources/02-deployment.yaml"
kubectl apply -f "${SCRIPT_DIR}/resources/03-service.yaml"

# Wait for pods
echo ""
echo "--- Waiting for pods to be ready ---"
kubectl wait --for=condition=ready pod -l app=backend -n "${NAMESPACE}" --timeout=120s

# Display status
echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
kubectl get all -n "${NAMESPACE}"
echo ""
echo "To test the app:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/backend 3000:3000 &"
echo "  curl http://localhost:3000/status"
echo ""
echo "To start Raftt Dev-Mode:"
echo "  raftt up"
echo ""
