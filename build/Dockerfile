FROM archlinux:base-devel

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL
ARG DOCKER_GID

# Use Hanzo to prepare the DevBox
# NOTE: Change `docker` GID is required to start sibling containers
RUN curl -L http://j.mp/hattori-hanzo | sh \
    && groupmod -g $DOCKER_GID docker

# Set default login user
USER $HANZO_USERNAME
