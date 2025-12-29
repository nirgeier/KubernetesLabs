
# K8S Hands-on



---

# ArgoCD

- In this tutorial, we will learn the essentials of `ArgoCD`, a declarative GitOps continuous delivery tool for Kubernetes.
- We will install `ArgoCD`, deploy applications, sync resources from Git repositories, and gain practical experience with GitOps workflows.

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

## What will we learn?

- What `ArgoCD` is and why it's useful for GitOps.
- How to install and configure `ArgoCD` on Kubernetes.
- `ArgoCD` core concepts: Applications, Projects, and Sync.
- How to deploy applications from `Git repositories`.
- Application health and sync status monitoring.
- Rollback and sync strategies.
- Best practices for GitOps workflows.

---

### What is ArgoCD?

- `ArgoCD` is a declarative, GitOps continuous delivery tool for Kubernetes.
- It follows the `GitOps` pattern where Git repositories are the source of truth for defining the desired application state.
- `ArgoCD` automates the deployment of the desired application states in the specified target environments.

### Why ArgoCD?

- **GitOps Workflow**: Uses Git as the single source of truth.
- **Automated Deployment**: Automatically syncs your Kubernetes cluster with Git repositories.
- **Application Health Monitoring**: Continuous monitoring of deployed applications.
- **Rollback Capabilities**: Easy rollback to previous versions.
- **Multi-Cluster Support**: Manage applications across multiple clusters.
- **SSO Integration**: Supports various SSO providers for authentication.
- **RBAC**: Fine-grained access control.
- **Audit Trail**: Full audit trail of all operations.

### Terminology

* **Application**
    - An `ArgoCD` **Application** is a Kubernetes resource object representing a deployed application instance in an environment.
    - It defines the source repository, target cluster, and sync policies.

* **Project**
    - An `ArgoCD` **Project** provides a logical grouping of applications.
    - Projects are useful for organizing applications and implementing RBAC.

* **Sync**
    - **Sync** is the process of making a live cluster state match the desired state defined in Git.
    - Sync can run manually or automatically.

* **Sync Status**
    - Indicates whether the live state matches the Git state.
    - Status can be: **Synced**, **OutOfSync**, or **Unknown**.

* **Health Status**
    - Indicates the health of the application resources.
    - Status can be: **Healthy**, **Progressing**, **Degraded**, **Suspended**, or **Missing**.

### ArgoCD Architecture

| Component                | Description                                                                                    |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| **API Server**           | Exposes the API consumed by Web UI, CLI, and CI/CD systems                                     |
| **Repository Server**    | Maintains a local cache of Git repositories holding application manifests                      |
| **Application Controller** | Monitors running applications and compares the current live state against the desired state   |
| **Dex**                  | Identity service for integrating with external identity providers                              |
| **Redis**                | Used for caching                                                                               |

### Common ArgoCD CLI Commands

| Command                                               | Description                                                          |
| ----------------------------------------------------- | -------------------------------------------------------------------- |
| `argocd login <server>`                               | Login to `ArgoCD` server                                               |
| `argocd app create <app-name>`                        | Create a new application                                             |
| `argocd app list`                                     | List all applications                                                |
| `argocd app get <app-name>`                           | Get application details                                              |
| `argocd app sync <app-name>`                          | Sync (deploy) an application                                         |
| `argocd app delete <app-name>`                        | Delete an application                                                |
| `argocd app set <app-name>`                           | Update application parameters                                        |
| `argocd app diff <app-name>`                          | Show differences between Git and live state                          |
| `argocd app history <app-name>`                       | Show application deployment history                                  |
| `argocd app rollback <app-name> <revision>`           | Rollback to a previous revision                                      |

---

# Lab

## Part 01 - Installing ArgoCD

### Step 01 - Create an ArgoCD Namespace

- Create a dedicated namespace for `ArgoCD`:

```bash
kubectl create namespace argocd
```

### Step 02 - Install ArgoCD

- Install `ArgoCD` using the official installation manifest:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 03 - Verify Installation

- Check that all `ArgoCD` pods are running:

```bash
kubectl get pods -n argocd
```

- Expected output should show all pods in **Running** status:

```plaintext
NAME                                  READY   STATUS    RESTARTS   AGE
argocd-application-controller-0       1/1     Running   0          2m
argocd-dex-server-xxx                 1/1     Running   0          2m
argocd-redis-xxx                      1/1     Running   0          2m
argocd-repo-server-xxx                1/1     Running   0          2m
argocd-server-xxx                     1/1     Running   0          2m
```

