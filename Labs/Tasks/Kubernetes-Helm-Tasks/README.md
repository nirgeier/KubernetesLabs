# Kubernetes Helm Chart Tasks

- Hands-on Kubernetes exercises covering Helm chart creation, packaging, deployment, and best practices.
- Each task includes a description, scenario, and a detailed solution with step-by-step instructions.
- Practice these tasks to master Helm from basic chart scaffolding to advanced templating and chart repositories.

#### Table of Contents

- [01. Scaffold a Helm Chart](#01-scaffold-a-helm-chart)
- [02. Explore the Chart Structure](#02-explore-the-chart-structure)
- [03. Deploy an Nginx-Based Chart](#03-deploy-an-nginx-based-chart)
- [04. Customize the Welcome Page with Current Date & Time](#04-customize-the-welcome-page-with-current-date--time)
- [05. Add a Service](#05-add-a-service)
- [06. Add Two Ingress Resources with Different Paths](#06-add-two-ingress-resources-with-different-paths)
- [07. Add an ExternalName Service](#07-add-an-externalname-service)
- [08. Values Overrides and Environments](#08-values-overrides-and-environments)
- [09. Template Helpers and Named Templates](#09-template-helpers-and-named-templates)
- [10. Template Control Flow (if / range / with)](#10-template-control-flow-if--range--with)
- [11. Chart Dependencies (Subcharts)](#11-chart-dependencies-subcharts)
- [12. Linting, Dry-Run, and Debugging](#12-linting-dry-run-and-debugging)
- [13. Package and Host a Chart Repository](#13-package-and-host-a-chart-repository)
- [14. Upgrade, Rollback, and Release History](#14-upgrade-rollback-and-release-history)
- [15. Hooks (Pre-install / Post-install)](#15-hooks-pre-install--post-install)
- [16. Use `helm status` to Inspect a Release](#16-use-helm-status-to-inspect-a-release)
- [17. Extract Values with `helm get values`](#17-extract-values-with-helm-get-values)
- [18. Show Chart Values with `helm show values`](#18-show-chart-values-with-helm-show-values)
- [19. Search Charts with `helm search repo`](#19-search-charts-with-helm-search-repo)
- [20. Update Repositories with `helm repo update`](#20-update-repositories-with-helm-repo-update)
- [21. Run Chart Tests with `helm test`](#21-run-chart-tests-with-helm-test)
- [22. Use `helm get all` to Retrieve Complete Release Info](#22-use-helm-get-all-to-retrieve-complete-release-info)
- [23. Use `helm list` with Filters and Formatting](#23-use-helm-list-with-filters-and-formatting)
- [24. Chain Multiple Commands for Release Management](#24-chain-multiple-commands-for-release-management)

---

#### 01. Scaffold a Helm Chart

Create a new Helm chart from scratch using `helm create` and explore the generated files.

#### Scenario:

  ◦ You need to package an application for Kubernetes and want a standardized project structure.
  ◦ `helm create` generates a best-practice skeleton you can customize.

**Hint:** `helm create`, `tree`

??? example "Solution"

    ```bash
    # 1. Create a new chart named "my-nginx-app"
    helm create my-nginx-app

    # 2. Explore the generated structure
    tree my-nginx-app/

    # Output:
    # my-nginx-app/
    # ├── Chart.yaml          # Chart metadata (name, version, description)
    # ├── values.yaml         # Default configuration values
    # ├── charts/             # Dependency charts (subcharts)
    # ├── templates/          # Kubernetes manifest templates
    # │   ├── NOTES.txt       # Post-install usage notes
    # │   ├── _helpers.tpl    # Named template definitions
    # │   ├── deployment.yaml
    # │   ├── hpa.yaml
    # │   ├── ingress.yaml
    # │   ├── service.yaml
    # │   ├── serviceaccount.yaml
    # │   └── tests/
    # │       └── test-connection.yaml
    # └── .helmignore         # Files to exclude when packaging
    ```

---

#### 02. Explore the Chart Structure

Inspect `Chart.yaml` and `values.yaml` to understand how Helm charts are configured.

#### Scenario:
  ◦ Before modifying a chart, you need to understand what each file does.
  ◦ `Chart.yaml` defines the chart identity; `values.yaml` drives all the template rendering.

**Hint:** `cat Chart.yaml`, `cat values.yaml`

??? example "Solution"

    ```bash
    # 1. Inspect Chart.yaml
    cat my-nginx-app/Chart.yaml

    # Key fields:
    # - apiVersion: v2       (Helm 3 chart)
    # - name: my-nginx-app
    # - version: 0.1.0       (chart version — bump this on changes)
    # - appVersion: "1.16.0" (the app version being deployed)

    # 2. Inspect values.yaml
    cat my-nginx-app/values.yaml

    # Key fields:
    # - replicaCount: 1
    # - image.repository: nginx
    # - image.tag: ""        (defaults to appVersion from Chart.yaml)
    # - service.type: ClusterIP
    # - service.port: 80
    # - ingress.enabled: false

    # 3. See how values are consumed in templates
    grep -n '{{ .Values' my-nginx-app/templates/deployment.yaml

    # 4. Render the templates without deploying (dry-run)
    helm template my-release my-nginx-app/
    ```

---

#### 03. Deploy an Nginx-Based Chart

Install the chart to your cluster using the default nginx image, verify the deployment, and access nginx.

#### Scenario:
  ◦ You want to deploy a basic nginx web server using Helm to validate the chart works before customizing it.

**Hint:** `helm install`, `kubectl get all`, `kubectl port-forward`

??? example "Solution"

    ```bash
    # 1. Install the chart
    helm install my-nginx my-nginx-app/

    # 2. Verify all resources were created
    kubectl get all -l app.kubernetes.io/instance=my-nginx

    # 3. Check the release
    helm list

    # 4. Access the application via port-forward
    kubectl port-forward svc/my-nginx-my-nginx-app 8080:80

    # 5. In another terminal or browser
    curl http://localhost:8080
    # Should show the default nginx welcome page

    # 6. Uninstall when done
    helm uninstall my-nginx
    ```

---

#### 04. Customize the Welcome Page with Current Date & Time

Create a ConfigMap that generates a custom HTML welcome page showing the current date and time, and mount it into the nginx container.

#### Scenario:
  ◦ You want to display dynamic content (deployment timestamp) on the nginx welcome page.
  ◦ This demonstrates how Helm templates can inject build-time values into application configuration.

**Hint:** `now`, `date`, ConfigMap volume mount, `{{ .Release }}`

??? example "Solution"

    #### Step 1: Create the ConfigMap template [templates/configmap-html.yaml]

    ```bash
    cat > my-nginx-app/templates/configmap-html.yaml << 'TEMPLATE'
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-html
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
    data:
      index.html: |
        <!DOCTYPE html>
        <html>
        <head>
          <title>{{ .Values.welcomePage.title | default "Welcome" }}</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              margin: 0;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white;
            }
            .container { text-align: center; }
            h1 { font-size: 2.5em; }
            .info { font-size: 1.2em; margin: 10px 0; }
            .time { font-size: 3em; font-weight: bold; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>{{ .Values.welcomePage.title | default "Welcome to My Nginx App" }}</h1>
            <p class="info">Release: <strong>{{ .Release.Name }}</strong></p>
            <p class="info">Namespace: <strong>{{ .Release.Namespace }}</strong></p>
            <p class="info">Chart Version: <strong>{{ .Chart.Version }}</strong></p>
            <p class="info">App Version: <strong>{{ .Chart.AppVersion }}</strong></p>
            <p class="time">Deployed at: {{ now | date "2006-01-02 15:04:05 MST" }}</p>
            {{- if .Values.welcomePage.message }}
            <p class="info">{{ .Values.welcomePage.message }}</p>
            {{- end }}
          </div>
        </body>
        </html>
    TEMPLATE
    ```

    #### Step 2: Add welcome page values to `values.yaml`

    ```bash
    cat >> my-nginx-app/values.yaml << 'EOF'

    # Custom welcome page configuration
    welcomePage:
      title: "Welcome to My Nginx App"
      message: "Deployed with Helm!"
    EOF
    ```

    #### Step 3: Update the deployment template to mount the ConfigMap

    Edit `my-nginx-app/templates/deployment.yaml` — add the `volumeMounts` and `volumes`:

    ```bash
    # Add volumeMounts under the container spec and volumes under the pod spec.
    # The easiest approach: replace the deployment template entirely.
    # Here we patch the key sections:

    # In the container spec, add:
    #   volumeMounts:
    #     - name: html-volume
    #       mountPath: /usr/share/nginx/html
    #       readOnly: true

    # In the pod spec (same level as containers), add:
    #   volumes:
    #     - name: html-volume
    #       configMap:
    #         name: {{ include "my-nginx-app.fullname" . }}-html
    ```

    For a quick approach, replace the entire deployment template:

    ```bash
    cat > my-nginx-app/templates/deployment.yaml << 'TEMPLATE'
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
    spec:
      {{- if not .Values.autoscaling.enabled }}
      replicas: {{ .Values.replicaCount }}
      {{- end }}
      selector:
        matchLabels:
          {{- include "my-nginx-app.selectorLabels" . | nindent 6 }}
      template:
        metadata:
          annotations:
            # Force pod restart on ConfigMap changes
            checksum/html: {{ include (print $.Template.BasePath "/configmap-html.yaml") . | sha256sum }}
          {{- with .Values.podAnnotations }}
            {{- toYaml . | nindent 8 }}
          {{- end }}
          labels:
            {{- include "my-nginx-app.labels" . | nindent 8 }}
            {{- with .Values.podLabels }}
            {{- toYaml . | nindent 8 }}
            {{- end }}
        spec:
          {{- with .Values.imagePullSecrets }}
          imagePullSecrets:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          serviceAccountName: {{ include "my-nginx-app.serviceAccountName" . }}
          {{- with .Values.podSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          containers:
            - name: {{ .Chart.Name }}
              {{- with .Values.securityContext }}
              securityContext:
                {{- toYaml . | nindent 12 }}
              {{- end }}
              image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
              imagePullPolicy: {{ .Values.image.pullPolicy }}
              ports:
                - name: http
                  containerPort: {{ .Values.service.port }}
                  protocol: TCP
              livenessProbe:
                {{- toYaml .Values.livenessProbe | nindent 12 }}
              readinessProbe:
                {{- toYaml .Values.readinessProbe | nindent 12 }}
              {{- with .Values.resources }}
              resources:
                {{- toYaml . | nindent 12 }}
              {{- end }}
              volumeMounts:
                - name: html-volume
                  mountPath: /usr/share/nginx/html
                  readOnly: true
                {{- with .Values.volumeMounts }}
                {{- toYaml . | nindent 12 }}
                {{- end }}
          volumes:
            - name: html-volume
              configMap:
                name: {{ include "my-nginx-app.fullname" . }}-html
            {{- with .Values.volumes }}
            {{- toYaml . | nindent 8 }}
            {{- end }}
          {{- with .Values.nodeSelector }}
          nodeSelector:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          {{- with .Values.affinity }}
          affinity:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          {{- with .Values.tolerations }}
          tolerations:
            {{- toYaml . | nindent 8 }}
          {{- end }}
    TEMPLATE
    ```

    #### Step 4: Install and verify

    ```bash
    # Install (or upgrade if already installed)
    helm upgrade --install my-nginx my-nginx-app/

    # Port-forward and check the custom page
    kubectl port-forward svc/my-nginx-my-nginx-app 8080:80

    # In another terminal
    curl http://localhost:8080
    # Should show the custom HTML page with current date/time and release info
    ```

---

#### 05. Add a Service

Verify the Service template supports ClusterIP, NodePort, and LoadBalancer types via `values.yaml`.

#### Scenario:

  ◦ You want to expose your application with different service types depending on the environment (e.g., ClusterIP for dev, NodePort for minikube, LoadBalancer for cloud).
  ◦ You need your chart to be flexible enough to deploy with different service types depending on the environment.
  ◦ The default `helm create` already includes a service template — you need to understand and test it.

**Hint:** `--set service.type=NodePort`, `helm upgrade`

??? example "Solution"

    ```bash
    # 1. Check the current service template
    cat my-nginx-app/templates/service.yaml

    # 2. The default template already supports configurable type:
    #    type: {{ .Values.service.type }}
    #    port: {{ .Values.service.port }}

    # 3. Install with ClusterIP (default)
    helm upgrade --install my-nginx my-nginx-app/

    # 4. Verify
    kubectl get svc -l app.kubernetes.io/instance=my-nginx
    # TYPE should be ClusterIP

    # 5. Upgrade to NodePort
    helm upgrade my-nginx my-nginx-app/ --set service.type=NodePort

    # 6. Verify
    kubectl get svc -l app.kubernetes.io/instance=my-nginx
    # TYPE should now be NodePort

    # 7. Upgrade to LoadBalancer
    helm upgrade my-nginx my-nginx-app/ --set service.type=LoadBalancer

    # 8. Verify
    kubectl get svc -l app.kubernetes.io/instance=my-nginx
    # TYPE should now be LoadBalancer (EXTERNAL-IP may stay <pending> on local clusters)
    ```

---

#### 06. Add Two Ingress Resources with Different Paths

Create two Ingress resources: one serving the main app at `/` and another serving a health/status endpoint at `/status`.

#### Scenario:
  ◦ Your application has a main frontend and a separate status/health page.
  ◦ You want to route traffic using different URL paths to the same backend, each with its own Ingress resource.
  ◦ This is useful when different Ingress resources need different annotations (rate limiting, auth, etc.).

**Prerequisites:** An Ingress controller must be installed (e.g., `nginx-ingress`).

**Hint:** Two separate Ingress templates, `pathType: Prefix`

??? example "Solution"

    **Step 1:** Create the main Ingress template [templates/ingress-main.yaml]

    ```bash
    cat > my-nginx-app/templates/ingress-main.yaml << 'TEMPLATE'
    {{- if .Values.ingress.main.enabled -}}
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-main
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
      {{- with .Values.ingress.main.annotations }}
      annotations:
        {{- toYaml . | nindent 4 }}
      {{- end }}
    spec:
      {{- if .Values.ingress.main.className }}
      ingressClassName: {{ .Values.ingress.main.className }}
      {{- end }}
      rules:
        - host: {{ .Values.ingress.main.host | quote }}
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: {{ include "my-nginx-app.fullname" . }}
                    port:
                      number: {{ .Values.service.port }}
      {{- if .Values.ingress.main.tls }}
      tls:
        {{- toYaml .Values.ingress.main.tls | nindent 4 }}
      {{- end }}
    {{- end }}
    TEMPLATE
    ```

    **Step 2:** Create the status Ingress template [templates/ingress-status.yaml]

    ```bash
    cat > my-nginx-app/templates/ingress-status.yaml << 'TEMPLATE'
    {{- if .Values.ingress.status.enabled -}}
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-status
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
      {{- with .Values.ingress.status.annotations }}
      annotations:
        {{- toYaml . | nindent 4 }}
      {{- end }}
    spec:
      {{- if .Values.ingress.status.className }}
      ingressClassName: {{ .Values.ingress.status.className }}
      {{- end }}
      rules:
        - host: {{ .Values.ingress.status.host | quote }}
          http:
            paths:
              - path: /status
                pathType: Prefix
                backend:
                  service:
                    name: {{ include "my-nginx-app.fullname" . }}
                    port:
                      number: {{ .Values.service.port }}
      {{- if .Values.ingress.status.tls }}
      tls:
        {{- toYaml .Values.ingress.status.tls | nindent 4 }}
      {{- end }}
    {{- end }}
    TEMPLATE
    ```

    **Step 3:** Remove the default ingress template (optional) and update `values.yaml`

    ```bash
    # Remove the default generated ingress template to avoid confusion
    rm my-nginx-app/templates/ingress.yaml

    # Add ingress values to values.yaml
    cat >> my-nginx-app/values.yaml << 'EOF'

    # Ingress configuration — two separate Ingress resources
    ingress:
      main:
        enabled: true
        className: nginx
        host: my-nginx.local
        annotations:
          nginx.ingress.kubernetes.io/rewrite-target: /
        tls: []
      status:
        enabled: true
        className: nginx
        host: my-nginx.local
        annotations:
          nginx.ingress.kubernetes.io/rewrite-target: /
          # Example: different rate limit for status endpoint
          nginx.ingress.kubernetes.io/limit-rps: "10"
        tls: []
    EOF
    ```

    **Step 4:** Deploy and verify

    ```bash
    # Upgrade the release
    helm upgrade --install my-nginx my-nginx-app/

    # Verify both Ingress resources were created
    kubectl get ingress -l app.kubernetes.io/instance=my-nginx

    # Expected output:
    # NAME                        CLASS   HOSTS            ADDRESS   PORTS   AGE
    # my-nginx-my-nginx-app-main    nginx   my-nginx.local             80      5s
    # my-nginx-my-nginx-app-status  nginx   my-nginx.local             80      5s

    # Describe each to see the path rules
    kubectl describe ingress my-nginx-my-nginx-app-main
    kubectl describe ingress my-nginx-my-nginx-app-status

    # Test (add host entry or use curl with Host header)
    # curl -H "Host: my-nginx.local" http://<INGRESS_IP>/
    # curl -H "Host: my-nginx.local" http://<INGRESS_IP>/status
    ```

---

#### 07. Add an ExternalName Service

Add a second Service of type `ExternalName` that maps a Kubernetes service name to an external DNS name.

#### Scenario:
  ◦ Your application needs to connect to an external API or database (e.g., an RDS instance, a SaaS endpoint).
  ◦ By using an ExternalName service, you can refer to it by a local name inside the cluster and change the target later without modifying application code.

**Hint:** `type: ExternalName`, `externalName`

??? example "Solution"

    **Step 1:** Create the ExternalName Service template [templates/service-external.yaml]

    ```bash
    cat > my-nginx-app/templates/service-external.yaml << 'TEMPLATE'
    {{- if .Values.externalService.enabled -}}
    apiVersion: v1
    kind: Service
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-external
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
    spec:
      type: ExternalName
      externalName: {{ .Values.externalService.host | quote }}
      {{- if .Values.externalService.ports }}
      ports:
        {{- toYaml .Values.externalService.ports | nindent 4 }}
      {{- end }}
    {{- end }}
    TEMPLATE
    ```

    **Step 2:** Add values to `values.yaml`

    ```bash
    cat >> my-nginx-app/values.yaml << 'EOF'

    # ExternalName service — maps a local name to an external DNS
    externalService:
      enabled: true
      host: api.example.com
      ports:
        - port: 443
          protocol: TCP
    EOF
    ```

    **Step 3:** Deploy and verify

    ```bash
    # Upgrade the release
    helm upgrade --install my-nginx my-nginx-app/

    # Verify the ExternalName service
    kubectl get svc -l app.kubernetes.io/instance=my-nginx

    # Should show something like:
    # NAME                              TYPE           CLUSTER-IP   EXTERNAL-IP       PORT(S)
    # my-nginx-my-nginx-app             ClusterIP      10.x.x.x    <none>            80/TCP
    # my-nginx-my-nginx-app-external    ExternalName   <none>       api.example.com   443/TCP

    # Test DNS resolution from inside the cluster
    kubectl run dns-check --image=busybox --restart=Never \
      -- nslookup my-nginx-my-nginx-app-external
    kubectl logs dns-check
    # Should resolve to api.example.com

    # Cleanup test pod
    kubectl delete pod dns-check
    ```

---

#### 08. Values Overrides and Environments

Use multiple values files to manage different environments (dev, staging, production).

#### Scenario:
  ◦ You have one chart but need different configurations per environment (replica count, image tag, resource limits).
  ◦ Helm supports layering multiple `-f` values files and `--set` overrides.

**Hint:** `helm install -f`, `--set`, multiple values files

??? example "Solution"

    ```bash
    # 1. Create a dev values file
    cat > values-dev.yaml << 'EOF'
    replicaCount: 1
    image:
      tag: "alpine"
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
    welcomePage:
      title: "DEV Environment"
      message: "This is the development instance"
    EOF

    # 2. Create a production values file
    cat > values-prod.yaml << 'EOF'
    replicaCount: 3
    image:
      tag: "stable"
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
    welcomePage:
      title: "PRODUCTION"
      message: "Production instance — handle with care"
    service:
      type: LoadBalancer
    EOF

    # 3. Install with dev values
    helm upgrade --install my-nginx-dev my-nginx-app/ \
      -f values-dev.yaml \
      --namespace dev --create-namespace

    # 4. Install with prod values
    helm upgrade --install my-nginx-prod my-nginx-app/ \
      -f values-prod.yaml \
      --namespace prod --create-namespace

    # 5. Verify different configurations
    kubectl get deployment -n dev -o wide
    kubectl get deployment -n prod -o wide

    # 6. Override a single value on top of a values file
    helm upgrade my-nginx-dev my-nginx-app/ \
      -f values-dev.yaml \
      --set replicaCount=2 \
      --namespace dev

    # Cleanup
    helm uninstall my-nginx-dev -n dev
    helm uninstall my-nginx-prod -n prod
    kubectl delete ns dev prod
    ```

---

#### 09. Template Helpers and Named Templates

Create a custom named template in `_helpers.tpl` and use it across multiple templates.

#### Scenario:
  ◦ You have repeated logic (e.g., generating labels, resource names) across templates.
  ◦ Named templates (partials) in `_helpers.tpl` let you define reusable snippets.

**Hint:** `define`, `include`, `_helpers.tpl`

??? example "Solution"

    ```bash
    # 1. Inspect existing helpers
    cat my-nginx-app/templates/_helpers.tpl

    # You'll see templates like:
    # {{- define "my-nginx-app.name" -}}         → Chart name
    # {{- define "my-nginx-app.fullname" -}}     → Release-qualified name
    # {{- define "my-nginx-app.labels" -}}       → Standard labels
    # {{- define "my-nginx-app.selectorLabels" -}} → Selector labels

    # 2. Add a custom helper — e.g., environment label
    cat >> my-nginx-app/templates/_helpers.tpl << 'EOF'

    {{/*
    Custom: Generate environment-specific annotations
    */}}
    {{- define "my-nginx-app.envAnnotations" -}}
    app.kubernetes.io/environment: {{ .Values.environment | default "dev" }}
    app.kubernetes.io/team: {{ .Values.team | default "platform" }}
    {{- end }}
    EOF

    # 3. Use it in a template (e.g., deployment.yaml metadata.annotations):
    #   annotations:
    #     {{- include "my-nginx-app.envAnnotations" . | nindent 4 }}

    # 4. Add default values
    cat >> my-nginx-app/values.yaml << 'EOF'

    # Environment metadata
    environment: dev
    team: platform
    EOF

    # 5. Test rendering
    helm template my-nginx my-nginx-app/ | grep -A2 "environment"
    ```

---

#### 10. Template Control Flow (if / range / with)

Practice Helm template control structures: conditionals, loops, and scoping.

#### Scenario:
  ◦ You need to conditionally render resources, iterate over lists, or scope into nested values.
  ◦ Go template control flow is essential for writing flexible Helm charts.

**Hint:** `{{- if }}`, `{{- range }}`, `{{- with }}`

??? example "Solution"

    ```bash
    # 1. Conditional: only create a resource if enabled
    # Already used in ingress templates:
    #   {{- if .Values.ingress.main.enabled -}}
    #   ...
    #   {{- end }}

    # 2. Range: iterate over a list
    # Example: Add multiple environment variables from a values list
    # In values.yaml:
    cat >> my-nginx-app/values.yaml << 'EOF'

    # Extra environment variables
    extraEnv:
      - name: LOG_LEVEL
        value: "info"
      - name: APP_MODE
        value: "production"
    EOF

    # In deployment.yaml, under containers[].env:
    #   {{- range .Values.extraEnv }}
    #   - name: {{ .name }}
    #     value: {{ .value | quote }}
    #   {{- end }}

    # 3. With: scope into a map
    # {{- with .Values.nodeSelector }}
    # nodeSelector:
    #   {{- toYaml . | nindent 8 }}
    # {{- end }}

    # 4. Test the rendering
    helm template my-nginx my-nginx-app/ --set extraEnv[0].name=DEBUG,extraEnv[0].value=true
    ```

---

#### 11. Chart Dependencies (Subcharts)

Add a dependency (e.g., Redis) as a subchart and configure it through the parent `values.yaml`.

#### Scenario:
  ◦ Your application needs a Redis cache alongside nginx.
  ◦ Instead of writing Redis manifests from scratch, you depend on an existing chart from a repository.

**Hint:** `Chart.yaml` dependencies, `helm dependency update`

??? example "Solution"

    ```bash
    # 1. Add dependency to Chart.yaml
    cat >> my-nginx-app/Chart.yaml << 'EOF'

    dependencies:
      - name: redis
        version: "~18.0"
        repository: "https://charts.bitnami.com/bitnami"
        condition: redis.enabled
    EOF

    # 2. Add redis configuration in values.yaml
    cat >> my-nginx-app/values.yaml << 'EOF'

    # Redis subchart configuration
    redis:
      enabled: false          # Set to true to deploy Redis alongside nginx
      architecture: standalone
      auth:
        enabled: false
    EOF

    # 3. Build dependencies (downloads the redis chart into charts/)
    helm dependency update my-nginx-app/

    # 4. Verify
    ls my-nginx-app/charts/
    # Should show: redis-18.x.x.tgz

    # 5. Install with Redis enabled
    helm upgrade --install my-nginx my-nginx-app/ --set redis.enabled=true

    # 6. Verify Redis pods
    kubectl get pods -l app.kubernetes.io/instance=my-nginx

    # Cleanup
    helm uninstall my-nginx
    ```

---

#### 12. Linting, Dry-Run, and Debugging

Use Helm's built-in tools to validate, debug, and troubleshoot your chart before deploying.

#### Scenario:
  ◦ You modified several templates and want to catch errors before deploying to the cluster.
  ◦ Helm provides lint, template, dry-run, and debug tools for this purpose.

**Hint:** `helm lint`, `helm template`, `--dry-run`, `--debug`

??? example "Solution"

    ```bash
    # 1. Lint — checks for common errors and best practices
    helm lint my-nginx-app/

    # With values overrides
    helm lint my-nginx-app/ -f values-dev.yaml

    # 2. Template — render manifests locally (no cluster needed)
    helm template my-release my-nginx-app/ > rendered.yaml
    cat rendered.yaml

    # 3. Dry-run — simulates install against the cluster (validates with API server)
    helm install my-nginx my-nginx-app/ --dry-run

    # 4. Dry-run + Debug — shows rendered templates AND computed values
    helm install my-nginx my-nginx-app/ --dry-run --debug

    # 5. Get rendered templates for a deployed release
    helm get manifest my-nginx

    # 6. Get the computed values for a deployed release
    helm get values my-nginx

    # 7. Get all information about a release
    helm get all my-nginx
    ```

---

#### 13. Package and Host a Chart Repository

Package the chart and host it in a Git-based chart repository using GitHub Pages.

#### Scenario:
  ◦ You want to share your Helm chart with your team or the community.
  ◦ A Helm chart repository is simply a web server hosting `index.yaml` and `.tgz` chart packages.
  ◦ GitHub Pages is a free and easy way to host a chart repo.

**Hint:** `helm package`, `helm repo index`, GitHub Pages

??? example "Solution"

    ```bash
    # ── Step 1: Package the chart ──

    helm package my-nginx-app/
    # Output: my-nginx-app-0.1.0.tgz

    # ── Step 2: Create a chart repository on GitHub ──

    # Create a new GitHub repository (e.g., "helm-charts")
    # Clone it locally:
    git clone https://github.com/<your-username>/helm-charts.git
    cd helm-charts

    # Create a docs/ directory (GitHub Pages will serve from here)
    mkdir -p docs

    # Move the packaged chart
    cp ../my-nginx-app-0.1.0.tgz docs/

    # ── Step 3: Generate the repository index ──

    helm repo index docs/ --url https://<your-username>.github.io/helm-charts/

    # Verify the index
    cat docs/index.yaml

    # ── Step 4: Push to GitHub ──

    git add .
    git commit -m "Add my-nginx-app chart"
    git push origin main

    # ── Step 5: Enable GitHub Pages ──

    # Go to: GitHub repo → Settings → Pages
    # Set Source: Deploy from branch → main → /docs
    # Save and wait for deployment

    # ── Step 6: Add the repo to Helm ──

    helm repo add my-charts https://<your-username>.github.io/helm-charts/
    helm repo update

    # Verify the chart is available
    helm search repo my-charts

    # ── Step 7: Install from the repository ──

    helm install my-nginx my-charts/my-nginx-app
    ```

    **Alternative: Use OCI Registry (Helm 3.8+)**

    ```bash
    # Push to an OCI-compatible registry (e.g., GitHub Container Registry)
    helm push my-nginx-app-0.1.0.tgz oci://ghcr.io/<your-username>/charts

    # Install from OCI
    helm install my-nginx oci://ghcr.io/<your-username>/charts/my-nginx-app --version 0.1.0
    ```

---

#### 14. Upgrade, Rollback, and Release History

Upgrade a release with new values, inspect its history, and rollback to a previous revision.

#### Scenario:
  ◦ You deployed version 1 of your chart, then upgraded to version 2 with bad configuration.
  ◦ You need to quickly rollback to the known-good state.

**Hint:** `helm upgrade`, `helm history`, `helm rollback`

??? example "Solution"

    ```bash
    # 1. Initial install (revision 1)
    helm install my-nginx my-nginx-app/ \
      --set welcomePage.title="Version 1"

    # 2. Upgrade to revision 2 (change the title)
    helm upgrade my-nginx my-nginx-app/ \
      --set welcomePage.title="Version 2 - BROKEN"

    # 3. Check release history
    helm history my-nginx

    # Output:
    # REVISION  STATUS      DESCRIPTION
    # 1         superseded  Install complete
    # 2         deployed    Upgrade complete

    # 4. Rollback to revision 1
    helm rollback my-nginx 1

    # 5. Verify history (now shows 3 revisions)
    helm history my-nginx

    # Output:
    # REVISION  STATUS      DESCRIPTION
    # 1         superseded  Install complete
    # 2         superseded  Upgrade complete
    # 3         deployed    Rollback to 1

    # 6. Verify the running app shows "Version 1" again
    kubectl port-forward svc/my-nginx-my-nginx-app 8080:80
    curl http://localhost:8080 | grep "Version"

    # Cleanup
    helm uninstall my-nginx
    ```

---

#### 15. Hooks (Pre-install / Post-install)

Create Helm hooks that run a Job before and after chart installation.

#### Scenario:
  ◦ You need to run a database migration before the app starts, or send a notification after deployment.
  ◦ Helm hooks let you run resources at specific points in the release lifecycle.

**Hint:** `helm.sh/hook` annotation, `pre-install`, `post-install`

??? example "Solution"

    **Step 1:** Create a pre-install hook [templates/pre-install-job.yaml]

    ```bash
    cat > my-nginx-app/templates/pre-install-job.yaml << 'TEMPLATE'
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-pre-install
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
      annotations:
        "helm.sh/hook": pre-install,pre-upgrade
        "helm.sh/hook-weight": "-5"
        "helm.sh/hook-delete-policy": hook-succeeded
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: pre-install
              image: busybox
              command:
                - sh
                - -c
                - |
                  echo "=== Pre-install hook ==="
                  echo "Running pre-flight checks..."
                  echo "Release: {{ .Release.Name }}"
                  echo "Namespace: {{ .Release.Namespace }}"
                  echo "Chart: {{ .Chart.Name }}-{{ .Chart.Version }}"
                  echo "Pre-install complete!"
    TEMPLATE
    ```

    **Step 2:** Create a post-install hook [templates/post-install-job.yaml]

    ```bash
    cat > my-nginx-app/templates/post-install-job.yaml << 'TEMPLATE'
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-post-install
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
      annotations:
        "helm.sh/hook": post-install,post-upgrade
        "helm.sh/hook-weight": "5"
        "helm.sh/hook-delete-policy": hook-succeeded
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: post-install
              image: busybox
              command:
                - sh
                - -c
                - |
                  echo "=== Post-install hook ==="
                  echo "Deployment verified!"
                  echo "Release: {{ .Release.Name }}"
                  echo "Post-install complete!"
    TEMPLATE
    ```

    **Step 3:** Deploy and observe hooks

    ```bash
    # Install and watch the hooks execute
    helm install my-nginx my-nginx-app/

    # Check jobs (hook jobs auto-delete on success due to hook-delete-policy)
    kubectl get jobs

    # If you want to see the logs, remove the hook-delete-policy temporarily
    # and check:
    kubectl logs job/my-nginx-my-nginx-app-pre-install
    kubectl logs job/my-nginx-my-nginx-app-post-install

    # Hook execution order:
    # 1. pre-install Job runs
    # 2. Chart resources are created (Deployment, Service, etc.)
    # 3. post-install Job runs

    # Cleanup
    helm uninstall my-nginx
    ```

---

### Diagram: Helm Chart Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Helm Chart: my-nginx-app                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Chart.yaml ──── name, version, dependencies                 │
│                                                              │
│  values.yaml ─── defaults ◄── values-dev.yaml               │
│                             ◄── values-prod.yaml             │
│                             ◄── --set overrides              │
│                                                              │
│  templates/ ─┬── deployment.yaml ──► Deployment              │
│              ├── service.yaml ─────► Service (ClusterIP)     │
│              ├── service-external ─► Service (ExternalName)  │
│              ├── ingress-main ─────► Ingress (path: /)       │
│              ├── ingress-status ───► Ingress (path: /status) │
│              ├── configmap-html ───► ConfigMap (welcome page)│
│              ├── pre-install-job ──► Hook (pre-install)      │
│              ├── post-install-job ─► Hook (post-install)     │
│              ├── _helpers.tpl ─────► Named templates         │
│              └── NOTES.txt ────────► Post-install message    │
│                                                              │
│  charts/ ────── redis (subchart dependency)                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                            │
                  helm package ──► my-nginx-app-0.1.0.tgz
                            │
                  GitHub Pages / OCI Registry
                            │
                  helm repo add / helm install
```

---

### Quick Reference: Essential Helm Commands

| Command                           | Description                           |
|-----------------------------------|---------------------------------------|
| `helm create <name>`              | Scaffold a new chart                  |
| `helm install <release> <chart>`  | Install a chart                       |
| `helm upgrade <release> <chart>`  | Upgrade a release                     |
| `helm upgrade --install`          | Install or upgrade (idempotent)       |
| `helm uninstall <release>`        | Remove a release                      |
| `helm list`                       | List installed releases               |
| `helm history <release>`          | Show release revision history         |
| `helm rollback <release> <rev>`   | Rollback to a previous revision       |
| `helm template <release> <chart>` | Render templates locally              |
| `helm lint <chart>`               | Check chart for errors                |
| `helm package <chart>`            | Package chart into `.tgz`             |
| `helm repo index <dir>`           | Generate repository index             |
| `helm repo add <name> <url>`      | Add a chart repository                |
| `helm search repo <keyword>`      | Search charts in added repos          |
| `helm dependency update <chart>`  | Download chart dependencies           |
| `helm get values <release>`       | Show computed values for a release    |
| `helm get manifest <release>`     | Show rendered manifests for a release |

---

#### 16. Use `helm status` to Inspect a Release

Use `helm status` to view detailed information about a deployed release including resource status and NOTES.

#### Scenario:
  ◦ A release was deployed by another team member and you need to understand its current state.
  ◦ You want to see the NOTES.txt output again without reinstalling.
  ◦ `helm status` provides a quick overview of the release deployment status and health.

**Hint:** `helm status`, `--revision`, `-o yaml`

??? example "Solution"

    ```bash
    # 1. Install a release first
    helm install my-nginx my-nginx-app/

    # 2. Get the status of the release
    helm status my-nginx

    # Output shows:
    # - Last deployment time
    # - Release status (deployed, failed, pending, etc.)
    # - Deployed resources
    # - NOTES.txt content

    # 3. Get status in YAML format
    helm status my-nginx -o yaml

    # 4. Get status in JSON format
    helm status my-nginx -o json

    # 5. Get status of a specific revision
    helm status my-nginx --revision 1

    # 6. Check status from a specific namespace
    helm status my-nginx --namespace production

    # Cleanup
    helm uninstall my-nginx
    ```

---

#### 17. Extract Values with `helm get values`

Use `helm get values` to see what values were actually used for a deployed release.

#### Scenario:
  ◦ You deployed a chart months ago with custom values and need to remember what overrides were applied.
  ◦ Multiple team members have upgraded the release and you want to know the current configuration.
  ◦ You need to replicate the same configuration in another environment.

**Hint:** `helm get values`, `--all`, `--revision`

??? example "Solution"

    ```bash
    # 1. Install with custom values
    helm install my-nginx my-nginx-app/ \
      --set replicaCount=3 \
      --set welcomePage.title="Production App"

    # 2. Get only the user-supplied values
    helm get values my-nginx

    # Output shows only the overrides:
    # replicaCount: 3
    # welcomePage:
    #   title: Production App

    # 3. Get ALL values (including defaults from values.yaml)
    helm get values my-nginx --all

    # 4. Get values from a specific revision
    helm upgrade my-nginx my-nginx-app/ --set replicaCount=5
    helm get values my-nginx --revision 1
    helm get values my-nginx --revision 2

    # 5. Output as JSON
    helm get values my-nginx -o json

    # 6. Save values to file for reuse
    helm get values my-nginx > my-nginx-values.yaml

    # 7. Use saved values in another deployment
    helm install my-nginx-copy my-nginx-app/ -f my-nginx-values.yaml

    # Cleanup
    helm uninstall my-nginx my-nginx-copy
    ```

---

#### 18. Show Chart Values with `helm show values`

Use `helm show values` to inspect the default values of a chart before installing.

#### Scenario:
  ◦ You want to install a third-party chart from a repository but need to understand what configuration options are available.
  ◦ You're evaluating multiple charts and want to compare their configuration interfaces.
  ◦ You need to create a custom values file but want to start from the defaults.

**Hint:** `helm show values`, chart repositories

??? example "Solution"

    ```bash
    # 1. Show default values of a local chart
    helm show values my-nginx-app/

    # 2. Show values from a packaged chart
    helm package my-nginx-app/
    helm show values my-nginx-app-0.1.0.tgz

    # 3. Add a public chart repository
    helm repo add bitnami https://charts.bitnami.com/bitnami

    # 4. Show default values from a repository chart
    helm show values bitnami/nginx

    # 5. Show values at a specific chart version
    helm show values bitnami/nginx --version 15.0.0

    # 6. Save default values to file for customization
    helm show values bitnami/nginx > nginx-defaults.yaml

    # 7. Compare values between chart versions
    helm show values bitnami/nginx --version 14.0.0 > nginx-v14-values.yaml
    helm show values bitnami/nginx --version 15.0.0 > nginx-v15-values.yaml
    diff nginx-v14-values.yaml nginx-v15-values.yaml

    # 8. Show all chart information (Chart.yaml + README + values)
    helm show all bitnami/nginx
    helm show chart bitnami/nginx
    helm show readme bitnami/nginx
    ```

---

#### 19. Search Charts with `helm search repo`

Use `helm search repo` to find charts in added repositories.

#### Scenario:
  ◦ You need to deploy PostgreSQL but don't want to write manifests from scratch.
  ◦ You want to find and compare available charts for a specific technology.
  ◦ You need to discover what version of a chart is available.

**Hint:** `helm search repo`, `--versions`, `--version`

??? example "Solution"

    ```bash
    # 1. Add popular chart repositories
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add stable https://charts.helm.sh/stable
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

    # 2. Update repository index
    helm repo update

    # 3. Search for charts by keyword
    helm search repo nginx

    # 4. Search showing all available versions
    helm search repo nginx --versions

    # 5. Search with version constraint
    helm search repo nginx --version "~15.0"

    # 6. Search for development/pre-release versions
    helm search repo nginx --devel

    # 7. Search with regex pattern
    helm search repo 'nginx.*'

    # 8. Search across all repositories with output formatting
    helm search repo postgresql -o json
    helm search repo postgresql -o yaml

    # 9. Search and filter with grep
    helm search repo database | grep -i postgres

    # 10. List all charts from a specific repository
    helm search repo bitnami/

    # 11. Show detailed output
    helm search repo nginx --max-col-width 0

    # 12. Install a found chart
    helm search repo bitnami/redis --versions | head -5
    helm install my-redis bitnami/redis --version 18.0.0
    helm uninstall my-redis
    ```

---

#### 20. Update Repositories with `helm repo update`

Use `helm repo update` to refresh the local cache of chart information.

#### Scenario:
  ◦ A new version of a chart was released but `helm search` doesn't show it.
  ◦ You haven't updated your repository index in weeks and want the latest charts.
  ◦ Similar to `apt update` or `yum update`, you need to sync the latest metadata.

**Hint:** `helm repo update`, `helm repo list`

??? example "Solution"

    ```bash
    # 1. List all configured repositories
    helm repo list

    # 2. Update all repositories
    helm repo update

    # Output shows each repository being refreshed:
    # Hang tight while we grab the latest from your chart repositories...
    # ...Successfully got an update from the "bitnami" chart repository
    # ...Successfully got an update from the "stable" chart repository
    # Update Complete.

    # 3. Update a specific repository
    helm repo update bitnami

    # 4. Update multiple specific repositories
    helm repo update bitnami stable

    # 5. Force update even if repository fails
    helm repo update --fail-on-repo-update-fail=false

    # 6. Verify you can now see newer chart versions
    helm search repo bitnami/nginx --versions | head -5

    # 7. Typical workflow: update before searching or installing
    helm repo update
    helm search repo redis
    helm install my-redis bitnami/redis

    # Cleanup
    helm uninstall my-redis
    ```

---

#### 21. Run Chart Tests with `helm test`

Use `helm test` to run tests defined in the chart's `templates/tests/` directory.

#### Scenario:
  ◦ You deployed a release and want to verify it's actually working correctly.
  ◦ The chart includes test pods that validate connectivity, configuration, or functionality.
  ◦ You want to include release validation in your CI/CD pipeline.

**Hint:** `helm test`, `templates/tests/`, `helm.sh/hook: test`

??? example "Solution"

    ```bash
    # 1. Create a test template if not already present
    cat > my-nginx-app/templates/tests/test-connection.yaml << 'TEMPLATE'
    apiVersion: v1
    kind: Pod
    metadata:
      name: {{ include "my-nginx-app.fullname" . }}-test-connection
      labels:
        {{- include "my-nginx-app.labels" . | nindent 4 }}
      annotations:
        "helm.sh/hook": test
    spec:
      containers:
        - name: wget
          image: busybox
          command: ['wget']
          args: ['{{ include "my-nginx-app.fullname" . }}:{{ .Values.service.port }}']
      restartPolicy: Never
    TEMPLATE

    # 2. Install the release
    helm install my-nginx my-nginx-app/

    # 3. Run the tests
    helm test my-nginx

    # Output shows:
    # NAME: my-nginx
    # ...
    # Phase: Succeeded

    # 4. Run tests with logs displayed
    helm test my-nginx --logs

    # 5. Run tests with timeout
    helm test my-nginx --timeout 2m

    # 6. View test pod logs manually
    kubectl logs my-nginx-my-nginx-app-test-connection

    # 7. Filter which tests to run (if multiple tests exist)
    helm test my-nginx --filter name=test-connection

    # 8. Clean up test pods after running (by default they remain)
    kubectl delete pod -l 'helm.sh/hook=test'

    # Or configure it in the test template with:
    # "helm.sh/hook-delete-policy": "hook-succeeded,hook-failed"

    # Cleanup
    helm uninstall my-nginx
    ```

---

#### 22. Use `helm get all` to Retrieve Complete Release Info

Use `helm get all` to retrieve all information about a deployed release in one command.

#### Scenario:
  ◦ You need to debug why a release isn't working correctly.
  ◦ You want to export the complete release configuration for documentation or backup.
  ◦ You need to see the rendered manifests, computed values, and hooks all together.

**Hint:** `helm get all`, `helm get manifest`, `helm get hooks`

??? example "Solution"

    ```bash
    # 1. Install a release
    helm install my-nginx my-nginx-app/ \
      --set replicaCount=2 \
      --set welcomePage.title="Debug Test"

    # 2. Get all information about the release
    helm get all my-nginx

    # Output includes:
    # - Release metadata
    # - User-supplied values
    # - Computed values
    # - Rendered Kubernetes manifests
    # - Hooks
    # - Notes

    # 3. Get all info from specific revision
    helm upgrade my-nginx my-nginx-app/ --set replicaCount=3
    helm get all my-nginx --revision 1
    helm get all my-nginx --revision 2

    # 4. Get individual components
    helm get manifest my-nginx       # Just the rendered manifests
    helm get values my-nginx         # Just the user values
    helm get hooks my-nginx          # Just the hooks
    helm get notes my-nginx          # Just the NOTES.txt

    # 5. Export to file for backup/documentation
    helm get all my-nginx > my-nginx-release-backup.yaml

    # 6. Use template to extract specific information
    helm get all my-nginx --template '{{.Release.Manifest}}'

    # 7. Compare two revisions
    helm get all my-nginx --revision 1 > rev1.yaml
    helm get all my-nginx --revision 2 > rev2.yaml
    diff rev1.yaml rev2.yaml

    # Cleanup
    helm uninstall my-nginx
    rm -f rev1.yaml rev2.yaml my-nginx-release-backup.yaml
    ```

---

#### 23. Use `helm list` with Filters and Formatting

Master `helm list` with various filters and output formats to manage multiple releases.

#### Scenario:
  ◦ You have dozens of releases across multiple namespaces and need to find specific ones.
  ◦ You want to script release management and need machine-readable output.
  ◦ You need to filter releases by status (deployed, failed, pending).

**Hint:** `helm list`, `--all-namespaces`, `--filter`, `-o json`

??? example "Solution"

    ```bash
    # 1. Install multiple releases for testing
    helm install nginx-dev my-nginx-app/ --set replicaCount=1
    helm install nginx-staging my-nginx-app/ --set replicaCount=2
    helm install nginx-prod my-nginx-app/ --set replicaCount=3 --namespace prod --create-namespace

    # 2. List all releases in current namespace
    helm list

    # 3. List releases across all namespaces
    helm list --all-namespaces

    # 4. List releases in specific namespace
    helm list --namespace prod

    # 5. Filter releases by name pattern
    helm list --filter 'nginx-.*'
    helm list --filter 'nginx-dev'

    # 6. Show only deployed releases
    helm list --deployed

    # 7. Show all releases including uninstalled (with --keep-history)
    helm list --all

    # 8. Show failed releases
    helm list --failed

    # 9. Show pending releases
    helm list --pending

    # 10. Output as JSON (for scripting)
    helm list -o json

    # 11. Output as YAML
    helm list -o yaml

    # 12. Show extended information
    helm list --all-namespaces -o wide

    # 13. Limit number of results
    helm list --max 5

    # 14. Sort by date
    helm list --date

    # 15. Reverse sort order
    helm list --reverse

    # 16. Show specific columns only (use with jq for JSON output)
    helm list -o json | jq '.[] | {name: .name, status: .status, namespace: .namespace}'

    # 17. Count releases
    helm list --all-namespaces | wc -l

    # 18. Find releases using specific chart
    helm list --all-namespaces -o json | jq '.[] | select(.chart | contains("my-nginx-app"))'

    # Cleanup
    helm uninstall nginx-dev nginx-staging
    helm uninstall nginx-prod -n prod
    kubectl delete namespace prod
    ```

---

#### 24. Chain Multiple Commands for Release Management

Practice chaining Helm commands for common workflows and debugging scenarios.

#### Scenario:
  ◦ You need to quickly deploy, verify, and troubleshoot releases in rapid iteration cycles.
  ◦ You want to create reusable scripts for release management.
  ◦ You need to validate deployments in CI/CD pipelines.

**Hint:** Combine `install`, `status`, `get values`, `test`, `upgrade`, `rollback`

??? example "Solution"

    ```bash
    # ── Workflow 1: Install, verify, test ──
    helm install my-nginx my-nginx-app/ && \
      helm status my-nginx && \
      helm test my-nginx

    # ── Workflow 2: Dry-run, lint, then install ──
    helm lint my-nginx-app/ && \
      helm install my-nginx my-nginx-app/ --dry-run --debug && \
      helm install my-nginx my-nginx-app/

    # ── Workflow 3: Template, validate, install ──
    helm template my-nginx my-nginx-app/ | kubectl apply --dry-run=client -f - && \
      helm install my-nginx my-nginx-app/

    # ── Workflow 4: Upgrade or install (idempotent) ──
    helm upgrade --install my-nginx my-nginx-app/ --wait --timeout 5m

    # ── Workflow 5: Upgrade with backup and rollback on failure ──
    helm get values my-nginx > backup-values.yaml && \
      helm upgrade my-nginx my-nginx-app/ --set replicaCount=5 --atomic

    # ── Workflow 6: Install, check status, get all info ──
    helm install my-nginx my-nginx-app/ && \
      sleep 10 && \
      helm status my-nginx && \
      helm get all my-nginx

    # ── Workflow 7: Compare before and after upgrade ──
    helm get values my-nginx > before.yaml && \
      helm upgrade my-nginx my-nginx-app/ --set newKey=newValue && \
      helm get values my-nginx > after.yaml && \
      diff before.yaml after.yaml

    # ── Workflow 8: Install with custom values and verify ──
    cat > custom.yaml << EOF
    replicaCount: 3
    welcomePage:
      title: "Production"
    EOF
    helm install my-nginx my-nginx-app/ -f custom.yaml && \
      kubectl get pods -l app.kubernetes.io/instance=my-nginx

    # ── Workflow 9: Rollback if tests fail ──
    helm upgrade my-nginx my-nginx-app/ --set replicaCount=10 && \
      helm test my-nginx || helm rollback my-nginx

    # ── Workflow 10: Clean reinstall ──
    helm uninstall my-nginx 2>/dev/null || true && \
      helm install my-nginx my-nginx-app/ --wait

    # ── Workflow 11: Multi-environment deployment ──
    for env in dev staging prod; do
      helm upgrade --install my-nginx-$env my-nginx-app/ \
        -f values-$env.yaml \
        --namespace $env --create-namespace
    done

    # List all deployments
    helm list --all-namespaces

    # ── Workflow 12: Debugging failed release ──
    helm status my-nginx && \
      helm get values my-nginx --all && \
      helm get manifest my-nginx | kubectl apply --dry-run=client -f - && \
      kubectl describe pods -l app.kubernetes.io/instance=my-nginx

    # Cleanup all
    for env in dev staging prod; do
      helm uninstall my-nginx-$env -n $env 2>/dev/null || true
      kubectl delete namespace $env 2>/dev/null || true
    done
    helm uninstall my-nginx 2>/dev/null || true
    rm -f backup-values.yaml before.yaml after.yaml custom.yaml
    ```

---
