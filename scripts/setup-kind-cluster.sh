#!/bin/bash

export CLUSTER_NAME=codewizard-demo-cluster
export DEMO_NS=codewizard

# Install kind if not already installed
eval "$(/opt/homebrew/bin/brew shellenv)"
arch -arm64 brew install kind derailed/k9s/k9s

# Delete old cluster if exists
kind    delete                      \
        cluster                     \
        --name      $CLUSTER_NAME   

# Create the new cluster
cat << EOF |                \
kind  create                \
      cluster               \
      --name  $CLUSTER_NAME \
      --config=-            \
###
### Auto Generated file.
### Do not edit !!!
###
###
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        #
        # node-labels:
        #               only allow the ingress controller to run on a 
        #               specific node(s) matching the label selector
        #
        node-labels: "ingress-ready=true"
  #
  # extraPortMappings:
  #                     allow the local host to make requests to the 
  #                     Ingress controller over ports 80/443
  #      
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF

# Wait for nodes 
kubectl wait node               \
        --all                   \
        --for condition=ready   \
        --timeout=600s

# Verify that the cluster is running
kubectl get nodes -o wide
kind get clusters

# Create namespaces
kubectl delete ns $DEMO_NS
kubectl create ns $DEMO_NS

# Switch to the new namespace as default namespace
kubectl     config \
            set-context $(kubectl config current-context) \
            --namespace=$DEMO_NS
