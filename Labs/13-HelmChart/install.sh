#!/bin/sh

helm uninstall charts-demo
helm package codewizard-nginx-helm
helm install charts-demo codewizard-helm-demo-0.1.0.tgz
clear
kubectl get all --all-namespaces
kubectl run --image=busybox b1 --rm -it --restart=Never -- /bin/sh -c "wget -qO- http://charts-demo-codewizard-helm-demo.codewizard.svc.cluster.local"
