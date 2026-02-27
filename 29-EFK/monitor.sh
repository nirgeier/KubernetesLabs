#!/bin/bash

# EFK Stack Monitoring Script
# This script provides comprehensive monitoring of the EFK stack with file-based log processing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Namespace
NAMESPACE="efk"

# Function to print colored output
print_header() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}========================================${NC}"
}

print_section() {
  echo ""
  echo -e "${BLUE}--- $1 ---${NC}"
}

print_info() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_value() {
  echo -e "  ${MAGENTA}$1:${NC} $2"
}

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
  if ! command_exists kubectl; then
    print_error "kubectl is not installed"
    exit 1
  fi
  
  if ! kubectl cluster-info &>/dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
  fi
  
  print_info "Connected to Kubernetes cluster"
}

# Check pod status
check_pods() {
  print_header "POD STATUS"
  
  echo ""
  kubectl get pods -n $NAMESPACE -o wide
  
  echo ""
  print_section "Pod Health Summary"
  
  # Elasticsearch
  ES_STATUS=$(kubectl get pods -n $NAMESPACE -l app=elasticsearch -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ "$ES_STATUS" = "Running" ]; then
    print_info "Elasticsearch: Running"
  else
    print_error "Elasticsearch: $ES_STATUS"
  fi
  
  # Kibana
  KIBANA_STATUS=$(kubectl get pods -n $NAMESPACE -l app=kibana -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ "$KIBANA_STATUS" = "Running" ]; then
    print_info "Kibana: Running"
  else
    print_error "Kibana: $KIBANA_STATUS"
  fi
  
  # Filebeat
  FILEBEAT_READY=$(kubectl get daemonset -n $NAMESPACE filebeat -o jsonpath='{.status.numberReady}' 2>/dev/null)
  FILEBEAT_DESIRED=$(kubectl get daemonset -n $NAMESPACE filebeat -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
  if [ "$FILEBEAT_READY" = "$FILEBEAT_DESIRED" ]; then
    print_info "Filebeat: $FILEBEAT_READY/$FILEBEAT_DESIRED pods ready"
  else
    print_warning "Filebeat: $FILEBEAT_READY/$FILEBEAT_DESIRED pods ready"
  fi
  
  # Log Generator
  LOG_GEN_READY=$(kubectl get deployment -n $NAMESPACE log-generator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  LOG_GEN_DESIRED=$(kubectl get deployment -n $NAMESPACE log-generator -o jsonpath='{.spec.replicas}' 2>/dev/null)
  if [ "$LOG_GEN_READY" = "$LOG_GEN_DESIRED" ]; then
    print_info "Log Generator: $LOG_GEN_READY/$LOG_GEN_DESIRED pods ready"
  else
    print_warning "Log Generator: $LOG_GEN_READY/$LOG_GEN_DESIRED pods ready"
  fi
}

# Check log collection (Filebeat)
check_log_collection() {
  print_header "LOG COLLECTION (Filebeat → Files)"
  
  print_section "Filebeat Configuration"
  FILEBEAT_POD=$(kubectl get pods -n $NAMESPACE -l app=filebeat -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -n "$FILEBEAT_POD" ]; then
    print_info "Filebeat pod: $FILEBEAT_POD"
    
    print_section "Log Files in Shared Storage"
    echo ""
    kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'ls -lh /filebeat-logs/ 2>/dev/null | head -20' 2>/dev/null || echo "  No files found or cannot access"
    
    print_section "File Count"
    FILE_COUNT=$(kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'ls /filebeat-logs/filebeat* 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
    print_value "Active log files" "$FILE_COUNT"
    
    print_section "Sample Log Content (First 3 lines)"
    echo ""
    kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'head -n 3 /filebeat-logs/filebeat 2>/dev/null' 2>/dev/null || echo "  Cannot read log file"
    
    print_section "Storage Usage"
    kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'df -h /filebeat-logs 2>/dev/null' 2>/dev/null || echo "  Cannot check storage"
  else
    print_error "No Filebeat pod found"
  fi
}

# Check log processing
check_log_processing() {
  print_header "LOG PROCESSING (Files → Elasticsearch)"
  
  print_section "CronJob Status"
  kubectl get cronjob -n $NAMESPACE log-processor 2>/dev/null || print_error "CronJob not found"
  
  print_section "Recent Jobs (Last 5)"
  echo ""
  kubectl get jobs -n $NAMESPACE -l app=log-processor --sort-by=.metadata.creationTimestamp 2>/dev/null | tail -6
  
  print_section "Latest Job Log (Last 20 lines)"
  LATEST_JOB=$(kubectl get jobs -n $NAMESPACE -l app=log-processor --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null)
  if [ -n "$LATEST_JOB" ]; then
    echo ""
    print_info "Job: $LATEST_JOB"
    echo ""
    kubectl logs -n $NAMESPACE job/$LATEST_JOB --tail=20 2>/dev/null || echo "  Cannot get logs"
  else
    print_warning "No jobs found yet"
  fi
  
  # Check processed files
  print_section "Processed Files Tracking"
  FILEBEAT_POD=$(kubectl get pods -n $NAMESPACE -l app=filebeat -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$FILEBEAT_POD" ]; then
    PROCESSED_COUNT=$(kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'ls /filebeat-logs/processed/*.processed 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
    BACKUP_COUNT=$(kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'ls /filebeat-logs/processed/*.backup 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
    print_value "Processed markers" "$PROCESSED_COUNT"
    print_value "Backup copies" "$BACKUP_COUNT"
  fi
}

# Check Elasticsearch
check_elasticsearch() {
  print_header "ELASTICSEARCH INDICES & DATA"
  
  ES_POD="elasticsearch-0"
  
  print_section "Cluster Health"
  kubectl exec -n $NAMESPACE $ES_POD -- curl -s http://localhost:9200/_cluster/health?pretty 2>/dev/null | grep -E '(status|number_of_nodes|active_primary_shards)' || print_error "Cannot connect to Elasticsearch"
  
  print_section "Indices"
  echo ""
  kubectl exec -n $NAMESPACE $ES_POD -- curl -s http://localhost:9200/_cat/indices?v 2>/dev/null | grep -E '(health|filebeat)' || echo "  No indices found"
  
  print_section "Document Count"
  DOC_COUNT=$(kubectl exec -n $NAMESPACE $ES_POD -- curl -s http://localhost:9200/filebeat-*/_count 2>/dev/null | grep -o '"count":[0-9]*' | cut -d: -f2)
  if [ -n "$DOC_COUNT" ]; then
    print_value "Total documents in filebeat-* indices" "$DOC_COUNT"
  else
    print_warning "No documents found or cannot query"
  fi
  
  print_section "Latest Documents (Sample)"
  echo ""
  kubectl exec -n $NAMESPACE $ES_POD -- curl -s "http://localhost:9200/filebeat-*/_search?size=3&sort=@timestamp:desc&pretty" 2>/dev/null | grep -A 10 '"_source"' | head -30 || echo "  Cannot retrieve documents"
}

# Check Kibana
check_kibana() {
  print_header "KIBANA ACCESS"
  
  KIBANA_POD=$(kubectl get pods -n $NAMESPACE -l app=kibana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -n "$KIBANA_POD" ]; then
    print_info "Kibana pod: $KIBANA_POD"
    
    # Check for ingress
    INGRESS_HOST=$(kubectl get ingress -n $NAMESPACE kibana -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
    if [ -n "$INGRESS_HOST" ]; then
      print_section "Access via Ingress"
      print_value "URL" "http://$INGRESS_HOST"
      print_warning "Make sure '$INGRESS_HOST' is in your /etc/hosts file"
    else
      print_section "Access via Port Forward"
      print_info "Run: kubectl port-forward -n $NAMESPACE svc/kibana 5601:5601"
      print_info "Then access: http://localhost:5601"
    fi
  else
    print_error "Kibana pod not found"
  fi
}

# Check log generation
check_log_generation() {
  print_header "LOG GENERATION"
  
  print_section "Log Generator Pods"
  LOG_GEN_PODS=$(kubectl get pods -n $NAMESPACE -l app=log-generator -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  if [ -n "$LOG_GEN_PODS" ]; then
    for pod in $LOG_GEN_PODS; do
      print_info "Pod: $pod"
    done
    
    print_section "Recent Logs (Last 10 lines from first pod)"
    FIRST_POD=$(echo $LOG_GEN_PODS | awk '{print $1}')
    echo ""
    kubectl logs -n $NAMESPACE $FIRST_POD --tail=10 2>/dev/null || echo "  Cannot get logs"
  else
    print_error "No log generator pods found"
  fi
}

# Pipeline flow test
test_pipeline() {
  print_header "PIPELINE FLOW TEST"
  
  print_section "Step 1: Check Log Generation"
  LOG_GEN_PODS=$(kubectl get pods -n $NAMESPACE -l app=log-generator --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [ "$LOG_GEN_PODS" -gt 0 ]; then
    print_info "$LOG_GEN_PODS log generator pod(s) running"
  else
    print_error "No log generator pods"
  fi
  
  print_section "Step 2: Check Filebeat Collection"
  FILEBEAT_PODS=$(kubectl get daemonset -n $NAMESPACE filebeat -o jsonpath='{.status.numberReady}' 2>/dev/null)
  if [ "$FILEBEAT_PODS" -gt 0 ]; then
    print_info "$FILEBEAT_PODS Filebeat pod(s) collecting logs"
  else
    print_error "No Filebeat pods ready"
  fi
  
  print_section "Step 3: Check File Storage"
  FILEBEAT_POD=$(kubectl get pods -n $NAMESPACE -l app=filebeat -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$FILEBEAT_POD" ]; then
    FILE_COUNT=$(kubectl exec -n $NAMESPACE $FILEBEAT_POD -- sh -c 'ls /filebeat-logs/filebeat* 2>/dev/null | wc -l' 2>/dev/null | tr -d ' ')
    if [ "$FILE_COUNT" -gt 0 ]; then
      print_info "$FILE_COUNT log file(s) in storage"
    else
      print_warning "No log files found in storage"
    fi
  fi
  
  print_section "Step 4: Check Log Processing Jobs"
  COMPLETED_JOBS=$(kubectl get jobs -n $NAMESPACE -l app=log-processor -o jsonpath='{.items[?(@.status.succeeded>0)].metadata.name}' 2>/dev/null | wc -w | tr -d ' ')
  if [ "$COMPLETED_JOBS" -gt 0 ]; then
    print_info "$COMPLETED_JOBS completed processing job(s)"
  else
    print_warning "No completed jobs yet"
  fi
  
  print_section "Step 5: Check Elasticsearch Ingestion"
  ES_POD="elasticsearch-0"
  DOC_COUNT=$(kubectl exec -n $NAMESPACE $ES_POD -- curl -s http://localhost:9200/filebeat-*/_count 2>/dev/null | grep -o '"count":[0-9]*' | cut -d: -f2)
  if [ -n "$DOC_COUNT" ] && [ "$DOC_COUNT" -gt 0 ]; then
    print_info "$DOC_COUNT document(s) in Elasticsearch"
  else
    print_warning "No documents in Elasticsearch yet"
  fi
  
  print_section "Step 6: Check Kibana Availability"
  KIBANA_READY=$(kubectl get pods -n $NAMESPACE -l app=kibana -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  if [ "$KIBANA_READY" = "true" ]; then
    print_info "Kibana is ready for visualization"
  else
    print_warning "Kibana is not ready"
  fi
  
  echo ""
  print_header "PIPELINE STATUS: $([ $? -eq 0 ] && echo 'OPERATIONAL' || echo 'CHECK WARNINGS')"
}

# Summary
show_summary() {
  print_header "QUICK SUMMARY"
  
  echo ""
  print_section "Component Status"
  
  # Get all statuses
  ES_STATUS=$(kubectl get pods -n $NAMESPACE -l app=elasticsearch -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  KIBANA_STATUS=$(kubectl get pods -n $NAMESPACE -l app=kibana -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  FILEBEAT_COUNT=$(kubectl get daemonset -n $NAMESPACE filebeat -o jsonpath='{.status.numberReady}' 2>/dev/null)
  LOG_GEN_COUNT=$(kubectl get deployment -n $NAMESPACE log-generator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  JOB_COUNT=$(kubectl get jobs -n $NAMESPACE -l app=log-processor -o jsonpath='{.items[?(@.status.succeeded>0)].metadata.name}' 2>/dev/null | wc -w | tr -d ' ')
  DOC_COUNT=$(kubectl exec -n $NAMESPACE elasticsearch-0 -- curl -s http://localhost:9200/filebeat-*/_count 2>/dev/null | grep -o '"count":[0-9]*' | cut -d: -f2)
  
  print_value "Elasticsearch" "${ES_STATUS:-Unknown}"
  print_value "Kibana" "${KIBANA_STATUS:-Unknown}"
  print_value "Filebeat pods" "${FILEBEAT_COUNT:-0}"
  print_value "Log Generator pods" "${LOG_GEN_COUNT:-0}"
  print_value "Completed jobs" "${JOB_COUNT:-0}"
  print_value "Documents in ES" "${DOC_COUNT:-0}"
  
  echo ""
  print_section "Useful Commands"
  echo "  # Watch pods"
  echo "  watch kubectl get pods -n $NAMESPACE"
  echo ""
  echo "  # Tail log generator"
  echo "  kubectl logs -n $NAMESPACE -l app=log-generator -f"
  echo ""
  echo "  # Trigger manual processing"
  echo "  kubectl create job -n $NAMESPACE --from=cronjob/log-processor manual-\$(date +%s)"
  echo ""
  echo "  # Access Kibana"
  echo "  kubectl port-forward -n $NAMESPACE svc/kibana 5601:5601"
}

# Main menu
show_menu() {
  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║       EFK Stack Monitoring Menu              ║${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
  echo ""
  echo "  1) Show Summary"
  echo "  2) Check Pods Status"
  echo "  3) Check Log Collection (Filebeat)"
  echo "  4) Check Log Processing (Jobs)"
  echo "  5) Check Elasticsearch"
  echo "  6) Check Kibana"
  echo "  7) Check Log Generation"
  echo "  8) Test Pipeline Flow"
  echo "  9) Full Report (All Checks)"
  echo "  0) Exit"
  echo ""
}

# Main execution
main() {
  clear
  print_header "EFK STACK MONITORING"
  check_prerequisites
  
  if [ "$1" = "full" ] || [ "$1" = "-f" ] || [ "$1" = "--full" ]; then
    show_summary
    check_pods
    check_log_generation
    check_log_collection
    check_log_processing
    check_elasticsearch
    check_kibana
    test_pipeline
    exit 0
  fi
  
  if [ "$1" = "test" ] || [ "$1" = "-t" ] || [ "$1" = "--test" ]; then
    test_pipeline
    exit 0
  fi
  
  if [ "$1" = "summary" ] || [ "$1" = "-s" ] || [ "$1" = "--summary" ]; then
    show_summary
    exit 0
  fi
  
  # Interactive mode
  while true; do
    show_menu
    read -p "Select option: " choice
    
    case $choice in
      1) show_summary ;;
      2) check_pods ;;
      3) check_log_collection ;;
      4) check_log_processing ;;
      5) check_elasticsearch ;;
      6) check_kibana ;;
      7) check_log_generation ;;
      8) test_pipeline ;;
      9)
        show_summary
        check_pods
        check_log_generation
        check_log_collection
        check_log_processing
        check_elasticsearch
        check_kibana
        test_pipeline
        ;;
      0) 
        echo ""
        print_info "Goodbye!"
        echo ""
        exit 0
        ;;
      *) print_error "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
  done
}

# Run main function
main "$@"
