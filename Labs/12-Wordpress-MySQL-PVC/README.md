---

# WordPress, MySQL, PVC

- In this lab you will deploy a WordPress site and a MySQL database.
- You will use `PersistentVolumes` and `PersistentVolumeClaims` as storage.

---

## What will we learn?

- How to deploy a multi-tier application (WordPress + MySQL) on Kubernetes
- How to use `PersistentVolumeClaims` for persistent storage
- How to use `kustomization.yaml` with secret generators
- How to use port forwarding to test applications locally

---

## Prerequisites

- A running Kubernetes cluster (`kubectl cluster-info` should work)
- `kubectl` configured against the cluster
- Minikube (for LoadBalancer support)

---

## Walkthrough

- Patch `minikube` so we can use `Service: LoadBalancer`

```sh
# Source:
# https://github.com/knative/serving/blob/b31d96e03bfa1752031d0bc4ae2a3a00744d6cd5/docs/creating-a-kubernetes-cluster.md#loadbalancer-support-in-minikube

sudo ip route add \
    $(cat ~/.minikube/profiles/minikube/config.json | \
    jq -r ".KubernetesConfig.ServiceCIDR") \
    via $(minikube ip)

kubectl run minikube-lb-patch \
    --replicas=1 \
    --image=elsonrodriguez/minikube-lb-patch:0.1 \
    --namespace=kube-system
```

- Create the desired `Namespace`
- Create the `MySQL` resources:
    - Create `Service`
    - Create `PersistentVolumeClaims`
    - Create `Deployment`
    - Create `password file`
- Create the WordPress resources:
    - Create `Service`
    - Create `PersistentVolumeClaims`
    - Create `Deployment`
- Create a `kustomization.yaml` with:
    - `Secret generator`
    - `MySQL` resources
    - `WordPress` resources
- Deploy the stack
- Port forward from the host to the application
- We use a port forward so we will be able to test and verify if the WordPress is actually running:

```sh
kubectl port-forward service/wordpress 8080:32267 -n wp-demo
```

---

## Cleanup

```sh
kubectl delete namespace wp-demo
```
