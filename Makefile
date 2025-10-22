OCI_REGISTRY ?= quay.io
OCI_IMAGE_REPO ?= yuntae/yob
OCI_IMAGE_TAG ?= latest
TARGET_INTERFACE ?= core
OCI_REGISTRY_USERNAME ?= your_username
OCI_REGISTRY_PASSWORD ?= your_password
DEFAULT_DISK ?= nvme0n1
DEFAULT_USER_NAME ?= yob
DEFAULT_USER_PASSWD ?= yob1234
ROOTFS ?= btrfs
ARCH ?= amd64
BIB_CONTAINER ?= quay.io/centos-bootc/bootc-image-builder@sha256:ba8c4bee758b4b816ce0c3a605f55389412edab034918f56982e7893e0b08532
GIT_COMMIT_HASH ?= $(shell git rev-parse HEAD)
SHORT_COMMIT_HASH := $(shell echo ${GIT_COMMIT_HASH} | cut -c1-8)
AWS_ACCESS_KEY_ID ?= your_aws_access_key_id
AWS_SECRET_ACCESS_KEY ?= your_aws_secret_access_key
AWS_S3_BUCKET ?= yob
AWS_REGION ?= us-east-1

.PHONY: login-public-oci-registry
login-public-oci-registry:
	docker login -u=${OCI_REGISTRY_USERNAME} -p=${OCI_REGISTRY_PASSWORD} ${OCI_REGISTRY}

.PHONY: lint-dockerfile
lint-dockerfile:
	hadolint Dockerfile --config tools/hadolint.yaml -f json | \
	jq -r '.' | \
	tee dockerfile-lint.json

.PHONY: build-bootc
build-bootc:
	OCI_REGISTRY=${OCI_REGISTRY} \
	OCI_IMAGE_REPO=${OCI_IMAGE_REPO} \
	OCI_IMAGE_TAG=${OCI_IMAGE_TAG} \
	GIT_COMMIT_HASH=${GIT_COMMIT_HASH} \
	docker buildx bake ${TARGET_INTERFACE}

.PHONY: login-public-oci-registry push-bootc
push-bootc:
	[[ "${TARGET_INTERFACE}" == "all" ]] && TARGETS="core desktop" || TARGETS="${TARGET_INTERFACE}"; \
	for target in $${TARGETS}; do \
		docker push ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-$${target}; \
	done

.PHONY: login-public-oci-registry pull-bootc
pull-bootc:
	[[ "${TARGET_INTERFACE}" == "all" ]] && TARGETS="core desktop" || TARGETS="${TARGET_INTERFACE}"; \
	for target in $${TARGETS}; do \
		docker pull ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-$${target}; \
	done

.PHONY: save-image-as-tgz
save-image-as-tgz:
	[[ "${TARGET_INTERFACE}" == "all" ]] && TARGETS="core desktop" || TARGETS="${TARGET_INTERFACE}"; \
	for target in $${TARGETS}; do \
		docker save ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-$${target} | \
		pigz > container-tarbells/image-${SHORT_COMMIT_HASH}-$${target}.tar.gz; \
	done

# See https://github.com/osbuild/bootc-image-builder
.PHONY: convert-to-iso
convert-to-iso: bib-dind-up
	cp -rf template-iso.toml config.toml
	sed -i "s|{DEFAULT_DISK}|${DEFAULT_DISK}|g" config.toml
	sed -i "s|{DEFAULT_USER_NAME}|${DEFAULT_USER_NAME}|g" config.toml
	sed -i "s|{DEFAULT_USER_PASSWD}|${DEFAULT_USER_PASSWD}|g" config.toml
	docker cp config.toml bib-dind:/config.toml
	[[ "${TARGET_INTERFACE}" == "all" ]] && TARGETS="core desktop" || TARGETS="${TARGET_INTERFACE}"; \
	for target in $${TARGETS}; do \
		mkdir -p image-builder-output/$${target}; \
		docker exec bib-dind /bin/bash -c " \
			podman load -i container-tarbells/image-${SHORT_COMMIT_HASH}-$${target}.tar.gz; \
			podman run --rm \
				--privileged \
				--security-opt label=type:unconfined_t \
				-v ./image-builder-output/$${target}:/output \
				-v /var/lib/containers/storage:/var/lib/containers/storage \
				-v ./config.toml:/config.toml:ro \
				${BIB_CONTAINER} \
				--type iso \
				--use-librepo=True \
				--rootfs ${ROOTFS} \
			${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-$${target}"; \
	done
	$(MAKE) bib-dind-down

# See https://github.com/osbuild/bootc-image-builder?tab=readme-ov-file#amazon-machine-images-amis
.PHONY: convert-to-ami
convert-to-ami: bib-dind-up
	cp -rf template-ami.toml config.toml
	sed -i "s|{DEFAULT_USER_NAME}|${DEFAULT_USER_NAME}|g" config.toml
	sed -i "s|{DEFAULT_USER_PASSWD}|${DEFAULT_USER_PASSWD}|g" config.toml
	docker cp config.toml bib-dind:/config.toml
	AWS_AMI_NAME=${SHORT_COMMIT_HASH}-core; \
	docker exec bib-dind /bin/bash -c " \
		podman load -i container-tarbells/image-${SHORT_COMMIT_HASH}-core.tar.gz; \
		podman run --rm \
			--privileged \
			--security-opt label=type:unconfined_t \
			-v /var/lib/containers/storage:/var/lib/containers/storage \
			-v ./config.toml:/config.toml:ro \
			--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
			--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
			${BIB_CONTAINER} \
			--type ami \
			--rootfs ${ROOTFS} \
			--aws-ami-name $${AWS_AMI_NAME} \
			--aws-bucket ${AWS_S3_BUCKET} \
			--aws-region ${AWS_REGION} \
		${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-core"
	$(MAKE) bib-dind-down

.PHONY: bib-dind-up
bib-dind-up:
	docker run \
		-itd \
		--privileged \
		--name bib-dind \
		-v ./container-tarbells:/container-tarbells \
		-v ./image-builder-output:/image-builder-output \
	quay.io/containers/podman:latest

.PHONY: bib-dind-down
bib-dind-down:
	docker rm -f bib-dind || true
