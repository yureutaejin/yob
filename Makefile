OCI_REGISTRY ?= quay.io
OCI_IMAGE_REPO ?= yuntae/yob
OCI_IMAGE_TAG ?= latest
OCI_REGISTRY_USERNAME ?= your_username
OCI_REGISTRY_PASSWORD ?= your_password
DISK_FORMAT ?= iso
DEFAULT_DISK ?= nvme0n1
DEFAULT_USER_NAME ?= yob
DEFAULT_USER_PASSWD ?= yob1234
ROOTFS ?= btrfs
ARCH ?= amd64
BIB_CONTAINER ?= quay.io/centos-bootc/bootc-image-builder@sha256:ba8c4bee758b4b816ce0c3a605f55389412edab034918f56982e7893e0b08532
GIT_COMMIT_HASH ?= $(shell git rev-parse HEAD)
AWS_ACCESS_KEY_ID ?= your_aws_access_key_id
AWS_SECRET_ACCESS_KEY ?= your_aws_secret_access_key
AWS_AMI_NAME ?= yob-$(GIT_COMMIT_HASH:0:8)
AWS_S3_BUCKET ?= yob
AWS_REGION ?= us-east-1

.PHONY: build-bootc
build-bootc:
	docker build \
	--build-arg GIT_COMMIT_HASH=${GIT_COMMIT_HASH} \
	-t ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG} \
	.

.PHONY: push-bootc
push-bootc:
	docker push ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}

.PHONY: pull-bootc
pull-bootc:
	docker pull ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}

.PHONY: lint-dockerfile
lint-dockerfile:
	hadolint Dockerfile --config tools/hadolint.yaml -f json | \
	jq -r '.' | \
	tee dockerfile-lint.json

.PHONY: login-public-oci-registry
login-public-oci-registry:
	docker login -u=${OCI_REGISTRY_USERNAME} -p=${OCI_REGISTRY_PASSWORD} ${OCI_REGISTRY}

.PHONY: save-image-as-tar
save-image-as-tar:
	docker save -o image-${GIT_COMMIT_HASH:0:8}.tar ${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}

# See https://github.com/osbuild/bootc-image-builder
.PHONY: convert-to-iso
convert-to-iso: pull-bootc save-image-as-tar
	sudo podman load -i image-${GIT_COMMIT_HASH:0:8}.tar
	sed -i "s|{DEFAULT_DISK}|${DEFAULT_DISK}|g" config.toml
	sed -i "s|{DEFAULT_USER_NAME}|${DEFAULT_USER_NAME}|g" config.toml
	sed -i "s|{DEFAULT_USER_PASSWD}|${DEFAULT_USER_PASSWD}|g" config.toml
	sudo docker run --rm \
	--privileged \
	--security-opt label=type:unconfined_t \
	-v ./image-builder-output:/output \
	-v /var/lib/containers/storage:/var/lib/containers/storage \
	-v ./config.toml:/config.toml:ro \
	${BIB_CONTAINER} \
	--type ${DISK_FORMAT} \
	--use-librepo=True \
	--rootfs ${ROOTFS} \
	${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}

# See https://github.com/osbuild/bootc-image-builder?tab=readme-ov-file#amazon-machine-images-amis
.PHONY: convert-to-ami
convert-to-ami: pull-bootc save-image-as-tar
	sudo podman load -i image-${GIT_COMMIT_HASH:0:8}.tar
	sudo docker run --rm \
	--privileged \
	--security-opt label=type:unconfined_t \
	-v /var/lib/containers/storage:/var/lib/containers/storage \
	--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
	--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
	${BIB_CONTAINER} \
	--type ${DISK_FORMAT} \
	--rootfs ${ROOTFS} \
	--aws-ami-name ${AWS_AMI_NAME} \
	--aws-bucket ${AWS_S3_BUCKET} \
	--aws-region ${AWS_REGION} \
	${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}
