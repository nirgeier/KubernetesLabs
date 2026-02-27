#!/bin/bash
#
# 03-reset-cluster.sh
# Tears down the Kubernetes cluster on this node.
# Run on each node you want to clean up.
#
set -euo pipefail

echo "=== Resetting kubeadm ==="
kubeadm reset -f

echo "=== Cleaning up networking rules ==="
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

echo "=== Removing CNI configs ==="
rm -rf /etc/cni/net.d

echo "=== Removing kubeconfig ==="
rm -rf "$HOME/.kube"

echo "=== Cluster teardown complete ==="
