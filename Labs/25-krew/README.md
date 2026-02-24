---

# Krew - kubectl Plugin Manager

<img src="../assets/images/k8s-lab.png" alt="Kubernetes Logo" />

- Welcome to the `Krew` hands-on lab! In this tutorial, you'll learn how to use `Krew`, the plugin manager for `kubectl`, to discover, install, and manage plugins that extend Kubernetes CLI capabilities.
- You'll install useful plugins, explore their functionality, and learn how to build your own `kubectl` plugin.

---

## What will we learn?

- What `Krew` is and why it is useful
- How to install and configure `Krew`
- How to discover, install, update, and remove `kubectl` plugins
- Essential `kubectl` plugins for daily Kubernetes work
- How to create your own `kubectl` plugin
- Troubleshooting and best practices

---

## Official Documentation & References

| Resource                        | Link                                                                                         |
| ------------------------------- | -------------------------------------------------------------------------------------------- |
| Krew Official Site              | [krew.sigs.k8s.io](https://krew.sigs.k8s.io/)                                               |
| Krew User Guide                 | [krew.sigs.k8s.io/docs/user-guide](https://krew.sigs.k8s.io/docs/user-guide/)               |
| Krew Plugin Index               | [krew.sigs.k8s.io/plugins](https://krew.sigs.k8s.io/plugins/)                               |
| Krew GitHub Repository          | [github.com/kubernetes-sigs/krew](https://github.com/kubernetes-sigs/krew)                   |
| Writing Custom kubectl Plugins  | [kubernetes.io/docs/tasks/extend-kubectl](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) |
| kubectl Plugin Discovery        | [kubernetes.io/docs/concepts/extend-kubectl](https://kubernetes.io/docs/concepts/extend-kubernetes/kubectl-plugins/) |

---

## Prerequisites

- A running Kubernetes cluster (minikube, kind, Docker Desktop, or cloud-managed)
- `kubectl` installed and configured to communicate with your cluster
- `git` installed (for plugin installation from source)
- Basic familiarity with the command line

---

## Introduction

### What is Krew?

- `Krew` is a **plugin manager** for `kubectl`, the Kubernetes command-line tool.
- It works similarly to `apt` for Debian, `brew` for macOS, or `npm` for Node.js — but specifically for `kubectl` plugins.
- `Krew` helps you discover, install, and manage plugins that extend `kubectl` with additional commands and capabilities.

### Why use Krew?

- **Discoverability**: Browse 200+ community-maintained plugins from a centralized index
- **Easy installation**: Install plugins with a single command (`kubectl krew install <plugin>`)
- **Version management**: Update all installed plugins at once
- **Cross-platform**: Works on Linux, macOS, and Windows
- **No sudo required**: Plugins are installed in your home directory

### How kubectl plugins work

- `kubectl` has a built-in plugin mechanism: any executable in your `PATH` named `kubectl-<plugin_name>` becomes a `kubectl` subcommand.
- For example, an executable named `kubectl-whoami` can be invoked as `kubectl whoami`.
- `Krew` manages the installation of these executables into `~/.krew/bin/`.

```mermaid
graph LR
    A[kubectl krew install foo] --> B[Download plugin binary]
    B --> C[Place in ~/.krew/bin/kubectl-foo]
    C --> D[kubectl foo is now available]
    style A fill:#326CE5,color:#fff
    style D fill:#326CE5,color:#fff
```

### Krew Architecture

```text
~/.krew/
├── bin/                  # Plugin binaries (added to PATH)
│   ├── kubectl-krew      # Krew itself
│   ├── kubectl-ctx        # Context switcher plugin
│   ├── kubectl-ns         # Namespace switcher plugin
│   └── ...
├── index/                # Plugin index (metadata)
│   └── default/
│       └── plugins/
├── receipts/             # Installation records
│   ├── ctx.yaml
│   ├── ns.yaml
│   └── ...
└── store/                # Downloaded plugin archives
```

---

## Common `Krew` Commands

Below are the most common `Krew` commands you'll use when working with `kubectl` plugins.

??? example "`kubectl krew install` - Install a plugin"

      **Syntax:** `kubectl krew install <plugin-name>`

      **Description:** Downloads and installs a plugin from the Krew index.

      - Downloads the plugin binary for your OS and architecture
      - Places the binary in `~/.krew/bin/`
      - The plugin becomes available as `kubectl <plugin-name>`

          ```bash
          # Install a single plugin
          kubectl krew install ctx

          # Install multiple plugins at once
          kubectl krew install ctx ns view-secret

          # The plugin is now available
          kubectl ctx
          ```

??? example "`kubectl krew list` - List installed plugins"

      **Syntax:** `kubectl krew list`

      **Description:** Shows all currently installed plugins managed by Krew.

      - Displays plugin name and installed version
      - Only shows Krew-managed plugins (not manually installed ones)

          ```bash
          # List all installed plugins
          kubectl krew list

          # Example output:
          # PLUGIN          VERSION
          # ctx             v0.9.5
          # krew            v0.4.4
          # ns              v0.9.5
          # view-secret     v0.12.0
          ```

??? example "`kubectl krew search` - Search for plugins"

      **Syntax:** `kubectl krew search [keyword]`

      **Description:** Searches the Krew plugin index for available plugins.

      - Without arguments, lists all available plugins
      - With a keyword, filters plugins by name and description
      - Shows plugin name, description, installed status, and stability

          ```bash
          # List all available plugins
          kubectl krew search

          # Search for plugins by keyword
          kubectl krew search secret

          # Search for resource-related plugins
          kubectl krew search resource

          # Example output:
          # NAME             DESCRIPTION                                  INSTALLED
          # view-secret      Decode Kubernetes secrets                    yes
          # modify-secret    Edit secrets in-place                        no
          ```

??? example "`kubectl krew info` - Show plugin details"

      **Syntax:** `kubectl krew info <plugin-name>`

      **Description:** Displays detailed information about a specific plugin.

      - Shows plugin name, version, homepage, and description
      - Includes supported platforms and caveats

          ```bash
          # Show plugin details
          kubectl krew info ctx

          # Example output:
          # NAME: ctx
          # URI: https://github.com/ahmetb/kubectx/...
          # SHA256: ...
          # VERSION: v0.9.5
          # HOMEPAGE: https://github.com/ahmetb/kubectx
          # DESCRIPTION:
          # ...
          ```

??? example "`kubectl krew update` - Update the plugin index"

      **Syntax:** `kubectl krew update`

      **Description:** Fetches the latest plugin index from the Krew plugin repository.

      - Downloads the latest plugin metadata
      - Does NOT update installed plugins
      - Should be run periodically to discover new plugins

          ```bash
          # Update the plugin index
          kubectl krew update

          # Output:
          # Updated the local copy of plugin index.
          ```

??? example "`kubectl krew upgrade` - Upgrade installed plugins"

      **Syntax:** `kubectl krew upgrade [plugin-name]`

      **Description:** Upgrades installed plugins to their latest versions.

      - Without arguments, upgrades ALL installed plugins
      - With a plugin name, upgrades only that specific plugin

          ```bash
          # Upgrade all installed plugins
          kubectl krew upgrade

          # Upgrade a specific plugin
          kubectl krew upgrade ctx

          # Output:
          # Updated the local copy of plugin index.
          # Upgrading plugin: ctx
          # Upgraded plugin: ctx
          ```

??? example "`kubectl krew uninstall` - Remove a plugin"

      **Syntax:** `kubectl krew uninstall <plugin-name>`

      **Description:** Removes an installed plugin.

      - Deletes the plugin binary and installation receipt
      - The `kubectl <plugin-name>` command will no longer be available

          ```bash
          # Uninstall a plugin
          kubectl krew uninstall ctx

          # Verify it's removed
          kubectl krew list
          ```

---

## Essential kubectl Plugins

Below is a curated list of the most useful `kubectl` plugins organized by category. These plugins can dramatically improve your daily Kubernetes workflow.

### Cluster Navigation

| Plugin    | Description                                              | Usage                     |
| --------- | -------------------------------------------------------- | ------------------------- |
| `ctx`     | Switch between Kubernetes contexts quickly               | `kubectl ctx <context>`   |
| `ns`      | Switch between namespaces quickly                        | `kubectl ns <namespace>`  |
| `get-all` | List ALL resources in a namespace (not just common ones) | `kubectl get-all`         |

### Debugging & Inspection

| Plugin          | Description                                           | Usage                                  |
| --------------- | ----------------------------------------------------- | -------------------------------------- |
| `debug-shell`   | Create a debug container in a running pod              | `kubectl debug-shell <pod>`            |
| `pod-inspect`   | Detailed pod inspection with events and logs           | `kubectl pod-inspect <pod>`            |
| `node-shell`    | Open a shell into a Kubernetes node                    | `kubectl node-shell <node>`            |
| `blame`         | Show who last modified Kubernetes resources            | `kubectl blame <resource> <name>`      |
| `tail`          | Stream logs from multiple pods (like `stern`)          | `kubectl tail --ns <ns>`              |

### Security & Secrets

| Plugin          | Description                                           | Usage                                  |
| --------------- | ----------------------------------------------------- | -------------------------------------- |
| `view-secret`   | Decode and view Kubernetes secrets easily              | `kubectl view-secret <secret>`         |
| `modify-secret` | Edit secrets in-place with base64 encoding handled     | `kubectl modify-secret <secret>`       |
| `access-matrix` | Show RBAC access matrix for a resource                 | `kubectl access-matrix`                |
| `who-can`       | Show who has RBAC permissions for an action            | `kubectl who-can get pods`             |
| `view-cert`     | View certificate details from secrets                  | `kubectl view-cert <secret>`           |

### Resource Management

| Plugin              | Description                                          | Usage                                |
| ------------------- | ---------------------------------------------------- | ------------------------------------ |
| `resource-capacity` | Show resource requests/limits and utilization         | `kubectl resource-capacity`          |
| `view-utilization`  | Show cluster resource utilization                     | `kubectl view-utilization`           |
| `count`             | Count resources by kind                              | `kubectl count pods`                 |
| `images`            | List container images running in the cluster         | `kubectl images`                     |
| `neat`              | Remove clutter from Kubernetes YAML output           | `kubectl get pod -o yaml \| kubectl neat` |

### Networking

| Plugin         | Description                                             | Usage                              |
| -------------- | ------------------------------------------------------- | ---------------------------------- |
| `ingress-rule` | List Ingress rules across the cluster                   | `kubectl ingress-rule`             |
| `sniff`        | Capture network traffic from a pod using tcpdump/Wireshark | `kubectl sniff <pod>`           |

---

# Lab

### Step 01 - Install `Krew`

- Before using `Krew`, you need to install it on your local machine.

=== "macOS"

    ```bash
    # Using Homebrew (recommended)
    brew install krew
    ```

=== "Linux"

    ```bash
    (
      set -x; cd "$(mktemp -d)" &&
      OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
      KREW="krew-${OS}_${ARCH}" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
      tar zxvf "${KREW}.tar.gz" &&
      ./"${KREW}" install krew
    )
    ```

=== "Windows (PowerShell)"

    ```powershell
    # Download and install Krew
    Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-windows_amd64.exe" -OutFile krew.exe
    .\krew.exe install krew
    ```

#### Add Krew to PATH

After installation, you must add `Krew` to your shell `PATH`:

=== "bash"

    ```bash
    # Add to ~/.bashrc
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    ```

=== "zsh"

    ```bash
    # Add to ~/.zshrc
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
    ```

#### Verify Installation

```bash
kubectl krew version

## Expected output (version may vary):
# OPTION            VALUE
# GitTag            v0.4.4
# GitCommit         ...
# IndexURI          https://github.com/kubernetes-sigs/krew-index.git
# BasePath          /home/user/.krew
# IndexPath         /home/user/.krew/index/default
# InstallPath       /home/user/.krew/store
# BinPath           /home/user/.krew/bin
```

---

### Step 02 - Update the Plugin Index

- Before installing plugins, update the local plugin index to get the latest available plugins:

```bash
kubectl krew update
```

- You should see output similar to:

```text
Updated the local copy of plugin index.
```

---

### Step 03 - Discover Plugins

- Browse the available plugins to find tools that match your needs:

```bash
# List all available plugins (200+)
kubectl krew search

# Search for specific functionality
kubectl krew search secret
kubectl krew search debug
kubectl krew search resource

# Get detailed info about a specific plugin
kubectl krew info view-secret
```

---

### Step 04 - Install Essential Plugins

- Install a curated set of essential plugins for daily Kubernetes work:

```bash
# Context and namespace switching
kubectl krew install ctx
kubectl krew install ns

# Secret management
kubectl krew install view-secret

# Resource inspection
kubectl krew install get-all
kubectl krew install resource-capacity
kubectl krew install count
kubectl krew install images

# RBAC
kubectl krew install access-matrix
```

- Verify the installed plugins:

```bash
kubectl krew list
```

---

### Step 05 - Use Context & Namespace Switchers

- The `ctx` and `ns` plugins make switching between contexts and namespaces effortless:

#### Switch contexts with `ctx`

```bash
# List all available contexts (current context is highlighted)
kubectl ctx

# Switch to a different context
kubectl ctx my-other-cluster

# Switch back to the previous context
kubectl ctx -
```

#### Switch namespaces with `ns`

```bash
# List all namespaces (current namespace is highlighted)
kubectl ns

# Switch to a different namespace
kubectl ns kube-system

# Switch back to the previous namespace
kubectl ns -

# Verify the current namespace
kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'
```

---

### Step 06 - Inspect Secrets

- The `view-secret` plugin makes it easy to decode and view Kubernetes secrets:

```bash
# First, create a test secret
kubectl create secret generic demo-secret \
  --from-literal=username=admin \
  --from-literal=password=s3cr3t

# List all secrets in the current namespace
kubectl view-secret

# View all keys in a specific secret
kubectl view-secret demo-secret

# View a specific key (decoded automatically)
kubectl view-secret demo-secret username

# View a specific key from a specific namespace
kubectl view-secret demo-secret password -n default

# Compare with the standard kubectl approach (base64 encoded)
kubectl get secret demo-secret -o jsonpath='{.data.password}' | base64 -d
```

---

### Step 07 - Explore Cluster Resources

#### Get all resources with `get-all`

- Unlike `kubectl get all`, which only shows common resources, `get-all` lists **every** resource in a namespace:

```bash
# List ALL resources in the current namespace
kubectl get-all

# List all resources in a specific namespace
kubectl get-all -n kube-system
```

!!! tip "Why `get-all` instead of `kubectl get all`?"
    `kubectl get all` only shows a subset of resources (Pods, Services, Deployments, ReplicaSets, etc.).
    It does **not** show ConfigMaps, Secrets, Ingresses, ServiceAccounts, RBAC resources, CRDs, and many others.
    The `get-all` plugin discovers and lists every resource type in the namespace.

#### Count resources with `count`

```bash
# Count all pods across all namespaces
kubectl count pods

# Count deployments in a specific namespace
kubectl count deployments -n kube-system

# Count all resource types
kubectl count all
```

#### View resource capacity

```bash
# Show node resource requests, limits, and utilization
kubectl resource-capacity

# Show with pods breakdown
kubectl resource-capacity --pods

# Show utilization percentages
kubectl resource-capacity --util

# Show specific resource type
kubectl resource-capacity --pods --util --sort cpu.util
```

---

### Step 08 - Check RBAC Permissions

- The `access-matrix` plugin helps you understand who can do what in your cluster:

```bash
# Show access matrix for pods in the current namespace
kubectl access-matrix --for pods

# Show access matrix for all resources
kubectl access-matrix

# Show what a specific service account can do
kubectl access-matrix --sa default:default
```

---

### Step 09 - List Container Images

- The `images` plugin shows all container images running in the cluster:

```bash
# List all images across all namespaces
kubectl images --all-namespaces

# List images in a specific namespace
kubectl images -n kube-system

# Show image columns
kubectl images --columns namespace,name,image
```

---

### Step 10 - Update and Manage Plugins

```bash
# Update the plugin index (fetch new metadata)
kubectl krew update

# Upgrade all installed plugins to latest versions
kubectl krew upgrade

# Upgrade a specific plugin
kubectl krew upgrade ctx

# Uninstall a plugin you no longer need
kubectl krew uninstall sniff

# Check for outdated plugins
kubectl krew list
```

---

### Step 11 - Create Your Own kubectl Plugin

- Any executable in your `PATH` named `kubectl-<name>` becomes a `kubectl` plugin.
- Let's create a simple plugin that shows pod resource usage:

#### Create the plugin script

```bash
cat << 'EOF' > kubectl-pod-status
#!/bin/bash
# kubectl-pod-status: Show a summary of pod statuses in a namespace

NAMESPACE="${1:---all-namespaces}"

if [ "$NAMESPACE" = "--all-namespaces" ]; then
  NS_FLAG="--all-namespaces"
else
  NS_FLAG="-n $NAMESPACE"
fi

echo "=== Pod Status Summary ==="
echo ""

# Count pods by status
kubectl get pods $NS_FLAG --no-headers 2>/dev/null | \
  awk '{print $NF}' | \
  sort | \
  uniq -c | \
  sort -rn | \
  while read count status; do
    printf "  %-15s %s\n" "$status" "$count"
  done

echo ""
echo "=== Total Pods ==="
TOTAL=$(kubectl get pods $NS_FLAG --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "  Total: $TOTAL"
EOF
```

#### Install and test the plugin

```bash
# Make it executable
chmod +x kubectl-pod-status

# Move it to a directory in your PATH
sudo mv kubectl-pod-status /usr/local/bin/

# Verify kubectl recognizes it
kubectl plugin list

# Use your custom plugin
kubectl pod-status
kubectl pod-status kube-system
kubectl pod-status default
```

#### Clean up

```bash
# Remove the custom plugin
sudo rm /usr/local/bin/kubectl-pod-status
```

---

# Exercises

The following exercises will test your understanding of `Krew` and `kubectl` plugins.
Try to solve each exercise on your own before revealing the solution.

---

#### 01. Find and Install a Plugin by Use Case

You need to find a plugin that can show you the certificate expiration dates stored in Kubernetes secrets. Find it, install it, and test it.

#### Scenario:

- You manage a cluster with TLS certificates stored as secrets.
- You need a quick way to inspect certificate details without manual base64 decoding and openssl commands.

**Hint:** Use `kubectl krew search cert` to find relevant plugins.

<details>
<summary>Solution</summary>

```bash
# Search for certificate-related plugins
kubectl krew search cert

# Install the view-cert plugin
kubectl krew install view-cert

# Create a self-signed certificate for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=test.example.com"

# Create a TLS secret
kubectl create secret tls test-tls \
  --cert=tls.crt --key=tls.key

# View the certificate details
kubectl view-cert test-tls

# Clean up
kubectl delete secret test-tls
rm tls.key tls.crt
```

</details>

---

#### 02. Compare `kubectl get all` vs `kubectl get-all`

Run both commands in the `kube-system` namespace and document the differences. How many more resource types does `get-all` discover?

#### Scenario:

- You need to audit all resources in a namespace for compliance purposes.
- The standard `kubectl get all` misses many resource types.

**Hint:** Pipe both outputs through `grep "kind:"` or count the lines.

<details>
<summary>Solution</summary>

```bash
# Standard kubectl - limited resource types
kubectl get all -n kube-system 2>/dev/null | head -50

# get-all plugin - discovers ALL resource types
kubectl get-all -n kube-system 2>/dev/null | head -100

# Count resource types from standard kubectl
echo "=== kubectl get all ==="
kubectl get all -n kube-system --no-headers 2>/dev/null | wc -l

# Count resource types from get-all
echo "=== kubectl get-all ==="
kubectl get-all -n kube-system --no-headers 2>/dev/null | wc -l

# The get-all plugin typically finds 2-5x more resources including:
# - ConfigMaps, Secrets, ServiceAccounts
# - Roles, RoleBindings, ClusterRoles
# - Events, Endpoints, EndpointSlices
# - PodDisruptionBudgets, NetworkPolicies
# - Custom Resources (CRDs)
```

</details>

---

#### 03. Audit Cluster RBAC Permissions

Use `Krew` plugins to answer: "Which service accounts in the `default` namespace can create Deployments?"

#### Scenario:

- As a cluster administrator, you need to audit RBAC to ensure least-privilege access.
- Understanding who can create workloads is critical for security.

**Hint:** Install `who-can` or use `access-matrix` to check RBAC permissions.

<details>
<summary>Solution</summary>

```bash
# Install the who-can plugin
kubectl krew install who-can

# Check who can create deployments in the default namespace
kubectl who-can create deployments -n default

# Check who can delete pods
kubectl who-can delete pods -n default

# Check who can get secrets (sensitive!)
kubectl who-can get secrets -n default

# Use access-matrix for a broader view
kubectl access-matrix --for deployments -n default
```

</details>

---

#### 04. Check Cluster Resource Utilization

Install and use the `resource-capacity` plugin to identify nodes with the highest CPU and memory utilization. Then check if any node is over 80% utilized.

#### Scenario:

- You're troubleshooting slow pod scheduling and suspect resource exhaustion.
- You need a quick overview of cluster capacity vs. usage.

**Hint:** Use `kubectl resource-capacity --util --sort cpu.util`.

<details>
<summary>Solution</summary>

```bash
# Install the resource-capacity plugin (if not already installed)
kubectl krew install resource-capacity

# Show basic resource capacity
kubectl resource-capacity

# Show with utilization percentages
kubectl resource-capacity --util

# Sort by CPU utilization (highest first)
kubectl resource-capacity --util --sort cpu.util

# Show per-pod breakdown
kubectl resource-capacity --pods --util

# Show resource capacity with specific output
kubectl resource-capacity --util --pod-count

# To check if any node is over 80%, examine the output percentages
# Nodes with CPU% or Memory% above 80% may need attention
```

</details>

---

#### 05. Create a Multi-Function kubectl Plugin

Create a custom `kubectl` plugin called `kubectl-cluster-info-extended` that shows:

1. Current context and namespace
2. Node count and status
3. Pod count by namespace (top 5)
4. Resource utilization summary

#### Scenario:

- You want a single command that gives you a quick cluster health overview.
- This is useful as a morning check or after a deployment.

**Hint:** Combine multiple `kubectl` commands in a bash script named `kubectl-cluster_info_extended`.

<details>
<summary>Solution</summary>

```bash
cat << 'PLUGINEOF' > kubectl-cluster_info_extended
#!/bin/bash
# kubectl-cluster-info-extended: Quick cluster health overview

echo "============================================"
echo "  Kubernetes Cluster Overview"
echo "============================================"
echo ""

# Current context
echo "--- Context & Namespace ---"
CONTEXT=$(kubectl config current-context 2>/dev/null)
NAMESPACE=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null)
echo "  Context:   ${CONTEXT:-N/A}"
echo "  Namespace: ${NAMESPACE:-default}"
echo ""

# Node status
echo "--- Nodes ---"
kubectl get nodes --no-headers 2>/dev/null | \
  awk '{printf "  %-30s %-10s %s\n", $1, $2, $5}'
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "  Total: $NODE_COUNT nodes"
echo ""

# Pod count by namespace (top 5)
echo "--- Pods by Namespace (Top 5) ---"
kubectl get pods --all-namespaces --no-headers 2>/dev/null | \
  awk '{print $1}' | \
  sort | uniq -c | sort -rn | head -5 | \
  while read count ns; do
    printf "  %-30s %s pods\n" "$ns" "$count"
  done
echo ""

# Pod status summary
echo "--- Pod Status Summary ---"
kubectl get pods --all-namespaces --no-headers 2>/dev/null | \
  awk '{print $4}' | \
  sort | uniq -c | sort -rn | \
  while read count status; do
    printf "  %-15s %s\n" "$status" "$count"
  done
echo ""
echo "============================================"
PLUGINEOF

# Install and test
chmod +x kubectl-cluster_info_extended
sudo mv kubectl-cluster_info_extended /usr/local/bin/

# Run the plugin (note: hyphens in the name become spaces or underscores)
kubectl cluster-info-extended

# Clean up
sudo rm /usr/local/bin/kubectl-cluster_info_extended
```

</details>

---

#### 06. Manage Plugin Lifecycle

Perform a full plugin lifecycle: search, install, use, update, and uninstall. Track the disk space used by `Krew` plugins before and after.

#### Scenario:

- You're managing a shared jump host where disk space matters.
- You need to keep installed plugins lean and up-to-date.

**Hint:** Check the `~/.krew/store/` directory size with `du -sh`.

<details>
<summary>Solution</summary>

```bash
# Check initial disk usage
echo "=== Before ==="
du -sh ~/.krew/ 2>/dev/null || echo "Krew not yet installed"

# Update the plugin index
kubectl krew update

# Search and install a plugin
kubectl krew search neat
kubectl krew install neat

# Use the plugin
kubectl get pod -n kube-system -o yaml | head -1 | kubectl neat

# List installed plugins
kubectl krew list

# Check disk usage after install
echo "=== After Install ==="
du -sh ~/.krew/
du -sh ~/.krew/store/

# Upgrade all plugins
kubectl krew upgrade

# Uninstall the plugin
kubectl krew uninstall neat

# Check disk usage after uninstall
echo "=== After Uninstall ==="
du -sh ~/.krew/

# List remaining plugins
kubectl krew list
```

</details>

---

## Finalize & Cleanup

- To remove all plugins installed during this lab:

```bash
# List all installed plugins
kubectl krew list

# Uninstall specific plugins
kubectl krew uninstall ctx ns view-secret get-all \
  resource-capacity count images access-matrix

# Remove Krew completely (optional)
rm -rf ~/.krew
```

- Remove the `PATH` entry from your shell configuration file if you no longer want `Krew`.

---

## Troubleshooting

- **`kubectl krew` command not found:**

Make sure `~/.krew/bin` is in your `PATH`. Add it to your shell configuration:

```bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

<br>

- **Plugin installation fails:**

Update the plugin index and try again:

```bash
kubectl krew update
kubectl krew install <plugin-name>
```

<br>

- **Plugin not found after installation:**

Verify the plugin is in the Krew bin directory and your `PATH` is correct:

```bash
ls ~/.krew/bin/
echo $PATH | tr ':' '\n' | grep krew
```

<br>

- **Custom plugin not recognized by kubectl:**

Ensure the plugin file name follows the pattern `kubectl-<name>`, is executable, and is in a directory listed in your `PATH`:

```bash
# Check kubectl can find your plugins
kubectl plugin list

# Verify the file is executable
ls -la /usr/local/bin/kubectl-*
```

<br>

- **Permission errors during installation:**

`Krew` installs plugins in your home directory and should not require `sudo`. If you encounter permission issues:

```bash
# Check Krew directory ownership
ls -la ~/.krew/

# Fix ownership if needed
sudo chown -R $(whoami) ~/.krew/
```

---

## Next Steps

- Explore the full [Krew Plugin Index](https://krew.sigs.k8s.io/plugins/) for more plugins
- Learn about [writing kubectl plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) in any language
- Submit your own plugin to the [Krew Index](https://krew.sigs.k8s.io/docs/developer-guide/)
- Combine `Krew` plugins with shell aliases for even faster workflows
- Explore [Krew Custom Indexes](https://krew.sigs.k8s.io/docs/user-guide/custom-indexes/) for private plugin distribution
