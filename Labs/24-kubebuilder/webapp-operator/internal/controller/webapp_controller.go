// Package controller implements the WebApp reconciler.
package controller

import (
	"context"
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	webappv1 "codewizard.io/webapp-operator/api/v1"
)

const webappFinalizer = "apps.codewizard.io/finalizer"

// WebAppReconciler reconciles a WebApp object.
type WebAppReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// RBAC markers - controller-gen turns these into config/rbac/role.yaml
//
//+kubebuilder:rbac:groups=apps.codewizard.io,resources=webapps,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps.codewizard.io,resources=webapps/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=apps.codewizard.io,resources=webapps/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=configmaps,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=events,verbs=create;patch

// Reconcile is the main reconciliation loop.
// It is called whenever a WebApp CR, or any resource it owns, changes.
func (r *WebAppReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// ── Step 1: Fetch the WebApp instance ─────────────────────────────────────
	webapp := &webappv1.WebApp{}
	if err := r.Get(ctx, req.NamespacedName, webapp); err != nil {
		if errors.IsNotFound(err) {
			// Object was deleted before we could reconcile - nothing to do.
			logger.Info("WebApp not found, likely deleted", "name", req.Name)
			return ctrl.Result{}, nil
		}
		return ctrl.Result{}, fmt.Errorf("fetching WebApp: %w", err)
	}

	// ── Step 2: Finalizer handling ─────────────────────────────────────────────
	if webapp.DeletionTimestamp.IsZero() {
		// Object is NOT being deleted - ensure finalizer is registered
		if !controllerutil.ContainsFinalizer(webapp, webappFinalizer) {
			controllerutil.AddFinalizer(webapp, webappFinalizer)
			if err := r.Update(ctx, webapp); err != nil {
				return ctrl.Result{}, err
			}
			// Re-queue after updating the object
			return ctrl.Result{}, nil
		}
	} else {
		// Object IS being deleted - run cleanup before Kubernetes removes it
		if controllerutil.ContainsFinalizer(webapp, webappFinalizer) {
			logger.Info("Running finalizer cleanup", "name", webapp.Name)
			// Add any external resource cleanup here (e.g., cloud DNS, certificates)

			// Remove finalizer - Kubernetes will then delete the object
			controllerutil.RemoveFinalizer(webapp, webappFinalizer)
			if err := r.Update(ctx, webapp); err != nil {
				return ctrl.Result{}, err
			}
		}
		return ctrl.Result{}, nil
	}

	// ── Step 3: Short-circuit when paused ─────────────────────────────────────
	if webapp.Spec.Paused {
		logger.Info("WebApp is paused, skipping reconciliation", "name", webapp.Name)
		return ctrl.Result{}, nil
	}

	logger.Info("Reconciling WebApp",
		"name", webapp.Name,
		"namespace", webapp.Namespace,
		"replicas", webapp.Spec.Replicas)

	// ── Step 4: Reconcile ConfigMap (HTML content) ────────────────────────────
	if err := r.reconcileConfigMap(ctx, webapp); err != nil {
		return ctrl.Result{}, fmt.Errorf("reconciling ConfigMap: %w", err)
	}

	// ── Step 5: Reconcile Deployment ──────────────────────────────────────────
	deployment, err := r.reconcileDeployment(ctx, webapp)
	if err != nil {
		return ctrl.Result{}, fmt.Errorf("reconciling Deployment: %w", err)
	}

	// ── Step 6: Reconcile Service ─────────────────────────────────────────────
	if err := r.reconcileService(ctx, webapp); err != nil {
		return ctrl.Result{}, fmt.Errorf("reconciling Service: %w", err)
	}

	// ── Step 7: Update Status ─────────────────────────────────────────────────
	if err := r.updateStatus(ctx, webapp, deployment); err != nil {
		return ctrl.Result{}, fmt.Errorf("updating status: %w", err)
	}

	return ctrl.Result{}, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// reconcileConfigMap ensures the HTML ConfigMap exists and is up-to-date.
// ─────────────────────────────────────────────────────────────────────────────
func (r *WebAppReconciler) reconcileConfigMap(ctx context.Context, webapp *webappv1.WebApp) error {
	logger := log.FromContext(ctx)

	desired := &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      webapp.Name + "-html",
			Namespace: webapp.Namespace,
			Labels:    labelsForWebApp(webapp.Name),
		},
		Data: map[string]string{
			"index.html": fmt.Sprintf(`<!DOCTYPE html>
<html>
<head><title>%s</title></head>
<body>
  <h1>%s</h1>
  <p>Managed by the <strong>WebApp Operator</strong> | Instance: <strong>%s</strong></p>
</body>
</html>`, webapp.Spec.Message, webapp.Spec.Message, webapp.Name),
		},
	}

	// Owner reference: ConfigMap is garbage-collected when the WebApp CR is deleted
	if err := ctrl.SetControllerReference(webapp, desired, r.Scheme); err != nil {
		return err
	}

	existing := &corev1.ConfigMap{}
	err := r.Get(ctx, types.NamespacedName{Name: desired.Name, Namespace: desired.Namespace}, existing)
	if errors.IsNotFound(err) {
		logger.Info("Creating ConfigMap", "name", desired.Name)
		return r.Create(ctx, desired)
	}
	if err != nil {
		return err
	}

	// Update only if the content changed
	if existing.Data["index.html"] != desired.Data["index.html"] {
		existing.Data = desired.Data
		logger.Info("Updating ConfigMap", "name", existing.Name)
		return r.Update(ctx, existing)
	}

	return nil
}

