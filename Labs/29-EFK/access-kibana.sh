#!/bin/bash

# Quick Access Guide for EFK Stack
# This script helps you access Kibana via Ingress

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== EFK Stack - Kibana Access ===${NC}"
echo ""

# Get ingress information
INGRESS_IP=$(kubectl get ingress -n efk kibana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
INGRESS_HOST=$(kubectl get ingress -n efk kibana -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)

if [ -z "$INGRESS_HOST" ]; then
  echo -e "${YELLOW}⚠ Ingress not found. Is the EFK stack deployed?${NC}"
  echo ""
  echo "Deploy the stack first:"
  echo "  ./demo.sh deploy"
  exit 1
fi

echo -e "${GREEN}✓ Ingress Found${NC}"
echo "  Host: $INGRESS_HOST"
echo "  IP: ${INGRESS_IP:-<pending>}"
echo ""

# Check /etc/hosts
if grep -q "$INGRESS_HOST" /etc/hosts; then
  echo -e "${GREEN}✓ /etc/hosts configured${NC}"
  HOSTS_IP=$(grep "$INGRESS_HOST" /etc/hosts | awk '{print $1}' | head -1)
  echo "  Entry: $HOSTS_IP $INGRESS_HOST"
else
  echo -e "${YELLOW}⚠ /etc/hosts not configured${NC}"
  echo ""
  echo "Add the following to /etc/hosts:"
  echo "  ${INGRESS_IP:-192.168.139.2} $INGRESS_HOST"
  echo ""
  echo "Run this command:"
  echo "  echo \"${INGRESS_IP:-192.168.139.2} $INGRESS_HOST\" | sudo tee -a /etc/hosts"
  echo ""
  read -p "Add to /etc/hosts now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "${INGRESS_IP:-192.168.139.2} $INGRESS_HOST" | sudo tee -a /etc/hosts
    echo -e "${GREEN}✓ Added to /etc/hosts${NC}"
  fi
fi

echo ""
echo -e "${BLUE}=== Access Information ===${NC}"
echo ""
echo "Kibana URL:"
echo -e "  ${GREEN}http://$INGRESS_HOST${NC}"
echo ""

# Test connectivity
echo "Testing connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$INGRESS_HOST/api/status 2>/dev/null)

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✓ Kibana is accessible!${NC}"
  echo ""
  echo "Opening Kibana in browser..."
  echo ""

  # Try to open in browser
  if command -v open &>/dev/null; then
    open "http://$INGRESS_HOST"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "http://$INGRESS_HOST"
  else
    echo "Please open http://$INGRESS_HOST in your browser"
  fi

  echo ""
  echo -e "${BLUE}=== Available Dashboards ===${NC}"
  echo "  • Error Analysis Dashboard"
  echo "  • General Logs Dashboard"
  echo ""
  echo "Navigate to 'Dashboard' in the Kibana sidebar to view them."
else
  echo -e "${YELLOW}⚠ Cannot reach Kibana (HTTP $HTTP_CODE)${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check if Kibana pod is running:"
  echo "     kubectl get pods -n efk -l app=kibana"
  echo ""
  echo "  2. Check ingress status:"
  echo "     kubectl describe ingress -n efk kibana"
  echo ""
  echo "  3. Use port-forward as alternative:"
  echo "     kubectl port-forward -n efk svc/kibana 5601:5601"
  echo "     Then open: http://localhost:5601"
fi

echo ""
