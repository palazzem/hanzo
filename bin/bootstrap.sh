#!/usr/bin/env bash
# Hanzo bootstrap — one-command CachyOS provisioner setup.
# Usage: curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash
# Modes: bash -s -- --check (dry run) | --ci (unattended, container-only) | none (attended)

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
# Mode parsing — inline because this script runs curl-piped, before the
# repo (and bin/lib.sh) exists on disk. Same contract as lib.sh parse_mode.
# ---------------------------------------------------------------------------
in_container() {
    [ -f /run/.containerenv ] || [ -f /.dockerenv ] || \
        grep -qa 'container=' /proc/1/environ 2>/dev/null
}

HANZO_MODE="full"
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--check" ] && [ "$1" != "--ci" ]; }; then
    log_error "invalid arguments: $*"
    log_error "usage: bootstrap.sh [--check|--ci]"
    exit 1
elif [ "$#" -eq 1 ]; then
    HANZO_MODE="${1#--}"
fi

# CI mode later bypasses human AUR verification — never allow it on a real host.
if [ "$HANZO_MODE" = "ci" ] && ! in_container; then
    log_error "--ci runs unattended and bypasses human AUR verification — allowed only inside a container"
    exit 1
fi

case "$HANZO_MODE" in
    check) echo -e "${YELLOW}>>> CHECK MODE — dry run — reports changes without applying them${NC}" ;;
    ci)    echo -e "${YELLOW}>>> CI MODE — unattended provisioning — human AUR verification is bypassed${NC}" ;;
esac

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
# Step 1: Install uv (Astral's Python package manager)
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

if command -v uv >/dev/null 2>&1; then
    log_info "uv is already installed: $(uv --version)"
else
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ---------------------------------------------------------------------------
# Step 2: Install Ansible via uv tool
# ---------------------------------------------------------------------------
if uv tool list 2>/dev/null | grep -q "^ansible-core"; then
    log_info "ansible-core is already installed"
else
    log_info "Installing ansible-core..."
    uv tool install 'ansible-core~=2.20.5'
fi

# ---------------------------------------------------------------------------
# Step 3: Clone or update the Hanzo repository
# ---------------------------------------------------------------------------
HANZO_REPO="https://github.com/palazzem/hanzo.git"
HANZO_DIR="$HOME/.local/src/hanzo"

mkdir -p "$(dirname "$HANZO_DIR")"

if [ -d "$HANZO_DIR/.git" ]; then
    log_info "Hanzo repository already present at $HANZO_DIR"
else
    log_info "Cloning Hanzo repository..."
    git clone "$HANZO_REPO" "$HANZO_DIR"
fi

# ---------------------------------------------------------------------------
# Step 4: User configuration
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
# Step 5: Symlink bin/hanzo into PATH
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
ln -sf "$HANZO_DIR/bin/hanzo" "$HOME/.local/bin/hanzo"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    log_warn "\$HOME/.local/bin is not in your PATH — add it to your shell config"
fi

# ---------------------------------------------------------------------------
# Step 6: Run Hanzo for provisioning
# ---------------------------------------------------------------------------
log_info "Running provisioner..."
echo ""
if [ "$HANZO_MODE" = "full" ]; then
    exec "$HOME/.local/bin/hanzo"
else
    exec "$HOME/.local/bin/hanzo" "--$HANZO_MODE"
fi
