![Kubernetes Logo](../assets/images/Kubernetes-Logo.wine.png)

---

# 

## Kubernetes Labs

This is a comprehensive collection of hands-on labs designed to help you learn and master Kubernetes concepts, from basic deployments to advanced topics like Istio, ArgoCD and custom schedulers.

---

## 📚 What You'll Learn

* This lab series covers a wide range of `Kubernetes` topics:

<div class="grid cards" markdown>

- #### <i class="fas fa-layer-group" style="color: #3e84e0;"></i>&emsp;Basics
  Namespaces, Deployments, Services and Rollouts

- #### <i class="fas fa-database" style="color: #3e84e0;"></i>&emsp;Storage
  DataStores, Persistent Volume Claims and StatefulSets

- #### <i class="fas fa-network-wired" style="color: #3e84e0;"></i>&emsp;Networking
  Ingress Controllers and Service Mesh (Istio)

- #### <i class="fas fa-cogs" style="color: #3e84e0;"></i>&emsp;Configuration Management
  Kustomization and Helm Charts

- #### <i class="fas fa-code-branch" style="color: #3e84e0;"></i>&emsp;GitOps
  ArgoCD for continuous deployment

- #### <i class="fas fa-eye" style="color: #3e84e0;"></i>&emsp;Observability
  Istio, Kiali, Logging, Prometheus and Grafana

- #### <i class="fas fa-rocket" style="color: #3e84e0;"></i>&emsp;Advanced Topics
  Custom Resource Definitions (CRDs), Custom Schedulers and Pod Disruption Budgets

- #### <i class="fas fa-tools" style="color: #3e84e0;"></i>&emsp;Tools
  k9s, Krew, Kubeapps, Kubeadm and Rancher

</div>

---

## 🛠️ Prerequisites

* Before starting these labs, you should have:

  - Basic understanding of containerization (Docker)
  - Command-line (CLI) familiarity
  - A Kubernetes cluster (Minikube, Kind, or cloud-based cluster)
  - `kubectl` installed and configured

---

* Recommended Software Installations:

  | Tool Name              | Description                      |
  |------------------------|----------------------------------|
  | **DevBox**             | Development environment manager  |
  | **Docker**             | Containerization tool            |
  | **Git**                | Version control system           |
  | **Helm**               | Kubernetes package manager       |
  | **Kubernetes**         | Container orchestration platform |
  | **Node.js**            | JavaScript runtime environment   |
  | **Visual Studio Code** | Source code editor               |
  | **k9s**                | Kubernetes CLI tool              |
  | **Kind**               | Kubernetes cluster               |
  | **kubectl**            | Kubernetes command-line tool     |


---

### DevBox Installation

=== " macOS"

    ```bash
    # Install DevBox using Homebrew
    brew install getdevbox/tap/devbox
    
    # Verify installation
    devbox --version
    ```
=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Download and install DevBox
    curl -fsSL https://get.devbox.sh | bash 
    # Restart terminal or run:
    source ~/.bashrc  
    # Verify installation
    devbox --version
    ``` 
=== "🐧 Linux (CentOS)"

    ```bash
    # Download and install DevBox
    curl -fsSL https://get.devbox.sh | bash         
    # Restart terminal or run:
    source ~/.bashrc
    # Verify installation
    devbox --version
    ```
=== "⊞ Windows"

    ```powershell
    # Install DevBox using Scoop
    scoop install devbox
    # Verify installation
    devbox --version
    ```
---

### 🐳 Docker Installation

=== " macOS"

    ```bash
    # Install orbstack
    brew install --cask orbstack
    
    # Start orbstack
    open -a orbstack

    
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Update package index
    sudo apt-get update
    
    # Install Docker
    curl -fsSL https://get.docker.com | sh
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Restart session or run:
    newgrp docker
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Set up the repository
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # Install Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    # Start Docker
    sudo systemctl start docker
    # Add user to docker group
    sudo usermod -aG docker $USER
    # Restart session or run:
    newgrp docker

    ```  
  
=== "⊞ Windows"

    ```powershell
    # Install Docker Desktop
    winget install --id Docker.DockerDesktop -e
    # Start Docker Desktop
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    ```
---

### 📥 Git Installation

=== " macOS"

    ```bash
    # Install Git using Homebrew
    brew install git
    
    # Verify installation
    git --version
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Update package index
    sudo apt update
    
    # Install Git
    sudo apt install -y git
    
    # Verify installation
    git --version
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Install Git
    sudo yum install -y git
    
    # Verify installation
    git --version
    ```

=== "⊞ Windows"

    Download Git from the official website: [https://git-scm.com/download/win](https://git-scm.com/download/win)

---

### ⚓ Helm Installation

=== " macOS"

    ```bash
    # Install Helm using Homebrew
    brew install helm
    
    # Verify installation
    helm version
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Download and install Helm
    curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
    tar -zxvf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz
    
    # Verify installation
    helm version
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Download and install Helm
    curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
    tar -zxvf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz
    
    # Verify installation
    helm version
    ```

=== "⊞ Windows"

    Download Helm from: [https://get.helm.sh/helm-v3.12.0-windows-amd64.zip](https://get.helm.sh/helm-v3.12.0-windows-amd64.zip)

---

### ☸️ kubectl Installation

=== " macOS"

    ```bash
    # Install kubectl using Homebrew
    brew install kubectl
    
    # Verify installation
    kubectl version --client
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    
    # Make it executable
    chmod +x kubectl
    
    # Move to PATH
    sudo mv kubectl /usr/local/bin/
    
    # Verify installation
    kubectl version --client
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    
    # Make it executable
    chmod +x kubectl
    
    # Move to PATH
    sudo mv kubectl /usr/local/bin/
    
    # Verify installation
    kubectl version --client
    ```

=== "⊞ Windows"

    Download kubectl from: [https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/)

---

### 🟢 Node.js Installation

=== " macOS"

    ```bash
    # Install Node.js using Homebrew
    brew install node
    
    # Verify installation
    node --version
    npm --version
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    node --version
    npm --version
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    dnf module reset nodejs -y
    dnf module enable nodejs:20 -y
    dnf install nodejs -y
    node -v
    npm -v
    ```

=== "⊞ Windows"

    Download Node.js from: [https://nodejs.org/](https://nodejs.org/)

---

### 💻 Visual Studio Code Installation

=== " macOS"

    ```bash
    # Install VS Code using Homebrew
    brew install --cask visual-studio-code
    
    # Start VS Code
    code .
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Install VS Code using snap
    sudo snap install code --classic
    
    # Or using apt repository
    # wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    # sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    # sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    # sudo apt update
    # sudo apt install code
    
    # Start VS Code
    code .
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Import Microsoft GPG key
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    
    # Add VS Code repository
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    
    # Install VS Code
    sudo yum install -y code
    
    # Start VS Code
    code .
    ```

=== "⊞ Windows"

    Download Visual Studio Code from: [https://code.visualstudio.com/download](https://code.visualstudio.com/download)

---

### 🐶 k9s Installation

=== " macOS"

    ```bash
    # Install k9s using Homebrew
    brew install k9s
    
    # Verify installation
    k9s version
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Install k9s using webinstall
    curl -sS https://webinstall.dev/k9s | bash
    
    # Or download binary
    # curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -o k9s.tar.gz
    # tar -xzf k9s.tar.gz
    # sudo mv k9s /usr/local/bin/
    
    # Verify installation
    k9s version
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Download k9s binary
    curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -o k9s.tar.gz
    tar -xzf k9s.tar.gz
    sudo mv k9s /usr/local/bin/
    rm k9s.tar.gz
    
    # Verify installation
    k9s version
    ```

=== "⊞ Windows"

    Download k9s from: [https://github.com/derailed/k9s/releases](https://github.com/derailed/k9s/releases)

---

### 🎯 Kind Installation

=== " macOS"

    ```bash
    # Install Kind using Homebrew
    brew install kind
    
    # Verify installation
    kind version
    ```

=== "🐧 Linux (Ubuntu/Debian)"

    ```bash
    # Download Kind binary
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    
    # Verify installation
    kind version
    ```

=== "🐧 Linux (CentOS)"

    ```bash
    # Download Kind binary
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    
    # Verify installation
    kind version
    ```

=== "⊞ Windows"

    Download Kind from: [https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64](https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64)

---

## Getting Started




Let's dive into the world of Kubernetes together!
