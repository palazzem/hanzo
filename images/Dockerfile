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
    dosfstools \
    ffmpeg \
    fzf \
    htop \
    httpie \
    iputils \
    mono-core \
    ntfs-3g \
    chrony \
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
    glibc-langpack-en \
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
# TODO: Add development tools and SDKs

# Code editors and IDE tools
# Equivalent to 'editors' role
# TODO: Add editor packages and configurations

# Container orchestration tools
# Equivalent to 'orchestrators' role
# TODO: Add container and orchestration tools

# Infrastructure provisioning tools
# Equivalent to 'provisioning' role
# TODO: Add infrastructure tools

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
