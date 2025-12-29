
# K8S Hands-on


---

# Pod Disruption Budgets (PDB)
- In this lab, we will learn about `Pod Disruption Budgets (PDB)` in Kubernetes.
- We will explore how to define and implement PDBs to ensure application availability during voluntary disruptions, such as node maintenance or cluster upgrades.
- By the end of this lab, you will understand how to create and manage Pod Disruption Budgets to maintain the desired level of service availability in your Kubernetes cluster.

---

<!-- omit in toc -->
## Pre requirements

- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

### **<kbd>CTRL</kbd> + click to open in new window**

<!-- omit in toc -->
---

## `PodDisruptionBudgets`: Budgeting the Number of Faults to Tolerate

- A `pod disruption budget` is an **indicator of the number of disruptions that can be tolerated at a given time for a class of pods** (a budget of faults).

- Disruptions may be caused by **deliberate** or **accidental** Pod deletion.
- Whenever a disruption to the pods in a service is calculated to cause the service to **drop below the budget**, the operation is paused until it can maintain the budget. This means that the `drain event` could be temporarily halted while it waits for more pods to become available such that the budget isn’t crossed by evicting the pods.

- You can specify Pod Disruption Budgets for Pods managed by these built-in Kubernetes controllers:

    - `Deployment`
    - `ReplicationController`
    - `ReplicaSet`
    - `StatefulSet`

- For this tutorial you should get familier with [**Kubernetes Eviction Policies**](https://kubernetes.io/docs/concepts/scheduling-eviction/), as it demonstrates how `Pod Disruption Budgets` handle evictions.

- As in the `Kubernetes Eviction Policies` tutorial, we start with 
```sh
eviction-hard="memory.available<480M"
```

---

### Sample
- In the below sample we will configure a `Pod Disruption Budget` which insure that we will always have **at least** 1 Nginx instance.

- First we need an [Nginx Deployment](./resources/Deployment.yaml):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: codewizard
  labels:
    app: nginx # <- We will use this name below
...
```

- Now we can create the `Pod Disruption Budget`:

```yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
spec:
  minAvailable: 1 # <--- This will insure that we will have at least 1
  selector:
    matchLabels:
      app: nginx # <- The deployment app label 
```      

---
## Walkthrough

[01. start minikube with Feature Gates](#01-start-minikube-with-feature-gates)

[02. Check Node Pressure(s)](#02-check-node-pressure)

---
### Step 01 - Start minikube with Feature Gates

- Run thwe following command to start minikube with the required `Feature Gates` and `Eviction Signals`:

```sh
minikube start \
    --extra-config=kubelet.eviction-hard="memory.available<480M" \
    --extra-config=kubelet.eviction-pressure-transition-period="30s" \
    --extra-config=kubelet.feature-gates="ExperimentalCriticalPodAnnotation=true"
```

- For more details about `Feature Gates`, read [here](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/#feature-stages).

- For more details about `eviction-signals`, read [here](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/#eviction-signals).

### Step 02 - Check Node Pressure(s)

- Check to see the Node conditions, if we have any kind of "Pressure", by running the following:

```sh
kubectl describe node minikube | grep MemoryPressure

# Output should be similar to :
Conditions:
  Type             Status  Reason                       Message
  ----             ------  ------                       -------
  MemoryPressure   False   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    KubeletReady                 kubelet is posting ready status. AppArmor enabled
  ...
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests    Limits
  --------           --------    ------
  cpu                750m (37%)  0 (0%)
  memory             140Mi (6%)  340Mi (16%)
  ephemeral-storage  0 (0%)      0 (0%)  
```

### Step 03 - Create 3 Pods using 50 MB each

- Create a file named `50MB-ram.yaml` with the following content:

```yaml
# ./resources/50MB-ram.yaml
...

# 3 replicas
spec:
  replicas: 3

# resources request and limits
resources:
  requests:
    memory: "50Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

- Create the pods with the following command:

```sh
kubectl apply -f resources/50MB-ram.yaml
```

### Step 04 - Check Memory Pressure

- Now let's check the Node conditions again to see if we have `MemoryPressure`:

```sh
$ kubectl describe node minikube | grep MemoryPressure

# Output should be similar to 
MemoryPressure   False   ...   KubeletHasSufficientMemory   kubelet has sufficient memory available
```
- As we can see, we still have `sufficient memory available`.