### Step 04 - Expose ArgoCD Server

- By default, the `ArgoCD` API server is not exposed externally. 
- We' will use port-forwarding to access it, by running:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

- Alternatively, you can change the service type to **LoadBalancer** or create an **Ingress**:

```bash
# Change to LoadBalancer (for cloud environments)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Or use NodePort (for local/development)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

### Step 05 - Get Initial Admin Password

- The initial password for the `admin` user is auto-generated and stored as a secret by running the following command:

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

!!! note
    Save this password - you'll need it to login to the ArgoCD UI later.

### Step 06 - Access ArgoCD UI

- Open your browser and navigate to:
    - **Port-forward**: `https://localhost:8080`
    - **LoadBalancer**: Use the external IP
    - **NodePort**: Use `http://<node-ip>:<node-port>`

- Login with:
    - **Username**: `admin`
    - **Password**: (from Step 05)

---

## Part 02 - Installing ArgoCD CLI

### Step 01 - Download and Install ArgoCD CLI

- Install the `ArgoCD CLI` based on your operating system:

**Linux:**
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

**macOS:**
```bash
brew install argocd
```

**Windows (via Chocolatey):**
```bash
choco install argocd-cli
```

### Step 02 - Verify CLI Installation

```bash
argocd version --short
```

### Step 03 - Login via CLI

```bash
# If using port-forward
argocd login localhost:8080 --insecure

# You'll be prompted for username and password
```

### Step 04 - Change Admin Password (optional, but highly recommended)

```bash
argocd account update-password
```

---

## Part 03 - Deploying Your First Application

### Step 01 - Prepare a Git Repository

- For this lab, we will use a sample Git repository with Kubernetes manifests.
- You can use the `ArgoCD` example repository or your own:

```bash
# Sample repository URL
https://github.com/argoproj/argocd-example-apps.git
```

### Step 02 - Create an Application via CLI

- Create an `ArgoCD` application that deploys the guestbook app:

```bash
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

??? info "Command Explanation"
    - `--repo`: The Git repository URL
    - `--path`: Path within the repository where manifests are located
    - `--dest-server`: Target Kubernetes cluster (default is the cluster where ArgoCD is installed)
    - `--dest-namespace`: Target namespace for deployment

### Step 03 - View Application Status

```bash
# List all applications
argocd app list

# Get detailed information about the application
argocd app get guestbook
```

### Step 04 - Sync the Application

- Initially, the application status will be **OutOfSync**. 
- Sync it to deploy by running:

```bash
argocd app sync guestbook
```

### Step 05 - Verify Deployment

```bash
# Check the deployed resources
kubectl get all -n default

# You should see the guestbook deployment, service, and pods
```

### Step 06 - Access the Application

```bash
# Port-forward to access the guestbook service
kubectl port-forward svc/guestbook-ui -n default 8081:80

# Open browser to http://localhost:8081
```

---

## Part 04 - Creating Application via UI

### Step 01 - Access ArgoCD UI

- Navigate to the `ArgoCD` UI at `https://localhost:8080`

### Step 02 - Create a New Application

1. Click on **"+ NEW APP"** button.
2. Fill in the following details:
    - **Application Name**: `helm-guestbook`
    - **Project**: `default`
    - **Sync Policy**: `Manual` (or `Automatic` for auto-sync)
    - **Repository URL**: `https://github.com/argoproj/argocd-example-apps.git`
    - **Revision**: `HEAD`
    - **Path**: `helm-guestbook`
    - **Cluster URL**: `https://kubernetes.default.svc`
    - **Namespace**: `default`

3. Click **"CREATE"**.

### Step 03 - View Application in UI

- You should now be able to see the `helm-guestbook` application tile in the UI.
- Click on it to see the application topology.

### Step 04 - Sync via UI

- Click the **"SYNC"** button.
- Select the resources you want to sync (or select all).
- Click **"SYNCHRONIZE"**.

### Step 05 - Monitor Sync Progress

- Watch the sync progress in real-time.
- The UI will show each resource being created/updated.
- Once completed, all resources should show as **Healthy** and **Synced**.

---

## Part 05 - Application Management

### Step 01 - View Application Details

```bash
# Get full application details
argocd app get guestbook

# View application parameters
argocd app get guestbook --show-params
```

### Step 02 - View Sync History

```bash
# View deployment history
argocd app history guestbook
```

### Step 03 - View Differences

```bash
# Show differences between Git and live state
argocd app diff guestbook
```

### Step 04 - Manual Sync with Options

