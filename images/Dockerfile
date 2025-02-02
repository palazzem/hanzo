FROM fedora:41

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL

# Fail if required build args are missing
RUN [ -n "$HANZO_USERNAME" ] || (echo "HANZO_USERNAME not set" && false) && \
    [ -n "$HANZO_FULLNAME" ] || (echo "HANZO_FULLNAME not set" && false) && \
    [ -n "$HANZO_EMAIL" ] || (echo "HANZO_EMAIL not set" && false)

# Base system configuration
# Equivalent to 'base' role from Ansible
RUN dnf update -y && \
    dnf group install -y development-tools && \
    dnf install -y \
    sudo \
    kernel-devel \
    kernel-headers \
    && dnf clean all

# Enable RPM Fusion repositories
# Equivalent to 'aur' role from Ansible
RUN dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    && dnf clean all

# System configuration
# Equivalent to 'system' role
RUN dnf install -y \
    bind-utils \
    chrony \
    dosfstools \
    ffmpeg \
    fzf \
    gettext \
    glibc-langpack-en \
    htop \
    httpie \
    iputils \
    mono-core \
    ntfs-3g \
    openssl \
    p7zip \
    p7zip-plugins \
    plocate \
    speedtest-cli \
    tree \
    unrar \
    wget \
    which \
    whois \
    && dnf clean all

# User and directory setup
RUN useradd -m -G wheel "${HANZO_USERNAME}" && \
    mkdir -p "/home/${HANZO_USERNAME}/programs" && \
    mkdir -p "/home/${HANZO_USERNAME}/workspaces" && \
    chown -R "${HANZO_USERNAME}:${HANZO_USERNAME}" "/home/${HANZO_USERNAME}" && \
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    # Set locale
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Shell setup
# Equivalent to 'shell' role
# TODO: Add shell configurations and utilities

# Security tools and configurations
# Equivalent to 'security' role
# TODO: Add security-related packages and configs

# Development tools and languages
# Equivalent to 'development' role
RUN dnf install -y \
    gdb \
    golang \
    java-latest-openjdk-devel \
    jq \
    nodejs \
    postgresql \
    python3 \
    python3-pip \
    python3-setuptools \
    ruby \
    rust \
    cargo \
    sqlite \
    yq \
    pipx \
    && dnf clean all \
    && su - ${HANZO_USERNAME} -c "mkdir -p /home/${HANZO_USERNAME}/programs/go/bin && \
        GOPATH=/home/${HANZO_USERNAME}/programs/go go install github.com/minamijoyo/tfupdate@latest && \
        pipx install ipython && \
        pipx install hatch && \
        pipx install pre-commit && \
        pipx install checkov" \
    && curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Code editors and IDE tools
# Equivalent to 'editors' role
RUN dnf install -y \
    neovim \
    emacs \
    && dnf clean all \
    && su - ${HANZO_USERNAME} -c "git clone https://github.com/syl20bnr/spacemacs /home/${HANZO_USERNAME}/.emacs.d"

# Container orchestration tools
# Equivalent to 'orchestrators' role
RUN dnf -y install dnf-plugins-core && \
    dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    && dnf clean all \
    && usermod -aG docker ${HANZO_USERNAME}

# Infrastructure provisioning tools
# Equivalent to 'provisioning' role
RUN dnf install -y dnf-plugins-core && \
    dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo && \
    dnf install -y \
    terraform \
    packer \
    && dnf clean all

# Cluster management tools
# Equivalent to 'cluster' role
# TODO: Add cluster management tools

# Additional utilities
# Equivalent to 'extras' role
# TODO: Add extra utilities

# User dotfiles configuration
# Equivalent to 'dotfiles' role
# TODO: Add dotfiles setup

# Cleanup
# Equivalent to 'cleanup' role
RUN dnf clean all && \
    rm -rf /var/cache/dnf

# Set default login user
USER $HANZO_USERNAME
