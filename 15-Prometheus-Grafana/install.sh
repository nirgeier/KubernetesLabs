#!/bin/bash

# Step 1: Add Helm Repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Step 2: Install Prometheus Stack
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# Step 3: Install Grafana
helm install grafana grafana/grafana --namespace monitoring

# Step 4: Wait for Prometheus and Grafana to be deployed
echo "Waiting for Prometheus and Grafana to be deployed..."
kubectl rollout status deployment/prometheus-operated -n monitoring
kubectl rollout status deployment/grafana -n monitoring

# Step 5: Get Grafana Admin Password
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode)

# Step 6: Port-forward Grafana
echo "Grafana is ready. Port forwarding to localhost:3000..."
kubectl port-forward --namespace monitoring service/grafana 3000:80 &

# Step 7: Output Grafana credentials
echo "Grafana URL: http://localhost:3000"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"

# Optional: Print instructions for manual steps
echo "To configure Grafana and Prometheus, please follow the instructions provided in the guide."

kubectl port-forward --namespace monitoring svc/prometheus-operated 9090:9090 &
