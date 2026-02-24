FROM mcr.microsoft.com/devcontainers/base:ubuntu

LABEL org.opencontainers.image.source="https://github.com/nirgeier/KubernetesLabs"
LABEL org.opencontainers.image.description="KubernetesLabs devcontainer with Kind, kubectl, helm, k9s"
LABEL org.opencontainers.image.licenses="MIT"

# Install common tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
    zsh \
    jq \
    curl \
    wget \
    bash-completion \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Kind (multi-arch)
ARG KIND_VERSION="v0.27.0"
RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSLo /usr/local/bin/kind \
       "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}" \
    && chmod +x /usr/local/bin/kind

# Install k9s
RUN curl -sS https://webi.sh/k9s | sh 2>/dev/null; \
    mv ~/.local/bin/k9s /usr/local/bin/k9s 2>/dev/null || true

# Install kubewall (multi-arch)
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

# Install kubectx + kubens
RUN curl -fsSLo /usr/local/bin/kubectx https://github.com/ahmetb/kubectx/releases/latest/download/kubectx \
    && curl -fsSLo /usr/local/bin/kubens https://github.com/ahmetb/kubectx/releases/latest/download/kubens \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens


