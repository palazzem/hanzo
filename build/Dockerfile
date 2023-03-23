FROM archlinux:base-devel

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL

# Build with Hanzo and complete the cleanup
RUN curl -L http://j.mp/hattori-hanzo | sh

# Set default login user
USER $HANZO_USERNAME
