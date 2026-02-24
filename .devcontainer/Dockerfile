FROM mcr.microsoft.com/devcontainers/base:ubuntu

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

# Install Kind
ARG KIND_VERSION="v0.27.0"
RUN curl -Lo /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" \
    && chmod +x /usr/local/bin/kind

# Install k9s
RUN curl -sS https://webi.sh/k9s | sh 2>/dev/null; \
    mv ~/.local/bin/k9s /usr/local/bin/k9s 2>/dev/null || true

# Install kubewall
ARG KUBEWALL_VERSION="v0.0.16"
RUN curl -Lo /tmp/kubewall.tar.gz \
    "https://github.com/kubewall/kubewall/releases/download/${KUBEWALL_VERSION}/kubewall_Linux_x86_64.tar.gz" \
    && tar -xzf /tmp/kubewall.tar.gz -C /usr/local/bin kubewall \
    && chmod +x /usr/local/bin/kubewall \
    && rm /tmp/kubewall.tar.gz

# Install kubectx + kubens
RUN curl -Lo /usr/local/bin/kubectx https://github.com/ahmetb/kubectx/releases/latest/download/kubectx \
    && curl -Lo /usr/local/bin/kubens https://github.com/ahmetb/kubectx/releases/latest/download/kubens \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens


