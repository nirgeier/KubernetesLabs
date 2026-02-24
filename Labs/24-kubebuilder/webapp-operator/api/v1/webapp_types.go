// Package v1 contains API Schema definitions for the apps v1 API group.
// +kubebuilder:object:generate=true
// +groupName=apps.codewizard.io
package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// WebAppSpec defines the desired state of WebApp.
type WebAppSpec struct {
	// Replicas is the desired number of nginx Pods.
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=10
	// +kubebuilder:default=1
	Replicas int32 `json:"replicas,omitempty"`

	// Image is the nginx container image (repository:tag).
	// +kubebuilder:default="nginx:1.25.3"
	// +kubebuilder:validation:MinLength=1
	Image string `json:"image,omitempty"`

	// Message is the HTML body text served by nginx.
	// +kubebuilder:validation:MinLength=1
	// +kubebuilder:validation:MaxLength=500
	Message string `json:"message"`

	// Port is the container port nginx listens on.
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=65535
	// +kubebuilder:default=80
	Port int32 `json:"port,omitempty"`

	// ServiceType controls how the Service is exposed.
	// +kubebuilder:validation:Enum=ClusterIP;NodePort;LoadBalancer
	// +kubebuilder:default=ClusterIP
	ServiceType string `json:"serviceType,omitempty"`

	// Paused halts reconciliation when true, leaving all child resources unchanged.
	// +kubebuilder:default=false
	Paused bool `json:"paused,omitempty"`

	// MaxUnavailable is the max number of Pods that can be unavailable during a rolling update.
	// +kubebuilder:validation:Minimum=0
	// +kubebuilder:default=1
	MaxUnavailable int32 `json:"maxUnavailable,omitempty"`
}

// WebAppPhase is a simple enum for the overall lifecycle state.
// +kubebuilder:validation:Enum=Pending;Running;Degraded;Failed
type WebAppPhase string

const (
	WebAppPhasePending  WebAppPhase = "Pending"
	WebAppPhaseRunning  WebAppPhase = "Running"
	WebAppPhaseDegraded WebAppPhase = "Degraded"
	WebAppPhaseFailed   WebAppPhase = "Failed"
)

// Condition type constants
const (
	// ConditionTypeAvailable means the WebApp has at least one ready pod.
	ConditionTypeAvailable = "Available"
	// ConditionTypeProgressing means a rollout or scale is in progress.
	ConditionTypeProgressing = "Progressing"
	// ConditionTypeDegraded means some (but not all) replicas are ready.
	ConditionTypeDegraded = "Degraded"
)

// WebAppStatus defines the observed state of WebApp.
type WebAppStatus struct {
	// AvailableReplicas is the number of Pods in the Ready state.
	AvailableReplicas int32 `json:"availableReplicas,omitempty"`

	// ReadyReplicas is the number of Pods that have passed readiness checks.
	ReadyReplicas int32 `json:"readyReplicas,omitempty"`

	// Phase is a high-level summary of the WebApp lifecycle.
	Phase WebAppPhase `json:"phase,omitempty"`

	// DeploymentName is the name of the managed Deployment.
	DeploymentName string `json:"deploymentName,omitempty"`

	// ServiceName is the name of the managed Service.
	ServiceName string `json:"serviceName,omitempty"`

	// URL is the in-cluster reachable address of the web application.
	URL string `json:"url,omitempty"`

	// Conditions holds standard API conditions.
	// +listType=map
	// +listMapKey=type
	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:resource:shortName=wa,categories=all
//+kubebuilder:printcolumn:name="Replicas",type=integer,JSONPath=".spec.replicas"
//+kubebuilder:printcolumn:name="Available",type=integer,JSONPath=".status.availableReplicas"
//+kubebuilder:printcolumn:name="Phase",type=string,JSONPath=".status.phase"
//+kubebuilder:printcolumn:name="Image",type=string,JSONPath=".spec.image"
//+kubebuilder:printcolumn:name="Age",type=date,JSONPath=".metadata.creationTimestamp"

// WebApp is the Schema for the webapps API.
// It provisions a Deployment, Service, and ConfigMap that serve the configured HTML page.
type WebApp struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   WebAppSpec   `json:"spec,omitempty"`
	Status WebAppStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// WebAppList contains a list of WebApp.
type WebAppList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []WebApp `json:"items"`
}

func init() {
	SchemeBuilder.Register(&WebApp{}, &WebAppList{})
}
