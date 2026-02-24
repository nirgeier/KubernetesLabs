#!/usr/bin/env bash
# =============================================================================
# devlab.sh — Local devcontainer runner for KubernetesLabs
#
# Replicates the VS Code / Codespaces devcontainer experience using plain
# Docker commands. Runs Docker-in-Docker with a Kind cluster inside.
#
# Usage:
#   devlab.sh build       Build the Docker image
#   devlab.sh up          Start container + Kind cluster (builds if needed)
#   devlab.sh down        Stop container (preserves Kind cluster via volume)
#   devlab.sh down --rm   Stop and remove container + volume (full reset)
#   devlab.sh shell       Open zsh in the running container
#   devlab.sh status      Show container, DinD, and Kind cluster status
#   devlab.sh logs        Tail Docker daemon logs
#   devlab.sh push        Push image to GitHub Container Registry
#   devlab.sh rebuild     Full clean rebuild from scratch
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="kubernetes-labs-devlab"
GHCR_IMAGE="ghcr.io/nirgeier/kubernetes-labs-devlab"
CONTAINER_NAME="kubernetes-labs-devcontainer"
VOLUME_NAME="kubernetes-labs-docker-data"

# =============================================================================
# Helpers
# =============================================================================

image_exists() {
    docker image inspect "$IMAGE_NAME" >/dev/null 2>&1
}

container_state() {
    docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "missing"
}

# macOS bind mounts benefit from :cached
bind_mount_flag() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo ":cached"
    fi
}

require_running() {
    if [[ "$(container_state)" != "running" ]]; then
        echo "ERROR: Container is not running. Run: devlab.sh up"
        exit 1
    fi
}

# =============================================================================
# Commands
# =============================================================================

cmd_build() {
    echo "==> Building image ${IMAGE_NAME}..."
    docker build \
        -t "$IMAGE_NAME" \
        -f "${SCRIPT_DIR}/Dockerfile.devlab" \
        "$SCRIPT_DIR"
    echo "==> Build complete."
}

cmd_up() {
    # Auto-build if image doesn't exist
    if ! image_exists; then
        echo "==> Image not found, building first..."
        cmd_build
    fi

    STATE=$(container_state)
    case "$STATE" in
    running)
        echo "==> Container is already running."
        ;;
    exited | created)
        echo "==> Starting existing container..."
        docker start "$CONTAINER_NAME"
        ;;
    *)
        echo "==> Creating and starting container..."
        docker run -d \
            --name "$CONTAINER_NAME" \
            --hostname klabs \
            --privileged \
            -p 8000:8000 \
            -p 8443:8443 \
            -p 9080:80 \
            -p 9443:443 \
            -p 30000:30000 \
            -p 30001:30001 \
            -p 30002:30002 \
            -v "${VOLUME_NAME}:/var/lib/docker" \
            -v "${REPO_DIR}:/workspaces/KubernetesLabs$(bind_mount_flag)" \
            -w /workspaces/KubernetesLabs \
            "$IMAGE_NAME"
        ;;
    esac

    # Wait for Docker-in-Docker to be ready
    echo "==> Waiting for Docker-in-Docker..."
    TRIES=0
    until docker exec "$CONTAINER_NAME" docker info >/dev/null 2>&1; do
        TRIES=$((TRIES + 1))
        if [ "$TRIES" -ge 30 ]; then
            echo "ERROR: DinD failed to start. Check: devlab.sh logs"
            exit 1
        fi
        sleep 1
    done

    # Kind cluster: create or resume
    if docker exec "$CONTAINER_NAME" kind get clusters 2>/dev/null | grep -q "^labs$"; then
        echo "==> Kind cluster 'labs' found, ensuring nodes are running..."
        # Restart any stopped Kind node containers inside DinD
        docker exec "$CONTAINER_NAME" \
            sh -c 'NODES=$(docker ps -a --filter "label=io.x-k8s.kind.cluster=labs" --filter "status=exited" -q) && [ -n "$NODES" ] && docker start $NODES || true'
        echo "==> Waiting for nodes to be ready..."
        docker exec -u vscode "$CONTAINER_NAME" \
            kubectl wait --for=condition=Ready nodes --all --timeout=120s 2>/dev/null || true
    else
        echo "==> Creating Kind cluster 'labs'..."
        docker exec -u vscode "$CONTAINER_NAME" \
            kind create cluster \
            --name labs \
            --config .devcontainer/kind-config.yaml \
            --wait 60s
    fi

    # Install mkdocs deps
    echo "==> Installing MkDocs dependencies..."
    docker exec -u vscode "$CONTAINER_NAME" \
        pip install --quiet -r mkdocs/requirements.txt

    echo ""
    echo "============================================"
    echo "  KubernetesLabs devcontainer is ready!"
    echo "  - Kind cluster 'labs' is running"
    echo "  - kubectl, helm, k9s are available"
    echo "  - Shell:    ./scripts/devlab.sh shell"
    echo "  - MkDocs:   http://localhost:8000"
    echo "  - Kubewall: http://localhost:8443"
    echo "  - Ingress:  http://localhost:9080"
    echo "============================================"
}

