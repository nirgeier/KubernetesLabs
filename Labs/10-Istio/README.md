
![](../../resources/k8s-logos.png)


<!-- omit in toc -->
# K8S Hands-on 

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)

---

<!-- omit in toc -->
## PreRequirements

- [Helm](https://helm.sh/docs/intro/install/)
- K8S cluster
- **kubectl**  configured to interact with your cluster.

---

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)

<!-- omit in toc -->
### **<kbd>CTRL</kbd> + click to open in new window**

---

- [Introduction](#introduction)
  - [`Istio`](#istio)
  - [`Kiali`](#kiali)
- [Part 01 - Installing Istio and Kiali](#part-01---installing-istio-and-kiali)
  - [Step 01: Install Istio Using Istioctl](#step-01-install-istio-using-istioctl)
  - [Step 02: Verify Istio installation](#step-02-verify-istio-installation)
  - [Step 03: Install Kiali](#step-03-install-kiali)
  - [Step 04: Verify Kiali installation](#step-04-verify-kiali-installation)
- [Part 02 - Viewing the Network with Istio](#part-02---viewing-the-network-with-istio)
  - [Step 01: Enable Istio Injection](#step-01-enable-istio-injection)
  - [Step 2: Deploy Sample Application](#step-2-deploy-sample-application)
  - [Step 03: Verify the Sample Application](#step-03-verify-the-sample-application)
  - [Step 04: Expose the Application](#step-04-expose-the-application)
- [Part 03 - Visualizing the Network with Kiali](#part-03---visualizing-the-network-with-kiali)
  - [Step 01: Access Kiali Dashboard](#step-01-access-kiali-dashboard)
  - [Step 02: Explore the Service Mesh Topology](#step-02-explore-the-service-mesh-topology)
- [Part 04: Creating a Demo Istio VirtualService](#part-04-creating-a-demo-istio-virtualservice)
  - [Step 1: Define a VirtualService](#step-1-define-a-virtualservice)
  - [Step 02: Apply the VirtualService](#step-02-apply-the-virtualservice)
  - [Step 03: Verify the Routing](#step-03-verify-the-routing)
- [Conclusion](#conclusion)


---

<!-- omit in toc -->
# Istio and Kiali
- This guide provides a detailed walkthrough on installing and configuring **Istio**  and **Kiali**  in a Kubernetes cluster. 
- You will also learn how to visualize your service mesh with Istio and Kiali, create a demo **Istio VirtualService**.
  
---


## Introduction 

### `Istio` 

- **Istio**  is an open-source **service mesh** that provides a way to manage microservices traffic, security, and observability in a Kubernetes cluster. 
- It acts as a layer of infrastructure that sits between your services, **intercepting and controlling the traffic** between them. 
- Istio key features: 
  
  | **Feature**                         | **Description**                                                                                                                                                   |
  | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | **Traffic Management**              | Istio enables sophisticated traffic control capabilities, such as routing, load balancing, retries, timeouts, and circuit breakers for microservices.             |
  | **Service Discovery**               | Automatically discovers services in the mesh, enabling dynamic routing and management of microservices without the need for manual configuration.                 |
  | **Load Balancing**                  | Istio provides various load balancing algorithms (round-robin, weighted, etc.) to distribute traffic between microservices, ensuring optimal performance.         |
  | **Traffic Shaping**                 | Allows fine-grained control of traffic between services, such as A/B testing, canary releases, or blue/green deployments by defining routing rules.               |
  | **Fault Injection**                 | Supports fault injection to simulate network failures, latency, or errors in microservices to test resilience and robustness of the application.                  |
  | **Mutual TLS (mTLS)**               | Istio can automatically encrypt traffic between services using mutual TLS (mTLS) to ensure secure communication and provide strong identity-based access control. |
  | **Authentication & Authorization**  | Provides identity and access management through role-based access control (RBAC) and integration with external identity providers (e.g., OAuth, JWT).             |
  | **Telemetry & Observability**       | Istio collects metrics, logs, and traces for monitoring service performance and behavior. Integrates with tools like Prometheus, Grafana, and Jaeger.             |
  | **Distributed Tracing**             | Integrates with tracing systems like **Jaeger** and **Zipkin** to provide end-to-end tracing for debugging and monitoring service interactions.                   |
  | **Policy Enforcement**              | Istio provides fine-grained control over traffic policies, such as rate limiting, quotas, and security policies, using its Policy and Telemetry components.       |
  | **Resilience & Retries**            | Istio can retry failed requests, set timeouts, and apply circuit breakers to prevent cascading failures and enhance the reliability of services.                  |
  | **Sidecar Proxy (Envoy)**           | Istio uses **Envoy** as a sidecar proxy to intercept and manage network traffic, providing a transparent proxy between microservices.                             |
  | **Automatic Sidecar Injection**     | Istio automatically injects the **Envoy proxy** into application pods via Kubernetes annotations, simplifying the management of service communication.            |
  | **Service Mesh Topology**           | Visualizes and manages the network of microservices, allowing users to monitor how services interact with each other and troubleshoot issues.                     |
  | **Canary Deployments**              | Supports **canary releases** and traffic splitting, which allows gradual rollout of new versions of services for safe deployments and testing.                    |
  | **Multi-cluster Support**           | Istio supports a multi-cluster environment, allowing you to deploy services across different Kubernetes clusters while maintaining a unified service mesh.        |
  | **Integration with Existing Tools** | Istio integrates seamlessly with other tools such as **Prometheus**, **Grafana**, **Jaeger**, and **Kiali** for observability, monitoring, and tracing.           |
  | **Service-Level Agreements (SLAs)** | Provides mechanisms to define service-level objectives (SLOs) and monitor them, ensuring services meet expected performance and reliability standards.            |


- Istio core components: 
  | **Components**  | **Description**                                                          |
  | --------------- | ------------------------------------------------------------------------ |
  | **Envoy Proxy** | A sidecar proxy that intercepts traffic to and from microservices.       |
  | **Pilot**       | Manages configuration and distributes traffic management rules.          |
  | **Mixer**       | Provides policy enforcement and telemetry data collection.               |
  | **Citadel**     | Handles security-related tasks like identity and certificate management. |


### `Kiali` 

- **Kiali**  is a graphical user interface (GUI) for `Istio`. 
- It helps you visualize the service mesh and provides insights into how microservices are interacting with each other. 
- `Kiali` integrates deeply with Istio, allowing you to view:
  - The **service mesh topology**  showing services, traffic flow, and dependencies.
  - Metrics like request rates, latencies, and error rates.
  - **Distributed tracing**  (if enabled) for better debugging and troubleshooting.
  - **Istio configuration**  to visualize resources like VirtualServices, DestinationRules, and more.

- `Kiali` simplifies the operation of Istio by offering an intuitive way to manage and visualize your service mesh.


---

## Part 01 - Installing Istio and Kiali 

### Step 01: Install Istio Using Istioctl

- Istio supply an installer
- Go to the [Istio releases page](https://github.com/istio/istio/releases) and download the latest version of Istio. 
- Alternatively, use `istioctl` to install Istio.

  ```bash
  # Install Istio using istioctl
  echo  "Installing Istio..."
  curl  -L https://istio.io/downloadIstio | sh -
  cd    istio-*
  
  # Add bin directory to your $PATH
  export PATH=$PWD/bin:$PATH

  # Install istio will all features enabled (demo profile)
  istioctl install --set profile=demo -y
  
  ```
 
 
### Step 02: Verify Istio installation

- Check the Istio system components in the `istio-system` namespace:
  ```bash
  # Verify Istio installation
  kubectl get pods -n istio-system
  ```
- You should see several pods, including the Istio control plane components like 
  - `istiod`
  - `istio-ingressgateway`
  - `istio-egressgateway`
  
  <br/>

  **`kubectl get pods -n istio-system`**
    ```plaintext
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-egressgateway-684f5dc857-bzww6    1/1     Running   0          21m
    istio-ingressgateway-6b5bd79c5c-9n8tg   1/1     Running   0          21m
    istiod-68885d595-vv2ft                  1/1     Running   0          22m
    ```

### Step 03: Install Kiali

- We will install kiali with Helm

  ```bash
  # Add the Kiali Helm chart repository
  helm repo add kiali https://kiali.org/helm-charts
  helm repo update
  ```
 
- **Install Kiali:** 

  ```bash
  # Install Kiali into the `istio-system` namespace 
  # this is the default namespace for Istio components
  #
  # Install Kiali with anonymous authentication
  #
  helm install  kiali-server              \
                kiali/kiali-server        \
                --namespace istio-system  \
                --set auth.strategy="anonymous"
  ```

### Step 04: Verify Kiali installation

- Once installed, check the status of Kiali:
  ```bash
  kubectl get pods -n istio-system
  ```

- You should see the Kiali pod running, along with the Istio components from previous step.
  ```plaintext
  NAME                                    READY   STATUS    RESTARTS   AGE
  istio-egressgateway-684f5dc857-bzww6    1/1     Running   0          28m
  istio-ingressgateway-6b5bd79c5c-9n8tg   1/1     Running   0          28m
  istiod-68885d595-vv2ft                  1/1     Running   0          28m
  kiali-68ccc848b6-j4q28                  1/1     Running   0          27m
  ```

---

## Part 02 - Viewing the Network with Istio 

- Istio uses a sidecar proxy model, where an Envoy proxy is deployed alongside each microservice pod. 
- This proxy intercepts and manages traffic between the services.

### Step 01: Enable Istio Injection

- You need to enable **Istio sidecar injection** for your Kubernetes namespace. 
- This will ensure that new pods in the `default` namespace will automatically have the Envoy proxy sidecar injected.
- For example, to enable injection in the `default` namespace:

  ```bash
  kubectl label namespace default istio-injection=enabled
  ```

### Step 2: Deploy Sample Application

- To see Istio in action, deploy a sample application, such as **Bookinfo** , which is available in Istio's demo repository.
  
  ```bash
  # Deploy the sample application supplied by istio
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  ```

### Step 03: Verify the Sample Application

- To check that the application pods are running, execute the following command:

  ```bash
  kubectl get pods
  ```
  
### Step 04: Expose the Application

- To expose the application via Istio's ingress gateway, create an Istio **Gateway**  and **VirtualService** .

  ```bash
  # This will expose the 'Bookinfo' application to the external world via Istio ingress gateway.
  kubectl   apply -f \
            samples/bookinfo/networking/bookinfo-gateway.yaml
  ```

---


## Part 03 - Visualizing the Network with Kiali 

### Step 01: Access Kiali Dashboard 

- Once Kiali is installed, you can access its dashboard. 
- First, define a port-forward the Kiali service:

  ```bash
  kubectl   port-forward        \
            -n istio-system     \
            svc/kiali 20001:20001
  ```

- Now, open your browser and go to [http://localhost:20001](http://localhost:20001)
  - **Username** : `admin`
  - **Password** : (Leave blank if anonymous access is enabled)

### Step 02: Explore the Service Mesh Topology 

- Once inside the Kiali dashboard, Open the `Mesh` View
- You will see a **graph**  of your services in the mesh.
- The graph shows the interactions between microservices, along with traffic flows, success/error rates, and latency.
- You can use the Kiali interface to:
  - **Zoom in/out**  of the topology.
  - View detailed metrics for each service.
  - Understand the traffic flow, including retries, timeouts, and error rates.


---

## Part 04: Creating a Demo Istio VirtualService 

- In Istio, **VirtualServices**  are used to define the routing rules for your services.

### Step 1: Define a VirtualService
- Create a `VirtualService` resource to route traffic to the `ratings` service in the **Bookinfo** demo app.

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: ratings-vs
    namespace: default
  spec:
    hosts:
      - ratings
    http:
      - route:
          - destination:
              host: ratings
              subset: v2
  ```

### Step 02: Apply the VirtualService
- Apply the `VirtualService`
- This will route all traffic for the `ratings` service to version `v2`.

  ```bash
  kubectl apply -f ratings-virtualservice.yaml
  ```

### Step 03: Verify the Routing

- You can use Kiali to visualize the traffic flow and verify that the routing is happening as expected. 
- The Kiali dashboard should reflect the new route configuration for `ratings`.

---


## Conclusion 

- You have now successfully installed Istio and Kiali, set up a service mesh, and visualized your network's behavior. 
- The combination of Istio's powerful traffic management features and Kiali's intuitive visualization interface makes it easier to manage and monitor microservices in a Kubernetes cluster.
