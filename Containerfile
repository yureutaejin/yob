ARG BASE=quay.io/fedora/fedora-bootc:41

FROM ${BASE}

COPY --from=docker.io/mikefarah/yq:4 /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/astral-sh/uv:0.8.13 /uv /uvx /bin/
ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo

RUN mkdir -p /var/roothome

RUN dnf upgrade -y

RUN dnf install -y \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN dnf group install -y \
	base-graphical \
	container-management \
	core \
	firefox \
	fonts \
	gnome-desktop \
	guest-desktop-agents \
	hardware-support \
	multimedia \
	networkmanager-submodules \
	printing \
	virtualization \
	workstation-product

RUN dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

RUN dnf install -y \
    tailscale \
    net-tools \
    vim \
    wireshark \
    bash-completion \
    && dnf clean all -y

RUN systemctl set-default graphical.target

RUN bootc container lint
