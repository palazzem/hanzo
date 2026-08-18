#!/usr/bin/env bash
# Hanzo bootstrap — one-command CachyOS provisioner setup.
# Usage: curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash
# Modes: bash -s -- --check (dry run) | --ci (unattended, container-only) | none (attended)

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
log()  { echo -e "${GREEN}[hanzo]${NC} $1"; }
fail() { echo -e "${RED}[hanzo]${NC} $1" >&2; exit 1; }

case "${1:-}" in
    ""|--check) ;;
    # CI bypasses human verification — never allow it on a real host.
    # podman creates /run/.containerenv and sets container=; docker run
    # creates /.dockerenv; docker build provides none of them, so
    # tests/Containerfile sets container=docker explicitly.
    --ci)
        [ -f /run/.containerenv ] || [ -f /.dockerenv ] || [ -n "${container:-}" ] || \
            fail "--ci runs unattended — allowed only inside a container"
        ;;
    *) fail "usage: bootstrap.sh [--check|--ci]" ;;
esac

HANZO_REPO="https://github.com/palazzem/hanzo.git"
HANZO_DIR="$HOME/.local/src/hanzo"
CONFIG_FILE="$HOME/.config/hanzo/config.yml"
export PATH="$HOME/.local/bin:$PATH"

echo -e "${BLUE}"
echo "  _   _                       "
echo " | | | | __ _ _ __  _______   "
echo " | |_| |/ _\` | '_ \\|_  / _ \\  "
echo " |  _  | (_| | | | |/ / (_) | "
echo " |_| |_|\\__,_|_| |_/___\\___/  "
echo -e "${NC}"
echo -e "${GREEN}CachyOS System Provisioner${NC}"
echo ""

if ! command -v uv >/dev/null 2>&1; then
    log "Installing uv..."
    sudo pacman -S --needed --noconfirm uv
fi

if [ ! -d "$HANZO_DIR/.git" ]; then
    log "Cloning Hanzo repository..."
    mkdir -p "$(dirname "$HANZO_DIR")"
    git clone "$HANZO_REPO" "$HANZO_DIR"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    if [ -z "${HANZO_FULLNAME:-}" ]; then
        # Under curl | bash stdin is the pipe — prompt via /dev/tty.
        read -rp "Full name: " HANZO_FULLNAME </dev/tty
        read -rp "Email: " HANZO_EMAIL </dev/tty
    fi
    mkdir -p "$(dirname "$CONFIG_FILE")"
    printf 'hanzo_fullname: "%s"\nhanzo_email: "%s"\n' "$HANZO_FULLNAME" "$HANZO_EMAIL" > "$CONFIG_FILE"
    log "Configuration saved to $CONFIG_FILE"
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$HANZO_DIR/bin/hanzo" "$HOME/.local/bin/hanzo"
ln -sf "$HANZO_DIR/bin/hanzo-aur" "$HOME/.local/bin/hanzo-aur"

log "Running provisioner..."
echo ""
exec "$HOME/.local/bin/hanzo" "$@"
