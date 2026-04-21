// Package v1 contains the admission webhook for the WebApp API.
package v1

import (
	"fmt"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/util/validation/field"
	ctrl "sigs.k8s.io/controller-runtime"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

var webapplog = logf.Log.WithName("webapp-webhook")

// SetupWebhookWithManager registers the webhook handlers with the controller-runtime manager.
func (r *WebApp) SetupWebhookWithManager(mgr ctrl.Manager) error {
	return ctrl.NewWebhookManagedBy(mgr).
		For(r).
		Complete()
}

// ────────────────────────────────────────────────────────────────────────────
// Defaulting webhook (MutatingAdmissionWebhook)
// ────────────────────────────────────────────────────────────────────────────

//+kubebuilder:webhook:path=/mutate-apps-codewizard-io-v1-webapp,mutating=true,failurePolicy=fail,sideEffects=None,groups=apps.codewizard.io,resources=webapps,verbs=create;update,versions=v1,name=mwebapp.kb.io,admissionReviewVersions=v1

var _ webhook.Defaulter = &WebApp{}

// Default applies default values to the WebApp when it is created or updated.
// This is the MutatingAdmissionWebhook handler.
func (r *WebApp) Default() {
	webapplog.Info("Applying defaults", "name", r.Name)

	if r.Spec.Image == "" {
		r.Spec.Image = "nginx:1.25.3"
	}
	if r.Spec.Replicas == 0 {
		r.Spec.Replicas = 1
	}
	if r.Spec.Port == 0 {
		r.Spec.Port = 80
	}
	if r.Spec.ServiceType == "" {
		r.Spec.ServiceType = "ClusterIP"
	}
	if r.Spec.MaxUnavailable == 0 {
		r.Spec.MaxUnavailable = 1
	}
}

// ────────────────────────────────────────────────────────────────────────────
// Validation webhook (ValidatingAdmissionWebhook)
// ────────────────────────────────────────────────────────────────────────────

//+kubebuilder:webhook:path=/validate-apps-codewizard-io-v1-webapp,mutating=false,failurePolicy=fail,sideEffects=None,groups=apps.codewizard.io,resources=webapps,verbs=create;update,versions=v1,name=vwebapp.kb.io,admissionReviewVersions=v1

var _ webhook.Validator = &WebApp{}

// ValidateCreate validates a new WebApp on creation.
func (r *WebApp) ValidateCreate() (admission.Warnings, error) {
	webapplog.Info("Validating create", "name", r.Name)
	return r.validateWebApp(nil)
}

// ValidateUpdate validates an updated WebApp.
func (r *WebApp) ValidateUpdate(old runtime.Object) (admission.Warnings, error) {
	webapplog.Info("Validating update", "name", r.Name)
	oldWebApp, ok := old.(*WebApp)
	if !ok {
		return nil, fmt.Errorf("expected *WebApp, got %T", old)
	}
	return r.validateWebApp(oldWebApp)
}

// ValidateDelete is called on deletion. We allow all deletions.
func (r *WebApp) ValidateDelete() (admission.Warnings, error) {
	return nil, nil
}

// validateWebApp contains the shared validation logic for create and update.
// oldWebApp is nil on create.
func (r *WebApp) validateWebApp(oldWebApp *WebApp) (admission.Warnings, error) {
	var errs field.ErrorList

	// ── Replica count ─────────────────────────────────────────────────────────
	if r.Spec.Replicas < 1 || r.Spec.Replicas > 10 {
		errs = append(errs, field.Invalid(
			field.NewPath("spec", "replicas"),
			r.Spec.Replicas,
			"must be between 1 and 10",
		))
	}

	// ── Message is required ────────────────────────────────────────────────────
	if r.Spec.Message == "" {
		errs = append(errs, field.Required(
			field.NewPath("spec", "message"),
			"message is required and cannot be empty",
		))
	}

	// ── Image must not be empty ────────────────────────────────────────────────
	if r.Spec.Image == "" {
		errs = append(errs, field.Required(
			field.NewPath("spec", "image"),
			"image is required",
		))
	}

	// ── Update-only: prevent downscaling to 0 if already running ──────────────
	if oldWebApp != nil && oldWebApp.Spec.Replicas > 0 && r.Spec.Replicas == 0 {
		errs = append(errs, field.Forbidden(
			field.NewPath("spec", "replicas"),
			"cannot downscale to 0 while the WebApp is running; delete the resource instead",
		))
	}

	// ── MaxUnavailable must not exceed replicas ────────────────────────────────
	if r.Spec.MaxUnavailable > r.Spec.Replicas {
		errs = append(errs, field.Invalid(
			field.NewPath("spec", "maxUnavailable"),
			r.Spec.MaxUnavailable,
			fmt.Sprintf("cannot exceed replicas (%d)", r.Spec.Replicas),
		))
	}

	if len(errs) > 0 {
		return nil, apierrors.NewInvalid(
			schema.GroupKind{Group: "apps.codewizard.io", Kind: "WebApp"},
			r.Name,
			errs,
		)
	}

	return nil, nil
}
