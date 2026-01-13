#!/bin/bash
NAMESPACE=demo-fluentbit

echo "Cleaning up Lab 30 resources..."

# Kill background port-forwards
echo "Stopping port-forwards..."
pkill -f "port-forward.*$NAMESPACE" || true
pkill -f "port-forward.*svc/kibana" || true
pkill -f "port-forward.*svc/elasticsearch" || true
rm -f /tmp/kuberneteslabs-efk-demo/port-forward.pids || true

# Uninstall Helm charts
if helm status elasticsearch -n $NAMESPACE >/dev/null 2>&1; then
  echo "Uninstalling Elasticsearch..."
  helm uninstall elasticsearch -n $NAMESPACE --wait --timeout=60s || true
fi

if helm status kibana -n $NAMESPACE >/dev/null 2>&1; then
  echo "Uninstalling Kibana..."
  helm uninstall kibana -n $NAMESPACE --wait --timeout=60s || true
fi

# Delete namespace
if kubectl get ns $NAMESPACE >/dev/null 2>&1; then
  echo "Deleting namespace $NAMESPACE..."
  kubectl delete ns $NAMESPACE --timeout=60s || true
fi

echo "Cleanup complete."
