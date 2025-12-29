
<!-- omit in toc -->
# K8S Hands-on



---

# Node Affinity, Taints, and Tolerations Lab

- In this lab, we will explore Kubernetes mechanisms for controlling Pod placement on Nodes.
- We will learn how to use `Node Affinity`, `Taints`, and `Tolerations` to schedule Pods on specific Nodes based on labels, constraints, and preferences.
- By the end of this lab, you will understand how to control where Pods run in your cluster and how to reserve Nodes for specific workloads.

---

<!-- omit in toc -->
## Pre requirements

- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

### **<kbd>CTRL</kbd> + click to open in new window**

<!-- omit in toc -->
---

## Introduction to Pod Scheduling

Kubernetes provides several mechanisms to control which Nodes your Pods run on:

### Node Affinity

- `Node Affinity` allows us to constrain which Nodes our Pods can be scheduled on based on Node labels.
- It's a more expressive and flexible version of `nodeSelector`.
- There are two types:
  - **`requiredDuringSchedulingIgnoredDuringExecution`**: Hard requirement - Pod will not be scheduled unless the rule is met.
  - **`preferredDuringSchedulingIgnoredDuringExecution`**: Soft preference - Scheduler will try to enforce but will still schedule the Pod if it can't.

### Taints and Tolerations

- `Taints` are applied to Nodes and allow a Node to repel a set of Pods.
- `Tolerations` are applied to Pods and allow (but do not require) Pods to schedule onto Nodes with matching `Taints`.
- `Taints` and `Tolerations` work together to ensure that Pods are not scheduled onto inappropriate Nodes.
- Use cases include:
    - Dedicating Nodes to specific workloads
    - Reserving Nodes with special hardware (GPUs, SSDs)
    - Isolating problematic Pods

---

## Part 01 - Node Affinity

- In this section, we will learn how to use Node `Affinity` to schedule Pods on specific Nodes.

### Step 01 - Label Your Nodes

- First, let's label some Nodes to use with Node `Affinity`:

```bash
# Get list of nodes
kubectl get nodes

# Label a node with environment=production
kubectl label nodes <node-name> environment=production

# Label another node with environment=development
kubectl label nodes <node-name> environment=development

# Verify the labels
kubectl get nodes --show-labels
```

### Step 02 - Create a Pod with Required Node Affinity

- Create a Pod that **must** run on a Node with `environment=production`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-required-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: environment
            operator: In
            values:
            - production
  containers:
  - name: nginx
    image: nginx:latest
```

- Apply the Pod:

```bash
# Create the Pod
kubectl apply -f affinity-required-pod.yaml

# Check which Node the Pod is running on
kubectl get pod affinity-required-pod -o wide

# Verify it's running on the production Node
kubectl describe pod affinity-required-pod | grep Node:
```

### Step 03 - Create a Pod with Preferred Node Affinity

- Create a Pod that **prefers** to run on a Node with `environment=development`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-preferred-pod
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: environment
            operator: In
            values:
            - development
  containers:
  - name: nginx
    image: nginx:latest
```

- Apply the Pod:

```bash
# Create the Pod
kubectl apply -f affinity-preferred-pod.yaml

# Check which Node the Pod is running on
kubectl get pod affinity-preferred-pod -o wide

# This Pod will prefer the development Node but can run elsewhere if needed
```

### Step 04 - Experiment with Node Affinity Operators

- `Node Affinity` supports several operators:

    - **`In`**: Label value is in the list of values
    - **`NotIn`**: Label value is not in the list of values
    - **`Exists`**: Label key exists (value does not matter)
    - **`DoesNotExist`**: Label key does not exist
    - **`Gt`**: Label value is greater than the specified value (numeric comparison)
    - **`Lt`**: Label value is less than the specified value (numeric comparison)

- Example with multiple conditions:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-multiple-conditions
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: environment
            operator: In
            values:
            - production
            - staging
          - key: disk-type
            operator: Exists
  containers:
  - name: nginx
    image: nginx:latest
```

---

## Part 02 - Taints and Tolerations

- In this section, we will learn how to use `Taints` and `Tolerations` to control Pod scheduling.

### Step 01 - Understanding Taint Effects

- `Taints` have three effects:

    - **`NoSchedule`**: Pods without matching `tolerations` will not be scheduled on the Node.
    - **`PreferNoSchedule`**: Scheduler will try to avoid placing Pods without `tolerations`, but it's not guaranteed.
    - **`NoExecute`**: Existing Pods without `tolerations` will be evicted, and new ones won't be scheduled.

### Step 02 - Apply a Taint to a Node

- Let's `taint` a Node to dedicate it for special workloads:

```bash
# Apply a taint to a Node
kubectl taint nodes <node-name> dedicated=special-workload:NoSchedule

