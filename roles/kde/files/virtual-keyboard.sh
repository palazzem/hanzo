#!/usr/bin/env bash
set -euo pipefail

# Sets the Wayland virtual keyboard (on-screen keyboard input method) to
# the given .desktop file and verifies KWin reports it available.
#
# Always writes empty first, then the target, each with --notify: KWin's
# setInputMethodCommand() no-ops when the new value equals the current
# in-memory value even if the live state has drifted, so a real
# transition must be forced (see lessons/input-devices.md). The caller
# guards invocation, so this script applies unconditionally.
#
# Config:
#   VIRTUAL_KEYBOARD_DESKTOP_FILE=/usr/share/applications/org.kde.plasma.keyboard.desktop (default)

VIRTUAL_KEYBOARD_DESKTOP_FILE="${VIRTUAL_KEYBOARD_DESKTOP_FILE:-/usr/share/applications/org.kde.plasma.keyboard.desktop}"

if [ ! -f "$VIRTUAL_KEYBOARD_DESKTOP_FILE" ]; then
  echo "Virtual keyboard desktop file not found: $VIRTUAL_KEYBOARD_DESKTOP_FILE" >&2
  exit 1
fi

kwriteconfig6 --file kwinrc --group Wayland --key InputMethod "" --notify
sleep 1
kwriteconfig6 --file kwinrc --group Wayland --key InputMethod "$VIRTUAL_KEYBOARD_DESKTOP_FILE" --notify
sleep 1

available=$(busctl --user get-property org.kde.KWin /VirtualKeyboard org.kde.kwin.VirtualKeyboard available 2>/dev/null | awk '{print $2}')

if [ "$available" != "true" ]; then
  echo "Virtual keyboard did not report available=true after applying - check 'busctl --user get-property org.kde.KWin /VirtualKeyboard org.kde.kwin.VirtualKeyboard available'." >&2
  exit 1
fi

echo "Virtual keyboard set to $VIRTUAL_KEYBOARD_DESKTOP_FILE (available=true)."
