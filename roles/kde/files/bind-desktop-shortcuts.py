#!/usr/bin/env python3
"""Bind Meta+1..N to "Switch to Desktop 1..N" via kglobalaccel D-Bus.

Keeps any pre-existing shortcut alternatives (e.g. the default Ctrl+F1)
intact, only calls setForeignShortcutKeys for actions still missing their
Meta+N key, and prints one CHANGED line per rebound action — safe to
re-run.

Each key alternative MUST be marshalled as a fixed 4-int array
[key, 0, 0, 0]: kglobalshortcutinfo_dbus.cpp reads exactly 4 ints with no
length check, and a shorter array desyncs the D-Bus stream parser and
crashes kwin_wayland (see lessons/shortcuts.md).

Config: TARGET_DESKTOPS (default: 5).
"""
import json
import os
import subprocess

META = 0x10000000  # Qt::MetaModifier
KEY1 = 0x31        # Qt::Key_1
N = int(os.environ.get("TARGET_DESKTOPS", "5"))


def get_shortcuts():
    out = subprocess.run(
        ["busctl", "--user", "--json=short", "call", "org.kde.kglobalaccel",
         "/component/kwin", "org.kde.kglobalaccel.Component", "allShortcutInfos"],
        capture_output=True, text=True, check=True).stdout
    return json.loads(out)["data"][0]


by_name = {r[0]: r for r in get_shortcuts()}

for n in range(1, N + 1):
    action = f"Switch to Desktop {n}"
    row = by_name.get(action)
    if row is None:
        print(f"WARNING: action '{action}' not found, skipping")
        continue

    existing_keys = list(row[6])  # active keys, flat list of ints (one per alternative)
    meta_key = META | (KEY1 + (n - 1))
    if meta_key in existing_keys:
        continue

    alternatives = existing_keys + [meta_key]
    action_id = ["kwin", action, "System Settings", action]

    args = ["busctl", "--user", "call", "org.kde.kglobalaccel", "/kglobalaccel",
            "org.kde.KGlobalAccel", "setForeignShortcutKeys", "asa(ai)", "4", *action_id,
            str(len(alternatives))]
    for k in alternatives:
        args += ["4", str(k), "0", "0", "0"]

    subprocess.run(args, check=True)
    print(f"CHANGED: {action} -> {alternatives}")
