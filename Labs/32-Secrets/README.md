---

# Kubernetes Secrets

- Welcome to the Kubernetes `Secrets` hands-on lab! In this tutorial, you'll learn everything about Kubernetes Secrets -- how to create, manage, consume, secure, and rotate them.
- Secrets are first-class Kubernetes objects designed to hold sensitive data such as passwords, OAuth tokens, TLS certificates, and SSH keys.
- You'll gain practical experience creating Secrets imperatively and declaratively, mounting them into Pods as environment variables and volumes, working with TLS and docker-registry Secrets, using projected volumes, making Secrets immutable, and enabling encryption at rest.

---

## What will we learn?

- What Kubernetes Secrets are and why they exist
- The different types of Secrets and when to use each one
- How Secrets differ from ConfigMaps
- How to create Secrets imperatively (from literals, files, and env-files)
- How to create Secrets declaratively using YAML manifests
- How to mount Secrets as environment variables in Pods
- How to mount Secrets as files (volumes) in Pods
- How to create and use `docker-registry` Secrets for private image registries
- How to create and use TLS Secrets for HTTPS termination
- How to use projected volumes to combine Secrets and ConfigMaps
- How to make Secrets immutable for safety and performance
- How to rotate Secrets and trigger Pod restarts
- How to enable encryption at rest with `EncryptionConfiguration`
- Security best practices and common pitfalls

---

## Official Documentation & References

