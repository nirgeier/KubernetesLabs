#!/bin/bash

# Quick Start Script for Telepresence Demo
# This script helps you quickly start intercepting

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Telepresence Quick Start${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if telepresence is connected
if ! telepresence status &>/dev/null; then
  echo -e "${YELLOW}Connecting to cluster...${NC}"
  telepresence connect
  echo -e "${GREEN}✓ Connected${NC}"
else
  echo -e "${GREEN}✓ Already connected${NC}"
fi

echo ""
echo -e "${YELLOW}Available services in telepresence-demo:${NC}"
telepresence list --namespace telepresence-demo

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ready to intercept!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To intercept the backend service:"
echo ""
echo "1. Navigate to the backend app directory:"
echo -e "   ${GREEN}cd resources/backend-app${NC}"
echo ""
echo "2. Set up Python environment (first time only):"
echo -e "   ${GREEN}python3 -m venv venv${NC}"
echo -e "   ${GREEN}source venv/bin/activate${NC}"
echo -e "   ${GREEN}pip install -r requirements.txt${NC}"
echo ""
echo "3. Start the intercept:"
echo -e "   ${GREEN}telepresence intercept backend --port 5000 --namespace telepresence-demo${NC}"
echo ""
echo "4. Run the application locally:"
echo -e "   ${GREEN}python app.py${NC}"
echo ""
echo "5. Test your changes:"
echo -e "   ${GREEN}kubectl port-forward -n telepresence-demo svc/frontend 8080:80${NC}"
echo "   Then open http://localhost:8080 in your browser"
echo ""
echo "6. When done, leave the intercept:"
echo -e "   ${GREEN}telepresence leave backend${NC}"
echo ""
