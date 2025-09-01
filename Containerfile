ARG BASE=quay.io/fedora/fedora-bootc:41

FROM ${BASE}

## See https://docs.fedoraproject.org/en-US/bootc/home-directories
RUN mkdir -p /var/roothome

# Install packages from source OCI image
COPY --from=docker.io/mikefarah/yq:4 /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/astral-sh/uv:0.8.13 /uv /uvx /usr/bin/
COPY ./filesystem /tmp/filesystem

ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
    | tee /etc/yum.repos.d/vscode.repo > /dev/null

RUN dnf upgrade -y

# Add RPM Fusion repositories
## Refer to https://rpmfusion.org/
RUN dnf install -y \
	  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# dnf package group installation
## See also https://fedoraproject.org/wiki/Changes/UnprivilegedUpdatesAtomicDesktops
RUN dnf group install -y \
	  core \
	  gnome-desktop \
	  firefox \
	  fonts \
	  guest-desktop-agents

# dnf package installation
RUN dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    tailscale \
    net-tools \
    vim \
    unzip \
    wireshark \
    bash-completion \
    code \
    rsync \
    fedora-release-ostree-desktop \
    && dnf clean all && \
    rm -rf /var/cache/libdnf5

# Install packages from source
RUN curl -fsSL https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz | \
    tar xz starship -C /usr/bin/
RUN curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# sync ./filesystem with root filesystem
RUN rsync -a /tmp/filesystem/ / && \
    rm -rf /tmp/filesystem

# Activate GUI as default
RUN systemctl set-default graphical.target

# static analysis checks
RUN bootc container lint
