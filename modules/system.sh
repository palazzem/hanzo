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

# Add current user to a group if not already a member
ensure_group_membership() {
    local group="$1"

    if id -nG "$USER" | grep -qw "$group"; then
        log_info "User $USER is already a member of group '$group'"
    else
        log_info "Adding user $USER to group '$group'..."
        sudo usermod -aG "$group" "$USER"
        log_success "User $USER added to group '$group'"
    fi
}

# Enable and start a systemd service if not already enabled
ensure_service_enabled() {
    local service="$1"

    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        log_info "Service '$service' is already enabled"
    else
        log_info "Enabling service '$service'..."
        sudo systemctl enable "$service"
        sudo systemctl start "$service" 2>/dev/null || log_warn "Service '$service' enabled but could not be started (will start on next boot)"
        log_success "Service '$service' enabled and started"
    fi
}

# Ensure locale is generated and set
configure_locale() {
    local target_locale="en_US.UTF-8"

    # Check if locale is already generated
    if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
        log_info "Locale $target_locale is already generated"
    else
        log_info "Generating locale $target_locale..."

        # Uncomment the locale in /etc/locale.gen if it's commented out
        if grep -q "^#\s*${target_locale}" /etc/locale.gen; then
            sudo sed -i "s/^#\s*\(${target_locale}\)/\1/" /etc/locale.gen
        fi

        sudo locale-gen
        log_success "Locale $target_locale generated"
    fi

    # Ensure /etc/locale.conf has the correct LANG
    if grep -q "^LANG=${target_locale}$" /etc/locale.conf 2>/dev/null; then
        log_info "Locale configuration is already set to $target_locale"
    else
        log_info "Setting system locale to $target_locale..."
        echo "LANG=${target_locale}" | sudo tee /etc/locale.conf >/dev/null
        log_success "System locale set to $target_locale"
    fi
}

# User groups
configure_groups() {
    log_info "Configuring user group memberships..."

    ensure_group_membership docker
    ensure_group_membership render
    ensure_group_membership video

    log_success "User group memberships configured"
}

# Systemd services
configure_services() {
    log_info "Configuring systemd services..."

    ensure_service_enabled docker
    ensure_service_enabled ollama
    ensure_service_enabled asusd

    log_success "Systemd services configured"
}

# Main
main() {
    log_info "Starting system configuration..."

    configure_groups
    configure_services
    configure_locale

    log_success "System configuration complete"
}

main "$@"
