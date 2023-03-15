FROM archlinux:base-devel

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL

# Build with Hanzo and complete the cleanup
RUN pacman -Sy git --noconfirm \
  && curl -L http://j.mp/hattori-hanzo | sh \
  && find /var/cache/pacman/ -type f -delete \
  && rm -rf /root/.hanzo /root/.ansible /root/.local

# Set default login user
USER $HANZO_USERNAME
