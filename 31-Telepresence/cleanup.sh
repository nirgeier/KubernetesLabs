#!/bin/bash

# Telepresence Demo - Cleanup Script
# This script removes all demo resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Telepresence Demo - Cleanup${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Confirm cleanup
read -p "This will delete the telepresence-demo namespace and all resources. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cleanup cancelled"
  exit 0
fi

# Leave all telepresence intercepts
echo ""
echo -e "${YELLOW}Leaving Telepresence intercepts...${NC}"
if command -v telepresence &>/dev/null; then
  telepresence leave --all 2>/dev/null || echo "No active intercepts"
  echo -e "${GREEN}✓ Intercepts cleared${NC}"
else
  echo -e "${YELLOW}Telepresence not installed, skipping...${NC}"
fi

# Delete namespace (this will delete all resources)
echo ""
echo -e "${YELLOW}Deleting namespace and all resources...${NC}"
kubectl delete namespace telepresence-demo --timeout=60s 2>/dev/null || echo "Namespace already deleted or not found"
echo -e "${GREEN}✓ Namespace deleted${NC}"

# Verify cleanup
echo ""
echo -e "${YELLOW}Verifying cleanup...${NC}"
if kubectl get namespace telepresence-demo &>/dev/null; then
  echo -e "${YELLOW}Warning: Namespace still exists (may take a moment to fully delete)${NC}"
else
  echo -e "${GREEN}✓ All resources cleaned up${NC}"
fi

# Optional: Disconnect telepresence
echo ""
read -p "Do you want to disconnect Telepresence from the cluster? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v telepresence &>/dev/null; then
    telepresence quit
    echo -e "${GREEN}✓ Telepresence disconnected${NC}"
  else
    echo -e "${YELLOW}Telepresence not installed${NC}"
  fi
fi

# Optional: Uninstall traffic manager
echo ""
read -p "Do you want to uninstall the Telepresence Traffic Manager? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v telepresence &>/dev/null; then
    telepresence uninstall --everything
    echo -e "${GREEN}✓ Traffic Manager uninstalled${NC}"
  else
    echo -e "${YELLOW}Telepresence not installed${NC}"
  fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup completed! 🎉${NC}"
echo -e "${GREEN}========================================${NC}"
