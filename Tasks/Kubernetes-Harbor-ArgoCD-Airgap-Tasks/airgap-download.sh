#!/bin/bash

# Airgap download script for Kubernetes, Harbor, ArgoCD and ingress controller
# This script downloads all required Docker images for full airgap installation

echo "Starting airgap image download process..."

# Define base directory for storing images
BASE_DIR="./airgap-images"
mkdir -p "$BASE_DIR"

# List of required Docker images
IMAGES=(
	# Nginx Ingress Controller
	"registry.k8s.io/ingress-nginx/controller:v1.10.1"
	"registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1"

	# Harbor Registry
	"goharbor/harbor-portal:v2.9.3"
	"goharbor/harbor-core:v2.9.3"
	"goharbor/harbor-database:v2.9.3"
	"goharbor/harbor-jobservice:v2.9.3"
	"goharbor/harbor-log:v2.9.3"
	"goharbor/harbor-registryctl:v2.9.3"
	"goharbor/nginx-photon:v2.9.3"
	"goharbor/redis-photon:v2.9.3"
	"ghcr.io/goharbor/chartmuseum-photon:v0.17.0-v2.9.3"

	# ArgoCD
	"quay.io/argoproj/argocd:v2.13.3"
	"redis:7.4.2-alpine"
	"ghcr.io/dexidp/dex:v2.41.1"

	# Additional components
	"registry.k8s.io/kube-apiserver:v1.29.0"
	"registry.k8s.io/kube-controller-manager:v1.29.0"
	"registry.k8s.io/kube-scheduler:v1.29.0"
	"registry.k8s.io/kube-proxy:v1.29.0"
	"registry.k8s.io/pause:3.9"
	"registry.k8s.io/etcd:3.5.9-0"
	"registry.k8s.io/coredns/coredns:v1.10.1"

	# Tools and utilities
	"busybox:latest"
	"curlimages/curl:7.85.0"
	"alpine:latest"
	"nginx:1.25-alpine"
)

echo "Total images to download: ${#IMAGES[@]}"

# Download images using docker pull with progress tracking
success_count=0
failed_count=0

echo "Pulling Docker images..."
for i in "${!IMAGES[@]}"; do
	image="${IMAGES[i]}"
	echo "[$((i + 1))/${#IMAGES[@]}] Pulling $image..."

	if docker pull "$image" 2>/dev/null; then
		((success_count++))
	else
		echo "Failed to pull $image"
		((failed_count++))
	fi
done

echo "Download completed!"
echo "Successful downloads: $success_count"
echo "Failed downloads: $failed_count"

# Save images as tar files for airgap installation
echo "Saving images as tar files..."
for i in "${!IMAGES[@]}"; do
	image="${IMAGES[i]}"
	# Sanitize image name for file naming
	safe_image=$(echo "$image" | sed 's/[\/:]/_/g')
	echo "[$((i + 1))/${#IMAGES[@]}] Saving $image as $BASE_DIR/$safe_image.tar"
	if docker save "$image" >"$BASE_DIR/$safe_image.tar" 2>/dev/null; then
		echo "Saved $image successfully"
	else
		echo "Failed to save $image"
	fi
done

echo "All images saved as tar files in $BASE_DIR directory!"
echo "Total images: ${#IMAGES[@]}"
echo "Successfully downloaded: $success_count"
echo "Failed downloads: $failed_count"

if [ $failed_count -gt 0 ]; then
	echo "Warning: Some image downloads failed. Please check the output above."
fi