| Resource                                | Link                                                                                                                                                   |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Kubernetes Secrets                      | [kubernetes.io/docs/concepts/configuration/secret](https://kubernetes.io/docs/concepts/configuration/secret/)                                           |
| Managing Secrets with kubectl           | [kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/) |
| Managing Secrets with Config File       | [kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/) |
| Distribute Credentials via Secrets      | [kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/) |
| Encrypting Secrets at Rest             | [kubernetes.io/docs/tasks/administer-cluster/encrypt-data](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)                           |
| Good Practices for Secrets             | [kubernetes.io/docs/concepts/security/secrets-good-practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)                     |
| Projected Volumes                      | [kubernetes.io/docs/concepts/storage/projected-volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/)                                 |
| Pull Image from Private Registry       | [kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| TLS Secrets                            | [kubernetes.io/docs/concepts/configuration/secret/#tls-secrets](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)                   |
| External Secrets Operator              | [external-secrets.io](https://external-secrets.io/)                                                                                                     |
| Sealed Secrets (Bitnami)               | [github.com/bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)                                                                |
| HashiCorp Vault                        | [vaultproject.io](https://www.vaultproject.io/)                                                                                                         |

---

## Introduction

### What Are Kubernetes Secrets?

- A `Secret` is a Kubernetes object that holds a small amount of sensitive data, such as a password, a token, or a key.
- Secrets decouple sensitive information from Pod specs and container images, reducing the risk of accidental exposure.
- Without Secrets, you would need to embed credentials directly in Pod manifests, Dockerfiles, or application code -- all of which are insecure practices.
- Secrets are stored in `etcd`, the Kubernetes cluster's key-value store, and are made available to Pods through environment variables or volume mounts.

### Secret Types

Kubernetes supports several built-in Secret types, each designed for a specific use case:

| Type                                  | Description                                                 | Usage                                   |
|---------------------------------------|-------------------------------------------------------------|-----------------------------------------|
| `Opaque`                              | Generic Secret for arbitrary key-value pairs (default type) | Passwords, API keys, connection strings |
| `kubernetes.io/dockerconfigjson`      | Docker registry credentials for pulling private images      | `imagePullSecrets` in Pod specs         |
| `kubernetes.io/tls`                   | TLS certificate and private key pair                        | HTTPS termination, Ingress TLS          |
| `kubernetes.io/basic-auth`            | Credentials for basic HTTP authentication                   | Username/password for HTTP auth         |
| `kubernetes.io/ssh-auth`              | SSH private key for authentication                          | Git clones, SSH connections             |
| `bootstrap.kubernetes.io/token`       | Bootstrap token for node joining                            | `kubeadm join` operations               |
| `kubernetes.io/service-account-token` | Service account token (auto-created by Kubernetes)          | Pod-to-API-server authentication        |

!!! note "Default Type"
    If you do not specify a `type` when creating a Secret, Kubernetes defaults to `Opaque`. This is the most common type and accepts any arbitrary data.

### Secrets vs. ConfigMaps

Both Secrets and ConfigMaps store configuration data, but they serve different purposes:

| Feature              | Secret                                                  | ConfigMap                                         |
| -------------------- | ------------------------------------------------------- | ------------------------------------------------- |
| **Purpose**          | Sensitive data (passwords, tokens, keys)                | Non-sensitive configuration (settings, properties) |
| **Data encoding**    | Values stored as base64-encoded strings                 | Values stored as plain text                        |
| **Size limit**       | 1 MiB per Secret                                        | 1 MiB per ConfigMap                                |
| **RBAC**             | Typically restricted with fine-grained RBAC              | Often more broadly accessible                      |
| **tmpfs mounting**   | Mounted in `tmpfs` (RAM) -- never written to disk on nodes | Mounted on disk                                  |
| **Encryption**       | Can be encrypted at rest in etcd                        | Not encrypted at rest                              |
| **Environment vars** | Supported via `secretKeyRef`                            | Supported via `configMapKeyRef`                    |
| **Volume mounts**    | Supported (files in tmpfs)                              | Supported (files on disk)                          |

!!! warning "Base64 Is NOT Encryption"
    Kubernetes stores Secret values as base64-encoded strings. Base64 is an **encoding** scheme, not an encryption algorithm. Anyone with `get` access to Secrets can decode them trivially with `base64 --decode`. Always combine Secrets with proper RBAC and encryption at rest.

### Secret Encoding: base64 vs. Encryption at Rest

Understanding the difference between encoding and encryption is critical:

- **base64 encoding**: Secrets stored in the `data` field must be base64-encoded. This is a reversible encoding (not encryption) that allows binary data to be represented as text. You can use the `stringData` field to provide plain-text values that Kubernetes will automatically base64-encode.
- **Encryption at rest**: By default, Secrets are stored **unencrypted** in etcd. Anyone with access to etcd can read all Secrets. To protect Secrets in etcd, you must enable encryption at rest using an `EncryptionConfiguration` resource and configure the API server to use it.

### Security Best Practices

!!! danger "Critical Security Considerations"
    1. **Enable RBAC**: Restrict who can `get`, `list`, and `watch` Secrets. A user who can `list` Secrets in a namespace can see all Secret data.
    2. **Enable encryption at rest**: Configure the API server with `--encryption-provider-config` to encrypt Secrets in etcd.
    3. **Avoid Secrets in Git**: Never commit Secret manifests with real credentials to version control. Use tools like Sealed Secrets, External Secrets Operator, or SOPS.
    4. **Use least privilege**: Grant only the minimum RBAC permissions needed. Avoid giving `*` (wildcard) access to Secrets.
    5. **Rotate Secrets regularly**: Establish a rotation schedule and automate the process.
    6. **Prefer volume mounts over env vars**: Environment variables can leak through crash dumps, logs, or child processes. Volume-mounted Secrets are more secure.
    7. **Use immutable Secrets**: Mark Secrets as `immutable: true` when the data should never change, improving security and API server performance.
    8. **Audit Secret access**: Enable Kubernetes audit logging to track who accesses Secrets and when.

### Secret Lifecycle

The following diagram illustrates how Secrets flow from creation to consumption in a Kubernetes cluster:

```mermaid
flowchart TB
    subgraph Creation ["Secret Creation"]
        A["kubectl create secret"] --> D["API Server"]
        B["YAML Manifest\n(stringData / data)"] --> D
        C["External Secrets\nOperator / Vault"] --> D
    end

    subgraph Storage ["Storage Layer"]
        D --> E{"Encryption\nat Rest?"}
        E -->|Yes| F["Encrypted in etcd"]
        E -->|No| G["Plain base64 in etcd"]
    end

    subgraph Consumption ["Pod Consumption"]
        F --> H["kubelet fetches Secret"]
        G --> H
        H --> I["Environment\nVariables"]
        H --> J["Volume Mounts\n(tmpfs)"]
        H --> K["imagePullSecrets"]
    end

    subgraph Pod ["Pod Runtime"]
        I --> L["Container Process\nreads env var"]
        J --> M["Container Process\nreads file"]
        K --> N["kubelet pulls\nprivate image"]
    end

    style Creation fill:#e1f5fe,stroke:#0277bd
    style Storage fill:#fff3e0,stroke:#ef6c00
    style Consumption fill:#e8f5e9,stroke:#2e7d32
    style Pod fill:#f3e5f5,stroke:#7b1fa2
```

---

## Prerequisites

- A running Kubernetes cluster (minikube, kind, k3d, Docker Desktop, or a cloud-managed cluster)
- `kubectl` installed and configured to communicate with your cluster
- `openssl` installed (for generating TLS certificates in Step 06)
- Basic familiarity with Kubernetes Pods, Deployments, and YAML manifests

Verify your cluster is accessible:

```bash
## Verify kubectl is configured and the cluster is reachable
kubectl cluster-info

## Verify you can list namespaces
kubectl get namespaces
```

---

# Lab

### Step 01 - Create the Lab Namespace

- Before we begin working with Secrets, let's create a dedicated namespace to keep our lab resources isolated.

```bash
## Create the secrets-lab namespace from the manifest file
kubectl apply -f manifests/namespace.yaml

## Verify the namespace was created
kubectl get namespace secrets-lab

## Set the default namespace for this lab session so we don't need
## to add -n secrets-lab to every command
kubectl config set-context --current --namespace=secrets-lab
```

!!! tip "Using a Dedicated Namespace"
    Working in a dedicated namespace makes cleanup easy -- just delete the namespace at the end and all resources are removed. It also provides an isolation boundary for RBAC policies.

---

### Step 02 - Create Secrets Imperatively

- The fastest way to create Secrets is using `kubectl create secret` directly from the command line.
- Kubernetes supports creating Secrets from literal values, from files, and from environment files.

#### From Literal Values

```bash
## Create an Opaque Secret with literal key-value pairs
## The --from-literal flag accepts key=value pairs
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='S3cur3P@ssw0rd!' \
  --from-literal=host=db.example.com \
  --from-literal=port=5432

## Verify the Secret was created
kubectl get secret db-credentials

## View the Secret details (values are base64-encoded)
kubectl get secret db-credentials -o yaml
```

!!! note "Quoting Special Characters"
    When using `--from-literal`, wrap values containing special characters (`$`, `!`, `@`, `#`, etc.) in **single quotes** to prevent shell interpretation. For example: `--from-literal=password='My$ecret!'`.

#### From Files

```bash
## Create sample credential files
echo -n "admin" > /tmp/username.txt
echo -n "S3cur3P@ssw0rd!" > /tmp/password.txt

## Create a Secret from files
## Each file becomes a key (filename) with the file contents as the value
kubectl create secret generic file-credentials \
  --from-file=/tmp/username.txt \
  --from-file=/tmp/password.txt

## Verify the Secret was created
kubectl get secret file-credentials -o yaml

## You can also specify a custom key name using key=path syntax
kubectl create secret generic file-credentials-custom \
  --from-file=db-user=/tmp/username.txt \
  --from-file=db-pass=/tmp/password.txt

## Verify the custom key names
kubectl get secret file-credentials-custom -o jsonpath='{.data}' | python3 -m json.tool

## Clean up temporary files
rm /tmp/username.txt /tmp/password.txt
```

!!! warning "Trailing Newlines"
    Use `echo -n` (without trailing newline) when creating files for Secrets. A trailing newline character will be included in the Secret value and can cause authentication failures.

#### From an Env File

```bash
## Create an env file with key=value pairs (one per line)
cat <<'EOF' > /tmp/app-secrets.env
DB_HOST=db.example.com
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=S3cur3P@ssw0rd!
API_KEY=sk-1234567890abcdef
EOF

## Create a Secret from the env file
## Each line becomes a separate key-value pair in the Secret
kubectl create secret generic env-credentials \
  --from-env-file=/tmp/app-secrets.env

## Verify the Secret keys match the env file entries
kubectl get secret env-credentials -o jsonpath='{.data}' | python3 -m json.tool

## Clean up
rm /tmp/app-secrets.env
```

#### Inspect the Created Secrets

```bash
## List all Secrets in the namespace
kubectl get secrets

## Describe a Secret to see metadata (values are hidden)
kubectl describe secret db-credentials

## Decode a specific value from a Secret
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode
echo  ## Add a newline for readability

## Decode ALL values from a Secret using a one-liner
kubectl get secret db-credentials -o json | \
  python3 -c "import json,sys,base64; \
  data=json.load(sys.stdin)['data']; \
  [print(f'{k}: {base64.b64decode(v).decode()}') for k,v in data.items()]"
```

---

### Step 03 - Create Secrets Declaratively

- For production workflows, you typically define Secrets in YAML manifests and manage them through GitOps pipelines.
- Kubernetes supports two fields for providing Secret data: `data` (base64-encoded) and `stringData` (plain text).

#### Using `stringData` (Recommended for Readability)

```bash
## Apply the Opaque Secret manifest that uses stringData
kubectl apply -f manifests/secret-opaque.yaml

## Verify the Secret was created
kubectl get secret app-credentials

## View the Secret -- notice that stringData values are now base64-encoded
## under the 'data' field (stringData is a write-only convenience field)
kubectl get secret app-credentials -o yaml
```

#### Using `data` (Base64-Encoded)

```bash
## When using the 'data' field, you must base64-encode values yourself
## Encode a value to base64
echo -n "my-secret-value" | base64
## Output: bXktc2VjcmV0LXZhbHVl

## Decode a base64 value back to plain text
echo "bXktc2VjcmV0LXZhbHVl" | base64 --decode
## Output: my-secret-value
```

```yaml
## Example: Secret using the 'data' field with pre-encoded values
## (You do NOT need to apply this -- it is shown for comparison)
apiVersion: v1
kind: Secret
metadata:
  name: base64-example
  namespace: secrets-lab
type: Opaque
data:
  ## Each value must be base64-encoded
  username: YWRtaW4=          ## base64("admin")
  password: UzNjdXIzUEBzc3cwcmQh  ## base64("S3cur3P@ssw0rd!")
```

!!! tip "`stringData` vs. `data`"
    - Use `stringData` for readability during development and when values are plain text.
    - Use `data` when you have already-encoded values or when generating manifests programmatically.
    - If both `stringData` and `data` contain the same key, the `stringData` value takes precedence.
    - After a Secret is created, Kubernetes always stores and returns values in the base64-encoded `data` field. The `stringData` field does not appear in `kubectl get secret -o yaml` output.

#### Verify the Data Is Base64-Encoded

```bash
## Retrieve the Secret and decode the username
kubectl get secret app-credentials -o jsonpath='{.data.username}' | base64 --decode
echo  ## Newline
## Output: admin

## Retrieve and decode the password
kubectl get secret app-credentials -o jsonpath='{.data.password}' | base64 --decode
echo  ## Newline
## Output: S3cur3P@ssw0rd!

## Retrieve and decode the database URL
kubectl get secret app-credentials -o jsonpath='{.data.database-url}' | base64 --decode
echo  ## Newline
## Output: postgres://admin:S3cur3P%40ssw0rd!@db-host:5432/mydb
```

---

### Step 04 - Mount Secrets as Environment Variables

- One of the most common ways to consume Secrets is by injecting them as environment variables into a container.
- The Pod references specific keys from a Secret using `secretKeyRef`.

```bash
## Ensure the app-credentials Secret exists (from Step 03)
kubectl get secret app-credentials

## Apply the Pod that mounts Secret values as environment variables
kubectl apply -f manifests/pod-env-secret.yaml

## Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/secret-env-demo --timeout=60s

## View the Pod logs to see the environment variables in action
kubectl logs secret-env-demo
```

Expected output:

```text
=== Secret values loaded as environment variables ===
DB_USERNAME=admin
DB_PASSWORD=S3cur3P@ssw0rd!
DATABASE_URL=postgres://admin:S3cur3P%40ssw0rd!@db-host:5432/mydb
=== Sleeping to keep pod alive for inspection ===
```

```bash
## You can also exec into the Pod and inspect the environment
kubectl exec secret-env-demo -- env | grep -E "DB_|DATABASE_"

## Verify a specific variable
kubectl exec secret-env-demo -- sh -c 'echo $DB_USERNAME'
```

#### Loading All Keys with `envFrom`

Instead of mapping individual keys, you can inject **all** keys from a Secret as environment variables:

```bash
## Create a Pod that loads all Secret keys as env vars using envFrom
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-envfrom-demo
  namespace: secrets-lab
spec:
  containers:
    - name: demo
      image: busybox:1.36
      command: ["sh", "-c", "env | sort | grep -v PATH && sleep 3600"]
      envFrom:
        - secretRef:
            name: db-credentials
          ## Optional: add a prefix to all env var names
          prefix: SECRET_
  restartPolicy: Never
EOF

## Wait for the Pod and check the environment variables
kubectl wait --for=condition=Ready pod/secret-envfrom-demo --timeout=60s
kubectl logs secret-envfrom-demo | grep SECRET_
```

!!! warning "Environment Variable Risks"
    Environment variables are visible in process listings (`/proc/<pid>/environ`), crash dumps, and may be logged by applications. For highly sensitive data (private keys, TLS certificates), prefer volume mounts over environment variables.

---

### Step 05 - Mount Secrets as Volumes

- Mounting Secrets as volumes creates files in the container's filesystem.
- Each key in the Secret becomes a file, and the file content is the decoded Secret value.
- Volume-mounted Secrets are stored in `tmpfs` (RAM-backed filesystem) and are never written to disk on the node.

```bash
## Ensure the app-credentials Secret exists
kubectl get secret app-credentials

## Apply the Pod that mounts Secret as a volume
kubectl apply -f manifests/pod-volume-secret.yaml

## Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/secret-volume-demo --timeout=60s

## View the Pod logs to see the mounted files
kubectl logs secret-volume-demo
```

Expected output:

```text
=== Secret files mounted as volume ===
--- Listing /etc/secrets ---
total 0
drwxrwx--T    2 root     root           120 ...  .
drwxr-xr-x    1 root     root            28 ...  ..
-r--------    1 root     root             5 ...  username
-r--------    1 root     root            16 ...  password
-r--------    1 root     root            52 ...  database-url
--- Contents of each file ---
/etc/secrets/database-url: postgres://admin:S3cur3P%40ssw0rd!@db-host:5432/mydb
/etc/secrets/password: S3cur3P@ssw0rd!
/etc/secrets/username: admin
```

```bash
## Exec into the Pod and read individual Secret files
kubectl exec secret-volume-demo -- cat /etc/secrets/username
kubectl exec secret-volume-demo -- cat /etc/secrets/password

## Verify file permissions (should be 0400 as set in the manifest)
kubectl exec secret-volume-demo -- ls -la /etc/secrets/

## Verify the mount is tmpfs (in-memory filesystem)
kubectl exec secret-volume-demo -- df -T /etc/secrets/
```

#### Mounting Specific Keys Only

You can select which keys to mount and control their file paths using the `items` field:

```bash
## Create a Pod that mounts only the password key with a custom filename
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-selective-mount
  namespace: secrets-lab
spec:
  containers:
    - name: demo
      image: busybox:1.36
      command: ["sh", "-c", "ls -la /etc/secrets/ && cat /etc/secrets/db-password && sleep 3600"]
      volumeMounts:
        - name: secret-vol
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secret-vol
      secret:
        secretName: app-credentials
        items:
          ## Only mount the 'password' key, renaming the file to 'db-password'
          - key: password
            path: db-password
            mode: 0400
  restartPolicy: Never
EOF

## Wait and verify
kubectl wait --for=condition=Ready pod/secret-selective-mount --timeout=60s
kubectl logs secret-selective-mount
```

!!! tip "Automatic Updates"
    When a Secret is updated, volume-mounted Secrets are **automatically updated** by the kubelet (with a delay of up to the kubelet sync period, typically 1-2 minutes). Environment variables are **NOT** updated -- the Pod must be restarted.

---

### Step 06 - Create and Use Docker Registry Secrets

- When pulling container images from a private registry, Kubernetes needs credentials.
- The `docker-registry` Secret type stores these credentials in the format that the kubelet expects.

```bash
## Create a docker-registry Secret
## Replace the placeholder values with your actual registry credentials
kubectl create secret docker-registry my-registry-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com

## View the created Secret
kubectl get secret my-registry-secret -o yaml

## The Secret contains a .dockerconfigjson key with the registry auth data
## Decode it to see the structure
kubectl get secret my-registry-secret \
  -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode | python3 -m json.tool
```

#### Using imagePullSecrets in a Pod

```bash
## Create a Pod that references the registry Secret for image pulling
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
  namespace: secrets-lab
spec:
  containers:
    - name: app
      image: your-registry.example.com/your-app:latest
      ports:
        - containerPort: 8080
  imagePullSecrets:
    - name: my-registry-secret
  restartPolicy: Never
EOF
```

#### Attaching imagePullSecrets to a ServiceAccount

Instead of adding `imagePullSecrets` to every Pod, you can attach it to a ServiceAccount so all Pods using that ServiceAccount automatically use the registry credentials:

```bash
## Create a ServiceAccount with the imagePullSecret attached
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: private-registry-sa
  namespace: secrets-lab
imagePullSecrets:
  - name: my-registry-secret
EOF

## Any Pod using this ServiceAccount will automatically pull from the private registry
## kubectl get serviceaccount private-registry-sa -o yaml
```

!!! tip "ServiceAccount Pattern"
    Attaching `imagePullSecrets` to a ServiceAccount is the recommended pattern for teams. It avoids repeating the Secret reference in every Pod spec and centralizes registry credential management.

---

### Step 07 - Create and Use TLS Secrets

- TLS Secrets hold a certificate and its associated private key.
- They are commonly used for HTTPS termination in Ingress controllers or directly in application Pods.

#### Generate a Self-Signed Certificate

```bash
## Generate a self-signed TLS certificate and private key using openssl
## This creates a certificate valid for 365 days for localhost
openssl req -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout /tmp/tls.key \
  -out /tmp/tls.crt \
  -subj "/CN=localhost/O=secrets-lab"

## Verify the certificate details
openssl x509 -in /tmp/tls.crt -text -noout | head -20
```

#### Create the TLS Secret

```bash
## Create a TLS Secret from the certificate and key files
## kubectl validates that the cert and key are valid and match
kubectl create secret tls tls-secret \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key

## Verify the Secret was created with the correct type
kubectl get secret tls-secret
## The TYPE column should show kubernetes.io/tls

## View the Secret structure
kubectl get secret tls-secret -o yaml
## It contains two keys: tls.crt and tls.key

## Clean up local files
rm /tmp/tls.crt /tmp/tls.key
```

#### Deploy Nginx with TLS

```bash
## Apply the nginx TLS pod and its ConfigMap
kubectl apply -f manifests/tls-pod.yaml

## Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/nginx-tls-demo --timeout=60s

## Test the HTTPS endpoint from inside the cluster
## The -k flag tells curl to accept the self-signed certificate
kubectl exec nginx-tls-demo -- curl -k https://localhost:443 2>/dev/null
## Output: TLS is working! Served by nginx with a self-signed certificate.

## Verify the certificate details served by nginx
kubectl exec nginx-tls-demo -- \
  sh -c "echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -subject -dates"
```

!!! note "TLS in Ingress"
    In production, TLS Secrets are typically referenced in Ingress resources rather than mounted directly in Pods. Ingress controllers handle TLS termination centrally. Tools like cert-manager can automate certificate issuance and renewal.

---

### Step 08 - Using Projected Volumes

- Projected volumes allow you to combine multiple volume sources into a single mount directory.
- This is useful when a container needs both Secrets and ConfigMaps accessible from the same path.

```bash
## Apply the projected volume demo (includes both a ConfigMap and a Pod)
kubectl apply -f manifests/pod-projected-volume.yaml

## Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/projected-volume-demo --timeout=60s

## View the Pod logs to see all projected files
kubectl logs projected-volume-demo
```

Expected output:

```text
=== Projected volume contents ===
--- Listing /etc/app-config ---
...
--- Secret: username ---
admin
--- Secret: password ---
S3cur3P@ssw0rd!
--- ConfigMap: app.properties ---
app.name=secrets-demo
app.version=1.0.0
app.environment=development
app.log.level=info
--- ConfigMap: feature-flags.json ---
{
  "enableNewUI": true,
  "enableBetaFeatures": false,
  "maxRetries": 3
}
=== All config and secrets unified under one mount ===
```

```bash
## Exec into the Pod and explore the projected mount
kubectl exec projected-volume-demo -- ls -la /etc/app-config/

## Read a specific file
kubectl exec projected-volume-demo -- cat /etc/app-config/app.properties
```

!!! tip "Projected Volume Sources"
    Projected volumes can combine: `secret`, `configMap`, `downwardAPI`, and `serviceAccountToken` sources. This is powerful for applications that expect all configuration in a single directory.

---

### Step 09 - Immutable Secrets

- Kubernetes supports marking Secrets as **immutable** starting from v1.21 (GA).
- Once a Secret is marked as `immutable: true`, its `data` and `stringData` fields cannot be updated.
- The only way to change an immutable Secret is to delete it and recreate it.

#### Benefits of Immutable Secrets

1. **Security**: Prevents accidental or malicious modifications to critical credentials
2. **Performance**: The kubelet does not need to set up watches for immutable Secrets, reducing API server load
3. **Reliability**: Guarantees that the Secret data remains consistent throughout its lifetime

```bash
## Apply the immutable Secret
kubectl apply -f manifests/immutable-secret.yaml

## Verify it was created
kubectl get secret immutable-api-key
kubectl get secret immutable-api-key -o jsonpath='{.immutable}'
echo  ## Newline
## Output: true
```

#### Attempt to Modify an Immutable Secret

```bash
## Try to update the immutable Secret -- this will FAIL
kubectl patch secret immutable-api-key \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/api-key", "value": "bmV3LWtleQ=="}]'

## Expected error:
## Error from server (Forbidden): secrets "immutable-api-key" is forbidden:
## field is immutable when `immutable` is set
```

```bash
## Also try editing -- this will also fail on save
## kubectl edit secret immutable-api-key
## (Uncomment and try if you want to see the error)

## The ONLY way to change an immutable Secret is to delete and recreate it
kubectl delete secret immutable-api-key
kubectl apply -f manifests/immutable-secret.yaml
```

!!! warning "Immutable Cannot Be Reversed"
    Once `immutable: true` is set on a Secret, you **cannot** change it back to `false`. The only option is to delete and recreate the Secret. Plan accordingly before marking Secrets as immutable.

---

### Step 10 - Secret Rotation and Pod Restart Strategies

- In production, credentials must be rotated regularly for security compliance.
- When a Secret is updated, volume-mounted Secrets are automatically refreshed, but environment variables are not.
- For environment variable-based Secrets, you need to trigger a Pod restart.

#### Update a Secret

```bash
## Update the db-credentials Secret with a new password
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='N3wR0t@tedP@ss!' \
  --from-literal=host=db.example.com \
  --from-literal=port=5432 \
  --dry-run=client -o yaml | kubectl apply -f -

## Verify the password was updated
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode
echo  ## Newline
## Output: N3wR0t@tedP@ss!
```

#### Verify Volume Mount Auto-Update

```bash
## If you still have the secret-volume-demo Pod running from Step 05,
## check that the mounted files reflect the new Secret data.
## (There may be a delay of up to the kubelet sync period, typically 1-2 minutes)

## Wait a moment for the kubelet to sync
sleep 120

## Check the updated file content
kubectl exec secret-volume-demo -- cat /etc/secrets/password 2>/dev/null || \
  echo "Pod secret-volume-demo is not running. Recreate it to test volume auto-update."
```

#### Trigger a Rolling Restart for Deployments

When Pods consume Secrets as environment variables, updating the Secret does not restart the Pod. Use one of these strategies:

```bash
## Strategy 1: kubectl rollout restart (simplest, requires Deployment/StatefulSet)
## Create a sample Deployment first
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-consumer
  namespace: secrets-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secret-consumer
  template:
    metadata:
      labels:
        app: secret-consumer
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh", "-c", "while true; do echo DB_PASSWORD=$DB_PASSWORD; sleep 30; done"]
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
EOF

## Wait for the Deployment to be ready
kubectl rollout status deployment/secret-consumer --timeout=60s

## Now trigger a rolling restart to pick up the updated Secret
kubectl rollout restart deployment/secret-consumer

## Wait for the rollout to complete
kubectl rollout status deployment/secret-consumer --timeout=60s

## Verify the new pods have the updated password
kubectl logs deployment/secret-consumer | head -5
```

```bash
## Strategy 2: Annotation-based trigger (useful in Helm/GitOps workflows)
## Add a hash of the Secret data as a pod annotation.
## When the Secret changes, the annotation changes, triggering a rollout.
SECRET_HASH=$(kubectl get secret db-credentials -o jsonpath='{.data}' | sha256sum | cut -d' ' -f1)

kubectl patch deployment secret-consumer \
  -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"secret-hash\":\"$SECRET_HASH\"}}}}}"

## Verify the annotation was added
kubectl get deployment secret-consumer -o jsonpath='{.spec.template.metadata.annotations}' | python3 -m json.tool
```

```bash
## Strategy 3: Automated rotation script
## This script updates a Secret and triggers a rolling restart

cat <<'SCRIPT'
#!/bin/bash
## rotate-secret.sh - Rotate a Secret and restart the consuming Deployment

SECRET_NAME="${1:?Usage: rotate-secret.sh <secret-name> <deployment-name>}"
DEPLOYMENT_NAME="${2:?Usage: rotate-secret.sh <secret-name> <deployment-name>}"
NAMESPACE="${3:-secrets-lab}"

## Generate a new password
NEW_PASSWORD=$(openssl rand -base64 24)

## Update the Secret
kubectl create secret generic "$SECRET_NAME" \
  --from-literal=username=admin \
  --from-literal=password="$NEW_PASSWORD" \
  --from-literal=host=db.example.com \
  --from-literal=port=5432 \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret '$SECRET_NAME' updated with new password."

## Trigger rolling restart
kubectl rollout restart deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
echo "Rolling restart triggered for deployment '$DEPLOYMENT_NAME'."

## Wait for rollout
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=120s
echo "Rotation complete."
SCRIPT
```

---

### Step 11 - Enable Encryption at Rest

- By default, Secrets are stored **unencrypted** in etcd.
- Encryption at rest ensures that Secrets are encrypted before being written to etcd.
- This step requires access to the control-plane node and the ability to modify kube-apiserver flags.

!!! danger "Control Plane Access Required"
    This step can only be performed on clusters where you have control-plane access (e.g., kubeadm clusters, bare-metal). Managed Kubernetes services (EKS, GKE, AKS) typically handle encryption at rest automatically or through their own configuration mechanisms.

#### Review the EncryptionConfiguration

```bash
## View the example EncryptionConfiguration
cat manifests/encryption-config.yaml
```

```yaml
## The EncryptionConfiguration specifies:
## - Which resources to encrypt (secrets)
## - Which encryption provider to use (aescbc)
## - The encryption key (base64-encoded 32-byte key)
## - A fallback identity provider (for reading unencrypted data)
```

#### Generate an Encryption Key

```bash
## Generate a random 32-byte encryption key and base64-encode it
head -c 32 /dev/urandom | base64
## Use this output as the 'secret' value in the EncryptionConfiguration
```

#### Apply Encryption (kubeadm clusters)

!!! warning "Cluster-Specific Instructions"
    The following steps apply to kubeadm-based clusters. For managed Kubernetes services, consult your provider's documentation.

```bash
## 1. Copy the EncryptionConfiguration to the control-plane node
## (Replace the key in the file with your generated key first!)
## sudo cp encryption-config.yaml /etc/kubernetes/encryption-config.yaml

## 2. Edit the kube-apiserver manifest to add the encryption flag
## sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
## Add under spec.containers.command:
##   - --encryption-provider-config=/etc/kubernetes/encryption-config.yaml
## Add under spec.containers.volumeMounts:
##   - name: encryption-config
##     mountPath: /etc/kubernetes/encryption-config.yaml
##     readOnly: true
## Add under spec.volumes:
##   - name: encryption-config
##     hostPath:
##       path: /etc/kubernetes/encryption-config.yaml
##       type: File

## 3. The kube-apiserver will restart automatically (it's a static Pod)
## Wait for it to come back up
## kubectl get pods -n kube-system -l component=kube-apiserver

## 4. Re-encrypt all existing Secrets so they are stored encrypted
## kubectl get secrets --all-namespaces -o json | kubectl replace -f -

## 5. Verify encryption is working by checking etcd directly
## ETCDCTL_API=3 etcdctl get /registry/secrets/default/my-secret \
##   --cacert=/etc/kubernetes/pki/etcd/ca.crt \
##   --cert=/etc/kubernetes/pki/etcd/server.crt \
##   --key=/etc/kubernetes/pki/etcd/server.key
## The output should show encrypted (non-readable) data prefixed with "k8s:enc:aescbc:v1:key1"
```

!!! tip "Managed Kubernetes Encryption"
    - **GKE**: Secrets are encrypted at rest by default. You can use customer-managed encryption keys (CMEK) via Cloud KMS.
    - **EKS**: Enable envelope encryption with AWS KMS through the `--encryption-config` flag in the cluster config.
    - **AKS**: Enable encryption at rest with customer-managed keys through Azure Key Vault.

---

# Exercises

The following exercises will test your understanding of Kubernetes Secrets.
Try to solve each exercise on your own before revealing the solution.

---

#### 01. Create a Secret from Multiple Files and Verify Its Content

Create a Secret named `multi-file-secret` from three separate files containing a username, password, and API token. Then verify you can retrieve and decode each value.

#### Scenario:

◦ You have received three credential files from your security team.
◦ Each file contains a single credential value that must be stored in Kubernetes.
◦ You need to create a single Secret containing all three credentials.

**Hint:** Use `kubectl create secret generic --from-file` with multiple `--from-file` flags or a directory.

<details>
<summary>Solution</summary>

```bash
## Create temporary credential files
echo -n "lab-admin" > /tmp/username
echo -n "Ex3rc1se#1!" > /tmp/password
echo -n "tok-abc123def456" > /tmp/api-token

## Create the Secret from multiple files
kubectl create secret generic multi-file-secret \
  --from-file=/tmp/username \
  --from-file=/tmp/password \
  --from-file=/tmp/api-token

## Verify the Secret exists and has 3 data entries
kubectl get secret multi-file-secret
## DATA column should show 3

## Decode each value to verify correctness
kubectl get secret multi-file-secret -o jsonpath='{.data.username}' | base64 --decode
echo  ## Newline -- Output: lab-admin

kubectl get secret multi-file-secret -o jsonpath='{.data.password}' | base64 --decode
echo  ## Newline -- Output: Ex3rc1se#1!

kubectl get secret multi-file-secret -o jsonpath='{.data.api-token}' | base64 --decode
echo  ## Newline -- Output: tok-abc123def456

## Clean up
rm /tmp/username /tmp/password /tmp/api-token
kubectl delete secret multi-file-secret
```

</details>

---

#### 02. Mount a Secret as an Environment Variable and Prove the Pod Can Read It

Create a Secret named `greeting-secret` with a key `message` containing the value `Hello from Kubernetes Secrets!`. Then create a Pod that reads this value as an environment variable and prints it.

#### Scenario:

◦ Your application reads its greeting message from an environment variable named `GREETING`.
◦ The message is sensitive (perhaps it contains an internal URL) and should be stored in a Secret.
◦ You need to verify the application can read the value correctly.

**Hint:** Use `secretKeyRef` in the Pod's `env` section and `kubectl logs` to verify.

<details>
<summary>Solution</summary>

```bash
## Create the Secret with the greeting message
kubectl create secret generic greeting-secret \
  --from-literal=message="Hello from Kubernetes Secrets!"

## Create a Pod that reads the Secret as an environment variable
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: greeting-pod
  namespace: secrets-lab
spec:
  containers:
    - name: greeter
      image: busybox:1.36
      command: ["sh", "-c", "echo $GREETING"]
      env:
        - name: GREETING
          valueFrom:
            secretKeyRef:
              name: greeting-secret
              key: message
  restartPolicy: Never
EOF

## Wait for the Pod to complete
kubectl wait --for=condition=Ready pod/greeting-pod --timeout=30s 2>/dev/null || sleep 5

## Check the logs -- should print the greeting
kubectl logs greeting-pod
## Output: Hello from Kubernetes Secrets!

## Clean up
kubectl delete pod greeting-pod
kubectl delete secret greeting-secret
```

</details>

---

#### 03. Create a Secret with `stringData` and Verify It Gets Base64-Encoded

Create a Secret declaratively using the `stringData` field with a username of `developer` and a password of `PlainText123`. After applying, verify that the values are stored as base64 in the `data` field.

#### Scenario:

◦ You want to create a Secret using plain-text values for convenience.
◦ You need to confirm that Kubernetes correctly encodes the values before storing them.
◦ Understanding this encoding behavior is essential for debugging Secret issues.

**Hint:** Use `kubectl apply` with a YAML manifest containing `stringData`, then inspect with `kubectl get secret -o yaml`.

<details>
<summary>Solution</summary>

```bash
## Create the Secret using stringData
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: stringdata-demo
  namespace: secrets-lab
type: Opaque
stringData:
  username: developer
  password: PlainText123
EOF

## View the Secret -- notice stringData is converted to data with base64
kubectl get secret stringdata-demo -o yaml

## Manually verify the base64 encoding
echo -n "developer" | base64
## Output: ZGV2ZWxvcGVy

echo -n "PlainText123" | base64
## Output: UGxhaW5UZXh0MTIz

## Compare with what Kubernetes stored
kubectl get secret stringdata-demo -o jsonpath='{.data.username}'
echo  ## Should output: ZGV2ZWxvcGVy

kubectl get secret stringdata-demo -o jsonpath='{.data.password}'
echo  ## Should output: UGxhaW5UZXh0MTIz

## Decode to confirm round-trip integrity
kubectl get secret stringdata-demo -o jsonpath='{.data.username}' | base64 --decode
echo  ## Output: developer

kubectl get secret stringdata-demo -o jsonpath='{.data.password}' | base64 --decode
echo  ## Output: PlainText123

## Clean up
kubectl delete secret stringdata-demo
```

</details>

---

#### 04. Mount a Secret as a Volume and Read the File Inside the Pod

Create a Secret named `config-secret` with two keys: `db.conf` containing `host=db.local\nport=5432` and `cache.conf` containing `host=redis.local\nport=6379`. Mount it as a volume at `/etc/config` and read both files from inside the Pod.

#### Scenario:

◦ Your application reads configuration from files in `/etc/config/`.
◦ Some configuration values are sensitive (database and cache connection details).
◦ You need the files to appear as regular files that the application can read.

**Hint:** Create the Secret with `--from-literal`, mount as a volume with `secret.secretName`, and use `kubectl exec` to read files.

<details>
<summary>Solution</summary>

```bash
## Create the Secret with configuration data
kubectl create secret generic config-secret \
  --from-literal=db.conf=$'host=db.local\nport=5432' \
  --from-literal=cache.conf=$'host=redis.local\nport=6379'

## Create a Pod that mounts the Secret as a volume
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-reader
  namespace: secrets-lab
spec:
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
          readOnly: true
  volumes:
    - name: config-vol
      secret:
        secretName: config-secret
  restartPolicy: Never
EOF

## Wait for the Pod
kubectl wait --for=condition=Ready pod/config-reader --timeout=60s

## List the files in the mounted directory
kubectl exec config-reader -- ls -la /etc/config/

## Read the database configuration
kubectl exec config-reader -- cat /etc/config/db.conf
## Output:
## host=db.local
## port=5432

## Read the cache configuration
kubectl exec config-reader -- cat /etc/config/cache.conf
## Output:
## host=redis.local
## port=6379

## Clean up
kubectl delete pod config-reader
kubectl delete secret config-secret
```

</details>

---

#### 05. Create a TLS Secret and Mount It in an Nginx Pod

Generate a self-signed TLS certificate, create a `kubernetes.io/tls` Secret, and deploy an nginx Pod that serves HTTPS traffic using the certificate.

#### Scenario:

◦ Your team needs to test HTTPS termination at the Pod level.
◦ You must generate a self-signed certificate, store it as a Kubernetes TLS Secret, and verify nginx can serve HTTPS responses.

**Hint:** Use `openssl req` to generate the cert/key, `kubectl create secret tls` to create the Secret, and `kubectl exec` with `curl -k` to test.

<details>
<summary>Solution</summary>

```bash
## Generate a self-signed certificate
openssl req -x509 -nodes -days 30 \
  -newkey rsa:2048 \
  -keyout /tmp/exercise-tls.key \
  -out /tmp/exercise-tls.crt \
  -subj "/CN=exercise.local/O=exercise"

## Create the TLS Secret
kubectl create secret tls exercise-tls-secret \
  --cert=/tmp/exercise-tls.crt \
  --key=/tmp/exercise-tls.key

## Verify the Secret type
kubectl get secret exercise-tls-secret
## TYPE should be kubernetes.io/tls

## Create an nginx ConfigMap for HTTPS
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: exercise-nginx-conf
  namespace: secrets-lab
data:
  default.conf: |
    server {
        listen 443 ssl;
        ssl_certificate     /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        location / {
            return 200 'Exercise 05: TLS is working!\n';
            add_header Content-Type text/plain;
        }
    }
EOF

## Deploy nginx with the TLS Secret
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: exercise-nginx-tls
  namespace: secrets-lab
spec:
  containers:
    - name: nginx
      image: nginx:1.25-alpine
      ports:
        - containerPort: 443
      volumeMounts:
        - name: tls-certs
          mountPath: /etc/nginx/ssl
          readOnly: true
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
          readOnly: true
  volumes:
    - name: tls-certs
      secret:
        secretName: exercise-tls-secret
    - name: nginx-config
      configMap:
        name: exercise-nginx-conf
  restartPolicy: Never
EOF

## Wait for the Pod
kubectl wait --for=condition=Ready pod/exercise-nginx-tls --timeout=60s

## Test HTTPS
kubectl exec exercise-nginx-tls -- curl -k https://localhost:443 2>/dev/null
## Output: Exercise 05: TLS is working!

## Clean up
rm /tmp/exercise-tls.crt /tmp/exercise-tls.key
kubectl delete pod exercise-nginx-tls
kubectl delete configmap exercise-nginx-conf
kubectl delete secret exercise-tls-secret
```

</details>

---

#### 06. Create an imagePullSecret and Reference It in a Deployment

Create a `docker-registry` Secret for a fictional private registry and create a Deployment that references it via `imagePullSecrets`.

#### Scenario:

◦ Your organization uses a private container registry at `registry.internal.example.com`.
◦ All Pods pulling from this registry need credentials.
◦ You need to set up the credentials and reference them in a Deployment.

**Hint:** Use `kubectl create secret docker-registry` and add `imagePullSecrets` to the Deployment's Pod template spec.

<details>
<summary>Solution</summary>

```bash
## Create the docker-registry Secret
kubectl create secret docker-registry internal-registry \
  --docker-server=registry.internal.example.com \
  --docker-username=deploy-bot \
  --docker-password='R3g1stryP@ss!' \
  --docker-email=deploy@example.com

## Verify the Secret
kubectl get secret internal-registry
## TYPE should be kubernetes.io/dockerconfigjson

## Create a Deployment referencing the imagePullSecret
## (This will fail to pull since the registry is fictional, but the
## configuration is correct -- check the Pod spec for the reference)
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-app
  namespace: secrets-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: private-app
  template:
    metadata:
      labels:
        app: private-app
    spec:
      containers:
        - name: app
          ## Using nginx as a stand-in; in production this would be
          ## registry.internal.example.com/my-app:latest
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
      imagePullSecrets:
        - name: internal-registry
EOF

## Verify the Deployment references the imagePullSecret
kubectl get deployment private-app -o jsonpath='{.spec.template.spec.imagePullSecrets}' | python3 -m json.tool

## Clean up
kubectl delete deployment private-app
kubectl delete secret internal-registry
```

</details>

---

#### 07. Update a Secret and Verify the Volume Mount Reflects the Change

Create a Secret, mount it as a volume in a Pod, update the Secret, and verify that the file content inside the Pod changes automatically.

#### Scenario:

◦ You need to update an API key without restarting the application.
◦ Volume-mounted Secrets are automatically refreshed by the kubelet.
◦ You need to prove this auto-update behavior works.

**Hint:** Create a Secret and a long-running Pod with a volume mount. Use `kubectl create --dry-run=client -o yaml | kubectl apply -f -` to update the Secret, then wait and re-read the file.

<details>
<summary>Solution</summary>

```bash
## Create the initial Secret
kubectl create secret generic rotating-secret \
  --from-literal=api-key="original-key-v1"

## Create a long-running Pod that mounts the Secret
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-watcher
  namespace: secrets-lab
spec:
  containers:
    - name: watcher
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \"$(date): $(cat /etc/secrets/api-key)\"; sleep 10; done"]
      volumeMounts:
        - name: secret-vol
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secret-vol
      secret:
        secretName: rotating-secret
  restartPolicy: Never
EOF

## Wait for the Pod
kubectl wait --for=condition=Ready pod/secret-watcher --timeout=60s

## Verify the current value
kubectl exec secret-watcher -- cat /etc/secrets/api-key
## Output: original-key-v1

## Update the Secret with a new value
kubectl create secret generic rotating-secret \
  --from-literal=api-key="rotated-key-v2" \
  --dry-run=client -o yaml | kubectl apply -f -

## Wait for the kubelet to sync (up to ~2 minutes)
echo "Waiting for kubelet to sync the updated Secret..."
sleep 120

## Verify the value has been updated inside the Pod
kubectl exec secret-watcher -- cat /etc/secrets/api-key
## Output: rotated-key-v2

## Check the logs for the transition
kubectl logs secret-watcher | tail -20

## Clean up
kubectl delete pod secret-watcher
kubectl delete secret rotating-secret
```

</details>

---

#### 08. Create an Immutable Secret and Try to Modify It

Create a Secret marked as `immutable: true` and attempt to update its data. Verify that the update is rejected by the API server.

#### Scenario:

◦ Your compliance team requires that production API keys cannot be modified after deployment.
◦ You need to prove that the immutable flag prevents changes.
◦ You also need to understand the only way to change an immutable Secret.

**Hint:** Create a Secret with `immutable: true` in the YAML, then try `kubectl patch` or `kubectl edit` to modify it.

<details>
<summary>Solution</summary>

```bash
## Create an immutable Secret
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: locked-secret
  namespace: secrets-lab
type: Opaque
immutable: true
stringData:
  token: "immutable-token-abc123"
EOF

## Verify it's immutable
kubectl get secret locked-secret -o jsonpath='{.immutable}'
echo  ## Output: true

## Attempt to modify the Secret data -- this WILL FAIL
kubectl patch secret locked-secret \
  --type='json' \
  -p='[{"op": "replace", "path": "/stringData", "value": {"token": "new-token"}}]' 2>&1 || true
## Expected error: field is immutable when `immutable` is set

## Attempt to add a new key -- this WILL also FAIL
kubectl patch secret locked-secret \
  --type='merge' \
  -p='{"stringData": {"new-key": "new-value"}}' 2>&1 || true

## The ONLY way to change it is delete + recreate
kubectl delete secret locked-secret

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: locked-secret
  namespace: secrets-lab
type: Opaque
immutable: true
stringData:
  token: "new-immutable-token-xyz789"
EOF

## Verify the new value
kubectl get secret locked-secret -o jsonpath='{.data.token}' | base64 --decode
echo  ## Output: new-immutable-token-xyz789

## Clean up
kubectl delete secret locked-secret
```

</details>

---

#### 09. Use Projected Volumes to Combine a Secret and a ConfigMap

Create a Secret and a ConfigMap, then mount both into a single directory in a Pod using a projected volume. Verify all files appear under the same mount path.

#### Scenario:

◦ Your application expects all configuration (sensitive and non-sensitive) in `/app/config/`.
◦ You cannot have two separate mount paths -- the application reads from a single directory.
◦ You need to combine a Secret and a ConfigMap into one unified mount.

**Hint:** Use a `projected` volume with `sources` containing both `secret` and `configMap` entries.

<details>
<summary>Solution</summary>

```bash
## Create the Secret
kubectl create secret generic app-secret \
  --from-literal=db-password="pr0j3ct3d!"

## Create the ConfigMap
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
  namespace: secrets-lab
data:
  app.env: "production"
  log.level: "warn"
EOF

## Create a Pod with a projected volume combining both
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: projected-demo
  namespace: secrets-lab
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "ls -la /app/config/ && echo '---' && for f in /app/config/*; do echo \"$f: $(cat $f)\"; done && sleep 3600"]
      volumeMounts:
        - name: all-config
          mountPath: /app/config
          readOnly: true
  volumes:
    - name: all-config
      projected:
        sources:
          - secret:
              name: app-secret
              items:
                - key: db-password
                  path: db-password
          - configMap:
              name: app-settings
              items:
                - key: app.env
                  path: app.env
                - key: log.level
                  path: log.level
  restartPolicy: Never
EOF

## Wait and check the logs
kubectl wait --for=condition=Ready pod/projected-demo --timeout=60s
kubectl logs projected-demo

## Expected output shows all three files under /app/config/:
## db-password (from Secret)
## app.env (from ConfigMap)
## log.level (from ConfigMap)

## Verify individual files
kubectl exec projected-demo -- cat /app/config/db-password
## Output: pr0j3ct3d!

kubectl exec projected-demo -- cat /app/config/app.env
## Output: production

## Clean up
kubectl delete pod projected-demo
kubectl delete secret app-secret
kubectl delete configmap app-settings
```

</details>

---

#### 10. Decode All Values in a Secret Using a One-Liner

Given a Secret named `multi-key-secret` with several keys, write a single command that decodes and displays all key-value pairs.

#### Scenario:

◦ You are debugging an application and need to quickly inspect all values in a Secret.
◦ Running separate `jsonpath` + `base64 --decode` for each key is tedious.
◦ You need a single command that outputs all decoded key-value pairs.

**Hint:** Use `kubectl get secret -o json` piped to a tool that iterates over the `data` map and decodes each value.

<details>
<summary>Solution</summary>

```bash
## Create a Secret with multiple keys for testing
kubectl create secret generic multi-key-secret \
  --from-literal=key1="value-one" \
  --from-literal=key2="value-two" \
  --from-literal=key3="value-three" \
  --from-literal=api-token="tok-abc123"

## Method 1: Using python3 (available on most systems)
kubectl get secret multi-key-secret -o json | \
  python3 -c "
import json, sys, base64
data = json.load(sys.stdin)['data']
for k, v in sorted(data.items()):
    print(f'{k}: {base64.b64decode(v).decode()}')
"

## Method 2: Using kubectl jsonpath + bash loop
for key in $(kubectl get secret multi-key-secret -o jsonpath='{.data}' | python3 -c "import json,sys; [print(k) for k in json.load(sys.stdin)]"); do
  value=$(kubectl get secret multi-key-secret -o jsonpath="{.data.$key}" | base64 --decode)
  echo "$key: $value"
done

## Method 3: Using go-template
kubectl get secret multi-key-secret -o go-template='{{range $k, $v := .data}}{{$k}}: {{$v | base64decode}}
{{end}}'

## Expected output (any method):
## api-token: tok-abc123
## key1: value-one
## key2: value-two
## key3: value-three

## Clean up
kubectl delete secret multi-key-secret
```

</details>

---

#### 11. Create a Secret with Special Characters in Values

Create a Secret containing values with special characters: backslashes, quotes, dollar signs, newlines, and unicode characters. Verify they survive the encoding/decoding round-trip.

#### Scenario:

◦ A database password generated by your security tool contains complex special characters.
◦ You need to ensure these characters are not corrupted during Secret creation and retrieval.
◦ Shell escaping and base64 encoding can sometimes mangle special characters.

**Hint:** Use `--from-file` with a file containing the exact value to avoid shell escaping issues, or use `stringData` in a YAML manifest.

<details>
<summary>Solution</summary>

```bash
## Method 1: Using --from-file to avoid shell escaping entirely
printf 'P@$$w0rd\n"quotes"\tand\\backslash' > /tmp/special-chars.txt

kubectl create secret generic special-secret \
  --from-file=complex-value=/tmp/special-chars.txt

## Verify the round-trip
kubectl get secret special-secret -o jsonpath='{.data.complex-value}' | base64 --decode
## Output should exactly match the original value

## Method 2: Using stringData in a YAML manifest for more control
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: special-yaml-secret
  namespace: secrets-lab
type: Opaque
stringData:
  password: 'P@$$w0rd!"quotes"&<xml>'
  multiline: |
    line1: value1
    line2: value2
    line3: "quoted value"
  json-config: '{"key": "value with \"quotes\" and $pecial chars"}'
EOF

## Verify each key
kubectl get secret special-yaml-secret -o jsonpath='{.data.password}' | base64 --decode
echo
## Output: P@$$w0rd!"quotes"&<xml>

kubectl get secret special-yaml-secret -o jsonpath='{.data.multiline}' | base64 --decode
## Output should preserve the multi-line format

kubectl get secret special-yaml-secret -o jsonpath='{.data.json-config}' | base64 --decode
echo
## Output: {"key": "value with \"quotes\" and $pecial chars"}

## Clean up
rm /tmp/special-chars.txt
kubectl delete secret special-secret
kubectl delete secret special-yaml-secret
```

</details>

---

#### 12. Write a Script That Rotates a Secret and Triggers a Rolling Restart

Write a shell script that generates a new random password, updates a Secret, and triggers a rolling restart of the consuming Deployment. Verify the Pods pick up the new credential.

#### Scenario:

◦ Your security policy requires rotating database passwords every 30 days.
◦ The rotation must be automated and must not cause downtime.
◦ After rotation, all Pods must pick up the new password via a rolling restart.

**Hint:** Use `openssl rand` to generate a password, `kubectl create secret --dry-run=client -o yaml | kubectl apply -f -` to update, and `kubectl rollout restart` to trigger the restart.

<details>
<summary>Solution</summary>

```bash
## Create the initial Secret and Deployment
kubectl create secret generic rotatable-db-creds \
  --from-literal=username=app-user \
  --from-literal=password="initial-password-v1"

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-consumer
  namespace: secrets-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: db-consumer
  template:
    metadata:
      labels:
        app: db-consumer
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh", "-c", "while true; do echo \"password=$DB_PASSWORD\"; sleep 30; done"]
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: rotatable-db-creds
                  key: password
EOF

## Wait for the Deployment to be ready
kubectl rollout status deployment/db-consumer --timeout=60s

## Verify the current password
kubectl logs deployment/db-consumer | head -1
## Output: password=initial-password-v1

## --- The rotation script ---
## Generate a new random password
NEW_PASSWORD=$(openssl rand -base64 24)
echo "New password: $NEW_PASSWORD"

## Update the Secret using the dry-run + apply pattern
kubectl create secret generic rotatable-db-creds \
  --from-literal=username=app-user \
  --from-literal=password="$NEW_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

## Verify the Secret was updated
kubectl get secret rotatable-db-creds -o jsonpath='{.data.password}' | base64 --decode
echo  ## Should match $NEW_PASSWORD

## Trigger a rolling restart so Pods pick up the new env var value
kubectl rollout restart deployment/db-consumer

## Wait for the rollout to complete
kubectl rollout status deployment/db-consumer --timeout=120s

## Verify the new Pods have the updated password
sleep 5
kubectl logs deployment/db-consumer | head -1
## Output: password=<new-random-password>

## Clean up
kubectl delete deployment db-consumer
kubectl delete secret rotatable-db-creds
```

</details>

---

## Finalize & Cleanup

- To remove all resources created by this lab, delete the `secrets-lab` namespace:

```bash
## Delete the entire namespace (this removes ALL resources within it)
kubectl delete namespace secrets-lab
```

- Reset your kubectl context to the default namespace:

```bash
## Switch back to the default namespace
kubectl config set-context --current --namespace=default
```

- (Optional) Remove any local temporary files created during the lab:

```bash
## Clean up any leftover temporary files
rm -f /tmp/username.txt /tmp/password.txt /tmp/app-secrets.env
rm -f /tmp/tls.crt /tmp/tls.key
rm -f /tmp/exercise-tls.crt /tmp/exercise-tls.key
rm -f /tmp/special-chars.txt
```

---

## Troubleshooting

- **Secret not found:**

Verify the Secret exists in the correct namespace:

```bash
## List Secrets in the current namespace
kubectl get secrets -n secrets-lab

## Check if you are in the right namespace
kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'
```

<br>

- **Base64 decode errors:**

Ensure values were encoded without trailing newlines:

```bash
## Correct: no trailing newline
echo -n "myvalue" | base64

## Incorrect: includes trailing newline (will cause issues)
echo "myvalue" | base64
```

<br>

- **Pod cannot access Secret:**

Check RBAC permissions and ensure the Secret name matches:

```bash
## Verify the Secret exists
kubectl get secret <secret-name> -n secrets-lab

## Check Pod events for errors
kubectl describe pod <pod-name> -n secrets-lab | grep -A10 "Events:"

## Common error: "secret not found" -- verify the name matches exactly
kubectl get pod <pod-name> -n secrets-lab -o yaml | grep secretName
```

<br>

- **Volume-mounted Secret not updating:**

The kubelet syncs Secret updates with a configurable period (default: up to ~1 minute plus cache propagation delay). If using subPath mounts, the file is **never** updated:

```bash
## Check kubelet sync period (on the node)
## Default is --sync-frequency=1m

## IMPORTANT: subPath volume mounts do NOT receive automatic updates
## Avoid using subPath with Secrets if you need auto-rotation
```

<br>

- **Immutable Secret cannot be updated:**

This is expected behavior. Delete and recreate the Secret:

```bash
## Delete the immutable Secret
kubectl delete secret <secret-name> -n secrets-lab

## Recreate it with updated values
kubectl apply -f <manifest.yaml>
```

<br>

- **TLS Secret creation fails:**

Ensure the certificate and key files are valid and match:

```bash
## Verify the certificate
openssl x509 -in /tmp/tls.crt -text -noout

## Verify the key
openssl rsa -in /tmp/tls.key -check

## Verify the cert and key match (modulus should be identical)
openssl x509 -noout -modulus -in /tmp/tls.crt | openssl md5
openssl rsa -noout -modulus -in /tmp/tls.key | openssl md5
```

<br>

- **imagePullSecrets not working:**

Verify the Secret type and the registry URL:

```bash
## The Secret type must be kubernetes.io/dockerconfigjson
kubectl get secret <secret-name> -o jsonpath='{.type}'

## Decode and verify the registry URL matches your image registry
kubectl get secret <secret-name> -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode | python3 -m json.tool
```

---

## Next Steps

- Explore [External Secrets Operator](https://external-secrets.io/) to sync Secrets from external secret managers (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, GCP Secret Manager).
- Try [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) by Bitnami to safely store encrypted Secrets in Git repositories.
- Learn about [HashiCorp Vault](https://www.vaultproject.io/) and the Vault Agent Injector for dynamic secret management in Kubernetes.
- Set up [cert-manager](https://cert-manager.io/) to automate TLS certificate issuance and renewal with Let's Encrypt.
- Implement Kubernetes [RBAC policies](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) to restrict Secret access to only the ServiceAccounts and users that need it.
- Enable [Kubernetes Audit Logging](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/) to monitor who accesses Secrets in your cluster.
- Explore [SOPS](https://github.com/getsops/sops) (Secrets OPerationS) for encrypting Secret manifests before committing to Git.
- Try the [CSI Secrets Store Driver](https://secrets-store-csi-driver.sigs.k8s.io/) to mount Secrets from external stores as volumes without Kubernetes Secret objects.
