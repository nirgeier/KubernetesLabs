
# K8S Hands-on



---

# StatefulSets

<img src="../assets/images/statefulSet.png" width=500>


## The Difference Between a `Statefulset` And a `Deployment`

#### `Stateless` application

- A stateless application is one that does not care which network it is using, and it does not need permanent storage and can be scaled up and down without the need to re-use the same network or persistence.
- Deployment is the suitable kind for Stateless applications.
- The most trivial example of stateless app is a `Web Server`.

#### `Stateful` application

- Stateful applications are apps which in order to work properly need to use the same resources, such as network, storage etc.
- Usually with `Stateful` applications you will need to ensure that pods can reach each other through a **unique identity that does not change** (e.g., hostnames, IP).
- The most trivial example of Stateful app is a database of any kind.

---

!!! warning "Stateful Notes"
    - Like a Deployment, a `StatefulSet` manages Pods that are based on an **identical container spec**.
    - Unlike a Deployment, **a `StatefulSet` maintains a sticky identity for each of their Pods**.
    - These pods are created from the same spec, but are not interchangeable: each has a persistent identifier that it maintains across any rescheduling.
    - Deleting and/or scaling down a `StatefulSet` will not delete the volumes associated with the `StatefulSet`. This is done to ensure data safety.
    - `StatefulSet` keeps a unique identity for each Pod and assign the same identity to those pods when they are rescheduled (update, restart etc).
    - The storage for a given Pod must either be provisioned by a `PersistentVolume` provisioner, based on the requested storage class, or pre-provisioned by an admin.
    - `StatefulSet` manages the deployment and scaling of a set of Pods, and **provides guarantees about the ordering and uniqueness of these Pods**.
    - A `stateful` app needs to use a dedicated storage.

---

### Stable Network Identity

- A `Stateful` application node **must** have a unique hostname and IP address so that other nodes in the same application know how to reach it.
- A `ReplicaSet` assign **a random hostname and IP address** to each Pod. In such a case, we must use a service which exposes those Pods for us.

### Start and Termination Order

- Each `StatefulSet` follows this naming pattern: `$(statefulSet name)-$(ordinal)`
- `Stateful` applications restarted or re-created, following the creation order.
- A `ReplicaSet` does not follow a specific order when starting or killing its pods.

### StatefulSet Volumes

- `StatefulSet` **does not create a volume for you**.
- When a `StatefulSet` is deleted, the respective volumes **are not deleted with it**.

---

### To address all these requirements, Kubernetes offers the `StatefulSet primitive`.

---

### Pre-Requirements

- K8S cluster - <a href="../00-VerifyCluster">Setting up minikube cluster instruction</a>

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/KubernetesLabs)  
**<kbd>CTRL</kbd> + <kbd>click</kbd> to open in new window**


---

### 01. Create namespace and clear previous data if there is any

```sh
# If the namespace already exist and contains data form previous steps, lets clean it
kubectl delete namespace codewizard

# Create the desired namespace [codewizard]
$ kubectl create namespace codewizard
namespace/codewizard created
```

### 02. Create and test the Stateful application

- In order to deploy the Stateful set we will need the following resources:

  - `ConfigMap`
  - `Service`
  - `StatefulSet`
  - `PersistentVolumeClaim or`PersistentVolume`

- All the resources including `kustomization` script are defined inside the base folder

---

- [ConfigMap.yaml](./PostgreSQL/base/ConfigMap.yaml)

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: postgres-config
    labels:
      app: postgres
  data:
    # The following names are the one defined in the officail postgres docs

    # The name of the database we will use in this demo
    POSTGRES_DB: codewizard
    # the user name for this demo
    POSTGRES_USER: codewizard
    # The password for this demo
    POSTGRES_PASSWORD: admin123
  ```

