# Telepresence Lab 28 - Examples

This document provides practical examples for different Telepresence use cases.

## Example 1: Basic Development Workflow

**Scenario**: You're developing a new feature for the backend service.

```bash
# 1. Connect to cluster
telepresence connect

# 2. Navigate to backend code
cd resources/backend-app

# 3. Set up local environment (first time only)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Start intercept
telepresence intercept backend --port 5000 --namespace telepresence-demo

# 5. Run locally
python app.py

# 6. Access via frontend
kubectl port-forward -n telepresence-demo svc/frontend 8080:80
# Open http://localhost:8080

# 7. Make changes to app.py and see them live!

# 8. When done, clean up
telepresence leave backend
```

## Example 2: Debugging with VS Code

**Scenario**: You want to debug the backend service with breakpoints.

```bash
# 1. Start intercept
telepresence intercept backend --port 5000 --namespace telepresence-demo

# 2. In VS Code, create .vscode/launch.json:
```

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Flask",
            "type": "python",
            "request": "launch",
            "module": "flask",
            "env": {
                "FLASK_APP": "app.py",
                "FLASK_DEBUG": "1",
                "DATASERVICE_URL": "http://dataservice.telepresence-demo.svc.cluster.local:5001"
            },
            "args": [
                "run",
                "--no-debugger",
                "--no-reload",
                "--port",
                "5000"
            ],
            "jinja": true,
            "justMyCode": true
        }
    ]
}
```

```bash
# 3. Set breakpoints in app.py
# 4. Press F5 to start debugging
# 5. Access the service and hit your breakpoints!
```

## Example 3: Testing with Real Database

**Scenario**: Access cluster database from local code.

```bash
# 1. Connect telepresence
telepresence connect

# 2. Now you can access cluster services as if you're in the cluster
psql -h postgres.default.svc.cluster.local -U myuser -d mydb

# 3. Run your app locally with database access
python app.py

# Your local app now talks to the cluster database!
```

## Example 4: Personal Intercept for Team Development

**Scenario**: Multiple developers working on the same service.

```bash
# Developer 1 (Alice)
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --http-header=x-dev-user=alice

# Developer 2 (Bob)  
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --http-header=x-dev-user=bob

# Alice's requests (with header x-dev-user=alice) go to her local machine
# Bob's requests (with header x-dev-user=bob) go to his local machine
# Everyone else's requests go to the cluster

# Test with curl:
curl -H "x-dev-user=alice" http://backend.telepresence-demo.svc.cluster.local:5000/api/health
```

## Example 5: Preview URLs for Stakeholder Review

**Scenario**: Share your local changes with product manager.

```bash
# 1. Login to Ambassador Cloud (free tier)
telepresence login

# 2. Create preview intercept
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --preview-url=true

# Output shows preview URL:
# Preview URL: https://abc123.preview.edgestack.me

# 3. Share URL with stakeholders
# They can access your local version without any setup!

# 4. Make changes and they see them immediately
```

## Example 6: Environment Variable Sync

**Scenario**: Capture all cluster environment variables locally.

```bash
# 1. Create intercept and capture env vars
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --env-file=.env.cluster \
  --env-json=env.json

# 2. Load in shell
source .env.cluster

# 3. View as JSON
cat env.json | jq

# 4. Use in docker-compose.yml
cat .env.cluster >> .env

# 5. Run your app with cluster config
python app.py
```

## Example 7: Volume Access

**Scenario**: Access ConfigMaps and Secrets locally.

```bash
# 1. Intercept with volume mounts
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --mount=true

# 2. Volumes are mounted at:
ls ~/telepresence/telepresence-demo/backend-*/volumes/

# 3. Access ConfigMaps and Secrets
cat ~/telepresence/telepresence-demo/backend-*/volumes/config/app-config

# 4. Your local app can read these files
```

## Example 8: Docker Mode

**Scenario**: Run local container that accesses cluster.

```bash
# 1. Build your image
cd resources/backend-app
docker build -t my-backend:dev .

# 2. Run with telepresence in Docker mode
telepresence intercept backend \
  --port 5000 \
  --namespace telepresence-demo \
  --docker-run -- \
  -v $(pwd):/app \
  -e ENVIRONMENT=local-docker \
  my-backend:dev

# Your container now runs locally but has full cluster access!
```

## Example 9: Integration Testing

**Scenario**: Run integration tests against real cluster services.

```bash
# 1. Connect telepresence
telepresence connect

# 2. Run tests - they can access cluster services
pytest tests/integration/ -v

# Example test:
# def test_backend_to_dataservice():
#     response = requests.get('http://dataservice.telepresence-demo.svc.cluster.local:5001/data')
#     assert response.status_code == 200

# 3. No need for mocks - test against real services!
```

## Example 10: Multi-Service Development

**Scenario**: Develop two services simultaneously.

```bash
# Terminal 1 - Backend
cd resources/backend-app
telepresence intercept backend --port 5000 --namespace telepresence-demo
python app.py

# Terminal 2 - Data Service
cd resources/dataservice-app
telepresence intercept dataservice --port 5001 --namespace telepresence-demo
python app.py

# Both services now run locally and can communicate!
# Frontend still runs in cluster
```

## Example 11: Performance Profiling

**Scenario**: Profile your service with real cluster traffic.

```bash
# 1. Start intercept
telepresence intercept backend --port 5000 --namespace telepresence-demo

# 2. Run with profiler
python -m cProfile -o profile.stats app.py

# 3. Generate traffic from cluster

# 4. Analyze profile
python -m pstats profile.stats

# 5. Visualize with snakeviz
pip install snakeviz
snakeviz profile.stats
```

## Example 12: Hot Reload Development

**Scenario**: Use Flask hot reload with cluster access.

```bash
# 1. Start intercept
telepresence intercept backend --port 5000 --namespace telepresence-demo

# 2. Run with debug mode
export FLASK_APP=app.py
export FLASK_ENV=development
flask run --port 5000

# 3. Make changes to app.py
# Flask automatically reloads!
# Changes immediately visible in cluster
```

## Quick Reference Commands

```bash
# Connect
telepresence connect

# List services
telepresence list --namespace telepresence-demo

# Basic intercept
telepresence intercept SERVICE --port LOCAL_PORT --namespace NAMESPACE

# Intercept with preview URL
telepresence intercept SERVICE --port PORT --preview-url=true

# Personal intercept
telepresence intercept SERVICE --port PORT --http-match=auto

# Leave intercept
telepresence leave SERVICE

# Disconnect
telepresence quit

# Status
telepresence status

# Debug mode
telepresence loglevel debug
```

## Tips and Tricks

1. **Use shell aliases** for common commands:
   ```bash
   alias tpc='telepresence connect'
   alias tpq='telepresence quit'
   alias tps='telepresence status'
   alias tpl='telepresence list'
   ```

2. **Keep telepresence connected** during your work session - connection is cheap to maintain

3. **Use watch mode** in your framework (Flask, nodemon, etc.) for hot reload

4. **Combine with kubectl port-forward** to access additional services

5. **Use preview URLs** for quick stakeholder demos without VPN setup

6. **Personal intercepts** are safer in shared clusters - use them by default

7. **Monitor traffic manager** logs if issues arise:
   ```bash
   kubectl logs -n ambassador deployment/traffic-manager -f
   ```

8. **Export environment** once and reuse:
   ```bash
   telepresence intercept backend --env-file=.env --namespace telepresence-demo
   source .env
   # Now run any command with cluster environment
   ```
