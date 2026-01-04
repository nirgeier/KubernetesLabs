# Kubernetes Labs

## 📋 Lab Overview

Welcome to the hands-on Kubernetes labs! This comprehensive series of labs will guide you through essential Kubernetes concepts and advanced topics.

## 🗂️ Available Labs

### Foundation Labs

| Lab | Topic | Description |
|-----|-------|-------------|
| [00](00-VerifyCluster/README.md) | Verify Cluster | Ensure your Kubernetes cluster is properly configured |
| [01](01-Namespace/README.md) | Namespace | Learn to organize resources with namespaces |
| [02](02-Deployments-Imperative/README.md) | Deployments (Imperative) | Create deployments using kubectl commands |
| [03](03-Deployments-Declarative/README.md) | Deployments (Declarative) | Create deployments using YAML manifests |
| [04](04-Rollout/README.md) | Rollout | Manage deployment updates and rollbacks |
| [05](05-Services/README.md) | Services | Expose applications with Kubernetes services |

### Storage & StatefulSets

| Lab | Topic | Description |
|-----|-------|-------------|
| [06](06-DataStore/README.md) | DataStore | Work with persistent storage in Kubernetes |
| [09](09-StatefulSet/README.md) | StatefulSet | Deploy stateful applications |
| [12](12-Wordpress-MySQL-PVC/README.md) | WordPress MySQL PVC | Complete stateful application with persistent storage |

### Networking & Ingress

| Lab | Topic | Description |
|-----|-------|-------------|
| [07](07-nginx-Ingress/README.md) | Nginx Ingress | Configure ingress controllers for external access |
| [10](10-Istio/README.md) | Istio | Implement service mesh for microservices |

### Configuration Management

| Lab | Topic | Description |
|-----|-------|-------------|
| [08](08-Kustomization/README.md) | Kustomization | Manage configurations with Kustomize |
| [13](13-HelmChart/README.md) | Helm Chart | Package and deploy applications with Helm |

### GitOps & CI/CD

| Lab | Topic | Description |
|-----|-------|-------------|
| [18](18-ArgoCD/README.md) | ArgoCD | Implement GitOps with ArgoCD |

### Observability

| Lab | Topic | Description |
|-----|-------|-------------|
| [14](14-Logging/README.md) | Logging | Centralized logging with Fluentd |
| [15](15-Prometheus-Grafana/README.md) | Prometheus & Grafana | Monitoring and visualization |
| [23](23-MetricServer/README.md) | Metric Server | Resource metrics collection |

### Advanced Topics

| Lab | Topic | Description |
|-----|-------|-------------|
| [11](11-CRD-Custom-Resource-Definition/README.md) | Custom Resource Definition | Extend Kubernetes API with CRDs |
| [16](16-Affinity-Taint-Tolleration/README.md) | Affinity, Taint & Toleration | Control pod scheduling |
| [17](17-PodDisruptionBudgets-PDB/README.md) | Pod Disruption Budgets | Ensure availability during disruptions |
| [19](19-CustomScheduler/README.md) | Custom Scheduler | Build custom scheduling logic |
| [20](20-CronJob/README.md) | CronJob | Schedule recurring tasks |
| [21](21-Auditing/README.md) | Auditing | Track cluster activities |
| [21](21-KubeAPI/README.md) | Kube API | Work with Kubernetes API |
| [24](24-HelmOperator/README.md) | Helm Operator | Manage Helm releases with operators |
| [25](25-kubebuilder/README.md) | Kubebuilder | Build Kubernetes operators |

### Tools & Utilities

| Lab | Topic | Description |
|-----|-------|-------------|
| [22](22-Rancher/README.md) | Rancher | Multi-cluster management platform |
| [26](26-k9s/README.md) | k9s | Terminal-based Kubernetes UI |
| [27](27-krew/README.md) | Krew | kubectl plugin manager |
| [28](28-kubeapps/README.md) | Kubeapps | Application dashboard for Kubernetes |
| [29](29-kubeadm/README.md) | Kubeadm | Bootstrap Kubernetes clusters |
| [30](30-k9s/README.md) | k9s (Advanced) | Advanced k9s usage |

### 🧠 Practice Tasks

| Task Category | Description |
|---------------|-------------|
| [Kubernetes CLI Tasks](Tasks/Kubernetes-CLI-Tasks/README.md) | Hands-on exercises for CLI, debugging, and orchestration |

## 🎯 Learning Path

### Beginner Track
Start here if you're new to Kubernetes:<br>
1. Lab 00: Verify Cluster <br>
2. Lab 01: Namespace <br>
3. Lab 02: Deployments (Imperative) <br>
4. Lab 03: Deployments (Declarative) <br>
5. Lab 05: Services <br>

### Intermediate Track
For those with basic Kubernetes knowledge:<br>
1. Lab 04: Rollout <br>
2. Lab 06: DataStore <br>
3. Lab 07: Nginx Ingress <br>
4. Lab 08: Kustomization <br>
5. Lab 13: Helm Chart <br>

### Advanced Track
For experienced Kubernetes users:<br>
1. Lab 10: Istio<br>
2. Lab 11: Custom Resource Definition<br>
3. Lab 18: ArgoCD<br>
4. Lab 19: Custom Scheduler<br>
5. Lab 25: Kubebuilder<br>

## 💡 Tips for Success

- **Take your time**: Don't rush through the labs
- **Practice regularly**: Repetition builds muscle memory
- **Experiment**: Try variations of the examples
- **Read the docs**: Kubernetes documentation is excellent
- **Join the community**: Engage with other learners

## 🚀 Get Started

Ready to begin? Click on any lab on the left menu, or start with [Lab 00: Verify Cluster](00-VerifyCluster/README.md)!



