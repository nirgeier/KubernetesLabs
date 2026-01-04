<!-- header start -->
<a href="https://stackoverflow.com/users/1755598/codewizard"><img src="https://stackoverflow.com/users/flair/1755598.png" width="208" height="58" alt="profile for CodeWizard at Stack Overflow, Q&amp;A for professional and enthusiast programmers" title="profile for CodeWizard at Stack Overflow, Q&amp;A for professional and enthusiast programmers"></a>&emsp;&emsp;[![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/)&emsp;[![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=flat&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com)&emsp;[![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=flat&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)
<!-- header end -->

---

# Kubernetes Hands-on Repository

- A collection of Hands-on labs for Kubernetes (K8S).
- Each lab is a standalone lab and does not require to complete the previous labs.

---

![](./resources/lab.jpg)

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

### **<kbd>CTRL</kbd> + click to open in new window**

---

- List of the labs in this repository:

<!-- Labs list start -->

:green_book: [00-VerifyCluster](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/)  
:green_book: [01-Namespace](https://nirgeier.github.io/KubernetesLabs/01-Namespace/)  
:green_book: [02-Deployments-Imperative](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/)  
:green_book: [03-Deployments-Declarative](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/)  
:green_book: [04-Rollout](https://nirgeier.github.io/KubernetesLabs/04-Rollout/)  
:green_book: [05-Services](https://nirgeier.github.io/KubernetesLabs/05-Services/)  
:green_book: [06-DataStore](https://nirgeier.github.io/KubernetesLabs/06-DataStore/)  
:green_book: [07-nginx-Ingress](https://nirgeier.github.io/KubernetesLabs/07-nginx-Ingress/)  
:green_book: [08-Kustomization](https://nirgeier.github.io/KubernetesLabs/08-Kustomization/)  
:green_book: [09-StatefulSet](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/)  
:green_book: [10-Istio](https://nirgeier.github.io/KubernetesLabs/10-Istio/)  
:green_book: [11-CRD-Custom-Resource-Definition](https://nirgeier.github.io/KubernetesLabs/11-CRD-Custom-Resource-Definition/)  
:green_book: [12-Wordpress-MySQL-PVC](https://nirgeier.github.io/KubernetesLabs/12-Wordpress-MySQL-PVC/)  
:green_book: [13-HelmChart](https://nirgeier.github.io/KubernetesLabs/13-HelmChart/)  
:green_book: [14-Logging](https://nirgeier.github.io/KubernetesLabs/14-Logging/)  
:green_book: [15-Prometheus-Grafana](https://nirgeier.github.io/KubernetesLabs/15-Prometheus-Grafana/)  
:green_book: [16-Affinity-Taint-Tolleration](https://nirgeier.github.io/KubernetesLabs/16-Affinity-Taint-Tolleration/)  
:green_book: [17-PodDisruptionBudgets-PDB](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/)  
:green_book: [18-ArgoCD](https://nirgeier.github.io/KubernetesLabs/18-ArgoCD/)  
:green_book: [19-CustomScheduler](https://nirgeier.github.io/KubernetesLabs/19-CustomScheduler/)  
:green_book: [20-CronJob](https://nirgeier.github.io/KubernetesLabs/20-CronJob/)  
:green_book: [21-Auditing](https://nirgeier.github.io/KubernetesLabs/21-Auditing/)  
:green_book: [21-KubeAPI](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/)  
:green_book: [22-Rancher](https://nirgeier.github.io/KubernetesLabs/22-Rancher/)  
:green_book: [23-MetricServer](https://nirgeier.github.io/KubernetesLabs/23-MetricServer/)  
:green_book: [24-HelmOperator](https://nirgeier.github.io/KubernetesLabs/24-HelmOperator/)  
:green_book: [25-kubebuilder](https://nirgeier.github.io/KubernetesLabs/25-kubebuilder/)  
:green_book: [26-k9s](https://nirgeier.github.io/KubernetesLabs/26-k9s/)  
:green_book: [27-krew](https://nirgeier.github.io/KubernetesLabs/27-krew/)  
:green_book: [28-kubeapps](https://nirgeier.github.io/KubernetesLabs/28-kubeapps/)  
:green_book: [29-kubeadm](https://nirgeier.github.io/KubernetesLabs/29-kubeadm/)  
:green_book: [30-k9s](https://nirgeier.github.io/KubernetesLabs/30-k9s/)  

### Tasks

:blue_book: [Kubernetes-CLI-Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/)  
:blue_book: [Kubernetes-Service-Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/)  


---

:green_book: [00-VerifyCluster](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/)

- [01. Installing minikube](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/#01-Installing-minikube)
- [02. Start minikube](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/#02-Start-minikube)
- [03. Check the minikube status](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/#03-Check-the-minikube-status)
- [04. Verify that the cluster is up and running](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/#04-Verify-that-the-cluster-is-up-and-running)
- [05. Verify that you can "talk" to your cluster](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/#05-Verify-that-you-can-talk-to-your-cluster)
  - [05.01. Verify that you can "talk" to your cluster](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/#0501-Verify-that-you-can-talk-to-your-cluster)

:green_book: [01-Namespace](https://nirgeier.github.io/KubernetesLabs/01-Namespace/)

- [01. Create Namespace](https://nirgeier.github.io/KubernetesLabs/01-Namespace/#01-Create-Namespace)
  - [01.01. Create Namespace](https://nirgeier.github.io/KubernetesLabs/01-Namespace/#0101-Create-Namespace)
- [02. Setting the default Namespace for `kubectl`](https://nirgeier.github.io/KubernetesLabs/01-Namespace/#02-Setting-the-default-Namespace-for-kubectl)
- [03. Verify that you've updated the namespace](https://nirgeier.github.io/KubernetesLabs/01-Namespace/#03-Verify-that-youve-updated-the-namespace)

:green_book: [02-Deployments-Imperative](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/)

- [01. Create namespace](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/#01-Create-namespace)
- [02. Deploy multitool image](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/#02-Deploy-multitool-image)
- [03. Test the deployment](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/#03-Test-the-deployment)
  - [03.01. Create a Service using `kubectl expose`](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/#0301-Create-a-Service-using-kubectl-expose)
  - [03.02. Find the port & the IP which was assigned to our pod by the cluster.](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/#0302-Find-the-port--the-IP-which-was-assigned-to-our-pod-by-the-cluster)
  - [03.03. Test the deployment](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/#0303-Test-the-deployment)

:green_book: [03-Deployments-Declarative](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/)

- [01. Create namespace](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#01-Create-namespace)
- [02. Deploy nginx using yaml file (declarative)](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#02-Deploy-nginx-using-yaml-file-declarative)
- [03. Verify that the deployment is created:](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#03-Verify-that-the-deployment-is-created)
- [04. Check if the pods are running:](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#04-Check-if-the-pods-are-running)
- [05. Update the yaml file with replica's value of 5](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#05-Update-the-yaml-file-with-replicas-value-of-5)
- [06. Update the deployment using `kubectl apply`](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#06-Update-the-deployment-using-kubectl-apply)
- [07. Scaling down with `kubectl scale`](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/#07-Scaling-down-with-kubectl-scale)

:green_book: [04-Rollout](https://nirgeier.github.io/KubernetesLabs/04-Rollout/)

- [01. Create namespace](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#01-Create-namespace)
- [02. Create the desired deployment](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#02-Create-the-desired-deployment)
- [03. Expose nginx as service](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#03-Expose-nginx-as-service)
- [04. Verify that the pods and the service are running](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#04-Verify-that-the-pods-and-the-service-are-running)
- [05. Change the number of replicas to 3](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#05-Change-the-number-of-replicas-to-3)
- [06. Verify that now we have 3 replicas](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#06-Verify-that-now-we-have-3-replicas)
- [07. Test the deployment](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#07-Test-the-deployment)
- [08. Deploy another version of nginx](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#08-Deploy-another-version-of-nginx)
- [09. Investigate rollout history:](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#09-Investigate-rollout-history)
- [10. Lets see what was changed during the previous updates:](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#10-Lets-see-what-was-changed-during-the-previous-updates)
- [11. Undo the version upgrade by rolling back and restoring previous version](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#11-Undo-the-version-upgrade-by-rolling-back-and-restoring-previous-version)
- [12. Rolling Restart](https://nirgeier.github.io/KubernetesLabs/04-Rollout/#12-Rolling-Restart)

:green_book: [05-Services](https://nirgeier.github.io/KubernetesLabs/05-Services/)

- [01. Create namespace and clear previous data if there is any](https://nirgeier.github.io/KubernetesLabs/05-Services/#01-Create-namespace-and-clear-previous-data-if-there-is-any)
- [02. Create the required resources for this hand-on](https://nirgeier.github.io/KubernetesLabs/05-Services/#02-Create-the-required-resources-for-this-hand-on)
- [03. Expose the nginx with ClusterIP](https://nirgeier.github.io/KubernetesLabs/05-Services/#03-Expose-the-nginx-with-ClusterIP)
- [04. Test the nginx with ClusterIP](https://nirgeier.github.io/KubernetesLabs/05-Services/#04-Test-the-nginx-with-ClusterIP)
  - [04.01. Test the nginx with ClusterIP](https://nirgeier.github.io/KubernetesLabs/05-Services/#0401-Test-the-nginx-with-ClusterIP)
  - [04.02. Test the nginx using the deployment name](https://nirgeier.github.io/KubernetesLabs/05-Services/#0402-Test-the-nginx-using-the-deployment-name)
  - [04.03. using the full DNS name](https://nirgeier.github.io/KubernetesLabs/05-Services/#0403-using-the-full-DNS-name)
- [05. Create NodePort](https://nirgeier.github.io/KubernetesLabs/05-Services/#05-Create-NodePort)
  - [05.01. Delete previous service](https://nirgeier.github.io/KubernetesLabs/05-Services/#0501-Delete-previous-service)
  - [05.02. Create `NodePort` Service](https://nirgeier.github.io/KubernetesLabs/05-Services/#0502-Create-NodePort-Service)
  - [05.03. Test the `NodePort` Service](https://nirgeier.github.io/KubernetesLabs/05-Services/#0503-Test-the-NodePort-Service)
- [06. Create LoadBalancer (only if you are on real cloud)](https://nirgeier.github.io/KubernetesLabs/05-Services/#06-Create-LoadBalancer-only-if-you-are-on-real-cloud)
  - [06.01. Delete previous service](https://nirgeier.github.io/KubernetesLabs/05-Services/#0601-Delete-previous-service)
  - [06.02. Create `LoadBalancer` Service](https://nirgeier.github.io/KubernetesLabs/05-Services/#0602-Create-LoadBalancer-Service)
  - [06.03. Test the `LoadBalancer` Service](https://nirgeier.github.io/KubernetesLabs/05-Services/#0603-Test-the-LoadBalancer-Service)

:green_book: [06-DataStore](https://nirgeier.github.io/KubernetesLabs/06-DataStore/)

- [01. Create namespace and clear previous data if there is any](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#01-Create-namespace-and-clear-previous-data-if-there-is-any)
- [02. Build the docker container](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#02-Build-the-docker-container)
  - [02.01. write the server code](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0201-write-the-server-code)
  - [02.02. Write the DockerFile](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0202-Write-the-DockerFile)
  - [02.03. Build the docker container](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0203-Build-the-docker-container)
  - [02.04. Test the container](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0204-Test-the-container)
- [03. Using K8S deployment & Secrets/ConfigMap](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#03-Using-K8S-deployment--SecretsConfigMap)
  - [03.01. Writing the deployment & Service file](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0301-Writing-the-deployment--Service-file)
  - [03.02. Deploy to cluster](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0302-Deploy-to-cluster)
  - [03.03. Test the app](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0303-Test-the-app)
- [04. Using Secrets & config maps](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#04-Using-Secrets--config-maps)
  - [04.01. Create the desired secret and config map for this lab](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0401-Create-the-desired-secret-and-config-map-for-this-lab)
  - [04.02. Updating the Deployment to read the values from Secrets & ConfigMap](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0402-Updating-the-Deployment-to-read-the-values-from-Secrets--ConfigMap)
  - [04.03. Update the deployment to read values from K8S resources](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0403-Update-the-deployment-to-read-values-from-K8S-resources)
  - [04.04. Test the changes](https://nirgeier.github.io/KubernetesLabs/06-DataStore/#0404-Test-the-changes)

:green_book: [07-nginx-Ingress](https://nirgeier.github.io/KubernetesLabs/07-nginx-Ingress/)

:green_book: [08-Kustomization](https://nirgeier.github.io/KubernetesLabs/08-Kustomization/)

:green_book: [09-StatefulSet](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/)

- [01. Create namespace and clear previous data if there is any](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#01-Create-namespace-and-clear-previous-data-if-there-is-any)
- [02. Create and test the Stateful application](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#02-Create-and-test-the-Stateful-application)
- [03. Test the Stateful application](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#03-Test-the-Stateful-application)
- [04. Scale down the StatefulSet and check that its down](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#04-Scale-down-the-StatefulSet-and-check-that-its-down)
  - [04.01. Scale down the `Statefulset` to 0](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#0401-Scale-down-the-Statefulset-to-0)
  - [04.02. Verify that the pods Terminated](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#0402-Verify-that-the-pods-Terminated)
  - [04.03. Verify that the DB is not reachable](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#0403-Verify-that-the-DB-is-not-reachable)
- [05. Scale up again and verify that we still have the prevoius data](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#05-Scale-up-again-and-verify-that-we-still-have-the-prevoius-data)
  - [05.01. scale up the `Statefulset` to 1 or more](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#0501-scale-up-the-Statefulset-to-1-or-more)
  - [05.02. Verify that the pods is in Running status](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#0502-Verify-that-the-pods-is-in-Running-status)
  - [05.03. Verify that the pods is using the previous data](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/#0503-Verify-that-the-pods-is-using-the-previous-data)

:green_book: [10-Istio](https://nirgeier.github.io/KubernetesLabs/10-Istio/)

- [01. Download latest Istio release (Linux)](https://nirgeier.github.io/KubernetesLabs/10-Istio/#01-Download-latest-Istio-release-Linux)
- [01.01 Add the istioctl client to your path (Linux or macOS):](https://nirgeier.github.io/KubernetesLabs/10-Istio/#0101-Add-the-istioctl-client-to-your-path-Linux-or-macOS)
  - [01.02. Install Istio](https://nirgeier.github.io/KubernetesLabs/10-Istio/#0102-Install-Istio)
  - [01.03. Add the required label](https://nirgeier.github.io/KubernetesLabs/10-Istio/#0103-Add-the-required-label)
  - [01.02. Install Kiali server](https://nirgeier.github.io/KubernetesLabs/10-Istio/#0102-Install-Kiali-server)
- [02. Deploy the demo application](https://nirgeier.github.io/KubernetesLabs/10-Istio/#02-Deploy-the-demo-application)
  - [02.01. Check the installation](https://nirgeier.github.io/KubernetesLabs/10-Istio/#0201-Check-the-installation)
  - [02.02. Verify that Istio is working](https://nirgeier.github.io/KubernetesLabs/10-Istio/#0202-Verify-that-Istio-is-working)

:green_book: [11-CRD-Custom-Resource-Definition](https://nirgeier.github.io/KubernetesLabs/11-CRD-Custom-Resource-Definition/)

:green_book: [12-Wordpress-MySQL-PVC](https://nirgeier.github.io/KubernetesLabs/12-Wordpress-MySQL-PVC/)

:green_book: [13-HelmChart](https://nirgeier.github.io/KubernetesLabs/13-HelmChart/)

:green_book: [15-Prometheus-Grafana](https://nirgeier.github.io/KubernetesLabs/15-Prometheus-Grafana/)

:green_book: [16-Affinity-Taint-Tolleration](https://nirgeier.github.io/KubernetesLabs/16-Affinity-Taint-Tolleration/)

:green_book: [17-PodDisruptionBudgets-PDB](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/)

- [01. start minikube with Feature Gates](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/#01-start-minikube-with-Feature-Gates)
- [02. Check Node Pressure(s)](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/#02-Check-Node-Pressures)
- [03. Create 3 Pods using 50 MB each.](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/#03-Create-3-Pods-using-50-MB-each)
- [04. Check MemoryPressure](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/#04-Check-MemoryPressure)

:green_book: [19-CustomScheduler](https://nirgeier.github.io/KubernetesLabs/19-CustomScheduler/)

:green_book: [20-CronJob](https://nirgeier.github.io/KubernetesLabs/20-CronJob/)

:green_book: [21-KubeAPI](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/)

- [01. Build the docker image](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/#01-Build-the-docker-image)
  - [01.01. The script which will be used for query K8S API](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/#0101-The-script-which-will-be-used-for-query-K8S-API)
  - [01.02. Build the docker image](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/#0102-Build-the-docker-image)
- [02. Deploy the Pod to K8S](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/#02-Deploy-the-Pod-to-K8S)
  - [02.01. Run kustomization to deploy](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/#0201-Run-kustomization-to-deploy)
  - [02.02. Query the K8S API](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/#0202-Query-the-K8S-API)
  

:blue_book: [Kubernetes-CLI-Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/)

- [01. Kubernetes Pod Workflow](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#01-kubernetes-pod-workflow)
- [02. Pod Debugging Challenge](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#02-pod-debugging-challenge)
- [03. Imperative to Declarative](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#03-imperative-to-declarative)
- [04. Scaling Deployments](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#04-scaling-deployments)
- [05. Rolling Updates and Rollbacks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#05-rolling-updates-and-rollbacks)
- [06. ConfigMaps and Environment Variables](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#06-configmaps-and-environment-variables)
- [07. Secrets Management](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#07-secrets-management)
- [08. Persistent Storage with PVCs](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#08-persistent-storage-with-pvcs)
- [09. Multi-Container Pods](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#09-multi-container-pods)
- [10. Jobs and CronJobs](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#10-jobs-and-cronjobs)
- [11. Namespaces and Isolation](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#11-namespaces-and-isolation)
- [12. Resource Limits and Quotas](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#12-resource-limits-and-quotas)
- [13. Liveness and Readiness Probes](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#13-liveness-and-readiness-probes)
- [14. Node Selection and Affinity](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/#14-node-selection-and-affinity)

:blue_book: [Kubernetes-Service-Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/)

- [01. Basic Service Exposure (ClusterIP)](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#01-basic-service-exposure-clusterip)
- [02. NodePort & LoadBalancer](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#02-nodeport--loadbalancer)
- [03. Service Discovery with DNS (FQDN)](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#03-service-discovery-with-dns-fqdn)
- [04. Headless Services](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#04-headless-services)
- [05. ExternalName Service](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#05-externalname-service)
- [06. Manual Endpoints](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#06-manual-endpoints)
- [07. Session Affinity](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#07-session-affinity)
- [08. Multi-Port Service](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/#08-multi-port-service)

<!-- Labs list ends -->
