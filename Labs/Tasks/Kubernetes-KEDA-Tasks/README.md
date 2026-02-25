# Kubernetes KEDA Tasks

- Hands-on Kubernetes exercises covering KEDA (Kubernetes Event-Driven Autoscaling) installation, ScaledObjects, ScaledJobs, TriggerAuthentication, and real-world autoscaling patterns.
- Each task includes a description, scenario, and a detailed solution with step-by-step instructions.
- Practice these tasks to master event-driven autoscaling with KEDA.

#### Table of Contents

- [01. Install KEDA via Helm](#01-install-keda-via-helm)
- [02. Create a CPU-Based ScaledObject](#02-create-a-cpu-based-scaledobject)
- [03. Scale to Zero with Redis Queue](#03-scale-to-zero-with-redis-queue)
- [04. Schedule Scaling with the Cron Trigger](#04-schedule-scaling-with-the-cron-trigger)
- [05. Use TriggerAuthentication with Secrets](#05-use-triggerauthentication-with-secrets)
- [06. Combine Multiple Triggers](#06-combine-multiple-triggers)
- [07. Create a ScaledJob for Batch Processing](#07-create-a-scaledjob-for-batch-processing)
- [08. Tune Scale-Up and Scale-Down Behavior](#08-tune-scale-up-and-scale-down-behavior)
- [09. Pause and Resume a ScaledObject](#09-pause-and-resume-a-scaledobject)
- [10. Troubleshoot a Non-Scaling ScaledObject](#10-troubleshoot-a-non-scaling-scaledobject)

---

#### 01. Install KEDA via Helm

Install KEDA on a Kubernetes cluster using the official Helm chart and verify all components.

#### Scenario:

  ◦ Your team wants to adopt event-driven autoscaling for queue-based workers.
  ◦ KEDA extends the native HPA with 60+ event source scalers.

**Hint:** `helm repo add kedacore`, `helm upgrade --install keda`

??? example "Solution"

    ```bash
    # 1. Add the KEDA Helm repository
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update kedacore

    # 2. Install KEDA
    helm upgrade --install keda kedacore/keda \
        --namespace keda \
        --create-namespace \
        --wait

    # 3. Verify pods are running
    kubectl get pods -n keda
    # keda-admission-webhooks-xxxx     1/1     Running
    # keda-operator-xxxx               1/1     Running
    # keda-operator-metrics-apiserver   1/1     Running

    # 4. Verify CRDs are registered
    kubectl get crd | grep keda
    # scaledobjects.keda.sh
    # scaledjobs.keda.sh
    # triggerauthentications.keda.sh
    # clustertriggerauthentications.keda.sh

    # 5. Verify the metrics API
    kubectl get apiservice | grep keda
    ```

---

#### 02. Create a CPU-Based ScaledObject

Create a ScaledObject that scales a Deployment based on CPU utilization (threshold: 60%).

#### Scenario:

  ◦ You want to replace your existing HPA with KEDA to later add queue-based triggers.
  ◦ The CPU scaler works identically to HPA but can be combined with other KEDA scalers.

**Hint:** Use `type: cpu` with `metadata.type: Utilization` and `metadata.value: "60"`.

??? example "Solution"

    ```bash
    # 1. Create a namespace and deployment
    kubectl create namespace keda-tasks
    kubectl create deployment nginx-demo \
        --image=nginx:1.25 \
        --replicas=1 \
        --namespace=keda-tasks
    kubectl set resources deployment nginx-demo \
        --requests=cpu=50m,memory=64Mi \
        --namespace=keda-tasks

    # 2. Apply the ScaledObject
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: cpu-scaler
      namespace: keda-tasks
    spec:
      scaleTargetRef:
        name: nginx-demo
      minReplicaCount: 1
      maxReplicaCount: 10
      triggers:
        - type: cpu
          metadata:
            type: Utilization
            value: "60"
    EOF

    # 3. Verify KEDA created an HPA
    kubectl get hpa -n keda-tasks
    kubectl get scaledobject -n keda-tasks

    # Cleanup
    kubectl delete namespace keda-tasks
    ```

---

#### 03. Scale to Zero with Redis Queue

Deploy a Redis-backed worker that scales from 0 to N based on queue depth, and back to 0 when empty.

#### Scenario:

  ◦ Idle workers waste resources. You want pods only when there's work.
  ◦ KEDA monitors the Redis list length and scales workers accordingly.

**Hint:** Set `minReplicaCount: 0` and use the `redis` scaler with `listName` and `listLength`.

??? example "Solution"

    ```bash
    # 1. Create namespace and deploy Redis
    kubectl create namespace keda-tasks
    kubectl create deployment redis --image=redis:7-alpine -n keda-tasks
    kubectl expose deployment redis --port=6379 -n keda-tasks

    # 2. Create a worker deployment (starting at 0)
    cat <<'EOF' | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: queue-worker
      namespace: keda-tasks
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: queue-worker
      template:
        metadata:
          labels:
            app: queue-worker
        spec:
          containers:
          - name: worker
            image: redis:7-alpine
            command: ["/bin/sh", "-c"]
            args:
              - |
                while true; do
                  JOB=$(redis-cli -h redis LPOP work:queue)
                  if [ -n "$JOB" ]; then echo "Processing: $JOB"; sleep 2
                  else sleep 1; fi
                done
    EOF

    # 3. Create the ScaledObject
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: queue-scaler
      namespace: keda-tasks
    spec:
      scaleTargetRef:
        name: queue-worker
      minReplicaCount: 0
      maxReplicaCount: 10
      cooldownPeriod: 30
      pollingInterval: 5
      triggers:
        - type: redis
          metadata:
            address: redis.keda-tasks.svc:6379
            listName: work:queue
            listLength: "5"
    EOF

    # 4. Verify 0 pods
    kubectl get pods -n keda-tasks -l app=queue-worker

    # 5. Push jobs and watch scale-up
    kubectl exec deployment/redis -n keda-tasks -- \
        redis-cli RPUSH work:queue j1 j2 j3 j4 j5 j6 j7 j8 j9 j10 j11 j12 j13 j14 j15
    kubectl get pods -n keda-tasks -l app=queue-worker -w

    # Cleanup
    kubectl delete namespace keda-tasks
    ```

---

#### 04. Schedule Scaling with the Cron Trigger

Create a ScaledObject that scales to 5 replicas during business hours (Mon–Fri, 08:00–18:00).

#### Scenario:

  ◦ Your API needs pre-warmed capacity every weekday morning.
  ◦ The Cron scaler provides time-based replica scheduling.

**Hint:** Use `type: cron` with `start`, `end`, `timezone`, and `desiredReplicas`.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: cron-scaler
      namespace: keda-tasks
    spec:
      scaleTargetRef:
        name: nginx-demo
      minReplicaCount: 1
      maxReplicaCount: 10
      triggers:
        - type: cron
          metadata:
            timezone: "UTC"
            start: "0 8 * * 1-5"
            end: "0 18 * * 1-5"
            desiredReplicas: "5"
    EOF

    # Check the ScaledObject
    kubectl describe scaledobject cron-scaler -n keda-tasks
    ```

---

#### 05. Use TriggerAuthentication with Secrets

Create a TriggerAuthentication backed by a Kubernetes Secret and reference it in a ScaledObject.

#### Scenario:

  ◦ Your Redis requires authentication and you don't want the password in the ScaledObject.
  ◦ TriggerAuthentication separates credentials from scaling configuration.

**Hint:** Create a Secret, create a TriggerAuthentication with `secretTargetRef`, then use `authenticationRef` in the ScaledObject.

??? example "Solution"

    ```bash
    # 1. Create the Secret
    kubectl create secret generic redis-creds \
        --namespace keda-tasks \
        --from-literal=password='s3cret'

    # 2. Create TriggerAuthentication
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: TriggerAuthentication
    metadata:
      name: redis-auth
      namespace: keda-tasks
    spec:
      secretTargetRef:
        - parameter: password
          name: redis-creds
          key: password
    EOF

    # 3. Reference it in a ScaledObject
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: auth-scaler
      namespace: keda-tasks
    spec:
      scaleTargetRef:
        name: queue-worker
      minReplicaCount: 0
      maxReplicaCount: 10
      triggers:
        - type: redis
          authenticationRef:
            name: redis-auth
          metadata:
            address: redis:6379
            listName: secure:queue
            listLength: "5"
    EOF

    # 4. Verify
    kubectl get triggerauthentication -n keda-tasks
    kubectl describe scaledobject auth-scaler -n keda-tasks
    ```

---

#### 06. Combine Multiple Triggers

Create a ScaledObject with both a Cron trigger and a CPU trigger in a single resource.

#### Scenario:

  ◦ You need a baseline of 3 pods during work hours, but CPU-driven bursting beyond that.
  ◦ KEDA evaluates all triggers and uses the maximum demanded replicas.

**Hint:** Add multiple entries in the `triggers` list.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: multi-trigger
      namespace: keda-tasks
    spec:
      scaleTargetRef:
        name: nginx-demo
      minReplicaCount: 1
      maxReplicaCount: 15
      triggers:
        - type: cron
          metadata:
            timezone: "UTC"
            start: "0 8 * * 1-5"
            end: "0 18 * * 1-5"
            desiredReplicas: "3"
        - type: cpu
          metadata:
            type: Utilization
            value: "60"
    EOF

    # KEDA uses whichever trigger demands MORE replicas
    kubectl get hpa -n keda-tasks
    kubectl describe scaledobject multi-trigger -n keda-tasks
    ```

---

#### 07. Create a ScaledJob for Batch Processing

Create a ScaledJob that spawns one Job per batch of 5 items in a Redis list.

#### Scenario:

  ◦ Each batch task (e.g., video transcoding, report generation) runs as a short-lived Job.
  ◦ ScaledJob creates new Jobs (not replica scaling) - one per event batch.

**Hint:** Use `kind: ScaledJob` with `jobTargetRef` instead of `scaleTargetRef`.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledJob
    metadata:
      name: batch-job
      namespace: keda-tasks
    spec:
      jobTargetRef:
        parallelism: 1
        completions: 1
        backoffLimit: 2
        template:
          spec:
            restartPolicy: Never
            containers:
            - name: processor
              image: redis:7-alpine
              command: ["/bin/sh", "-c"]
              args:
                - |
                  for i in $(seq 1 5); do
                    JOB=$(redis-cli -h redis LPOP batch:queue)
                    [ -n "$JOB" ] && echo "Processing: $JOB" && sleep 1
                  done
      minReplicaCount: 0
      maxReplicaCount: 20
      pollingInterval: 10
      successfulJobsHistoryLimit: 5
      failedJobsHistoryLimit: 3
      triggers:
        - type: redis
          metadata:
            address: redis:6379
            listName: batch:queue
            listLength: "5"
    EOF

    # Push items
    kubectl exec deployment/redis -n keda-tasks -- \
        redis-cli RPUSH batch:queue b1 b2 b3 b4 b5 b6 b7 b8 b9 b10

    # Watch Jobs
    kubectl get jobs -n keda-tasks -w
    kubectl get scaledjob -n keda-tasks
    ```

---

#### 08. Tune Scale-Up and Scale-Down Behavior

Configure a ScaledObject with custom HPA behavior: fast scale-up, slow scale-down with a 2-minute stabilization window.

#### Scenario:

  ◦ Your service is latency-sensitive - scale up fast, but avoid flapping by scaling down slowly.
  ◦ KEDA supports the same `behavior` config as native HPA.

**Hint:** Use `spec.advanced.horizontalPodAutoscalerConfig.behavior`.

??? example "Solution"

    ```bash
    cat <<'EOF' | kubectl apply -f -
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: tuned-scaler
      namespace: keda-tasks
    spec:
      scaleTargetRef:
        name: nginx-demo
      minReplicaCount: 1
      maxReplicaCount: 20
      advanced:
        horizontalPodAutoscalerConfig:
          behavior:
            scaleUp:
              stabilizationWindowSeconds: 0
              policies:
                - type: Pods
                  value: 4
                  periodSeconds: 15
            scaleDown:
              stabilizationWindowSeconds: 120
              policies:
                - type: Pods
                  value: 1
                  periodSeconds: 60
      triggers:
        - type: cpu
          metadata:
            type: Utilization
            value: "60"
    EOF

    kubectl describe hpa -n keda-tasks
    ```

---

#### 09. Pause and Resume a ScaledObject

Temporarily pause KEDA scaling at a fixed replica count, then resume.

#### Scenario:

  ◦ You're performing maintenance on the metric source (e.g., Redis migration).
  ◦ You need to freeze replicas at the current count without deleting the ScaledObject.

**Hint:** Use the `autoscaling.keda.sh/paused-replicas` annotation.

??? example "Solution"

    ```bash
    # 1. Pause at 3 replicas
    kubectl annotate scaledobject cpu-scaler \
        -n keda-tasks \
        autoscaling.keda.sh/paused-replicas="3"

    # 2. Verify paused
    kubectl get scaledobject cpu-scaler -n keda-tasks -o yaml | grep -A2 annotations
    kubectl get deployment nginx-demo -n keda-tasks

    # 3. Resume
    kubectl annotate scaledobject cpu-scaler \
        -n keda-tasks \
        autoscaling.keda.sh/paused-replicas-

    # 4. Verify resumed
    kubectl describe scaledobject cpu-scaler -n keda-tasks
    ```

---

#### 10. Troubleshoot a Non-Scaling ScaledObject

Diagnose why a ScaledObject isn't scaling and fix the issue.

#### Scenario:

  ◦ A ScaledObject was applied but the Deployment stays at its initial replica count.
  ◦ You need to check status conditions, KEDA operator logs, and the managed HPA.

**Hint:** `kubectl describe scaledobject`, `kubectl logs -n keda`, `kubectl get hpa`.

??? example "Solution"

    ```bash
    # 1. Check ScaledObject status
    kubectl describe scaledobject <name> -n <namespace>
    # Look for:
    #   Ready: True/False
    #   Active: True/False
    #   External Metric Names

    # 2. Check the KEDA-managed HPA
    kubectl get hpa -n <namespace>
    kubectl describe hpa keda-hpa-<name> -n <namespace>

    # 3. Check KEDA operator logs for errors
    kubectl logs -n keda -l app=keda-operator --tail=100

    # 4. Common issues:
    # - Wrong address/host for the scaler → fix metadata.address
    # - Missing TriggerAuthentication → create one or fix the reference
    # - ScaledObject targeting wrong Deployment name → fix scaleTargetRef.name
    # - CRD validation error → check Events section

    # 5. Verify metric source connectivity
    kubectl run debug --rm -it --image=busybox -n <namespace> --restart=Never \
        -- sh -c "nc -zv redis.keda-tasks.svc 6379"

    # 6. Check if metrics are being exposed
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1" | jq '.resources[].name'
    ```
