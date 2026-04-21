#!/bin/bash
# =============================================================================
# Step 06 - Create an ArgoCD Application to Deploy the Helm Chart
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

banner "STEP 6: Create ArgoCD Application"

APP_NAME="my-web-app"
APP_NAMESPACE="my-web-app"

# ── 1. Create Application manifest ──
header "Creating ArgoCD Application Manifest"

cat >/tmp/argocd-app-my-web-app.yaml <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-web-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    # Replace with your actual Git repository URL
    repoURL: https://github.com/<your-org>/helm-apps.git
    targetRevision: HEAD
    path: my-web-app
    helm:
      valuesObject:
        replicaCount: 3
        welcomePage:
          title: "Airgap GitOps App"
          message: "Deployed by ArgoCD from Harbor registry!"
  destination:
    server: https://kubernetes.default.svc
    namespace: my-web-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

success "Manifest created"

# ── 2. Apply the Application ──
header "Deploying Application"
kubectl apply -f /tmp/argocd-app-my-web-app.yaml
success "Application created"

# ── 3. Wait for sync ──
header "Waiting for Sync"
for i in $(seq 1 30); do
  HEALTH=$(kubectl get application "${APP_NAME}" -n argocd \
    -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
  SYNC=$(kubectl get application "${APP_NAME}" -n argocd \
    -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")

  if [ "${HEALTH}" = "Healthy" ] && [ "${SYNC}" = "Synced" ]; then
    success "Application is Synced and Healthy!"
    break
  fi
  info "Attempt ${i}/30 - Health: ${HEALTH}, Sync: ${SYNC}"
  sleep 5
done

# ── 4. Verify resources ──
header "Deployed Resources"
kubectl get all -n "${APP_NAMESPACE}"

# ── 5. Show status ──
if command -v argocd &>/dev/null; then
  header "ArgoCD Application Status"
  argocd app get "${APP_NAME}"
fi

info "Access: kubectl port-forward svc/${APP_NAME} -n ${APP_NAMESPACE} 8081:80"
success "Step 06 complete!"
