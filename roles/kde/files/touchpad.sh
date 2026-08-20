#!/usr/bin/env bash
set -euo pipefail

# Configures touchpad natural (inverted) scrolling, tap-to-click and the
# right-click method over the KWin InputDevice D-Bus API. KWin applies live and persists to
# ~/.config/kcminputrc. Prints one CHANGED line per property it had to
# write; prints nothing when every touchpad already matches.
#
# Config:
#   NATURAL_SCROLL=true|false   (default: true)  true = inverted scroll direction
#   TAP_TO_CLICK=true|false     (default: false) false = tap-to-click disabled
#   CLICK_METHOD=clickfinger|areas (default: clickfinger)
#     clickfinger = right-click by pressing anywhere with two fingers
#     areas       = right-click by pressing the bottom-right corner

BUS_DEST="org.kde.KWin"
MANAGER_PATH="/org/kde/KWin/InputDevice"
MANAGER_IFACE="org.kde.KWin.InputDeviceManager"
DEVICE_IFACE="org.kde.KWin.InputDevice"

NATURAL_SCROLL="${NATURAL_SCROLL:-true}"
TAP_TO_CLICK="${TAP_TO_CLICK:-false}"
CLICK_METHOD="${CLICK_METHOD:-clickfinger}"

case "$CLICK_METHOD" in
  clickfinger) CLICKFINGER=true ;;
  areas) CLICKFINGER=false ;;
  *) echo "CLICK_METHOD must be clickfinger or areas, got: $CLICK_METHOD" >&2; exit 1 ;;
esac

get_prop() { # <device path> <property> -> lowercase value
  busctl --user --json=short get-property "$BUS_DEST" "$1" "$DEVICE_IFACE" "$2" \
    | python3 -c 'import json,sys; print(str(json.load(sys.stdin)["data"]).lower())'
}

ensure_prop() { # <device path> <property> <true|false>
  local current
  current="$(get_prop "$1" "$2")"
  if [ "$current" != "$3" ]; then
    busctl --user set-property "$BUS_DEST" "$1" "$DEVICE_IFACE" "$2" b "$3"
    echo "CHANGED: $1 $2 -> $3"
  fi
}

sys_names=$(busctl --user --json=short get-property "$BUS_DEST" "$MANAGER_PATH" "$MANAGER_IFACE" devicesSysNames \
  | python3 -c 'import json,sys; print("\n".join(json.load(sys.stdin)["data"]))')

found=0
while IFS= read -r sys_name; do
  [ -z "$sys_name" ] && continue
  dev_path="${MANAGER_PATH}/${sys_name}"

  if [ "$(get_prop "$dev_path" touchpad 2>/dev/null || echo false)" = "true" ]; then
    found=1
    ensure_prop "$dev_path" naturalScroll "$NATURAL_SCROLL"
    ensure_prop "$dev_path" tapToClick "$TAP_TO_CLICK"
    ensure_prop "$dev_path" clickMethodClickfinger "$CLICKFINGER"
  fi
done <<< "$sys_names"

if [ "$found" -eq 0 ]; then
  echo "No touchpad device found on the session bus." >&2
  exit 1
fi
