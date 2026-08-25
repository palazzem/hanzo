#!/usr/bin/env python3
"""Add global shortcut alternatives through the kglobalaccel D-Bus API.

BINDINGS is a JSON array of {"component", "action", "key"} objects:
`component` is a kglobalaccel component unique name, `action` an action
unique name inside it, and `key` a `Modifier+...+Key` string built from
Meta, Ctrl, Shift, Alt and a single ASCII letter or digit. Each action
keeps its existing alternatives; setForeignShortcutKeys is called only
for actions still missing their key, printing one CHANGED line per
rebound action, so re-runs are no-ops. An unknown component, action,
modifier or key fails the run.
"""
import json
import os
import subprocess
import sys

MODIFIERS = {
    "Meta": 0x10000000,
    "Ctrl": 0x04000000,
    "Shift": 0x02000000,
    "Alt": 0x08000000,
}


def query(path, interface, method, *args):
    result = subprocess.run(
        ["busctl", "--user", "--json=short", "call", "org.kde.kglobalaccel",
         path, interface, method, *args],
        capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"ERROR: {method} failed: {result.stderr.strip()}")
    return json.loads(result.stdout)["data"]


def parse_key(spec):
    *modifiers, key = spec.split("+")
    if len(key) != 1 or not key.isascii() or not key.isalnum():
        sys.exit(f"ERROR: unsupported key '{key}' in '{spec}'")
    code = ord(key.upper())
    for modifier in modifiers:
        if modifier not in MODIFIERS:
            sys.exit(f"ERROR: unknown modifier '{modifier}' in '{spec}'")
        code |= MODIFIERS[modifier]
    return code


by_component = {}
for binding in json.loads(os.environ["BINDINGS"]):
    by_component.setdefault(binding["component"], []).append(binding)

for component, bindings in by_component.items():
    path = query("/kglobalaccel", "org.kde.KGlobalAccel", "getComponent", "s", component)[0]
    rows = {r[0]: r for r in query(path, "org.kde.kglobalaccel.Component", "allShortcutInfos")[0]}

    for binding in bindings:
        row = rows.get(binding["action"])
        if row is None:
            sys.exit(f"ERROR: action '{binding['action']}' not found in component '{component}'")

        key = parse_key(binding["key"])
        # Active keys come back flat, one int per alternative; 0 marks an unbound action.
        keys = [k for k in row[6] if k]
        if key in keys:
            continue
        keys.append(key)

        args = ["busctl", "--user", "call", "org.kde.kglobalaccel", "/kglobalaccel",
                "org.kde.KGlobalAccel", "setForeignShortcutKeys", "asa(ai)",
                "4", row[2], row[0], row[3], row[1], str(len(keys))]
        # kglobalaccel reads exactly four ints per key; a shorter array crashes kwin_wayland.
        for k in keys:
            args += ["4", str(k), "0", "0", "0"]

        subprocess.run(args, check=True)
        print(f"CHANGED: {component}/{binding['action']} += {binding['key']}")
