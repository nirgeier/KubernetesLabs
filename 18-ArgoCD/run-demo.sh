#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Ensure we are in the correct directory
cd "$(dirname "$0")"

echo -e "${GREEN}=== Starting ArgoCD Demo ===${NC}"

# Step 1: Install ArgoCD
if [ -f "./install-argocd.sh" ]; then
  chmod +x ./install-argocd.sh
  ./install-argocd.sh
else
  echo "Error: install-argocd.sh not found!"
  exit 1
fi

echo -e "\n${GREEN}=== Deploying Guestbook Application ===${NC}"

# Step 2: Apply the Application manifest
# This connects ArgoCD to the git repository
kubectl apply -f guestbook-app.yaml

echo "Waiting for Application to be created..."
sleep 5

echo -e "${GREEN}=== Verifying Application Status ===${NC}"
# Check if the application exists
kubectl get application guestbook -n argocd

echo -e "\n${GREEN}=== Waiting for Application to Sync ===${NC}"
# Wait for the application to be healthy and synced
# We look for .status.health.status == 'Healthy' and .status.sync.status == 'Synced'
# This might take a moment as ArgoCD pulls the repo and deploys

echo "Checking status loop (max 2 minutes)..."
for i in {1..24}; do
  STATUS=$(kubectl get application guestbook -n argocd -o jsonpath='{.status.health.status}')
  SYNC=$(kubectl get application guestbook -n argocd -o jsonpath='{.status.sync.status}')

  echo "Attempt $i: Health=$STATUS, Sync=$SYNC"

  if [[ "$STATUS" == "Healthy" && "$SYNC" == "Synced" ]]; then
    echo -e "${GREEN}Application is Healthy and Synced!${NC}"
    break
  fi

  if [ $i -eq 24 ]; then
    echo "Timeout waiting for sync."
  fi

  sleep 5
done

echo -e "\n${GREEN}=== Verifying Deployed Resources ===${NC}"
kubectl get all -n default -l app=guestbook-ui

echo -e "\n${GREEN}=== Demo Complete ===${NC}"
echo "You can check the application at http://localhost:8080 (ArgoCD UI) or check the deployed guestbook."
