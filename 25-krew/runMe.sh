#!/bin/bash
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

kubectl krew update
kubectl krew install        \
        access-matrix       \
        blame               \
        count               \
        debug-shell         \
        get-all             \
        ingress-rule        \
        minio               \
        modify-secret       \
        node-admin          \
        node-shell          \
        pod-inspect         \
        resource-capacity   \
        sshd                \
        view-cert           \
        view-secret         \
        view-utilization
        
