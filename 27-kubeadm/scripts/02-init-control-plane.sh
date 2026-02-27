#!/bin/bash
#
# 02-init-control-plane.sh
# Run this script ONLY on the control-plane node (after running 01-prepare-node.sh).
# Initializes the Kubernetes control plane and installs Flannel CNI.
#
set -euo pipefail

CONTROL_PLANE_IP="${1:-$(hostname -I | awk '{print $1}')}"

echo "=== Initializing control-plane on ${CONTROL_PLANE_IP} ==="
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address="${CONTROL_PLANE_IP}"

echo "=== Setting up kubeconfig ==="
mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "=== Installing Flannel CNI ==="
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "=== Waiting for node to become Ready ==="
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "=== Control-plane initialized ==="
echo ""
echo "To join worker nodes, run the following on each worker:"
echo ""
kubeadm token create --print-join-command
