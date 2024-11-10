
###
### rke2 relase
RKE2_RELEASE="https://github.com/rancher/rke2/releases/download/v1.30.3-rc4%2Brke2r1"


# # Setup network
# ip link add dummy0 type dummy
# ip link set dummy0 up
# ip addr add 203.0.113.254/31 dev dummy0
# ip route add default via 203.0.113.255 dev dummy0 metric 1000

# Install helm
wget https://get.helm.sh/helm-v3.15.3-linux-amd64.tar.gz
tar -zxvf helm-v3.15.3-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# Download load rke2 binary
wget  $RKE2_RELEASE/rke2.linux-amd64
chmod +x rke2.linux-amd64
mv    rke2.linux-amd64 /usr/local/bin/rke2

# Get kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv    kubectl /usr/local/bin/kubectl

# Download load rke2 installation files
mkdir ~/rke2-artifacts && cd ~/rke2-artifacts/
curl -OLs $RKE2_RELEASE/rke2-images.linux-amd64.tar.zst
curl -OLs $RKE2_RELEASE/rke2.linux-amd64.tar.gz
curl -OLs $RKE2_RELEASE/sha256sum-amd64.txt
curl -sfL https://get.rke2.io --output install.sh

INSTALL_RKE2_ARTIFACT_PATH=~/rke2-artifacts sh install.sh
# systemctl enable rke2-server.service
# systemctl start rke2-server.service
rke2 server

# Set the kubeconfig 
mkdir -p ~/.kube
ln -s /etc/rancher/rke2/rke2.yaml ~/.kube/config

# Install k9s 
wget    https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Linux_amd64.tar.gz 
gunzip  k9s_Linux_amd64.tar.gz
tar     -xvf k9s_Linux_amd64.tar
chmod   +x k9s
mv      k9s /usr/local/bin/k9s

# Set the kubeconfig
mkdir -p ~/.kube/
cp  /etc/rancher/rke2/rke2.yaml ~/.kube/config

# Check the server status
kubectl get pods -A

# Add the rancher helm repository
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

# Download the helm 
helm fetch rancher-latest/rancher
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm fetch jetstack/cert-manager

curl -L -o cert-manager-crd.yaml https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
kubectl create ns cert-manager
kubectl apply -n cert-manager -f cert-manager-crd.yaml
helm --debug install cert-manager --create-namespace -n cert-manager cert-manager-v1.15.2.tgz



# Setuup the registry for rancher
# cat << "EOF" > /etc/rancher/rke2/registries.yaml
# mirrors:
#   docker.io:
#     endpoint:
#       - "https://globalrepo.pe.jfrog.io/remote-docker-hub"
# EOF

# docker pull quay.io/jetstack/cert-manager-ctl 
# docker pull quay.io/jetstack/cert-manager-acmesolver
# docker pull quay.io/jetstack/cert-manager-cainjector
# docker pull quay.io/jetstack/cert-manager-webhook

# helm repo add jetstack https://charts.jetstack.io

