# shellcheck shell=bash
# Shared utilities for hanzo bin/ scripts. Source it, don't execute it.

# shellcheck disable=SC2034  # consumers pick the colors they need
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

HANZO_LOG_PREFIX="${HANZO_LOG_PREFIX:-hanzo}"

log_info()  { echo -e "${GREEN}[${HANZO_LOG_PREFIX}]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[${HANZO_LOG_PREFIX}]${NC} $1"; }
log_error() { echo -e "${RED}[${HANZO_LOG_PREFIX}]${NC} $1" >&2; }

# True when a controlling terminal is available for prompts.
has_tty() { { : </dev/tty; } 2>/dev/null; }

# True when running inside a container (podman, docker, or generic).
in_container() {
    [ -f /run/.containerenv ] || [ -f /.dockerenv ] || \
        grep -qa 'container=' /proc/1/environ 2>/dev/null
}

# Parses at most one mode flag into HANZO_MODE: --check, --ci, or none (full).
# Anything else is a usage error.
parse_mode() {
    HANZO_MODE="full"
    if [ "$#" -eq 0 ]; then
        return 0
    fi
    if [ "$#" -eq 1 ]; then
        case "$1" in
            --check) HANZO_MODE="check"; return 0 ;;
            --ci)    HANZO_MODE="ci";    return 0 ;;
        esac
    fi
    log_error "invalid arguments: $*"
    log_error "usage: ${0##*/} [--check|--ci]"
    exit 1
}

# Announces any non-default HANZO_MODE; new modes only add a description line.
mode_banner() {
    local label desc
    case "${HANZO_MODE:-full}" in
        check) label="CHECK"; desc="dry run — reports changes without applying them" ;;
        ci)    label="CI";    desc="unattended provisioning — human AUR verification is bypassed" ;;
        *)     return 0 ;;
    esac
    echo -e "${YELLOW}>>> ${label} MODE — ${desc}${NC}"
}
