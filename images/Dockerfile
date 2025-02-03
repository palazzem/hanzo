FROM fedora:41

# Build environment settings
ARG HANZO_USERNAME
ARG HANZO_FULLNAME
ARG HANZO_EMAIL
ENV TZ="Europe/Rome"

# Fail if required build args are missing
RUN [ -n "$HANZO_USERNAME" ] || (echo "HANZO_USERNAME not set" && false) && \
    [ -n "$HANZO_FULLNAME" ] || (echo "HANZO_FULLNAME not set" && false) && \
    [ -n "$HANZO_EMAIL" ] || (echo "HANZO_EMAIL not set" && false)

# Update base system
RUN dnf update -y && dnf clean all

# Add external repositories
RUN dnf install -y dnf-plugins-core && \
    dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo && \
    dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    && dnf clean all

# Install dev env packages
RUN dnf group install -y development-tools && \
    dnf install -y \
    bind-utils \
    cargo \
    chrony \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    dosfstools \
    emacs \
    fastfetch \
    ffmpeg \
    fzf \
    gdb \
    gettext \
    git \
    glibc-langpack-en \
    golang \
    htop \
    httpie \
    iputils \
    java-latest-openjdk-devel \
    jq \
    kernel-devel \
    kernel-headers \
    mono-core \
    neovim \
    nodejs \
    ntfs-3g \
    openssl \
    p7zip \
    p7zip-plugins \
    packer \
    pipx \
    plocate \
    postgresql \
    python3 \
    python3-pip \
    python3-setuptools \
    ruby \
    rust \
    speedtest-cli \
    sqlite \
    sudo \
    terraform \
    transmission-cli \
    tree \
    unrar \
    wget \
    which \
    whois \
    yq \
    yt-dlp \
    zsh \
    && dnf clean all

# User setup and permissions
RUN useradd -m -G wheel "${HANZO_USERNAME}" && \
    mkdir -p "/home/${HANZO_USERNAME}/programs" && \
    mkdir -p "/home/${HANZO_USERNAME}/workspaces" && \
    chown -R "${HANZO_USERNAME}:${HANZO_USERNAME}" "/home/${HANZO_USERNAME}" && \
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    usermod -aG docker ${HANZO_USERNAME}

# Install and configure Oh My Zsh
RUN su - ${HANZO_USERNAME} -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh > install.sh && sh install.sh --unattended && rm install.sh' && \
    chsh -s $(which zsh) ${HANZO_USERNAME}

# Development tools and configurations that require user context
RUN su - ${HANZO_USERNAME} -c "\
        curl -fsSL https://pyenv.run | bash && \
        mkdir -p /home/${HANZO_USERNAME}/programs/go/bin && \
        GOPATH=/home/${HANZO_USERNAME}/programs/go go install github.com/minamijoyo/tfupdate@latest && \
        pipx install ipython && \
        pipx install hatch && \
        pipx install pre-commit && \
        pipx install checkov && \
        mkdir -p /home/${HANZO_USERNAME}/.local/share && \
        curl -o /tmp/gcloud_installer.sh https://sdk.cloud.google.com && \
        bash /tmp/gcloud_installer.sh --disable-prompts \
            --install-dir=/home/${HANZO_USERNAME}/.local/share && \
        rm /tmp/gcloud_installer.sh && \
        git clone https://github.com/syl20bnr/spacemacs /home/${HANZO_USERNAME}/.emacs.d" && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# User dotfiles
RUN su - ${HANZO_USERNAME} -c "\
    git clone https://github.com/palazzem/dotfiles.git /home/${HANZO_USERNAME}/.dotfiles && \
    rm -f /home/${HANZO_USERNAME}/.zshrc \
         /home/${HANZO_USERNAME}/.zshenv \
         /home/${HANZO_USERNAME}/.spacemacs && \
    ln -s /home/${HANZO_USERNAME}/.dotfiles/zshrc /home/${HANZO_USERNAME}/.zshrc && \
    ln -s /home/${HANZO_USERNAME}/.dotfiles/zshenv /home/${HANZO_USERNAME}/.zshenv && \
    ln -s /home/${HANZO_USERNAME}/.dotfiles/spacemacs /home/${HANZO_USERNAME}/.spacemacs"

# Git configuration from template
COPY templates/gitconfig /tmp/.gitconfig.template
RUN envsubst < /tmp/.gitconfig.template > "/home/${HANZO_USERNAME}/.gitconfig" && \
    chown ${HANZO_USERNAME}:${HANZO_USERNAME} "/home/${HANZO_USERNAME}/.gitconfig" && \
    rm /tmp/.gitconfig.template -f

# Set default login user
USER $HANZO_USERNAME
