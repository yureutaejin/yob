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

target "core" {
  dockerfile = "Dockerfile"
  context    = "."
  target = "core"
  tags = ["${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-core"]
  args = {
    GIT_COMMIT_HASH = "${GIT_COMMIT_HASH}"
  }
}

target "desktop" {
  dockerfile = "Dockerfile"
  context    = "."
  target = "desktop"
  tags = ["${OCI_REGISTRY}/${OCI_IMAGE_REPO}:${OCI_IMAGE_TAG}-desktop"]
  args = {
    GIT_COMMIT_HASH = "${GIT_COMMIT_HASH}"
  }
}

group "all" {
  targets = ["core", "desktop"]
}
