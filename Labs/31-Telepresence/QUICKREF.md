# Lab 31 - Telepresence Demo

## 🎯 Quick Start

Deploy the demo and start intercepting in minutes:

```bash
# 1. Setup everything
./setup.sh

# 2. Quick start intercept
./quickstart.sh

# 3. Navigate to backend app
cd resources/backend-app

# 4. Setup Python environment (first time)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Start intercepting
telepresence intercept backend --port 5000 --namespace telepresence-demo

# 6. Run locally
python app.py

# 7. Test via frontend
kubectl port-forward -n telepresence-demo svc/frontend 8080:80
# Open http://localhost:8080
```

## 📁 Lab Structure

```
31-Telepresence/
├── README.md              # Complete guide with theory and exercises
├── EXAMPLES.md            # 12 practical examples
├── TROUBLESHOOTING.md     # Common issues and solutions
├── setup.sh              # Automated setup script
├── cleanup.sh            # Cleanup script
├── test.sh               # Test script
├── quickstart.sh         # Quick start guide
└── resources/
    ├── 01-namespace.yaml           # Namespace definition
    ├── 02-dataservice.yaml         # Data service deployment
    ├── 03-backend.yaml             # Backend service deployment
    ├── 04-frontend.yaml            # Frontend deployment
    ├── BUILD.md                     # Docker build instructions
    ├── backend-app/
    │   ├── app.py                   # Backend Python application
    │   ├── requirements.txt         # Python dependencies
    │   └── Dockerfile              # Backend Docker image
    ├── dataservice-app/
    │   ├── app.py                   # Data service application
    │   ├── requirements.txt         # Python dependencies
    │   └── Dockerfile              # Data service Docker image
    └── frontend-app/
        ├── index.html               # Frontend HTML/JS
        ├── nginx.conf              # Nginx configuration
        └── Dockerfile              # Frontend Docker image
```

## 🚀 What You'll Learn

1. **Installation & Setup**
   - Install Telepresence CLI
   - Connect to Kubernetes cluster
   - Deploy Traffic Manager

2. **Basic Intercepts**
   - Global intercepts (all traffic)
   - Personal intercepts (header-based)
   - Preview URLs (shareable links)

3. **Development Workflows**
   - Local debugging with cluster access
   - Hot reload development
   - Integration testing

4. **Advanced Features**
   - Volume mounts
   - Environment variable sync
   - Docker mode

## 📚 Documentation

- **[README.md](README.md)** - Complete guide (50+ pages)
  - Theory and concepts
  - Installation steps
  - 4 hands-on exercises
  - Best practices
  - Troubleshooting

- **[EXAMPLES.md](EXAMPLES.md)** - 12 Practical Examples
  - Basic workflows
  - VS Code debugging
  - Team collaboration
  - Integration testing

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Problem Solving
  - 10 common issues
  - Solutions and workarounds
  - Debug commands

## 🛠️ Scripts

- **setup.sh** - Deploy all resources automatically
- **cleanup.sh** - Remove all demo resources
- **test.sh** - Verify deployment and connectivity
- **quickstart.sh** - Quick start guide for intercepting

## 🎓 Exercises

### Exercise 1: Basic Intercept
Route all backend traffic to your local machine

### Exercise 2: Preview URLs
Create shareable links for stakeholder review

### Exercise 3: Global Intercept
Test breaking changes safely

### Exercise 4: Personal Intercept
Use header-based routing for team development

## 🏗️ Demo Architecture

```
┌─────────────────┐
│   Frontend      │
│   (Nginx)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────┐
│   Backend       │─────▶│ Data Service │
│   (Python)      │      │  (Python)    │
└─────────────────┘      └──────────────┘
```

**Intercept Point**: Backend service
- Local development with cluster access
- Real-time testing with other services
- No container builds required

## ⚡ Key Features Demonstrated

- ✅ Fast inner-loop development
- ✅ Service mesh integration
- ✅ Real-time code changes
- ✅ Team collaboration
- ✅ Production debugging
- ✅ Integration testing
- ✅ Preview URLs
- ✅ Environment sync

## 🔧 Prerequisites

- Kubernetes cluster (Minikube, Kind, or cloud)
- kubectl configured
- Admin access to cluster
- Python 3.11+
- Docker (optional)

## 📝 Common Commands

```bash
# Connect
telepresence connect

# List services
telepresence list --namespace telepresence-demo

# Intercept
telepresence intercept backend --port 5000 --namespace telepresence-demo

# Status
telepresence status

# Leave intercept
telepresence leave backend

# Disconnect
telepresence quit

# Cleanup
telepresence uninstall --everything
```

## 🎯 Learning Outcomes

After completing this lab, you will:

1. Understand Telepresence architecture
2. Install and configure Telepresence
3. Create and manage intercepts
4. Debug services with local tools
5. Collaborate using personal intercepts
6. Share changes via preview URLs
7. Integrate Telepresence into workflows
8. Troubleshoot common issues

## 🌟 Best Practices

1. Use personal intercepts in shared environments
2. Keep telepresence connected during development
3. Leverage hot reload for fast feedback
4. Export environment variables once, reuse
5. Monitor Traffic Manager logs
6. Clean up intercepts when done
7. Use preview URLs for demos
8. Document team intercept conventions

## 🐛 Troubleshooting

If you encounter issues:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Run `./test.sh` to verify setup
3. Check `telepresence status`
4. Enable debug: `telepresence loglevel debug`
5. View logs: `kubectl logs -n ambassador deployment/traffic-manager`

## 🔗 Resources

- Official Docs: https://www.telepresence.io/docs/
- GitHub: https://github.com/telepresenceio/telepresence
- Community Slack: https://a8r.io/slack
- Video Tutorials: https://www.youtube.com/c/Datawire

## 🧹 Cleanup

```bash
# Remove demo resources
./cleanup.sh

# Or manually
kubectl delete namespace telepresence-demo
telepresence quit
telepresence uninstall --everything
```

## 💡 Next Steps

After mastering this lab:

1. Integrate Telepresence into CI/CD
2. Create team workflows
3. Explore Ambassador Cloud features
4. Set up automated testing
5. Configure for your specific stack
6. Share knowledge with team

---

**Happy Coding! 🚀**

Questions? Check the [README.md](README.md) for detailed information or [EXAMPLES.md](EXAMPLES.md) for practical use cases.
