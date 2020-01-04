FROM archlinux/base
LABEL maintainer="hello@palazzetti.me"

# Configure testing environment
ARG TAGS
ENV EXTRA_ARGS --verbose
ENV HANZO_FULLNAME test
ENV HANZO_USERNAME test
ENV HANZO_EMAIL test@example.com
ENV HANZO_FOLDER /root/hanzo

COPY . /root/hanzo
WORKDIR /root/hanzo

# Provisioning at build time so that if a container builds correctly,
# the test is successful
RUN bash bin/bootstrap.sh
