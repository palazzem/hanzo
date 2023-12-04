ARG PLATFORM=amd64

FROM --platform=${PLATFORM} archlinux:base-devel

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL

# Use Hanzo to prepare the DevBox
RUN curl -L http://j.mp/hattori-hanzo | sh

# Set default login user
USER $HANZO_USERNAME
