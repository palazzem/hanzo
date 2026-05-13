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

# --- Logging helpers ---
# Duplicated from bin/hanzo.sh until a shared library is extracted.

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

# --- Configuration ---

HANZO_CONFIG_FILE="${HOME}/.config/hanzo/config"

load_hanzo_config() {
    if [ -f "$HANZO_CONFIG_FILE" ]; then
        # shellcheck source=/dev/null
        source "$HANZO_CONFIG_FILE"
    else
        log_warn "Hanzo config file not found at ${HANZO_CONFIG_FILE}"
        log_warn "Run 'hanzo config init' to create it"
    fi
}

# --- Dotfiles repository ---

DOTFILES_REPO="https://github.com/palazzem/dotfiles.git"
DOTFILES_DIR="${HOME}/.dotfiles"

clone_or_update_dotfiles() {
    if [ -d "${DOTFILES_DIR}/.git" ]; then
        log_info "Dotfiles already cloned. Pulling latest changes..."
        git -C "$DOTFILES_DIR" pull
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
    log_success "Dotfiles repository is up to date"
}

# --- Dotfiles installer ---

run_dotfiles_installer() {
    local installer="${DOTFILES_DIR}/install.sh"

    if [ ! -f "$installer" ]; then
        log_error "Dotfiles installer not found at ${installer}"
        log_error "The dotfiles repository may need to be updated"
        return 1
    fi

    if [ ! -x "$installer" ]; then
        log_warn "Dotfiles installer is not executable. Setting permissions..."
        chmod +x "$installer"
    fi

    log_info "Running dotfiles installer..."
    "$installer"
    log_success "Dotfiles installer completed"
}

# --- Git identity injection ---

inject_git_config() {
    local has_values=true

    if [ -z "${HANZO_FULLNAME:-}" ]; then
        log_warn "HANZO_FULLNAME is empty. Skipping git user.name injection."
        has_values=false
    fi

    if [ -z "${HANZO_EMAIL:-}" ]; then
        log_warn "HANZO_EMAIL is empty. Skipping git user.email injection."
        has_values=false
    fi

    if [ "$has_values" = false ]; then
        log_warn "Run 'hanzo config init' to set your identity"
        return 0
    fi

    log_info "Injecting git identity..."
    git config --global user.name "$HANZO_FULLNAME"
    git config --global user.email "$HANZO_EMAIL"
    log_success "Git identity set to: ${HANZO_FULLNAME} <${HANZO_EMAIL}>"
}

# --- Main ---

main() {
    log_info "Setting up dotfiles..."
    load_hanzo_config
    clone_or_update_dotfiles
    run_dotfiles_installer
    inject_git_config
    log_success "Dotfiles setup complete"
}

main
