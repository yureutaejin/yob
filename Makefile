OCI_REGISTRY ?= localhost
OCI_IMAGE_REPO ?= localdev/immutable-os-bootc
OCI_IMAGE_TAG ?= latest
DISK_FORMAT ?= iso
ROOTFS ?= btrfs
ARCH ?= amd64
BIB_CONTAINER ?= quay.io/centos-bootc/bootc-image-builder@sha256:ba8c4bee758b4b816ce0c3a605f55389412edab034918f56982e7893e0b08532
GIT_COMMIT_HASH ?= $(shell git rev-parse --short=12 HEAD || echo "notgitrepo123")

.PHONY: build-oci-bootc-image
build-oci-bootc-image:
	sudo podman build \
	--build-arg GIT_COMMIT_HASH=$(GIT_COMMIT_HASH) \
	-t ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG} \
	.

.PHONY: push-oci-image
push-oci-image:
	sudo podman push $(OCI_REGISTRY)/$(OCI_IMAGE_REPO):${OCI_IMAGE_TAG}

# See https://github.com/osbuild/bootc-image-builder
.PHONY: convert-to-disk-image
convert-to-disk-image:
	sudo podman run --rm \
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
