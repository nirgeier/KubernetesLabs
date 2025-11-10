#!/bin/bash

# Step 1: Install Istio using istioctl
echo "Installing Istio..."
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

# Step 2: Install Kiali using Helm
echo "Installing Kiali..."
helm repo add kiali https://kiali.org/helm-charts
helm repo update
helm install kiali-server kiali/kiali-server --namespace istio-system --set auth.strategy="anonymous"
helm install                  \
  --namespace kiali-operator  \
  --create-namespace          \
  kiali-operator              \
  kiali/kiali-operator


# Step 3: Enable Istio sidecar injection for all namespaces
echo "Enabling Istio sidecar injection for default namespace..."
kubectl label namespace default istio-injection=enabled
kubectl label namespace codewizard istio-injection=enabled
kubectl label namespace monitoring istio-injection=enabled


# Step 4: Deploy the Bookinfo demo application
echo "Deploying Bookinfo sample app..."
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Step 5: Expose the Bookinfo app through Istio gateway
echo "Exposing Bookinfo app through Istio gateway..."
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

# Step 6: Apply VirtualService to route traffic to v2 of ratings
echo "Creating VirtualService for ratings..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-vs
  namespace: default
spec:
  hosts:
    - ratings
  http:
    - route:
        - destination:
            host: ratings
            subset: v2
EOF
cat <<EOF | kubectl apply -f -
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  namespace: istio-system
  name: kiali
spec:
  istio_namespace: istio-system
  auth:
    strategy: anonymous
  deployment:
    view_only_mode: true
  external_services:
    prometheus:
      url: http://prometheus-operated:9090
EOF

sleep 10

# Step 7: Deploy addons
echo "Deploying Istio addons..."
kubectl apply -f samples/addons


# Step 8: Port-forward Kiali for access
echo "Port forwarding Kiali to http://localhost:20001..."
kubectl port-forward -n istio-system svc/kiali 20001:20001 &

echo "Installation complete. Access Kiali at http://localhost:20001."


cat << EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: mtls-strict
  namespace: default
spec:
  mtls:
    mode: STRICT
EOF

cat << EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: mtls-destination-rule
  namespace: default
spec:
  host: "*.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF