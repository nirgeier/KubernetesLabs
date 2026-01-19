#!/bin/bash

# Update the apt package index
apt update

# apt-transport-https may be a dummy package; if so, you can skip that package
apt install -y docker.io apt-transport-https ca-certificates curl gpg < "/dev/null"

# Download the public signing key for the Kubernetes package repositories. 
# The same signing key is used for all repositories 
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
      gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the appropriate Kubernetes apt repository
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo  'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' \
      | tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index, install kubelet, kubeadm and kubectl
apt update
apt install -y socat kubelet kubeadm kubectl kubernetes-cni < "/dev/null"

# Prevent updating of kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# (Optional) Enable the kubelet service before running kubeadm:
# The kubelet is now restarting every few seconds, 
# as it waits in a crashloop for kubeadm to tell it what to do.
#systemctl enable --now kubelet      

# Matching the container runtime and kubelet cgroup drivers is required
# or otherwise the kubelet process will fail.

# Initializing your control-plane node
swapoff -a

# Initializing the cluster
kubeadm init --ignore-preflight-errors=NumCPU,MeM,swap 
            
# Set up the kubeconfig
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config      

# Set up the kubeconfig globally
export KUBECONFIG=/etc/kubernetes/admin.conf

# Installing a pod network add-on
# Install a lightweight CNI [Flannel] (Container Network Interface) plugin. 
# ** CoreDNS will not start up before a network is installed.
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# By default, your cluster will not schedule Pods on the control plane nodes for security reasons. 
# Enable to schedule Pods on the control plane nodes 
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# List of nodes
kubectl get nodes

# Install helmchart
wget https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz
tar -zxvf helm-v3.16.2-linux-amd64.tar.gz
chmod +x linux-amd64/helm
mv linux-amd64/helm /usr/local/bin/helm

