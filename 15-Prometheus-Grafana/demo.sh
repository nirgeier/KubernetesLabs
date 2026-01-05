#!/bin/bash

#set -x

export CLUSTER_NAME=prometheus-cluster
export PROMETHEUS_NS=prometheus-stack

# Install kind if not already installed
# eval "$(/opt/homebrew/bin/brew shellenv)"
# brew install kind derailed/k9s/k9s

## Add helm charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create the demo folder
rm -rf demo
mkdir -p demo
cd demo

# Create the cluster.yaml
# cat << EOF > cluster.yaml
# ###
# ### Auto Generated file from the script.
# ### Do not edit !!!
# ###
# ###
# apiVersion: kind.x-k8s.io/v1alpha4
# kind: Cluster
# nodes:
# - role: control-plane
#   kubeadmConfigPatches:
#   - |
#     kind: InitConfiguration
#     nodeRegistration:
#       kubeletExtraArgs:
#         #
#         # node-labels:
#         #               only allow the ingress controller to run on a 
#         #               specific node(s) matching the label selector
#         #
#         node-labels: "ingress-ready=true"
#   #
#   # extraPortMappings:
#   #                     allow the local host to make requests to the 
#   #                     Ingress controller over ports 80/443
#   #      
#   extraPortMappings:
#   - containerPort: 80
#     hostPort: 8080
#     protocol: TCP
#   - containerPort: 443
#     hostPort: 6443
#     protocol: TCP
# - role: worker
# - role: worker
# EOF

# # Delete old cluster
# kind    delete                      \
#         cluster                     \
#         --name      $CLUSTER_NAME   

# # Start the cluster
# kind    create                      \
#         cluster                     \
#         --name      $CLUSTER_NAME   \
#         --config    ./cluster.yaml

# # Wait for nodes 
# kubectl wait node               \
#         --all                   \
#         --for condition=ready   \
#         --timeout=600s

# Verify that the cluster is running
kubectl get nodes -o wide
kind get clusters

# Insatll prometeus
kubectl delete ns $PROMETHEUS_NS
kubectl create ns $PROMETHEUS_NS

# Swicth to the new namespace as default namespace
kubectl     config \
            set-context $(kubectl config current-context) \
            --namespace=$PROMETHEUS_NS

###
### Install prometheus
###

###  Install prometheus-stack 
helm    install                                     \
        prometheus-stack                            \
        prometheus-community/kube-prometheus-stack    

### Check the installation
kubectl get \
        pods -l "release=prometheus-stack"      \
        -n $PROMETHEUS_NS

kubectl wait \
        pod -l "release=prometheus-stack"       \
        --for=condition=ready                   \
        -n $PROMETHEUS_NS

## Open the Grafan ports
kubectl     port-forward                \
            svc/$PROMETHEUS_NS-grafana  \
            -n $PROMETHEUS_NS           \
            3000:80 &

kubectl     port-forward                \
            svc/$PROMETHEUS_NS-kube-prom-prometheus  \
            -n $PROMETHEUS_NS           \
            9090:9090 &

# Extract the values of the secret
export GRAFANA_USER_NAME=$(kubectl get secret                              \
        prometheus-stack-grafana                \
        -o jsonpath='{.data.admin-user}'        \
        | base64 -d)

export GRAFANA_PASSWORD=$(kubectl get secret                              \
        prometheus-stack-grafana                \
        -o jsonpath='{.data.admin-password}'    \
        | base64 -d)  

echo ''
echo ''
echo 'User    : ' $GRAFANA_USER_NAME
echo 'Password: ' $GRAFANA_PASSWORD
echo ''
echo ''

            