# Lab 30 — EFK Stack (Elasticsearch, Fluent Bit, Kibana)

Goal
----

Deploy a complete centralized logging stack on Kubernetes:
- **Elasticsearch**: Store and index logs.
- **Fluent Bit**: Collect container logs and ship them to Elasticsearch.
- **Kibana**: Visualize and query the logs.
- **Log Generator**: A sample app generating structured logs to verify the pipeline.

What you will learn
-------------------

- Architecture of the EFK stack.
- Installing Elasticsearch and Kibana using Helm.
- Configuring Fluent Bit to parse logs and output to Elasticsearch.
- Creating Kibana Data Views and discovering logs.

Files in this lab
-----------------

- `demo.sh` — Automated script to deploy the entire stack.
- `manifests/` — Kubernetes manifests for Fluent Bit (ConfigMap, DaemonSet, RBAC).
- `sample-app/` — Sample log generator application.

Prerequisites
-------------

- A running Kubernetes cluster.
- `helm` installed (v3+).
- Sufficient memory (Elasticsearch requires ~2GB+ allocated potentially, though we'll use a small setup).

Architecture
------------

1. **Fluent Bit** runs as a **DaemonSet** on every node. It tails container logs from `/var/log/containers/*.log`.
2. **Fluent Bit** parses/filters these logs and sends them to the **Elasticsearch** service.
3. **Elasticsearch** (StatefulSet) indexes the data.
4. **Kibana** (Deployment) connects to Elasticsearch and provides a web UI.

Run the Demo
-----------

The demo script handles the Helm installation, manifest application, and automatically opens the Kibana dashboard.

```bash
chmod +x Labs/30-fluentbit/demo.sh
Labs/30-fluentbit/demo.sh
```

What the demo does:
1. Installs Elasticsearch and Kibana via Helm.
2. Deploys Fluent Bit (DaemonSet) and the Log Generator app.
3. Waits for all pods to be ready.
4. **Automatically port-forwards** Kibana (5601) and Elasticsearch (9200) in the background.
5. **Prints credentials** (Username: `elastic`, Password: `<generated>`).
6. **Opens Kibana** in your default browser.

To stop the background port-forwards later, the script provides a kill command (or you can close your terminal).

Accessing Kibana
----------------

Once the browser opens at [http://localhost:5601](http://localhost:5601):

1. **Log in** using the credentials printed by the script.
2. Go to **Management** -> **Stack Management**.
3. Under **Kibana**, click **Data Views**.
4. Create a data view:
   - Name: `fluent-bit*`
   - Timestamp field: `@timestamp`
5. Go to **Analytics** -> **Discover** to see live logs from the `log-generator` app.

Mock Data
---------

The `log-generator` app emits JSON structured logs every second. You should see fields like `app`, `message`, `random_id` in Kibana.
