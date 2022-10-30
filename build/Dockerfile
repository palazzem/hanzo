FROM library/archlinux:latest

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL

# Build with Hanzo
RUN pacman -Sy git --noconfirm \
  && curl -L http://j.mp/hattori-hanzo | sh \
  && find /var/cache/pacman/ -type f -delete
