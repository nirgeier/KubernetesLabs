![](../../resources/k8s-logos.png)


<!-- omit in toc -->
# K8S Hands-on 

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)

---

<!-- omit in toc -->
# Helm Chart

- In This tutorial you will learn the basics of Helm Charts (version 3).
- This demo will cover the following:
  - build
  - package
  - install
  - list packages

---

<!-- omit in toc -->
## PreRequirements

- [Helm](https://helm.sh/docs/intro/install/)
- K8S cluster

---

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

<!-- omit in toc -->
### **<kbd>CTRL</kbd> + click to open in new window**

---

## Table of Contents 

- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
  - [Terminology](#terminology)
  - [Chart files and folders](#chart-files-and-folders)
  - [Common Helm Commands](#common-helm-commands)
- [Lab](#lab)
  - [Step 01. Installing Helm](#step-01-installing-helm)
    - [Verify Installation](#verify-installation)
  - [Step 02 - Creating our Helm chart](#step-02---creating-our-helm-chart)
    - [Create a New Chart](#create-a-new-chart)
    - [Navigate to the Chart Directory](#navigate-to-the-chart-directory)
    - [Write the chart content](#write-the-chart-content)
  - [Step 03 - Pack the chart](#step-03---pack-the-chart)
    - [`helm package`](#helm-package)
  - [Step 04 - Validate the chart content](#step-04---validate-the-chart-content)
    - [`helm template`](#helm-template)
  - [Step 05 - Install the chart](#step-05---install-the-chart)
    - [`helm install`](#helm-install)
  - [Step 06: Verify the installation](#step-06-verify-the-installation)
  - [Step 07: Test the service](#step-07-test-the-service)
  - [Step 08: Upgrade the release to newer version](#step-08-upgrade-the-release-to-newer-version)
  - [Step 09: Check the upgrade](#step-09-check-the-upgrade)
  - [Step 10 - History:](#step-10---history)
    - [`helm history`](#helm-history)
  - [Step 11 - Rollback](#step-11---rollback)
    - [`helm rollback`](#helm-rollback)
  - [Finalize:](#finalize)

---

## Introduction

- `Helm` is the **package manager** for Kubernetes. 
- It simplifies the deployment, management, and upgrade of applications on your Kubernetes cluster. 
- Helm helps you manage Kubernetes applications by providing a way to define, install, and upgrade complex Kubernetes applications.
- When packaging applications as Helm charts, you gain a standardized and reusable approach for deploying and managing your services.

- A Helm chart consists of a few files that define the Kubernetes resources that will be **created** when the chart is installed. 
  - These files include the:
    - `Chart.yaml` file, which contains metadata about the chart, such as its name and version, and the 
    - `values.yaml` file, which contains the configuration values for the chart. 
    - The `templates` directory contains the Kubernetes resource templates that will be used to create the actual resources in the cluster.

### Terminology

* `Chart`
  - A Helm package is called a **chart**.
  - Charts are versioned, shareable packages that contain all the Kubernetes resources needed to run an application.

* `Release`
  - A specific instance of a chart is called a **release**.
  - Each release is a deployed *version of a chart*, with its own configuration, resources, and revision history.
  
* `Repository`
  - A collection of charts is stored in a Helm repository.
  - Helm charts can be hosted in public or private repositories for easy sharing and distribution.

### Chart files and folders

| Filename/Folder | Description                                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| `Chart.yaml`    | Contains metadata about the chart, including its name, version, dependencies, and maintainers.               |
| `values.yaml`   | Defines **default configuration** values for the chart. Users can override these values during installation. |
| `templates/`    | Directory containing Kubernetes manifest templates written in the Go template language.                      |
| `charts/`       | Directory containing dependencies of the chart.                                                              |
| `README.md`     | Documentation for the chart, explaining how to use and configure it.                                         |

```sh
## codewizard-helm-demo
- Chart.yaml        # Defines chart metadata and values schema
- values.yaml       # Default configuration values
- templates/        # Deployment templates using Go templating language
  - deployment.yaml # Deployment manifest template
  - service.yaml    # Service manifest template
- README.md         # Documentation for your chart 
```  

### Common Helm Commands 

Here are some of the most common Helm commands you’ll use when working with Helm charts:
| Command                                          | Description                                                                                              |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| helm **create**      `chart-name`                | Create a new Helm chart with the specified name.                                                         |
| helm **install**     `release-name` `chart-path` | Install a Helm chart to your Kubernetes cluster.                                                         |
| helm **upgrade**     `release-name` `chart-path` | Upgrade an installed release with a new version of a chart.                                              |
|                                                  |                                                                                                          |
| helm **uninstall**   `release-name`              | Uninstall a release from the Kubernetes cluster.                                                         |
| helm **list**                                    | List all installed Helm releases in the cluster.                                                         |
| helm **status**      `release-name`              | Show the status of a deployed Helm release.                                                              |
| helm **rollback**    `release-name` `revision`   | Rollback a release to a previous revision.                                                               |
| helm **get all**     `release-name`              | Retrieve all information about a deployed release (e.g., templates, values).                             |
| helm **show values** `chart-name`                | Show the default values of a Helm chart.                                                                 |
| helm **template**    `chart-name`                | Generate the output of the Helm chart.                                                                   |
| helm **lint**        `chart-path`                | This command takes a path to a chart and runs a series of tests to verify that the chart is well-formed. |
| helm **history**     `chart-name`                | This command takes a path to a chart and runs a series of tests to verify that the chart is well-formed. |


---

## Lab

### Step 01. Installing Helm 

- Before you can use the `codewizard-helm-demo` chart, you'll need to **install** Helm on your local machine. 

- Steps to Install Helm 
    | OS                       | Command                                                                            |
    | ------------------------ | ---------------------------------------------------------------------------------- |
    | Linux                    | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |
    | MacOS                    | `brew install helm`                                                                |
    | Windows (via Chocolatey) | `choco install kubernetes-helm`                                                    |
  
#### Verify Installation
  
  - To confirm that Helm is installed correctly, run:
    ```bash
    $ helm version
    version.BuildInfo{Version:"xx", GitCommit:"xx", GitTreeState:"clean", GoVersion:"xx"}
    ```

### Step 02 - Creating our Helm chart

- Creating our custom `codewizard-helm-demo` Helm chart
- The custom `codewizard-helm-demo` Helm chart is build upon the following K8S resources:

  - ConfigMap
  - Deployment
  - Service

- As mentioned above we will also have the following Helm resources:
  - Chart.yaml
  - values.yaml
  - templates/\_helpers.tpl

#### Create a New Chart

- First, you need to create a Helm chart using the `helm create` command. 
- This command will generate the necessary file structure for your new chart.

  ```bash
  helm create codewizard-helm-demo
  ```

- ?? Question: What is result of this command? Examine the chart structure

#### Navigate to the Chart Directory 

  - Move into the  Chart Directory

    ```bash
    cd codewizard-helm-demo
    ```

#### Write the chart content

  - Copy the content of the chart folder (in this lab) to the chart directory (overwrite the files)

### Step 03 - Pack the chart

- After you’ve create or customized your chart, you need to pack it as `.tgz` file, which can then be shared or installed.

  #### `helm package`

> [!NOTE]
> `helm package` packages a chart into a **versioned chart archive file**.  
> If a path is given, this will look at that path for a chart which must contain a `Chart.yaml` file and then package that directory.

  ```sh
  helm package codewizard-helm-demo
  ```

- This command will create a file called `codewizard-helm-demo-<version>.tgz` in your current directory. 


### Step 04 - Validate the chart content

#### `helm template`

- Helm allows you to **generate** the Kubernetes manifests based on the templates and values files without actually installing the chart. 
- This is useful to preview what the generated resources will look like.

  ```sh
  helm template codewizard-helm-demo
  ```
- This will output the rendered Kubernetes manifests to your terminal.

### Step 05 - Install the chart

- Install the `codewizard-helm-demo` chart into Kubernetes cluster

#### `helm install`

- This command installs a chart archive.
- The install argument must be a chart reference, a path to a packaged chart, a path to an unpacked chart directory or a URL.
- To override values in a chart:
  - `--values` - pass in a file 
  - `--set` - pass configuration from the command line
  
  ```
  # Install the packed helm
  helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz
  ```

### Step 06: Verify the installation

- Examine newly created Helm chart release, and all cluster created resources

  ```
  # List the installed helms
  helm ls

  # Check the resources
  kubectl get all -n codewizard
  ```

### Step 07: Test the service

- Perform an HTTP GET request, send it to the newly created cluster service
- Confirm that the response contains the `CodeWizard Helm Demo` message passed from the `values.yaml` file

  ```sh
  kubectl run busybox         \
          --image=busybox     \
          --rm                \
          -it                 \
          --restart=Never     \
          -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local"

    ### Output: 
    `CodeWizard Helm Demo`
  ```

### Step 08: Upgrade the release to newer version

- Perform a Helm upgrade on the `codewizard-helm-demo` release

  ```
  # upgrade and pass different message than the one from the default values
  # Use the --set to pass the desired value
  helm  upgrade \
        codewizard-helm-demo \
        codewizard-helm-demo-0.1.0.tgz \
        --set nginx.conf.message="Helm Rocks"
  ```

### Step 09: Check the upgrade

- Perform another HTTP GET request.
- Confirm that the response now has the updated message `Helm Rocks`

```sh
  kubectl run busybox         \
          --image=busybox     \
          --rm                \
          -it                 \
          --restart=Never     \
          -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local"

    ### Output: 
    `Helm Rocks`
  ```

### Step 10 - History:

- Examine the `codewizard-helm-demo` release history

  #### `helm history`
  
  - `helm history` prints historical revisions for a given release.
  - A default maximum of 256 revisions will be returned
  
  ```
  helm history codewizard-helm-demo

  ### Sample output
  REVISION        UPDATED    STATUS          CHART                           APP VERSION     DESCRIPTION     
  1               ...        superseded      codewizard-helm-demo-0.1.0      1.19.7          Install complete
  2               ...        deployed        codewizard-helm-demo-0.1.0      1.19.7          Upgrade complete
  ```

### Step 11 - Rollback

  #### `helm rollback`

  - Rollback the `codewizard-helm-demo` release to previous version

    ```sh
    helm rollback codewizard-helm-demo

    ### Output:
    Rollback was a success! Happy Helming!

    ```
  - Check again to verify that you get the original message

### Finalize:

  - Uninstall the `codewizard-helm-demo` release

    ```
    helm uninstall codewizard-helm-demo
    ```

<!-- navigation start -->

---

<div align="center">
:arrow_left:&nbsp;
  <a href="../12-Wordpress-MySQL-PVC">12-Wordpress-MySQL-PVC</a>
&nbsp;&nbsp;||&nbsp;&nbsp;  <a href="../14-Logging">14-Logging</a>
  &nbsp; :arrow_right: </div>

---

<div align="center">
  <small>&copy;CodeWizard LTD</small>
</div>

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)

<!-- navigation end -->
