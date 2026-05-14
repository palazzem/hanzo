#!/usr/bin/env bash
# Hanzo bootstrap — one-command CachyOS provisioner setup.
# Usage: curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[hanzo]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[hanzo]${NC} $1"; }
log_error()   { echo -e "${RED}[hanzo]${NC} $1" >&2; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo -e "${BLUE}"
echo "  _   _                       "
echo " | | | | __ _ _ __  _______   "
echo " | |_| |/ _\` | '_ \\|_  / _ \\  "
echo " |  _  | (_| | | | |/ / (_) | "
echo " |_| |_|\\__,_|_| |_/___\\___/  "
echo -e "${NC}"
echo -e "${GREEN}CachyOS System Provisioner${NC}"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Sudo — ask password once, keep the ticket alive in background
# ---------------------------------------------------------------------------
log_info "Requesting sudo access (you may be prompted for your password)..."
sudo -v

# Provisioning takes long enough for the sudo ticket to expire mid-run
while true; do sudo -n true; sleep 50; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT

# ---------------------------------------------------------------------------
# Step 2: Install uv (Astral's Python package manager)
# ---------------------------------------------------------------------------
if command -v uv >/dev/null 2>&1; then
    log_info "uv is already installed: $(uv --version)"
else
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # uv's installer only modifies shell profiles, not the current session
    export PATH="$HOME/.local/bin:$PATH"
fi

# ---------------------------------------------------------------------------
# Step 3: Install Ansible via uv tool
# ---------------------------------------------------------------------------
if uv tool list 2>/dev/null | grep -q "^ansible-core"; then
    log_info "ansible-core is already installed"
else
    log_info "Installing ansible-core..."
    uv tool install ansible-core
fi

# ---------------------------------------------------------------------------
# Step 4: Clone or update the Hanzo repository
# ---------------------------------------------------------------------------
HANZO_REPO="https://github.com/palazzem/hanzo.git"
HANZO_DIR="$HOME/.local/src/hanzo"

mkdir -p "$(dirname "$HANZO_DIR")"

if [ -d "$HANZO_DIR/.git" ]; then
    log_info "Updating Hanzo repository..."
    git -C "$HANZO_DIR" pull --ff-only
else
    log_info "Cloning Hanzo repository..."
    git clone "$HANZO_REPO" "$HANZO_DIR"
fi

# ---------------------------------------------------------------------------
# Step 4b: Install Ansible Galaxy collections
# ---------------------------------------------------------------------------
log_info "Installing Ansible Galaxy collections..."
ansible-galaxy collection install -r "$HANZO_DIR/requirements.yml"

# ---------------------------------------------------------------------------
# Step 5: User configuration
# When piped from curl, stdin is the pipe — read from /dev/tty to reach
# the terminal for interactive prompts.
# ---------------------------------------------------------------------------
CONFIG_DIR="$HOME/.config/hanzo"
CONFIG_FILE="$CONFIG_DIR/config.yml"

# YAML double-quoted strings treat \ and " as significant. Order matters:
# escape backslash first so we don't double-escape the backslashes we
# add in the quote-escape step.
yaml_escape() {
    local v="${1//\\/\\\\}"
    printf '%s' "${v//\"/\\\"}"
}

# Writes the YAML config file with restrictive permissions. Uses a
# subshell umask so the file is never world-readable, even briefly.
write_config() {
    local escaped_fullname escaped_email
    escaped_fullname=$(yaml_escape "$HANZO_FULLNAME")
    escaped_email=$(yaml_escape "$HANZO_EMAIL")

    mkdir -p "$CONFIG_DIR"
    chmod 0700 "$CONFIG_DIR"
    (umask 077 && cat > "$CONFIG_FILE" << EOF
hanzo_fullname: "$escaped_fullname"
hanzo_email: "$escaped_email"
EOF
    )
}

if [ -f "$CONFIG_FILE" ]; then
    log_info "Configuration already exists at $CONFIG_FILE"
elif [ -n "${HANZO_FULLNAME:-}" ] && [ -n "${HANZO_EMAIL:-}" ]; then
    # Unattended mode: env vars are set (e.g., container testing).
    # Newlines and carriage returns would inject arbitrary lines into
    # the YAML config file; YAML parsers handle \r inconsistently so we
    # reject both.
    if [[ "$HANZO_FULLNAME" == *[$'\n\r']* ]] || [[ "$HANZO_EMAIL" == *[$'\n\r']* ]]; then
        log_error "HANZO_FULLNAME and HANZO_EMAIL must not contain newlines or carriage returns"
        exit 1
    fi

    write_config
    log_info "Configuration saved to $CONFIG_FILE (from environment)"
else
    log_info "First-time setup — configuring Hanzo"
    echo ""

    read -rp "Full name: " HANZO_FULLNAME </dev/tty
    read -rp "Email: " HANZO_EMAIL </dev/tty

    write_config
    log_info "Configuration saved to $CONFIG_FILE"
fi

# ---------------------------------------------------------------------------
# Step 6: Symlink bin/hanzo into PATH
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
ln -sf "$HANZO_DIR/bin/hanzo" "$HOME/.local/bin/hanzo"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    log_warn "\$HOME/.local/bin is not in your PATH — add it to your shell config"
fi

# ---------------------------------------------------------------------------
# Step 7: Run the provisioner
# ---------------------------------------------------------------------------
log_info "Running provisioner..."
echo ""
cd "$HANZO_DIR"
ansible-playbook playbook.yml

echo ""
log_info "Done! Run 'hanzo' to re-provision at any time."
