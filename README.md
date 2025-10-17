# YOB : Your own OS using bootc

## Index

<!-- no toc -->
- [Contributors](#contributors)
- [Introduction](#introduction)
- [Overall pipeline workflows](#overall-pipeline-workflows)
- [Quick Start](#quick-start)

## Translation

- [한국어](./docs/README-KO.md)

## Contributors

<table>
  <tr>
    <td align="center"><a href="https://github.com/yureutaejin"><img src="https://avatars.githubusercontent.com/u/85734054?v=4" width="100px;" alt=""/><br /><sub><b>
Yuntae</b></sub></a><br /></td>
    <td align="center"><a href="https://github.com/charlie3965"><img src="https://avatars.githubusercontent.com/u/19777578?v=4" width="100px;" alt=""/><br /><sub><b>
Chunsoo</b></sub></a><br /></td>
</table>

## Introduction

Base project YOB referenced

- [bootc](https://bootc-dev.github.io/)

<img src="https://developers.redhat.com/sites/default/files/styles/article_floated/public/image1_62.png.webp?itok=c0vYglLs" width="500" alt="bootc container">

As everybody knows, The Linux container usually shares kernel with host OS,  
so that we can easily create a "Container" which is more lightweight and faster than Virtual Machine.

The bootc project uses the method in reverse to create OS using the Linux container techniques.  
Unlike usual OCI containers, the base OCI container (so called, bootable container) that bootc uses have below things already.

- Linux kernel
- Bootloader
- systemd
- System utilities & drivers

So we can create OS image using OCI container techniques which is familiar to modern developers/engineers.

## Overall pipeline workflows

Currently, this project referred RHEL image mode pipeline diagram.

- [what-image-mode-means-users-rhel-edge](https://www.redhat.com/en/blog/what-image-mode-means-users-rhel-edge)

![Image mode pipeline for RHEL](https://www.redhat.com/rhdc/managed-files/image2_132.png)

## Quick Start

Quick start without editing few configurations.

### Prerequisites

- Docker
- Make
- Podman
  - It just uses `/var/lib/containers/storage`. No need to use podman command.
- OCI Registry
  - Get your account of OCI Registry (e.g. Docker Hub, Quay.io, etc.)
- Just define local variables in host shell without fixing Makefile (Refer to default value in [Makefile](./Makefile))

### 1. Build bootc

It will build OCI container based on bootc project and push it to your OCI Registry.

1. `make build-bootc`
2. `make push-bootc`

### 2. (Just for first boot) Convert bootc to disk format

- `make convert-to-{iso,ami,qcow2}`
  - Currently, only iso format is fully tested.

### 3. Flash bootable disk

There are too many ways to make bootable disk.
Just leave Bare Metal case for now.

- (Bare Metal) Recommend to flash USB drive (3.0, color blue) with at least 8GB
  - [Ventoy](https://www.ventoy.net/en/index.html)
  - [BalenaEtcher](https://etcher.balena.io/)

### 4. Boot OS

Boot with created bootable disk
Since we've set host's config with [config.toml](./config.toml) already, Just wait until first booting is done.

### 5. (On target machine) Rollback/Upgrade/Switch OS

> [!NOTE]
> No need to make bootable disk again after first boot.

Simply push the new image to the OCI Registry, and the OS switching will be complete after downloading and rebooting.

- `sudo bootc upgrade`
  - Upgrade to latest pushed image with same tag you booted
- `sudo bootc switch OCI_REGISTRY/OCI_IMAGE_REPO:OCI_IMAGE_TAG`
  - Switch to specified bootc image
  - You can switch any bootc image if it is accessible
  - e.g. `sudo bootc switch quay.io/fedora/fedora-bootc:latest`
- `sudo bootc rollback`
  - Rollback to previous image
  - (Important) OS will keep just 1 previous version of image for rollback
