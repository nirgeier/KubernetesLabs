<div align="center">

<!-- Kubernetes Logo -->
<img src="./mkdocs/overrides/assets/images/Kubernetes-Logo.wine.png" alt="Kubernetes Logo" width="400">

<br>

# ☸️ Kubernetes Hands-on Labs

**A comprehensive collection of 33+ hands-on labs designed to help you learn and master Kubernetes — from basic deployments to advanced topics like Istio, ArgoCD and custom schedulers.**

<br>

[![Website](https://img.shields.io/badge/📖_Documentation-nirgeier.github.io-3e84e0?style=for-the-badge&labelColor=1c1c1c)](https://nirgeier.github.io/KubernetesLabs/)&nbsp;
[![Open in Cloud Shell](https://img.shields.io/badge/☁️_Open_in-Cloud_Shell-4285F4?style=for-the-badge&labelColor=1c1c1c)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

<br>

<a href="https://github.com/nirgeier/KubernetesLabs/stargazers"><img src="https://img.shields.io/github/stars/nirgeier/KubernetesLabs?style=for-the-badge&color=e3b341&labelColor=1c1c1c" alt="Stars"></a>&nbsp;
<a href="https://github.com/nirgeier/KubernetesLabs/network/members"><img src="https://img.shields.io/github/forks/nirgeier/KubernetesLabs?style=for-the-badge&color=0072b1&labelColor=1c1c1c" alt="Forks"></a>&nbsp;
<a href="https://www.linkedin.com/in/nirgeier/"><img src="https://img.shields.io/badge/LinkedIn-nirgeier-0072b1?style=for-the-badge&logo=linkedin&logoColor=white&labelColor=1c1c1c" alt="LinkedIn"></a>&nbsp;
<a href="https://stackoverflow.com/users/1755598/codewizard"><img src="https://img.shields.io/badge/StackOverflow-CodeWizard-f48024?style=for-the-badge&logo=stackoverflow&logoColor=white&labelColor=1c1c1c" alt="StackOverflow"></a>&nbsp;
<a href="mailto:nirgeier@gmail.com"><img src="https://img.shields.io/badge/Email-nirgeier@gmail.com-d14836?style=for-the-badge&logo=gmail&logoColor=white&labelColor=1c1c1c" alt="Email"></a>

</div>

---

## 📚 What You'll Learn

This lab series covers a wide range of Kubernetes topics:

<table>
<tr>
<td align="center" width="25%"><h4>🧱 Basics</h4>Namespaces, Deployments,<br>Services and Rollouts</td>
<td align="center" width="25%"><h4>💾 Storage</h4>DataStores, Persistent Volume<br>Claims and StatefulSets</td>
<td align="center" width="25%"><h4>🌐 Networking</h4>Ingress Controllers and<br>Service Mesh (Istio)</td>
<td align="center" width="25%"><h4>⚙️ Configuration</h4>Kustomization and<br>Helm Charts</td>
</tr>
<tr>
<td align="center"><h4>🔀 GitOps</h4>ArgoCD for continuous<br>deployment</td>
<td align="center"><h4>👁️ Observability</h4>Logging, Prometheus<br>and Grafana</td>
<td align="center"><h4>🚀 Advanced</h4>CRDs, Custom Schedulers<br>and Pod Disruption Budgets</td>
<td align="center"><h4>🔧 Tools</h4>k9s, Krew, Kubeapps<br>and Kubeadm</td>
</tr>
</table>

---

## 🗂️ Available Labs

### Getting Started

| Lab | Topic | Description |
|:---:|-------|-------------|
| [00](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/) | **Verify Cluster** | Ensure your Kubernetes cluster is properly configured |
| [01](https://nirgeier.github.io/KubernetesLabs/01-Namespace/) | **Namespace** | Learn to organize resources with namespaces |
| [02](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/) | **Deployments (Imperative)** | Create deployments using kubectl commands |
| [03](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/) | **Deployments (Declarative)** | Create deployments using YAML manifests |
| [04](https://nirgeier.github.io/KubernetesLabs/04-Rollout/) | **Rollout** | Manage deployment updates and rollbacks |
| [20](https://nirgeier.github.io/KubernetesLabs/20-CronJob/) | **CronJob** | Schedule recurring tasks |

### Networking

| Lab | Topic | Description |
|:---:|-------|-------------|
| [05](https://nirgeier.github.io/KubernetesLabs/05-Services/) | **Services** | Expose applications with Kubernetes services |
| [07](https://nirgeier.github.io/KubernetesLabs/07-nginx-Ingress/) | **Nginx Ingress** | Configure ingress controllers for external access |
| [10](https://nirgeier.github.io/KubernetesLabs/10-Istio/) | **Istio** | Implement service mesh for microservices |
| [33](https://nirgeier.github.io/KubernetesLabs/33-NetworkPolicies/) | **NetworkPolicies** | Control traffic flow between pods |

### Security

| Lab | Topic | Description |
|:---:|-------|-------------|
| [31](https://nirgeier.github.io/KubernetesLabs/31-RBAC/) | **RBAC** | Role-based access control for Kubernetes |
| [32](https://nirgeier.github.io/KubernetesLabs/32-Secrets/) | **Secrets** | Manage sensitive data in Kubernetes |
| [33](https://nirgeier.github.io/KubernetesLabs/33-NetworkPolicies/) | **NetworkPolicies** | Control traffic flow between pods |
| [37](https://nirgeier.github.io/KubernetesLabs/37-ResourceQuotas/) | **ResourceQuotas & LimitRanges** | Manage resource consumption per namespace |

### Storage & Config

| Lab | Topic | Description |
|:---:|-------|-------------|
| [06](https://nirgeier.github.io/KubernetesLabs/06-DataStore/) | **DataStore** | Work with persistent storage in Kubernetes |
| [08](https://nirgeier.github.io/KubernetesLabs/08-Kustomization/) | **Kustomization** | Manage configurations with Kustomize |
| [09](https://nirgeier.github.io/KubernetesLabs/09-StatefulSet/) | **StatefulSet** | Deploy stateful applications |
| [12](https://nirgeier.github.io/KubernetesLabs/12-Wordpress-MySQL-PVC/) | **WordPress MySQL PVC** | Complete stateful application with persistent storage |

### Observability

| Lab | Topic | Description |
|:---:|-------|-------------|
| [14](https://nirgeier.github.io/KubernetesLabs/14-Logging/) | **Logging** | Centralized logging with Fluentd |
| [15](https://nirgeier.github.io/KubernetesLabs/15-Prometheus-Grafana/) | **Prometheus & Grafana** | Monitoring and visualization |
| [22](https://nirgeier.github.io/KubernetesLabs/22-MetricServer/) | **Metric Server** | Kubernetes metrics collection |
| [29](https://nirgeier.github.io/KubernetesLabs/29-EFK/) | **EFK Stack** | Elasticsearch, Fluentd, and Kibana stack |

### GitOps & CI/CD

| Lab | Topic | Description |
|:---:|-------|-------------|
| [13](https://nirgeier.github.io/KubernetesLabs/13-HelmChart/) | **Helm Chart** | Package and deploy applications with Helm |
| [18](https://nirgeier.github.io/KubernetesLabs/18-ArgoCD/) | **ArgoCD** | Implement GitOps with ArgoCD |
| [23](https://nirgeier.github.io/KubernetesLabs/23-HelmOperator/) | **Helm Operator** | Manage Helm releases with operators |

### Advanced

| Lab | Topic | Description |
|:---:|-------|-------------|
| [11](https://nirgeier.github.io/KubernetesLabs/11-CRD-Custom-Resource-Definition/) | **Custom Resource Definition** | Extend Kubernetes API with CRDs |
| [16](https://nirgeier.github.io/KubernetesLabs/16-Affinity-Taint-Tolleration/) | **Affinity, Taint & Toleration** | Control pod scheduling |
| [17](https://nirgeier.github.io/KubernetesLabs/17-PodDisruptionBudgets-PDB/) | **Pod Disruption Budgets** | Ensure availability during disruptions |
| [19](https://nirgeier.github.io/KubernetesLabs/19-CustomScheduler/) | **Custom Scheduler** | Build custom scheduling logic |
| [21](https://nirgeier.github.io/KubernetesLabs/21-KubeAPI/) | **KubeAPI** | Work with Kubernetes API |
| [24](https://nirgeier.github.io/KubernetesLabs/24-kubebuilder/) | **Kubebuilder** | Build Kubernetes operators |
| [25](https://nirgeier.github.io/KubernetesLabs/25-krew/) | **Krew** | kubectl plugin manager |
| [28](https://nirgeier.github.io/KubernetesLabs/28-Telepresence/) | **Telepresence** | Local development with remote clusters |
| [30](https://nirgeier.github.io/KubernetesLabs/30-Keda/) | **KEDA** | Kubernetes event-driven autoscaling |
| [34](https://nirgeier.github.io/KubernetesLabs/34-crictl/) | **crictl** | Container runtime interface CLI |
| [36](https://nirgeier.github.io/KubernetesLabs/36-kubectl-Deep-Dive/) | **kubectl Deep Dive** | Advanced kubectl usage and techniques |

---

## 🧠 Practice Tasks

| Task Category | Description |
|---------------|-------------|
| [CLI Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-CLI-Tasks/) | Hands-on exercises for CLI, debugging, and orchestration |
| [Service Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Service-Tasks/) | Practice with Kubernetes services and networking |
| [Helm Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Helm-Tasks/) | Helm chart creation, templating, repositories, and deployment |
| [ArgoCD Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-ArgoCD-Tasks/) | GitOps workflows with ArgoCD |
| [Scheduling Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Scheduling-Tasks/) | Pod scheduling, affinity, and resource management |
| [Kubebuilder Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-Kubebuilder-Tasks/) | Building Kubernetes operators |
| [KEDA Tasks](https://nirgeier.github.io/KubernetesLabs/Tasks/Kubernetes-KEDA-Tasks/) | Event-driven autoscaling exercises |

---

## 🎯 Learning Path

<table>
<tr>
<td valign="top" width="33%">

### 🟢 Beginner Track
Start here if you're new to Kubernetes:

1. [Lab 00: Verify Cluster](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/)
2. [Lab 01: Namespace](https://nirgeier.github.io/KubernetesLabs/01-Namespace/)
3. [Lab 02: Deployments (Imperative)](https://nirgeier.github.io/KubernetesLabs/02-Deployments-Imperative/)
4. [Lab 03: Deployments (Declarative)](https://nirgeier.github.io/KubernetesLabs/03-Deployments-Declarative/)
5. [Lab 05: Services](https://nirgeier.github.io/KubernetesLabs/05-Services/)

</td>
<td valign="top" width="33%">

### 🟡 Intermediate Track
For those with basic Kubernetes knowledge:

1. [Lab 04: Rollout](https://nirgeier.github.io/KubernetesLabs/04-Rollout/)
2. [Lab 06: DataStore](https://nirgeier.github.io/KubernetesLabs/06-DataStore/)
3. [Lab 07: Nginx Ingress](https://nirgeier.github.io/KubernetesLabs/07-nginx-Ingress/)
4. [Lab 08: Kustomization](https://nirgeier.github.io/KubernetesLabs/08-Kustomization/)
5. [Lab 13: Helm Chart](https://nirgeier.github.io/KubernetesLabs/13-HelmChart/)

</td>
<td valign="top" width="33%">

### 🔴 Advanced Track
For experienced Kubernetes users:

1. [Lab 10: Istio](https://nirgeier.github.io/KubernetesLabs/10-Istio/)
2. [Lab 11: CRDs](https://nirgeier.github.io/KubernetesLabs/11-CRD-Custom-Resource-Definition/)
3. [Lab 18: ArgoCD](https://nirgeier.github.io/KubernetesLabs/18-ArgoCD/)
4. [Lab 19: Custom Scheduler](https://nirgeier.github.io/KubernetesLabs/19-CustomScheduler/)
5. [Lab 24: Kubebuilder](https://nirgeier.github.io/KubernetesLabs/24-kubebuilder/)

</td>
</tr>
</table>

---

## 🛠️ Prerequisites

Before starting these labs, you should have:

- Basic understanding of containerization (Docker)
- Command-line (CLI) familiarity
- A Kubernetes cluster (Minikube, Kind, or cloud-based)
- `kubectl` installed and configured

### Recommended Tools

| Tool | Description |
|------|-------------|
| **Docker / OrbStack** | Containerization tool |
| **kubectl** | Kubernetes command-line tool |
| **Kind** | Local Kubernetes cluster |
| **Helm** | Kubernetes package manager |
| **k9s** | Kubernetes CLI dashboard |
| **Git** | Version control system |
| **VS Code** | Source code editor |
| **DevBox** | Development environment manager |

---

## 💡 Tips for Success

- **Take your time** — Don't rush through the labs
- **Practice regularly** — Repetition builds muscle memory
- **Experiment** — Try variations of the examples
- **Read the docs** — [Kubernetes documentation](https://kubernetes.io/docs/) is excellent
- **Join the community** — Engage with other learners

---

<div align="center">

### 🚀 Ready to begin?

**Start with [Lab 00: Verify Cluster](https://nirgeier.github.io/KubernetesLabs/00-VerifyCluster/) or browse the [full documentation site](https://nirgeier.github.io/KubernetesLabs/)!**

<br>

©2021-2025 [Nir Geier](https://www.linkedin.com/in/nirgeier/) &emsp;|&emsp;
[GitHub](https://github.com/nirgeier/KubernetesLabs) &emsp;|&emsp;
[LinkedIn](https://www.linkedin.com/in/nirgeier/) &emsp;|&emsp;
[Stack Overflow](https://stackoverflow.com/users/1755598/codewizard) &emsp;|&emsp;
[Discord](https://discord.gg/U6xW23Ss)

</div>
