ARG BASE=quay.io/fedora/fedora-bootc:41

FROM ${BASE}

## See https://docs.fedoraproject.org/en-US/bootc/home-directories
RUN mkdir -p /var/roothome

COPY ./filesystem/usr/* /usr/
COPY ./filesystem/etc/* /etc/
ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
        && echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
        > /etc/yum.repos.d/vscode.repo

RUN dnf upgrade -y

COPY --from=docker.io/mikefarah/yq:4 /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/astral-sh/uv:0.8.13 /uv /uvx /usr/bin/
RUN curl -fsSL https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz | \
        tar xz starship -C /usr/bin/

# Add RPM Fusion repositories
## Refer to https://rpmfusion.org/
RUN dnf install -y \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# package group installation
## See also https://fedoraproject.org/wiki/Changes/UnprivilegedUpdatesAtomicDesktops	
RUN dnf group install -y \
	core \
	gnome-desktop \
	firefox \
	fonts \
	guest-desktop-agents

# Install docker
RUN dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Install additional packages
RUN dnf install -y \
    tailscale \
    net-tools \
    vim \
    wireshark \
    bash-completion \
    code \
    fedora-release-ostree-desktop \
    && dnf clean all -y

# Activate GUI as default
RUN systemctl set-default graphical.target

# static analysis checks
RUN bootc container lint
