---

# Namespaces

- Kubernetes supports **multiple virtual clusters** backed by the same **physical cluster**.
- These virtual clusters are called `namespaces`.
- `Namespaces` are the default way for Kubernetes to separate resources.
- Using `namespaces` we can isolate the development, improve security and much more.
- Kubernetes clusters has a builtin `namespace` called **default** and might contain more `namespaces`, like `kube-system`, for example.

---

## What will we learn?

- How to create a Kubernetes `namespace`
- How to set a default `namespace` for `kubectl`
- How to verify the current namespace configuration
- How to use the `-n` flag to target specific namespaces

---

## Prerequisites

- A running Kubernetes cluster (`kubectl cluster-info` should work)
- `kubectl` configured against the cluster

---

## 01. Create Namespace

```sh
# In this sample `codewizard` is the desired namespace
kubectl create namespace codewizard
namespace/codewizard created

### !!! Try to create the following namespace (with _ & -), and see what happens:
kubectl create namespace my_namespace-
```

---

## 02. Setting the Default Namespace for `kubectl`

- To set the default namespace run:

```sh
kubectl config set-context $(kubectl config current-context) --namespace=codewizard

Context minikube modified.
```

---

## 03. Verify That You've Updated the Namespace

```sh
kubectl config get-contexts
CURRENT     NAME                 CLUSTER          AUTHINFO         NAMESPACE
            docker-desktop       docker-desktop   docker-desktop
            docker-for-desktop   docker-desktop   docker-desktop
*           minikube             minikube         minikube         codewizard
```

---

## 04. Using the `-n` Flag

- When using `kubectl` you can pass the `-n` flag in order to execute the `kubectl` command on a desired `namespace`.
- For example:

```sh
# get resources of a specific namespace
kubectl get pods -n <namespace>
```
