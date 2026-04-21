package controller

import (
	"context"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"

	webappv1 "codewizard.io/webapp-operator/api/v1"
)

// Test constants
const (
	testWebAppName      = "test-webapp"
	testWebAppNamespace = "default"
	timeout             = time.Second * 30
	interval            = time.Millisecond * 250
)

var _ = Describe("WebApp Controller", func() {
	ctx := context.Background()

	Context("When creating a WebApp CR", func() {
		It("should create a Deployment, Service, and ConfigMap", func() {
			By("Creating the WebApp CR")
			webapp := &webappv1.WebApp{
				ObjectMeta: metav1.ObjectMeta{
					Name:      testWebAppName,
					Namespace: testWebAppNamespace,
				},
				Spec: webappv1.WebAppSpec{
					Replicas:       2,
					Image:          "nginx:1.25.3",
					Message:        "Hello from controller test",
					Port:           80,
					ServiceType:    "ClusterIP",
					MaxUnavailable: 1,
				},
			}
			Expect(k8sClient.Create(ctx, webapp)).To(Succeed())

			namespacedName := types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}

			By("Checking the Deployment is created with correct replica count")
			createdDeployment := &appsv1.Deployment{}
			Eventually(func() error {
				return k8sClient.Get(ctx, namespacedName, createdDeployment)
			}, timeout, interval).Should(Succeed())

			Expect(*createdDeployment.Spec.Replicas).To(Equal(int32(2)))
			Expect(createdDeployment.Spec.Template.Spec.Containers[0].Image).To(Equal("nginx:1.25.3"))

			By("Checking the Service is created with ClusterIP type")
			createdService := &corev1.Service{}
			Eventually(func() error {
				return k8sClient.Get(ctx, namespacedName, createdService)
			}, timeout, interval).Should(Succeed())

			Expect(createdService.Spec.Type).To(Equal(corev1.ServiceTypeClusterIP))
			Expect(createdService.Spec.Ports[0].Port).To(Equal(int32(80)))

			By("Checking the ConfigMap is created with the correct HTML content")
			cmName := types.NamespacedName{
				Name:      testWebAppName + "-html",
				Namespace: testWebAppNamespace,
			}
			createdCM := &corev1.ConfigMap{}
			Eventually(func() error {
				return k8sClient.Get(ctx, cmName, createdCM)
			}, timeout, interval).Should(Succeed())

			Expect(createdCM.Data["index.html"]).To(ContainSubstring("Hello from controller test"))
		})

		It("should scale the Deployment when replicas change", func() {
			By("Fetching the current WebApp")
			webapp := &webappv1.WebApp{}
			Expect(k8sClient.Get(ctx, types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}, webapp)).To(Succeed())

			By("Patching replicas to 4")
			webapp.Spec.Replicas = 4
			Expect(k8sClient.Update(ctx, webapp)).To(Succeed())

			By("Asserting that the Deployment reflects the new replica count")
			Eventually(func() int32 {
				dep := &appsv1.Deployment{}
				_ = k8sClient.Get(ctx, types.NamespacedName{
					Name:      testWebAppName,
					Namespace: testWebAppNamespace,
				}, dep)
				if dep.Spec.Replicas == nil {
					return 0
				}
				return *dep.Spec.Replicas
			}, timeout, interval).Should(Equal(int32(4)))
		})

		It("should update ConfigMap when message changes", func() {
			By("Fetching the current WebApp")
			webapp := &webappv1.WebApp{}
			Expect(k8sClient.Get(ctx, types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}, webapp)).To(Succeed())

			By("Updating the message")
			webapp.Spec.Message = "Updated via envtest"
			Expect(k8sClient.Update(ctx, webapp)).To(Succeed())

			By("Asserting that the ConfigMap's index.html contains the new message")
			Eventually(func() string {
				cm := &corev1.ConfigMap{}
				_ = k8sClient.Get(ctx, types.NamespacedName{
					Name:      testWebAppName + "-html",
					Namespace: testWebAppNamespace,
				}, cm)
				return cm.Data["index.html"]
			}, timeout, interval).Should(ContainSubstring("Updated via envtest"))
		})

		It("should restore a deleted Deployment (self-healing)", func() {
			By("Deleting the Deployment manually")
			dep := &appsv1.Deployment{}
			Expect(k8sClient.Get(ctx, types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}, dep)).To(Succeed())
			Expect(k8sClient.Delete(ctx, dep)).To(Succeed())

			By("Asserting the Deployment is recreated by the operator")
			Eventually(func() error {
				restored := &appsv1.Deployment{}
				return k8sClient.Get(ctx, types.NamespacedName{
					Name:      testWebAppName,
					Namespace: testWebAppNamespace,
				}, restored)
			}, timeout, interval).Should(Succeed())
		})

		It("should not reconcile when paused", func() {
			By("Pausing the WebApp")
			webapp := &webappv1.WebApp{}
			Expect(k8sClient.Get(ctx, types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}, webapp)).To(Succeed())
			webapp.Spec.Paused = true
			Expect(k8sClient.Update(ctx, webapp)).To(Succeed())

			By("Manually scaling the Deployment down to 1")
			dep := &appsv1.Deployment{}
			Expect(k8sClient.Get(ctx, types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}, dep)).To(Succeed())
			one := int32(1)
			dep.Spec.Replicas = &one
			Expect(k8sClient.Update(ctx, dep)).To(Succeed())

			By("Asserting that the operator does NOT restore the replica count")
			// Give the operator a chance to act (it should not)
			Consistently(func() int32 {
				d := &appsv1.Deployment{}
				_ = k8sClient.Get(ctx, types.NamespacedName{
					Name:      testWebAppName,
					Namespace: testWebAppNamespace,
				}, d)
				if d.Spec.Replicas == nil {
					return 0
				}
				return *d.Spec.Replicas
			}, 5*time.Second, interval).Should(Equal(int32(1)))
		})

		AfterEach(func() {
			// Cleanup created WebApp after each test group
			webapp := &webappv1.WebApp{}
			if err := k8sClient.Get(ctx, types.NamespacedName{
				Name:      testWebAppName,
				Namespace: testWebAppNamespace,
			}, webapp); err == nil {
				Expect(k8sClient.Delete(ctx, webapp)).To(Succeed())
			}
		})
	})
})
