#!/bin/bash

# start minikube
#minikube start --kubernetes-version=v1.21.2

# start tunnel so we will be able to use LoadBalancer
# bash --rcfile <(minikube tunnel &)
#minikube tunnel &

# Login to docker hub
#docker login 

# Build and push the images
docker-compose build && docker-compose push

# Create the desired resources
kubectl kustomize ./K8S | kubectl apply -f - 

# Set defaulalt namespace
kubectl config set-context --current --namespace codewizard

# Check that the proxy is running
curl -vs $(kubectl get service/proxy-service -o jsonpath="{.spec.clusterIP}")