
# K8S Hands-on


---

# Writing custom Scheduler

- `Scheduling` is the process of selecting a node for a pod to run on.
- In this lab we will write our own pods `scheduler`.
- It is probably not something that you will ever need to do, but still it's a good practice to understand how scheduling works in K8S and how you can extend it.


---

<!-- omit in toc -->
## Pre Requirements

- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>
- [**kubectl**](https://kubernetes.io/docs/tasks/tools/) configured to interact with your cluster
- A `Git repository` (GitHub, GitLab, or Bitbucket) for storing application manifests
- Basic understanding of Kubernetes resources (Deployments, Services, etc.)

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

### **<kbd>CTRL</kbd> + click to open in new window**
<!-- omit in toc -->

---

## Custom Scheduler

- See further information in the official documentation: [Scheduler Configuration](https://kubernetes.io/docs/reference/scheduling/config)
- To schedule a given pod using a specific scheduler, specify the name of the scheduler in that specification `.spec.schedulerName`.

## A bit about scheduler

- Scheduling happens in a series of **stages** that are exposed through extension points.
- We can define several scheduling Profile. A scheduling Profile allows you to configure the different stages of scheduling in the `kube-scheduler`

---

## Sample `KubeSchedulerConfiguration`

```yaml
###
# Sample KubeSchedulerConfiguration
###
#
# You can configure `kube-scheduler` to run more than one profile.
# Each profile has an associated scheduler name and can have a different
# set of plugins configured in its extension points.

# With the following sample configuration, 
# the scheduler will run with two profiles: 
# - default plugins 
# - all scoring plugins disabled

apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
profiles:
  - schedulerName: default-scheduler
  - schedulerName: no-scoring-scheduler
    plugins:
      preScore:
        disabled:
        - name: '*'
      score:
        disabled:
        - name: '*'
```

- Once you have your scheduler code, you can use it in your pod scheduler: 

```yaml
# In this sample we use deployment but it will apply to any pod
...
apiVersion: apps/v1
kind: Deployment
spec:
    spec:
      # This is the import part of this file.
      # Here we define our custom scheduler
      schedulerName: CodeWizardScheduler # <------
      containers:
      - name: nginx
        image: nginx

```

### Sample bash scheduler

- The "trick" is loop over all the waiting pods and search for the custom scheduler match in `spec.schedulerName` 

```sh

...
  # Get a list of all our pods in pending state
  for POD in $(kubectl  get pods \
                        --server ${CLUSTER_URL} \
                        --all-namespaces \
                        --output jsonpath='{.items..metadata.name}' \
                        --field-selector=status.phase==Pending); 
    do

    # Get the desired schedulerName if th epod has defined any schedulerName
    CUSTOM_SCHEDULER_NAME=$(kubectl get pod ${POD} \
                                    --output jsonpath='{.spec.schedulerName}')

    # Check if the desired schedulerName is our custome one
    # If its a match this is where our custom scheduler will "jump in"
    if [ "${CUSTOM_SCHEDULER_NAME}" == "${CUSTOM_SCHEDULER}" ]; 
      then
        # Do your magic here ......
        # Schedule the PODS as you wish
    fi
    ...
```
