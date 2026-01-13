# Telepresence Troubleshooting Guide

## Common Issues and Solutions

### 1. Cannot Connect to Cluster

**Symptom**: `telepresence connect` fails

**Solutions**:
```bash
# Check kubectl connectivity
kubectl cluster-info

# Check current context
kubectl config current-context

# Try with specific context
telepresence connect --context your-context

# Check RBAC permissions
kubectl auth can-i create mutatingwebhookconfigurations
```

### 2. Traffic Manager Not Installing

**Symptom**: Traffic Manager pod in `ambassador` namespace is not running

**Solutions**:
```bash
# Check traffic manager status
kubectl get pods -n ambassador

# View logs
kubectl logs -n ambassador deployment/traffic-manager

# Uninstall and reinstall
telepresence uninstall --everything
telepresence connect

# Check for resource constraints
kubectl describe pod -n ambassador -l app=traffic-manager
```

### 3. Intercept Not Working

**Symptom**: Traffic not reaching local service

**Solutions**:
```bash
# Check intercept status
telepresence list
telepresence status

# Verify local service is running
netstat -an | grep 5000
# or
lsof -i :5000

# Check for port conflicts
telepresence intercept backend --port 5001:5000 --namespace telepresence-demo

# View detailed logs
telepresence quit
telepresence loglevel debug
telepresence connect
```

### 4. DNS Resolution Issues

**Symptom**: Cannot resolve cluster service names

**Solutions**:
```bash
# Check DNS configuration
telepresence status

# Test DNS resolution
ping dataservice.telepresence-demo.svc.cluster.local

# Try alternative DNS
telepresence quit
telepresence connect --dns=google

# On macOS, reset DNS
sudo killall -HUP mDNSResponder
```

### 5. Permission Denied Errors

**Symptom**: Permission errors when connecting

**Solutions**:
```bash
# Check if running with proper permissions
# On macOS/Linux, might need to run with sudo for the first connection
sudo telepresence connect

# Check cluster admin permissions
kubectl auth can-i '*' '*' --all-namespaces

# Contact cluster admin if lacking permissions
```

### 6. Port Already in Use

**Symptom**: "Address already in use" error

**Solutions**:
```bash
# Find what's using the port
lsof -i :5000

# Kill the process
kill -9 <PID>

# Use a different local port
telepresence intercept backend --port 5001:5000 --namespace telepresence-demo
# Then run your app on port 5001
```

### 7. Slow Connection or Timeouts

**Symptom**: Slow responses or connection timeouts

**Solutions**:
```bash
# Check network connectivity
ping 8.8.8.8

# Restart telepresence
telepresence quit
telepresence connect

# Check cluster health
kubectl get nodes
kubectl top nodes

# Reduce intercept scope
telepresence intercept backend --port 5000 --http-match=auto
```

### 8. Environment Variables Not Loading

**Symptom**: App can't access cluster environment variables

**Solutions**:
```bash
# Capture environment to file
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --env-file=.env.cluster

# Load in your shell
source .env.cluster

# Then run your app
python app.py

# Or use with Docker
telepresence intercept backend \
  --port 5000 \
  --docker-run -- \
  --env-file .env.cluster \
  my-image
```

### 9. Multiple Intercepts Conflict

**Symptom**: Only one intercept works at a time

**Solutions**:
```bash
# List all intercepts
telepresence list

# Leave specific intercept
telepresence leave backend

# Leave all intercepts
telepresence leave --all

# Use different ports for different services
telepresence intercept backend --port 5000
telepresence intercept frontend --port 3000
```

### 10. Can't Access Volumes

**Symptom**: Volume mounts not accessible locally

**Solutions**:
```bash
# Enable volume mounts with intercept
telepresence intercept backend \
  --port 5000 \
  --mount=true \
  --mount-type=sshfs

# Check mount location
ls ~/telepresence/telepresence-demo/

# Alternative: use docker mode
telepresence intercept backend \
  --port 5000 \
  --docker-run \
  -- \
  -v ~/telepresence/telepresence-demo:/mnt/volumes \
  my-image
```

## Debugging Commands

```bash
# Show detailed status
telepresence status

# Enable debug logging
telepresence loglevel debug

# Show version information
telepresence version

# Show all intercepts across namespaces
telepresence list --all-namespaces

# Test cluster connectivity
telepresence test

# View background daemon logs (macOS)
tail -f ~/Library/Logs/telepresence/*.log

# View background daemon logs (Linux)
journalctl -u telepresence -f
```

## Getting Help

- Official Docs: https://www.telepresence.io/docs/
- GitHub Issues: https://github.com/telepresenceio/telepresence/issues
- Community Slack: https://a8r.io/slack
- Stack Overflow: Tag `telepresence`

## Reporting Issues

When reporting issues, include:

1. Telepresence version: `telepresence version`
2. Kubernetes version: `kubectl version`
3. Operating system and version
4. Output of `telepresence status`
5. Relevant logs with debug enabled
6. Steps to reproduce the issue
