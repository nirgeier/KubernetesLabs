#!/bin/bash
# =============================================================================
# Step 04 - Create a Git Repository with a Helm Chart
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "STEP 4: Create Git Repository with Helm Chart"

# ── 1. Create bare Git repo ──
header "Creating Bare Git Repository"
rm -rf "${REPO_BASE}"
mkdir -p "${REPO_BASE}"
git init --bare "${BARE_REPO}"
success "Bare repo: ${BARE_REPO}"

# ── 2. Clone working directory ──
header "Cloning Working Directory"
git clone "${BARE_REPO}" "${WORK_DIR}"
cd "${WORK_DIR}"

# ── 3. Scaffold Helm chart ──
header "Creating Helm Chart: ${CHART_NAME}"
helm create "${CHART_NAME}"

# ── 4. Customize Chart.yaml ──
cat >"${CHART_NAME}/Chart.yaml" <<'EOF'
apiVersion: v2
name: my-web-app
description: A simple web application deployed via ArgoCD GitOps
type: application
version: 0.1.0
appVersion: "1.25.0"
EOF

# ── 5. Customize values.yaml ──
cat >"${CHART_NAME}/values.yaml" <<'EOF'
replicaCount: 2
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25-alpine"
imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
serviceAccount:
  create: true
  automount: true
  annotations: {}
  name: ""
podAnnotations: {}
podLabels: {}
podSecurityContext: {}
securityContext: {}
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
autoscaling:
  enabled: false
volumes: []
volumeMounts: []
nodeSelector: {}
tolerations: []
affinity: {}
welcomePage:
  title: "GitOps Demo App"
  message: "Deployed by ArgoCD from Harbor airgap registry!"
  backgroundColor: "#1a1a2e"
  textColor: "#e94560"
EOF

# ── 6. Create ConfigMap template ──
cat >"${CHART_NAME}/templates/configmap.yaml" <<'TEMPLATE'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-web-app.fullname" . }}-html
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>{{ .Values.welcomePage.title }}</title>
    <style>
      body { font-family: Arial, sans-serif; display: flex; justify-content: center;
             align-items: center; min-height: 100vh; margin: 0;
             background: {{ .Values.welcomePage.backgroundColor }};
             color: {{ .Values.welcomePage.textColor }}; }
      .container { text-align: center; }
      h1 { font-size: 2.5em; }
      .info { font-size: 1.2em; margin: 8px 0; color: #eee; }
      .badge { display: inline-block; background: {{ .Values.welcomePage.textColor }};
               color: white; padding: 5px 15px; border-radius: 20px; margin: 5px; }
    </style></head>
    <body><div class="container">
      <h1>{{ .Values.welcomePage.title }}</h1>
      <p class="info">{{ .Values.welcomePage.message }}</p>
      <p class="info">
        <span class="badge">Release: {{ .Release.Name }}</span>
        <span class="badge">Namespace: {{ .Release.Namespace }}</span>
        <span class="badge">Chart: {{ .Chart.Name }}-{{ .Chart.Version }}</span>
      </p>
    </div></body></html>
TEMPLATE

# ── 7. Update Deployment template ──
cat >"${CHART_NAME}/templates/deployment.yaml" <<'TEMPLATE'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-web-app.fullname" . }}
  labels:
    {{- include "my-web-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-web-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "my-web-app.labels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "my-web-app.serviceAccountName" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
              readOnly: true
      volumes:
        - name: html
          configMap:
            name: {{ include "my-web-app.fullname" . }}-html
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
TEMPLATE

# ── 8. Validate ──
header "Validating Helm Chart"
helm lint "${CHART_NAME}/"
success "Chart is valid"

# ── 9. Commit and push ──
header "Committing to Git"
git add .
git commit -m "Add ${CHART_NAME} Helm chart"
git push origin master 2>/dev/null || git push origin main
success "Pushed to Git repository"

info "Bare repo:   ${BARE_REPO}"
info "Workspace:   ${WORK_DIR}"
success "Step 04 complete!"