* [Service.yaml](./PostgreSQL/base/Service.yaml)
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: postgres
    labels:
      app: postgres
  spec:
    selector:
      app: postgres
    # Service of type nodeport
    type: NodePort
    # The deafult port for postgres
    ports:
      - port: 5432
  ```

- [PersistentVolumeClaim.yaml](./PostgreSQL/base/PersistentVolumeClaim.yaml)

  ```yaml
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: postgres-pv-claim
    labels:
      app: postgres
  spec:
    # in this demo we use GCP so we are using the 'standard' StorageClass
    # We can of course define our own StorageClass resource
    storageClassName: standard

    # The access modes are:
    #   ReadWriteOnce - The volume can be mounted as read-write by a single node
    #   ReadWriteMany - The volume can be mounted as read-write by a many node
    #   ReadOnlyMany  - The volume can be mounted as read-only  by many nodes
    accessModes:
      - ReadWriteMany
    resources:
      requests:
        storage: 1Gi
  ```

- [StatefulSet.yaml](./PostgreSQL/base/StatefulSet.yaml)

  ```yaml
  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: postgres
  spec:
    replicas: 1
    # StatefulSet must contain a serviceName
    serviceName: postgres
    selector:
      matchLabels:
        app: postgres # has to match .spec.template.metadata.labels
    template:
      metadata:
        labels:
          app: postgres # has to match .spec.selector.matchLabels
      spec:
        containers:
          - name: postgres
            image: postgres:10.4
            imagePullPolicy: "IfNotPresent"
            # The default DB port
            ports:
              - containerPort: 5432
            # Load the required configuration env values form the configMap
            envFrom:
              - configMapRef:
                  name: postgres-config
            # Use volume for storage
            volumeMounts:
              - mountPath: /var/lib/postgresql/data
                name: postgredb
        # We can use PersistentVolume or PersistentVolumeClaim.
        # In this sample we are useing PersistentVolumeClaim
        volumes:
          - name: postgredb
            persistentVolumeClaim:
              # reference to Pre-Define PVC
              claimName: postgres-pv-claim
  ```

**Note**: You can use the kustomization file to create or apply all the above resources

```sh
# Generate and apply the required resources using kustomization
kubectl kustomize PostgreSQL/ | kubectl apply -f -
```

---

### 03. Test the Stateful application

- Use the - [testDB.sh](./PostgreSQL/testDB.sh) to test the StatefulSet
- Don't forget to set the execution flag `chmod +x testDb.sh` if required

```sh
### Test to see if the StatefulSet "saves" the state of the pods

# Programmatically get the port and the IP
export CLUSTER_IP=$(kubectl get nodes \
            --selector=node-role.kubernetes.io/control-plane \
            -o jsonpath='{$.items[*].status.addresses[?(@.type=="InternalIP")].address}')

export NODE_PORT=$(kubectl get \
            services postgres \
            -o jsonpath="{.spec.ports[0].nodePort}" \
            -n codewizard)

export POSTGRES_DB=$(kubectl get \
            configmap postgres-config \
            -o jsonpath='{.data.POSTGRES_DB}' \
            -n codewizard)

export POSTGRES_USER=$(kubectl get \
            configmap postgres-config \
            -o jsonpath='{.data.POSTGRES_USER}' \
            -n codewizard)

export PGPASSWORD=$(kubectl get \
            configmap postgres-config \
            -o jsonpath='{.data.POSTGRES_PASSWORD}' \
            -n codewizard)

# Check to see if we have all the required variables
printenv | grep POST*

# Connect to postgres and create table if required.
# Once the table exists - add row into the table
# you can run this command as amny times as you like
psql \
    -U ${POSTGRES_USER} \
    -h ${CLUSTER_IP} \
    -d ${POSTGRES_DB} \
    -p ${NODE_PORT} \
    -c "CREATE TABLE IF NOT EXISTS stateful (str VARCHAR); INSERT INTO stateful values (1); SELECT count(*) FROM stateful"
```

### 04. Scale down the StatefulSet and check that its down

#### 04.01. Scale down the `Statefulset` to 0

```sh
# scale down the `Statefulset` to 0
kubectl scale statefulset postgres -n codewizard --replicas=0
```

#### 04.02. Verify that the pods Terminated

```sh
# Wait until the pods will be terminated
kubectl get pods -n codewizard --watch
NAME         READY   STATUS    RESTARTS   AGE
postgres-0   1/1     Running   0          32m
postgres-0   1/1     Terminating   0      32m
postgres-0   0/1     Terminating   0      32m
postgres-0   0/1     Terminating   0      33m
postgres-0   0/1     Terminating   0      33m
```

### 04.03. Verify that the DB is not reachable

- If the DB is not reachable it mean that all the pods are down

```sh
psql \
    -U ${POSTGRES_USER} \
    -h ${CLUSTER_IP} \
    -d ${POSTGRES_DB} \
    -p ${NODE_PORT} \
    -c "SELECT count(*) FROM stateful"

# You should get output similar to this one:
psql: error: could not connect to server: Connection refused
        Is the server running on host "192.168.49.2" and accepting
        TCP/IP connections on port 32570?
```

### 05. Scale up again and verify that we still have the prevoius data

#### 05.01. scale up the `Statefulset` to 1 or more

```sh
# scale up the `Statefulset`
kubectl scale statefulset postgres -n codewizard --replicas=1
```

#### 05.02. Verify that the pods is in Running status

```sh
kubectl get pods -n codewizard --watch
NAME         READY   STATUS    RESTARTS   AGE
postgres-0   1/1     Running   0          5s
```

#### 05.03. Verify that the pods is using the previous data

```sh
psql \
    -U ${POSTGRES_USER} \
    -h ${CLUSTER_IP} \
    -d ${POSTGRES_DB} \
    -p ${NODE_PORT} \
    -c "SELECT count(*) FROM stateful"
# The output should be similar to this one

 count
-------
     2
(1 row)
```

