
# K8S Hands-on


---

# Service Discovery

- In the following lab we will learn what is a `Service` and go over the different `Service` types.

---
### Pre-Requirements
- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)  
**<kbd>CTRL</kbd> + <kbd>click</kbd> to open in new window**

---

## 01. Some general notes on what is a `Service`


- `Service` is a unit of application behavior bound to a unique name in a `service registry`. 
- `Service` consist of multiple `network endpoints` implemented by workload instances running on pods, containers, VMs etc.
- `Service` allow us to gain access to any given pod or container (e.g., a web service).
- A `service` is (normally) created on top of an existing deployment and exposing it to the "world", using IP(s) & port(s).
- `K8S` define 3 main ways (+FQDN internally) to define a service, which means that we have 4 different ways to access Pods.
- There are several proxy mode which inplements diffrent behaviour, for example in `user proxy mode` for each `Service` `kube-proxy` opens a port (randomly chosen) on the local node. Any connections to this "proxy port" are proxied to one of the Service's backend Pods (as reported via Endpoints).
- All the service types are assigned with a `Cluster-IP`.
- Every service also creates `Endoint(s)`, which point to the actual pods. `Endpoints` are usually referred to as `back-ends` of a particular service.

---

### 01. Create namespace and clear previous data if there is any

```sh
# If the namespace already exists and contains data form previous steps, let's clean it
kubectl delete namespace codewizard

# Create the desired namespace [codewizard]
$ kubectl create namespace codewizard
namespace/codewizard created
```

---

### 02. Create the required resources for this hand-on

```sh
# Network tools pod
$ kubectl create deployment -n codewizard multitool --image=praqma/network-multitool
deployment.apps/multitool created

# nginx pod
$ kubectl create deployment -n codewizard nginx --image=nginx
deployment.apps/nginx created

# Verify that the pods running
$ kubectl get all -n codewizard

NAME                             READY   STATUS    RESTARTS   AGE
pod/multitool-74477484b8-bdrwr   1/1     Running   0          29s
pod/nginx-6799fc88d8-p2fjn       1/1     Running   0          7s
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/multitool   1/1     1            1           30s
deployment.apps/nginx       1/1     1            1           8s
NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/multitool-74477484b8   1         1         1       30s
replicaset.apps/nginx-6799fc88d8       1         1         1       8s
```

---

# Service types

- As previously mentioned, there are several services type. Let's practice them:

### Service type: ClusterIP

- If not specified, the default service type is `ClusterIP`.
- In order to expose the deployment as a service, use: `--type=ClusterIP`
- `ClusterIP` will expose the pods within the cluster. Since we don't have an `external IP`, it will not be reachable from outside the cluster.
- When the service is created `K8S` attaches a DNS record to the service in the following format: `<service name>.<namespace>.svc.cluster.local`

---

### 03. Expose the nginx with ClusterIP

```sh
# Expose the service on port 80
$ kubectl expose deployment nginx -n codewizard --port 80 --type ClusterIP
service/nginx exposed

# Check the services and see it's type
# Grab the ClusterIP - we will use it in the next steps
$ kubectl get services -n codewizard

NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
nginx        ClusterIP   10.109.78.182   <none>        80/TCP
```

---

### 04. Test the nginx with ClusterIP

- Since the service is a `ClusterIP`, we will test if we can access the service using the multitool pod.

```sh
# Get the name of the multitool pod to be used
$ kubectl get pods -n codewizard
NAME
multitool-XXXXXX-XXXXX

# Run an interactive shell inside the network-multitool-container (same concept as with Docker)
$ kubectl exec -it <pod name> -n codewizard -- sh
```

- Connect to the service in **any** of the following ways:

#### Test the nginx with ClusterIP

##### 1. using the IP from the services output. grab the server response:

```sh
bash-5.0# curl -s <ClusterIP>
```

```html
# Expected output:
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

<br>

##### 2. Test the nginx using the deployment name - using the service name since its the DNS name behind the scenes

```sh
bash-5.0# curl -s nginx
```

```html
# Expected output:
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to nginx!</title>
    <style>
      body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
      }
    </style>
  </head>
  <body>
    <h1>Welcome to nginx!</h1>
    <p>
      If you see this page, the nginx web server is successfully installed and
      working. Further configuration is required.
    </p>
    <p>
      For online documentation and support please refer to
      <a href="http://nginx.org/">nginx.org</a>.<br />
      Commercial support is available at
      <a href="http://nginx.com/">nginx.com</a>.
    </p>
    <p><em>Thank you for using nginx.</em></p>
  </body>
</html>
```

<br>

##### 3. using the full DNS name - for every service we have a full `FQDN` (Fully qualified domain name) so we can use it as well

```sh
# bash-5.0# curl -s <service name>.<namespace>.svc.cluster.local
bash-5.0# curl -s nginx.codewizard.svc.cluster.local
```

---

# Service type: NodePort

- `NodePort`: Exposes the Service on each Node's IP at a **static port** (the `NodePort`).
- A `ClusterIP` Service, to which the `NodePort` Service routes, **is automatically created**.
- `NodePort` service is reachable from outside the cluster, by requesting `<Node IP>:<Node Port>`.

### 05. Create NodePort

##### 1. Delete previous service

```sh
# Delete the existing service from previous steps
$ kubectl delete svc nginx -n codewizard
service "nginx" deleted from codewizard namespace
```

<br>

##### 2. Create `NodePort` service

```sh
# As before but this time the type is a NodePort
$ kubectl expose deployment -n codewizard nginx --port 80 --type NodePort
service/nginx exposed

# Verify that the type is set to NodePort.
# This time you should see ClusterIP and port as well
$ kubectl get svc -n codewizard
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
nginx        NodePort    100.65.29.172  <none>        80:32593/TCP
```
<br>

##### 3. Test the `NodePort` service

- If we have the host IP and the node port number, we can connect directly to the pod.

- If you followed the previous labs, you should be able to do it yourself by now......

```sh
# Tiny clue....
$ kubectl cluster-info
$ kubectl get services

# Executing curl <cluster host ip>:<port> you should see the flowing Output
Welcome to nginx!
...
Thank you for using nginx.
```

---


# Service type: LoadBalancer



!!! warning "Note"
    **We cannot test a `LoadBalancer` service locally on a localhost, but only on a cluster which can provide an `external-IP`**



### 06. Create LoadBalancer (only if you are on real cloud)

<br>

##### 1. Delete previous service

```sh
# Delete the existing service from previous steps
$ kubectl delete svc nginx -n codewizard
service "nginx" deleted
```
<br>

##### 2. Create `LoadBalancer` Service

```sh
# As before this time the type is a LoadBalancer
$ kubectl expose deployment nginx -n codewizard --port 80 --type LoadBalancer
service/nginx exposed

# In real cloud we should se an EXTERNAL-IP and we can access the service
# via the internet
$ kubectl get svc
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
nginx        LoadBalancer   100.69.15.89   35.205.60.29  80:31354/TCP
```
<br>

##### 3. Test the `LoadBalancer` Service

```sh
# Testing load balancer only require us to use the EXTERNAL-IP
$ curl -s <EXTERNAL-IP>
```
