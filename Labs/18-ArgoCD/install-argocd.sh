#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting ArgoCD Installation...${NC}"

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Ensure kustomization files exist
if [ ! -f "kustomization.yaml" ]; then
  echo "Creating kustomization.yaml..."
  cat <<EOF >kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: argocd
resources:
  - https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
patchesStrategicMerge:
- patch-replace.yaml
EOF
fi

if [ ! -f "patch-replace.yaml" ]; then
  echo "Creating patch-replace.yaml..."
  cat <<EOF >patch-replace.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  template:
    spec:
      containers:
      - name: argocd-server
        command:
        - argocd-server
        - --insecure
        - --staticassets
        - /shared/app
EOF
fi

# Apply using kustomize
echo -e "${GREEN}Applying ArgoCD manifests...${NC}"
kubectl apply -k .

# Wait for ArgoCD server to be ready
echo -e "${GREEN}Waiting for ArgoCD server to be ready...${NC}"
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Wait for secret
echo -e "${GREEN}Waiting for initial admin secret...${NC}"
while ! kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; do
  sleep 2
done

# Get password
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}ArgoCD Installed Successfully!${NC}"
echo "---------------------------------------------------------------"
echo "URL     : https://localhost:8080 (requires port-forwarding)"
echo "User    : admin"
echo "Password: $PASSWORD"
echo "---------------------------------------------------------------"
echo ""
echo "To access the UI run:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