```bash
# Sync with prune (removes resources not in Git)
argocd app sync guestbook --prune

# Sync specific resources
argocd app sync guestbook --resource Deployment:guestbook-ui

# Dry-run sync
argocd app sync guestbook --dry-run
```

---

## Part 06 - Auto-Sync and Self-Healing

### Step 01 - Enable Auto-Sync

- Enable automatic synchronization so `ArgoCD` automatically deploys changes from Git:

```bash
argocd app set guestbook --sync-policy automated
```

### Step 02 - Enable Self-Healing

- Enable self-healing to automatically fix out-of-sync resources:

```bash
argocd app set guestbook --self-heal
```

### Step 03 - Enable Auto-Prune

- Enable auto-prune to automatically delete resources removed from Git:

```bash
argocd app set guestbook --auto-prune
```

### Step 04 - Test Auto-Sync

1. Make a change to your Git repository (e.g., change replica count).
2. Commit and push the change.
3. Watch as `ArgoCD` automatically detects and syncs the change:

```bash
# Watch the application sync status
watch argocd app get guestbook
```

### Step 05 - Test Self-Healing

1. Manually modify a deployed resource by running:

```bash
# Manually scale the deployment
kubectl scale deployment guestbook-ui --replicas=5
```

2. Watch as `ArgoCD` detects the drift and automatically restores the desired state:

```bash
# ArgoCD will revert the replica count to what's in Git
argocd app get guestbook
```

---

## Part 07 - Rollback

### Step 01 - View Application History

```bash
# View all deployment revisions
argocd app history guestbook
```

Example output:
```plaintext
ID  DATE                 REVISION
0   2025-11-10 10:15:30  abc123 (HEAD)
1   2025-11-10 10:20:45  def456
2   2025-11-10 10:25:30  ghi789
```

### Step 02 - Rollback to Previous Revision

```bash
# Rollback to revision ID 1
argocd app rollback guestbook 1
```

### Step 03 - Verify Rollback

```bash
# Verify the application state
argocd app get guestbook

# Check deployed resources
kubectl get all -n default
```

---

## Part 08 - Working with Helm Charts

### Step 01 - Create Helm-Based Application

```bash
argocd app create nginx-helm \
  --repo https://charts.bitnami.com/bitnami \
  --helm-chart nginx \
  --revision 15.1.0 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

### Step 02 - Set Helm Values

```bash
# Set Helm values
argocd app set nginx-helm \
  --helm-set service.type=NodePort \
  --helm-set replicaCount=3
```

### Step 03 - Sync Helm Application

```bash
argocd app sync nginx-helm
```

### Step 04 - View Helm Parameters

```bash
# View all Helm parameters
argocd app get nginx-helm --show-params
```

---

## Part 09 - Working with Kustomize

### Step 01 - Create Kustomize-Based Application

```bash
argocd app create kustomize-guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path kustomize-guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

### Step 02 - Sync Kustomize Application

```bash
argocd app sync kustomize-guestbook
```

### Step 03 - Verify Deployment

```bash
kubectl get all -n default -l app=kustomize-guestbook
```

---

## Part 10 - Projects and RBAC

### Step 01 - Create a New Project

```bash
argocd proj create my-project \
  --description "My demo project" \
  --src https://github.com/argoproj/argocd-example-apps.git \
  --dest https://kubernetes.default.svc,default \
  --dest https://kubernetes.default.svc,my-namespace
```

### Step 02 - List Projects

```bash
argocd proj list
```

### Step 03 - View Project Details

```bash
argocd proj get my-project
```

### Step 04 - Create Application in Project

```bash
argocd app create my-app \
  --project my-project \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

---

## Part 11 - Multi-Source Applications

### Step 01 - Create Multi-Source Application

- `ArgoCD` supports applications with multiple source repositories:

```yaml
# Save as multi-source-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: multi-source-app
  namespace: argocd
spec:
  project: default
  sources:
    - repoURL: https://github.com/argoproj/argocd-example-apps.git
      path: guestbook
      targetRevision: HEAD
    - repoURL: https://github.com/another-repo/configs.git
      path: overlays/prod
      targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step 02 - Apply Multi-Source Application

```bash
kubectl apply -f multi-source-app.yaml
```

---

## Part 12 - Sync Windows and Waves

### Step 01 - Configure Sync Windows

- Sync windows allow you to define time periods when syncs are allowed or denied:

```bash
# Add a sync window to allow syncs only during business hours
argocd proj windows add my-project \
  --kind allow \
  --schedule "0 9 * * 1-5" \
  --duration 8h \
  --applications "*"
```

