OCI_REGISTRY ?= quay.io
OCI_IMAGE_REPO ?= teamthepioneers/immutable-os-bootc
OCI_IMAGE_TAG ?= latest
OCI_REGISTRY_USERNAME ?= your_username
OCI_REGISTRY_PASSWORD ?= your_password
DISK_FORMAT ?= iso
DEFAULT_DISK ?= nvme0n1
DEFAULT_USER_NAME ?= pioneers
DEFAULT_USER_PASSWD ?= pioneers1234
ROOTFS ?= btrfs
ARCH ?= amd64
BIB_CONTAINER ?= quay.io/centos-bootc/bootc-image-builder@sha256:ba8c4bee758b4b816ce0c3a605f55389412edab034918f56982e7893e0b08532
GIT_COMMIT_HASH ?= $(shell git rev-parse HEAD)

.PHONY: build-oci-bootc-image
build-oci-bootc-image:
	docker build \
	--build-arg GIT_COMMIT_HASH=$(GIT_COMMIT_HASH) \
	-t ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG} \
	.

.PHONY: login-public-oci-registry
login-public-oci-registry:
	docker login -u=$(OCI_REGISTRY_USERNAME) -p=$(OCI_REGISTRY_PASSWORD) $(OCI_REGISTRY)

.PHONY: save-image-as-tar
save-image-as-tar:
	docker save -o image-${GIT_COMMIT_HASH:0:8}.tar ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}

.PHONY: push-oci-image
push-oci-image:
	docker push $(OCI_REGISTRY)/$(OCI_IMAGE_REPO):${OCI_IMAGE_TAG}

.PHONY: pull-oci-image
pull-oci-image:
	docker pull $(OCI_REGISTRY)/$(OCI_IMAGE_REPO):${OCI_IMAGE_TAG}

# See https://github.com/osbuild/bootc-image-builder
.PHONY: convert-to-disk-image
convert-to-disk-image:
	sudo podman load -i image-${GIT_COMMIT_HASH:0:8}.tar
	sed -i "s|{DEFAULT_DISK}|${DEFAULT_DISK}|g" config.toml
	sed -i "s|{DEFAULT_USER_NAME}|${DEFAULT_USER_NAME}|g" config.toml && \
	sed -i "s|{DEFAULT_USER_PASSWD}|${DEFAULT_USER_PASSWD}|g" config.toml && \
	sudo docker run --rm \
	--privileged \
	--security-opt label=type:unconfined_t \
	-v ./image-builder-output:/output \
	-v /var/lib/containers/storage:/var/lib/containers/storage \
	-v ./config.toml:/config.toml:ro \
	$(BIB_CONTAINER) \
	--type $(DISK_FORMAT) \
	--use-librepo=True \
	--rootfs $(ROOTFS) \
	$(OCI_REGISTRY)/$(OCI_IMAGE_REPO):${OCI_IMAGE_TAG}
