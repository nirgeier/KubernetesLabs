# Lab 06 - Data Store: Secrets and ConfigMaps

## Overview

In this lab we will learn how to manage application configuration in Kubernetes using **Secrets** and **ConfigMaps**.

| Resource       | Purpose                                                      |
| -------------- | ------------------------------------------------------------ |
| **Secret**     | Stores sensitive data (passwords, tokens, certificates, API keys) encoded in Base64 |
| **ConfigMap**  | Stores non-sensitive configuration data (feature flags, connection strings, config files) |

### What You Will Learn

- How to create Secrets and ConfigMaps (imperative & declarative)
- How to inject configuration into pods via **environment variables**
- How to mount configuration as **files/volumes**
- How to update and rotate Secrets/ConfigMaps
- Key differences between Secrets and ConfigMaps
- Best practices for managing configuration in Kubernetes

### Prerequisites

- A running Kubernetes cluster (`kubectl cluster-info` should work)
- `kubectl` configured against the cluster
- Docker installed (optional — only needed if you want to build the demo image yourself)

---

## 01. Create namespace

```sh
# If the namespace already exists and contains data from previous steps, let's clean it
kubectl delete namespace codewizard --ignore-not-found

# Create the desired namespace [codewizard]
kubectl create namespace codewizard
```

!!! warning "Note"

    - **You can skip section 02 if you don't wish to build and push your own Docker container.**
    - **A pre-built image `nirgeier/k8s-secrets-sample` is available on Docker Hub.**

---

## 02. Build the demo Docker container (Optional)

##### 1. Write the server code

- For this demo we use a tiny Node.js HTTP server that reads configuration from environment variables and returns them in the response.
- Source file: [resources/server.js](resources/server.js)

```js
//
// server.js
//
const
  // Get those values in runtime.
  // The variables will be passed from the Dockerfile and later on from K8S ConfigMap/Secret
  language = process.env.LANGUAGE,
  token    = process.env.TOKEN;

require("http")
  .createServer((request, response) => {
    response.write(`Language: ${language}\n`);
    response.write(`Token   : ${token}\n`);
    response.end(`\n`);
  })
  // Set the default port to 5000
  .listen(process.env.PORT || 5000);
```

---

##### 2. Write the Dockerfile

- If you wish, you can skip this and use the existing image: `nirgeier/k8s-secrets-sample`
- Source file: [resources/Dockerfile](resources/Dockerfile)

```Dockerfile
# Base Image
FROM        node

# Exposed port - same port is defined in server.js
EXPOSE      5000

# The "configuration" which we pass in runtime
# The server will "read" those variables at run time and will print them out
ENV         LANGUAGE    Hebrew
ENV         TOKEN       Hard-To-Guess

# Copy the server to the container
COPY        server.js .

# Start the server
ENTRYPOINT  node server.js
```

---

##### 3. Build the Docker container

```sh
# Replace `nirgeier` with your own Docker Hub username
docker build -t nirgeier/k8s-secrets-sample ./resources/
```

---

##### 4. Test the container locally

```sh
# Run the container
docker run -d -p 5000:5000 --name server nirgeier/k8s-secrets-sample

# Get the response — values should come from the Dockerfile ENVs
curl 127.0.0.1:5000

# Expected response:
# Language: Hebrew
# Token   : Hard-To-Guess
```

- Stop and remove the container when done:

```sh
docker rm -f server
```

- (Optional) Push the container to your Docker Hub account:

```sh
docker push nirgeier/k8s-secrets-sample
```

---

## 03. Deploy with hardcoded environment variables

In this step we will deploy the container with environment variables defined **directly in the YAML** — no Secrets or ConfigMaps yet.

##### 1. Review the deployment & service file

