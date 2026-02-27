#!/bin/bash
# =============================================================================
#  Harbor + ArgoCD Airgap - Full Installer (All Steps)
# =============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Harbor + ArgoCD Airgap Full Installer                      ║"
echo "║  Steps: Ingress → Harbor → Mirror → Git → ArgoCD → App     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

bash "${SCRIPT_DIR}/01-install-ingress-harbor.sh"
bash "${SCRIPT_DIR}/02-configure-harbor.sh"
bash "${SCRIPT_DIR}/03-mirror-argocd-images.sh"
bash "${SCRIPT_DIR}/04-create-git-repo.sh"
bash "${SCRIPT_DIR}/05-deploy-argocd-airgap.sh"
bash "${SCRIPT_DIR}/06-create-argocd-app.sh"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ALL STEPS COMPLETED SUCCESSFULLY                           ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Harbor:  http://harbor.local   (admin / Harbor12345)       ║"
echo "║  ArgoCD:  http://argocd.local   (admin / <see output>)     ║"
echo "║  App:     kubectl port-forward svc/my-web-app -n my-web-app 8081:80 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
