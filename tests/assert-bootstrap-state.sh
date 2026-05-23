#!/usr/bin/env bash
# Assertions for the bootstrap idempotency test (tests/Containerfile.bootstrap).
# Sourced or invoked after `bootstrap.sh` to verify the post-install
# contract: prerequisites installed, clone present, config present,
# symlink resolves correctly. Run after each bootstrap invocation.

set -euo pipefail

: "${HANZO_DIR:?HANZO_DIR must be set}"

test -x "$HOME/.local/bin/uv"
"$HOME/.local/bin/uv" tool list | grep -q '^ansible-core'
test -d "$HANZO_DIR/.git"
test -f "$HOME/.config/hanzo/config.yml"
test "$(readlink -f "$HOME/.local/bin/hanzo")" = "$HANZO_DIR/bin/hanzo"
