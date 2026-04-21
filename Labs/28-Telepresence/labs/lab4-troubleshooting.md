---

# Lab 4: Troubleshooting

---

## What will we learn?

- Using `telepresence status` to diagnose connection problems
- Adjusting log levels and gathering diagnostic logs
- Checking Traffic Manager health in the cluster
- Resolving the five most common Telepresence issues
- Performing a full nuclear reset when all else fails

---

## Introduction

- Telepresence has multiple components (Root Daemon, User Daemon, Traffic Manager) - any can fail
- Most issues fall into a few categories: DNS, intercept, port conflicts, stale connections, permissions
- The diagnostic tools are designed to help you quickly identify which component is misbehaving

---

## Diagnostic Toolkit

### 1. `telepresence status`

The **first command** to run when something isn't working:

```bash
telepresence status
```

| Field | Healthy | Problem Indicator |
|-------|---------|-------------------|
| Root Daemon | Running | Not running → restart with `sudo telepresence connect` |
| User Daemon | Running | Not running → `telepresence quit` then reconnect |
| DNS | Connected | Not configured → check `/etc/resolv.conf` |
| Cluster context | Matches expected | Wrong context → quit, switch, reconnect |

---

### 2. Log Levels and Gathering

```bash
# Set verbose logging for debugging
telepresence loglevel debug

# ... reproduce the issue ...

# Collect all logs into a zip file
telepresence gather-logs -o /tmp/tel-logs.zip

# Reset log level when done
telepresence loglevel info
```

??? question "What's in the log bundle?"
    `gather-logs` collects:

    - Client-side daemon logs
    - Traffic Manager logs from the cluster
    - Connection state snapshots
    - DNS configuration
    - Intercept state

---

### 3. Traffic Manager Health

```bash
# Check the traffic manager pod
kubectl get pods -n ambassador

# View traffic manager logs
kubectl logs -n ambassador deploy/traffic-manager --tail=50

# Check the service
kubectl get svc -n ambassador
```

---

## Common Issues & Solutions

### Issue 1: DNS Not Resolving

!!! failure "Symptom"
    `curl http://svc.ns.svc.cluster.local` hangs or fails with "Could not resolve host"

**Diagnosis:**

```bash
telepresence status | grep DNS
cat /etc/resolv.conf
```

**Fix:**

```bash
telepresence quit
telepresence connect
```

---

### Issue 2: Intercept Fails to Create

!!! failure "Symptom"
    `telepresence intercept` returns an error about missing Traffic Manager

**Diagnosis:**

```bash
# Check if traffic manager is installed
kubectl get deploy -n ambassador

# Check the target workload exists
kubectl get deploy -n telepresence-lab
```

**Fix:**

```bash
# Install or reinstall traffic manager
telepresence helm install

# Or upgrade existing installation
telepresence helm upgrade
```

---

### Issue 3: Port Conflict

!!! failure "Symptom"
    `Address already in use` when starting local process

**Diagnosis:**

```bash
# Find what's using port 5000
lsof -i :5000
```

**Fix:**

=== "Kill Conflicting Process"

    ```bash
    kill $(lsof -t -i :5000)
    ```

=== "Use Different Port"

    ```bash
    # Map cluster port 5000 → local port 8080
    telepresence intercept backend \
      --port 5000:8080 \
      --namespace telepresence-lab
    ```

---

### Issue 4: Stale Connection After Context Switch

!!! failure "Symptom"
    Commands target wrong cluster or hang indefinitely

**Diagnosis:**

```bash
telepresence status
kubectl config current-context
# If these show different clusters → stale connection
```

**Fix:**

```bash
# Always quit before switching
telepresence quit
kubectl config use-context kind-cluster-east
telepresence connect
```

---

### Issue 5: Permission Denied

!!! failure "Symptom"
    `permission denied` when running `telepresence connect`

**Fix:**

```bash
# First-time connect needs sudo for the root daemon
sudo telepresence connect

# Subsequent connects should work without sudo
```

---

## Nuclear Reset

When all else fails, perform a full reset:

```bash
# 1. Disconnect everything
telepresence quit

# 2. Uninstall from all clusters
telepresence uninstall --everything

# 3. Reinstall traffic manager
telepresence helm install

# 4. Reconnect
telepresence connect

# 5. Verify
telepresence status
```

!!! warning "Nuclear Reset Consequences"
    This removes **all intercepts** and the **Traffic Manager** from the cluster. Other developers using the same cluster will be disconnected.

---

## Pro Tips

!!! tip "Multi-Cluster Best Practices"
    **One cluster at a time**

    - Telepresence daemon only connects to one cluster at a time
    - Always `telepresence quit` before switching kubectl contexts

    **Docker mode**

    - On some setups, `telepresence connect --docker` avoids DNS/routing conflicts with the host OS

    **Log collection**

    - `telepresence gather-logs` captures both client-side and Traffic Manager logs - always include this when filing bug reports

---

## Validation Checklist

!!! success "Completion Criteria"
    - [x] `telepresence status` returns all components as "Running"
    - [x] `telepresence loglevel debug` + `gather-logs` produces a log bundle
    - [x] Traffic Manager pod is running in `ambassador` namespace
    - [x] Can diagnose and resolve at least one of the common issues above
    - [x] Understand when and how to perform a nuclear reset
