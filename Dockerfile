FROM archlinux:base-devel
LABEL maintainer="Emanuele Palazzetti <emanuele.palazzetti@gmail.com>"

# Configure the build environment
ENV HANZO_FOLDER /root/.hanzo
ARG HANZO_FULLNAME
ARG HANZO_USERNAME
ARG HANZO_EMAIL

# Copy development build
COPY . /root/.hanzo

# Provisioning at build time
RUN sh $HANZO_FOLDER/bin/bootstrap.sh
