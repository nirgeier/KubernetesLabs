#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
  print_info "Checking prerequisites..."

  if ! command_exists kubectl; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
  fi

  if ! command_exists helm; then
    print_error "helm is not installed. Please install Helm first."
    exit 1
  fi

  # Check if kubectl can connect to cluster
  if ! kubectl cluster-info &>/dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please configure kubectl."
    exit 1
  fi

  print_success "All prerequisites are met!"
}

# Deploy Elasticsearch
deploy_elasticsearch() {
  print_info "Deploying Elasticsearch..."

  helm upgrade --install elasticsearch ./helm/elasticsearch \
    --namespace efk \
    --create-namespace \
    --wait \
    --timeout 5m

  if [ $? -eq 0 ]; then
    print_success "Elasticsearch deployed successfully!"
  else
    print_error "Failed to deploy Elasticsearch"
    exit 1
  fi
}

# Deploy Kibana
deploy_kibana() {
  print_info "Deploying Kibana..."

  helm upgrade --install kibana ./helm/kibana \
    --namespace efk \
    --wait \
    --timeout 5m

  if [ $? -eq 0 ]; then
    print_success "Kibana deployed successfully!"
  else
    print_error "Failed to deploy Kibana"
    exit 1
  fi
}

# Deploy Filebeat
deploy_filebeat() {
  print_info "Deploying Filebeat..."

  helm upgrade --install filebeat ./helm/filebeat \
    --namespace efk \
    --wait \
    --timeout 5m

  if [ $? -eq 0 ]; then
    print_success "Filebeat deployed successfully!"
  else
    print_error "Failed to deploy Filebeat"
    exit 1
  fi
}

# Deploy Log Generator
deploy_log_generator() {
  print_info "Deploying Log Generator..."

  helm upgrade --install log-generator ./helm/log-generator \
    --namespace efk \
    --wait \
    --timeout 5m

  if [ $? -eq 0 ]; then
    print_success "Log Generator deployed successfully!"
  else
    print_error "Failed to deploy Log Generator"
    exit 1
  fi
}

# Deploy Log Processor
deploy_log_processor() {
  print_info "Deploying Log Processor..."

  helm upgrade --install log-processor ./helm/log-processor \
    --namespace efk \
    --wait \
    --timeout 5m

  if [ $? -eq 0 ]; then
    print_success "Log Processor deployed successfully!"
  else
    print_error "Failed to deploy Log Processor"
    exit 1
  fi
}

# Wait for pods to be ready
wait_for_pods() {
  print_info "Waiting for all pods to be ready..."

  kubectl wait --for=condition=ready pod -l app=elasticsearch -n efk --timeout=300s
  kubectl wait --for=condition=ready pod -l app=kibana -n efk --timeout=300s
  kubectl wait --for=condition=ready pod -l app=filebeat -n efk --timeout=300s
  kubectl wait --for=condition=ready pod -l app=log-generator -n efk --timeout=300s

  print_success "All pods are ready!"
}

