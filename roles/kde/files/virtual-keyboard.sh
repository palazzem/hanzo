#!/usr/bin/env bash
set -euo pipefail

# Sets the Wayland virtual keyboard (on-screen keyboard input method) to
# the given .desktop file.
#
# Writes empty first, then the target, each with --notify: KConfig sends
# no change notification for a value already on disk (see
# lessons/input-devices.md). The caller guards invocation, so this script
# applies unconditionally.
#
# Config:
#   VIRTUAL_KEYBOARD_DESKTOP_FILE=/usr/share/applications/org.kde.plasma.keyboard.desktop (default)

VIRTUAL_KEYBOARD_DESKTOP_FILE="${VIRTUAL_KEYBOARD_DESKTOP_FILE:-/usr/share/applications/org.kde.plasma.keyboard.desktop}"

if [ ! -f "$VIRTUAL_KEYBOARD_DESKTOP_FILE" ]; then
  echo "Virtual keyboard desktop file not found: $VIRTUAL_KEYBOARD_DESKTOP_FILE" >&2
  exit 1
fi

kwriteconfig6 --file kwinrc --group Wayland --key InputMethod "" --notify
kwriteconfig6 --file kwinrc --group Wayland --key InputMethod "$VIRTUAL_KEYBOARD_DESKTOP_FILE" --notify

echo "Virtual keyboard set to $VIRTUAL_KEYBOARD_DESKTOP_FILE."
