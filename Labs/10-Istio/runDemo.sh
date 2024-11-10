#!/bin/bash

# Print out all messages 
set -x

# Hack to fix GCP console docker problem
# rm -rf ~/.docker

# Make sure minikube is running 
# the script below will check and will start minikube if required
# source ../../scripts/startMinikube.sh 

# Set the desired Istio version to download and install
export ISTIO_VERSION=1.15.0

# Set the Istio home, we will use this home for the installation
export ISTIO_HOME=${PWD}/istio-${ISTIO_VERSION}

# Download Istio with the specific verison
curl -L https://istio.io/downloadIstio | \
      ISTIO_VERSION=$ISTIO_VERSION \
      TARGET_ARCH=arm64 \
      sh -

# Add the cli to the path
export PATH="$PATH:${ISTIO_HOME}/bin"

# Check if our cluster is ready for istio
istioctl x precheck 

# For this installation, we use the demo configuration profile
# Istio support different profiles
istioctl install --set profile=demo -y

# Mark default namespace for istio
kubectl label namespace default istio-injection=enabled

# Verify that the label added
kubectl get ns -l istio-injection=enabled

# install istio addons 
kubectl apply -f ${ISTIO_HOME}/samples/addons/grafana.yaml
kubectl apply -f ${ISTIO_HOME}/samples/httpbin/httpbin.yaml
kubectl apply -f ${ISTIO_HOME}/samples/addons/prometheus.yaml
kubectl apply -f ${ISTIO_HOME}/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f ${ISTIO_HOME}/samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl apply -f ${ISTIO_HOME}/samples/bookinfo/networking/destination-rule-all.yaml

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

# Add the helm chart repo
helm repo add kiali https://kiali.org/helm-charts

# Update the helm chart
helm repo update

# Install kiali server
helm install \
  --namespace   istio-system \
  --set         auth.strategy="anonymous" \
  --repo        https://kiali.org/helm-charts \
  kiali-server \
  kiali-server

# Port forward for kiali gui.
# Extract the Kiali pod name
kubectl port-forward \
        -n istio-system \
        $(kubectl get pods -n istio-system --selector=app=kiali -o jsonpath='{$.items[*].metadata.name}') \
        20001:20001 &

# Enable the ingress addon on minikube
minikube addons enable ingress

# Enable the "LoadBalancer"
minikube tunnel & 

# Get the token from the secret
KIALI_TOKEN=$(kubectl get secret kiali-signing-key -n istio-system -o jsonpath={.data.key} )

echo ($KIALI_TOKEN | base64 -d)/n