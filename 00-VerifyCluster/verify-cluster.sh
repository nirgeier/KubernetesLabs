#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Kubernetes Cluster Verification Lab Script${NC}"
echo -e "${BLUE}====================================================${NC}"

# Step 1: Installing Kind
echo -e "${YELLOW}Step 1: Installing Kind${NC}"
echo -e "${GREEN}Installing Kind using Homebrew...${NC}"
brew install kind
echo -e "${GREEN}Verifying Kind installation...${NC}"
kind version
echo -e "${GREEN}Kind installation completed.${NC}"
echo ""

# Step 2: Create Kind cluster
echo -e "${YELLOW}Step 2: Creating Kind cluster${NC}"
echo -e "${GREEN}Running: kind create cluster${NC}"
kind create cluster
echo -e "${GREEN}Kind cluster creation completed.${NC}"
echo ""

# Step 3: Check the Kind cluster status
echo -e "${YELLOW}Step 3: Checking Kind cluster status${NC}"
echo -e "${GREEN}Running: kubectl cluster-info${NC}"
kubectl cluster-info
echo -e "${GREEN}Cluster status check completed.${NC}"
echo ""

# Step 4: Verify that the cluster is up and running (kubectl cluster-info again)
echo -e "${YELLOW}Step 4: Verifying cluster is up and running${NC}"
echo -e "${GREEN}Running: kubectl cluster-info${NC}"
kubectl cluster-info
echo -e "${GREEN}Cluster verification completed.${NC}"
echo ""

# Step 5: Verify kubectl configuration
echo -e "${YELLOW}Step 5: Verifying kubectl configuration${NC}"
echo -e "${GREEN}Running: kubectl config view${NC}"
kubectl config view
echo -e "${GREEN}Kubectl configuration verified.${NC}"
echo ""

# Step 6: Verify that you can "talk" to your cluster
echo -e "${YELLOW}Step 6: Checking nodes in the cluster${NC}"
echo -e "${GREEN}Running: kubectl get nodes${NC}"
kubectl get nodes
echo -e "${GREEN}Node check completed.${NC}"
echo ""

echo -e "${BLUE}All steps completed successfully!${NC}"
