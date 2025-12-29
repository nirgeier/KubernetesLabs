
# K8S Hands-on 



---

# Helm Chart

- Welcome to the `Helm` Chart hands-on lab! In this tutorial, you'll learn the essentials of `Helm` (version 3), the package manager for Kubernetes. 
- You'll build, package, install, and manage applications using `Helm` charts, gaining practical experience with real Kubernetes resources.

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

## What will you learn

- What `Helm` is and why is it useful
- `Helm` chart structure and key files
- Common `Helm` commands for managing releases
- How to create, pack, install, upgrade, and rollback a `Helm` chart
- Troubleshooting and best practices

---

## Introduction

- `Helm` is the **package manager** for Kubernetes. 
- It simplifies the deployment, management, and upgrade of applications on your Kubernetes cluster. 
- `Helm` helps you manage Kubernetes applications by providing a way to define, install, and upgrade complex Kubernetes applications.
- When packing applications as `Helm` charts, you gain a standardized and reusable approach for deploying and managing your services.

- A `Helm` chart consists of a few files that define the Kubernetes resources that will be **created** when the chart is installed. 
  - These files include the:
    - `Chart.yaml` file, which contains metadata about the chart, such as its name and version, and the chart's dependencies and maintainers.
    - `values.yaml` file, which contains the configuration values for the chart. 
    - The `templates` directory which contains the Kubernetes resource templates to be used to create the actual resources in the cluster.

### Terminology

* `Chart`
    - A `Helm` package is called a **chart**.
    - Charts are versioned, shareable packages that contain all the Kubernetes resources needed to run an application.

* `Release`
    - A specific instance of a chart is called a **release**.
    - Each release is a deployed *version of a chart*, with its own configuration, resources, and revision history.
  
* `Repository`
    - A collection of charts is stored in a `Helm` repository.
    - `Helm` charts can be hosted in public or private repositories for easy sharing and distribution.

### Chart files and folders

| Filename/Folder | Description                                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| `Chart.yaml`    | Contains metadata about the chart, including its name, version, dependencies, and maintainers.               |
| `values.yaml`   | Defines **default configuration** values for the chart. Users can override these values during installation. |
| `templates/`    | Directory containing Kubernetes manifest templates written in the Go template language.                      |
| `charts/`       | Directory containing dependencies of the chart.                                                              |
| `README.md`     | Documentation for the chart, explaining how to use and configure it.                                         |

##### codewizard-helm-demo Helm Chart tructure

```sh
- Chart.yaml        # Defines chart metadata and values schema
- values.yaml       # Default configuration values
- templates/        # Deployment templates using Go templating language
  - deployment.yaml # Deployment manifest template
  - service.yaml    # Service manifest template
- README.md         # Documentation for your chart 
```  

### Common `Helm` Commands 

Here are some of the most common `Helm` commands you’ll use when working with `Helm` charts:

| Command                                          | Description                                                                                              |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `helm` **create**      `chart-name`                | Create a new `Helm` chart with the specified name.                                                         |
| `helm` **install**     `release-name` `chart-path` | Install a `Helm` chart to your Kubernetes cluster.                                                         |
| `helm` **upgrade**     `release-name` `chart-path` | Upgrade an installed release with a new version of a chart.                                                |
| `helm` **uninstall**   `release-name`              | Uninstall a release from the Kubernetes cluster.                                                           |
| `helm` **list**                                    | List all installed `Helm` releases in the cluster.                                                         |
| `helm` **status**      `release-name`              | Show the status of a deployed `Helm` release.                                                              |
| `helm` **rollback**    `release-name` `revision`   | Rollback a release to a previous revision.                                                                 |
| `helm` **get all**     `release-name`              | Retrieve all information about a deployed release (e.g., templates, values).                               |
| `helm` **show values** `chart-name`                | Show the default values of a `Helm` chart.                                                                 |
| `helm` **template**    `chart-name`                | Generate the output of the `Helm` chart.                                                                   |
| `helm` **lint**        `chart-path`                | This command takes a path to a chart and runs a series of tests to verify that the chart is well-formed.   |
| `helm` **history**     `chart-name`                | This command takes a path to a chart and runs a series of tests to verify that the chart is well-formed.   |


---

# Lab

### Step 01 - Installing `Helm` 

- Before you can use the `codewizard-helm-demo` chart, you'll need to **install** `Helm` on your local machine. 

- `Helm` install methods by OS:

  | OS                       | Command                                                                            |
  | ------------------------ | ---------------------------------------------------------------------------------- |
  | Linux                    | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |
  | MacOS                    | ``brew install helm``                                                              |
  | Windows (via Chocolatey) | ``choco install kubernetes-helm``                                                  |
  
#### Verify Installation
  
  - To confirm that `Helm` is installed correctly, run:

  ```bash
  $ helm version

  ## Expected output
  version.BuildInfo{Version:"xx", GitCommit:"xx", GitTreeState:"clean", GoVersion:"xx"}
  ```

---

### Step 02 - Creating our `Helm` chart

- Creating our custom `codewizard-helm-demo` `Helm` chart
- The custom `codewizard-helm-demo` `Helm` chart is build upon the following K8S resources:

    - ConfigMap
    - Deployment
    - Service

- As mentioned above, we will also have the following `Helm` resources:
    - Chart.yaml
    - values.yaml
    - templates/\_helpers.tpl

