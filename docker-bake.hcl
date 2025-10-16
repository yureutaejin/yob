variable "oci_registry" {
  default = "quay.io"
}

variable "oci_image_repo" {
  default = "yuntae/yob"
}

variable "oci_image_tag" {
  default = "latest"
}

variable "git_commit_hash" {
  default = "sha-unknown"
}

target "core" {
  dockerfile = "Dockerfile"
  context    = "."
  tags = ["${oci_registry}/${oci_image_repo}:${oci_image_tag}-core"]
  args = {
    GIT_COMMIT_HASH = "${git_commit_hash}"
  }
}

target "desktop" {
  dockerfile = "Dockerfile"
  context    = "."
  tags = ["${oci_registry}/${oci_image_repo}:${oci_image_tag}-desktop"]
  args = {
    GIT_COMMIT_HASH = "${git_commit_hash}"
  }
}

group "all" {
  targets = ["core", "desktop"]
}
