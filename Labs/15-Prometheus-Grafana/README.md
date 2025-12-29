

<!-- omit in toc -->
# K8S Hands-on 



---
# Prometheus and Grafana Monitoring Lab

- In this lab, we will learn how to set up and configure *`Prometheus`  and `Grafana` for monitoring a Kubernetes cluster.
- You will install `Prometheus` to collect metrics from the cluster and `Grafana` to visualize those metrics.
- By the end of this lab, you will have a functional monitoring stack that provides insights into the health and performance of your Kubernetes environment.

---
<!-- omit in toc -->
## Pre requirements

- [`Helm`](https://helm.sh/docs/intro/install/) installed
- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster


[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

### **<kbd>CTRL</kbd> + click to open in new window**
<!-- omit in toc -->
---

<!-- omit in toc -->
## Prometheus and Grafana Setup and Configuration Guide 

- This guide serves as a comprehensive walkthrough of the steps to set up `Prometheus` and `Grafana` on your Kubernetes cluster. 
- It includes hands-on steps for installing `Prometheus` using `Helm`, configuring `Prometheus` to collect metrics, setting up `Grafana` to visualize key metrics, and automating the setup using a bash script.

---

## Introduction to Prometheus and Grafana 

### `Prometheus`

- `Prometheus` is an open-source systems monitoring and alerting toolkit designed for reliability and scalability. 
- It collects and stores metrics as time-series data, providing powerful querying capabilities. 
- It is commonly used in Kubernetes environments for monitoring cluster health, application performance, and infrastructure.

### `Grafana` 

- `Grafana` is a popular open-source data visualization tool that works well with `Prometheus`. 
- It allows you to create dashboards and visualize metrics in real-time, providing insights into system performance and application health. 
- `Grafana` supports a wide range of visualization options, including `graphs`, `heatmaps`, `tables`, and more.
- Together, `Prometheus` and `Grafana` provide a powerful stack for monitoring and alerting in Kubernetes.

---


## Part 01 - Installing Prometheus and Grafana  

!!! warning "Helm Charts"
    We will use [Helm](../13-HelmChart/README.md), to deploy Prometheus and Grafana.


### Step 01 - Add Prometheus and Grafana Helm Repositories 

- Let's add the official `Helm` charts for `Prometheus` and `Grafana`:


```bash
# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
# Update your Helm repositories to make sure they are up-to-date
helm repo update
```

### Step 02 - Install Prometheus Stack

- `Prometheus` is installed using the `prometheus-stack` `Helm` chart.

  ```bash
  # Install Prometheus 
  #          Alertmanager
  #          Node Exporter
  # Create the `monitoring` namespace if it does not exist.
  helm install  prometheus                                  \
                --namespace monitoring                      \
                --create-namespace                          \
                prometheus-community/kube-prometheus-stack  
  
  # Verify the status of the release using the following:
  helm status prometheus -n monitoring
  ```

### Step 03 - Install Grafana

  - Now, let's install `Grafana`.
  - `Grafana` will be deployed in the same `monitoring` namespace.

  ```bash
  helm install grafana grafana/grafana --namespace monitoring
  
  # Verify the status of the release using the following:
  helm status grafana -n monitoring
  ```

### Step 04 - Access Grafana 

- `Grafana` will expose a service in your Kubernetes cluster.
- To access it, you need a password and port forwarding.

  ```bash
  # In order to get the Grafana admin password, run the following command:
  kubectl get secret grafana          \
              --namespace monitoring  \
              -o jsonpath='{.data.admin-password}' | base64 --decode ; echo
  
  # Set the port forwarding so you can access the service using your browsers
  kubectl port-forward            \
          --namespace monitoring  \
          service/grafana 3000:80
  ```

- Verify that you can access `**Grafana`
  - Open your browser and navigate to [http://localhost:3000](http://localhost:3000)
  - The default login is: 
    - **Username** : `admin`
    - **Password** : (the password you retrieved earlier)


!!! warning "Accessing Grafana on Google Cloud Shell"

    If you are running your cluster in Google Cloud Shell, you cannot use `localhost` for port forwarding. Instead, use the Cloud Shell Web Preview:

    1. Run the port-forward command as usual:
        ```bash
        kubectl port-forward --namespace monitoring service/grafana 3000:80
        ```
    2. In Google Cloud Shell, click the "Web Preview" button (top right) and select "Preview on port 3000".
    3. Grafana will open in a new browser tab.  
      - **Username**: `admin`
      - **Password**: (the password you retrieved earlier)

    **Note:** You can use any available port (e.g., 3000, 3001) in the port-forward command, just match it in the Web Preview.


---


## Part 02 - Configuring Prometheus  

- `Prometheus` can collect various metrics from your Kubernetes cluster **automatically** if the right **exporters** are enabled. 
- The **kube-prometheus-stack** chart that you installed earlier automatically configures `Prometheus` to scrape a number of Kubernetes components (like `kubelet`, `node-exporter`, and `kube-state-metrics`) for various metrics.
  
### Step 01 - Verify Prometheus Metrics Collection 

- You can check if `Prometheus` is correctly scraping metrics by navigating to `Prometheus`' web UI.


```bash
# Port-forward the Prometheus service:
kubectl port-forward            \
        --namespace monitoring  \
        svc/prometheus-operated 9090:9090
```

- Verify that you can access `Prometheus`
  - Open [http://localhost:9090](http://localhost:9090)
  - In the expression field paste the following:

  ```bash
  # This query will show the current status of the `kube-state-metrics` job
  up{job="kube-state-metrics"}
  ```

!!! warning "Accessing Prometheus on Google Cloud Shell"

    If you are running your cluster in Google Cloud Shell, you cannot use `localhost` for port forwarding. Instead, use the Cloud Shell Web Preview:

    1. Run the port-forward command as usual:
        ```bash
        kubectl port-forward --namespace monitoring svc/prometheus-operated 9090:9090
        ```
    2. In Google Cloud Shell, click the "Web Preview" button (top right) and select "Preview on port 9090".
    3. Prometheus will open in a new browser tab.

    **Note:** You can use any available port (e.g., 9090, 9091) in the port-forward command, just match it in the Web Preview.

---

## Part 03 - Configuring Grafana 

- In this part we will set `grafana` to display the Cluster's CPUs, Memory, and Requests.
- `Grafana` dashboards can be configured to display **real-time metrics** for CPU, memory, and requests.
- `Prometheus` stores these metrics and `Grafana` will query `Prometheus` to display them.

### Step 01 - Add Prometheus as a Data Source in Grafana

  1. Log into `Grafana` at: [http://localhost:3000](http://localhost:3000), or use the **Cloud Shell Web Preview**.
  2. Click on the hamburger icon on the left sidebar to open the **Configuration** menu.
  3. Click on **Data Sources**.
  4. Click **Add data source** and choose **Prometheus**.
  5. In the **URL** field, enter the Prometheus server URL: `http://prometheus-operated:9090`.
  6. Click **Save & Test** to confirm that the connection is working.

### Step 02 - Create a Dashboard to Display Metrics 

  - Next step is to create a dashboard and panels to display the desired metrics.
  - To create a dashboard in `Grafana` for CPU, memory, and requests do the following:
 
  1. In `Grafana`, open the left sidebar menu and select **Dashboard**.
  2. Click **Add visualization**.
  3. Choose `Data Source` (as we defined it previously).
  4. In the panel editor, click on the `Code` option (right side of the query builder).
  5. Enter the below queries to visualize metric(s): 
     Note: To add new query click on the `+ Add query`
  6. Save the dashboard.
  
<br>

  - **CPU Usage**
  
  ```plaintext
  sum(rate(container_cpu_usage_seconds_total{namespace="default", container!="", container!="POD"}[5m])) by (pod, namespace)
  ```
 
  - **Memory Usage** :

  ```plaintext
  sum(container_memory_usage_bytes{namespace="default", container!="", container!="POD"}) by (pod, namespace)
  ```
 
  - **Request Count** :

  ```plaintext
  sum(rate(http_requests_total{job="kubelet", cluster="", namespace="default"}[5m])) by (pod, namespace)
  ```



### Step 03 - Get Number of Pods in the Cluster 

- To track the number of pods running in the cluster, add new panel with the following query:

```sh
# This query counts the number of pods running in all the namespaces
count(kube_pod_info{}) by (namespace)
```

- Add another query which will count the number of pods under the namespace `monitoring`:


  ```sh
  count(kube_pod_info{namespace="monitoring"}) by (namespace)
  ```
!!! note "Tip"
    We have already defined query based upon namespaces before....
    You can use the same approach to filter by other labels as well.
    
### Step 04: Customize the Panel 

  - Change the visualization by changing the **Graph Style**
   