#### Create a New Chart

- First, we need to create a `Helm` chart using the ``helm create`` command. 
- This command will generate the necessary file structure for your new chart.

  ```bash
  helm create codewizard-helm-demo
  ```

??? Question "What is the result of this command?"
    Examine the chart structure!

#### Navigate to the Chart Directory 

  ```bash
  cd codewizard-helm-demo
  ```

#### Write the chart content

  - Copy the content of the chart folder (in this lab) to the chart directory (overwriting the files).

### Step 03 - Pack the chart

- After we have created or customized our chart, we need to pack it as `.tgz` file, which can then be shared or installed.

#### helm package

!!! warning "Helm Package"
    `helm package` packages a chart into a **versioned chart archive file**.  
    If a path is given, this will "look" at that path for a chart which must contain a `Chart.yaml` file and then pack that directory.

```sh
helm package codewizard-helm-demo
```

- This command will create a file called `codewizard-helm-demo-<version>.tgz` inside your current directory.


### Step 04 - Validate the chart content

#### ``helm template``

- `Helm` allows you to **generate** the Kubernetes manifests based on the templates and values files without actually installing the chart. 
- This is useful to preview what the generated resources will look like:

```sh
helm template codewizard-helm-demo

## This will output the rendered Kubernetes manifests to your terminal
```

### Step 05 - Install the chart

- Install the `codewizard-helm-demo` chart into Kubernetes cluster


#### The ``helm install`` command

- This command installs a chart archive.
- The install argument must be a chart reference, a path to a packed chart, a path to an unpacked chart directory or a URL.
- To override values in a chart, use:
    - `--values` - pass in a file 
    - `--set` - pass configuration from the command line


```sh
# Install the packed helm chart
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz
```

### Step 06 - Verify the installation

- Examine newly created `Helm` chart release, and all cluster created resources:

```sh
# List the installed helms
helm ls

# Check the resources
kubectl get all -n codewizard
```

### Step 07 - Test the service

- Perform an `HTTP GET` request, send it to the newly created cluster service.
- Confirm that the response contains the `CodeWizard Helm Demo` message passed from the `values.yaml` file.

```sh
kubectl run busybox         \
        --image=busybox     \
        --rm                \
        -it                 \
        --restart=Never     \
        -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local"

### Output: 
CodeWizard Helm Demo
```

### Step 08 - Upgrade the release to newer version

- Perform a Helm upgrade on the `codewizard-helm-demo` release:

```sh
# upgrade and pass a different message than the one from the default values
# Use the --set to pass the desired value
helm  upgrade \
  codewizard-helm-demo \
  codewizard-helm-demo-0.1.0.tgz \
  --set nginx.conf.message="Helm Rocks"
```

### Step 09 - Check the upgrade

- Perform another `HTTP GET` request.
- Confirm that the response now has the updated message `Helm Rocks`:

```sh
kubectl run busybox         \
        --image=busybox     \
        --rm                \
        -it                 \
        --restart=Never     \
        -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local"

### Output: 
Helm Rocks
```

### Step 10 - History

- Examine the `codewizard-helm-demo` release history

#### `helm history`
  
  - `helm history` prints historical revisions for a given release.
  - A default maximum of 256 revisions will be returned.
  
```sh
$ helm history codewizard-helm-demo

### Sample output
REVISION        UPDATED    STATUS          CHART                           APP VERSION     DESCRIPTION     
1               ...        superseded      codewizard-helm-demo-0.1.0      1.19.7          Install complete
2               ...        deployed        codewizard-helm-demo-0.1.0      1.19.7          Upgrade complete
```

### Step 11 - Rollback

#### `helm rollback`

  - Rollback the `codewizard-helm-demo` release to previous version:

```sh
$ helm rollback codewizard-helm-demo

### Output:
Rollback was a success! Happy Helming!
```

- Check again to verify that you get the original message!

---

## Finalize & Cleanup

- To remove all resources created by this lab, uninstall the `codewizard-helm-demo` release:

```sh
helm uninstall codewizard-helm-demo
```

- (Optional) If you have created a dedicated namespace for this lab, you can delete it by runniung:

```sh
kubectl delete namespace codewizard
```

---

## Troubleshooting

- **Helm not found:**

Make sure `Helm` is installed and available in your `PATH`. 
Run the following to verify:

```sh
helm version
```

<br>

- **Pods not starting:**

Check pod status and logs by running the following commands:

```sh
kubectl get pods -n codewizard
kubectl describe pod <pod-name> -n codewizard
kubectl logs <pod-name> -n codewizard
```

<br>

- **Service not reachable:**

Ensure the service and pods are running by running the following commands:

```sh
kubectl get svc -n codewizard
kubectl get pods -n codewizard
```

<br>

- **Values not updated after upgrade:**

Double-check your `--set` or `--values` flags and confirm the upgrade by running:

```sh
helm get values codewizard-helm-demo
```

---

## Next Steps

- Try creating your own `Helm` chart for a different application.
- Explore `Helm` chart repositories like [Artifact Hub](https://artifacthub.io/).
- Learn about advanced `Helm` features, such as: dependencies, hooks, and chart testing.
- Integrate `Helm` with CI/CD pipelines for automated deployments.
- Read more in the [official Helm documentation](https://helm.sh/docs/).
