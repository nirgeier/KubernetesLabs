 



---

# Istio

Istio is an open-source service mesh that provides a way to manage microservices traffic, security, and observability in a Kubernetes cluster.

---

## Istio and Kiali
- This guide provides a detailed walkthrough on installing and configuring **Istio**  and **Kiali**  on a Kubernetes cluster. 
- We will also learn how to visualize your service mesh with Istio and Kiali and create a demo **Istio VirtualService**.
  
---


## 01. Introduction 

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
  | **Telemetry & Observability**       | Istio collects metrics, logs, and traces for monitoring service's performance and behavior. It integrates with tools like Prometheus, Grafana, and Jaeger.             |
  | **Distributed Tracing**             | Istio integrates with tracing systems like **Jaeger** and **Zipkin** to provide end-to-end tracing for debugging and monitoring service interactions.                   |
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

---

### `Kiali`

- **Kiali**  is a graphical user interface (GUI) for `Istio`. 
- It helps you visualize the service mesh and provides insights on how microservices are interacting with each other. 
- `Kiali` integrates deeply with Istio, allowing you to view:
    - The **service mesh topology**, showing services, traffic flow, and dependencies.
    - Metrics like request rates, latencies, and error rates.
    - **Distributed tracing**  (if enabled) for better debugging and troubleshooting.
    - **Istio configuration**  to visualize resources like VirtualServices, DestinationRules, and more.

- `Kiali` simplifies the operation of `Istio` by offering an intuitive way to manage and visualize your service mesh.


---

## Prerequisites

Before starting this lab, ensure you have the following prerequisites:

- **Kubernetes Cluster**: A running Kubernetes cluster (e.g., Minikube, Kind, Docker Desktop, or a cloud-based cluster like EKS, GKE, or AKS). The cluster should have at least 4 CPU cores and 8GB RAM for the demo profile.
- **kubectl**: The Kubernetes command-line tool installed and configured to access your cluster. Verify with `kubectl version`.
- **Helm**: Helm package manager (version 3.x) installed. Verify with `helm version`.
- **curl and bash**: For downloading and running installation scripts.
- **Permissions**: Sufficient cluster permissions to install CRDs, create namespaces, and manage resources.
- **Internet Access**: Required for downloading Istio and Kiali binaries.

If you don't have a cluster, you can set up a local one using Minikube or Kind. For example, with Minikube:

```bash
minikube start --cpus=4 --memory=8192
```

---

## Part 01 - Installing Istio and Kiali 

### Step 01: Install Istio Using Istioctl

