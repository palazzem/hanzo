FROM docker.io/palazzem/archlinux-toolbox:latest
LABEL maintainer="Emanuele Palazzetti <emanuele.palazzetti@gmail.com>"

# Configure the build environment
ENV HANZO_FOLDER /root/.hanzo
ARG HANZO_FULLNAME
ARG HANZO_USERNAME
ARG HANZO_EMAIL

# Push the repository in Hanzo default folder
COPY . /root/.hanzo
WORKDIR /root/.hanzo

# Provisioning at build time
RUN bash bin/bootstrap.sh