# Display access information
display_access_info() {
  echo ""
  echo "=========================================="
  print_success "EFK Stack Deployment Complete!"
  echo "=========================================="
  echo ""

  print_info "Access Information:"
  echo ""

  # Get Kibana ingress information
  KIBANA_HOST=$(kubectl get ingress kibana -n efk -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
  INGRESS_IP=$(kubectl get ingress kibana -n efk -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

  if [ -n "$KIBANA_HOST" ]; then
    echo "  Kibana Ingress URL: ${GREEN}http://$KIBANA_HOST${NC}"
    echo "  Ingress IP: ${INGRESS_IP:-<pending>}"
    echo ""

    # Check if host is in /etc/hosts
    if grep -q "$KIBANA_HOST" /etc/hosts; then
      print_success "/etc/hosts already configured"
    else
      print_warning "Add '$KIBANA_HOST' to your /etc/hosts file:"
      echo "  echo \"${INGRESS_IP:-192.168.139.2} $KIBANA_HOST\" | sudo tee -a /etc/hosts"
      echo ""
    fi

    echo "  Quick access script:"
    echo "  ${BLUE}./access-kibana.sh${NC}"
  else
    echo "  Kibana: Use port-forward to access"
    echo "  kubectl port-forward -n efk svc/kibana 5601:5601"
    echo "  Then access: http://localhost:5601"
  fi

  echo ""
  print_info "Useful Commands:"
  echo "  # View all pods"
  echo "  kubectl get pods -n efk"
  echo ""
  echo "  # View logs from log generator"
  echo "  kubectl logs -n efk -l app=log-generator --tail=20"
  echo ""
  echo "  # View Filebeat logs (writing to files)"
  echo "  kubectl logs -n efk -l app=filebeat --tail=50"
  echo ""
  echo "  # View Log Processor jobs"
  echo "  kubectl get jobs -n efk -l app=log-processor"
  echo ""
  echo "  # View Log Processor CronJob"
  echo "  kubectl get cronjob -n efk"
  echo ""
  echo "  # Check files in shared folder"
  echo "  kubectl exec -n efk -l app=filebeat -- ls -lh /filebeat-logs"
  echo ""
  echo "  # Check Elasticsearch indices"
  echo "  kubectl exec -n efk elasticsearch-0 -- curl -s http://localhost:9200/_cat/indices?v"
  echo ""

  print_info "Architecture:"
  echo "  1. Filebeat collects logs and writes to /filebeat-logs (PVC)"
  echo "  2. Log Processor Job reads from /filebeat-logs and sends to Elasticsearch"
  echo "  3. CronJob runs every 2 minutes to process new logs"
  echo "  4. Original files are KEPT for debugging (dual output)"
  echo ""

  print_info "Monitoring:"
  echo "  Run the monitoring script to check the entire pipeline:"
  echo "  ./monitor.sh           # Interactive mode"
  echo "  ./monitor.sh summary   # Quick summary"
  echo "  ./monitor.sh test      # Test pipeline flow"
  echo "  ./monitor.sh full      # Full detailed report"
  echo ""

  print_info "Dashboards:"
  echo "  Dashboards are automatically imported by the Kibana chart!"
  echo "  Available dashboards:"
  echo "    - Error Analysis Dashboard (ERROR level logs)"
  echo "    - General Logs Dashboard (All logs overview)"
  echo "    - Warning Analysis Dashboard"
  echo "    - Component Activity Dashboard"
  echo "    - Performance Overview Dashboard"
  echo "    - HTTP Access Dashboard"
  echo "    - K8s Monitoring Dashboard"
  echo "    - APM Dashboard"
  echo ""
  echo "  If dashboards show 'Could not find data view', run:"
  echo "  ${BLUE}./fix-kibana.sh${NC}"
  echo ""
  print_info "Next Steps:"
  echo "  1. Access Kibana using the URL above"
  echo "  2. Navigate to 'Dashboard' in the sidebar"
  echo "  3. View 'Error Analysis Dashboard' or 'General Logs Dashboard'"
  echo "  4. If no data visible, hard refresh browser (Cmd+Shift+R)"
  echo ""
}

# Cleanup function
cleanup() {
  print_warning "Cleaning up EFK stack..."

  helm uninstall log-processor -n efk 2>/dev/null
  helm uninstall log-generator -n efk 2>/dev/null
  helm uninstall filebeat -n efk 2>/dev/null
  helm uninstall kibana -n efk 2>/dev/null
  helm uninstall elasticsearch -n efk 2>/dev/null

  # Delete any remaining jobs
  kubectl delete jobs -n efk -l app=log-processor 2>/dev/null
  kubectl delete jobs -n efk -l app=kibana-dashboard-importer 2>/dev/null

  kubectl delete namespace efk 2>/dev/null

  print_success "Cleanup complete!"
}

# Main deployment function
deploy() {
  print_info "Starting EFK Stack Deployment..."
  echo ""

  check_prerequisites
  echo ""

  deploy_elasticsearch
  echo ""

  # Wait for Elasticsearch to be ready before deploying Kibana
  print_info "Waiting for Elasticsearch to be fully ready..."
  sleep 30

  deploy_kibana
  echo ""

  deploy_filebeat
  echo ""

  deploy_log_generator
  echo ""

  deploy_log_processor
  echo ""

  wait_for_pods

  # Wait for initial log processor job to complete
  print_info "Waiting for initial log processor job to process logs..."
  echo "  This ensures dashboards will have data to display"

  # Wait up to 10 minutes for job to complete
  kubectl wait --for=condition=complete --timeout=600s -n efk job/log-processor-initial 2>/dev/null || {
    print_warning "Initial job still running, continuing anyway..."
  }

  # Give it a few more seconds to ensure data is indexed
  sleep 10

  # Check if we have data in Elasticsearch
  DOC_COUNT=$(kubectl exec -n efk elasticsearch-0 -- curl -s 'http://localhost:9200/filebeat-*/_count' 2>/dev/null | grep -o '"count":[0-9]*' | cut -d: -f2 || echo "0")
  if [ "$DOC_COUNT" -gt 0 ]; then
    print_success "Found $DOC_COUNT documents in Elasticsearch"
  else
    print_warning "No data in Elasticsearch yet - dashboards may need manual refresh later"
  fi
  echo ""

  display_access_info
}

# Parse command line arguments
case "${1}" in
deploy)
  deploy
  ;;
cleanup)
  cleanup
  ;;
*)
  echo "Usage: $0 {deploy|cleanup}"
  echo ""
  echo "Commands:"
  echo "  deploy  - Deploy the complete EFK stack"
  echo "  cleanup - Remove the EFK stack and all resources"
  exit 1
  ;;
esac
