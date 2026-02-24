#!/bin/bash

# Telepresence Demo - Test Script
# This script runs tests to verify the demo setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Telepresence Demo - Testing${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if services are running
echo -e "${YELLOW}Checking service status...${NC}"

# Check pods
echo ""
echo "Pod Status:"
kubectl get pods -n telepresence-demo

# Check services
echo ""
echo "Service Status:"
kubectl get svc -n telepresence-demo

# Test dataservice
echo ""
echo -e "${YELLOW}Testing Data Service...${NC}"
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n telepresence-demo -- \
  curl -s http://dataservice:5001/health | grep -q "healthy" &&
  echo -e "${GREEN}✓ Data Service health check passed${NC}" ||
  echo -e "${RED}✗ Data Service health check failed${NC}"

# Test backend
echo ""
echo -e "${YELLOW}Testing Backend Service...${NC}"
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n telepresence-demo -- \
  curl -s http://backend:5000/api/health | grep -q "healthy" &&
  echo -e "${GREEN}✓ Backend Service health check passed${NC}" ||
  echo -e "${RED}✗ Backend Service health check failed${NC}"

# Test backend-to-dataservice communication
echo ""
echo -e "${YELLOW}Testing inter-service communication...${NC}"
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n telepresence-demo -- \
  curl -s http://backend:5000/api/data | grep -q "success" &&
  echo -e "${GREEN}✓ Inter-service communication working${NC}" ||
  echo -e "${RED}✗ Inter-service communication failed${NC}"

# Test frontend
echo ""
echo -e "${YELLOW}Testing Frontend...${NC}"
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n telepresence-demo -- \
  curl -s http://frontend | grep -q "Telepresence Demo" &&
  echo -e "${GREEN}✓ Frontend is accessible${NC}" ||
  echo -e "${RED}✗ Frontend is not accessible${NC}"

# Test Telepresence connection
echo ""
echo -e "${YELLOW}Checking Telepresence connection...${NC}"
if command -v telepresence &>/dev/null; then
  if telepresence status &>/dev/null; then
    echo -e "${GREEN}✓ Telepresence is connected${NC}"
    telepresence status

    echo ""
    echo -e "${YELLOW}Listing available services...${NC}"
    telepresence list --namespace telepresence-demo
  else
    echo -e "${YELLOW}Telepresence is not connected${NC}"
    echo "Run: telepresence connect"
  fi
else
  echo -e "${YELLOW}Telepresence is not installed${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing completed!${NC}"
echo -e "${GREEN}========================================${NC}"
