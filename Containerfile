ARG BASE="quay.io/fedora/fedora-bootc:42"
ARG GIT_COMMIT_HASH

FROM ${BASE} AS step-scratch

# See https://docs.fedoraproject.org/en-US/bootc/home-directories
RUN mkdir -p /var/roothome

ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
    | tee /etc/yum.repos.d/vscode.repo > /dev/null

# Add RPM Fusion repositories
## Refer to https://rpmfusion.org/
RUN dnf install -y \
	  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

FROM step-scratch AS step-external

# Install packages from source OCI image
# e.g. COPY --from=ghcr.io/astral-sh/uv:0.8.13 /uv /uvx /usr/bin/
RUN dnf install -y unzip

# Install packages from source
RUN mkdir -p /tmp/external
RUN curl -fsSL https://github.com/starship/starship/releases/download/v1.23.0/starship-x86_64-unknown-linux-gnu.tar.gz | \
    tar xz -C /tmp/external/ starship
RUN curl -fsSL https://github.com/wagoodman/dive/releases/download/v0.13.1/dive_0.13.1_linux_amd64.tar.gz | \
    tar xz -C /tmp/external/ dive
RUN curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.47.2/yq_linux_amd64.tar.gz | \
    tar xz -C /tmp/external/ ./yq_linux_amd64
RUN curl -fsSL https://github.com/astral-sh/uv/releases/download/0.8.18/uv-x86_64-unknown-linux-gnu.tar.gz | \
    tar xz -C /tmp/external/ --strip-components=1
RUN curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/external/awscliv2.zip && \
    unzip /tmp/external/awscliv2.zip -d /tmp/external/

COPY ./filesystem /tmp/filesystem

FROM step-scratch AS step-final
ARG GIT_COMMIT_HASH

# See https://bootc-dev.github.io/bootc/bootc-images.html#standard-metadata-for-bootc-compatible-images
LABEL containers.bootc=1
# See https://specs.opencontainers.org/image-spec/annotations/#pre-defined-annotation-keys
LABEL org.opencontainers.image.revision=${GIT_COMMIT_HASH}

# dnf package installation
## See also https://fedoraproject.org/wiki/Changes/UnprivilegedUpdatesAtomicDesktops
RUN dnf install -y \
    @core \
    @gnome-desktop \
    @firefox \
    @fonts \
    @guest-desktop-agents \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    tailscale \
    systemd-networkd \
    netplan.io \
    vim \
    wireshark \
    bash-completion \
    code \
    rsync \
    fedora-release-ostree-desktop \
    && dnf clean all && \
    rm -rf /var/cache/libdnf5

COPY --from=step-external /tmp /tmp

RUN /tmp/external/aws/install && rm -rf /tmp/external/aws

# sync {filesystem,external}
RUN cp -a /tmp/filesystem/. / && \
    cp -a /tmp/external/. /usr/bin/ && \
    rm -rf /tmp/*

# systemd settings
RUN systemctl disable NetworkManager
RUN systemctl disable NetworkManager-wait-online
RUN systemctl mask bootc-fetch-apply-updates.timer
RUN systemctl enable systemd-networkd
RUN systemctl enable netplan-apply.service
RUN systemctl enable tailscaled
RUN systemctl enable docker
RUN systemctl enable sshd
RUN systemctl set-default graphical.target

RUN dconf update

# static analysis checks
RUN bootc container lint
