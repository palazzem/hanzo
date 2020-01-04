FROM archlinux/base
LABEL maintainer="hello@palazzetti.me"

# Configure testing environment
ARG TAGS
ENV ANSIBLE_VERSION=2.9.2
ENV HANZO_FULLNAME test
ENV HANZO_USERNAME test
ENV HANZO_EMAIL test@example.com
ENV HANZO_SSH_PASSWORD som3th!ng

COPY . /root/hanzo
WORKDIR /root/hanzo

# Install Ansible Portable
RUN pacman -Sy tar python --noconfirm && \
  curl -L https://github.com/palazzem/ansible-portable/releases/download/$ANSIBLE_VERSION/ansible-$ANSIBLE_VERSION.tar.gz > /tmp/ansible.tar.gz && \
  curl -L https://github.com/kewlfft/ansible-aur/archive/v0.24.tar.gz > /tmp/aur.tar.gz && \
  tar -xf /tmp/ansible.tar.gz && \
  tar -xf /tmp/aur.tar.gz -C /tmp && \
  mkdir library && \
  mv /tmp/ansible-aur-0.24/aur.py ./library && \
  ln -s ansible ansible-$ANSIBLE_VERSION/ansible-playbook

# Provisioning during the build so that a container correctly
# built corresponds to a successful test
RUN PYTHONPATH=ansible-$ANSIBLE_VERSION python ansible-$ANSIBLE_VERSION/ansible-playbook orchestrate.yml --connection=local --verbose --tags=$TAGS
