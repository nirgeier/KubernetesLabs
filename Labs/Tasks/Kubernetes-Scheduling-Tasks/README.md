# Kubernetes Scheduling Tasks

- Hands-on Kubernetes exercises covering Node Affinity, Pod Affinity, Pod Anti-Affinity, Taints, Tolerations, and Topology Spread Constraints.
- Each task includes a description, scenario, and a detailed solution with step-by-step instructions.
- Practice these tasks to master fine-grained Pod placement and scheduling strategies.

#### Table of Contents

- [01. Label Nodes and Use nodeSelector](#01-label-nodes-and-use-nodeselector)
- [02. Required Node Affinity with Multiple Labels](#02-required-node-affinity-with-multiple-labels)
- [03. Preferred Node Affinity with Weights](#03-preferred-node-affinity-with-weights)
- [04. Pod Anti-Affinity for High Availability](#04-pod-anti-affinity-for-high-availability)
- [05. Pod Affinity to Co-Locate Services](#05-pod-affinity-to-co-locate-services)
- [06. Taint a Node and Add a Toleration](#06-taint-a-node-and-add-a-toleration)
- [07. NoExecute Taint with tolerationSeconds](#07-noexecute-taint-with-tolerationseconds)
- [08. Topology Spread Constraints](#08-topology-spread-constraints)
- [09. Combine Node Affinity with Taints](#09-combine-node-affinity-with-taints)
- [10. Debug a Pending Pod](#10-debug-a-pending-pod)

---

#### 01. Label Nodes and Use nodeSelector

Add a custom label to a node and schedule a Pod on it using `nodeSelector`.

#### Scenario:

  ◦ You have a node with SSD storage and want to ensure a database Pod only runs on it.
  ◦ `nodeSelector` is the simplest scheduling constraint.

**Hint:** `kubectl label nodes`, then use `spec.nodeSelector` in the Pod spec.

??? example "Solution"

    ```bash
    # 1. List nodes
    kubectl get nodes

    # 2. Label a node
    kubectl label nodes <node-name> disk-type=ssd

    # 3. Create a Pod with nodeSelector
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: ssd-pod
    spec:
      nodeSelector:
        disk-type: ssd
      containers:
      - name: app
        image: nginx:1.25
    EOF

    # 4. Verify the Pod landed on the correct node
    kubectl get pod ssd-pod -o wide

    # 5. Cleanup
    kubectl delete pod ssd-pod
    kubectl label nodes <node-name> disk-type-
    ```

---

#### 02. Required Node Affinity with Multiple Labels

Schedule a Pod that requires nodes with BOTH `environment=production` AND `zone=us-east` labels.

#### Scenario:

  ◦ Your production workload must run in a specific zone on production-labeled nodes.
  ◦ Node Affinity with the `In` operator lets you express this constraint.

**Hint:** Use `requiredDuringSchedulingIgnoredDuringExecution` with multiple `matchExpressions` in a single `nodeSelectorTerms` entry.

??? example "Solution"

    ```bash
    # 1. Label nodes
    kubectl label nodes <node-name> environment=production zone=us-east

    # 2. Create the Pod
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: prod-east-pod
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: environment
                operator: In
                values: [production]
              - key: zone
                operator: In
                values: [us-east]
      containers:
      - name: app
        image: nginx:1.25
    EOF

    # 3. Verify
    kubectl get pod prod-east-pod -o wide
    kubectl describe pod prod-east-pod | grep "Node:"

    # 4. Cleanup
    kubectl delete pod prod-east-pod
    kubectl label nodes <node-name> environment- zone-
    ```

---

#### 03. Preferred Node Affinity with Weights

Deploy a Pod that strongly prefers production nodes (weight 80) and weakly prefers SSD nodes (weight 20).

#### Scenario:

  ◦ You want soft scheduling preferences — the Pod should schedule even if neither preference is met.
  ◦ Weights (1–100) let you prioritize multiple preferences.

**Hint:** Use `preferredDuringSchedulingIgnoredDuringExecution` with two entries at different weights.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: weighted-pod
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            preference:
              matchExpressions:
              - key: environment
                operator: In
                values: [production]
          - weight: 20
            preference:
              matchExpressions:
              - key: disk-type
                operator: In
                values: [ssd]
      containers:
      - name: app
        image: nginx:1.25
    EOF

    kubectl get pod weighted-pod -o wide
    kubectl describe pod weighted-pod | grep "Node:"

    # Cleanup
    kubectl delete pod weighted-pod
    ```

---

#### 04. Pod Anti-Affinity for High Availability

Deploy a 3-replica Deployment where no two replicas land on the same node.

#### Scenario:

  ◦ For high availability, replicas should be spread across different nodes.
  ◦ If you have fewer nodes than replicas, some Pods will stay Pending with required anti-affinity.

**Hint:** Use `podAntiAffinity` with `requiredDuringSchedulingIgnoredDuringExecution` and `topologyKey: kubernetes.io/hostname`.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: ha-web
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: ha-web
      template:
        metadata:
          labels:
            app: ha-web
        spec:
          affinity:
            podAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchLabels:
                    app: ha-web
                topologyKey: kubernetes.io/hostname
          containers:
          - name: web
            image: nginx:1.25
    EOF

    # Verify each pod is on a different node
    kubectl get pods -l app=ha-web -o wide

    # Cleanup
    kubectl delete deployment ha-web
    ```

---

#### 05. Pod Affinity to Co-Locate Services

Deploy a cache Pod and an app Pod that must be on the same node as the cache.

#### Scenario:

  ◦ Your application benefits from sub-millisecond latency to the local cache.
  ◦ Pod Affinity ensures co-location on the same node.

**Hint:** Use `podAffinity` with `topologyKey: kubernetes.io/hostname` matching the cache Pod's labels.

??? example "Solution"

    ```bash
    # 1. Deploy the cache
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: cache
      labels:
        app: cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
    EOF

    # 2. Deploy the app with affinity to cache
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: app-near-cache
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: cache
            topologyKey: kubernetes.io/hostname
      containers:
      - name: app
        image: nginx:1.25
    EOF

    # 3. Verify both are on the same node
    kubectl get pods cache app-near-cache -o wide

    # Cleanup
    kubectl delete pod cache app-near-cache
    ```

---

#### 06. Taint a Node and Add a Toleration

Taint a node with `NoSchedule`, verify a regular Pod is rejected, then deploy a Pod with a matching toleration.

#### Scenario:

  ◦ You have dedicated GPU nodes that should only accept GPU workloads.
  ◦ Taints repel Pods; tolerations opt-in specific Pods.

**Hint:** `kubectl taint nodes`, then add a `tolerations` block to the Pod spec.

??? example "Solution"

    ```bash
    # 1. Taint a node
    kubectl taint nodes <node-name> dedicated=gpu:NoSchedule

    # 2. Try a regular Pod (will stay Pending if this is the only node)
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: regular-pod
    spec:
      containers:
      - name: app
        image: nginx:1.25
    EOF

    kubectl describe pod regular-pod | grep -A5 "Events:"

    # 3. Deploy a Pod with toleration
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: gpu-pod
    spec:
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gpu"
        effect: "NoSchedule"
      containers:
      - name: app
        image: nginx:1.25
    EOF

    kubectl get pod gpu-pod -o wide

    # Cleanup
    kubectl delete pod regular-pod gpu-pod
    kubectl taint nodes <node-name> dedicated=gpu:NoSchedule-
    ```

---

#### 07. NoExecute Taint with tolerationSeconds

Deploy a Pod with a `NoExecute` toleration and `tolerationSeconds: 60`. Apply the taint and observe the Pod being evicted after 60 seconds.

#### Scenario:

  ◦ During planned maintenance, you want to give running Pods a grace period before eviction.
  ◦ `tolerationSeconds` controls how long a Pod survives after the taint is applied.

**Hint:** Use `effect: NoExecute` with `tolerationSeconds` in the Pod toleration.

??? example "Solution"

    ```bash
    # 1. Deploy a Pod with tolerationSeconds
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: graceful-pod
    spec:
      tolerations:
      - key: "maintenance"
        operator: "Equal"
        value: "true"
        effect: "NoExecute"
        tolerationSeconds: 60
      containers:
      - name: app
        image: nginx:1.25
    EOF

    # 2. Verify it's running
    kubectl get pod graceful-pod -o wide
    NODE=$(kubectl get pod graceful-pod -o jsonpath='{.spec.nodeName}')

    # 3. Taint the node with NoExecute
    kubectl taint nodes $NODE maintenance=true:NoExecute

    # 4. Watch the Pod — it survives ~60s then is evicted
    kubectl get pod graceful-pod -w

    # Cleanup
    kubectl taint nodes $NODE maintenance=true:NoExecute-
    ```

---

#### 08. Topology Spread Constraints

Deploy 6 replicas of a Deployment with `maxSkew: 1` across availability zones.

#### Scenario:

  ◦ You need even distribution of pods across zones for resilience.
  ◦ Topology Spread Constraints provide finer control than Anti-Affinity.

**Hint:** Use `topologySpreadConstraints` with `topologyKey: topology.kubernetes.io/zone`.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: zone-spread
    spec:
      replicas: 6
      selector:
        matchLabels:
          app: zone-spread
      template:
        metadata:
          labels:
            app: zone-spread
        spec:
          topologySpreadConstraints:
          - maxSkew: 1
            topologyKey: topology.kubernetes.io/zone
            whenUnsatisfiable: DoNotSchedule
            labelSelector:
              matchLabels:
                app: zone-spread
          containers:
          - name: app
            image: nginx:1.25
    EOF

    # Verify distribution
    kubectl get pods -l app=zone-spread -o wide

    # Cleanup
    kubectl delete deployment zone-spread
    ```

---

#### 09. Combine Node Affinity with Taints

Create a dedicated node pool pattern: taint the node (repel others) and use Node Affinity (attract your Pods).

#### Scenario:

  ◦ You want to isolate monitoring workloads on dedicated nodes.
  ◦ The pattern is: Taint (repel) + Affinity (attract) + Toleration (allow).

**Hint:** Label and taint the node, then create a Pod with both `nodeAffinity` and `tolerations`.

??? example "Solution"

    ```bash
    # 1. Setup the dedicated node
    kubectl label nodes <node-name> role=monitoring
    kubectl taint nodes <node-name> role=monitoring:NoSchedule

    # 2. Deploy a monitoring Pod
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: monitor-pod
    spec:
      tolerations:
      - key: "role"
        operator: "Equal"
        value: "monitoring"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: role
                operator: In
                values: [monitoring]
      containers:
      - name: prometheus
        image: prom/prometheus:latest
    EOF

    # 3. Verify it landed on the correct node
    kubectl get pod monitor-pod -o wide

    # Cleanup
    kubectl delete pod monitor-pod
    kubectl taint nodes <node-name> role=monitoring:NoSchedule-
    kubectl label nodes <node-name> role-
    ```

---

#### 10. Debug a Pending Pod

Given a Pod stuck in Pending, use kubectl commands to identify and resolve the scheduling failure.

#### Scenario:

  ◦ A colleague deployed a Pod that's stuck in Pending. You need to diagnose the issue.
  ◦ Common causes: missing labels, unmatched taints, insufficient resources.

**Hint:** `kubectl describe pod`, `kubectl get events`, check node labels and taints.

??? example "Solution"

    ```bash
    # 1. Create a Pod with an impossible affinity (to simulate the issue)
    cat <<'EOF' | kubectl apply -f -
    apiVersion: v1
    kind: Pod
    metadata:
      name: stuck-pod
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: nonexistent-label
                operator: In
                values: [does-not-exist]
      containers:
      - name: app
        image: nginx:1.25
    EOF

    # 2. Check pod status
    kubectl get pod stuck-pod
    # STATUS: Pending

    # 3. Describe for scheduling events
    kubectl describe pod stuck-pod | grep -A10 "Events:"
    # "0/N nodes are available: N node(s) didn't match Pod's node affinity/selector"

    # 4. Check node labels to understand what's available
    kubectl get nodes --show-labels

    # 5. Check node taints
    kubectl describe nodes | grep -A3 "Taints:"

    # 6. Fix: either label a node or remove the affinity constraint
    # Option A: Label a node to satisfy the affinity
    kubectl label nodes <node-name> nonexistent-label=does-not-exist

    # 7. Verify the Pod is now scheduled
    kubectl get pod stuck-pod -o wide

    # Cleanup
    kubectl delete pod stuck-pod
    kubectl label nodes <node-name> nonexistent-label-
    ```
