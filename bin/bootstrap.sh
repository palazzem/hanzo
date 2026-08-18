#!/usr/bin/env bash
# Hanzo bootstrap — one-command CachyOS provisioner setup.
# Usage: curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash
# Modes: bash -s -- --check (dry run) | --ci (unattended, container-only) | none (attended)

set -euo pipefail

ANSIBLE_CORE_VERSION="2.21.3"

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
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! uv tool list 2>/dev/null | grep -q '^ansible-core'; then
    log "Installing ansible-core..."
    uv tool install "ansible-core~=${ANSIBLE_CORE_VERSION}"
fi

if [ ! -d "$HANZO_DIR/.git" ]; then
    log "Cloning Hanzo repository..."
    mkdir -p "$(dirname "$HANZO_DIR")"
    git clone "$HANZO_REPO" "$HANZO_DIR"
fi

trim_value() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# YAML double-quoted scalar: backslashes first, then quotes.
yaml_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# Under curl | bash stdin is the pipe — prompt and read via /dev/tty.
prompt_required() {
    local prompt="$1" value=""
    while :; do
        printf '%s' "$prompt" >/dev/tty
        read -r value </dev/tty || fail "no input available — set HANZO_FULLNAME and HANZO_EMAIL instead"
        value="$(trim_value "$value")"
        if [ -n "$value" ]; then break; fi
        printf 'A value is required.\n' >/dev/tty
    done
    printf '%s' "$value"
}

if [ ! -f "$CONFIG_FILE" ]; then
    if [ -n "${HANZO_FULLNAME:-}" ] || [ -n "${HANZO_EMAIL:-}" ]; then
        # Unattended: a half-filled identity would be persisted forever.
        HANZO_FULLNAME="$(trim_value "${HANZO_FULLNAME:-}")"
        HANZO_EMAIL="$(trim_value "${HANZO_EMAIL:-}")"
        if [ -z "$HANZO_FULLNAME" ] || [ -z "$HANZO_EMAIL" ]; then
            fail "HANZO_FULLNAME and HANZO_EMAIL must both be set to non-empty values"
        fi
    else
        HANZO_FULLNAME="$(prompt_required "Full name: ")"
        HANZO_EMAIL="$(prompt_required "Email: ")"
    fi
    mkdir -p "$(dirname "$CONFIG_FILE")"
    printf 'hanzo_fullname: "%s"\nhanzo_email: "%s"\n' \
        "$(yaml_escape "$HANZO_FULLNAME")" "$(yaml_escape "$HANZO_EMAIL")" > "$CONFIG_FILE"
    log "Configuration saved to $CONFIG_FILE"
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$HANZO_DIR/bin/hanzo" "$HOME/.local/bin/hanzo"
ln -sf "$HANZO_DIR/bin/hanzo-aur" "$HOME/.local/bin/hanzo-aur"

log "Running provisioner..."
echo ""
exec "$HOME/.local/bin/hanzo" "$@"
