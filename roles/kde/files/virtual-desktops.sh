#!/usr/bin/env bash
set -euo pipefail

# Ensures the virtual desktop count and grid layout over the KWin
# VirtualDesktopManager D-Bus API. KWin applies live and persists to
# ~/.config/kwinrc. Prints one CHANGED line per desktop created or row
# change; prints nothing when the layout already matches.
#
# `count` is read-only: desktops are added with createDesktop(position,
# name). No CLI tool exists for this, hence the direct D-Bus calls.
#
# Config:
#   TARGET_DESKTOPS=5   (default: 5)  total number of virtual desktops
#   TARGET_ROWS=1       (default: 1)  desktop grid rows (columns are implied)

BUS_DEST="org.kde.KWin"
VDM_PATH="/VirtualDesktopManager"
VDM_IFACE="org.kde.KWin.VirtualDesktopManager"

TARGET_DESKTOPS="${TARGET_DESKTOPS:-5}"
TARGET_ROWS="${TARGET_ROWS:-1}"

get_prop() { # <property>
  busctl --user --json=short get-property "$BUS_DEST" "$VDM_PATH" "$VDM_IFACE" "$1" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"])'
}

current_count="$(get_prop count)"

while [ "$current_count" -lt "$TARGET_DESKTOPS" ]; do
  next_num=$((current_count + 1))
  busctl --user call "$BUS_DEST" "$VDM_PATH" "$VDM_IFACE" createDesktop us "$current_count" "Desktop $next_num"
  current_count="$next_num"
  echo "CHANGED: created desktop $next_num"
done

if [ "$(get_prop rows)" != "$TARGET_ROWS" ]; then
  busctl --user set-property "$BUS_DEST" "$VDM_PATH" "$VDM_IFACE" rows u "$TARGET_ROWS"
  echo "CHANGED: rows -> $TARGET_ROWS"
fi
