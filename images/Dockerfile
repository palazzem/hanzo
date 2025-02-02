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
# Equivalent to 'base' role
RUN dnf update -y && \
    dnf install -y \
    sudo \
    && dnf clean all

# System configuration
# Equivalent to 'system' role
# TODO: Add system-level configurations

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
