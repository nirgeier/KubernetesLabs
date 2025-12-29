# K8S Hands-on



---



## Helm Operator 

- An in-depth Helm-based operator tutorial.
- The `Helm Operator` is a Kubernetes operator, allowing one to declaratively manage Helm chart releases.

---


### Pre-Requirements
- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)  
**<kbd>CTRL</kbd> + <kbd>click</kbd> to open in new window**

- Docker
- kubectl
- operator-sdk installed and configured
- `cluster-admin` permissions


### Install `operator-sdk`

```sh
# Grab the ARCH and OS
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')

# Get the desired download URL
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.23.0

# Download the Operator binaries
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}

# Install the release binary in your PATH
chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk
```

---

### Step 01 - Create a new project

- Use the CLI to create a new Helm-based nginx-operator project:

```sh
# Create the desired folder
mkdir nginx-operator

# Switch to the desired folder
cd nginx-operator

# Create the helm operator
operator-sdk                \
        init                \
        --kind    Nginx     \
        --group   demo      \
        --plugins helm      \
        --version v1alpha1  \
        --domain  codewizard.co.il
```

- This creates the `nginx-operator` project specifically for watching the `Nginx` resource with APIVersion `demo.codewizard.co.il/v1alpha1` and Kind `Nginx`.

### Operator SDK Project Layout

- The command will generate the following structure:

```sh
.
├── Dockerfile
├── Makefile
├── PROJECT
├── config
│   ├── crd
│   │   ├── bases
│   │   │   └── demo.codewizard.co.il_nginxes.yaml
│   │   └── kustomization.yaml
│   ├── default
│   │   ├── kustomization.yaml
│   │   ├── manager_auth_proxy_patch.yaml
│   │   └── manager_config_patch.yaml
│   ├── manager
│   │   ├── controller_manager_config.yaml
│   │   ├── kustomization.yaml
│   │   └── manager.yaml
│   ├── manifests
│   │   └── kustomization.yaml
│   ├── prometheus
│   │   ├── kustomization.yaml
│   │   └── monitor.yaml
│   ├── rbac
│   │   ├── auth_proxy_client_clusterrole.yaml
│   │   ├── auth_proxy_role.yaml
│   │   ├── auth_proxy_role_binding.yaml
│   │   ├── auth_proxy_service.yaml
│   │   ├── kustomization.yaml
│   │   ├── leader_election_role.yaml
│   │   ├── leader_election_role_binding.yaml
│   │   ├── nginx_editor_role.yaml
│   │   ├── nginx_viewer_role.yaml
│   │   ├── role.yaml
│   │   ├── role_binding.yaml
│   │   └── service_account.yaml
│   ├── samples
│   │   ├── demo_v1alpha1_nginx.yaml
│   │   └── kustomization.yaml
│   └── scorecard
│       ├── bases
│       │   └── config.yaml
│       ├── kustomization.yaml
│       └── patches
│           ├── basic.config.yaml
│           └── olm.config.yaml
├── helm-charts
│   └── nginx
│       ├── Chart.yaml
│       ├── templates
│       │   ├── NOTES.txt
│       │   ├── _helpers.tpl
│       │   ├── deployment.yaml
│       │   ├── hpa.yaml
│       │   ├── ingress.yaml
│       │   ├── service.yaml
│       │   ├── serviceaccount.yaml
│       │   └── tests
│       │       └── test-connection.yaml
│       └── values.yaml
├── tree.txt
└── watches.yaml

16 directories, 44 files
```

### Step 02 - Customize the operator logic

- For this example the nginx-operator will execute the following reconciliation logic for each Nginx Custom Resource (CR):
  - Create an nginx Deployment, if it doesn’t exist.
  - Create an nginx Service, if it doesn’t exist.
  - Create an nginx Ingress, if it is enabled and doesn’t exist.
  - Update the Deployment, Service, and Ingress, if they already exist but don’t match the desired configuration as specified by the Nginx CR.
  - Ensure that the Deployment, Service, and optional Ingress all match the desired configuration (e.g. replica count, image, service type, etc) as specified by the Nginx CR.

<br> 

#### Watch the Nginx CR

