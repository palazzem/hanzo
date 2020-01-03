FROM archlinux/base
LABEL maintainer="hello@palazzetti.me"

# Configure testing environment
ARG TAGS
ENV HANZO_FULLNAME test
ENV HANZO_USERNAME test
ENV HANZO_EMAIL test@example.com
ENV HANZO_SSH_PASSWORD som3th!ng

# Install Hanzo with requirements
RUN pacman -Syu --noconfirm \
  && pacman --noconfirm -S \
     sudo \
     git \
     ansible \
  && mkdir -p /usr/share/ansible/plugins/modules \
  && git clone https://github.com/kewlfft/ansible-aur.git /usr/share/ansible/plugins/modules
COPY . /root/hanzo
WORKDIR /root/hanzo

# Provisioning during the build so that a container correctly
# built corresponds to a successful test
RUN ansible-playbook orchestrate.yml --connection=local --verbose --tags=$TAGS
