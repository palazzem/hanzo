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
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Settings
URL="https://github.com/palazzem/hanzo.git"
WORKSPACE_NAME="hanzo"

# Configuration handling
CONFIG_FILE="$HOME/.config/hanzo/config"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

# Load configuration from file if it exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

# Save configuration to file
save_config() {
    mkdir -p "$CONFIG_DIR"

    # Create or overwrite config file
    cat > "$CONFIG_FILE" << EOF
# Hanzo configuration file
# Generated on $(date)

# User information
HANZO_FULLNAME="$HANZO_FULLNAME"
HANZO_USERNAME="$HANZO_USERNAME"
HANZO_EMAIL="$HANZO_EMAIL"
EOF

    log_success "Configuration saved to $CONFIG_FILE"
}

# Set configuration values
set_config() {
    case "$1" in
        fullname)
            HANZO_FULLNAME="$2"
            log_success "Full name set to: $HANZO_FULLNAME"
            ;;
        username)
            HANZO_USERNAME="$2"
            log_success "Username set to: $HANZO_USERNAME"
            ;;
        email)
            HANZO_EMAIL="$2"
            log_success "Email set to: $HANZO_EMAIL"
            ;;
        *)
            log_error "Unknown configuration key: $1"
            log_info "Available keys: fullname, username, email"
            return 1
            ;;
    esac

    save_config
    return 0
}

# Initialize configuration with environment variables or defaults
init_config() {
    # Use environment variables if set, otherwise use values from config file
    HANZO_FULLNAME="${HANZO_FULLNAME:-}"
    HANZO_USERNAME="${HANZO_USERNAME:-}"
    HANZO_EMAIL="${HANZO_EMAIL:-}"

    # Load from config file if values are still empty
    if [ -z "$HANZO_FULLNAME" ] || [ -z "$HANZO_USERNAME" ] || [ -z "$HANZO_EMAIL" ]; then
        load_config
    fi
}

# Print banner
print_banner() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}║                      ${GREEN}Hanzo CLI${BLUE}                         ║${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print usage information
print_usage() {
    echo -e "${GREEN}Usage:${NC} hanzo <command>"
    echo ""
    echo -e "${GREEN}Commands:${NC}"
    echo -e "  ${BLUE}ssh${NC}                Connect to the workspace via SSH"
    echo -e "  ${BLUE}up${NC}                 Start the workspace"
    echo -e "  ${BLUE}down${NC}               Stop the workspace"
    echo -e "  ${BLUE}update${NC}             Update the workspace (recreate)"
    echo -e "  ${BLUE}destroy${NC}            Destroy the workspace"
    echo -e "  ${BLUE}config${NC}             Show current configuration"
    echo -e "  ${BLUE}config set KEY VALUE${NC}  Set configuration value"
    echo -e "  ${BLUE}config init${NC}        Interactive configuration setup"
    echo -e "  ${BLUE}help${NC}               Show this help message"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  hanzo config set fullname \"John Doe\""
    echo -e "  hanzo config set username johndoe"
    echo -e "  hanzo config set email john@example.com"
    echo ""
}

# Log messages with different levels
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

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    local missing_deps=0

    for cmd in devpod orb docker ssh-keygen gpgconf; do
        if ! command_exists "$cmd"; then
            log_error "Required command '$cmd' not found"
            missing_deps=1
        fi
    done

    if [ $missing_deps -eq 1 ]; then
        log_error "Please install missing dependencies and try again"
        exit 1
    fi
}

# Helper functions
setup_keys() {
    log_info "Setting up SSH keys..."

    # Check if the key exists
    if [ ! -f ~/.ssh/id_ed25519.pub ]; then
        log_error "SSH key not found at ~/.ssh/id_ed25519.pub"
        log_info "Generate a key with: ssh-keygen -t ed25519 -C \"your_email@example.com\""
        exit 1
    fi

    # Get the fingerprint of the key
    FINGERPRINT=$(ssh-keygen -l -f ~/.ssh/id_ed25519.pub | awk '{print $2}')

    # Check if the key is already added
    if ! ssh-add -l | grep -q "$FINGERPRINT"; then
        log_info "Adding SSH key to agent..."
        ssh-add ~/.ssh/id_ed25519
    else
        log_info "SSH key already added to agent"
    fi

    # Restart GPG service
    log_info "Restarting GPG agent..."
    gpgconf --kill gpg-agent && gpg -K

    log_success "Keys setup complete"
}

cleanup_docker() {
    log_info "Cleaning up Docker resources..."

    IMAGE_ID=$(docker images --format "{{.Repository}} {{.ID}}" | awk '$1 ~ /^vsc-content-/ {print $2}')

    if [ -n "$IMAGE_ID" ]; then
        log_info "Stopping workspace..."
        devpod stop $WORKSPACE_NAME

        log_info "Deleting workspace..."
        devpod delete $WORKSPACE_NAME

        log_info "Removing Docker image..."
        docker rmi $IMAGE_ID

        log_info "Pruning Docker builder cache..."
        docker builder prune -f

        log_success "Cleanup complete"
    else
        log_warn "No workspace images found to clean up"
    fi
}