cmd_down() {
    if [[ "${1:-}" == "--rm" ]]; then
        echo "==> Stopping and removing container + volume..."
        docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
        docker volume rm "$VOLUME_NAME" 2>/dev/null || true
        echo "==> Removed."
    else
        echo "==> Stopping container (Kind cluster preserved in volume)..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        echo "==> Stopped."
    fi
}

cmd_shell() {
    require_running
    docker exec -it -u vscode "$CONTAINER_NAME" zsh
}

cmd_status() {
    echo "=== Container ==="
    STATE=$(container_state)
    echo "  State: ${STATE}"

    if [[ "$STATE" != "running" ]]; then
        return
    fi

    echo ""
    echo "=== Docker-in-Docker ==="
    if docker exec "$CONTAINER_NAME" docker info >/dev/null 2>&1; then
        echo "  Status: running"
    else
        echo "  Status: not ready"
    fi

    echo ""
    echo "=== Kind Cluster ==="
    if docker exec "$CONTAINER_NAME" kind get clusters 2>/dev/null | grep -q "^labs$"; then
        echo "  Cluster: labs"
        echo ""
        echo "=== Nodes ==="
        docker exec -u vscode "$CONTAINER_NAME" kubectl get nodes 2>/dev/null || echo "  (nodes not reachable)"
    else
        echo "  No clusters found"
    fi
}

cmd_logs() {
    require_running
    docker exec "$CONTAINER_NAME" tail -f /var/log/dockerd.log
}

cmd_push() {
    if ! image_exists; then
        echo "==> Image not found, building first..."
        cmd_build
    fi
    echo "==> Tagging ${IMAGE_NAME} -> ${GHCR_IMAGE}:latest..."
    docker tag "$IMAGE_NAME" "${GHCR_IMAGE}:latest"
    echo "==> Pushing ${GHCR_IMAGE}:latest..."
    docker push "${GHCR_IMAGE}:latest"
    echo "==> Push complete."
}

cmd_rebuild() {
    echo "==> Full rebuild: removing container, volume, and image..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    docker volume rm "$VOLUME_NAME" 2>/dev/null || true
    docker rmi "$IMAGE_NAME" 2>/dev/null || true
    cmd_build
    cmd_up
}

# =============================================================================
# Main
# =============================================================================
case "${1:-help}" in
build) cmd_build ;;
up) cmd_up ;;
down)
    shift
    cmd_down "$@"
    ;;
shell) cmd_shell ;;
status) cmd_status ;;
logs) cmd_logs ;;
push) cmd_push ;;
rebuild) cmd_rebuild ;;
help | *)
    cat <<'EOF'
Usage: devlab.sh <command>

Commands:
  build       Build the Docker image
  up          Start container + Kind cluster (builds if needed)
  down        Stop container (preserves Kind cluster)
  down --rm   Stop and remove container + volume (full reset)
  shell       Open zsh in the running container
  status      Show container, DinD, and Kind cluster status
  logs        Tail Docker daemon logs
  push        Push image to GitHub Container Registry
  rebuild     Full clean rebuild from scratch

Port mappings:
  localhost:8000        MkDocs dev server
  localhost:8443        Kubewall dashboard
  localhost:9080        Kind ingress HTTP
  localhost:9443        Kind ingress HTTPS
  localhost:30000-30002 Kind NodePorts
EOF
    ;;
esac
