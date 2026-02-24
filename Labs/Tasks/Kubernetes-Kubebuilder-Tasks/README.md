# Kubernetes Kubebuilder Tasks

- Hands-on Kubernetes exercises covering Kubebuilder operator development, CRD creation, reconciliation loops, webhooks, and testing.
- Each task includes a description, scenario, and a detailed solution with step-by-step instructions.
- Practice these tasks to master building production-grade Kubernetes operators.

#### Table of Contents

- [01. Initialize a Kubebuilder Project](#01-initialize-a-kubebuilder-project)
- [02. Create a CRD API and Controller](#02-create-a-crd-api-and-controller)
- [03. Define CRD Types with Validation Markers](#03-define-crd-types-with-validation-markers)
- [04. Generate and Install CRDs](#04-generate-and-install-crds)
- [05. Implement a Basic Reconciler](#05-implement-a-basic-reconciler)
- [06. Run the Controller Locally](#06-run-the-controller-locally)
- [07. Add Owner References for Garbage Collection](#07-add-owner-references-for-garbage-collection)
- [08. Update Status Subresource](#08-update-status-subresource)
- [09. Add a Finalizer](#09-add-a-finalizer)
- [10. Write a Controller Test with envtest](#10-write-a-controller-test-with-envtest)

---

#### 01. Initialize a Kubebuilder Project

Scaffold a new operator project using `kubebuilder init` and explore the generated files.

#### Scenario:

  ◦ You're starting a new operator project and need the project skeleton.
  ◦ `kubebuilder init` creates the Makefile, Go module, and base Kustomize configs.

**Hint:** `kubebuilder init --domain <domain> --repo <module>`

??? example "Solution"

    ```bash
    # 1. Create and enter project directory
    mkdir my-operator && cd my-operator

    # 2. Initialize the project
    kubebuilder init \
        --domain example.com \
        --repo example.com/my-operator

    # 3. Explore generated files
    ls -la
    cat go.mod
    cat Makefile | head -30
    cat cmd/main.go | head -20

    # 4. View available Make targets
    make help

    # Cleanup (if needed)
    cd .. && rm -rf my-operator
    ```

---

#### 02. Create a CRD API and Controller

Use `kubebuilder create api` to scaffold a new CRD type and its controller.

#### Scenario:

  ◦ You need a custom resource called `MyApp` in the `apps` group.
  ◦ Kubebuilder scaffolds both the Go type and the controller stub.

**Hint:** `kubebuilder create api --group apps --version v1 --kind MyApp`

??? example "Solution"

    ```bash
    # 1. Create the API (answer y to both prompts)
    kubebuilder create api \
        --group apps \
        --version v1 \
        --kind MyApp

    # 2. Inspect the generated type
    cat api/v1/myapp_types.go

    # 3. Inspect the generated controller
    cat internal/controller/myapp_controller.go

    # 4. Check that main.go was updated
    grep MyApp cmd/main.go
    ```

---

#### 03. Define CRD Types with Validation Markers

Add fields to the CRD spec with Kubebuilder validation markers for min/max, enums, and defaults.

#### Scenario:

  ◦ Your CRD needs a `replicas` field (1–10, default 1) and a `tier` field (enum: basic/premium).
  ◦ Markers auto-generate OpenAPI v3 validation in the CRD YAML.

**Hint:** Use `//+kubebuilder:validation:Minimum=1`, `//+kubebuilder:default=1`, `//+kubebuilder:validation:Enum=basic;premium`.

??? example "Solution"

    ```go
    // Edit api/v1/myapp_types.go — replace MyAppSpec:

    type MyAppSpec struct {
        // Replicas is the desired number of pods.
        // +kubebuilder:validation:Minimum=1
        // +kubebuilder:validation:Maximum=10
        // +kubebuilder:default=1
        Replicas int32 `json:"replicas,omitempty"`

        // Tier is the service tier.
        // +kubebuilder:validation:Enum=basic;premium
        // +kubebuilder:default=basic
        Tier string `json:"tier,omitempty"`

        // Message is displayed by the application.
        // +kubebuilder:validation:MinLength=1
        // +kubebuilder:validation:MaxLength=200
        Message string `json:"message"`
    }
    ```

    ```bash
    # Regenerate deepcopy functions
    make generate

    # Regenerate CRD YAML with validation
    make manifests

    # Inspect the generated CRD
    cat config/crd/bases/*.yaml | grep -A20 "properties:"
    ```

---

#### 04. Generate and Install CRDs

Run `make manifests`, `make install`, and verify the CRD is registered in the cluster.

#### Scenario:

  ◦ After defining your types, you need to generate the CRD YAML and apply it to the cluster.
  ◦ This makes `kubectl get myapps` work.

**Hint:** `make generate && make manifests && make install`

??? example "Solution"

    ```bash
    # 1. Generate deepcopy + CRD + RBAC
    make generate
    make manifests

    # 2. Install CRDs into the cluster
    make install

    # 3. Verify the CRD exists
    kubectl get crds | grep example.com
    kubectl describe crd myapps.apps.example.com

    # 4. Test that the API resource is available
    kubectl get myapps
    # "No resources found in default namespace."

    # 5. Check the short name (if configured)
    kubectl api-resources --api-group=apps.example.com
    ```

---

#### 05. Implement a Basic Reconciler

Write a reconciler that creates a Deployment when a CR is created.

#### Scenario:

  ◦ When a user creates a `MyApp` CR, your controller should create a corresponding Deployment.
  ◦ The reconciler fetches the CR, checks if a Deployment exists, and creates it if missing.

**Hint:** Use `r.Get()` to fetch, `errors.IsNotFound()` to check, `r.Create()` to create.

??? example "Solution"

    ```go
    // In internal/controller/myapp_controller.go — Reconcile method:

    func (r *MyAppReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
        logger := log.FromContext(ctx)

        // Fetch the CR
        myapp := &appsv1.MyApp{}
        if err := r.Get(ctx, req.NamespacedName, myapp); err != nil {
            if errors.IsNotFound(err) {
                return ctrl.Result{}, nil
            }
            return ctrl.Result{}, err
        }

        // Check if Deployment exists
        dep := &appsv1.Deployment{}
        err := r.Get(ctx, types.NamespacedName{
            Name: myapp.Name, Namespace: myapp.Namespace,
        }, dep)

        if errors.IsNotFound(err) {
            logger.Info("Creating Deployment", "name", myapp.Name)
            // Build the Deployment
            dep = buildDeployment(myapp)
            ctrl.SetControllerReference(myapp, dep, r.Scheme)
            return ctrl.Result{}, r.Create(ctx, dep)
        }

        return ctrl.Result{}, err
    }
    ```

    ```bash
    # Run locally
    make run

    # In another terminal, create a CR
    kubectl apply -f config/samples/apps_v1_myapp.yaml

    # Verify the Deployment was created
    kubectl get deployments
    ```

---

#### 06. Run the Controller Locally

Use `make run` to run the operator on your machine against the cluster.

#### Scenario:

  ◦ During development, you run the controller locally using your kubeconfig.
  ◦ This is faster than building a Docker image for every change.

**Hint:** `make install && make run`

??? example "Solution"

    ```bash
    # 1. Ensure CRDs are installed
    make install

    # 2. Run the controller
    make run
    # INFO    Starting manager
    # INFO    Starting Controller    {"controller": "myapp"}

    # 3. In another terminal, create and delete CRs to test
    kubectl apply -f config/samples/apps_v1_myapp.yaml
    kubectl get myapps
    kubectl delete myapp my-myapp

    # 4. Stop the controller with Ctrl+C
    ```

---

#### 07. Add Owner References for Garbage Collection

Set owner references on child resources so they are automatically deleted when the parent CR is deleted.

#### Scenario:

  ◦ When a user deletes a `MyApp` CR, the Deployment, Service, and ConfigMap should be cleaned up.
  ◦ Owner references enable Kubernetes garbage collection.

**Hint:** Use `ctrl.SetControllerReference(parent, child, r.Scheme)` before creating the child.

??? example "Solution"

    ```go
    // Before r.Create(ctx, deployment):
    if err := ctrl.SetControllerReference(myapp, deployment, r.Scheme); err != nil {
        return ctrl.Result{}, err
    }
    ```

    ```bash
    # Test: create a CR, verify child resources exist
    kubectl apply -f config/samples/apps_v1_myapp.yaml
    kubectl get deployment -l app.kubernetes.io/managed-by=my-operator

    # Verify owner reference is set
    kubectl get deployment <name> -o jsonpath='{.metadata.ownerReferences}' | jq

    # Delete the CR — children should be garbage-collected
    kubectl delete myapp my-myapp
    kubectl get deployments  # Should be gone
    ```

---

#### 08. Update Status Subresource

Update the CR's `.status` fields to reflect the current state of managed resources.

#### Scenario:

  ◦ Users need to see the current state (e.g., available replicas, phase) via `kubectl get myapps`.
  ◦ Status updates use the `/status` subresource to avoid triggering spec watches.

**Hint:** Use `r.Status().Update(ctx, updated)` after computing the status.

??? example "Solution"

    ```go
    // At the end of Reconcile(), after reconciling child resources:
    updated := myapp.DeepCopy()
    updated.Status.AvailableReplicas = deployment.Status.AvailableReplicas
    updated.Status.Phase = "Running"

    if err := r.Status().Update(ctx, updated); err != nil {
        return ctrl.Result{}, err
    }
    ```

    ```bash
    # Apply a CR
    kubectl apply -f config/samples/apps_v1_myapp.yaml

    # Check status
    kubectl get myapp my-myapp -o jsonpath='{.status}' | jq

    # With printer columns configured:
    kubectl get myapps
    # NAME       REPLICAS   AVAILABLE   PHASE
    # my-myapp   2          2           Running
    ```

---

#### 09. Add a Finalizer

Implement a finalizer that runs custom cleanup logic before the CR is deleted.

#### Scenario:

  ◦ Your operator manages external resources (e.g., DNS records, cloud storage) that need cleanup.
  ◦ Finalizers prevent deletion until cleanup is done.

**Hint:** Use `controllerutil.AddFinalizer/RemoveFinalizer`, check `DeletionTimestamp.IsZero()`.

??? example "Solution"

    ```go
    const myFinalizer = "apps.example.com/finalizer"

    // In Reconcile(), after fetching the CR:
    if myapp.DeletionTimestamp.IsZero() {
        if !controllerutil.ContainsFinalizer(myapp, myFinalizer) {
            controllerutil.AddFinalizer(myapp, myFinalizer)
            return ctrl.Result{}, r.Update(ctx, myapp)
        }
    } else {
        if controllerutil.ContainsFinalizer(myapp, myFinalizer) {
            logger.Info("Running cleanup for", "name", myapp.Name)
            // Do external cleanup here...

            controllerutil.RemoveFinalizer(myapp, myFinalizer)
            return ctrl.Result{}, r.Update(ctx, myapp)
        }
        return ctrl.Result{}, nil
    }
    ```

    ```bash
    # Create and then delete — observe cleanup in operator logs
    kubectl apply -f config/samples/apps_v1_myapp.yaml
    kubectl delete myapp my-myapp

    # The operator log should show "Running cleanup for"
    ```

---

#### 10. Write a Controller Test with envtest

Write a Ginkgo/Gomega integration test that verifies your controller creates a Deployment.

#### Scenario:

  ◦ You need automated tests for your operator that run without a real cluster.
  ◦ `envtest` starts a local API server and etcd for testing.

**Hint:** Use `k8sClient.Create()` to create a CR, then `Eventually()` to wait for the Deployment.

??? example "Solution"

    ```go
    // internal/controller/myapp_controller_test.go
    var _ = Describe("MyApp Controller", func() {
        ctx := context.Background()

        It("should create a Deployment when a MyApp is created", func() {
            myapp := &v1.MyApp{
                ObjectMeta: metav1.ObjectMeta{
                    Name:      "test-app",
                    Namespace: "default",
                },
                Spec: v1.MyAppSpec{
                    Replicas: 2,
                    Message:  "test",
                },
            }
            Expect(k8sClient.Create(ctx, myapp)).To(Succeed())

            deployment := &appsv1.Deployment{}
            Eventually(func() error {
                return k8sClient.Get(ctx, types.NamespacedName{
                    Name:      "test-app",
                    Namespace: "default",
                }, deployment)
            }, time.Second*30, time.Millisecond*250).Should(Succeed())

            Expect(*deployment.Spec.Replicas).To(Equal(int32(2)))
        })
    })
    ```

    ```bash
    # Run tests
    make test

    # Verbose output
    make test ARGS="-v"
    ```