# Verify the taint
kubectl describe node <node-name> | grep Taints
```

### Step 03 - Create a Pod Without Toleration

- Let's try to create a Pod without a `toleration`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-without-toleration
spec:
  containers:
  - name: nginx
    image: nginx:latest
```

```bash
# Create the Pod
kubectl apply -f pod-without-toleration.yaml

# Check the Pod status - it should not be scheduled on the tainted Node
kubectl get pod pod-without-toleration -o wide

# If all your Nodes are tainted, the Pod will remain Pending
kubectl describe pod pod-without-toleration
```

### Step 04 - Create a Pod With Toleration

- Now let's create a Pod that tolerates the `taint`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-toleration
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "special-workload"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:latest
```

```bash
# Create the Pod
kubectl apply -f pod-with-toleration.yaml

# This Pod can now be scheduled on the tainted Node
kubectl get pod pod-with-toleration -o wide
```

### Step 05 - Understanding Toleration Operators

- Tolerations support two operators:

    - **`Equal`**: Requires exact match of key, value, and effect
    - **`Exists`**: Only checks for key existence (value is ignored)

- Example with `Exists` operator:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-exists-toleration
spec:
  tolerations:
  - key: "dedicated"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:latest
```

### Step 06 - NoExecute Effect

- The `NoExecute` effect is special - it evicts running Pods:

```bash
# Apply a NoExecute taint
kubectl taint nodes <node-name> maintenance=true:NoExecute

# Any Pods on this Node without matching toleration will be evicted
kubectl get pods -o wide --watch
```

- Let's add a toleration with `tolerationSeconds` to delay eviction:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-delayed-eviction
spec:
  tolerations:
  - key: "maintenance"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
    tolerationSeconds: 300  # Pod will be evicted after 5 minutes
  containers:
  - name: nginx
    image: nginx:latest
```

---

## Part 03 - Combining Affinity, Taints, and Tolerations

- We can combine `Node Affinity` with `Taints` and `Tolerations` for fine-grained control.

### Step 01 - Create a Dedicated Node Pool

- Let's simulate a dedicated Node pool for GPU workloads:

```bash
# Label a Node for GPU workload
kubectl label nodes <node-name> hardware=gpu

# Taint the Node to prevent non-GPU Pods
kubectl taint nodes <node-name> nvidia.com/gpu=true:NoSchedule
```

### Step 02 - Deploy a GPU Workload

- Let's create a Pod that requires GPU Nodes:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: hardware
            operator: In
            values:
            - gpu
  tolerations:
  - key: "nvidia.com/gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: gpu-app
    image: nvidia/cuda:11.0-base
    command: ["nvidia-smi"]
```

```bash
# Apply the Pod
kubectl apply -f gpu-workload.yaml

# Verify it's scheduled on the GPU Node
kubectl get pod gpu-workload -o wide
```

---

## Part 04 - Cleanup and Best Practices

### Step 01 - Remove Taints

```bash
# Remove a taint from a Node (add a minus sign at the end)
kubectl taint nodes <node-name> dedicated=special-workload:NoSchedule-

# Remove all taints with a specific key
kubectl taint nodes <node-name> nvidia.com/gpu-
```

### Step 02 - Remove Labels

```bash
# Remove a label from a Node (add a minus sign at the end)
kubectl label nodes <node-name> environment-
kubectl label nodes <node-name> hardware-
```

### Step 03 - Delete Test Pods

```bash
# Delete all test Pods
kubectl delete pod affinity-required-pod affinity-preferred-pod
kubectl delete pod pod-with-toleration pod-without-toleration
kubectl delete pod gpu-workload
```

---

### Best Practices

1. **Use Node Affinity for preferences**, `Taints/Tolerations` for hard requirements.
2. **Label Nodes consistently** across your cluster (e.g., `node-role`, `hardware-type`, `environment`).
3. **Document your taints** - team members need to know why Nodes are tainted.
4. **Use `PreferNoSchedule`** for soft isolation instead of `NoSchedule` when appropriate.
5. **Combine with Pod Priority** for more sophisticated scheduling strategies.
6. **Test eviction behavior** before using `NoExecute` in production.
7. **Use tolerationSeconds** to gracefully handle Node maintenance.
8. **Monitor unschedulable Pods** - they indicate scheduling constraint conflicts.

---

## Summary

In this lab, you learned:

- How to use **Node Affinity** to schedule Pods on specific Nodes based on labels.
- The difference between `required` and `preferred` affinity rules.
- How to use **Taints** to repel Pods from Nodes.
- How to use **Tolerations** to allow Pods on tainted Nodes.
- The three taint effects: `NoSchedule`, `PreferNoSchedule`, and `NoExecute`.
- How to combine affinity, taints, and tolerations for complex scheduling scenarios.
- Best practices for Pod placement in production clusters.

---

## Additional Resources

- [Kubernetes Node Affinity Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
- [Kubernetes Taints and Tolerations Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)