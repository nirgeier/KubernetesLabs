---

# Lab 3: Outbound Connectivity

---

## What will we learn?

- How Telepresence modifies local DNS to resolve cluster services
- Reaching cluster-internal services from your local terminal
- Verifying network isolation between two clusters
- Understanding DNS resolution patterns in Kubernetes

---

## Introduction

- When connected via Telepresence, your local machine can resolve **Kubernetes DNS names** and reach cluster-internal services
- Telepresence modifies your local DNS resolver to route `*.cluster.local` queries through the connected cluster's DNS
- This means you can `curl` cluster services directly from your laptop - as if you were inside the cluster

```
┌───────────────────────────────────────────────────────────────────┐
│ Local Machine (connected to cluster-east via Telepresence)        │
│                                                                   │
│  $ curl http://backend.telepresence-lab.svc.cluster.local:5000    │
│         │                                                         │
│         ▼                                                         │
│  Telepresence DNS ──► cluster-east kube-dns ──► 10.110.x.x       │
│         │                                                         │
│         ▼                                                         │
│  Telepresence VPN tunnel ──► backend pod (10.10.x.x)              │
└───────────────────────────────────────────────────────────────────┘
```

!!! info "No Intercept Needed"
    Outbound connectivity works with just `telepresence connect` - you don't need to create an intercept. This is useful for testing, debugging, and running integration tests locally.

---

## Prerequisites

- Both kind clusters running with apps deployed
- Familiar with `kubectl config use-context` for switching clusters

---

## Step 01 - Connect to cluster-east

```bash
kubectl config use-context kind-cluster-east
telepresence connect
```

---

## Step 02 - Test DNS Resolution

```bash
# Full FQDN - most explicit form
curl -s http://backend.telepresence-lab.svc.cluster.local:5000/

# Namespace-qualified - shorter form
curl -s http://backend.telepresence-lab:5000/

# Frontend service
curl -s http://frontend.telepresence-lab.svc.cluster.local/

# Check what DNS config Telepresence is using
telepresence status | grep -A5 DNS
```

!!! success "Expected Output"
    ```json
    {"source": "cluster-east", "service": "backend", "path": "/"}
    ```

---

## Step 03 - Test Different Endpoints

```bash
# Health check
curl -s http://backend.telepresence-lab.svc.cluster.local:5000/health

# Custom paths - the cluster backend responds to any path
curl -s http://backend.telepresence-lab.svc.cluster.local:5000/api/v1/items
curl -s http://backend.telepresence-lab.svc.cluster.local:5000/data
```

---

## Step 04 - Disconnect and Switch to cluster-west

```bash
# IMPORTANT: Always quit before switching contexts
telepresence quit

# Switch to cluster-west
kubectl config use-context kind-cluster-west
telepresence connect

# Test cluster-west DNS
curl -s http://backend-v2.telepresence-lab.svc.cluster.local:5000/
```

!!! success "Expected Output"
    ```json
    {"source": "cluster-west", "service": "backend-v2", "version": "2.0", "path": "/"}
    ```

---

## Step 05 - Verify Cluster Isolation

While connected to **cluster-west**, try reaching a cluster-east service:

```bash
# This should FAIL - cluster-east DNS should not resolve
curl --max-time 3 http://backend.telepresence-lab.svc.cluster.local:5000/ 2>&1 \
  || echo "✓ Correct: cluster-east is not reachable from cluster-west connection"
```

!!! warning "Why Isolation Matters"
    In real multi-cluster setups, services in different clusters have **different data, different configs, and different versions**. Verifying isolation prevents accidentally testing against the wrong environment - a common source of "works on my machine" bugs.

---

## Step 06 - Cleanup

```bash
telepresence quit
```

---

## DNS Resolution Reference

| DNS Form | Example | When It Works |
|----------|---------|---------------|
| Full FQDN | `backend.telepresence-lab.svc.cluster.local` | Always |
| Namespace-qualified | `backend.telepresence-lab` | Always (with Telepresence) |
| Service name only | `backend` | Only if search domain matches namespace |

---

## Validation Checklist

!!! success "Completion Criteria"
    - [x] cluster-east services resolve when connected to cluster-east
    - [x] cluster-west services resolve when connected to cluster-west
    - [x] Cross-cluster DNS correctly fails (isolation verified)
    - [x] `telepresence status` shows active DNS configuration
    - [x] Both FQDN and short-form DNS work
