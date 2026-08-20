# Global shortcuts (kglobalaccel)

Relevant to `roles/kde/files/bind-desktop-shortcuts.py`.

## Crash risk: `setForeignShortcutKeys` needs fixed 4-int arrays

`org.kde.kglobalaccel` `/kglobalaccel` `org.kde.KGlobalAccel`
`setForeignShortcutKeys(actionId: as, keys: a(ai))` requires each key
alternative to be marshalled as a **fixed 4-int array** `[key, 0, 0, 0]`
(zero-padded, not just the key on its own).

Source: `frameworks/kglobalaccel/src/kglobalshortcutinfo_dbus.cpp`'s
`operator>>(QDBusArgument&, QKeySequence&)` unconditionally reads exactly 4
ints with no length check. A shorter array desyncs the D-Bus stream parser
and **crashes `kwin_wayland`** - confirmed live: it did, mid-session, and
`kwin_wayland_wrapper` had to auto-respawn it. This is a real crash risk,
not just a clean failure - never omit the zero padding.

`actionId` is `[componentUniqueName, actionUniqueName,
componentFriendlyName, actionFriendlyName]` (confirmed via
`org.kde.KGlobalAccel.action(int)`).

## Qt key/modifier constants

From `/usr/include/qt6/QtCore/qnamespace.h` (verify against the actual
installed headers, don't trust from memory):

| Constant | Value |
|---|---|
| `Key_1`..`Key_5` | `0x31`..`0x35` |
| `MetaModifier` | `0x10000000` |
| `ControlModifier` | `0x04000000` |
| `ShiftModifier` | `0x02000000` |
| `AltModifier` | `0x08000000` |

## Testing tip

Before calling `setForeignShortcutKeys` against `kwin`'s own component,
validate the exact argument encoding against a lower-blast-radius component
first (e.g. `kmix`) - a crash there is much cheaper to recover from than a
compositor crash.