- Source file: [resources/variables-from-yaml.yaml](resources/variables-from-yaml.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codewizard-secrets
  namespace: codewizard
spec:
  replicas: 1
  selector:
    matchLabels:
      name: codewizard-secrets
  template:
    metadata:
      labels:
        name: codewizard-secrets
    spec:
      containers:
        - name: secrets
          image: nirgeier/k8s-secrets-sample
          imagePullPolicy: Always
          ports:
            - containerPort: 5000
          env:
            - name: LANGUAGE
              value: Hebrew
            - name: TOKEN
              value: Hard-To-Guess2
          resources:
            limits:
              cpu: "500m"
              memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: codewizard-secrets
  namespace: codewizard
spec:
  selector:
    name: codewizard-secrets
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```

---

##### 2. Deploy to cluster

```sh
kubectl apply -f resources/variables-from-yaml.yaml
```

---

##### 3. Test the app

```sh
# Get the pod name
kubectl get pods -n codewizard

# Test the response directly from the pod (no need for a separate container)
kubectl exec -it -n codewizard \
  $(kubectl get pod -n codewizard -l name=codewizard-secrets -o jsonpath='{.items[0].metadata.name}') \
  -- sh -c "curl -s localhost:5000"

# Expected response:
# Language: Hebrew
# Token   : Hard-To-Guess2
```

!!! info "Why not use the Service?"
    The Service makes the app accessible to other pods in the cluster. For quick testing, we can `exec` into the pod directly.

    In a real environment you would use the service DNS name: `codewizard-secrets.codewizard.svc.cluster.local:5000`

---

## 04. Using Secrets & ConfigMaps (Imperative)

Now let's externalize the configuration into proper Kubernetes resources.

##### 1. Create a Secret and a ConfigMap

```sh
# Create the secret (imperative)
#   Key   = TOKEN
#   Value = Hard-To-Guess3
kubectl create secret generic token \
  -n codewizard \
  --from-literal=TOKEN=Hard-To-Guess3

# Create the config map (imperative)
#   Key   = LANGUAGE
#   Value = English
kubectl create configmap language \
  -n codewizard \
  --from-literal=LANGUAGE=English
```

---

##### 2. Verify the resources were created

```sh
# List secrets and config maps
kubectl get secrets,cm -n codewizard

# View the secret details (note: data is Base64-encoded)
kubectl describe secret token -n codewizard

# View the config map details (note: data is plain text)
kubectl describe cm language -n codewizard
```

---

##### 3. Decode a Secret value

Secrets are stored as Base64-encoded strings. To view the actual value:

```sh
# Get the raw Base64 value
kubectl get secret token -n codewizard -o jsonpath='{.data.TOKEN}'

# Decode it
kubectl get secret token -n codewizard -o jsonpath='{.data.TOKEN}' | base64 -d
# Output: Hard-To-Guess3
```

!!! warning "Important"
    Base64 is **encoding**, not **encryption**. Anyone with access to the Secret resource can decode it.
    For real security, consider using:

    - [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
    - [External Secrets Operator](https://external-secrets.io/)
    - [HashiCorp Vault](https://www.vaultproject.io/)
    - Enabling [encryption at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) for etcd

---

## 05. Inject Secrets & ConfigMaps as environment variables

##### 1. Update the deployment to reference Secret & ConfigMap

- Source file: [resources/variables-from-secrets.yaml](resources/variables-from-secrets.yaml)
- The key change is in the `env` section — instead of hardcoded values, we reference the ConfigMap and Secret:

```yaml
  env:
    - name: LANGUAGE
      valueFrom:
        configMapKeyRef:    # Read from the ConfigMap
          name: language    # The ConfigMap name
          key:  LANGUAGE    # The key inside the ConfigMap
    - name: TOKEN
      valueFrom:
        secretKeyRef:       # Read from the Secret
          name: token       # The Secret name
          key:  TOKEN       # The key inside the Secret
```

---

##### 2. Apply the updated deployment

```sh
kubectl apply -f resources/variables-from-secrets.yaml
```

---

##### 3. Test the changes

```sh
# Wait for the new pod to be ready
kubectl rollout status deployment/codewizard-secrets -n codewizard

# Test the response
kubectl exec -it -n codewizard \
  $(kubectl get pod -n codewizard -l name=codewizard-secrets -o jsonpath='{.items[0].metadata.name}') \
  -- sh -c "curl -s localhost:5000"

# Expected response:
# Language: English
# Token   : Hard-To-Guess3
```

The values now come from the ConfigMap and Secret instead of being hardcoded!

---

## 06. Create Secrets & ConfigMaps declaratively (YAML)

Instead of imperative `kubectl create` commands, you can define Secrets and ConfigMaps in YAML files.

##### 1. Secret YAML

- Source file: [resources/secret.yaml](resources/secret.yaml)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: token
data:
  # Base64-encoded value of "Hard-To-Guess3"
  # echo -n "Hard-To-Guess3" | base64
  TOKEN: SGFyZC1Uby1HdWVzczM=
type: Opaque
```

##### 2. Using `stringData` (plain text — recommended for readability)

You can also use `stringData` to avoid manual Base64 encoding. Kubernetes will encode it for you:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: token
stringData:
  TOKEN: Hard-To-Guess3
type: Opaque
```

##### 3. ConfigMap YAML

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: language
data:
  LANGUAGE: English
```

##### 4. Apply declarative resources

```sh
# Apply the secret (delete existing one first to avoid conflicts)
kubectl delete secret token -n codewizard --ignore-not-found
kubectl apply -n codewizard -f resources/secret.yaml

# Verify
kubectl get secret token -n codewizard -o jsonpath='{.data.TOKEN}' | base64 -d
# Output: Hard-To-Guess3
```

---

## 07. Mount Secrets & ConfigMaps as volumes

Besides environment variables, you can mount Secrets and ConfigMaps as **files** inside the container.
This is useful for configuration files, certificates, or any data that should appear as files.

##### 1. Create a ConfigMap with a configuration file

```sh
# Create a ConfigMap from a literal that will be mounted as a file
kubectl create configmap app-config \
  -n codewizard \
  --from-literal=app.properties="server.port=5000
server.language=English
feature.debug=true"
```

##### 2. Mount the ConfigMap as a volume

Add this to your deployment spec (the full file is shown for clarity):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codewizard-secrets
  namespace: codewizard
spec:
  replicas: 1
  selector:
    matchLabels:
      name: codewizard-secrets
  template:
    metadata:
      labels:
        name: codewizard-secrets
    spec:
      containers:
        - name: secrets
          image: nirgeier/k8s-secrets-sample
          imagePullPolicy: Always
          ports:
            - containerPort: 5000
          env:
            - name: LANGUAGE
              valueFrom:
                configMapKeyRef:
                  name: language
                  key:  LANGUAGE
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: token
                  key:  TOKEN
          # Mount the ConfigMap as a file
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
              readOnly: true
            - name: secret-volume
              mountPath: /etc/secrets
              readOnly: true
          resources:
            limits:
              cpu: "500m"
              memory: "256Mi"
      volumes:
        - name: config-volume
          configMap:
            name: app-config
        - name: secret-volume
          secret:
            secretName: token
```

##### 3. Verify the mounted files

```sh
# Exec into the pod and check the mounted files
POD=$(kubectl get pod -n codewizard -l name=codewizard-secrets -o jsonpath='{.items[0].metadata.name}')

# View secret and config files
kubectl exec -it -n codewizard "$POD" -- sh -c  \
  "echo '--- ConfigMap file ---';               \
   cat /etc/config/app.properties;              \
   echo;                                        \
   echo '--- Secret file ---';                  \
   cat /etc/secrets/TOKEN"
```

!!! info "Volume Mounts vs Environment Variables"
    | Feature | Environment Variables | Volume Mounts |
    |---|---|---|
    | Update method | Pod restart required | Auto-updated (with delay) |
    | Best for | Simple key-value pairs | Config files, certificates |
    | File format | N/A | Each key becomes a file |

---

## 08. Updating Secrets & ConfigMaps

!!! warning "Important"
    Pods **do not** automatically restart when Secrets or ConfigMaps change.

    - **Environment variables**: Require a pod restart to pick up new values
    - **Volume mounts**: Are eventually updated automatically (kubelet sync period, typically ~60s)

##### 1. Update an existing Secret

```sh
# Use dry-run + replace to update an existing secret
kubectl create secret generic token \
  -n codewizard \
  --from-literal=TOKEN=NewToken123 \
  -o yaml --dry-run=client | kubectl replace -f -
```

##### 2. Restart the pods to pick up the changes

```sh
# Rolling restart — zero downtime
kubectl rollout restart deployment/codewizard-secrets -n codewizard

# Wait for rollout to complete
kubectl rollout status deployment/codewizard-secrets -n codewizard
```

##### 3. Verify the new values

```sh
kubectl exec -it -n codewizard \
  $(kubectl get pod -n codewizard -l name=codewizard-secrets -o jsonpath='{.items[0].metadata.name}') \
  -- sh -c "curl -s localhost:5000"

# Expected response:
# Language: English
# Token   : NewToken123
```

---

## 09. Immutable Secrets & ConfigMaps

Starting from Kubernetes v1.21, you can mark Secrets and ConfigMaps as **immutable**.
This prevents accidental (or malicious) modifications and improves cluster performance.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: stable-config
data:
  VERSION: "1.0"
immutable: true     # <-- Cannot be changed once created
```

```sh
# Once applied, attempting to modify this ConfigMap will fail:
# error: configmaps "stable-config" is immutable
```

!!! info "When to use immutable resources"
    - Application configuration that should never change after deployment
    - Certificates or credentials tied to a specific release
    - Improves performance: kubelet skips watching for updates on immutable resources

---

## 10. Cleanup

```sh
# Delete all resources created in this lab
kubectl delete namespace codewizard --ignore-not-found
```

---

## Summary

| Concept | Description |
| --- | --- |
| **Secret** | Stores sensitive data as Base64-encoded key-value pairs |
| **ConfigMap** | Stores non-sensitive configuration as plain key-value pairs |
| **Imperative creation** | `kubectl create secret/configmap` — quick for testing |
| **Declarative creation** | YAML files with `data:` / `stringData:` — version-controlled |
| **Env injection** | `valueFrom.secretKeyRef` / `valueFrom.configMapKeyRef` |
| **Volume mount** | Mount as files inside the pod — auto-updates for volume mounts |
| **Immutable** | `immutable: true` — prevents changes, improves performance |
| **Updating** | Use `dry-run=client` + `replace`, then `rollout restart` for env vars |

### Key Takeaways

1. **Never** hardcode sensitive values in Deployment YAML files
2. **Secrets are not encrypted** by default — they are only Base64-encoded
3. **ConfigMaps** are for non-sensitive data; **Secrets** are for sensitive data
4. **Volume-mounted** ConfigMaps/Secrets auto-update; **env vars** require pod restart
5. Use **immutable** resources when values should never change after deployment
6. In production, consider using external secret management tools (Vault, Sealed Secrets, etc.)

