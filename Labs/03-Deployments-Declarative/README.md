---

# Deployment - Declarative

- In this lab we will create Kubernetes deployments using declarative YAML files.
- We will deploy nginx, scale it up and down, and observe how Kubernetes manages replicas.

---

## What will we learn?

- How to create a deployment using a YAML file
- How to apply changes using `kubectl apply`
- How to scale replicas declaratively and imperatively
- How Kubernetes handles scaling up and down

---

## Prerequisites

- A running Kubernetes cluster (`kubectl cluster-info` should work)
- `kubectl` configured against the cluster

---

## 01. Create Namespace

- As completed in the previous lab, create the desired namespace [codewizard]:

```sh
kubectl create namespace codewizard
namespace/codewizard created
```

- In order to set this is as the default namespace, please refer to <a href="../01-Namespace#2-setting-the-default-namespace-for-kubectl">set default namespace</a>.

---

## 02. Deploy nginx Using YAML File (Declarative)

- Let's create the `YAML` file for the deployment.
- If this is your first `k8s` `YAML` file, its advisable that you type it in order to get the feeling of the structure.
- Save the file with the following name: `nginx.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment # We use a deployment and not pod !!!!
metadata:
  name: nginx # Deployment name
  namespace: codewizard
  labels:
    app: nginx # Deployment label
spec:
  replicas: 2
  selector:
    matchLabels: # Labels for the replica selector
      app: nginx
  template:
    metadata:
      labels:
        app: nginx # Labels for the replica selector
        version: "1.17" # Specify specific verion if required
    spec:
      containers:
        - name: nginx # The name of the pod
          image: nginx:1.17 # The image which we will deploy
          ports:
            - containerPort: 80
```

- Create the deployment using the `-f` flag & `--record=true`

```sh
kubectl apply -n codewizard -f nginx.yaml --record=true
deployment.extensions/nginx created
```

---

## 03. Verify That the Deployment Has Been Created

```sh
kubectl get deployments -n codewizard
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE
multitool   1         1         1            1
nginx       1         1         1            1
```

---

## 04. Check if the Pods Are Running

```sh
kubectl get pods -n codewizard
NAME                         READY   STATUS    RESTARTS
multitool-7885b5f94f-9s7xh   1/1     Running   0
nginx-647fb5956d-v8d2w       1/1     Running   0
```

---

## 05. Playing with K8S Replicas

- Let's play with the replica and see K8S in action.
- Open a second terminal and execute:

```sh
kubectl get pods -n codewizard --watch
```

---

## 06. Update the `nginx.yaml` File with Replica's Value of 5

```yaml
spec:
  replicas: 5
```

---

## 07. Update the Deployment Using `kubectl apply`

```sh
kubectl apply -n codewizard -f nginx.yaml --record=true
deployment.apps/nginx configured
```

- Switch to the second terminal and you should see something like the following:

```sh
kubectl get pods --watch -n codewizard
NAME                         READY   STATUS    RESTARTS   AGE
multitool-74477484b8-dj7th   1/1     Running   0          20m
nginx-dc8bb9b45-hqdv9        1/1     Running   0          111s
nginx-dc8bb9b45-vdmp5        0/1     Pending   0          0s
nginx-dc8bb9b45-28wwq        0/1     Pending   0          0s
nginx-dc8bb9b45-wkc68        0/1     Pending   0          0s
nginx-dc8bb9b45-vdmp5        0/1     Pending   0          0s
nginx-dc8bb9b45-28wwq        0/1     Pending   0          0s
nginx-dc8bb9b45-x7j4g        0/1     Pending   0          0s
nginx-dc8bb9b45-wkc68        0/1     Pending   0          0s
nginx-dc8bb9b45-x7j4g        0/1     Pending   0          0s
nginx-dc8bb9b45-vdmp5        0/1     ContainerCreating   0          0s
nginx-dc8bb9b45-28wwq        0/1     ContainerCreating   0          0s
nginx-dc8bb9b45-wkc68        0/1     ContainerCreating   0          0s
nginx-dc8bb9b45-x7j4g        0/1     ContainerCreating   0          0s
nginx-dc8bb9b45-vdmp5        1/1     Running             0          2s
nginx-dc8bb9b45-28wwq        1/1     Running             0          3s
nginx-dc8bb9b45-x7j4g        1/1     Running             0          3s
nginx-dc8bb9b45-wkc68        1/1     Running             0          3s
```

- Can you explain what do you see?

  `Why are there more containers than requested?`

---

## 08. Scaling Down with `kubectl scale`

- Scaling down using `kubectl`, and not by editing the `YAML` file:

```sh
kubectl scale -n codewizard --replicas=1 deployment/nginx
```

- Switch to the second terminal. The current output should show something like this:

```
NAME                         READY   STATUS    RESTARTS   AGE
multitool-74477484b8-dj7th   1/1     Running   0          29m
nginx-dc8bb9b45-28wwq        1/1     Running   0          4m41s
nginx-dc8bb9b45-hqdv9        1/1     Running   0          10m
nginx-dc8bb9b45-vdmp5        1/1     Running   0          4m41s
nginx-dc8bb9b45-wkc68        1/1     Running   0          4m41s
nginx-dc8bb9b45-x7j4g        1/1     Running   0          4m41s
nginx-dc8bb9b45-x7j4g        1/1     Terminating   0          6m21s
nginx-dc8bb9b45-vdmp5        1/1     Terminating   0          6m21s
nginx-dc8bb9b45-28wwq        1/1     Terminating   0          6m21s
nginx-dc8bb9b45-wkc68        1/1     Terminating   0          6m21s
nginx-dc8bb9b45-x7j4g        0/1     Terminating   0          6m22s
nginx-dc8bb9b45-vdmp5        0/1     Terminating   0          6m22s
nginx-dc8bb9b45-wkc68        0/1     Terminating   0          6m22s
nginx-dc8bb9b45-28wwq        0/1     Terminating   0          6m22s
nginx-dc8bb9b45-28wwq        0/1     Terminating   0          6m26s
nginx-dc8bb9b45-28wwq        0/1     Terminating   0          6m26s
nginx-dc8bb9b45-vdmp5        0/1     Terminating   0          6m26s
nginx-dc8bb9b45-vdmp5        0/1     Terminating   0          6m26s
nginx-dc8bb9b45-wkc68        0/1     Terminating   0          6m27s
nginx-dc8bb9b45-wkc68        0/1     Terminating   0          6m27s
nginx-dc8bb9b45-x7j4g        0/1     Terminating   0          6m27s
nginx-dc8bb9b45-x7j4g        0/1     Terminating   0          6m27s
```

---

## Cleanup

```sh
kubectl delete deployment nginx -n codewizard
kubectl delete deployment multitool -n codewizard
```
