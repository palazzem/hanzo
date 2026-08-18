#!/usr/bin/env bash
# PreToolUse guard: block any Bash command that executes a provisioning entry
# point on the host. Commands that only reference those paths as data (cat,
# grep, git, shellcheck, docker build) are allowed through.
set -euo pipefail

PAYLOAD=$(cat)

extract_command() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // ""'
    else
        printf '%s' "$PAYLOAD" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))'
    fi
}

COMMAND=$(extract_command 2>/dev/null || printf '')
[ -n "$COMMAND" ] || exit 0

# An execution position is the start of a line or the character after a shell
# separator (; | & && || $( `), optionally preceded by env assignments and by
# wrappers or interpreters that pass through to the real command.
SEPARATOR='(^|[;&|(`])[;&|]*[[:space:]]*'
PREFIX='(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|env|sudo|command|nohup|bash|sh|zsh|source|\.)[[:space:]]+)*'
TARGET='([^[:space:]]*/(hanzo|hanzo-aur|bootstrap\.sh)|hanzo|hanzo-aur|ansible|ansible-playbook|ansible-pull|ansible-console|shelly[[:space:]]+install)'
PATTERN="${SEPARATOR}${PREFIX}${TARGET}([[:space:]]|\$)"

if printf '%s' "$COMMAND" | grep -Eq "$PATTERN"; then
    echo "Blocked: this command executes a provisioning entry point (ansible*, hanzo, hanzo-aur, bootstrap.sh, shelly install) on the host — provisioning may only run in the CachyOS test container via 'docker build -f tests/Containerfile'." >&2
    exit 2
fi

exit 0
