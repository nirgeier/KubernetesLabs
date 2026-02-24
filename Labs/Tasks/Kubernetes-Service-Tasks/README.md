# Kubernetes Service Tasks

- Hands-on Kubernetes exercises covering Services, Networking, and Service Discovery.
- Each task includes a description and a detailed solution with step-by-step instructions.
- Practice these tasks to master how Kubernetes exposes applications and manages traffic.

#### Table of Contents

- [01. Basic Service Exposure (ClusterIP)](#01-basic-service-exposure-clusterip)
- [02. NodePort & LoadBalancer](#02-nodeport-loadbalancer)
- [03. Service Discovery with DNS (FQDN)](#03-service-discovery-with-dns-fqdn)
- [04. Headless Services](#04-headless-services)
- [05. ExternalName Service](#05-externalname-service)
- [06. Manual Endpoints](#06-manual-endpoints)
- [07. Session Affinity](#07-session-affinity)
- [08. Multi-Port Service](#08-multi-port-service)

---

#### 01. Basic Service Exposure (ClusterIP)

Run an `nginx` pod and expose it via a Service (ClusterIP) to access it from within the cluster.

#### Scenario:
  ◦ You have an application running in a pod, but it needs to be accessible by other pods.
  ◦ ClusterIP is the default service type, providing internal stable IP.

**Hint:** `kubectl expose`, `kubectl get services`, `kubectl port-forward`

<details>
<summary>Solution</summary>

```bash
# 1. Run an nginx pod
kubectl run nginx-web --image=nginx:alpine --port=80

# 2. Expose the pod as a Service (ClusterIP by default)
kubectl expose pod nginx-web --name=nginx-svc --port=80 --target-port=80

# 3. Verify the service
kubectl get svc

# 4. Access it (using port-forward for local access)
kubectl port-forward svc/nginx-svc 8080:80
# (Open localhost:8080 in browser)

# Cleanup
kubectl delete pod nginx-web
kubectl delete svc nginx-svc
```
</details>

---

#### 02. NodePort & LoadBalancer

Expose a deployment using `NodePort` to access it via the node's IP, and then switch it to `LoadBalancer` (simulated or real).

#### Scenario:
  ◦ You need to make your application accessible from outside the Kubernetes cluster.
  ◦ `NodePort` opens a specific port on all nodes, while `LoadBalancer` provisions an external IP (cloud provider dependent).

**Hint:** `type: NodePort`, `type: LoadBalancer`

<details>
<summary>Solution</summary>

```bash
# 1. Create a deployment
kubectl create deployment web-server --image=nginx:alpine --replicas=2

# 2. Expose as NodePort
kubectl expose deployment web-server --type=NodePort --name=web-nodeport --port=80

# 3. Get the allocated NodePort (e.g., 30xxx)
kubectl get svc web-nodeport

# 4. (Optional) Patch it to be a LoadBalancer
kubectl patch svc web-nodeport -p '{"spec": {"type": "LoadBalancer"}}'

# 5. Verify external IP (it might stay <pending> on Minikube/Kind without addons)
kubectl get svc web-nodeport

# Cleanup
kubectl delete deployment web-server
kubectl delete svc web-nodeport
```
</details>

---

#### 03. Service Discovery with DNS (FQDN)

Create two pods in different namespaces and verify they can communicate using the Fully Qualified Domain Name (FQDN).

#### Scenario:
  ◦ Microservices often live in different namespaces (e.g., `frontend` vs `backend`).
  ◦ You need to ensure they can talk to each other using Kubernetes internal DNS.

**Hint:** `nslookup`, `<service>.<namespace>.svc.cluster.local`

<details>
<summary>Solution</summary>

```bash
# 1. Create two namespaces
kubectl create ns app-a
kubectl create ns app-b

# 2. Run a target pod and service in app-b
kubectl run backend --image=nginx:alpine -n app-b
kubectl expose pod backend --name=backend-svc --port=80 -n app-b

# 3. Run a client pod in app-a
kubectl run client --image=busybox -n app-a -- sleep 3600

# 4. Test DNS resolution from client to backend
# FQDN format: service-name.namespace.svc.cluster.local
kubectl exec -it client -n app-a -- nslookup backend-svc.app-b.svc.cluster.local

# 5. Test connectivity
kubectl exec -it client -n app-a -- wget -O- backend-svc.app-b.svc.cluster.local

# Cleanup
kubectl delete ns app-a app-b
```
</details>

---

#### 04. Headless Services

Create a Headless Service (ClusterIP: None) and verify that DNS returns the IPs of the individual pods instead of a single Service IP.

#### Scenario:
  ◦ You are deploying a distributed stateful application (like Cassandra, MongoDB, or Kafka) that needs to discover all peer nodes directly.
  ◦ Headless services allow direct pod-to-pod communication without load balancing.

**Hint:** `clusterIP: None`

<details>
<summary>Solution</summary>

```bash
# 1. Create a Headless Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
spec:
  clusterIP: None
  selector:
    app: headless-app
  ports:
    - port: 80
EOF

# 2. Create pods matching the selector
kubectl run pod-1 --image=nginx:alpine --labels=app=headless-app
kubectl run pod-2 --image=nginx:alpine --labels=app=headless-app

# 3. Verify DNS resolution (should return multiple IPs)
kubectl run dns-test --image=busybox --restart=Never -- nslookup headless-svc

# 4. Check logs to see the IPs
kubectl logs dns-test

# Cleanup
kubectl delete pod pod-1 pod-2 dns-test
kubectl delete svc headless-svc
```
</details>

---

#### 05. ExternalName Service

Create a Service that maps to an external DNS name (e.g., `google.com`) instead of a pod selector.

#### Scenario:
  ◦ You want to refer to an external database or API (e.g., AWS RDS, external API) using a local Kubernetes service name.
  ◦ This allows you to change the external endpoint later without changing your application code.

**Hint:** `type: ExternalName`, `externalName: example.com`

<details>
<summary>Solution</summary>

```bash
# 1. Create ExternalName service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: my-external-service
spec:
  type: ExternalName
  externalName: google.com
EOF

# 2. Test resolution (it should be a CNAME to google.com)
kubectl run ext-test --image=busybox --restart=Never -- nslookup my-external-service

# 3. Check logs
kubectl logs ext-test

# Cleanup
kubectl delete svc my-external-service
kubectl delete pod ext-test
```
</details>

---

#### 06. Manual Endpoints

Create a Service without a selector, and manually create an Endpoints object to point to an external IP (or a specific pod IP).

#### Scenario:
  ◦ You want to use a Kubernetes Service to point to a specific IP address that isn't managed by a Kubernetes Pod selector (e.g., a legacy server or a database outside the cluster).

**Hint:** `kind: Endpoints`, same name as Service

<details>
<summary>Solution</summary>

```bash
# 1. Create a Service without a selector
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: manual-svc
spec:
  ports:
    - port: 80
      targetPort: 80
EOF

# 2. Create Endpoints manually (Use an IP you know, e.g., 1.1.1.1 or a pod IP)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Endpoints
metadata:
  name: manual-svc
subsets:
  - addresses:
      - ip: 1.1.1.1
    ports:
      - port: 80
EOF

# 3. Describe service to see endpoints
kubectl describe svc manual-svc

# Cleanup
kubectl delete svc manual-svc
kubectl delete endpoints manual-svc
```
</details>

---

#### 07. Session Affinity

Create a Service with `sessionAffinity: ClientIP` and verify that requests from the same client pod go to the same backend pod (if possible to observe).

#### Scenario:
  ◦ Your application stores session state locally in the container (not recommended, but happens).
  ◦ You need to ensure a user always hits the same pod during their session.

**Hint:** `sessionAffinity: ClientIP`

<details>
<summary>Solution</summary>

```bash
# 1. Create a deployment with 3 replicas
kubectl create deployment session-app --image=nginx:alpine --replicas=3

# 2. Expose with ClientIP affinity
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: session-svc
spec:
  selector:
    app: session-app
  ports:
    - port: 80
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
EOF

# 3. Verify affinity setting
kubectl describe svc session-svc

# Cleanup
kubectl delete deployment session-app
kubectl delete svc session-svc
```
</details>

---

#### 08. Multi-Port Service

Create a Service that exposes both port 80 (HTTP) and 443 (HTTPS) for the same set of pods.

#### Scenario:
  ◦ Your application serves both HTTP and HTTPS traffic.
  ◦ You need a single Service to handle both ports.

**Hint:** `ports` array in Service spec

<details>
<summary>Solution</summary>

```bash
# 1. Create a pod that exposes port 80
kubectl run web-multi --image=nginx:alpine --port=80

# 2. Create a multi-port service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: multi-port-svc
spec:
  selector:
    run: web-multi
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 80 # Mapping 443 to 80 just for demo since nginx listens on 80
EOF

# 3. Verify ports
kubectl get svc multi-port-svc

# Cleanup
kubectl delete pod web-multi
kubectl delete svc multi-port-svc
```
</details>
