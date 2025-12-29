
# K8S Hands-on 



---

## Logging

- Welcome to the `Logging` hands-on lab! In this tutorial, we will learn the essentials of `Logging` in Kubernetes clusters.
- We will deploy a sample application, configure log collection, and explore logs using popular tools like `Fluentd`, `Elasticsearch`, and `Kibana` (EFK stack).

---
<!-- omit in toc -->
## Pre requirements

- Kubernetes cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster
- [Helm](https://helm.sh/docs/intro/install/) installed for easier deployment

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

### **<kbd>CTRL</kbd> + click to open in new window**
<!-- omit in toc -->
---

## What will we learn?

- Why `Logging` is important in Kubernetes
- How to deploy a sample app that generates logs
- How to collect logs using Fluentd
- How to store and search logs with `Elasticsearch`
- How to visualize logs with `Kibana`
- Troubleshooting and best practices

---

## Introduction

- `Logging` is critical for monitoring, debugging, and auditing applications in Kubernetes.
- Kubernetes does not provide a builtin, centralized `Logging` solution, but it allows us to integrate with many `Logging` stacks.
- We will set up the EFK stack (`Elasticsearch`, `Fluentd`, `Kibana`) to collect, store, and visualize logs from our cluster.

---

## Lab

### Step 01 - Deploy a Sample Application

- Deploy a simple `Nginx` application that generates access logs.

```sh
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
```

- Check that the pod is running:

```sh
kubectl get pods
```

### Step 02 - Deploy `Elasticsearch`

- Deploy `Elasticsearch` using `Helm`:

```sh
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch --set replicas=1 --set minimumMasterNodes=1
```

- Wait for the pod to be ready and check its status:

```sh
kubectl get pods
```


### Step 03 - Deploy `Kibana`

- Deploy `Kibana` using `Helm`:

```sh
helm install kibana elastic/kibana
```

- Forward the `Kibana` port:

```sh
kubectl port-forward svc/kibana-kibana 5601:5601 &
```

!!! warning "If you are running this lab in Google Cloud Shell:"
    1. After running the port-forward command above, click the **Web Preview** button in the Cloud Shell toolbar (usually at the top right).
    2. Enter port `5601` when prompted.
    3. This will open `Kibana` in a new browser tab at a URL like `https://<cloudshell-id>.shell.cloud.google.com/?port=5601`.
    4. If you see a warning about an untrusted connection, you can safely proceed.

- Access `Kibana` at [http://localhost:5601](http://localhost:5601) (if running locally) or via the Cloud Shell Web Preview, as explained above.

### Step 04 - Deploy `Fluentd`

- Deploy `Fluentd` as a `DaemonSet` to collect logs from all nodes and forward them to `Elasticsearch`.

```sh
kubectl apply -f https://raw.githubusercontent.com/fluent/fluentd-kubernetes-daemonset/master/fluentd-daemonset-elasticsearch-rbac.yaml
```

- Check that `Fluentd` pods are running:

```sh
kubectl get pods -l app=fluentd
```

### Step 05 - Generate and View Logs

- Access the `Nginx` service to generate logs:

```sh
minikube service nginx
```


In `Kibana`, configure an index pattern to view logs:

1. Open Kibana in your browser (using the Cloud Shell Web Preview as described above).
2. In the left menu, click **Stack Management** > **Kibana** > **Index Patterns**.
3. Click **Create index pattern**.
4. In the "Index pattern" field, enter `fluentd-*` (or `logstash-*` if your logs use that prefix).
5. Click **Next step**.
6. For the time field, select `@timestamp` and click **Create index pattern**.
7. Go to **Discover** in the left menu to view and search your logs.

Explore the logs, search, and visualize traffic.

---

## Troubleshooting

##### **Pods not starting:**
  - Check pod status and logs:

```sh
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

<br>

##### **Kibana not reachable:**

  - Ensure port-forward is running and no firewall is blocking port 5601.

<br>

##### **No logs in Kibana:**

  - Check Fluentd and Elasticsearch pod logs for errors.
  - Ensure index pattern is set up correctly in Kibana.

---

## Cleanup

- To remove all resources created by this lab:

```sh
helm uninstall elasticsearch
helm uninstall kibana
kubectl delete deployment nginx
kubectl delete service nginx
kubectl delete -f https://raw.githubusercontent.com/fluent/fluentd-kubernetes-daemonset/master/fluentd-daemonset-elasticsearch-rbac.yaml
```

---

## Next Steps

- Try deploying other logging stacks like `Loki` + `Grafana`.
- Explore log aggregation, alerting, and retention policies.
- Integrate logging with monitoring and alerting tools.
- Read more in the [Kubernetes logging documentation](https://kubernetes.io/docs/concepts/cluster-administration/logging/).
