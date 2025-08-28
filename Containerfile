ARG BASE=quay.io/fedora/fedora-bootc:41

FROM ${BASE}

COPY --from=docker.io/mikefarah/yq:4 /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/astral-sh/uv:0.8.13 /uv /uvx /bin/
ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo

## See https://docs.fedoraproject.org/en-US/bootc/home-directories
RUN mkdir -p /var/roothome

RUN dnf upgrade -y

# Add RPM Fusion repositories
## Refer to https://rpmfusion.org/
RUN dnf install -y \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN dnf group install -y \
	core \
	gnome-desktop \
	firefox \
	fonts \
	guest-desktop-agents

# See https://fedoraproject.org/wiki/Changes/UnprivilegedUpdatesAtomicDesktops	
RUN dnf install -y fedora-release-ostree-desktop

# Install docker
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

# static analysis checks
RUN bootc container lint
