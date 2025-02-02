FROM fedora:41

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL

# Install essential build tools and curl (needed for hanzo script)
RUN dnf update -y && \
    dnf install -y \
    curl \
    sudo \
    && dnf clean all

# Use Hanzo to prepare the DevBox
RUN curl -L http://j.mp/hattori-hanzo | sh

# Set default login user
USER $HANZO_USERNAME
