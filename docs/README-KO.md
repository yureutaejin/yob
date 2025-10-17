# YOB : Your own OS using bootc

## Index

<!-- no toc -->
- [Contributors](#contributors)
- [Introduction](#introduction)
- [Overall pipeline workflows](#overall-pipeline-workflows)
- [Quick Start](#quick-start)

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

모두가 알고 있듯이, Linux 컨테이너는 일반적으로 호스트 OS와 커널을 공유하므로,  
가상 머신보다 더 가볍고 빠른 "컨테이너"를 쉽게 만들 수 있습니다.

bootc 프로젝트는 이 방법을 역으로 사용하여 Linux 컨테이너 기술을 이용해 OS를 생성합니다.  
일반적인 OCI 컨테이너와 달리, bootc가 사용하는 기본 OCI 컨테이너(부팅 가능한 컨테이너라고 함)는 이미 다음과 같은 것들을 포함하고 있습니다.

- Linux kernel
- Bootloader
- systemd
- 시스템 유틸리티 및 드라이버

따라서 현대 개발자/엔지니어에게 친숙한 OCI 컨테이너 기술을 사용하여 OS 이미지를 만들 수 있습니다.

## Overall pipeline workflows

현재 이 프로젝트는 RHEL 이미지 모드 파이프라인 다이어그램을 참조합니다.

- [what-image-mode-means-users-rhel-edge](https://www.redhat.com/en/blog/what-image-mode-means-users-rhel-edge)

![Image mode pipeline for RHEL](https://www.redhat.com/rhdc/managed-files/image2_132.png)

## Quick Start

구성을 거의 편집하지 않고 빠르게 시작하는 방법입니다.

### 사전 요구사항

- Docker
- Make
- Podman
  - `/var/lib/containers/storage`만 사용합니다. 본 프로젝트에서는 podman 명령어를 사용하지 않습니다.
- OCI Registry
  - OCI Registry 계정을 취득하세요 (예: Docker Hub, Quay.io 등)
- 호스트 셸에서 로컬 변수를 정의하기만 하면 됩니다. Makefile을 수정할 필요는 없습니다 (기본값은 [Makefile](./Makefile) 참조).

### 1. Build bootc

bootc 프로젝트 기반 OCI 컨테이너를 빌드하고 이를 OCI Registry에 푸시합니다.

1. `make build-bootc`
2. `make push-bootc`

### 2. (Just for first boot) Convert bootc to disk format

- `make convert-to-{iso,ami,qcow2}`
  - 현재는 iso 포맷만 완전히 테스트되었습니다.

### 3. Flash bootable disk

부팅 가능한 디스크를 만드는 방법은 너무 많습니다.
지금은 베어 메탈 경우만 남겨두겠습니다.

- (베어 메탈) 최소 8GB 이상의 USB 드라이브(3.0, 파란색)에 플래시하는 것을 권장합니다
  - [Ventoy](https://www.ventoy.net/en/index.html)
  - [BalenaEtcher](https://etcher.balena.io/)

### 4. Boot OS

생성된 부팅 가능한 디스크로 부팅합니다
이미 [config.toml](./config.toml)로 호스트 구성을 설정했으므로, 첫 번째 부팅이 완료될 때까지 기다리기만 하면 됩니다.

### 5. (On target machine) Rollback/Upgrade/Switch OS

> [!NOTE]
> 첫 부팅 이후라면 부팅 가능한 디스크를 다시 만들 필요가 없습니다.

새 이미지를 OCI Registry에 push하기만하면, 다운로드하고 재부팅하는 것으로 OS 전환이 완료됩니다.

- `sudo bootc upgrade`
  - 부팅한 것과 동일한 태그의 최신 푸시된 이미지로 업그레이드
- `sudo bootc switch OCI_REGISTRY/OCI_IMAGE_REPO:OCI_IMAGE_TAG`
  - 지정된 bootc 이미지로 전환
  - 예: `sudo bootc switch quay.io/fedora/fedora-bootc:latest`
- `sudo bootc rollback`
  - 이전 이미지로 롤백
  - (중요) OS는 단 1개의 이전 버전 이미지만을 유지합니다