check_config() {
    local missing=0

    if [ -z "$HANZO_FULLNAME" ]; then
        log_warn "HANZO_FULLNAME is not set"
        missing=1
    fi

    if [ -z "$HANZO_USERNAME" ]; then
        log_warn "HANZO_USERNAME is not set"
        missing=1
    fi

    if [ -z "$HANZO_EMAIL" ]; then
        log_warn "HANZO_EMAIL is not set"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        log_info "Update your configuration in ~/.local/src/hanzo/bin/hanzo.sh"
        return 1
    fi

    return 0
}

show_config() {
    echo -e "${GREEN}Current Configuration:${NC}"
    echo -e "  ${BLUE}HANZO_FULLNAME${NC}: ${HANZO_FULLNAME:-<not set>}"
    echo -e "  ${BLUE}HANZO_USERNAME${NC}: ${HANZO_USERNAME:-<not set>}"
    echo -e "  ${BLUE}HANZO_EMAIL${NC}:    ${HANZO_EMAIL:-<not set>}"
    echo ""

    if ! check_config; then
        log_warn "Some configuration values are missing"
    else
        log_success "Configuration is complete"
    fi
}

# Interactive configuration setup
interactive_config() {
    log_info "Interactive configuration setup"
    echo ""

    # Show current values if any
    [ -n "$HANZO_FULLNAME" ] && echo -e "Current full name: ${BLUE}$HANZO_FULLNAME${NC}"
    [ -n "$HANZO_USERNAME" ] && echo -e "Current username: ${BLUE}$HANZO_USERNAME${NC}"
    [ -n "$HANZO_EMAIL" ] && echo -e "Current email: ${BLUE}$HANZO_EMAIL${NC}"
    echo ""

    # Prompt for values with default suggestions
    echo -n "Enter your full name"
    [ -n "$HANZO_FULLNAME" ] && echo -n " [${BLUE}$HANZO_FULLNAME${NC}]"
    echo -n ": "
    read input_fullname
    HANZO_FULLNAME="${input_fullname:-$HANZO_FULLNAME}"

    echo -n "Enter your username"
    [ -n "$HANZO_USERNAME" ] && echo -n " [${BLUE}$HANZO_USERNAME${NC}]"
    echo -n ": "
    read input_username
    HANZO_USERNAME="${input_username:-$HANZO_USERNAME}"

    echo -n "Enter your email"
    [ -n "$HANZO_EMAIL" ] && echo -n " [${BLUE}$HANZO_EMAIL${NC}]"
    echo -n ": "
    read input_email
    HANZO_EMAIL="${input_email:-$HANZO_EMAIL}"

    # Save configuration
    save_config
    log_success "Configuration completed"
}

# Main command handling
main() {
    print_banner
    check_dependencies

    # Initialize configuration
    init_config

    case "$1" in
        ssh)
            setup_keys
            log_info "Connecting to workspace via SSH..."
            ssh "$WORKSPACE_NAME.devpod"
            ;;
        up)
            check_config || exit 1
            log_info "Starting orb..."
            orb start

            log_info "Starting workspace..."
            devpod up --gpg-agent-forwarding --id $WORKSPACE_NAME $URL

            log_success "Workspace is up and running"
            ;;
        down)
            log_info "Stopping workspace..."
            devpod stop $WORKSPACE_NAME

            log_info "Stopping orb..."
            orb stop

            log_success "Workspace stopped"
            ;;
        update)
            check_config || exit 1
            log_info "Starting orb..."
            orb start

            log_info "Cleaning up existing workspace..."
            cleanup_docker

            log_info "Recreating workspace..."
            devpod up --gpg-agent-forwarding --recreate --id $WORKSPACE_NAME $URL

            log_success "Workspace recreated successfully"
            ;;
        destroy)
            log_info "Starting orb..."
            orb start

            log_info "Destroying workspace..."
            cleanup_docker

            log_success "Workspace destroyed"
            ;;
        config)
            case "$2" in
                set)
                    if [ -z "$3" ] || [ -z "$4" ]; then
                        log_error "Missing arguments for config set"
                        echo -e "Usage: hanzo config set KEY VALUE"
                        exit 1
                    fi
                    set_config "$3" "$4"
                    ;;
                init)
                    interactive_config
                    ;;
                "")
                    show_config
                    ;;
                *)
                    log_error "Unknown config subcommand: $2"
                    echo -e "Available subcommands: set, init"
                    exit 1
                    ;;
            esac
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            log_error "Unknown command: $1"
            print_usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