### Step 02 - Configure Sync Waves

- Use annotations to control the order of resource synchronization:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Deploy first
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy after database
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy last
```

---

## Part 13 - Health Checks and Hooks

### Step 01 - Custom Health Checks

- Define custom health checks for your resources:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  resource.customizations: |
    cert-manager.io/Certificate:
      health.lua: |
        hs = {}
        if obj.status ~= nil then
          if obj.status.conditions ~= nil then
            for i, condition in ipairs(obj.status.conditions) do
              if condition.type == "Ready" and condition.status == "False" then
                hs.status = "Degraded"
                hs.message = condition.message
                return hs
              end
              if condition.type == "Ready" and condition.status == "True" then
                hs.status = "Healthy"
                hs.message = condition.message
                return hs
              end
            end
          end
        end
        hs.status = "Progressing"
        hs.message = "Waiting for certificate"
        return hs
```

### Step 02 - Sync Hooks

- Use hooks to execute actions during sync:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migration
        image: myapp/migration:latest
        command: ["./run-migrations.sh"]
      restartPolicy: Never
```

---

## Finalize & Cleanup

### Clean Up Applications

```bash
# Delete all applications
argocd app delete guestbook --cascade
argocd app delete helm-guestbook --cascade
argocd app delete nginx-helm --cascade
argocd app delete kustomize-guestbook --cascade

# Or delete via kubectl
kubectl delete applications -n argocd --all
```

### Uninstall ArgoCD

```bash
# Delete ArgoCD installation
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete the namespace
kubectl delete namespace argocd
```

---

## Troubleshooting

### ArgoCD Server Not Accessible

- Check if the `ArgoCD` server pod is running:

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
```

- Check the service:

```bash
kubectl get svc -n argocd argocd-server
```

### Application Stuck in Progressing State

- Check application details:

```bash
argocd app get <app-name>
kubectl describe application <app-name> -n argocd
```

- Check pod logs:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Sync Fails with Permission Errors

- Verify RBAC settings:

```bash
argocd proj get <project-name>
```

- Check if the destination namespace exists:

```bash
kubectl get namespace <namespace>
```

### Out of Sync Status

- View the differences:

```bash
argocd app diff <app-name>
```

- Force sync:

```bash
argocd app sync <app-name> --force
```

### Repository Connection Issues

- Test repository connectivity:

```bash
argocd repo add <repo-url> --username <username> --password <password>
argocd repo list
```

---

## Best Practices

### GitOps Workflow

1. **Single Source of Truth**: Keep all Kubernetes manifests in Git.
2. **Branch Strategy**: Use branches for different environments (dev, staging, prod).
3. **Pull Requests**: Use PRs for all changes with proper reviews.
4. **Automated Testing**: Validate manifests before merging.
5. **Rollback Strategy**: Use Git revert for rollbacks.

### Application Organization

1. **Use Projects**: Organize applications by team or environment.
2. **Naming Conventions**: Use clear, consistent naming.
3. **Sync Policies**: Choose appropriate sync policies per environment.
4. **Resource Limits**: Set proper resource limits in manifests.
5. **Health Checks**: Define custom health checks for complex resources.

### Security

1. **RBAC**: Implement fine-grained access control.
2. **SSO Integration**: Use SSO for authentication.
3. **Secret Management**: Use sealed-secrets or external secret managers.
4. **Network Policies**: Restrict `ArgoCD` network access.
5. **Audit Logging**: Enable and monitor audit logs.

### Monitoring

1. **Notifications**: Configure notifications for sync failures.
2. **Metrics**: Monitor `ArgoCD` metrics with `Prometheus`.
3. **Dashboards**: Create Grafana dashboards for visibility.
4. **Alerts**: Set up alerts for critical failures.
5. **Regular Reviews**: Periodically review application health.

---

## Next Steps

- Explore **ApplicationSets** for managing multiple applications.
- Integrate `ArgoCD` with **CI/CD pipelines**.
- Set up **notifications** using Slack, email, or webhooks.
- Implement **Progressive Delivery** with Argo Rollouts.
- Configure **SSO** integration with your identity provider.
- Set up **multi-cluster** management.
- Explore **ArgoCD Image Updater** for automated image updates.
- Read the [official ArgoCD documentation](https://argo-cd.readthedocs.io/)
- Join the [ArgoCD community](https://github.com/argoproj/argo-cd)

---

## Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Repository](https://github.com/argoproj/argo-cd)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://www.gitops.tech/)
- [Argo Rollouts (Progressive Delivery)](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
 
