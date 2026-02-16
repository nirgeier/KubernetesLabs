# Helm Chart

<img src="../assets/images/helm-k8s-lab.png" alt="Helm Logo" />

- Welcome to the `Helm` Chart hands-on lab! In this tutorial, you'll learn the essentials of `Helm` (version 3), the package manager for Kubernetes.
- You'll build, package, install, and manage applications using `Helm` charts, gaining practical experience with real Kubernetes resources.

---

## What will you learn

- What `Helm` is and why is it useful
- `Helm` chart structure and key files
- Common `Helm` commands for managing releases
- How to create, pack, install, upgrade, and rollback a `Helm` chart
- Go template language syntax for chart templates
- Built-in objects and named templates
- Advanced features: hooks, dependencies, conditionals, and testing
- Troubleshooting and best practices

---

## Official Documentation & References

| Resource                             | Link                                                                                                                            |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| Helm Official Docs                   | [helm.sh/docs](https://helm.sh/docs/)                                                                                           |
| Chart Template Guide                 | [helm.sh/docs/chart_template_guide](https://helm.sh/docs/chart_template_guide/)                                                 |
| Built-in Objects                     | [helm.sh/docs/chart_template_guide/builtin_objects](https://helm.sh/docs/chart_template_guide/builtin_objects/)                 |
| Values Files                         | [helm.sh/docs/chart_template_guide/values_files](https://helm.sh/docs/chart_template_guide/values_files/)                       |
| Template Functions & Pipelines       | [helm.sh/docs/chart_template_guide/functions_and_pipelines](https://helm.sh/docs/chart_template_guide/functions_and_pipelines/) |
| Flow Control (`if`, `range`, `with`) | [helm.sh/docs/chart_template_guide/control_structures](https://helm.sh/docs/chart_template_guide/control_structures/)           |
| Named Templates (`_helpers.tpl`)     | [helm.sh/docs/chart_template_guide/named_templates](https://helm.sh/docs/chart_template_guide/named_templates/)                 |
| Chart Hooks                          | [helm.sh/docs/topics/charts_hooks](https://helm.sh/docs/topics/charts_hooks/)                                                   |
| Chart Dependencies                   | [helm.sh/docs/helm/helm_dependency](https://helm.sh/docs/helm/helm_dependency/)                                                 |
| Chart Tests                          | [helm.sh/docs/topics/chart_tests](https://helm.sh/docs/topics/chart_tests/)                                                     |
| Chart Best Practices                 | [helm.sh/docs/chart_best_practices](https://helm.sh/docs/chart_best_practices/)                                                 |
| Go Template Language                 | [pkg.go.dev/text/template](https://pkg.go.dev/text/template)                                                                    |
| Sprig Template Functions             | [masterminds.github.io/sprig](https://masterminds.github.io/sprig/)                                                             |
| Artifact Hub (Chart Repository)      | [artifacthub.io](https://artifacthub.io/)                                                                                       |
| Helm Cheat Sheet                     | [helm.sh/docs/intro/cheatsheet](https://helm.sh/docs/intro/cheatsheet/)                                                         |

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

=== "Chart"

- A `Helm` package is called a **chart**.
- Charts are versioned, shareable packages that contain all the Kubernetes resources needed to run an application.

=== "Release"

- A specific instance of a chart is called a **release**.
- Each release is a deployed _version of a chart_, with its own configuration, resources, and revision history.

=== "Repository"

- A collection of charts is stored in a `Helm` repository.
- `Helm` charts can be hosted in public or private repositories for easy sharing and distribution.

### Chart files and folders

| Filename/Folder          | Description                                                                                                  |
| ------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `Chart.yaml`             | Contains metadata about the chart, including its name, version, dependencies, and maintainers.               |
| `Chart.lock`             | Lock file listing exact versions of resolved dependencies.                                                   |
| `values.yaml`            | Defines **default configuration** values for the chart. Users can override these values during installation. |
| `values.schema.json`     | Optional JSON Schema for validating `values.yaml` structure.                                                 |
| `templates/`             | Directory containing Kubernetes manifest templates written in the Go template language.                      |
| `templates/NOTES.txt`    | A plain text file containing usage notes displayed after installation.                                       |
| `templates/_helpers.tpl` | A file containing reusable named templates (partials).                                                       |
| `templates/tests/`       | Directory containing test pod definitions for `helm test`.                                                   |
| `charts/`                | Directory containing dependencies (subcharts) of the chart.                                                  |
| `crds/`                  | Directory containing Custom Resource Definitions (installed before templates).                               |
| `README.md`              | Documentation for the chart, explaining how to use and configure it.                                         |

### Git HELM chart repo structure

While there are many ways to structure your Helm charts in a Git repository, here are the two most common patterns:

#### Pattern 1: One Repo per Chart

- **Structure**: The root of the repository contains the `Chart.yaml`, `values.yaml`, and `templates/` folder.
- **Use Case**: Best for microservices where each service has its own repository and its own chart.
- **CI/CD**: The chart is versioned and released alongside the application code.

```text
my-app/
├── Chart.yaml
├── values.yaml
├── templates/
├── src/            # Application source code
└── ...
```

#### Pattern 2: Dedicated Charts Repository (Monorepo)

- **Structure**: A central repository containing multiple charts in a `charts/` directory.
- **Use Case**: Best for managing infrastructure charts (e.g., redis, postgres) or when you want centralized management of all your organization's charts.
- **Hosting**: Often used with GitHub Pages to host the chart repository index (`index.yaml`) and packaged charts (`.tgz`).

```text
my-charts-repo/
├── charts/
│   ├── redis/
│   │   ├── Chart.yaml
│   │   └── ...
│   └── frontend/
│       ├── Chart.yaml
│       └── ...
├── docs/           # Contains generated index.yaml and .tgz files (GitHub Pages source)
└── README.md
```

#### GitHub Pages as a Helm Repository

You can easily verify your Git repository into a Helm Chart Repository using GitHub Pages:

1. **Docs Folder**: Create a `docs` folder in your repo.
2. **Package**: Run `helm package ./charts/mychart -d ./docs`.
3. **Index**: Run `helm repo index ./docs --url https://<username>.github.io/<repo-name>/`.
4. **Publish**: Enable GitHub Pages for the `docs` folder.

Users can then add your repo:
```bash
helm repo add my-repo https://<username>.github.io/<repo-name>/
```



##### codewizard-helm-demo Helm Chart structure

```sh
- Chart.yaml        # Defines chart metadata and values schema
- values.yaml       # Default configuration values
- templates/        # Deployment templates using Go templating language
  - _helpers.tpl    # Named templates (partials) used across templates
  - Namespace.yaml  # Namespace manifest template
  - ConfigMap.yaml  # ConfigMap manifest template
  - Deployment.yaml # Deployment manifest template
  - Service.yaml    # Service manifest template
- README.md         # Documentation for your chart
```

### Common `Helm` Commands

Below are the most common `Helm` commands you'll use when working with `Helm` charts. Each command includes syntax, description, and detailed usage examples.


??? example "`helm create` - Create a new chart"

      **Syntax:** `helm create <chart-name>`

      **Description:** Creates a new Helm chart with the specified name. This command generates a chart directory with a standard structure including default templates, values.yaml, and Chart.yaml.

      - Creates a new chart directory with a standard structure
      - Includes default templates, values.yaml, and Chart.yaml
      - Provides a starting point that follows Helm best practices
      - You can customize the generated files to match your application needs

          ```bash
          # Create a new chart named 'myapp'
          helm create myapp

          # View the generated structure
          tree myapp

          # Output shows:
          # myapp/
          # ├── Chart.yaml
          # ├── values.yaml
          # ├── charts/
          # └── templates/
          #     ├── NOTES.txt
          #     ├── _helpers.tpl
          #     ├── deployment.yaml
          #     ├── service.yaml
          #     └── ...
          ```

??? example "`helm install` - Install a chart"

      **Syntax:** `helm install <release-name> <chart-path>`

      **Description:** Installs a Helm chart to your Kubernetes cluster, creating a new release with the specified name.

      - Deploys a chart to your Kubernetes cluster
      - Creates a new release with a unique name
      - Can override values using `--set` or `-f` flags
      - Use `--dry-run` to preview changes without applying them

          ```bash
          # Basic install
          helm install myrelease ./myapp

          # Install with custom values file
          helm install myrelease ./myapp -f custom-values.yaml

          # Install with inline value overrides
          helm install myrelease ./myapp --set replicaCount=3

          # Install in a specific namespace
          helm install myrelease ./myapp --namespace production --create-namespace

          # Dry run to see what would be installed
          helm install myrelease ./myapp --dry-run --debug

          # Install from a packaged chart
          helm install myrelease myapp-1.0.0.tgz

          # Install with a generated name
          helm install myapp --generate-name

          # Wait for all resources to be ready before marking release as successful
          helm install myrelease ./myapp --wait --timeout 5m
          ```

??? example "`helm upgrade` - Upgrade a release"

      **Syntax:** `helm upgrade <release-name> <chart-path>`

      **Description:** Upgrades an installed release with a new version of a chart or updated configuration values.

      - Updates an existing release with new configurations or chart version
      - Maintains revision history for rollback capability
      - Can use `--install` to install if release doesn't exist
      - Supports value overrides like install command

          ```bash
          # Basic upgrade
          helm upgrade myrelease ./myapp

          # Upgrade with new values
          helm upgrade myrelease ./myapp -f production-values.yaml

          # Upgrade or install if not exists (atomic operation)
          helm upgrade myrelease ./myapp --install

          # Upgrade with specific values
          helm upgrade myrelease ./myapp --set image.tag=v2.0.0

          # Force resource updates even if unchanged
          helm upgrade myrelease ./myapp --force

          # Reuse previous values and merge with new ones
          helm upgrade myrelease ./myapp --reuse-values --set newKey=newValue

          # Reset values to chart defaults
          helm upgrade myrelease ./myapp --reset-values

          # Wait for upgrade to complete
          helm upgrade myrelease ./myapp --wait --timeout 10m

          # Atomic upgrade - rollback on failure
          helm upgrade myrelease ./myapp --atomic --timeout 5m
          ```

??? example "`helm uninstall` - Remove a release"

      **Syntax:** `helm uninstall <release-name>`

      **Description:** Uninstalls a release from the Kubernetes cluster, removing all associated resources.

      - Deletes a release and all associated Kubernetes resources
      - Removes the release from Helm's history by default
      - Use `--keep-history` to retain release history for potential restoration
      - Respects hook deletion policies defined in templates

          ```bash
          # Basic uninstall
          helm uninstall myrelease

          # Uninstall but keep history (allows rollback)
          helm uninstall myrelease --keep-history

          # Uninstall from specific namespace
          helm uninstall myrelease --namespace production

          # Uninstall with custom timeout
          helm uninstall myrelease --timeout 5m

          # Dry run - see what would be deleted
          helm uninstall myrelease --dry-run

          # Uninstall and wait for all resources to be deleted
          helm uninstall myrelease --wait
          ```

??? example "`helm list` - List releases"

      **Syntax:** `helm list`

      **Description:** Lists all installed Helm releases in the current or specified namespace.

      - Shows all releases in the current namespace
      - Displays release name, namespace, revision, status, and chart info
      - Supports filtering and output formatting options
      - Use `--all-namespaces` to see releases across all namespaces

          ```bash
          # List all releases in current namespace
          helm list

          # List all releases across all namespaces
          helm list --all-namespaces

          # List releases in specific namespace
          helm list --namespace production

          # Show all releases including uninstalled (if kept history)
          helm list --all

          # Filter by status
          helm list --deployed
          helm list --failed
          helm list --pending

          # Show more details (longer output)
          helm list --all-namespaces -o wide

          # Output as JSON
          helm list -o json

          # Output as YAML
          helm list -o yaml

          # Filter releases by name pattern
          helm list --filter 'myapp.*'

          # Limit number of results
          helm list --max 10

          # Sort by release date
          helm list --date
          ```

??? example "`helm status` - Show release status"

      **Syntax:** `helm status <release-name>`

      **Description:** Shows the status of a deployed Helm release including resource information and deployment details.

      - Displays detailed information about a deployed release
      - Shows resource status, last deployment time, and revision number
      - Includes NOTES.txt content if present
      - Useful for debugging and verifying deployments

          ```bash
          # Show status of a release
          helm status myrelease

          # Show status from specific namespace
          helm status myrelease --namespace production

          # Show status at specific revision
          helm status myrelease --revision 2

          # Output as JSON
          helm status myrelease -o json

          # Output as YAML
          helm status myrelease -o yaml

          # Show status without displaying NOTES
          helm status myrelease --show-desc
          ```

??? example "`helm rollback` - Rollback to previous revision"

      **Syntax:** `helm rollback <release-name> [revision]`

      **Description:** Rollbacks a release to a previous revision number.

      - Reverts a release to a previous revision
      - Useful for quick recovery from failed upgrades
      - Creates a new revision (rollback is tracked in history)
      - Can rollback to any previously deployed revision

          ```bash
          # Rollback to previous revision
          helm rollback myrelease

          # Rollback to specific revision
          helm rollback myrelease 3

          # Rollback with timeout
          helm rollback myrelease 2 --timeout 5m

          # Wait for rollback to complete
          helm rollback myrelease --wait

          # Force rollback even if resources haven't changed
          helm rollback myrelease --force

          # Dry run - see what would be rolled back
          helm rollback myrelease --dry-run

          # Recreate resources (delete and recreate)
          helm rollback myrelease --recreate-pods

          # Cleanup on fail
          helm rollback myrelease --cleanup-on-fail
          ```

??? example "`helm get all` - Get release information"

      **Syntax:** `helm get all <release-name>`

      **Description:** Retrieves all information about a deployed release including templates, values, hooks, and notes.

      - Retrieves all information about a release
      - Shows manifest, values, hooks, and notes
      - Useful for debugging and understanding what was deployed
      - Can retrieve information from specific revisions

          ```bash
          # Get all info about a release
          helm get all myrelease

          # Get all info from specific revision
          helm get all myrelease --revision 2

          # Get all info from specific namespace
          helm get all myrelease --namespace production

          # Output as template for reuse
          helm get all myrelease --template '{{.Release.Manifest}}'
          ```

??? example "`helm get values` - Get release values"

      **Syntax:** `helm get values <release-name>`

      **Description:** Shows the user-supplied values for a release.

      - Shows the values that were used for a specific release
      - Displays only user-supplied values by default
      - Use `--all` to see all values including defaults
      - Useful for understanding current configuration

          ```bash
          # Get user-supplied values
          helm get values myrelease

          # Get all values (including defaults)
          helm get values myrelease --all

          # Get values from specific revision
          helm get values myrelease --revision 2

          # Output as JSON
          helm get values myrelease -o json

          # Output as YAML
          helm get values myrelease -o yaml

          # Save values to file
          helm get values myrelease > current-values.yaml
          ```

??? example "`helm show values` - Show chart default values"

      **Syntax:** `helm show values <chart-name>`

      **Description:** Shows the default values of a Helm chart before installation.

      - Displays the default values.yaml from a chart
      - Works with local charts, remote charts, or chart repositories
      - Useful for understanding available configuration options
      - Shows values before installation

          ```bash
          # Show default values of local chart
          helm show values ./myapp

          # Show values from packaged chart
          helm show values myapp-1.0.0.tgz

          # Show values from chart repository
          helm show values bitnami/nginx

          # Show values at specific version
          helm show values bitnami/nginx --version 15.0.0

          # Save default values to file
          helm show values ./myapp > default-values.yaml
          ```

??? example "`helm template` - Render templates locally"

      **Syntax:** `helm template <release-name> <chart-path>`

      **Description:** Renders chart templates locally without installing to the cluster.

      - Renders chart templates locally without connecting to Kubernetes
      - Outputs rendered YAML manifests to stdout
      - Useful for debugging templates and previewing changes
      - Does not require cluster access

          ```bash
          # Render templates to stdout
          helm template myrelease ./myapp

          # Render with custom values
          helm template myrelease ./myapp -f custom-values.yaml

          # Render with inline values
          helm template myrelease ./myapp --set replicaCount=3

          # Render and save to file
          helm template myrelease ./myapp > rendered-manifests.yaml

          # Show only specific template
          helm template myrelease ./myapp --show-only templates/deployment.yaml

          # Debug mode - show more information
          helm template myrelease ./myapp --debug

          # Validate rendered output
          helm template myrelease ./myapp --validate

          # Include CRDs in output
          helm template myrelease ./myapp --include-crds

          # Render for specific Kubernetes version
          helm template myrelease ./myapp --kube-version 1.28.0
          ```

??? example "`helm lint` - Validate chart"

      **Syntax:** `helm lint <chart-path>`

      **Description:** Runs a series of tests to verify that the chart is well-formed and follows best practices.

      - Runs tests to verify chart is well-formed
      - Checks Chart.yaml, values.yaml, and template syntax
      - Identifies common errors and issues
      - Should be run before packaging or installing

          ```bash
          # Lint a chart
          helm lint ./myapp

          # Lint with custom values
          helm lint ./myapp -f custom-values.yaml

          # Lint with inline values
          helm lint ./myapp --set replicaCount=3

          # Strict linting (fail on warnings)
          helm lint ./myapp --strict

          # Lint with debug output
          helm lint ./myapp --debug

          # Lint multiple charts
          helm lint ./myapp ./anotherapp
          ```

??? example "`helm history` - Show release history"

      **Syntax:** `helm history <release-name>`

      **Description:** Prints historical revisions for a given release.

      - Displays revision history for a release
      - Shows revision number, update time, status, and description
      - Useful for understanding what changed and when
      - Helps identify which revision to rollback to

          ```bash
          # Show release history
          helm history myrelease

          # Show history from specific namespace
          helm history myrelease --namespace production

          # Show more revisions (default is 256)
          helm history myrelease --max 100

          # Output as JSON
          helm history myrelease -o json

          # Output as YAML
          helm history myrelease -o yaml

          # Output as table (default)
          helm history myrelease -o table
          ```

??? example "`helm test` - Run release tests"

      **Syntax:** `helm test <release-name>`

      **Description:** Runs the tests defined in a chart for a release.

      - Executes tests defined in chart's templates/tests/ directory
      - Tests are Kubernetes pods with the `helm.sh/hook: test` annotation
      - Validates that a release is working correctly
      - Returns exit code based on test success/failure

          ```bash
          # Run tests for a release
          helm test myrelease

          # Run tests from specific namespace
          helm test myrelease --namespace production

          # Run tests with timeout
          helm test myrelease --timeout 5m

          # Show test logs
          helm test myrelease --logs

          # Cleanup tests after run (default: false)
          helm test myrelease --cleanup

          # Filter which tests to run
          helm test myrelease --filter name=test-connection
          ```

??? example "`helm dependency update` - Update chart dependencies"

      **Syntax:** `helm dependency update <chart-path>`

      **Description:** Updates the charts/ directory based on Chart.yaml dependencies.

      - Downloads chart dependencies listed in Chart.yaml
      - Stores dependencies in the charts/ subdirectory
      - Creates or updates Chart.lock file
      - Required before packaging or installing charts with dependencies

          ```bash
          # Update dependencies
          helm dependency update ./myapp

          # Update and skip refreshing repository index
          helm dependency update ./myapp --skip-refresh

          # Verify dependencies
          helm dependency list ./myapp

          # Build dependencies (use Chart.lock)
          helm dependency build ./myapp
          ```

??? example "`helm repo add` - Add chart repository"

      **Syntax:** `helm repo add <name> <url>`

      **Description:** Adds a chart repository to your local Helm configuration.

      - Adds a chart repository to your local Helm configuration
      - Repositories are stored in ~/.config/helm/repositories.yaml
      - Enables searching and installing charts from the repository
      - Can add both HTTP and OCI repositories

          ```bash
          # Add a chart repository
          helm repo add bitnami https://charts.bitnami.com/bitnami

          # Add with authentication
          helm repo add myrepo https://charts.example.com --username user --password pass

          # Add and force update if exists
          helm repo add bitnami https://charts.bitnami.com/bitnami --force-update

          # Add repository with custom certificate
          helm repo add myrepo https://charts.example.com --ca-file ca.crt

          # Add repository skipping TLS verification (not recommended)
          helm repo add myrepo https://charts.example.com --insecure-skip-tls-verify

          # List all repositories
          helm repo list
          ```

??? example "`helm repo update` - Update repository information"

      **Syntax:** `helm repo update`

      **Description:** Updates information of available charts from chart repositories.

      - Updates the local cache of charts from all added repositories
      - Fetches the latest available charts and versions
      - Should be run periodically to see new chart releases
      - Similar to `apt update` or `yum update`

          ```bash
          # Update all repositories
          helm repo update

          # Update specific repository
          helm repo update bitnami

          # Update with failure on any repository error
          helm repo update --fail-on-repo-update-fail

          # Update multiple specific repositories
          helm repo update bitnami stable
          ```

??? example "`helm search repo` - Search repositories"

      **Syntax:** `helm search repo <keyword>`

      **Description:** Searches repositories for charts matching a keyword.

      - Searches added repositories for charts matching keyword
      - Shows chart name, version, app version, and description
      - Supports regex patterns for advanced searching
      - Only searches locally added repositories

          ```bash
          # Search for charts
          helm search repo nginx

          # Search with version information
          helm search repo nginx --versions

          # Search with regex
          helm search repo 'nginx.*'

          # Show development versions (pre-release, etc.)
          helm search repo nginx --devel

          # Search with specific version constraint
          helm search repo nginx --version "~15.0"

          # Output as JSON
          helm search repo nginx -o json

          # Output as YAML
          helm search repo nginx -o yaml

          # Search all repositories
          helm search repo --max-col-width 0
          ```

---

## Advanced Concepts

### Built-in Objects

`Helm` templates have access to several built-in objects. These are the most commonly used:

| Object               | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| `.Release.Name`      | The name of the release                                             |
| `.Release.Namespace` | The namespace the release is installed into                         |
| `.Release.Revision`  | The revision number of this release (starts at 1)                   |
| `.Release.IsInstall` | `true` if the current operation is an install                       |
| `.Release.IsUpgrade` | `true` if the current operation is an upgrade                       |
| `.Release.Service`   | The service rendering the template (always `Helm`)                  |
| `.Values`            | Values passed to the template from `values.yaml` and user overrides |
| `.Chart.Name`        | The name of the chart from `Chart.yaml`                             |
| `.Chart.Version`     | The version of the chart                                            |
| `.Chart.AppVersion`  | The app version from `Chart.yaml`                                   |
| `.Template.Name`     | The namespaced path to the current template file                    |
| `.Template.BasePath` | The namespaced path to the templates directory                      |
| `.Files`             | Access to non-template files in the chart                           |
| `.Capabilities`      | Information about the Kubernetes cluster capabilities               |

> Docs: [Built-in Objects](https://helm.sh/docs/chart_template_guide/builtin_objects/)

---

### Go Template Syntax

`Helm` uses the **Go template language** with additional [Sprig](https://masterminds.github.io/sprig/) functions. Here's a quick reference:

#### Template Delimiters

| Delimiter syntax | Meaning                                                                                                  |
| ---------------- | -------------------------------------------------------------------------------------------------------- |
| `{{ ... }}`      | Standard output expression - evaluates and prints the result.                                            |
| `{{- ... }}`     | Trim whitespace/newline to the _left_ of the action (left-trim). Useful at the start of a template line. |
| `{{ ... -}}`     | Trim whitespace/newline to the _right_ of the action (right-trim). Useful at the end of a template line. |
| `{{- ... -}}`    | Trim whitespace/newline on _both sides_ of the action.                                                   |

!!! danger "Delimiters"
      - Whitespace trimming controls whether newlines and spaces immediately before or after template actions appear in the rendered YAML - this is important to produce valid, tidy manifests.
      - Prefer `{{-` at the start of a block and `-}}` at the end of a block when you want to avoid blank lines in rendered output.

Example (shows differences in rendered output):

```yaml
# Template A (no trimming)
prefix:
  {{ "val" }}
suffix:

# Template B (left-trim)
prefix:
  {{- "val" }}
suffix:

# Template C (right-trim)
prefix:
  {{ "val" -}}
suffix:

# Template D (both sides trimmed)
prefix:
  {{- "val" -}}
suffix:
```

When rendered, trimming removes the surrounding blank lines and keeps YAML indentation correct; use `helm template` during development to verify the output.

#### Variables

```yaml
# Assigning a variable
{{- $name := .Values.appName }}

# Using a variable
app: {{ $name }}
```

#### Pipelines and Functions

Template functions can be chained using the **pipe** `|` operator:

```yaml
# C`yaml
# Convert to uppercase
name: {{ .Values.name | upper }}

# Default value if empty
image: {{ .Values.image | default "nginx:latest" }}

# Quoting a value
version: {{ .Values.version | quote }}

# Trim and truncate
name: {{ .Values.name | trunc 63 | trimSuffix "-" }}

# Indentation (critical for YAML)
metadata:
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
```

---


!!! info "Common Sprig Functions"

    - Sprig is a library that provides over 70 useful template functions for Go’s template language.

        - **String**: `upper`, `lower`, `title`, `trim`, `quote`, `trunc`, `trimSuffix`
        - **Defaults**: `default`
        - **Indentation**: `nindent`, `indent`
        - **Encoding/Conversion**: `toYaml`, `toJson`, `b64enc`, `b64dec`
        - **Date/Time**: `now`, `htmlDate`
        - **Crypto**: `sha256sum> Common Sprig functions: `upper`, `lower`, `title`, `trim`, `quote`, `default`, `trunc`, `trimSuffix`, `nindent`, `indent`, `toYaml`, `toJson`, `b64enc`, `b64dec`, `sha256sum`, `now`, `htmlDate`

> Docs: [Functions and Pipelines](https://helm.sh/docs/chart_template_guide/functions_and_pipelines/)

---

### Flow Control

#### Conditionals (`if` / `else`)

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" . }}
spec:
  rules:
    - host: {{ .Values.ingress.host }}
{{- end }}
`
```yaml
# if / else if / else
{{- if eq .Values.env "production" }}
  replicas: 5
{{- else if eq .Values.env "staging" }}
  replicas: 2
{{- else }}
  replicas: 1
{{- end }}
```

#### Comparison operators

| Operator | Description           |
| -------- | --------------------- |
| `eq`     | Equal                 |
| `ne`     | Not equal             |
| `lt`     | Less than             |
| `gt`     | Greater than          |
| `le`     | Less than or equal    |
| `ge`     | Greater than or equal |
| `and`    | Logical AND           |
| `or`     | Logical OR            |
| `not`    | Logical NOT           |

#### Looping (`range`)

```yaml
# Iterating over a list
env:
{{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value | quote }}
{{- end }}
```

```yaml
# Iterating over a map/dict
labels:
{{- range $key, $value := .Values.labels }}
  {{ $key }}: {{ $value | quote }}
{{- end }}
```

#### Scoping (`with`)

```yaml
# `with` changes the scope of `.` inside the block
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
```

> Docs: [Flow Control](https://helm.sh/docs/chart_template_guide/control_structures/)

---

### Named Templates (`_helpers.tpl`)

- Files prefixed with `_` (underscore) in the `templates/` directory are **not rendered** as Kubernetes manifests.
- They are used to define reusable **named templates** (also called partials or sub-templates).
- Named templates are defined with `define` and invoked with `include` (preferred) or `template`.

```yaml
# _helpers.tpl - defining a named template
{{- define "myapp.labels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

```yaml
# Using the named template in a manifest
metadata:
  labels: { { - include "myapp.labels" . | nindent 4 } }
```

!!! info "`include` vs `template`"

      - Always prefer `include` over `template`.
      -The `include` function allows you to **pipe** the output (e.g., `| nindent 4`), while `template` does not support pipelines.

> Docs: [Named Templates](https://helm.sh/docs/chart_template_guide/named_templates/)

---

### Values Override Precedence

When installing or upgrading a release, values can be supplied from multiple sources.
The override precedence (last wins) is:

1. `values.yaml` in the chart (defaults)
2. Parent chart's `values.yaml` (for subcharts)
3. Values file passed with `-f` / `--values`
4. Individual values set with `--set` or `--set-string`

```sh
# Override with a custom values file
helm install my-release ./mychart -f custom-values.yaml

# Override with --set (highest precedence)
helm install my-release ./mychart --set replicaCount=3

# Multiple overrides combined
helm install my-release ./mychart \
  -f production-values.yaml \
  --set image.tag="v2.0.0"

# Override with --set-string (forces string type)
helm install my-release ./mychart --set-string image.tag="1234"

# Override with --set-file (read value from a file)
helm install my-release ./mychart --set-file config=./my-config.txt
```

> Docs: [Values Files](https://helm.sh/docs/chart_template_guide/values_files/)

---

### Chart Dependencies (Subcharts)

Charts can depend on other charts. Dependencies are declared in `Chart.yaml`:

```yaml
# Chart.yaml
apiVersion: v2
name: my-app
version: 1.0.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

```sh
# Download and update dependencies
helm dependency update ./my-app

# The dependencies are stored in the charts/ directory
ls ./my-app/charts/
```

> Docs: [Chart Dependencies](https://helm.sh/docs/helm/helm_dependency/)

---

### Helm Hooks

Hooks allow you to run resources at specific points in a release lifecycle.
  - They are standard Kubernetes resources (Jobs, Pods, ConfigMaps, etc.) with special annotations that tell Helm when to execute them.

#### Hook Types

| Hook            | Description                             |
|-----------------|-----------------------------------------|
| `pre-install`   | Runs before any resources are installed |
| `post-install`  | Runs after all resources are installed  |
| `pre-upgrade`   | Runs before any resources are upgraded  |
| `post-upgrade`  | Runs after all resources are upgraded   |
| `pre-delete`    | Runs before any resources are deleted   |
| `post-delete`   | Runs after all resources are deleted    |
| `pre-rollback`  | Runs before a rollback                  |
| `post-rollback` | Runs after a rollback                   |
| `test`          | Runs when `helm test` is called         |

#### Hook Annotations

Hooks are controlled by three key annotations:

| Annotation                   | Description                                                                                               |
|------------------------------|-----------------------------------------------------------------------------------------------------------|
| `helm.sh/hook`               | Defines when the hook runs (required). Can specify multiple hooks: `"pre-install,pre-upgrade"`            |
| `helm.sh/hook-weight`        | Defines execution order (default: 0). Lower weights execute first. Can be negative.                       |
| `helm.sh/hook-delete-policy` | Defines when to delete the hook resource. Values: `before-hook-creation`, `hook-succeeded`, `hook-failed` |

#### Hook Deletion Policies

| Policy                 | Description                                                          |
|------------------------|----------------------------------------------------------------------|
| `before-hook-creation` | Delete previous hook resource before a new one is launched (default) |
| `hook-succeeded`       | Delete the hook resource after it successfully completes             |
| `hook-failed`          | Delete the hook resource if it fails                                 |

You can specify multiple policies: `"hook-succeeded,hook-failed"`

#### Hook Execution Order

Hooks execute in the following order:

1. **Sorted by weight** (ascending): hooks with lower weights run first
2. **Sorted by kind** (alphabetical): if weights are equal
3. **Sorted by name** (alphabetical): if both weight and kind are equal

#### Practical Examples

#### (pre-install/pre-upgrade)

??? example "Example 1: Database Migration (pre-install/pre-upgrade)"

      - This hook runs a database migration job before installing or upgrading the main application resources.
      - It ensures that the database schema is up-to-date before the application starts.
      - The `migrate.sh` script would contain the logic to perform the database migration, and it would use environment variables to connect to the database.
          ```yaml
          # templates/hooks/db-migrate.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-db-migrate
            annotations:
              "helm.sh/hook": pre-install,pre-upgrade
              "helm.sh/hook-weight": "0"
              "helm.sh/hook-delete-policy": hook-succeeded,hook-failed
          spec:
            template:
              metadata:
                name: {{ include "myapp.fullname" . }}-db-migrate
              spec:
                containers:
                  - name: migrate
                    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
                    command: ["./migrate.sh"]
                    env:
                      - name: DB_HOST
                        value: {{ .Values.database.host }}
                      - name: DB_NAME
                        value: {{ .Values.database.name }}
                restartPolicy: Never
            backoffLimit: 3
          ```

??? example "Example 2: Schema Initialization (pre-install only)"

      - This hook runs a database initialization job only during the initial installation of the chart.
      - It creates the database schema if it doesn't already exist.
      - It uses a lower weight to ensure it runs before the migration hook.
      - The `psql` command is used to create the database, and it connects using environment variables for the database host and credentials.
      - This hook will not run during upgrades, ensuring that it only initializes the database on the first install.
          ```yaml
          # templates/hooks/db-init.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-db-init
            annotations:
              "helm.sh/hook": pre-install
              "helm.sh/hook-weight": "-5"  # Runs before migration (weight: 0)
              "helm.sh/hook-delete-policy": hook-succeeded
          spec:
            template:
              spec:
                containers:
                  - name: init-db
                    image: postgres:14
                    command:
                      - sh
                      - -c
                      - |
                        psql -h $DB_HOST -U $DB_USER -c "CREATE DATABASE IF NOT EXISTS {{ .Values.database.name }};"
                    env:
                      - name: DB_HOST
                        value: {{ .Values.database.host }}
                      - name: DB_USER
                        valueFrom:
                          secretKeyRef:
                            name: db-secret
                            key: username
                      - name: PGPASSWORD
                        valueFrom:
                          secretKeyRef:
                            name: db-secret
                            key: password
                restartPolicy: Never
          ```

??? example "Example 3: Service Readiness Check (post-install)"

      - This hook runs a job after the main application resources are installed to check if the service is ready.
      - It uses a simple `curl` command to check the health endpoint of the service, retrying until it gets a successful response.
      - This ensures that the application is fully operational before the release is considered successful.
      - The hook will be deleted after it succeeds, preventing it from running again unnecessarily.
      - This is particularly useful for applications that require some time to become ready after deployment, such as those that perform initialization tasks or have complex startup processes.
      - By using a post-install hook, you can provide immediate feedback on the success of the deployment and ensure that users are aware of any issues with service readiness right after installation.
          ```yaml
          # templates/hooks/smoke-test.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-smoke-test
            annotations:
              "helm.sh/hook": post-install,post-upgrade
              "helm.sh/hook-weight": "5"
              "helm.sh/hook-delete-policy": hook-succeeded
          spec:
            template:
              spec:
                containers:
                  - name: smoke-test
                    image: curlimages/curl:latest
                    command:
                      - sh
                      - -c
                      - |
                        echo "Waiting for service to be ready..."
                        until curl -f http://{{ include "myapp.fullname" . }}:{{ .Values.service.port }}/health; do
                          echo "Service not ready yet, retrying in 5 seconds..."
                          sleep 5
                        done
                        echo "Service is ready!"
                restartPolicy: Never
            backoffLimit: 10
          ```

??? example "Example 4: Backup Before Upgrade (pre-upgrade)"

      - This hook creates a backup of the database before upgrading the application.
      - It uses the `pg_dump` command to create a SQL backup file with a timestamp.
      - The backup is stored in a persistent volume claim to ensure it's retained even if the job is deleted.
      - The hook runs with a weight of `-10` to ensure it executes before other upgrade hooks like migrations.
      - This is a critical safety measure to ensure you can restore your data if an upgrade fails or causes data corruption.
          ```yaml
          # templates/hooks/backup.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-backup-{{ now | date "20060102-150405" }}
            annotations:
              "helm.sh/hook": pre-upgrade
              "helm.sh/hook-weight": "-10"
              "helm.sh/hook-delete-policy": hook-succeeded
          spec:
            template:
              spec:
                containers:
                  - name: backup
                    image: "{{ .Values.backup.image }}"
                    command:
                      - sh
                      - -c
                      - |
                        echo "Creating backup before upgrade..."
                        pg_dump -h $DB_HOST -U $DB_USER $DB_NAME > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
                        echo "Backup completed successfully"
                    env:
                      - name: DB_HOST
                        value: {{ .Values.database.host }}
                      - name: DB_USER
                        value: {{ .Values.database.user }}
                      - name: DB_NAME
                        value: {{ .Values.database.name }}
                    volumeMounts:
                      - name: backup-storage
                        mountPath: /backup
                volumes:
                  - name: backup-storage
                    persistentVolumeClaim:
                      claimName: backup-pvc
                restartPolicy: Never
          ```

??? example "Example 5: Notification Hook (post-install/post-upgrade)"

      - This hook sends a notification to Slack after the application is successfully installed or upgraded.
      - It uses the Helm built-in `.Release.IsInstall` variable to determine whether this is a new installation or an upgrade.
      - The hook runs with a weight of `10` to ensure it executes after other post-install/upgrade hooks like smoke tests.
      - Notifications are sent regardless of hook success or failure (deletion policy: `hook-succeeded,hook-failed`).
      - This is useful for keeping your team informed about deployments in production environments.
          ```yaml
          # templates/hooks/notify.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-notify
            annotations:
              "helm.sh/hook": post-install,post-upgrade
              "helm.sh/hook-weight": "10"  # Runs after smoke test
              "helm.sh/hook-delete-policy": hook-succeeded,hook-failed
          spec:
            template:
              spec:
                containers:
                  - name: notify
                    image: curlimages/curl:latest
                    command:
                      - sh
                      - -c
                      - |
                        if [ "{{ .Release.IsInstall }}" = "true" ]; then
                          ACTION="installed"
                        else
                          ACTION="upgraded"
                        fi
                        curl -X POST {{ .Values.slack.webhookUrl }} \
                          -H 'Content-Type: application/json' \
                          -d "{\"text\":\"Application {{ .Release.Name }} has been $ACTION to version {{ .Chart.Version }} in namespace {{ .Release.Namespace }}\"}"
                restartPolicy: Never
          ```

??? example "Example 6: Cleanup Hook (pre-delete)"

      - This hook performs cleanup operations before the main application resources are deleted.
      - It uses `kubectl` to delete specific resources (in this case, ConfigMaps) that match certain labels.
      - The hook requires a ServiceAccount with appropriate RBAC permissions to delete resources in the namespace.
      - This is useful for cleaning up dynamically created resources that might not be tracked by Helm directly.
      - The hook will be deleted after it succeeds, preventing orphaned cleanup jobs from accumulating.
          ```yaml
          # templates/hooks/cleanup.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-cleanup
            annotations:
              "helm.sh/hook": pre-delete
              "helm.sh/hook-weight": "0"
              "helm.sh/hook-delete-policy": hook-succeeded
          spec:
            template:
              spec:
                containers:
                  - name: cleanup
                    image: bitnami/kubectl:latest
                    command:
                      - sh
                      - -c
                      - |
                        echo "Cleaning up resources..."
                        kubectl delete configmap -n {{ .Release.Namespace }} -l app={{ include "myapp.name" . }},release={{ .Release.Name }}
                        echo "Cleanup completed"
                serviceAccountName: {{ include "myapp.fullname" . }}-cleanup
                restartPolicy: Never
          ```

??? example "Example 7: Secret Creation Hook (pre-install)"

      - This hook generates a random password and creates a Kubernetes secret before the main application resources are installed.
      - It uses the `bitnami/kubectl` image to run `kubectl` commands directly from the job.
      - The generated password is stored in a secret named `<release-name>-db-secret` in the same namespace as the release.
      - The hook is set to run only during installation, ensuring that a new secret is created each time a new release is installed.
      - The `before-hook-creation` deletion policy ensures that if the hook runs multiple times (e.g., due to retries), the previous secret will be deleted before a new one is created, preventing orphaned secrets from accumulating.
      - This hook is useful for scenarios where you need to generate dynamic configuration or credentials that must be available before the main application resources are created.
          ```yaml
          # templates/hooks/create-secret.yaml
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{ include "myapp.fullname" . }}-create-secret
            annotations:
              "helm.sh/hook": pre-install
              "helm.sh/hook-weight": "-15"  # Runs very early
              "helm.sh/hook-delete-policy": before-hook-creation
          spec:
            template:
              spec:
                containers:
                  - name: create-secret
                    image: bitnami/kubectl:latest
                    command:
                      - sh
                      - -c
                      - |
                        # Generate random password
                        PASSWORD=$(openssl rand -base64 32)

                        # Create Kubernetes secret
                        kubectl create secret generic {{ include "myapp.fullname" . }}-db-secret \
                          --from-literal=password=$PASSWORD \
                          --namespace={{ .Release.Namespace }} \
                          --dry-run=client -o yaml | kubectl apply -f -

                        echo "Secret created successfully"
                serviceAccountName: {{ include "myapp.fullname" . }}-admin
                restartPolicy: Never
          ```

#### Hook Best Practices

1. **Use appropriate weights**: Order hooks logically (e.g., backup before migration)
2. **Set deletion policies**: Clean up hook resources to avoid clutter
3. **Add timeouts**: Use `activeDeadlineSeconds` in Job specs to prevent hanging
4. **Use backoff limits**: Set `backoffLimit` to control retry attempts
5. **Handle idempotency**: Hooks should be safe to run multiple times
6. **Consider rollback**: Avoid destructive operations in pre-delete hooks
7. **Test hooks**: Run `helm install --dry-run --debug` to preview hook behavior
8. **Use ServiceAccounts**: Grant appropriate RBAC permissions for hooks that interact with the cluster

#### Debugging Hooks

```sh
# View hook resources
kubectl get jobs,pods -n <namespace> -l heritage=Helm

# Check hook logs
kubectl logs job/<hook-job-name> -n <namespace>

# View hook status during install
helm install myapp ./chart --wait --debug

# Manually clean up failed hooks
kubectl delete job <hook-job-name> -n <namespace>
```

> Docs: [Chart Hooks](https://helm.sh/docs/topics/charts_hooks/)

---

### Helm Tests

- Helm tests live in `templates/tests/` and are pod definitions with the `"helm.sh/hook": test` annotation.
- They are executed with `helm test <release-name>`.

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "myapp.fullname" . }}-test-connection
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "myapp.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

```sh
# Run the tests
helm test my-release
```

> Docs: [Chart Tests](https://helm.sh/docs/topics/chart_tests/)

---

### NOTES.txt - Post-Install Messages

You can create a `templates/NOTES.txt` file to display useful information after a chart is installed:

```
Thank you for installing {{ .Chart.Name }}!

Your release is named: {{ .Release.Name }}

To access the application, run:
  kubectl port-forward svc/{{ include "myapp.fullname" . }} 8080:{{ .Values.service.port }}

Then open http://localhost:8080 in your browser.
```

---

# Lab

### Step 01 - Installing `Helm`

- Before you can use the `codewizard-helm-demo` chart, you'll need to **install** `Helm` on your local machine.

- `Helm` install methods by OS:

=== "Linux"

    ```bash
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```

=== "MacOS"

    ```bash
    brew install helm
    ```

=== "Windows (via Chocolatey)"

    ```bash
    choco install kubernetes-helm
    ```

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

- First, we need to create a `Helm` chart using the `helm create` command.
- This command will generate the necessary file structure for your new chart.

  ```bash
  helm create codewizard-helm-demo
  ```

??? Question "What is the result of this command?"

    - Examine the chart structure!
    - Try to explain to yourself which files are in the folder.
    - See the above reference to the structure [#](#3#chart-files-and-folders)

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

#### `helm template`

- `Helm` allows you to **generate** the Kubernetes manifests based on the templates and values files without actually installing the chart.
- This is useful to preview what the generated resources will look like:

```sh
helm template codewizard-helm-demo

## This will output the rendered Kubernetes manifests to your terminal
```

#### `helm lint`

- You can also lint the chart to check for well-formedness and best practices:

```sh
helm lint codewizard-helm-demo

## Expected output:
## ==> Linting codewizard-helm-demo
## [INFO] Chart.yaml: icon is recommended
## 1 chart(s) linted, 0 chart(s) failed
```

### Step 05 - Install the chart

- Install the `codewizard-helm-demo` chart into Kubernetes cluster

#### The `helm install` command

- This command installs a chart archive.
- The install argument must be a chart reference, a path to a packed chart, a path to an unpacked chart directory or a URL.
- To override values in a chart, use:
  - `--values` - pass in a file
  - `--set` - pass configuration from the command line
- Use `--dry-run` to simulate an install without actually deploying:

```sh
# Dry run - preview what will be installed without deploying
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz --dry-run
```

```sh
# Install the packed helm chart
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz
```

### Step 06 - Verify the installation

- Examine newly created `Helm` chart release, and all cluster created resources:

```sh
# List the installed helms
helm ls

# Show detailed status of the release
helm status codewizard-helm-demo

# Get the rendered manifests of the release
helm get manifest codewizard-helm-demo

# Get the values used by the release
helm get values codewizard-helm-demo

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

- You can also test the release name and revision endpoints defined in the ConfigMap:

```sh
# Get the release name
kubectl run busybox --image=busybox --rm -it --restart=Never \
  -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local/release/name"

# Get the release revision
kubectl run busybox --image=busybox --rm -it --restart=Never \
  -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local/release/revision"
```

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

- Also check the revision number - it should now be `2`:

```sh
kubectl run busybox --image=busybox --rm -it --restart=Never \
  -- /bin/sh -c "wget -qO- http://codewizard-helm-demo.codewizard.svc.cluster.local/release/revision"

### Output:
2
```

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

# Exercises

The following exercises will test your understanding of `Helm` concepts.
Try to solve each exercise on your own before revealing the solution.

---

#### 01. Explore a Public Chart Repository

Add the Bitnami chart repository and search for an `nginx` chart.

#### Scenario:

◦ You need to find and inspect a publicly available Helm chart before installing it.
◦ Chart repositories are the standard way to discover and share Helm charts.

**Hint:** Use `helm repo add`, `helm repo update`, and `helm search repo`.

<details>
<summary>Solution</summary>

```bash
# Add the Bitnami chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update the repository index
helm repo update

# Search for nginx charts
helm search repo nginx

# Show the default values of the bitnami nginx chart
helm show values bitnami/nginx | head -50
```

</details>

---

#### 02. Install with Custom Values File

Create a custom `values.yaml` file that changes the `replicaCount` to `3` and the message to `"Hello from custom values"`, then install the chart using this file.

#### Scenario:

◦ In production environments, you rarely use default values.
◦ Custom values files let you manage environment-specific configurations (dev, staging, prod).

**Hint:** Create a YAML file and use `helm install -f <file>`.

<details>
<summary>Solution</summary>

```bash
# Create a custom values file
cat <<EOF > custom-values.yaml
replicaCount: 3
nginx:
  conf:
    message: "Hello from custom values"
EOF

# Install with the custom values file
helm install custom-demo codewizard-helm-demo-0.1.0.tgz -f custom-values.yaml

# Verify the replica count
kubectl get deployment -n codewizard

# Verify the message
kubectl run busybox --image=busybox --rm -it --restart=Never \
  -- /bin/sh -c "wget -qO- http://custom-demo.codewizard.svc.cluster.local"

# Cleanup
helm uninstall custom-demo
rm custom-values.yaml
```

</details>

---

#### 03. Debug a Failing Template

Given the following broken template snippet, identify and fix the error.
Save this as `templates/broken.yaml` in the chart, then use `helm template` to find the issue:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.brokenName }
data:
  key: {{ .Values.missingValue | default "fallback" }}
```

#### Scenario:

◦ Template syntax errors are common during chart development.
◦ `helm template` and `helm lint` are your best debugging tools.

**Hint:** Use `helm template` and `helm lint` to identify the error. Count the curly braces.

<details>
<summary>Solution</summary>

The error is a missing closing brace on line 4: `{{ .Values.brokenName }` should be `{{ .Values.brokenName }}`.

```bash
# Lint the chart to find errors
helm lint codewizard-helm-demo

# Try to render the template - this will show the error
helm template codewizard-helm-demo

# Fix: the correct line should be:
#   name: {{ .Values.brokenName }}
# (two closing braces instead of one)

# Don't forget to remove the broken test file
rm codewizard-helm-demo/templates/broken.yaml
```

</details>

---

#### 04. Use `--set` to Override Multiple Values

Upgrade the `codewizard-helm-demo` release to use `3` replicas, image tag `1.21.0`, and the message `"Multi-set Override"` - all in a single command.

#### Scenario:

◦ Quick overrides using `--set` are common for CI/CD pipelines and ad-hoc changes.
◦ You need to understand the dot-notation for nested values.

**Hint:** Chain multiple `--set` flags or use comma-separated notation.

<details>
<summary>Solution</summary>

```bash
# Method 1: multiple --set flags
helm upgrade codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz \
  --set replicaCount=3 \
  --set image.tag="1.21.0" \
  --set nginx.conf.message="Multi-set Override"

# Method 2: comma-separated (equivalent)
helm upgrade codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz \
  --set replicaCount=3,image.tag=1.21.0,nginx.conf.message="Multi-set Override"

# Verify the values
helm get values codewizard-helm-demo

# Verify replicas and image
kubectl get deployment -n codewizard -o wide
```

</details>

---

#### 05. Add a Conditional Resource

Modify the `codewizard-helm-demo` chart to add an optional `Ingress` resource that is only created when `ingress.enabled` is set to `true` in `values.yaml`.

#### Scenario:

◦ Not all environments need an Ingress (e.g., local development vs. production).
◦ Conditional rendering with `if` blocks is a fundamental Helm templating pattern.

**Hint:** Use `{{- if .Values.ingress.enabled }}` ... `{{- end }}`. Add `ingress.enabled: false` to `values.yaml`.

<details>
<summary>Solution</summary>

```bash
# 1. Add ingress values to values.yaml
cat <<EOF >> codewizard-helm-demo/values.yaml

ingress:
  enabled: false
  host: demo.example.com
EOF
```

```yaml
# 2. Create templates/Ingress.yaml
# Save this as codewizard-helm-demo/templates/Ingress.yaml:
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "webserver.fullname" . }}
  namespace: codewizard
  labels:
    {{- include "webserver.labels" . | nindent 4 }}
spec:
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "webserver.fullname" . }}
                port:
                  number: {{ .Values.service.port }}
{{- end }}
```

```bash
# 3. Verify: template without ingress (should NOT include Ingress resource)
helm template codewizard-helm-demo | grep -A5 "kind: Ingress"

# 4. Verify: template WITH ingress enabled (should include Ingress resource)
helm template codewizard-helm-demo --set ingress.enabled=true | grep -A20 "kind: Ingress"

# 5. Cleanup - remove the ingress template
rm codewizard-helm-demo/templates/Ingress.yaml
```

</details>

---

#### 06. Add a Named Template

Create a new named template in `_helpers.tpl` called `webserver.annotations` that generates a set of annotations including the chart version and a custom `team` annotation from values. Then use it in the Deployment.

#### Scenario:

◦ Named templates reduce duplication across manifests.
◦ Annotations are commonly used for metadata, monitoring, and CI/CD integration.

**Hint:** Use `{{- define "webserver.annotations" -}}` to define and `{{ include "webserver.annotations" . | nindent N }}` to use it.

<details>
<summary>Solution</summary>

```yaml
# 1. Add to _helpers.tpl:
{{/*
Common annotations
*/}}
{{- define "webserver.annotations" -}}
app.kubernetes.io/chart: {{ include "webserver.chart" . }}
app.kubernetes.io/team: {{ .Values.team | default "platform" }}
{{- end }}
```

```yaml
# 2. Use in Deployment.yaml metadata:
metadata:
  name: { { include "webserver.fullname" . } }
  namespace: codewizard
  annotations: { { - include "webserver.annotations" . | nindent 4 } }
  labels: { { - include "webserver.labels" . | nindent 4 } }
```

```bash
# 3. Verify the rendered output
helm template codewizard-helm-demo --set team="devops" | grep -A5 "annotations"
```

</details>

---

#### 07. Use `range` to Generate Multiple Environment Variables

Modify the Deployment template to inject a list of environment variables from `values.yaml` using the `range` function.

#### Scenario:

◦ Real-world deployments often require multiple environment variables.
◦ Hardcoding them in templates is not maintainable - values-driven configuration is preferred.

**Hint:** Add an `env` list to `values.yaml` and use `{{- range .Values.env }}` in the container spec.

<details>
<summary>Solution</summary>

```yaml
# 1. Add to values.yaml:
env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
  - name: APP_VERSION
    value: "1.0.0"
```

```yaml
# 2. Add to templates/Deployment.yaml inside the container spec (after imagePullPolicy):
          env:
          {{- range .Values.env }}
            - name: {{ .name }}
              value: {{ .value | quote }}
          {{- end }}
```

```bash
# 3. Verify rendered output
helm template codewizard-helm-demo | grep -A15 "env:"

# 4. Override from command line
helm template codewizard-helm-demo \
  --set "env[0].name=CUSTOM_VAR" \
  --set "env[0].value=custom-value" | grep -A5 "env:"
```

</details>

---

#### 08. Create a Helm Test

Add a Helm test to the `codewizard-helm-demo` chart that verifies the service is reachable and returns the expected message.

#### Scenario:

◦ Helm tests allow you to validate that a release is working correctly after deployment.
◦ Tests are pod definitions with the `"helm.sh/hook": test` annotation.

**Hint:** Create a file in `templates/tests/` with a `busybox` pod that runs `wget` against the service.

<details>
<summary>Solution</summary>

```bash
# 1. Create the tests directory
mkdir -p codewizard-helm-demo/templates/tests
```

```yaml
# 2. Create templates/tests/test-connection.yaml:
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "webserver.fullname" . }}-test-connection
  namespace: codewizard
  labels:
    {{- include "webserver.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['sh', '-c']
      args:
        - |
          RESPONSE=$(wget -qO- http://{{ include "webserver.fullname" . }}.codewizard.svc.cluster.local)
          echo "Response: $RESPONSE"
          echo "$RESPONSE" | grep -q "{{ .Values.nginx.conf.message }}"
  restartPolicy: Never
```

```bash
# 3. Install or upgrade the chart
helm upgrade --install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz

# 4. Run the test
helm test codewizard-helm-demo

# Expected output:
# NAME: codewizard-helm-demo
# ...
# Phase: Succeeded
```

</details>

---

#### 09. Manage Chart Dependencies

Create a new `Helm` chart that depends on the `bitnami/redis` chart as a subchart. Configure the dependency and update it.

#### Scenario:

◦ Most real-world applications depend on databases, caches, or message queues.
◦ Helm dependencies let you compose complex deployments from reusable charts.

**Hint:** Add a `dependencies` section to `Chart.yaml`, then run `helm dependency update`.

<details>
<summary>Solution</summary>

```bash
# 1. Create a new chart
helm create myapp-with-deps
cd myapp-with-deps
```

```yaml
# 2. Add dependencies to Chart.yaml (append at the end):
dependencies:
  - name: redis
    version: "~17"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

```yaml
# 3. Add Redis configuration to values.yaml:
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false
```

```bash
# 4. Add the Bitnami repo (if not already added)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 5. Download the dependency charts
helm dependency update .

# 6. Verify the dependency was downloaded
ls charts/

# 7. Preview the rendered output (Redis resources will be included)
helm template myapp-with-deps . | grep "kind:" | sort | uniq

# 8. Cleanup
cd ..
rm -rf myapp-with-deps
```

</details>

---

#### 10. Create a Pre-Install Hook

Add a `pre-install` hook to the `codewizard-helm-demo` chart that creates a Job to print a banner message before the main resources are installed.

#### Scenario:

◦ Hooks allow you to run setup, migration, or validation tasks at specific lifecycle points.
◦ `pre-install` hooks run before the main chart resources are created.

**Hint:** Create a `Job` manifest with the annotation `"helm.sh/hook": pre-install` and `"helm.sh/hook-delete-policy": hook-succeeded`.

<details>
<summary>Solution</summary>

```yaml
# Create templates/pre-install-hook.yaml:
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "webserver.fullname" . }}-pre-install
  namespace: codewizard
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
        - name: pre-install
          image: busybox
          command: ['sh', '-c', 'echo "=== Installing {{ .Release.Name }} (Chart: {{ .Chart.Name }}-{{ .Chart.Version }}) ==="']
      restartPolicy: Never
  backoffLimit: 1
```

```bash
# Install and observe the hook
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz

# The Job should run and complete before the main resources are created
# Check the jobs (it may already be cleaned up due to hook-delete-policy)
kubectl get jobs -n codewizard

# Cleanup
helm uninstall codewizard-helm-demo
rm codewizard-helm-demo/templates/pre-install-hook.yaml
```

</details>

---

#### 11. Diff Before Upgrade

Use the `helm-diff` plugin to preview what changes an upgrade will make before applying it.

#### Scenario:

◦ In production, blindly upgrading without reviewing changes is risky.
◦ The `helm-diff` plugin shows a diff of what would change, similar to `kubectl diff`.

**Hint:** Install the plugin with `helm plugin install`, then use `helm diff upgrade`.

<details>
<summary>Solution</summary>

```bash
# 1. Install the helm-diff plugin
helm plugin install https://github.com/databus23/helm-diff

# 2. Make sure the release is installed
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz

# 3. Preview what an upgrade would change (without applying)
helm diff upgrade codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz \
  --set nginx.conf.message="Updated Message" \
  --set replicaCount=5

# The output shows colorized diff of what resources would change

# 4. If you're satisfied, apply the upgrade
helm upgrade codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz \
  --set nginx.conf.message="Updated Message" \
  --set replicaCount=5

# Cleanup
helm uninstall codewizard-helm-demo
```

</details>

---

#### 12. Create a NOTES.txt

Add a `NOTES.txt` file to the `codewizard-helm-demo` chart that displays the release name, namespace, and instructions for testing the service after installation.

#### Scenario:

◦ `NOTES.txt` provides post-install guidance to users who install your chart.
◦ It supports the same Go template syntax as other template files.

**Hint:** Create `templates/NOTES.txt` with template directives like `{{ .Release.Name }}`.

<details>
<summary>Solution</summary>

```
# Create templates/NOTES.txt with the following content:

==================================================
  {{ .Chart.Name }} has been installed!
==================================================

Release Name : {{ .Release.Name }}
Namespace    : codewizard
Revision     : {{ .Release.Revision }}
Chart Version: {{ .Chart.Version }}
App Version  : {{ .Chart.AppVersion }}

To test the service, run:

  kubectl run busybox --image=busybox --rm -it --restart=Never \
    -- /bin/sh -c "wget -qO- http://{{ include "webserver.fullname" . }}.codewizard.svc.cluster.local"

To check release status:

  helm status {{ .Release.Name }}

To uninstall:

  helm uninstall {{ .Release.Name }}
```

```bash
# Install and verify the NOTES are displayed
helm install codewizard-helm-demo codewizard-helm-demo-0.1.0.tgz

# The NOTES should be displayed after installation
# You can also view them again with:
helm status codewizard-helm-demo

# Cleanup
helm uninstall codewizard-helm-demo
```

</details>

---

## Finalize & Cleanup

- To remove all resources created by this lab, uninstall the `codewizard-helm-demo` release:

```sh
helm uninstall codewizard-helm-demo
```

- (Optional) If you have created a dedicated namespace for this lab, you can delete it by running:

```sh
kubectl delete namespace codewizard
```

- (Optional) Remove added Helm repositories:

```sh
helm repo remove bitnami
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

<br>

- **Template rendering errors:**

Use `helm template` and `helm lint` to find and debug template issues:

```sh
helm template codewizard-helm-demo
helm lint codewizard-helm-demo
```

<br>

- **Hook failures:**

Inspect hook resources (Jobs, Pods) to check their status and logs:

```sh
kubectl get jobs -n codewizard
kubectl logs job/<job-name> -n codewizard
```

---

## Next Steps

- Try creating your own `Helm` chart for a different application.
- Explore `Helm` chart repositories like [Artifact Hub](https://artifacthub.io/).
- Learn about advanced `Helm` features, such as: dependencies, hooks, and chart testing.
- Explore [Helmfile](https://github.com/helmfile/helmfile) for declarative management of multiple Helm releases.
- Learn about [Helm Secrets](https://github.com/jkroepke/helm-secrets) for managing sensitive data in charts.
````

