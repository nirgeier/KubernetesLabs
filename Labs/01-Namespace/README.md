
# K8S Hands-on



---

# Namespaces

- Kubernetes supports **multiple virtual clusters** backed by the same **physical cluster**.
- These virtual clusters are called `namespaces`.
- `Namespaces` are the default way for Kubernetes to separate resources.
- Using `namespaces` we can isolate the development, improve security and much more.
- Kubernetes clusters has a builtin `namespace` called **default** and might contain more `namespaces`, like `kube-system`, for example.

---


### Pre-Requirements

- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)  
**<kbd>CTRL</kbd> + <kbd>click</kbd> to open in new window**

---

### 01. Create Namespace

```sh
# In this sample `codewizard` is the desired namespace
$ kubectl create namespace codewizard
namespace/codewizard created

### !!! Try to create the following namespace (with _ & -), and see what happens:
$ kubectl create namespace my_namespace-
```

---

### 02. Setting the default Namespace for `kubectl`

- To set the default namespace run:

```sh
$ kubectl config set-context $(kubectl config current-context) --namespace=codewizard

Context minikube modified.
```

---

### 03. Verify that you've updated the namespace

```sh
$ kubectl config get-contexts
CURRENT     NAME                 CLUSTER          AUTHINFO         NAMESPACE
            docker-desktop       docker-desktop   docker-desktop
            docker-for-desktop   docker-desktop   docker-desktop
*           minikube             minikube         minikube         codewizard
```

---

### 0.4 Using the `-n` Flag:

- When using `kubectl` you can pass the `-n` flag in order to execute the `kubectl` command on a desired `namespace`.
- For example:

```sh
# get resources of a specific workspace
$ kubectl get pods -n <namespace>
```
