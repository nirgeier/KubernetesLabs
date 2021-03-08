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

- Since we are using Helm we also have the following Helm resources:
    -   Chart.yaml
    -   values.yaml
    -   templates/_helpers.tpl

---

# STEP 1:
Package the ```codewizard-nginx-helm``` chart

```
helm package codewizard-nginx-helm
```

# STEP 2:
Install the ```codewizard-nginx-helm``` chart into Kubernetes cluster

Note: assumes that you have a cluster credentials configured within your local ```~/.kube/config``` file

```
helm install ca-demo1 codewizard-nginx-helm-0.1.0.tgz
```

# STEP 3:
Examine newly created Helm chart release, and all cluster created resources

```
helm ls

kubectl get all
```

# STEP 4:
Perform an HTTP GET request, send it to the newly created cluster service and confirm that the response containse the ```CloudAcademy DevOps 2020 v1``` message stored in the ```values.yaml``` file

```
kubectl run --image=busybox bbox1 --rm -it --restart=Never \
-- /bin/sh -c "wget -qO- http://ca-demo1-codewizard-nginx-helm"
```

# STEP 5:
Perform a Helm upgrade on the ```ca-demo1``` release

```
helm upgrade ca-demo1 codewizard-nginx-helm-0.1.0.tgz \
--set nginx.conf.message="Helm Rocks"
```

# STEP 6:
Perform another HTTP GET request. Confirm that the response now has the updated message ```Helm Rocks```

```
kubectl run --image=busybox bbox1 --rm -it --restart=Never \
-- /bin/sh -c "wget -qO- http://ca-demo1-codewizard-nginx-helm"
```

# STEP 7:
Examine the ```ca-demo1``` release history

```
helm history ca-demo1
```

# STEP 8:
Rollback the ```ca-demo1``` release to previous version

```
helm rollback ca-demo1
```

# STEP 9:
Perform another HTTP GET request. Confirm that the response has now been reset to the ```CloudAcademy DevOps 2020 v1``` message stored in the ```values.yaml``` file

```
kubectl run --image=busybox bbox1 --rm -it --restart=Never \
-- /bin/sh -c "wget -qO- http://ca-demo1-codewizard-nginx-helm"
```

# STEP 10:
Uninstall the ```ca-demo1``` release

```
helm uninstall ca-demo1
```