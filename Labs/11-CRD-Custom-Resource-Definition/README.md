---

# Custom Resource Definitions (CRD)

- `Custom Resource Definitions` (**CRD**) were added to Kubernetes 1.7.
- `CRD` added the ability to define custom objects/resources.
- In this lab we will learn how CRDs extend the Kubernetes API.

---

## What will we learn?

- What a Custom Resource Definition (CRD) is
- How CRDs extend the Kubernetes API
- How custom resources are stored and managed
- How to interact with custom resources using `kubectl`

---

## Prerequisites

- A running Kubernetes cluster (`kubectl cluster-info` should work)
- `kubectl` configured against the cluster

---

## Introduction

### What is a Custom Resource Definition (CRD)?

- A resource is an endpoint in the Kubernetes API that stores a collection of API objects of a certain kind; for example, the builtin pods resource contains a collection of Pod objects.

- A custom resource is an **extension of the Kubernetes API** that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.

- Custom resources can appear and disappear in a running cluster through **dynamic registration**, and cluster admins can update custom resources independently of the cluster itself.

- Once a custom resource is installed, users can create and access its objects using `kubectl`, just as they do for built-in resources like Pods.

- The custom resource created is also stored in the `etcd` cluster with proper replication and lifecycle management.
