# using the chart name and version from chart's metadata
CHART_NAME ?= $(shell awk '/^name:/ { print $$2 }' Chart.yaml)
CHART_VESION ?= $(shell awk '/^version:/ { print $$2 }' Chart.yaml)

# bats entry point and default flags
BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

# path to the bats test files, overwite the variables below to tweak the test scope
E2E_TESTS ?= ./test/e2e/s2i-python-e2e.bats

# external task dependency to run the end-to-end tests pipeline
TASK_GIT ?= https://github.com/openshift-pipelines/task-git/releases/download/0.0.1/task-git-0.0.1.yaml


# skopeo-copy task e2e test variables, source, destination url and tls-verify parameter.
E2E_SC_PARAMS_SOURCE ?= docker://docker.io/library/busybox:latest
E2E_SC_PARAMS_DESTINATION ?= docker://registry.registry.svc.cluster.local:32222/busybox:latest
# setting tls-verify as false disables the HTTPS client as well, something we need for e2e testing
E2E_SC_PARAMS_TLS_VERIFY ?= false
#The location of the path to run skopeo copy from.
E2E_SC_PARAMS_PATH_CONTEXT ?= .

# workspace "source" pvc resource and name
E2E_PVC ?= test/e2e/resources/pvc.yaml
E2E_PVC_NAME ?= task-s2i-go

# workspace "source" pvc resource and name
E2E_PYTHON_PVC ?= test/e2e/resources/pvc-s2i-python.yaml
E2E_PYTHON_PVC_NAME ?= task-s2i-python


# path to the github actions testing workflows
ACT_WORKFLOWS ?= ./.github/workflows/test.yaml

# workspace "source" pvc resource and name
E2E_BUILDAH_PVC ?= test/e2e/resources/pvc-buildah.yaml
E2E_BUILDAH_PVC_NAME ?= task-buildah

# buildah task e2e test variables, image path, containerfile_path
E2E_BUILDAH_CONTAINERFILE_PATH ?= /workspace/source/Dockerfile
E2E_BUILDAH_IMAGE ?= test-buildah
E2E_BUILDAH_REGISTRY ?= registry.registry.svc.cluster.local:32222/test-buildah:latest
E2E_BUILDAH_TLS_VERIFY ?= false
E2E_BUILDAH_POPULATE_WORKSPACE ?= test/e2e/resources/populate-workspace-task.yaml

# The local container registry to push the image during e2e testing of s2i-golang task
E2E_S2I_IMAGE ?= registry.registry.svc.cluster.local:32222/test-s2i:latest
# setting tls-verify as false disables the HTTPS client as well, something we need for e2e testin
E2E_S2I_TLS_VERIFY ?= false


# generic arguments employed on most of the targets
ARGS ?=

# making sure the variables declared in the Makefile are exported to the excutables/scripts invoked
# on all targets
.EXPORT_ALL_VARIABLES:

# uses helm to render the resource templates to the stdout
define render-template
	@helm template $(ARGS) $(CHART_NAME) .
endef

# renders the task resource file printing it out on the standard output
helm-template:
	$(call render-template)

default: helm-template

# renders and installs the resources (task)
install:
	$(call render-template) |kubectl $(ARGS) apply -f -

# installs "git" task directly from the informed location, the task is required to run the test-e2e
# target, it will hold the "source" workspace data
task-git:
	kubectl apply -f ${TASK_GIT}


task-populate-workspace:
	kubectl apply -f ${E2E_BUILDAH_POPULATE_WORKSPACE}

# applies the pvc resource file, if the file exists
.PHONY: workspace-source-pvc-buildah
workspace-source-pvc-buildah:
ifneq ("$(wildcard $(E2E_BUILDAH_PVC))","")
	kubectl apply -f $(E2E_BUILDAH_PVC)
endif

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package:
	rm -f $(CHART_NAME)-*.tgz || true
	helm package $(ARGS) .
	tar -ztvpf $(CHART_NAME)-$(CHART_VESION).tgz

# removes the package helm chart, and also the chart-releaser temporary directories
clean:
	rm -rf $(CHART_NAME)-*.tgz > /dev/null 2>&1 || true


# applies the pvc resource file, if the file exists
.PHONY: workspace-source-pvc
workspace-source-pvc:
ifneq ("$(wildcard $(E2E_PVC))","")
	kubectl apply -f $(E2E_PVC)
endif

# applies the pvc resource file, if the file exists
.PHONY: workspace-source-pvc-s2i-python
workspace-source-pvc-s2i-python:
ifneq ("$(wildcard $(E2E_PYTHON_PVC))","")
	kubectl apply -f $(E2E_PYTHON_PVC)
endif


# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed, before start testing the target invokes the
# installation of the current project's task (using helm).
test-e2e: task-populate-workspace workspace-source-pvc-buildah workspace-source-pvc workspace-source-pvc-s2i-python task-git install
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(E2E_TESTS)


# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --rm
act:
	act --workflows=$(ACT_WORKFLOWS) $(ARGS)
