variable "OCI_REGISTRY" {
  default = "registry_name"
}

variable "OCI_IMAGE_REPO" {
  default = "namespace/repo"
}

variable "OCI_IMAGE_TAG" {
  default = "latest"
}

variable "GIT_COMMIT_HASH" {
  default = "sha-unknown"
}

variable "BASE_CONTAINER" {
  default = "quay.io/fedora/fedora-bootc:42"
}

target "core" {
  dockerfile = "Dockerfile"
  context    = "."
  target = "core"
  tags = ["${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-core"]
  args = {
    GIT_COMMIT_HASH = "${GIT_COMMIT_HASH}",
    BASE_CONTAINER = "${BASE_CONTAINER}"
  }
}

target "desktop" {
  dockerfile = "Dockerfile"
  context    = "."
  target = "desktop"
  tags = ["${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-desktop"]
  args = {
    GIT_COMMIT_HASH = "${GIT_COMMIT_HASH}",
    BASE_CONTAINER = "${BASE_CONTAINER}"
  }
}

group "all" {
  targets = ["core", "desktop"]
}
