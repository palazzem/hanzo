#!/usr/bin/env bash

# Copyright (c) 2014-2025, Emanuele Palazzetti and contributors
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of the FreeBSD Project.

set -e

# Colors for better visual output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "ℹ️  ${GREEN}$1${NC}"
}

log_warn() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
}

log_error() {
    echo -e "❌ ${RED}$1${NC}"
}

log_success() {
    echo -e "✅ ${GREEN}$1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Layer 1: System base packages
install_system_base() {
    log_info "Installing system base packages..."

    local packages=(
        # Core tools
        base-devel
        git
        fzf
        htop
        neovim
        fastfetch
        tree
        wget
        jq
        yq
        httpie
        openssl
        gettext
        gdb
        plocate
        procps-ng
        sudo
        bind
        whois
        tmux
        # Docker stack
        docker
        docker-buildx
        docker-compose
        # Archive
        p7zip
        unrar
        # AI/ML
        ollama-rocm
        # Audio firmware
        sof-firmware
        # ASUS tools
        asusctl
        rog-control-center
    )

    sudo pacman -S --needed --noconfirm "${packages[@]}"
    log_success "System base packages installed"
}

# Layer 2: Language runtimes
install_runtimes() {
    log_info "Installing language runtimes..."

    local packages=(
        rustup
        go
    )

    sudo pacman -S --needed --noconfirm "${packages[@]}"
    log_success "Language runtimes installed"
}

# Layer 6: Gaming and multimedia
install_gaming() {
    log_info "Installing gaming and multimedia packages..."

    local packages=(
        cachyos-gaming-applications
        ffmpeg
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
    )

    sudo pacman -S --needed --noconfirm "${packages[@]}"
    log_success "Gaming and multimedia packages installed"
}

# AUR packages via paru
install_aur_packages() {
    if ! command_exists paru; then
        log_error "paru is not installed. Install paru first to manage AUR packages."
        exit 1
    fi

    log_info "Installing AUR packages..."
    # --noconfirm intentionally skips PKGBUILD review because the AUR package
    # list is curated and vetted at plan time, not chosen dynamically at runtime.
    paru -S --needed --noconfirm fnm-bin
    log_success "AUR packages installed"
}

# GPU drivers via hardware detection
install_gpu_drivers() {
    if ! command_exists chwd; then
        log_error "chwd is not installed. Cannot auto-detect GPU drivers."
        exit 1
    fi

    log_info "Auto-detecting and installing GPU drivers..."
    sudo chwd -a
    log_success "GPU drivers installed"
}

# Main
main() {
    log_info "Starting package installation..."

    install_system_base
    install_runtimes
    install_gaming
    install_aur_packages
    install_gpu_drivers

    log_success "All packages installed successfully"
}

main "$@"
