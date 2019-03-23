FROM archlinux/base
LABEL maintainer="hello@palazzetti.me"

# Configure testing environment
ENV FULLNAME test
ENV USERNAME test
ENV EMAIL test@example.com
ENV SSH_PASSWORD som3th!ng

# Install Hanzo with requirements
RUN pacman -Syu --noconfirm \
  && pacman --noconfirm -S \
     sudo \
     ansible
COPY . /root/hanzo
WORKDIR /root/hanzo

# Provisioning during the build so that a container correctly
# built corresponds to a successful test
RUN ansible-playbook orchestrate.yml --connection=local --verbose
