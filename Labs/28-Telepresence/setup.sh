#!/bin/bash

# Telepresence Demo - Setup Script
# This script sets up the complete demo environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Telepresence Demo - Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &>/dev/null; then
  echo -e "${RED}Error: kubectl is not installed${NC}"
  exit 1
fi
echo -e "${GREEN}✓ kubectl found${NC}"

if ! command -v telepresence &>/dev/null; then
  echo -e "${YELLOW}Warning: telepresence is not installed${NC}"
  echo "Please install telepresence first:"
  echo "  macOS: brew install datawire/blackbird/telepresence"
  echo "  Linux: curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence && chmod +x /usr/local/bin/telepresence"
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  echo -e "${GREEN}✓ telepresence found${NC}"
  telepresence version
fi

# Check cluster connectivity
echo ""
echo -e "${YELLOW}Checking cluster connectivity...${NC}"
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Cluster connection successful${NC}"
kubectl cluster-info | head -n 1

# Create namespace
echo ""
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl apply -f resources/01-namespace.yaml
echo -e "${GREEN}✓ Namespace created${NC}"

# Deploy dataservice
echo ""
echo -e "${YELLOW}Deploying Data Service...${NC}"
kubectl apply -f resources/02-dataservice.yaml
echo -e "${GREEN}✓ Data Service deployed${NC}"

# Wait for dataservice to be ready
echo ""
echo -e "${YELLOW}Waiting for Data Service to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=dataservice -n telepresence-demo --timeout=120s
echo -e "${GREEN}✓ Data Service is ready${NC}"

# Deploy backend
echo ""
echo -e "${YELLOW}Deploying Backend Service...${NC}"
kubectl apply -f resources/03-backend.yaml
echo -e "${GREEN}✓ Backend Service deployed${NC}"

# Wait for backend to be ready
echo ""
echo -e "${YELLOW}Waiting for Backend Service to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n telepresence-demo --timeout=120s
echo -e "${GREEN}✓ Backend Service is ready${NC}"

# Deploy frontend
echo ""
echo -e "${YELLOW}Deploying Frontend...${NC}"
kubectl apply -f resources/04-frontend.yaml
echo -e "${GREEN}✓ Frontend deployed${NC}"

# Wait for frontend to be ready
echo ""
echo -e "${YELLOW}Waiting for Frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend -n telepresence-demo --timeout=120s
echo -e "${GREEN}✓ Frontend is ready${NC}"

# Display deployment status
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Status${NC}"
echo -e "${GREEN}========================================${NC}"
kubectl get all -n telepresence-demo

# Get service URLs
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Access Information${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if we're using minikube
if kubectl config current-context | grep -q "minikube"; then
  echo -e "${YELLOW}Detected Minikube cluster${NC}"
  echo ""
  echo "To access the frontend, run:"
  echo -e "${GREEN}  minikube service frontend -n telepresence-demo${NC}"
  echo ""
  echo "Or use port-forward:"
  echo -e "${GREEN}  kubectl port-forward -n telepresence-demo svc/frontend 8080:80${NC}"
  echo "  Then open: http://localhost:8080"
else
  # Get LoadBalancer IP/hostname
  echo "Getting service endpoint..."
  FRONTEND_IP=$(kubectl get svc frontend -n telepresence-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  FRONTEND_HOST=$(kubectl get svc frontend -n telepresence-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

  if [ -n "$FRONTEND_IP" ]; then
    echo -e "${GREEN}Frontend URL: http://$FRONTEND_IP${NC}"
  elif [ -n "$FRONTEND_HOST" ]; then
    echo -e "${GREEN}Frontend URL: http://$FRONTEND_HOST${NC}"
  else
    echo -e "${YELLOW}LoadBalancer pending... Use port-forward:${NC}"
    echo -e "${GREEN}  kubectl port-forward -n telepresence-demo svc/frontend 8080:80${NC}"
    echo "  Then open: http://localhost:8080"
  fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "1. Connect Telepresence to your cluster:"
echo -e "   ${GREEN}telepresence connect${NC}"
echo ""
echo "2. Test the services:"
echo -e "   ${GREEN}telepresence list --namespace telepresence-demo${NC}"
echo ""
echo "3. Start intercepting the backend service:"
echo -e "   ${GREEN}cd resources/backend-app${NC}"
echo -e "   ${GREEN}python3 -m venv venv${NC}"
echo -e "   ${GREEN}source venv/bin/activate${NC}"
echo -e "   ${GREEN}pip install -r requirements.txt${NC}"
echo -e "   ${GREEN}telepresence intercept backend --port 5000 --namespace telepresence-demo${NC}"
echo -e "   ${GREEN}python app.py${NC}"
echo ""
echo "4. Make changes to app.py and see them reflected in real-time!"
echo ""
echo -e "${GREEN}Setup completed successfully! 🎉${NC}"