- By default, the Nginx-operator watches Nginx resource events as shown in `watches.yaml` and executes Helm releases using the specified chart:

```yaml
# Use the 'create api' subcommand to add watches to this file.
- group: demo
  version: v1alpha1
  kind: Nginx
  chart: helm-charts/nginx
```

<br>

### Reviewing the Nginx Helm Chart

- When a Helm operator project is created, the SDK creates an example Helm chart that contains a set of templates for a simple Nginx release.

- For this example, we have templates for deployment, service, and ingress resources, along with a `NOTES.txt` template, which Helm chart developers use to convey helpful information about a release.

<br>

### Understanding the Nginx CR spec

- Helm uses a concept called `values` to provide customizations to a Helm chart’s defaults, which are defined in the Helm chart’s `values.yaml` file.

- Overriding these defaults is as simple as setting the desired values in the CR spec.
- Let’s use the number of replicas value as an example.

- First, inspecting `helm-charts/nginx/values.yaml`, we can see that the chart has a value called `replicaCount` and it is set to `1` by default.

- Let’s update the value to 3 - `replicaCount: 3`.

  ```yaml
  # Update `config/samples/demo_v1alpha1_nginx.yaml` to look like the following:
  apiVersion: demo.codewizard.co.il/v1alpha1
  kind: Nginx
  metadata:
    name: nginx-sample
  spec:
    #... (Around line 33)
    replicaCount: 3 # <------- Adding our replicas count
  ```

- Similarly, we see that the default service port is set to `80`, but we would like to use `8888`, so we will again update config/samples/demo_v1alpha1_nginx.yaml by adding the service port override.


```yaml
# Update `config/samples/demo_v1alpha1_nginx.yaml` to look like the following:
apiVersion: demo.codewizard.co.il/v1alpha1
kind: Nginx
metadata:
  name: nginx-sample
spec:
  #... (Around line 36)
  service:
    port: 8888 # <------- Updating our service port
```

### Step 03 - Build the operator’s image

```sh
# Login to your DockerHub / acr / ecr or any other registry account

# Set the desired image name and tag

# In the Makefile update the following line
# Image URL to use all building/pushing image targets
IMG ?= controller:latest

# change it to your registry account
IMG ?= nirgeier/helm_operator:latest
```

- Now let's build and push the image:

```sh
make docker-build docker-push
```

### Step 04 - Deploy the operator to the cluster

```sh
make deploy

# Verify that the operator is deployed
kubectl get deployment -n nginx-operator-system
```


### Step 05 - Create the custom Nginx

```sh
# Deploy the custom nginx we created earlier
kubectl apply -f config/samples/demo_v1alpha1_nginx.yaml

# Ensure that the nginx-operator created
kubectl get deployment | grep nginx-sample

# Check that we have 3 replicas as defined earlier
kubectl get pods | grep nginx-sample

# Check that the port is set to 8888
kubectl get svc | grep nginx-sample
```

### Step 06 - Check the operator logic

```sh
# Update the replicaCount and remove the port
# Once we update the yaml we will check that the operator is working
# and updating the desired values

# Update the replicaCount in `config/samples/demo_v1alpha1_nginx.yaml`
replicaCount: 5

# Remark the service section in the yaml file
# We wish to see that the operator will use the default values
36   #service:
37   #  port: 8888
38   #  type: ClusterIP
```

- Apply the changes:

```sh
# Apply the changes
kubectl apply -f config/samples/demo_v1alpha1_nginx.yaml
```

- Check to see that the operator is working as expected:

```sh
# Ensure that the nginx-operator still running
kubectl get deployment | grep nginx-sample

# Deploy the custom nginx we created earlier
kubectl apply -f config/samples/demo_v1alpha1_nginx.yaml

# Check that we have 5 replicas as defined earlier
kubectl get pods | grep nginx-sample

# Check that the port is set back to its default (80)
kubectl get svc | grep nginx-sample
```

### Step07 - Logging / Debugging

- We can view the operator's logs using the following command:

```sh
# View the operator logs
kubectl logs deployment.apps/nginx-operator-controller-manager  -n nginx-operator-system -c manager
```

- Review the CR status and events:

```sh
kubectl describe nginxes.demo.codewizard.co.il
```
