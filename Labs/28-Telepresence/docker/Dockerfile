FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    python3 \
    make \
    g++ \
    curl \
    vim \
    grep \
    sed \
    gawk \
    tree \
    openssl \
    shadow \
    sudo \
    git \
    jq \
    bind-tools \
    docker-cli

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install kind
RUN curl -Lo /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64" \
    && chmod +x /usr/local/bin/kind

# Install Telepresence
RUN curl -fL https://app.getambassador.io/download/tel2oss/releases/download/v2.20.0/telepresence-linux-amd64 \
    -o /usr/local/bin/telepresence \
    && chmod +x /usr/local/bin/telepresence

# Install Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Set up the application
WORKDIR /app

# Copy package files and install dependencies
COPY package.json ./
RUN npm install --production

# Copy application files
COPY server.js ./
COPY public/ ./public/
COPY entrypoint.sh ./

RUN chmod +x /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
