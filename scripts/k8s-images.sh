#!/bin/bash

# Script to list all container images used in a Kubernetes cluster
# Requirements: kubectl installed and configured to access the cluster

echo "Fetching all container images used in the Kubernetes cluster..."
echo "============================================================"

# Get all pods across all namespaces
# Extract image names from pod specifications
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' |
	sort | uniq | grep -v "^$"