// ─────────────────────────────────────────────────────────────────────────────
// reconcileDeployment ensures the nginx Deployment exists and matches spec.
// ─────────────────────────────────────────────────────────────────────────────
func (r *WebAppReconciler) reconcileDeployment(ctx context.Context, webapp *webappv1.WebApp) (*appsv1.Deployment, error) {
	logger := log.FromContext(ctx)

	labels := labelsForWebApp(webapp.Name)
	replicas := webapp.Spec.Replicas
	maxUnavailable := intstr.FromInt32(webapp.Spec.MaxUnavailable)

	desired := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      webapp.Name,
			Namespace: webapp.Namespace,
			Labels:    labels,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{MatchLabels: labels},
			Strategy: appsv1.DeploymentStrategy{
				Type: appsv1.RollingUpdateDeploymentStrategyType,
				RollingUpdate: &appsv1.RollingUpdateDeployment{
					MaxUnavailable: &maxUnavailable,
				},
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{Labels: labels},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:            "nginx",
							Image:           webapp.Spec.Image,
							ImagePullPolicy: corev1.PullIfNotPresent,
							Ports: []corev1.ContainerPort{
								{ContainerPort: webapp.Spec.Port, Protocol: corev1.ProtocolTCP},
							},
							VolumeMounts: []corev1.VolumeMount{
								{
									Name:      "html",
									MountPath: "/usr/share/nginx/html",
								},
							},
							ReadinessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									HTTPGet: &corev1.HTTPGetAction{
										Path: "/",
										Port: intstr.FromInt32(webapp.Spec.Port),
									},
								},
								InitialDelaySeconds: 5,
								PeriodSeconds:       10,
							},
							LivenessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									HTTPGet: &corev1.HTTPGetAction{
										Path: "/",
										Port: intstr.FromInt32(webapp.Spec.Port),
									},
								},
								InitialDelaySeconds: 15,
								PeriodSeconds:       20,
							},
						},
					},
					Volumes: []corev1.Volume{
						{
							Name: "html",
							VolumeSource: corev1.VolumeSource{
								ConfigMap: &corev1.ConfigMapVolumeSource{
									LocalObjectReference: corev1.LocalObjectReference{
										Name: webapp.Name + "-html",
									},
								},
							},
						},
					},
				},
			},
		},
	}

	if err := ctrl.SetControllerReference(webapp, desired, r.Scheme); err != nil {
		return nil, err
	}

	existing := &appsv1.Deployment{}
	err := r.Get(ctx, types.NamespacedName{Name: desired.Name, Namespace: desired.Namespace}, existing)
	if errors.IsNotFound(err) {
		logger.Info("Creating Deployment", "name", desired.Name)
		if err := r.Create(ctx, desired); err != nil {
			return nil, err
		}
		return desired, nil
	}
	if err != nil {
		return nil, err
	}

	// Reconcile mutable fields: replicas, image, and port
	needsUpdate := false
	if *existing.Spec.Replicas != replicas {
		existing.Spec.Replicas = &replicas
		needsUpdate = true
	}
	containers := existing.Spec.Template.Spec.Containers
	if len(containers) == 0 {
		logger.Error(nil, "Deployment has no containers", "name", existing.Name)
		return existing, nil
	}
	if containers[0].Image != webapp.Spec.Image {
		existing.Spec.Template.Spec.Containers[0].Image = webapp.Spec.Image
		needsUpdate = true
	}
	if len(containers[0].Ports) > 0 && containers[0].Ports[0].ContainerPort != webapp.Spec.Port {
		existing.Spec.Template.Spec.Containers[0].Ports[0].ContainerPort = webapp.Spec.Port
		needsUpdate = true
	}

	if needsUpdate {
		logger.Info("Updating Deployment",
			"name", existing.Name,
			"replicas", replicas,
			"image", webapp.Spec.Image)
		if err := r.Update(ctx, existing); err != nil {
			return nil, err
		}
	}

	return existing, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// reconcileService ensures the Service exists and matches spec.
