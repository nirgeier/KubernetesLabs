---

# CronJobs

- In this lab, we will learn how to create and manage `CronJobs` in Kubernetes.
- A `CronJob` creates `Jobs` on a time-based schedule. It is useful for running periodic and recurring tasks, such as backups or report generation.

---

## What will we learn?

- What CronJobs are and how they work in Kubernetes
- How to create, monitor, and manage CronJobs
- How to view Job and Pod outputs from scheduled tasks

---

## Prerequisites

- A running Kubernetes cluster (`kubectl cluster-info` should work)
- `kubectl` configured against the cluster

---

## Introduction

- A `CronJob` in Kubernetes runs Jobs on a time-based schedule, similar to Linux cron.
- Useful for periodic tasks like backups, reports, or cleanup.

---

### Step 01 - Create a CronJob YAML
- Create a file named `hello-cronjob.yaml` with the following content:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
  namespace: default
spec:
  schedule: "*/1 * * * *" # Every 1 minute
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes CronJob!
          restartPolicy: OnFailure
```



### Step 02 - Apply the CronJob

```sh
kubectl apply -f hello-cronjob.yaml
```

### Step 03 - Verify CronJob Creation

```sh
kubectl get cronjob hello
```


### Step 04 - Check CronJob and Jobs

- List CronJobs:

```sh
kubectl get cronjobs
```

- List Jobs created by the CronJob:

```sh
kubectl get jobs
```

- List Pods created by Jobs:

```sh
kubectl get pods
```



### Step 05 - View Job Output

- Get the name of a pod created by the CronJob, then view its logs:

```sh
kubectl logs <pod-name>
```

Example output:

```
Mon Nov 10 12:00:00 UTC 2025
Hello from the Kubernetes CronJob!
```


---

## Cleanup

```sh
kubectl delete cronjob hello
kubectl delete jobs --all
```

---

## Questions

- What happens if the job takes longer than the schedule interval?
- How would you change the schedule to run every 5 minutes?
- How can you limit the number of successful or failed jobs to keep?

