# =============================================================================
# KubernetesLabs - Standalone Docker image
#
# Contains: Docker-in-Docker, Kind, kubectl, Helm, k9s, kubewall, kubectx/ns,
#           GitHub CLI, and all lab content under /labs.
#
# Usage:
#   docker run -d --privileged --name klabs ghcr.io/nirgeier/kubernetes-labs
#   docker exec -it klabs bash
# =============================================================================
FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/nirgeier/KubernetesLabs"
LABEL org.opencontainers.image.description="KubernetesLabs: Docker-in-Docker with Kind, kubectl, Helm, k9s, kubewall and all lab content"
LABEL org.opencontainers.image.licenses="MIT"

# --- Base packages -----------------------------------------------------------
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -y --no-install-recommends \
  bash zsh jq curl wget git \
  ca-certificates gnupg lsb-release \
  bash-completion iptables \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Docker CE (Docker-in-Docker) -------------------------------------------
RUN ARCH="$(dpkg --print-architecture)" \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  docker-ce docker-ce-cli containerd.io docker-compose-plugin \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- kubectl -----------------------------------------------------------------
RUN ARCH="$(dpkg --print-architecture)" \
  && curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
  -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

# --- Helm --------------------------------------------------------------------
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# --- GitHub CLI --------------------------------------------------------------
RUN ARCH="$(dpkg --print-architecture)" \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" \
  > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Kind (multi-arch) ------------------------------------------------------
ARG KIND_VERSION="v0.27.0"
RUN ARCH="$(dpkg --print-architecture)" \
  && curl -fsSLo /usr/local/bin/kind \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}" \
  && chmod +x /usr/local/bin/kind

# --- k9s (multi-arch) -------------------------------------------------------
ARG K9S_VERSION="v0.40.10"
RUN ARCH="$(dpkg --print-architecture)" \
  && case "${ARCH}" in \
  amd64) K9SARCH="amd64" ;; \
  arm64) K9SARCH="arm64" ;; \
  *)     K9SARCH="amd64" ;; \
  esac \
  && curl -fsSLo /tmp/k9s.tar.gz \
  "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${K9SARCH}.tar.gz" \
  && tar -xzf /tmp/k9s.tar.gz -C /usr/local/bin k9s \
  && chmod +x /usr/local/bin/k9s \
  && rm /tmp/k9s.tar.gz

# --- kubewall (multi-arch) --------------------------------------------------
ARG KUBEWALL_VERSION="v0.0.16"
RUN ARCH="$(dpkg --print-architecture)" \
  && case "${ARCH}" in \
  amd64) KWARCH="x86_64" ;; \
  arm64) KWARCH="arm64"  ;; \
  *)     KWARCH="x86_64" ;; \
  esac \
  && curl -fsSLo /tmp/kubewall.tar.gz \
  "https://github.com/kubewall/kubewall/releases/download/${KUBEWALL_VERSION}/kubewall_Linux_${KWARCH}.tar.gz" \
  && tar -xzf /tmp/kubewall.tar.gz -C /usr/local/bin kubewall \
  && chmod +x /usr/local/bin/kubewall \
  && rm /tmp/kubewall.tar.gz

# --- kubectx + kubens --------------------------------------------------------
RUN curl -fsSLo /usr/local/bin/kubectx \
  https://github.com/ahmetb/kubectx/releases/latest/download/kubectx \
  && curl -fsSLo /usr/local/bin/kubens \
  https://github.com/ahmetb/kubectx/releases/latest/download/kubens \
  && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

# --- Copy Labs content -------------------------------------------------------
COPY Labs/ /labs/
COPY docker/kind-config.yaml /etc/kind-config.yaml

# --- Entrypoint --------------------------------------------------------------
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /labs

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
