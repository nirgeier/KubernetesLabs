# Kubernetes Labs

## 📋 Lab Overview

Welcome to the hands-on Kubernetes labs! This comprehensive series of labs will guide you through essential Kubernetes concepts and advanced topics.

## 🗂️ Available Labs

### Getting Started

| Lab                                        | Topic                     | Description                                           |
|--------------------------------------------|---------------------------|-------------------------------------------------------|
| [00](00-VerifyCluster/README.md)           | Verify Cluster            | Ensure your Kubernetes cluster is properly configured |
| [01](01-Namespace/README.md)               | Namespace                 | Learn to organize resources with namespaces           |
| [02](02-Deployments-Imperative/README.md)  | Deployments (Imperative)  | Create deployments using kubectl commands             |
| [03](03-Deployments-Declarative/README.md) | Deployments (Declarative) | Create deployments using YAML manifests               |
| [04](04-Rollout/README.md)                 | Rollout                   | Manage deployment updates and rollbacks               |
| [20](20-CronJob/README.md)                 | CronJob                   | Schedule recurring tasks                              |

### Networking

| Lab                                | Topic           | Description                                       |
|------------------------------------|-----------------|---------------------------------------------------|
| [05](05-Services/README.md)        | Services        | Expose applications with Kubernetes services      |
| [07](07-nginx-Ingress/README.md)   | Nginx Ingress   | Configure ingress controllers for external access |
| [10](10-Istio/README.md)           | Istio           | Implement service mesh for microservices          |
| [33](33-NetworkPolicies/README.md) | NetworkPolicies | Control traffic flow between pods                 |

### Security

| Lab                                 | Topic                        | Description                               |
|-------------------------------------|------------------------------|-------------------------------------------|
| [31](31-RBAC/README.md)             | RBAC                         | Role-based access control for Kubernetes  |
| [32](32-Secrets/README.md)          | Secrets                      | Manage sensitive data in Kubernetes       |
| [33](33-NetworkPolicies/README.md)  | NetworkPolicies              | Control traffic flow between pods         |
| [35](35-SecretManagement/README.md) | Secret Management            | Advanced secret management strategies     |
| [37](37-ResourceQuotas/README.md)   | ResourceQuotas & LimitRanges | Manage resource consumption per namespace |

### Storage & Config

| Lab                                    | Topic               | Description                                           |
|----------------------------------------|---------------------|-------------------------------------------------------|
| [06](06-DataStore/README.md)           | DataStore           | Work with persistent storage in Kubernetes            |
| [08](08-Kustomization/README.md)       | Kustomization       | Manage configurations with Kustomize                  |
| [09](09-StatefulSet/README.md)         | StatefulSet         | Deploy stateful applications                          |
| [12](12-Wordpress-MySQL-PVC/README.md) | WordPress MySQL PVC | Complete stateful application with persistent storage |

### Observability

| Lab                                   | Topic                | Description                              |
|---------------------------------------|----------------------|------------------------------------------|
| [14](14-Logging/README.md)            | Logging              | Centralized logging with Fluentd         |
| [15](15-Prometheus-Grafana/README.md) | Prometheus & Grafana | Monitoring and visualization             |
| [29](29-EFK/README.md)                | EFK Stack            | Elasticsearch, Fluentd, and Kibana stack |

### GitOps & CI/CD

| Lab | Topic | Description |
|-----|-------|-------------|
| [13](13-HelmChart/README.md) | HelmChart | Package and deploy applications with Helm |
| [18](18-ArgoCD/README.md) | ArgoCD | Implement GitOps with ArgoCD |
| [23](23-HelmOperator/README.md) | Helm Operator | Manage Helm releases with operators |

### Advanced

