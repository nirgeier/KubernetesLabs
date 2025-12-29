# K8S Hands-on



---
# Kube API Access from Pod


- In this lab, we will learn how to access the Kubernetes API from within a Pod.
- We will create a simple Pod that runs a script to query the Kubernetes API server and retrieve information about the cluster.

---

### Pre-Requirements
- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)  
**<kbd>CTRL</kbd> + <kbd>click</kbd> to open in new window**

---


### Part 01 - Build the docker image

- In order to demonstrate the API query we will build a custom docker image.
- It is optional to use the pre-build image and skip this step.

### Step 01 - The script which will be used for query K8S API

- In order to be able to access K8S API from within a pod, we will be using the following script:


```sh
# `api_query.sh`

#!/bin/sh

#################################
## Access the internal K8S API ##
#################################
# Point to the internal API server hostname
API_SERVER_URL=https://kubernetes.default.svc

# Path to ServiceAccount token
# The service account is mapped by the K8S Api server in the pods
SERVICE_ACCOUNT_FOLDER=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace if required
# NAMESPACE=$(cat ${SERVICE_ACCOUNT_FOLDER}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICE_ACCOUNT_FOLDER}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICE_ACCOUNT_FOLDER}/ca.crt

# Explore the API with TOKEN and the Certificate
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${API_SERVER_URL}/api
```

### Step 02 - Build the docker image

- For the pod image we will use the following Dockerfile:



```Dockerfile

# `Dockerfile`

FROM    alpine

# Update and install dependencies
RUN     apk add --update nodejs npm curl

# Copy the endpoint script
COPY    api_query.sh .

# Set the execution bit
RUN     chmod +x api_query.sh .
```

---

### Part 02 - Deploy the Pod to K8S

- Once the image is ready, we can deploy it as a pod to the cluster.
- The required resources are under the k8s folder.

### Step 01 - Run kustomization to deploy

- Deploy to the cluster

```sh
# Remove old content if any
kubectl kustomize k8s | kubectl delete -f -

# Deploy the content
kubectl kustomize k8s | kubectl apply -f -
```

### Step 02 - Query the K8S API

- Run the following script to verify that the connection to the API is working:

```sh
# Get the deployment pod name
POD_NAME=$(kubectl get pod -A -l app=monitor-app -o jsonpath="{.items[0].metadata.name}")

# Print out the logs to verify that the pods is connected to the API
kubectl exec -it -n codewizard $POD_NAME sh ./api_query.sh
```
