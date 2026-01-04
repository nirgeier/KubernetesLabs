# Kubernetes CLI Tasks

- Hands-on Kubernetes exercises covering essential CLI commands, debugging techniques, and advanced orchestration concepts.
- Each task includes a description and a detailed solution with step-by-step instructions.
- Practice these tasks to master Kubernetes from basic operations to advanced deployment scenarios.

#### Table of Contents

- [01. Kubernetes Pod Workflow](#01-kubernetes-pod-workflow)
- [02. Pod Debugging Challenge](#02-pod-debugging-challenge)
- [03. Imperative to Declarative](#03-imperative-to-declarative)
- [04. Scaling Deployments](#04-scaling-deployments)
- [05. Rolling Updates and Rollbacks](#05-rolling-updates-and-rollbacks)
- [06. ConfigMaps and Environment Variables](#06-configmaps-and-environment-variables)
- [07. Secrets Management](#07-secrets-management)
- [08. Persistent Storage with PVCs](#08-persistent-storage-with-pvcs)
- [09. Multi-Container Pods](#09-multi-container-pods)
- [10. Jobs and CronJobs](#10-jobs-and-cronjobs)
- [11. Namespaces and Isolation](#11-namespaces-and-isolation)
- [12. Resource Limits and Quotas](#12-resource-limits-and-quotas)
- [13. Liveness and Readiness Probes](#13-liveness-and-readiness-probes)
- [14. Node Selection and Affinity](#14-node-selection-and-affinity)

---

#### 01. Kubernetes Pod Workflow

Start an `nginx` pod, verify it's running, execute a command inside it to check the version, and then delete it.

#### Scenario:
  ◦ As a developer, you need to quickly verify a container image or run a temporary workload without creating a full deployment.
  ◦ This workflow allows you to spin up pods, interact with them, and clean them up efficiently.

**Hint:** `kubectl run`, `kubectl get`, `kubectl exec`, `kubectl delete`

<details>
<summary>Solution</summary>

```bash
# 1. Run an nginx pod
kubectl run nginx-pod --image=nginx:alpine

# 2. Verify it is running
kubectl get pods

# 3. Execute a command inside the pod
kubectl exec nginx-pod -- nginx -v

# 4. Delete the pod
kubectl delete pod nginx-pod
```
</details>

---

#### 02. Pod Debugging Challenge

Run a pod that is destined to fail (e.g., using a non-existent image), inspect its status, find the error reason, and then fix it (by creating a correct one).

#### Scenario:
  ◦ Your application pod is stuck in `ImagePullBackOff` or `CrashLoopBackOff`.
  ◦ You need to diagnose the issue using Kubernetes inspection tools to understand why it's failing.

**Hint:** `kubectl run`, `kubectl get`, `kubectl describe`, `kubectl logs`

<details>
<summary>Solution</summary>

```bash
# 1. Run a pod with a wrong image
kubectl run bad-pod --image=nginx:wrongtag

# 2. Check status (should show ErrImagePull or ImagePullBackOff)
kubectl get pods

# 3. Describe the pod to see events
kubectl describe pod bad-pod

# 4. Delete the bad pod
kubectl delete pod bad-pod

# 5. Run a correct pod
kubectl run good-pod --image=nginx:alpine
```
</details>

---

#### 03. Imperative to Declarative

Create a pod using an imperative command, export its configuration to a YAML file, delete the pod, and recreate it using the YAML file.

#### Scenario:
  ◦ You want to move from ad-hoc CLI commands to Infrastructure as Code (IaC).
  ◦ Generating YAML from existing resources or dry-runs is a quick way to scaffold your manifests.

**Hint:** `kubectl run --dry-run=client -o yaml`

<details>
<summary>Solution</summary>

```bash
# 1. Generate YAML for a pod
kubectl run my-pod --image=redis:alpine --dry-run=client -o yaml > my-pod.yaml

# 2. Create the pod from YAML
kubectl apply -f my-pod.yaml

# 3. Verify it exists
kubectl get pods

# 4. Delete the pod using the file
kubectl delete -f my-pod.yaml
```
</details>

---

#### 04. Scaling Deployments

Create a deployment with 2 replicas, verify them, and then scale it up to 5 replicas.

#### Scenario:
  ◦ Your application is receiving high traffic and you need to increase capacity.
  ◦ Kubernetes Deployments make scaling stateless applications trivial.

**Hint:** `kubectl create deployment`, `kubectl scale`

<details>
<summary>Solution</summary>

```bash
# 1. Create a deployment
kubectl create deployment my-dep --image=nginx:alpine --replicas=2

# 2. Verify replicas
kubectl get pods

# 3. Scale up
kubectl scale deployment my-dep --replicas=5

# 4. Verify scaling
kubectl get pods

# Cleanup
kubectl delete deployment my-dep
```
</details>

---

#### 05. Rolling Updates and Rollbacks

Update the image of a deployment to a new version, watch the rollout status, and then rollback to the previous version.

#### Scenario:
  ◦ You deployed a new version of your app, but it has a bug.
  ◦ You need to quickly revert to the last stable version without downtime.

**Hint:** `kubectl set image`, `kubectl rollout status`, `kubectl rollout undo`

<details>
<summary>Solution</summary>

```bash
# 1. Create deployment with nginx:1.21
kubectl create deployment web-app --image=nginx:1.21 --replicas=3

# 2. Update image to nginx:1.22
kubectl set image deployment/web-app nginx=nginx:1.22

# 3. Watch rollout
kubectl rollout status deployment/web-app

# 4. Rollback to previous version
kubectl rollout undo deployment/web-app

# Cleanup
kubectl delete deployment web-app
```
</details>

---

#### 06. ConfigMaps and Environment Variables

Create a ConfigMap with some data and inject it into a pod as environment variables.

#### Scenario:
  ◦ You need to configure your application (e.g., DB host, API URL) without hardcoding values in the image.
  ◦ ConfigMaps decouple configuration artifacts from image content.

**Hint:** `kubectl create configmap`, `envFrom` in YAML

<details>
<summary>Solution</summary>

```bash
# 1. Create a ConfigMap
kubectl create configmap app-config --from-literal=APP_COLOR=blue --from-literal=APP_MODE=prod

# 2. Create a pod that uses it (using dry-run to generate yaml first is easier)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
  - name: test-container
    image: busybox
    command: [ "sh", "-c", "env" ]
    envFrom:
    - configMapRef:
        name: app-config
EOF

# 3. Check logs to see env vars
kubectl logs config-pod | grep APP_

# Cleanup
kubectl delete pod config-pod
kubectl delete cm app-config
```
</details>

---

#### 07. Secrets Management

Create a Secret and mount it as a volume in a pod.

#### Scenario:
  ◦ Your application needs sensitive data like passwords or API keys.
  ◦ Secrets store this data securely and can be mounted as files or env vars.

**Hint:** `kubectl create secret`, `volumeMounts`

<details>
<summary>Solution</summary>

```bash
# 1. Create a generic secret
kubectl create secret generic my-secret --from-literal=password=s3cr3t

# 2. Create a pod mounting the secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secret-volume
      mountPath: "/etc/secret-volume"
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: my-secret
EOF

# 3. Verify secret file exists
kubectl exec secret-pod -- cat /etc/secret-volume/password

# Cleanup
kubectl delete pod secret-pod
kubectl delete secret my-secret
```
</details>

---

#### 08. Persistent Storage with PVCs

Create a PersistentVolumeClaim (PVC) and mount it to a pod to persist data.

#### Scenario:
  ◦ You are running a database or stateful app that needs to save data even if the pod restarts.
  ◦ PVCs request storage from the cluster's storage provisioner.

**Hint:** `PersistentVolumeClaim`, `volumes`

<details>
<summary>Solution</summary>

```bash
# 1. Create a PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# 2. Create a pod using the PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - mountPath: "/data"
      name: my-storage
  volumes:
  - name: my-storage
    persistentVolumeClaim:
      claimName: my-pvc
EOF

# 3. Write data
kubectl exec pvc-pod -- sh -c "echo 'Hello Storage' > /data/test.txt"

# 4. Delete pod and recreate (data should persist - exercise for reader)
kubectl delete pod pvc-pod
# Re-apply pod yaml and check file

# Cleanup
kubectl delete pvc my-pvc
```
</details>

---

#### 09. Multi-Container Pods

Create a pod with two containers: a main application and a sidecar helper.

#### Scenario:
  ◦ You need a helper process (like a log shipper or proxy) to run alongside your main application in the same network namespace.
  ◦ Multi-container pods share storage and network.

**Hint:** `containers` array in Pod spec

<details>
<summary>Solution</summary>

```bash
# 1. Create multi-container pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: main-app
    image: busybox
    command: ["sh", "-c", "while true; do echo 'Main App' > /shared/index.html; sleep 5; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  - name: sidecar
    image: busybox
    command: ["sh", "-c", "while true; do cat /shared/index.html; sleep 5; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  volumes:
  - name: shared-data
    emptyDir: {}
EOF

# 2. Check logs of sidecar
kubectl logs multi-container-pod -c sidecar

# Cleanup
kubectl delete pod multi-container-pod
```
</details>

---

#### 10. Jobs and CronJobs

Create a Job that runs to completion, and a CronJob that runs every minute.

#### Scenario:
  ◦ You have a batch process (database migration, report generation) or a periodic task.
  ◦ Jobs ensure a task finishes successfully; CronJobs schedule them.

**Hint:** `kubectl create job`, `kubectl create cronjob`

<details>
<summary>Solution</summary>

```bash
# 1. Create a Job
kubectl create job my-job --image=busybox -- echo "Job Completed"

# 2. Check job status
kubectl get jobs
kubectl logs job/my-job

# 3. Create a CronJob
kubectl create cronjob my-cron --image=busybox --schedule="*/1 * * * *" -- echo "Cron Run"

# 4. Wait for a run and check jobs created by cron
kubectl get jobs --watch

# Cleanup
kubectl delete job my-job
kubectl delete cronjob my-cron
```
</details>

---

#### 11. Namespaces and Isolation

Create a new namespace and run a pod inside it.

#### Scenario:
  ◦ You want to separate development resources from production.
  ◦ Namespaces provide a scope for names and can be used to divide cluster resources.

**Hint:** `kubectl create namespace`, `kubectl run -n`

<details>
<summary>Solution</summary>

```bash
# 1. Create namespace
kubectl create ns dev

# 2. Run pod in namespace
kubectl run dev-pod --image=nginx:alpine -n dev

# 3. Verify it's not in default
kubectl get pods
kubectl get pods -n dev

# Cleanup
kubectl delete ns dev
```
</details>

---

#### 12. Resource Limits and Quotas

Create a pod with CPU and Memory requests and limits.

#### Scenario:
  ◦ You need to ensure fair resource usage and prevent one container from starving others.
  ◦ Requests guarantee resources; limits cap them.

**Hint:** `resources.requests`, `resources.limits`

<details>
<summary>Solution</summary>

```bash
# 1. Create pod with limits
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
EOF

# 2. Describe to see limits
kubectl describe pod resource-pod

# Cleanup
kubectl delete pod resource-pod
```
</details>

---

#### 13. Liveness and Readiness Probes

Add a liveness probe to a pod to restart it if it freezes, and a readiness probe to control traffic flow.

#### Scenario:
  ◦ Your app might deadlock or take time to start up.
  ◦ Liveness probes restart unhealthy pods; Readiness probes remove them from Service endpoints until ready.

**Hint:** `livenessProbe`, `readinessProbe`

<details>
<summary>Solution</summary>

```bash
# 1. Create pod with probes
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: probe-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 3
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
EOF

# 2. Describe to see probe status
kubectl describe pod probe-pod

# Cleanup
kubectl delete pod probe-pod
```
</details>

---

#### 14. Node Selection and Affinity

Schedule a pod on a specific node using a node selector (requires a node label).

#### Scenario:
  ◦ You have specialized hardware (GPU, SSD) on specific nodes.
  ◦ You need to ensure your pod lands on the correct node.

**Hint:** `kubectl label nodes`, `nodeSelector`

<details>
<summary>Solution</summary>

```bash
# 1. Label a node (use your node name, e.g., minikube or docker-desktop)
# Get node name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl label node $NODE_NAME disk=ssd

# 2. Create pod with nodeSelector
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
  nodeSelector:
    disk: ssd
EOF

# 3. Verify it's running
kubectl get pod ssd-pod -o wide

# Cleanup
kubectl delete pod ssd-pod
kubectl label node $NODE_NAME disk-
```
</details>
