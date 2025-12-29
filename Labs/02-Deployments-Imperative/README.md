
# K8S Hands-on


---
# Deployment - Imperative


## Creating deployments using `kubectl create`

- We start with creating the following deployment
  [praqma/network-multitool](https://github.com/Praqma/Network-MultiTool)
- This is a multitool for container/network testing and troubleshooting.

---

### Pre-Requirements

- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)  
**<kbd>CTRL</kbd> + <kbd>click</kbd> to open in new window**

---


### 01. Create Namespace

- As completed in the previous lab, create the desired namespace [codewizard]:

```sh
$ kubectl create namespace codewizard
namespace/codewizard created
```

- In order to set this is as the default namespace, please refer to <a href="../01-Namespace#2-setting-the-default-namespace-for-kubectl">set default namespace</a>.

---

### 02. Deploy Multitool Image

```sh
# Deploy the first container
$ kubectl create deployment multitool -n codewizard --image=praqma/network-multitool
deployment.apps/multitool created
```

- `kubectl create deployment` actually creating a replica set for us.
- We can verify it by running:

```
$ kubectl get all -n codewizard

## Expected output:
NAME                                    READY    UP-TO-DATE  AVAILABLE
deployment.apps/multitool               1/1      1           1

NAME                                    DESIRED  CURRENT     READY
replicaset.apps/multitool-7885b5f94f    1        1           1

NAME                                    READY    STATUS      RESTARTS
pod/multitool-7885b5f94f-9s7xh          1/1      Running     0
```

---

## 03. Test the Deployment

- The above deployment contains a container named, `multitool`.
- In order for us to be able to access this `multitool` container, we need to create a resource of type `Service` which will "open" the server for incoming traffic.

#### Create a service using `kubectl expose`

```sh
# "Expose" the desired port for incoming traffic
# This command is equivalent to declare a `kind: Service` im YAML file

$ kubectl expose deployment -n codewizard multitool --port 80 --type NodePort
service/multitool exposed
```

- Verify that the service have been created by running:

```sh
$ kubectl get service -n codewizard

# The output should be something like
NAME                TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/multitool   NodePort   10.102.73.248   <none>        80:31418/TCP   3s
```

---

#### Find the port & the IP which was assigned to our pod by the cluster.

- Grab the port from the previous output.
  - Port: In the above sample its `31418` [`80:31418/TCP`]
  - IP: we will need to grab the cluster ip using `kubectl cluster-info`

```sh

# get the IP
$ kubectl cluster-info

# You should get output similar to this one
Kubernetes control plane is running at https://192.168.49.2:8443
KubeDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# Programmatically get the port and the IP
CLUSTER_IP=$(kubectl get nodes \
            --selector=node-role.kubernetes.io/control-plane \
            -o jsonpath='{$.items[*].status.addresses[?(@.type=="InternalIP")].address}')

NODE_PORT=$(kubectl get -o \
            jsonpath="{.spec.ports[0].nodePort}" \
            services multitool -n codewizard)
```

- In this sample the cluster-ip is `192.168.49.2`

---

#### Test the deployment

- Test to see if the deployment worked using the `ip address and port number` we have retrieved above.
- Execute `curl` with the following parameters: `http://${CLUSTER_IP}:${NODE_PORT}`

```sh
curl http://${CLUSTER_IP}:${NODE_PORT}

# Or in the above sample
curl 192.168.49.2:30436

# The output should be similar to this:
Praqma Network MultiTool (with NGINX) ...
```
- If you get the above output, congratulations! You have successfully created a deployment using imperative commands.