| Lab                                               | Topic                        | Description                            |
|---------------------------------------------------|------------------------------|----------------------------------------|
| [11](11-CRD-Custom-Resource-Definition/README.md) | Custom Resource Definition   | Extend Kubernetes API with CRDs        |
| [16](16-Affinity-Taint-Tolleration/README.md)     | Affinity, Taint & Toleration | Control pod scheduling                 |
| [17](17-PodDisruptionBudgets-PDB/README.md)       | Pod Disruption Budgets       | Ensure availability during disruptions |
| [19](19-CustomScheduler/README.md)                | Custom Scheduler             | Build custom scheduling logic          |
| [21](21-KubeAPI/README.md)                        | KubeAPI                      | Work with Kubernetes API               |
| [24](24-kubebuilder/README.md)                    | Kubebuilder                  | Build Kubernetes operators             |
| [28](28-Telepresence/README.md)                   | Telepresence                 | Local development with remote clusters |
| [30](30-Keda/README.md)                           | KEDA                         | Kubernetes event-driven autoscaling    |
| [34](34-crictl/README.md)                         | crictl                       | Container runtime interface CLI        |
| [36](36-kubectl-Deep-Dive/README.md)              | kubectl Deep Dive            | Advanced kubectl usage and techniques  |

### 🧠 Practice Tasks

| Task Category                                                     | Description                                                   |
|-------------------------------------------------------------------|---------------------------------------------------------------|
| [Tasks Overview](Tasks/index.md)                                  | Overview of all available practice tasks                      |
| [CLI Tasks](Tasks/Kubernetes-CLI-Tasks/README.md)                 | Hands-on exercises for CLI, debugging, and orchestration      |
| [Service Tasks](Tasks/Kubernetes-Service-Tasks/README.md)         | Practice with Kubernetes services and networking              |
| [Helm Tasks](Tasks/Kubernetes-Helm-Tasks/README.md)               | Helm chart creation, templating, repositories, and deployment |
| [ArgoCD Tasks](Tasks/Kubernetes-ArgoCD-Tasks/README.md)           | GitOps workflows with ArgoCD                                  |
| [Scheduling Tasks](Tasks/Kubernetes-Scheduling-Tasks/README.md)   | Pod scheduling, affinity, and resource management             |
| [Kubebuilder Tasks](Tasks/Kubernetes-Kubebuilder-Tasks/README.md) | Building Kubernetes operators                                 |
| [KEDA Tasks](Tasks/Kubernetes-KEDA-Tasks/README.md)               | Event-driven autoscaling exercises                            |

## 🎯 Learning Path

### Beginner Track
Start here if you're new to Kubernetes:

1. [Lab 00: Verify Cluster](00-VerifyCluster/README.md)
2. [Lab 01: Namespace](01-Namespace/README.md)
3. [Lab 02: Deployments (Imperative)](02-Deployments-Imperative/README.md)
4. [Lab 03: Deployments (Declarative)](03-Deployments-Declarative/README.md)
5. [Lab 05: Services](05-Services/README.md)

### Intermediate Track
For those with basic Kubernetes knowledge:

1. [Lab 04: Rollout](04-Rollout/README.md)
2. [Lab 06: DataStore](06-DataStore/README.md)
3. [Lab 07: Nginx Ingress](07-nginx-Ingress/README.md)
4. [Lab 08: Kustomization](08-Kustomization/README.md)
5. [Lab 13: Helm Chart](13-HelmChart/README.md)

### Advanced Track
For experienced Kubernetes users:

1. [Lab 10: Istio](10-Istio/README.md)
2. [Lab 11: Custom Resource Definition](11-CRD-Custom-Resource-Definition/README.md)
3. [Lab 18: ArgoCD](18-ArgoCD/README.md)
4. [Lab 19: Custom Scheduler](19-CustomScheduler/README.md)
5. [Lab 24: Kubebuilder](24-kubebuilder/README.md)

## 💡 Tips for Success

- **Take your time**: Don't rush through the labs
- **Practice regularly**: Repetition builds muscle memory
- **Experiment**: Try variations of the examples
- **Read the docs**: Kubernetes documentation is excellent
- **Join the community**: Engage with other learners

## 🚀 Get Started

Ready to begin? Click on any lab on the left menu, or start with [Lab 00: Verify Cluster](00-VerifyCluster/README.md)!