// ─────────────────────────────────────────────────────────────────────────────
func (r *WebAppReconciler) reconcileService(ctx context.Context, webapp *webappv1.WebApp) error {
	logger := log.FromContext(ctx)

	labels := labelsForWebApp(webapp.Name)
	svcType := corev1.ServiceType(webapp.Spec.ServiceType)

	desired := &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      webapp.Name,
			Namespace: webapp.Namespace,
			Labels:    labels,
		},
		Spec: corev1.ServiceSpec{
			Selector: labels,
			Type:     svcType,
			Ports: []corev1.ServicePort{
				{
					Name:       "http",
					Port:       webapp.Spec.Port,
					TargetPort: intstr.FromInt32(webapp.Spec.Port),
					Protocol:   corev1.ProtocolTCP,
				},
			},
		},
	}

	if err := ctrl.SetControllerReference(webapp, desired, r.Scheme); err != nil {
		return err
	}

	existing := &corev1.Service{}
	err := r.Get(ctx, types.NamespacedName{Name: desired.Name, Namespace: desired.Namespace}, existing)
	if errors.IsNotFound(err) {
		logger.Info("Creating Service", "name", desired.Name)
		return r.Create(ctx, desired)
	}
	if err != nil {
		return err
	}

	// ServiceType is effectively immutable - recreate if changed
	if existing.Spec.Type != svcType {
		logger.Info("Recreating Service due to type change",
			"old", existing.Spec.Type, "new", svcType)
		if err := r.Delete(ctx, existing); err != nil {
			return err
		}
		return r.Create(ctx, desired)
	}

	// Reconcile port changes
	if len(existing.Spec.Ports) > 0 && existing.Spec.Ports[0].Port != webapp.Spec.Port {
		existing.Spec.Ports[0].Port = webapp.Spec.Port
		existing.Spec.Ports[0].TargetPort = intstr.FromInt32(webapp.Spec.Port)
		logger.Info("Updating Service port", "name", existing.Name, "port", webapp.Spec.Port)
		return r.Update(ctx, existing)
	}

	return nil
}

// ─────────────────────────────────────────────────────────────────────────────
// updateStatus computes and persists the WebApp status.
// ─────────────────────────────────────────────────────────────────────────────
func (r *WebAppReconciler) updateStatus(ctx context.Context, webapp *webappv1.WebApp, deployment *appsv1.Deployment) error {
	// Work on a DeepCopy to avoid mutating the cached object
	updated := webapp.DeepCopy()

	available := deployment.Status.AvailableReplicas
	ready := deployment.Status.ReadyReplicas

	updated.Status.AvailableReplicas = available
	updated.Status.ReadyReplicas = ready
	updated.Status.DeploymentName = deployment.Name
	updated.Status.ServiceName = webapp.Name

	// Populate the in-cluster URL from the Service ClusterIP
	logger := log.FromContext(ctx)
	svc := &corev1.Service{}
	if err := r.Get(ctx, types.NamespacedName{Name: webapp.Name, Namespace: webapp.Namespace}, svc); err == nil {
		if svc.Spec.ClusterIP != "" && svc.Spec.ClusterIP != "None" {
			updated.Status.URL = fmt.Sprintf("http://%s:%d", svc.Spec.ClusterIP, webapp.Spec.Port)
		}
	} else if !errors.IsNotFound(err) {
		logger.Error(err, "Failed to fetch Service for status", "name", webapp.Name)
	}

	// Compute Phase
	switch {
	case available == 0:
		updated.Status.Phase = webappv1.WebAppPhasePending
	case ready < webapp.Spec.Replicas:
		updated.Status.Phase = webappv1.WebAppPhaseDegraded
	default:
		updated.Status.Phase = webappv1.WebAppPhaseRunning
	}

	// Set the Available condition
	availableCond := metav1.Condition{
		Type:               webappv1.ConditionTypeAvailable,
		ObservedGeneration: webapp.Generation,
		LastTransitionTime: metav1.Now(),
	}
	if available >= webapp.Spec.Replicas {
		availableCond.Status = metav1.ConditionTrue
		availableCond.Reason = "DeploymentAvailable"
		availableCond.Message = fmt.Sprintf("%d/%d replicas are available", available, webapp.Spec.Replicas)
	} else {
		availableCond.Status = metav1.ConditionFalse
		availableCond.Reason = "DeploymentUnavailable"
		availableCond.Message = fmt.Sprintf("only %d/%d replicas are available", available, webapp.Spec.Replicas)
	}
	meta.SetStatusCondition(&updated.Status.Conditions, availableCond)

	// Only call Status().Update() when something actually changed
	if updated.Status.Phase != webapp.Status.Phase ||
		updated.Status.AvailableReplicas != webapp.Status.AvailableReplicas ||
		updated.Status.ReadyReplicas != webapp.Status.ReadyReplicas ||
		updated.Status.URL != webapp.Status.URL {
		return r.Status().Update(ctx, updated)
	}

	return nil
}

// ─────────────────────────────────────────────────────────────────────────────
// SetupWithManager wires the controller into the manager.
// ─────────────────────────────────────────────────────────────────────────────
func (r *WebAppReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		// Primary watch: reconcile whenever a WebApp CR changes
		For(&webappv1.WebApp{}).
		// Secondary watches: reconcile the parent WebApp when a child resource changes
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		Owns(&corev1.ConfigMap{}).
		Complete(r)
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

// labelsForWebApp returns the standard label set applied to all child resources.
func labelsForWebApp(name string) map[string]string {
	return map[string]string{
		"app.kubernetes.io/name":       "webapp",
		"app.kubernetes.io/instance":   name,
		"app.kubernetes.io/managed-by": "webapp-operator",
	}
}