- Istio supplies an installer that downloads the latest release and installs it.
- Go to the [Istio releases page](https://github.com/istio/istio/releases) and download the latest version of Istio. 
- Alternatively, use `istioctl` to install Istio, as follows:

  ```bash
  # Install Istio using istioctl
  echo  "Installing Istio..."
  curl  -L https://istio.io/downloadIstio | sh -
  cd    istio-*
  
  # Add bin directory to your $PATH
  export PATH=$PWD/bin:$PATH

  # Install istio with all features enabled (demo profile)
  istioctl install --set profile=demo -y
  ```

- The `demo` profile installs Istio with all features enabled, including:
  - Istio control plane (`istiod`)
  - Ingress and egress gateways
  - Telemetry components (Prometheus, Grafana, Jaeger)
  - Security features (Citadel for certificates)
- This profile is suitable for learning and development but not recommended for production due to resource requirements.
 
 
### Step 02: Verify Istio installation

- Check the Istio system components in the `istio-system` namespace:

```bash
# Verify Istio installation
kubectl get pods -n istio-system
```

- You should see several pods, including the Istio control plane components like: 
    - `istiod`
    - `istio-ingressgateway`
    - `istio-egressgateway`
  

```bash
kubectl get pods -n istio-system
```


  ```plaintext
  NAME                                    READY   STATUS    RESTARTS   AGE
  istio-egressgateway-684f5dc857-bzww6    1/1     Running   0          21m
  istio-ingressgateway-6b5bd79c5c-9n8tg   1/1     Running   0          21m
  istiod-68885d595-vv2ft                  1/1     Running   0          22m
  ```

### Step 03: Install Kiali

- We will install Kiali using Helm, which is the recommended way for production deployments.

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

- Kiali will be installed in the `istio-system` namespace with anonymous authentication for demo purposes. 
- In production, configure proper authentication methods like OAuth or token-based auth.

### Step 04: Verify Kiali installation

- Once installed, check the status of `Kiali`:

```bash
kubectl get pods -n istio-system
```

- You should see the `Kiali` pod running, along with the `Istio` components from previous step.

```plaintext
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-684f5dc857-bzww6    1/1     Running   0          28m
istio-ingressgateway-6b5bd79c5c-9n8tg   1/1     Running   0          28m
istiod-68885d595-vv2ft                  1/1     Running   0          28m
kiali-68ccc848b6-j4q28                  1/1     Running   0          27m
```

---

## Part 02 - Viewing the Network with Istio 

- `Istio` uses a sidecar proxy model, where an envoy proxy is deployed alongside each microservice pod. 
- This proxy intercepts and manages traffic between the services.

### Step 05: Enable Istio Injection

- You need to enable **Istio sidecar injection** for your Kubernetes namespace. 
- This will ensure that new pods in the `default` namespace will automatically have the envoy proxy sidecar injected.
- For example, to enable injection in the `default` namespace:

  ```bash
  kubectl label namespace default istio-injection=enabled
  ```

### Step 06: Deploy Sample Application

- To see `Istio` in action, deploy a sample application, such as **Bookinfo**, which is available in `Istio`'s demo repository.
  
  ```bash
  # Deploy the sample application supplied by istio
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  ```

### Step 07: Verify the Sample Application

- To check that the application pods are running, execute the following command:

  ```bash
  kubectl get pods
  ```
  
### Step 08: Expose the Application

- To expose the application via `Istio's` ingress gateway, create an `Istio` **Gateway**  and **VirtualService** .

  ```bash
  # This will expose the 'Bookinfo' application to the external world via Istio ingress gateway.
  kubectl   apply -f \
            samples/bookinfo/networking/bookinfo-gateway.yaml
  ```

---


## Part 03 - Visualizing the Network with Kiali 

### Step 09: Access Kiali Dashboard 

- Once `Kiali` is installed, you can access its dashboard. 
- First, port-forward to the `Kiali` service (keep this command running in a separate terminal):

  ```bash
  kubectl   port-forward        \
            -n istio-system     \
            svc/kiali 20001:20001
  ```

- **Note**: Keep this port-forward command running. If you stop it, the connection will be lost.
- Now, open your browser and navigate to [http://localhost:20001](http://localhost:20001)
  - **Username**: `admin` (if authentication is enabled)
  - **Password**: (Leave blank if anonymous access is enabled)
- It may take a few minutes for Kiali to fully initialize after installation. 
- If you see a loading screen, wait and refresh.

### Step 10: Explore the Service Mesh Topology 

- Once inside the `Kiali` dashboard, open the `Mesh` View
- You will see a **graph**  of your services in the mesh.
- The graph shows the interactions between microservices, along with traffic flows, success/error rates, and latency.
- You can use the `Kiali` interface to:
    - **Zoom in/out**  of the topology.
    - View detailed metrics for each service.
    - Understand the traffic flow, including retries, timeouts, and error rates.


---

## Part 04: Creating a Demo Istio VirtualService 

- In `Istio`, **VirtualServices**  are used to define the routing rules for your services.
- They allow you to specify how traffic should be routed to different versions (subsets) of your services based on various criteria like HTTP headers, URI paths, or weights.
- This enables advanced traffic management features like canary deployments, A/B testing, and blue-green deployments.

### Step 11: Define a VirtualService
- Create a `VirtualService` resource to route traffic to the `reviews` service in the **Bookinfo** demo app.
- This example routes all traffic to the `reviews` service to version `v2` (which shows black stars).

**Important:** Subsets like `v1`/`v2`/`v3` are defined via `DestinationRule` resources. Apply the Bookinfo destination rules first:

  ```bash
  kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
  ```

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: reviews-vs
    namespace: default
  spec:
    hosts:
      - reviews
    http:
      - route:
          - destination:
              host: reviews
              subset: v2
  ```

- **Explanation**:
  - `hosts`: Specifies which service this VirtualService applies to
  - `http.route.destination`: Defines where traffic should be sent
  - `subset: v2`: Routes to the v2 version of the reviews service

### Step 12: Apply the VirtualService
- Apply the `VirtualService`.
- This will route all traffic for the `reviews` service to version `v2`.

  ```bash
  kubectl apply -f ratings-virtualservice.yaml
  ```

### Step 13: Verify the Routing

- You can verify the routing by accessing the Bookinfo application and checking the ratings display.
- First, port-forward the Istio ingress gateway:

  ```bash
  kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
  ```

- Then visit [http://localhost:8080/productpage](http://localhost:8080/productpage) in your browser.
- Refresh the page multiple times - you should see the `reviews` section show black stars (v2).
- You can use `Kiali` to visualize the traffic flow and verify that routing is happening as expected.
- The `Kiali` dashboard should reflect the new route configuration for `ratings`.

---


## Conclusion 

- You have now successfully installed `Istio` and `Kiali`, set up a service mesh, and visualized your network's behavior. 
- The combination of `Istio's` powerful traffic management features and `Kiali's` intuitive visualization interface makes it easier to manage and monitor microservices in a Kubernetes cluster.

---

## Running the Demo Script

To automate the entire lab process, you can use the provided `demo.sh` script:

```bash
# Navigate to the demo directory
cd demo/scripts

# Run the demo script
./demo.sh
```

The script will:
- Check prerequisites (kubectl, helm, cluster access)
- Download and install Istio with the demo profile
- Install Kiali with anonymous authentication
- Enable sidecar injection in the default namespace
- Deploy the Bookinfo sample application
- Expose the application via Istio gateway
- Create a demo VirtualService for traffic routing
- Create a demo namespace with Nginx and HTTPD pods that curl each other every 3 seconds

After running the script, follow the on-screen instructions to access the application and Kiali dashboard.

**Note**: The script requires internet access for downloading Istio and may take several minutes to complete. Ensure your cluster has sufficient resources (4+ CPUs, 8GB+ RAM) for the demo profile.

---

## Demo Suite

For a more comprehensive demo experience, use the organized demo suite in the `demo/` directory:

```bash
# Navigate to demo directory
cd demo

# Run specific demo
./run-demo.sh basic      # Basic Istio setup
./run-demo.sh services   # Custom services demo
./run-demo.sh faults     # Network fault injection
./run-demo.sh nginx      # Nginx-HTTPD demo
./run-demo.sh all        # Run all demos

# Cleanup
./run-demo.sh cleanup    # Remove all demos
```

See `demo/README.md` for detailed information about each demo.

- Demo 01 (basic setup): `demo/01-basic-setup/`
- Demo 02 (traffic splitting between 3 pods): `demo/02-traffic-splitting-3pods/`

---

## Cleanup

To remove Istio and all related resources:

```bash
# Uninstall Istio
istioctl uninstall --purge -y

# Remove Kiali
helm uninstall kiali-server -n istio-system

# Delete the istio-system namespace
kubectl delete namespace istio-system

# Remove sample application
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml

# Remove demo namespace
kubectl delete namespace demo
```

---

## Part 05: Demo Namespace with Nginx and HTTPD

This part demonstrates creating a custom demo namespace with Nginx and HTTPD pods that communicate with each other.

### Step 14: Create Demo Namespace

```bash
kubectl create namespace demo
kubectl label namespace demo istio-injection=enabled
```

Alternatively, apply the provided YAML files:

```bash
kubectl apply -f nginx-demo.yaml
kubectl apply -f httpd-demo.yaml
```

### Step 15: Deploy Nginx with Curl Loop

Create a deployment for Nginx that runs the web server and curls the HTTPD service every 3 seconds:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
        - |
          nginx -g 'daemon off;' &
          while true; do
            echo "$(date): Nginx curling httpd" >> /var/log/nginx/curl.log
            curl -s --max-time 5 http://httpd.demo.svc.cluster.local >> /var/log/nginx/curl.log 2>&1
            sleep 3
          done
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/nginx
      volumes:
      - name: log-volume
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: demo
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### Step 16: Deploy HTTPD with Curl Loop

Create a deployment for HTTPD that runs the web server and curls the Nginx service every 3 seconds:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpd
  template:
    metadata:
      labels:
        app: httpd
    spec:
      containers:
      - name: httpd
        image: httpd:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
        - |
          httpd -D FOREGROUND &
          while true; do
            echo "$(date): HTTPD curling nginx" >> /usr/local/apache2/logs/curl.log
            curl -s --max-time 5 http://nginx.demo.svc.cluster.local >> /usr/local/apache2/logs/curl.log 2>&1
            sleep 3
          done
        volumeMounts:
        - name: log-volume
          mountPath: /usr/local/apache2/logs
      volumes:
      - name: log-volume
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: httpd
  namespace: demo
spec:
  selector:
    app: httpd
  ports:
  - port: 80
    targetPort: 80
```

### Step 17: Verify the Demo

```bash
# Check pods
kubectl get pods -n demo

# Check logs to see curl requests
kubectl logs -n demo deployment/nginx
kubectl logs -n demo deployment/httpd

# Port-forward to access the services
kubectl port-forward -n demo svc/nginx 8081:80
kubectl port-forward -n demo svc/httpd 8082:80

# Access in browser:
# Nginx: http://localhost:8081
# HTTPD: http://localhost:8082
```

### Step 18: Observe Traffic in Kiali

With Istio injection enabled, you can observe the traffic between Nginx and HTTPD in the Kiali dashboard. The services will show communication patterns as they curl each other every 3 seconds.
