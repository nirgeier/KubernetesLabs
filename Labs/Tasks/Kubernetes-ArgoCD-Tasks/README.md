# Kubernetes ArgoCD Tasks

- Hands-on Kubernetes exercises covering ArgoCD installation, CLI usage, application deployment, GitOps workflows, and the App of Apps pattern.
- Each task includes a description, scenario, and a detailed solution with step-by-step instructions.
- Practice these tasks to master ArgoCD from initial installation to advanced multi-app orchestration.

#### Table of Contents

- [01. Install ArgoCD via Helm](#01-install-argocd-via-helm)
- [02. Expose ArgoCD via Ingress](#02-expose-argocd-via-ingress)
- [03. Login with the ArgoCD CLI](#03-login-with-the-argocd-cli)
- [04. Deploy Your First Application via CLI](#04-deploy-your-first-application-via-cli)
- [05. Inspect Application Status and Health](#05-inspect-application-status-and-health)
- [06. Manually Trigger a Sync](#06-manually-trigger-a-sync)
- [07. Diff Live State Against Git](#07-diff-live-state-against-git)
- [08. Enable Auto-Sync with Self-Heal and Auto-Prune](#08-enable-auto-sync-with-self-heal-and-auto-prune)
- [09. Test Self-Healing](#09-test-self-healing)
- [10. View Deployment History](#10-view-deployment-history)
- [11. Rollback an Application](#11-rollback-an-application)
- [12. Deploy a Helm Chart via ArgoCD](#12-deploy-a-helm-chart-via-argocd)
- [13. Deploy from Kustomize via ArgoCD](#13-deploy-from-kustomize-via-argocd)
- [14. Connect a Private Repository](#14-connect-a-private-repository)
- [15. The App of Apps Pattern](#15-the-app-of-apps-pattern)
- [16. Use Sync Waves for Ordered Deployment](#16-use-sync-waves-for-ordered-deployment)
- [17. Manage Projects](#17-manage-projects)
- [18. Use Resource Hooks (PreSync / PostSync)](#18-use-resource-hooks-presync-postsync)
- [19. Troubleshoot a Failed Sync](#19-troubleshoot-a-failed-sync)
- [20. Cleanup and Uninstall ArgoCD](#20-cleanup-and-uninstall-argocd)
- [21. Chain CLI Commands for Release Workflows](#21-chain-cli-commands-for-release-workflows)

---

#### 01. Install ArgoCD via Helm

Install ArgoCD on a Kubernetes cluster using the official Argo Helm chart.

#### Scenario:

  ◦ Your team has adopted GitOps and needs a central delivery platform for all Kubernetes workloads.
  ◦ You've chosen ArgoCD and need to install it on the cluster from scratch using Helm.

**Hint:** `helm repo add`, `helm upgrade --install`, `kubectl get pods -n argocd`

??? example "Solution"

    ```bash
    # 1. Add the Argo Helm repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update argo

    # 2. Install ArgoCD in the argocd namespace (insecure mode: TLS terminated at Ingress)
    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --set server.insecure=true \
        --wait

    # 3. Verify all pods are Running
    kubectl get pods -n argocd

    # Expected output (all pods Running):
    # NAME                                                READY   STATUS
    # argocd-application-controller-0                    1/1     Running
    # argocd-dex-server-xxxx                             1/1     Running
    # argocd-redis-xxxx                                  1/1     Running
    # argocd-repo-server-xxxx                            1/1     Running
    # argocd-server-xxxx                                 1/1     Running

    # 4. Retrieve the initial admin password
    kubectl -n argocd get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d; echo

    # Save this password - you'll need it for the CLI and Web UI

    # 5. Verify the ArgoCD CRDs were installed
    kubectl get crd | grep argoproj
    # Expected: applications.argoproj.io, appprojects.argoproj.io, ...
    ```

---

#### 02. Expose ArgoCD via Ingress

Expose the ArgoCD API server using an Nginx Ingress so it is accessible via a hostname instead of port-forwarding.

#### Scenario:

  ◦ Port-forwarding is fine for development but your team needs a stable URL to access the ArgoCD UI and CLI.
  ◦ You will create an Ingress pointing `argocd.local` at the ArgoCD server.

**Prerequisites:** Nginx Ingress Controller installed on the cluster.

**Hint:** `argocd-ingress.yaml`, `/etc/hosts`, `kubectl apply`

??? example "Solution"

    ```bash
    # 1. Create the Ingress manifest
    cat > argocd-ingress.yaml << 'EOF'
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server-ingress
      namespace: argocd
      annotations:
        nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    spec:
      ingressClassName: nginx
      rules:
        - host: argocd.local
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      number: 80
    EOF

    # 2. Apply the Ingress
    kubectl apply -f argocd-ingress.yaml

    # 3. Verify the Ingress was created
    kubectl get ingress -n argocd

    # 4. Get the Ingress IP (use node IP for Kind/Minikube)
    INGRESS_IP=$(kubectl get nodes \
        -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

    echo "Ingress IP: ${INGRESS_IP}"

    # 5. Add the hostname to /etc/hosts
    echo "${INGRESS_IP}  argocd.local" | sudo tee -a /etc/hosts

    # 6. Verify connectivity
    curl -s -o /dev/null -w "%{http_code}" http://argocd.local
    # Expected: 200

    # Open in browser
    open http://argocd.local

    # Fallback: port-forward if Ingress is not available
    kubectl port-forward svc/argocd-server -n argocd 8080:80 &
    open http://localhost:8080
    ```

---

#### 03. Login with the ArgoCD CLI

Install the ArgoCD CLI and authenticate to the server.

#### Scenario:

  ◦ You will use the ArgoCD CLI to manage applications, repositories, and sync policies from the terminal.
  ◦ Before any CLI operations, you must authenticate to the ArgoCD server.

**Hint:** `brew install argocd`, `argocd login`, `argocd account update-password`

??? example "Solution"

    ```bash
    # ── Step 1: Install the ArgoCD CLI ──

    # macOS
    brew install argocd

    # Linux
    curl -sSL -o argocd-linux-amd64 \
        https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

    # Verify installation
    argocd version --client

    # ── Step 2: Retrieve the admin password ──

    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d)
    echo "Admin password: ${ARGOCD_PASSWORD}"

    # ── Step 3: Login via Ingress ──

    argocd login argocd.local \
        --username admin \
        --password "${ARGOCD_PASSWORD}" \
        --insecure

    # Login via port-forward (fallback)
    argocd login localhost:8080 \
        --username admin \
        --password "${ARGOCD_PASSWORD}" \
        --insecure

    # ── Step 4: Verify login ──

    argocd account get-user-info
    # Output shows the currently logged-in user

    argocd cluster list
    # Should show: https://kubernetes.default.svc  in-cluster  ...

    # ── Step 5: Change the admin password (recommended) ──

    argocd account update-password \
        --current-password "${ARGOCD_PASSWORD}" \
        --new-password "MySecurePassword123!"
    ```

---

#### 04. Deploy Your First Application via CLI

Create and deploy the classic ArgoCD guestbook example application using the CLI.

#### Scenario:

  ◦ You want to deploy a demo application to validate that ArgoCD can fetch from Git and deploy to the cluster.
  ◦ You will use the public `argocd-example-apps` repository and the `guestbook` path.

**Hint:** `argocd app create`, `argocd app sync`, `kubectl port-forward`

??? example "Solution"

    ```bash
    # 1. Create the application
    argocd app create guestbook \
      --repo https://github.com/argoproj/argocd-example-apps.git \
      --path guestbook \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace guestbook \
      --sync-option CreateNamespace=true

    # 2. Verify the application was created
    argocd app list

    # Output shows:
    # NAME       CLUSTER     NAMESPACE  STATUS     HEALTH   SYNCPOLICY  ...
    # guestbook  in-cluster  guestbook  OutOfSync  Missing  <none>

    # 3. Manually trigger the first sync (deploy to cluster)
    argocd app sync guestbook

    # 4. Wait for the application to become Healthy + Synced
    argocd app wait guestbook --health --sync --timeout 120

    # 5. Verify Kubernetes resources were created
    kubectl get all -n guestbook

    # Expected:
    # pod/guestbook-ui-xxxx    Running
    # service/guestbook-ui
    # deployment/guestbook-ui

    # 6. Access the application
    kubectl port-forward svc/guestbook-ui -n guestbook 8081:80 &
    open http://localhost:8081

    # Cleanup the port-forward
    kill %1
    ```

---

#### 05. Inspect Application Status and Health

Use the CLI to inspect the full status, health, and resource tree of a deployed application.

#### Scenario:

  ◦ A team member deployed an application and you need to understand its current state without touching the cluster directly.
  ◦ You want to see what Kubernetes resources ArgoCD is managing.

**Hint:** `argocd app get`, `--refresh`, `--output tree`

??? example "Solution"

    ```bash
    # 1. Get a summary of the application
    argocd app get guestbook

    # Output includes:
    # Name:               guestbook
    # Project:            default
    # Server:             https://kubernetes.default.svc
    # Namespace:          guestbook
    # URL:                http://argocd.local/applications/guestbook
    # Repo:               https://github.com/argoproj/argocd-example-apps.git
    # Target:             HEAD
    # Path:               guestbook
    # SyncWindow:         Sync Allowed
    # Sync Policy:        <none>
    # Sync Status:        Synced to HEAD
    # Health Status:      Healthy
    #
    # GROUP  KIND        NAMESPACE  NAME          STATUS  HEALTH   HOOK  MESSAGE
    #        Service     guestbook  guestbook-ui  Synced  Healthy
    # apps   Deployment  guestbook  guestbook-ui  Synced  Healthy        ...

    # 2. Force-refresh from Git before displaying
    argocd app get guestbook --refresh

    # 3. Display as a resource tree
    argocd app get guestbook --output tree

    # 4. Output as JSON for scripting
    argocd app get guestbook -o json

    # 5. Get JSON and parse with jq
    argocd app get guestbook -o json | \
      jq '{name: .metadata.name, sync: .status.sync.status, health: .status.health.status}'

    # 6. Watch live updates
    watch argocd app get guestbook

    # 7. Get all applications and their health at once
    argocd app list -o wide
    ```

---

#### 06. Manually Trigger a Sync

Practice manually triggering a sync and understand all the sync options available.

#### Scenario:

  ◦ You pushed a change to Git and want to immediately deploy it without waiting for the 3-minute poll interval.
  ◦ You also want to understand force sync, dry-run, and selective resource sync options.

**Hint:** `argocd app sync`, `--dry-run`, `--force`, `--resource`

??? example "Solution"

    ```bash
    # 1. Basic sync - apply the Git state to the cluster
    argocd app sync guestbook

    # 2. Sync and wait for completion with a timeout
    argocd app sync guestbook --timeout 120

    # 3. Dry-run - preview what would change without applying
    argocd app sync guestbook --dry-run

    # 4. Force sync - replace resources even if spec is unchanged
    argocd app sync guestbook --force

    # 5. Sync with pruning - delete resources removed from Git
    argocd app sync guestbook --prune

    # 6. Sync a specific resource only (avoids re-applying unchanged resources)
    argocd app sync guestbook \
      --resource apps:Deployment:guestbook-ui

    # 7. Sync only resources matching a label
    argocd app sync guestbook \
      --label app=guestbook-ui

    # 8. Sync with apply-out-of-sync-only (skip already-synced resources)
    argocd app sync guestbook --apply-out-of-sync-only

    # 9. Sync multiple applications at once
    argocd app sync guestbook app-of-apps efk-stack

    # 10. Check the sync status after sync
    argocd app get guestbook | grep -E "Sync|Health"
    ```

---

#### 07. Diff Live State Against Git

Use `argocd app diff` to see exactly what has drifted between the live cluster state and Git.

#### Scenario:

  ◦ A developer manually patched a running Deployment with `kubectl edit` and your monitoring shows the application is `OutOfSync`.
  ◦ Before syncing to fix the drift, you want to see exactly what changed.

**Hint:** `argocd app diff`, `kubectl scale`, drift detection

??? example "Solution"

    ```bash
    # 1. Deliberately introduce drift - manually scale the deployment
    kubectl scale deployment guestbook-ui --replicas=5 -n guestbook

    # 2. Wait for ArgoCD to detect the drift
    sleep 10
    argocd app get guestbook | grep -E "Sync|Health"
    # Sync Status: OutOfSync

    # 3. Show the diff - what changed in live vs Git
    argocd app diff guestbook

    # Output highlights the replica count change:
    # ===== apps/Deployment guestbook/guestbook-ui ======
    # 10       - replicas: 5    (live)
    # 10       + replicas: 1    (desired from Git)

    # 4. Diff against a specific Git revision
    argocd app diff guestbook --revision HEAD~1

    # 5. Diff only a specific resource
    argocd app diff guestbook \
      --resource apps:Deployment:guestbook-ui

    # 6. Use in CI - exit non-zero if drift is detected
    if ! argocd app diff guestbook --exit-code; then
      echo "DRIFT DETECTED - syncing..."
      argocd app sync guestbook
    fi

    # 7. Restore the desired state from Git
    argocd app sync guestbook
    kubectl get deployment guestbook-ui -n guestbook
    # READY should be back to 1/1
    ```

---

#### 08. Enable Auto-Sync with Self-Heal and Auto-Prune

Configure automated sync so ArgoCD continuously reconciles the cluster state with Git.

#### Scenario:

  ◦ Your team pushes application changes directly to Git and expects them to be deployed automatically.
  ◦ You also want ArgoCD to clean up resources removed from Git and heal any manual drift.

**Hint:** `argocd app set --sync-policy automated`, `--self-heal`, `--auto-prune`

??? example "Solution"

    ```bash
    # 1. Enable automated sync (ArgoCD polls Git every ~3 minutes)
    argocd app set guestbook --sync-policy automated

    # 2. Verify the sync policy was applied
    argocd app get guestbook | grep "Sync Policy"
    # Sync Policy: Automated

    # 3. Add self-heal: restores Git state if cluster is manually modified
    argocd app set guestbook --self-heal

    # 4. Add auto-prune: deletes resources removed from Git
    argocd app set guestbook --auto-prune

    # 5. Verify all options are active
    argocd app get guestbook | grep -E "Sync Policy|Prune|Self Heal"

    # 6. Test auto-sync: manually break the state
    kubectl scale deployment guestbook-ui --replicas=5 -n guestbook
    echo "Waiting for ArgoCD self-heal..."
    sleep 30
    kubectl get deployment guestbook-ui -n guestbook
    # READY should be restored to 1/1 by ArgoCD

    # 7. Configure using app manifest equivalents (declarative approach)
    # The equivalent spec in an Application YAML:
    # spec:
    #   syncPolicy:
    #     automated:
    #       prune: true
    #       selfHeal: true
    #     syncOptions:
    #       - CreateNamespace=true

    # 8. Disable auto-sync (switch back to manual)
    argocd app set guestbook --sync-policy none
    argocd app get guestbook | grep "Sync Policy"
    # Sync Policy: <none>
    ```

---

#### 09. Test Self-Healing

Validate that ArgoCD self-healing works by deliberately introducing drift and observing automatic recovery.

#### Scenario:

  ◦ A runbook says to test ArgoCD self-healing quarterly.
  ◦ You need to break the cluster state and confirm ArgoCD repairs it within the reconciliation window.

**Hint:** `kubectl scale`, `kubectl delete`, `watch argocd app get`

??? example "Solution"

    ```bash
    # 0. Ensure auto-sync + self-heal are enabled
    argocd app set guestbook --sync-policy automated --self-heal --auto-prune

    # ── Test 1: Scale drift ──

    # Break it
    kubectl scale deployment guestbook-ui --replicas=10 -n guestbook
    echo "Breaking: scaled to 10 replicas"

    # Watch ArgoCD detect and fix it (up to ~30s)
    watch -n 5 "kubectl get deployment guestbook-ui -n guestbook && argocd app get guestbook | grep -E 'Status|Health'"

    # After ~30 seconds, replicas will return to the value in Git
    kubectl get deployment guestbook-ui -n guestbook
    # DESIRED should match Git (e.g., 1)

    # ── Test 2: Delete a managed resource ──

    # Delete the service
    kubectl delete service guestbook-ui -n guestbook
    echo "Deleted the guestbook-ui service"

    # ArgoCD detects the missing resource and recreates it
    sleep 30
    kubectl get service guestbook-ui -n guestbook
    # Service should be recreated

    # ── Test 3: Manual label change ──

    # Add a label not in Git
    kubectl label deployment guestbook-ui -n guestbook manual-change=true

    # ArgoCD will detect and revert this within the next sync cycle
    sleep 60
    kubectl get deployment guestbook-ui -n guestbook --show-labels | grep manual-change
    # Label should be gone

    # ── Summary ──

    argocd app get guestbook
    # Health Status: Healthy
    # Sync Status: Synced
    ```

---

#### 10. View Deployment History

Use `argocd app history` to inspect the deployment history of an application.

#### Scenario:

  ◦ You need to audit which Git commits were deployed over the past month.
  ◦ You want to identify the revision ID to use for a rollback.

**Hint:** `argocd app history`, `-o json`, `jq`

??? example "Solution"

    ```bash
    # 1. Create some history by triggering multiple syncs
    argocd app sync guestbook
    argocd app sync guestbook
    argocd app sync guestbook

    # 2. View the deployment history
    argocd app history guestbook

    # Output shows each deployment:
    # ID  DATE                           REVISION
    # 0   2026-02-22 10:00:00 +0000 UTC  HEAD (abc1234)
    # 1   2026-02-22 10:05:00 +0000 UTC  HEAD (abc1234)
    # 2   2026-02-22 10:10:00 +0000 UTC  HEAD (abc1234)

    # 3. Output as JSON for scripting
    argocd app history guestbook -o json

    # 4. Extract key fields with jq
    argocd app history guestbook -o json | \
      jq '.[] | {id: .id, date: .deployedAt, revision: .revision}'

    # 5. Find the most recent deployment
    argocd app history guestbook -o json | jq '.[-1]'

    # 6. Find deployments by Git commit SHA
    argocd app history guestbook -o json | \
      jq '.[] | select(.revision | contains("abc1234"))'

    # 7. Save history to file for an audit log
    argocd app history guestbook -o json > guestbook-deploy-history.json
    cat guestbook-deploy-history.json
    ```

---

#### 11. Rollback an Application

Rollback an application to a previously deployed revision using the ArgoCD CLI.

#### Scenario:

  ◦ A recent deployment introduced a regression.
  ◦ You need to immediately revert to the last known-good revision to restore service.

**Hint:** `argocd app history`, `argocd app rollback`, `argocd app set --sync-policy`

??? example "Solution"

    ```bash
    # 1. Inspect the deployment history to choose a target revision
    argocd app history guestbook

    # Note the ID of the revision you want to roll back to.
    # In this example, we'll rollback to revision ID 0.

    # 2. Perform the rollback
    argocd app rollback guestbook 0

    # ArgoCD rolls back the cluster state to the snapshot from revision 0.
    # NOTE: Rollback disables automated sync on the app to prevent
    #       ArgoCD from immediately re-syncing forward again.

    # 3. Wait for the rollback to complete
    argocd app wait guestbook --health --timeout 120

    # 4. Verify the status
    argocd app get guestbook

    # 5. Verify the Kubernetes resources reflect the rolled-back state
    kubectl get all -n guestbook

    # 6. Check history - rollback is recorded as a new entry
    argocd app history guestbook

    # 7. Re-enable auto-sync after the incident is resolved
    argocd app set guestbook \
      --sync-policy automated \
      --self-heal \
      --auto-prune

    # 8. Confirm the app is back to Synced + Healthy
    argocd app get guestbook | grep -E "Sync|Health"
    ```

---

#### 12. Deploy a Helm Chart via ArgoCD

Use ArgoCD to deploy a Helm chart from a chart repository, with custom values managed in Git.

#### Scenario:

  ◦ You want ArgoCD to own the lifecycle of a Helm release, including upgrades and drift detection.
  ◦ Custom `values.yaml` overrides are stored in Git so changes go through GitOps.

**Hint:** `argocd app create --helm-chart`, `--helm-set`, `--revision`

??? example "Solution"

    ```bash
    # ── Option A: Deploy a Helm chart from an OCI / chart registry ──

    argocd app create nginx-helm \
      --repo https://charts.bitnami.com/bitnami \
      --helm-chart nginx \
      --revision 15.1.0 \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace nginx-helm \
      --sync-option CreateNamespace=true \
      --helm-set service.type=ClusterIP \
      --helm-set replicaCount=2

    # Sync and wait
    argocd app sync nginx-helm
    argocd app wait nginx-helm --health --timeout 120

    # ── Option B: Deploy a Helm chart stored in a Git repository ──

    # Store values overrides in Git, e.g.:
    #   my-repo/nginx/values.yaml
    #   apiVersion: argoproj.io/v1alpha1  ← not needed, ArgoCD auto-detects Helm

    argocd app create nginx-git-helm \
      --repo https://github.com/my-org/my-charts.git \
      --path nginx \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace nginx-git-helm \
      --sync-option CreateNamespace=true

    # ── Update Helm values through CLI (without changing Git) ──

    argocd app set nginx-helm \
      --helm-set replicaCount=3 \
      --helm-set image.tag=1.25.0

    argocd app sync nginx-helm

    # ── Verify ──

    argocd app get nginx-helm | grep -E "Sync|Health|Revision"
    kubectl get deployment -n nginx-helm

    # ── Cleanup ──

    argocd app delete nginx-helm --yes
    kubectl delete namespace nginx-helm
    ```

---

#### 13. Deploy from Kustomize via ArgoCD

Use ArgoCD to deploy a Kustomize-based application, showing how ArgoCD auto-detects the tool.

#### Scenario:

  ◦ Your team uses Kustomize overlays to manage configuration across environments (base + overlays).
  ◦ You want ArgoCD to render and deploy the Kustomize manifests for a specific overlay.

**Hint:** ArgoCD auto-detects Kustomize from `kustomization.yaml`. Point `--path` to the overlay directory.

??? example "Solution"

    ```bash
    # 1. Create a minimal Kustomize app structure in your Git repo
    #    Structure:
    #    kustomize-demo/
    #    ├── base/
    #    │   ├── deployment.yaml
    #    │   ├── service.yaml
    #    │   └── kustomization.yaml
    #    └── overlays/
    #        └── dev/
    #            ├── replica-patch.yaml
    #            └── kustomization.yaml

    # 2. Create the application in ArgoCD pointing at a Kustomize overlay
    argocd app create kustomize-demo \
      --repo https://github.com/argoproj/argocd-example-apps.git \
      --path kustomize-guestbook \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace kustomize-demo \
      --sync-option CreateNamespace=true

    # ArgoCD detects kustomization.yaml and uses `kustomize build` to render manifests

    # 3. Sync the application
    argocd app sync kustomize-demo
    argocd app wait kustomize-demo --health --timeout 120

    # 4. View rendered manifests (what kustomize build produced)
    argocd app manifests kustomize-demo

    # 5. Verify resources
    kubectl get all -n kustomize-demo

    # 6. Apply a Kustomize image override via CLI
    argocd app set kustomize-demo \
      --kustomize-image gcr.io/argoproj/argocd-example-apps/guestbook-ui:v0.2

    argocd app sync kustomize-demo

    # 7. Cleanup
    argocd app delete kustomize-demo --yes
    kubectl delete namespace kustomize-demo
    ```

---

#### 14. Connect a Private Repository

Add a private Git repository to ArgoCD using an HTTPS token or SSH key.

#### Scenario:

  ◦ Your application manifests live in a private GitHub repository.
  ◦ ArgoCD needs credentials to clone the repository in order to deploy from it.

**Hint:** `argocd repo add`, `--username`, `--password`, `--ssh-private-key-path`

??? example "Solution"

    ```bash
    # ── Option A: Connect via HTTPS Personal Access Token (PAT) ──

    # Create a GitHub PAT with 'repo' scope at https://github.com/settings/tokens

    argocd repo add https://github.com/my-org/private-repo.git \
        --username git \
        --password <YOUR_PAT_HERE>

    # ── Option B: Connect via SSH Key ──

    # Generate a deploy key (no passphrase)
    ssh-keygen -t ed25519 -C "argocd-deploy-key" -f ~/.ssh/argocd-deploy-key -N ""

    # Add the public key to GitHub repo:
    # GitHub Repo → Settings → Deploy Keys → Add Deploy Key
    # Paste the contents of ~/.ssh/argocd-deploy-key.pub

    # Add the private key to ArgoCD
    argocd repo add git@github.com:my-org/private-repo.git \
        --ssh-private-key-path ~/.ssh/argocd-deploy-key

    # ── Option C: Add a private Helm chart repository ──

    argocd repo add https://my-private-charts.example.com \
        --type helm \
        --name private-charts \
        --username admin \
        --password <PASSWORD>

    # ── Verify the connection ──

    argocd repo list

    # Expected output shows STATUS: Successful
    # SERVER                                        TYPE  STATUS      MESSAGE
    # https://github.com/my-org/private-repo.git   git   Successful

    # ── Use the private repo in an application ──

    argocd app create my-private-app \
      --repo https://github.com/my-org/private-repo.git \
      --path manifests \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace my-app

    # ── Remove a repository ──

    argocd repo rm https://github.com/my-org/private-repo.git
    ```

---

#### 15. The App of Apps Pattern

Use a single root Application to manage a directory of child Application manifests declaratively.

#### Scenario:

  ◦ You have many microservices and want a single GitOps entry point.
  ◦ Adding or removing an app is as simple as committing or deleting a YAML file in Git.
  ◦ The App of Apps pattern makes fleet management fully declarative.

**Hint:** `argocd app create` pointing at a directory of Application YAMLs, `argocd app list`

??? example "Solution"

    ```bash
    # ── Step 1: Create child Application manifests and commit them to Git ──

    # apps/guestbook.yaml
    cat > /tmp/guestbook.yaml << 'EOF'
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: guestbook
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: guestbook
      destination:
        server: https://kubernetes.default.svc
        namespace: guestbook
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
    EOF

    # apps/nginx.yaml
    cat > /tmp/nginx.yaml << 'EOF'
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: nginx-demo
      namespace: argocd
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: nginx-ingress
      destination:
        server: https://kubernetes.default.svc
        namespace: nginx-demo
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
    EOF

    # Commit both files to the apps/ directory of your Git repository

    # ── Step 2: Create the root App of Apps ──

    argocd app create app-of-apps \
      --repo https://github.com/my-org/my-gitops-repo.git \
      --path apps \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace argocd \
      --sync-policy automated \
      --auto-prune \
      --self-heal

    # ── Step 3: Sync the root app ──

    argocd app sync app-of-apps

    # ArgoCD discovers all YAML files in apps/ and creates child Applications

    # ── Step 4: Verify all child apps were created ──

    argocd app list
    # Expected:
    # NAME          CLUSTER     NAMESPACE  STATUS  HEALTH   SYNCPOLICY
    # app-of-apps   in-cluster  argocd     Synced  Healthy  Auto-Prune
    # guestbook     in-cluster  guestbook  Synced  Healthy  Auto-Prune
    # nginx-demo    in-cluster  nginx-demo Synced  Healthy  Auto-Prune

    # ── Step 5: Add a new application (GitOps way) ──

    # Commit a new YAML file to the apps/ directory in Git.
    # ArgoCD detects the change and automatically creates the child Application.
    # No kubectl or argocd commands needed!

    # ── Step 6: Remove an application (GitOps way) ──

    # Delete the YAML file from apps/ in Git and commit.
    # With auto-prune enabled, ArgoCD deletes the Application and its resources.
    ```

---

#### 16. Use Sync Waves for Ordered Deployment

Control the order in which resources are synced during a deployment using sync wave annotations.

#### Scenario:

  ◦ You have a database, a backend API, and a frontend that must start in order.
  ◦ Sync waves let you define phases so that each component waits for the previous one to become healthy.

**Hint:** `argocd.argoproj.io/sync-wave` annotation, wave numbers

??? example "Solution"

    ```bash
    # Sync waves are set as annotations on Kubernetes resources in Git.
    # Resources in lower waves deploy and become healthy before higher waves start.

    # ── Example: 3-tier app with ordered deployment ──

    # wave 0: Namespace and ConfigMaps (no dependencies)
    cat > /tmp/namespace.yaml << 'EOF'
    apiVersion: v1
    kind: Namespace
    metadata:
      name: my-app
      annotations:
        argocd.argoproj.io/sync-wave: "0"
    EOF

    # wave 1: Database (must be healthy before the API starts)
    cat > /tmp/database-deployment.yaml << 'EOF'
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: postgres
      namespace: my-app
      annotations:
        argocd.argoproj.io/sync-wave: "1"
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: postgres
      template:
        metadata:
          labels:
            app: postgres
        spec:
          containers:
            - name: postgres
              image: postgres:15
              env:
                - name: POSTGRES_PASSWORD
                  value: "mysecretpassword"
    EOF

    # wave 2: Backend API (waits for database to be healthy)
    cat > /tmp/api-deployment.yaml << 'EOF'
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: backend-api
      namespace: my-app
      annotations:
        argocd.argoproj.io/sync-wave: "2"
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: backend-api
      template:
        metadata:
          labels:
            app: backend-api
        spec:
          containers:
            - name: api
              image: my-api:latest
    EOF

    # wave 3: Frontend (waits for the API to be healthy)
    cat > /tmp/frontend-deployment.yaml << 'EOF'
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: frontend
      namespace: my-app
      annotations:
        argocd.argoproj.io/sync-wave: "3"
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: frontend
      template:
        metadata:
          labels:
            app: frontend
        spec:
          containers:
            - name: frontend
              image: my-frontend:latest
    EOF

    # Commit all files to a Git path, then create the app:
    argocd app create my-app \
      --repo https://github.com/my-org/my-repo.git \
      --path manifests \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace my-app \
      --sync-option CreateNamespace=true

    argocd app sync my-app

    # Watch the wave-by-wave deployment progress
    watch argocd app get my-app

    # Wave execution order:
    # Wave 0: Namespace created
    # Wave 1: postgres Deployment reaches Healthy
    # Wave 2: backend-api Deployment reaches Healthy
    # Wave 3: frontend Deployment reaches Healthy
    ```

---

#### 17. Manage Projects

Create an ArgoCD Project to restrict what repositories, clusters, and namespaces an application can use.

#### Scenario:

  ◦ Your cluster hosts applications for multiple teams (frontend, backend, ops).
  ◦ You want to prevent the frontend team from accidentally deploying to the `kube-system` namespace.
  ◦ ArgoCD Projects provide RBAC-level isolation between teams.

**Hint:** `argocd proj create`, `--src-repos`, `--dest`, `argocd proj list`

??? example "Solution"

    ```bash
    # 1. Create a project for the frontend team
    argocd proj create frontend \
      --description "Frontend team applications" \
      --src-repos "https://github.com/my-org/frontend-repo.git" \
      --dest "https://kubernetes.default.svc,frontend-*" \
      --dest "https://kubernetes.default.svc,staging"

    # --src-repos: only this repo is allowed as a source
    # --dest:      only these patterns are allowed as destinations (cluster,namespace)

    # 2. Verify the project was created
    argocd proj list

    # 3. View project details
    argocd proj get frontend

    # 4. Add additional allowed source repositories
    argocd proj add-source frontend \
      "https://github.com/my-org/shared-charts.git"

    # 5. Add allowed destinations
    argocd proj add-destination frontend \
      https://kubernetes.default.svc production-frontend

    # 6. Set cluster-scope resource DENY list (prevent modification of cluster-level resources)
    argocd proj deny-cluster-resource frontend "*" "*"
    argocd proj allow-cluster-resource frontend "" "Namespace"

    # 7. Assign an application to the project
    argocd app create frontend-app \
      --project frontend \
      --repo https://github.com/my-org/frontend-repo.git \
      --path manifests \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace frontend-prod

    # 8. Attempting to use a disallowed repo will fail with a permission error
    argocd app create bad-app \
      --project frontend \
      --repo https://github.com/other-org/other-repo.git \
      --path manifests \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace kube-system
    # Error: application destination {... kube-system} is not permitted in project 'frontend'

    # 9. Cleanup
    argocd app delete frontend-app --yes 2>/dev/null || true
    argocd proj delete frontend
    ```

---

#### 18. Use Resource Hooks (PreSync / PostSync)

Use ArgoCD resource hooks to run Jobs before or after a sync operation - e.g., database migrations or smoke tests.

#### Scenario:

  ◦ Your application requires a database migration to run before the new version starts.
  ◦ After deployment you want a smoke test to verify the application is responding correctly.

**Hint:** `argocd.argoproj.io/hook` annotation, `PreSync`, `PostSync`, `argocd.argoproj.io/hook-delete-policy`

??? example "Solution"

    ```bash
    # Hooks are standard Kubernetes Jobs with special ArgoCD annotations.
    # They are stored in your Git repository alongside the application manifests.

    # ── PreSync Hook: Run database migration before sync ──

    cat > /tmp/pre-sync-migration.yaml << 'EOF'
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: db-migration
      namespace: my-app
      annotations:
        argocd.argoproj.io/hook: PreSync
        argocd.argoproj.io/hook-delete-policy: HookSucceeded
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: migrate
              image: my-app:latest
              command: ["./migrate.sh"]
              env:
                - name: DB_HOST
                  value: postgres.my-app.svc
    EOF

    # ── PostSync Hook: Run smoke test after sync ──

    cat > /tmp/post-sync-smoke-test.yaml << 'EOF'
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: smoke-test
      namespace: my-app
      annotations:
        argocd.argoproj.io/hook: PostSync
        argocd.argoproj.io/hook-delete-policy: HookSucceeded
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: smoke-test
              image: curlimages/curl:latest
              command:
                - sh
                - -c
                - |
                  echo "Running smoke test..."
                  until curl -sf http://my-app.my-app.svc/health; do
                    echo "Service not ready, retrying in 5s..."
                    sleep 5
                  done
                  echo "Smoke test passed!"
    EOF

    # ── Sync Wave + Hook combination ──
    # Use sync waves to order hooks relative to other resources:
    #   annotations:
    #     argocd.argoproj.io/hook: PreSync
    #     argocd.argoproj.io/sync-wave: "-5"   # Run early within PreSync phase

    # ── Hook Delete Policies ──
    # HookSucceeded:       Delete job when it succeeds (default)
    # HookFailed:          Delete job when it fails
    # BeforeHookCreation:  Delete previous run before creating a new one

    # ── Commit the hook files to Git and sync ──

    argocd app sync my-app

    # Watch hooks execute
    kubectl get jobs -n my-app -w

    # Check hook logs
    kubectl logs job/db-migration -n my-app
    kubectl logs job/smoke-test -n my-app
    ```

---

#### 19. Troubleshoot a Failed Sync

Diagnose and fix a sync failure using CLI commands and `kubectl`.

#### Scenario:

  ◦ An application is stuck in `OutOfSync` or `Degraded` state.
  ◦ You need to identify the root cause and resolve it.

**Hint:** `argocd app get`, `argocd app diff`, `kubectl describe`, `kubectl logs`

??? example "Solution"

    ```bash
    # ── Step 1: Get the high-level status ──

    argocd app get <app-name>
    # Look for degraded resources or error messages in the resource list

    # ── Step 2: Show the diff to understand what ArgoCD is trying to apply ──

    argocd app diff <app-name>

    # ── Step 3: Get the rendered manifests ──

    argocd app manifests <app-name>
    # Validate the manifest looks correct

    # ── Step 4: Check ArgoCD conditions and events ──

    kubectl describe application <app-name> -n argocd
    # Look at Conditions and Events sections

    # ── Step 5: Check the ArgoCD application controller logs ──

    kubectl logs -n argocd \
      -l app.kubernetes.io/name=argocd-application-controller \
      --tail=100 | grep -i "error\|failed\|<app-name>"

    # ── Step 6: Check the repo-server logs (manifest rendering issues) ──

    kubectl logs -n argocd \
      -l app.kubernetes.io/name=argocd-repo-server \
      --tail=50 | grep -i "error\|failed"

    # ── Step 7: Force-refresh and retry sync ──

    argocd app get <app-name> --refresh
    argocd app sync <app-name> --force

    # ── Step 8: Common issues and fixes ──

    # Issue: Repository error (auth failure)
    argocd repo list               # Check STATUS column
    argocd repo get <repo-url>     # Check detailed status

    # Issue: Out of sync but diff shows no changes (stuck sync)
    argocd app sync <app-name> --force --replace

    # Issue: Hook is stuck running
    kubectl get jobs -n <namespace>
    kubectl delete job <stuck-job-name> -n <namespace>
    argocd app sync <app-name>

    # Issue: Resource exists with different owner (e.g., fields managed by another controller)
    argocd app sync <app-name> --server-side-apply

    # Issue: Namespace doesn't exist
    argocd app set <app-name> --sync-option CreateNamespace=true
    argocd app sync <app-name>

    # ── Step 9: App of Apps - child apps not created ──

    argocd app get app-of-apps            # Check root is Synced
    argocd repo list                      # Confirm repo is accessible
    argocd app manifests app-of-apps      # Confirm apps/ dir renders correctly
    kubectl get applications -n argocd    # Check all Application CRs
    ```

---

#### 20. Cleanup and Uninstall ArgoCD

Safely remove all ArgoCD applications and uninstall ArgoCD from the cluster.

#### Scenario:

  ◦ You've finished a demo or training environment and need to tear everything down cleanly.
  ◦ Resources must be deleted in the correct order to avoid orphaned namespaces or finalizer deadlocks.

**Hint:** `argocd app delete --cascade`, `helm uninstall`, finalizer removal

??? example "Solution"

    ```bash
    # ── Step 1: Delete all managed applications (cascade removes K8s resources too) ──

    # List all applications first
    argocd app list

    # Delete individual apps with cascade
    argocd app delete guestbook --yes
    argocd app delete app-of-apps --yes

    # Or delete ALL applications in one command
    argocd app list -o name | xargs -I {} argocd app delete {} --yes

    # ── Step 2: Verify managed namespaces were cleaned up ──

    kubectl get namespace | grep -E "guestbook|efk|nginx"

    # ── Step 3: Remove connected repositories ──

    argocd repo list | awk 'NR>1 {print $1}' | xargs -I {} argocd repo rm {}

    # ── Step 4: Remove custom Projects (if any were created) ──

    argocd proj list | awk 'NR>1 && $1 != "default" {print $1}' | \
      xargs -I {} argocd proj delete {}

    # ── Step 5: If apps are stuck due to finalizers, remove them manually ──

    # List all Application CRs
    kubectl get applications -n argocd

    # Remove a stuck application's finalizer
    kubectl patch application <app-name> -n argocd \
      -p '{"metadata":{"finalizers":[]}}' \
      --type merge

    # ── Step 6: Uninstall ArgoCD via Helm ──

    helm uninstall argocd --namespace argocd

    # ── Step 7: Delete the ArgoCD namespace and CRDs ──

    kubectl delete namespace argocd

    # Delete ArgoCD CRDs
    kubectl get crd | grep argoproj.io | awk '{print $1}' | \
      xargs kubectl delete crd

    # ── Step 8: Verify everything is gone ──

    kubectl get all -n argocd        # Should return "No resources found"
    kubectl get crd | grep argoproj  # Should return nothing
    helm list --all-namespaces       # argocd should not appear
    ```

---

#### 21. Chain CLI Commands for Release Workflows

Practice common multi-step ArgoCD CLI workflows for day-to-day GitOps operations.

#### Scenario:

  ◦ You want repeatable, scriptable workflows for deploying, validating, and rolling back GitOps applications.
  ◦ These one-liners and scripts model real-world CI/CD integration patterns.

**Hint:** Chain `argocd` and `kubectl` commands with `&&`, `||`, and loops.

??? example "Solution"

    ```bash
    # ── Workflow 1: Install ArgoCD, login, and deploy guestbook in one sequence ──

    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd --create-namespace \
        --set server.insecure=true --wait && \
    PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d) && \
    argocd login argocd.local \
        --username admin --password "$PASS" --insecure && \
    argocd app create guestbook \
        --repo https://github.com/argoproj/argocd-example-apps.git \
        --path guestbook \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace guestbook \
        --sync-option CreateNamespace=true && \
    argocd app sync guestbook && \
    argocd app wait guestbook --health --timeout 120 && \
    echo "Guestbook deployed successfully!"

    # ── Workflow 2: Deploy and auto-heal setup ──

    argocd app create guestbook \
        --repo https://github.com/argoproj/argocd-example-apps.git \
        --path guestbook \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace guestbook \
        --sync-policy automated \
        --auto-prune \
        --self-heal \
        --sync-option CreateNamespace=true && \
    argocd app wait guestbook --health && \
    argocd app get guestbook

    # ── Workflow 3: Health-check and rollback on failure ──

    argocd app sync guestbook --timeout 120 && \
    argocd app wait guestbook --health --timeout 60 || \
    ( echo "Deployment failed - rolling back." && argocd app rollback guestbook 0 )

    # ── Workflow 4: Check all apps and alert on degraded ──

    DEGRADED=$(argocd app list -o json | jq -r \
      '.[] | select(.status.health.status != "Healthy") | .metadata.name')
    if [ -n "$DEGRADED" ]; then
      echo "ALERT: Degraded applications detected:"
      echo "$DEGRADED"
    else
      echo "All applications are Healthy."
    fi

    # ── Workflow 5: Force-refresh and sync all out-of-sync apps ──

    argocd app list -o json | \
      jq -r '.[] | select(.status.sync.status == "OutOfSync") | .metadata.name' | \
      xargs -I {} bash -c 'argocd app get {} --refresh && argocd app sync {}'

    # ── Workflow 6: Deploy App of Apps and wait for all children ──

    argocd app create app-of-apps \
        --repo https://github.com/my-org/my-gitops-repo.git \
        --path apps \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace argocd \
        --sync-policy automated && \
    argocd app sync app-of-apps && \
    sleep 10 && \
    argocd app list

    # ── Workflow 7: Export all application definitions for backup ──

    mkdir -p argocd-backup
    argocd app list -o name | while read APP; do
      argocd app get "$APP" -o json > "argocd-backup/${APP}.json"
      echo "Backed up: ${APP}"
    done
    ls -la argocd-backup/

    # ── Workflow 8: Multi-environment deployment with different values ──

    for ENV in dev staging prod; do
      argocd app create "guestbook-${ENV}" \
        --repo https://github.com/argoproj/argocd-example-apps.git \
        --path guestbook \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace "guestbook-${ENV}" \
        --sync-policy automated \
        --auto-prune \
        --self-heal \
        --sync-option CreateNamespace=true
      echo "Created: guestbook-${ENV}"
    done
    argocd app list

    # ── Workflow 9: Full teardown ──

    argocd app list -o name | xargs -I {} argocd app delete {} --yes && \
    helm uninstall argocd -n argocd && \
    kubectl delete namespace argocd && \
    echo "ArgoCD fully removed."

    # Cleanup multi-env apps
    for ENV in dev staging prod; do
      kubectl delete namespace "guestbook-${ENV}" 2>/dev/null || true
    done
    rm -rf argocd-backup/
    ```

---

### Diagram: ArgoCD GitOps Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ArgoCD GitOps Flow                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Developer ──► git push ──► Git Repository (Source of Truth)      │
│                                    │                                │
│                        ArgoCD polls every ~3 min                    │
│                                    │                                │
│           ┌────────────────────────▼──────────────────────┐        │
│           │            ArgoCD Control Plane                │        │
│           │                                               │        │
│           │  API Server ◄── argocd CLI / Web UI           │        │
│           │       │                                        │        │
│           │  App Controller ──► compare desired vs live   │        │
│           │       │                                        │        │
│           │  Repo Server ──► renders Helm/Kustomize/YAML  │        │
│           └────────────────────────┬──────────────────────┘        │
│                                    │                                │
│                              sync / heal                            │
│                                    │                                │
│           ┌────────────────────────▼──────────────────────┐        │
│           │           Kubernetes Cluster                   │        │
│           │                                               │        │
│           │  Namespace: guestbook  ──► Deployment, Svc    │        │
│           │  Namespace: efk        ──► Elasticsearch,…    │        │
│           │  Namespace: argocd     ──► App of Apps        │        │
│           └───────────────────────────────────────────────┘        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

### Quick Reference: Essential ArgoCD CLI Commands

| Command                                                        | Description                                         |
|----------------------------------------------------------------|-----------------------------------------------------|
| `argocd login <server>`                                        | Authenticate to ArgoCD server                       |
| `argocd account update-password`                               | Change the admin password                           |
| `argocd cluster list`                                          | List connected clusters                             |
| `argocd repo add <url>`                                        | Connect a Git or Helm repository                    |
| `argocd repo list`                                             | List all connected repositories                     |
| `argocd app create <name>`                                     | Create a new application                            |
| `argocd app list`                                              | List all applications and their status              |
| `argocd app get <name>`                                        | Get detailed status and resource tree               |
| `argocd app get <name> --refresh`                              | Force-refresh from Git before displaying            |
| `argocd app sync <name>`                                       | Manually trigger a sync                             |
| `argocd app sync <name> --dry-run`                             | Preview a sync without applying                     |
| `argocd app diff <name>`                                       | Show diff between Git and live state                |
| `argocd app set <name> --sync-policy automated`                | Enable automated sync                               |
| `argocd app set <name> --self-heal --auto-prune`               | Enable self-heal and auto-prune                     |
| `argocd app wait <name> --health`                              | Wait for application to become Healthy              |
| `argocd app history <name>`                                    | Show deployment history                             |
| `argocd app rollback <name> <revision-id>`                     | Rollback to a previous revision                     |
| `argocd app manifests <name>`                                  | Show rendered Kubernetes manifests                  |
| `argocd app delete <name> --yes`                               | Delete application (cascades to K8s resources)      |
| `argocd proj create <name>`                                    | Create a new project                                |
| `argocd proj list`                                             | List all projects                                   |
| `argocd context`                                               | List all saved server contexts                      |
| `argocd context <name>`                                        | Switch to a different ArgoCD server context         |

---
