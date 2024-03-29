# Base image for iscsi operator build.
ISCSI_OPERATOR_IMAGE ?= utkarshmani1997/iscsi-operator:ci

# Output registry and image names for csi plugin image
REGISTRY ?= utkarshmani1997

# Output plugin name and its image name and tag
OPERATOR_NAME=iscsi-operator
OPERATOR_TAG=dev

GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD | sed -e "s/.*\\///")
GIT_TAG = $(shell git describe --tags)

# use git branch as default version if not set by env variable, if HEAD is detached that use the most recent tag
VERSION ?= $(if $(subst HEAD,,${GIT_BRANCH}),$(GIT_BRANCH),$(GIT_TAG))
COMMIT ?= $(shell git rev-parse HEAD | cut -c 1-7)
DATETIME ?= $(shell date +'%F_%T')
BUILD_META ?= unreleased
LDFLAGS ?= \
        -extldflags "-static" \
	-X github.com/utkarshmani1997/iscsi-operator/version/version.Version=${VERSION} \
	-X github.com/utkarshmani1997/iscsi-operator/version/version.Commit=${COMMIT} \
	-X github.com/utkarshmani1997/iscsi-operator/version/version.DateTime=${DATETIME} \
	-X github.com/utkarshmani1997/iscsi-operator/version/version.BuildMeta=${BUILD_META}

IMAGE_TAG ?= dev
REGISTRY_PATH=${REGISTRY}/${PLUGIN_NAME}:${PLUGIN_TAG}

.PHONY: all
all:
	@echo "Available commands:"
	@echo "  build                           - build operator source code"
	@echo "  container                       - build operator container"
	@echo "  push                            - push operator to dockerhub registry (${REGISTRY})"
	@echo ""
	@make print-variables --no-print-directory

.PHONY: print-variables
print-variables:
	@echo "Variables:"
	@echo "  VERSION:    ${VERSION}"
	@echo "  GIT_BRANCH: ${GIT_BRANCH}"
	@echo "  GIT_TAG:    ${GIT_TAG}"
	@echo "  COMMIT:     ${COMMIT}"
	@echo "Testing variables:"
	@echo " Produced Image: ${ISCSI_OPERATOR_IMAGE}"
	@echo " REGISTRY: ${REGISTRY}"


.get:
	rm -rf ./build/_output/bin/
	GO111MODULE=on go mod download

build: .get
	GO111MODULE=on GOOS=linux go build -a -ldflags '$(LDFLAGS)' -o ./build/_output/bin/$(OPERATOR_NAME) ./cmd/manager/main.go

container: build
	docker build -f ./build/Dockerfile -t $(REGISTRY)/$(OPERATOR_NAME):$(OPERATOR_TAG) .

generate:
	GO111MODULE=on operator-sdk generate k8s --verbose

operator:
	env GO111MODULE=on operator-sdk build $(REGISTRY)/$(OPERATOR_NAME):$(OPERATOR_TAG) --verbose

push: container
	docker push $(REGISTRY)/$(OPERATOR_NAME):$(OPERATOR_TAG)

clean: .get
