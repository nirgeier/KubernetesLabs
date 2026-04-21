#!/bin/bash
set -e

# ── Colors ──────────────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Telepresence Multi-Cluster Lab - Initializing      ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"

# ── Create lab user ─────────────────────────────────────
echo -e "${YELLOW}Creating lab user...${NC}"
adduser -D -h /home/lab -s /bin/bash lab 2>/dev/null || true
echo "lab ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

# ── Copy lab resources ──────────────────────────────────
echo -e "${YELLOW}Setting up lab resources...${NC}"
mkdir -p /home/lab/resources
cp -r /app/resources/* /home/lab/resources/ 2>/dev/null || true
cp /app/setup-clusters.sh /home/lab/ 2>/dev/null || true
chmod +x /home/lab/setup-clusters.sh 2>/dev/null || true

# ── Create kind cluster configs ─────────────────────────
echo -e "${YELLOW}Creating cluster configurations...${NC}"

cat >/home/lab/cluster-east.yaml <<'CLUSTEREOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster-east
networking:
  podSubnet: "10.10.0.0/16"
  serviceSubnet: "10.110.0.0/16"
nodes:
  - role: control-plane
  - role: worker
CLUSTEREOF

cat >/home/lab/cluster-west.yaml <<'CLUSTEREOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster-west
networking:
  podSubnet: "10.11.0.0/16"
  serviceSubnet: "10.111.0.0/16"
nodes:
  - role: control-plane
CLUSTEREOF

# ── Create setup-clusters.sh ───────────────────────────
cat >/home/lab/setup-clusters.sh <<'SETUPEOF'
#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Setting up Kind Clusters${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Delete existing clusters
echo -e "${YELLOW}Cleaning up existing clusters...${NC}"
kind delete cluster --name cluster-east 2>/dev/null || true
kind delete cluster --name cluster-west 2>/dev/null || true

# Create cluster-east
echo -e "${YELLOW}Creating cluster-east (Pod: 10.10.0.0/16, Svc: 10.110.0.0/16)...${NC}"
kind create cluster --config ~/cluster-east.yaml
echo -e "${GREEN}✓ cluster-east created${NC}"

# Create cluster-west
echo -e "${YELLOW}Creating cluster-west (Pod: 10.11.0.0/16, Svc: 10.111.0.0/16)...${NC}"
kind create cluster --config ~/cluster-west.yaml
echo -e "${GREEN}✓ cluster-west created${NC}"

# Deploy apps to cluster-east
echo ""
echo -e "${CYAN}Deploying apps to cluster-east...${NC}"
kubectl config use-context kind-cluster-east

kubectl create namespace telepresence-lab --dry-run=client -o yaml | kubectl apply -f -

# Frontend
kubectl apply -n telepresence-lab -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
        - |
          cat > /etc/nginx/conf.d/default.conf << 'NGINX'
          server {
            listen 80;
            location / {
              default_type text/plain;
              return 200 'Frontend OK - backend at: http://backend:5000\n';
            }
            location /api {
              proxy_pass http://backend:5000;
            }
          }
          NGINX
          nginx -g 'daemon off;'
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF
echo -e "${GREEN}✓ frontend deployed${NC}"

# Backend
kubectl apply -n telepresence-lab -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: python:3.11-alpine
        ports:
        - containerPort: 5000
        command: ["python3", "-c"]
        args:
        - |
          from http.server import HTTPServer, BaseHTTPRequestHandler
          import json, os
          class Handler(BaseHTTPRequestHandler):
              def do_GET(self):
                  self.send_response(200)
                  self.send_header('Content-Type', 'application/json')
                  self.end_headers()
                  resp = {"source": "cluster-east", "service": "backend", "path": self.path}
                  self.wfile.write(json.dumps(resp).encode())
              def log_message(self, format, *args): pass
          HTTPServer(('0.0.0.0', 5000), Handler).serve_forever()
        volumeMounts:
        - name: config
          mountPath: /etc/config
      volumes:
      - name: config
        configMap:
          name: backend-config
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 5000
    targetPort: 5000
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  app.conf: |
    environment=development
    log_level=debug
    database_host=datastore.telepresence-lab.svc.cluster.local
    cache_ttl=300
  features.json: |
    {"feature_x": true, "feature_y": false, "max_retries": 3}
EOF
echo -e "${GREEN}✓ backend deployed${NC}"

# Deploy apps to cluster-west
echo ""
echo -e "${CYAN}Deploying apps to cluster-west...${NC}"
kubectl config use-context kind-cluster-west

kubectl create namespace telepresence-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n telepresence-lab -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend-v2
  template:
    metadata:
      labels:
        app: backend-v2
    spec:
      containers:
      - name: backend-v2
        image: python:3.11-alpine
        ports:
        - containerPort: 5000
        command: ["python3", "-c"]
        args:
        - |
          from http.server import HTTPServer, BaseHTTPRequestHandler
          import json
          class Handler(BaseHTTPRequestHandler):
              def do_GET(self):
                  self.send_response(200)
                  self.send_header('Content-Type', 'application/json')
                  self.end_headers()
                  resp = {"source": "cluster-west", "service": "backend-v2", "version": "2.0", "path": self.path}
                  self.wfile.write(json.dumps(resp).encode())
              def log_message(self, format, *args): pass
          HTTPServer(('0.0.0.0', 5000), Handler).serve_forever()
---
apiVersion: v1
kind: Service
metadata:
  name: backend-v2
spec:
  selector:
    app: backend-v2
  ports:
  - port: 5000
    targetPort: 5000
EOF
echo -e "${GREEN}✓ backend-v2 deployed${NC}"

# Install Telepresence traffic manager on both clusters
echo ""
echo -e "${CYAN}Installing Telepresence traffic manager...${NC}"

for ctx in kind-cluster-east kind-cluster-west; do
  echo -e "${YELLOW}Installing on ${ctx}...${NC}"
  kubectl config use-context "$ctx"
  telepresence helm install 2>/dev/null || echo -e "${YELLOW}  (traffic manager may already be installed)${NC}"
done

# Wait for pods
echo ""
echo -e "${CYAN}Waiting for pods to be ready...${NC}"
kubectl config use-context kind-cluster-east
kubectl wait --for=condition=ready pod -l app=frontend -n telepresence-lab --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=backend -n telepresence-lab --timeout=120s 2>/dev/null || true

kubectl config use-context kind-cluster-west
kubectl wait --for=condition=ready pod -l app=backend-v2 -n telepresence-lab --timeout=120s 2>/dev/null || true

# Summary
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Setup Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${GREEN}Clusters:${NC}"
echo "  kind-cluster-east  (Pod: 10.10.0.0/16, Svc: 10.110.0.0/16)"
echo "  kind-cluster-west  (Pod: 10.11.0.0/16, Svc: 10.111.0.0/16)"
echo ""
echo -e "${GREEN}Services:${NC}"
echo "  cluster-east:  frontend (port 80), backend (port 5000)"
echo "  cluster-west:  backend-v2 (port 5000)"
echo ""
echo -e "${GREEN}Quick commands:${NC}"
echo "  kubectl config use-context kind-cluster-east"
echo "  kubectl config use-context kind-cluster-west"
echo "  telepresence connect"
echo "  telepresence list -n telepresence-lab"
echo ""
SETUPEOF

chmod +x /home/lab/setup-clusters.sh

# ── Write .bashrc ───────────────────────────────────────
cat >/home/lab/.bashrc <<'BASHRC'
# Telepresence Lab Environment
export PS1='\[\033[1;36m\]telepresence-lab\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]$ '
export EDITOR=vim

# Aliases
alias k='kubectl'
alias kge='kubectl config use-context kind-cluster-east && echo "Switched to cluster-east"'
alias kgw='kubectl config use-context kind-cluster-west && echo "Switched to cluster-west"'
alias tpc='telepresence connect'
alias tps='telepresence status'
alias tpq='telepresence quit'
alias tpl='telepresence list -n telepresence-lab'

# Welcome message
if [ -z "$WELCOMED" ]; then
  export WELCOMED=1
  echo ""
  echo -e "\033[1;36m╔═══════════════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;36m║  Welcome to the Telepresence Multi-Cluster Lab!      ║\033[0m"
  echo -e "\033[1;36m╚═══════════════════════════════════════════════════════╝\033[0m"
  echo ""
  echo -e "\033[1;33mQuick Start:\033[0m"
  echo "  1. Run  ./setup-clusters.sh  to create kind clusters"
  echo "  2. Select a lab from the dropdown on the left"
  echo "  3. Follow the instructions step by step"
  echo ""
  echo -e "\033[1;33mShortcuts:\033[0m"
  echo "  kge  → switch to cluster-east"
  echo "  kgw  → switch to cluster-west"
  echo "  tpc  → telepresence connect"
  echo "  tps  → telepresence status"
  echo "  tpq  → telepresence quit"
  echo "  tpl  → telepresence list"
  echo ""
fi
BASHRC

# ── Fix ownership ───────────────────────────────────────
chown -R lab:lab /home/lab

echo -e "${GREEN}✓ Lab environment ready${NC}"
echo ""

# ── Start server ────────────────────────────────────────
exec node /app/server.js
