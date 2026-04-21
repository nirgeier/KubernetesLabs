# Image registry & tag for the operator Docker image.
# Override with: make docker-build IMG=myregistry/myop:v1
IMG ?= codewizard.io/webapp-operator:latest

# ENVTEST_K8S_VERSION: the Kubernetes version for envtest binaries
ENVTEST_K8S_VERSION = 1.30.0

# Go settings
GOARCH  ?= $(shell go env GOARCH)
GOOS    ?= $(shell go env GOOS)

# Tool binary paths (downloaded automatically on first use)
LOCALBIN       ?= $(shell pwd)/bin
CONTROLLER_GEN ?= $(LOCALBIN)/controller-gen
ENVTEST        ?= $(LOCALBIN)/envtest
KUSTOMIZE      ?= $(LOCALBIN)/kustomize
GOLANGCI_LINT  ?= $(LOCALBIN)/golangci-lint

.PHONY: all
all: build

##@ General

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: fmt
fmt: ## Run go fmt
	go fmt ./...

.PHONY: vet
vet: ## Run go vet
	go vet ./...

.PHONY: lint
lint: golangci-lint ## Run golangci-lint
	$(GOLANGCI_LINT) run

.PHONY: test
test: manifests generate fmt vet envtest ## Run tests using envtest
	KUBEBUILDER_ASSETS="$(shell $(ENVTEST) use $(ENVTEST_K8S_VERSION) --bin-dir $(LOCALBIN) -p path)" \
	go test ./... -coverprofile cover.out

.PHONY: test-coverage
test-coverage: test ## Generate HTML coverage report
	go tool cover -html=cover.out -o coverage.html
	@echo "Coverage report: coverage.html"

##@ Build

.PHONY: generate
generate: controller-gen ## Generate DeepCopy functions (zz_generated.deepcopy.go)
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

.PHONY: manifests
manifests: controller-gen ## Generate CRD + RBAC + Webhook manifests
	$(CONTROLLER_GEN) rbac:roleName=manager-role crd webhook paths="./..." \
		output:crd:artifacts:config=config/crd/bases

.PHONY: build
build: generate fmt vet ## Build the manager binary
	go build -o bin/manager cmd/main.go

.PHONY: run
run: manifests generate fmt vet ## Run controller locally (uses ~/.kube/config)
	go run ./cmd/main.go $(ARGS)

##@ Deployment

.PHONY: install
install: manifests kustomize ## Install CRDs into the cluster
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

.PHONY: uninstall
uninstall: manifests kustomize ## Remove CRDs from the cluster
	$(KUSTOMIZE) build config/crd | kubectl delete --ignore-not-found=true -f -

.PHONY: deploy
deploy: manifests kustomize ## Deploy controller to the cluster using IMG
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

.PHONY: undeploy
undeploy: ## Undeploy controller from the cluster
	$(KUSTOMIZE) build config/default | kubectl delete --ignore-not-found=true -f -

##@ Docker

.PHONY: docker-build
docker-build: ## Build Docker image  --  make docker-build IMG=...
	docker build -t ${IMG} .

.PHONY: docker-push
docker-push: ## Push Docker image    --  make docker-push IMG=...
	docker push ${IMG}

.PHONY: docker-buildx
docker-buildx: ## Multi-arch build and push using buildx
	docker buildx build --platform linux/amd64,linux/arm64 -t ${IMG} --push .

##@ Tool installation

$(LOCALBIN):
	mkdir -p $(LOCALBIN)

.PHONY: controller-gen
controller-gen: $(LOCALBIN) ## Download controller-gen
	test -s $(CONTROLLER_GEN) || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest

.PHONY: kustomize
kustomize: $(LOCALBIN) ## Download kustomize
	test -s $(KUSTOMIZE) || GOBIN=$(LOCALBIN) go install sigs.k8s.io/kustomize/kustomize/v5@latest

.PHONY: envtest
envtest: $(LOCALBIN) ## Download envtest binaries
	test -s $(ENVTEST) || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

.PHONY: golangci-lint
golangci-lint: $(LOCALBIN) ## Download golangci-lint
	test -s $(GOLANGCI_LINT) || GOBIN=$(LOCALBIN) go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
