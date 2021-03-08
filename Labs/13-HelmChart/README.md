![](../../resources/k8s-logos.png)

---

# K8S Hands-on: Helm Chart Demon

- In This tutorial you will learn the basics of Helm Charts (verison 3).
- This demo will cover the following:
    -   build
    -   package
    -   install
    -   list packages

---

## PreRequirments
- [Helm](https://helm.sh/docs/intro/install/)
- K8S cluster

---

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)
### **<kbd>CTRL</kbd> + click to open in new window**   

---
## `codewizard-nginx-helm`

- The custom `codewizard-nginx-helm` Helm chart is build upon the foloowing K8S resources:
    -   ConfigMap
    -   Deployment
    -   Service
    -   Namespace

- Since we are using Helm we also have the following Helm resources:
    -   Chart.yaml
    -   values.yaml
    -   templates/_helpers.tpl

---

### Step 1 - Pack
Package the ```codewizard-nginx-helm``` chart

## `helm package`
> Package a chart directory into a chart archive. 
>  
> `helm package` packages a chart into a **versioned chart archive file**. 
>
> If a path is given, this will look at that path for a chart (which must contain a `Chart.yaml` file) and then package that directory.
```
helm package codewizard-nginx-helm
```

### Step 2 - install
- Install the ```codewizard-nginx-helm``` chart into Kubernetes cluster
- The install argument must be one of the following:
    -   Chart URL directory
    -   Path to a packaged chart
    -   Path to an unpacked chart 
    -   Chart URL

```
# Install the helm on the current cluster
helm install charts-demo codewizard-nginx-helm-0.1.0.tgz

# The output should be somethig similar to :
helm install charts-demo codewizard-helm-demo-0.1.0.tgz 
NAME: charts-demo
LAST DEPLOYED: .......
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

# STEP 3:
Examine newly created Helm chart release, and all cluster created resources

```
helm ls

# output shold be similar to 
NAME            NAMESPACE       REVISION        UPDATED    STATUS          CHART                           APP VERSION
charts-demo      default         1               ...        deployed        codewizard-helm-demo-0.1.0      1.19.7   

# check to see that the deployment 
kubectl get all -n codewizard
```

# STEP 4:
Perform an HTTP GET request, send it to the newly created cluster service and confirm that the response containse the message stored in the `values.yaml` file

```
kubectl run --image=busybox b1 --rm -it --restart=Never -- /bin/sh -c "wget -qO- http://charts-demo-codewizard-helm-demo.codewizard.svc.cluster.local"
```

# STEP 5:
Perform a Helm upgrade on the `charts-demo` release

```
helm upgrade charts-demo codewizard-nginx-helm-0.1.0.tgz --set nginx.conf.message="Helm Rocks"
```

# STEP 6:
Perform another HTTP GET request. Confirm that the response now has the updated message `Helm Rocks`

```
kubectl run --image=busybox bbox1 --rm -it --restart=Never \
-- /bin/sh -c "wget -qO- http://charts-demo-codewizard-nginx-helm"
```

# STEP 7:
Examine the `charts-demo` release history

```
helm history charts-demo
```

# STEP 8:
Rollback the `charts-demo` release to previous version

```
helm rollback charts-demo
```

# STEP 9:
Perform another HTTP GET request. Confirm that the response has now been reset to the ```CloudAcademy DevOps 2020 v1``` message stored in the ```values.yaml``` file

```
kubectl run --image=busybox bbox1 --rm -it --restart=Never \
-- /bin/sh -c "wget -qO- http://charts-demo-codewizard-nginx-helm"
```

# STEP 10:
Uninstall the `charts-demo` release

```
helm uninstall charts-demo
```