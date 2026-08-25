# Global shortcuts (kglobalaccel)

Relevant to `roles/kde/files/bind-shortcuts.py`.

## Live path vs config file

On Plasma 6 Wayland `org.kde.kglobalaccel` is owned by `kwin_wayland`
itself (`busctl --user status org.kde.kglobalaccel` reports
`Comm=kwin_wayland`; the `kglobalacceld` package ships
`libKGlobalAccelD.so`, loaded in-process). That is why a marshalling
error crashes the compositor rather than a helper daemon.

`plasma/kglobalacceld`'s `GlobalShortcutsRegistry` has no
`KConfigWatcher`: editing `~/.config/kglobalshortcutsrc` changes nothing
until the next login, and `Component::writeSettings` /
`KServiceActionComponent::writeSettings` delete and rewrite each loaded
component's group from memory on every scheduled write, so a hand-written
entry for a live component can be clobbered before login ever happens.
`setForeignShortcutKeys` is the live path: it replaces the action's key
set (`setShortcutKeys` with `NoAutoloading`) and the daemon then persists
on its own to `~/.config/kglobalshortcutsrc` (service components write
only keys that differ from the default) and
`~/.local/state/kglobalshortcutsstaterc` (serials). Confirmed live: after
the call, `[services][org.kde.spectacle.desktop]` gained
`CurrentMonitorScreenShot=Meta+Shift+5` within a minute.

The one legitimate config-file write is a `[services][<file>.desktop]`
group for a launcher kglobalaccel has never seen (the Copilot key):
`loadSettings` creates the component from that group at daemon start, and
`setForeignShortcutKeys` cannot target a component that does not exist.

## Shift+digit and Shift+symbol never match: bind the shifted character

Confirmed live: `Meta+Shift+4` and `Meta+Shift+5` set through
`setForeignShortcutKeys` were accepted, persisted as such, and never
fired. The modifier was not the problem: `Meta` is the Windows/Super key
(see the constants table below), and the same `Meta` drives the working
Meta+1..5 desktop shortcuts; the key half of the combination was.
`Xkb::modifiersRelevantForGlobalShortcuts` (`plasma/kwin`,
`src/xkb.cpp`) subtracts the modifiers xkb *consumed* to produce the
keysym; Shift is consumed turning `4` into `$`, and the exception that
keeps Shift anyway (BUG 370341) applies only when the resulting key is a
letter. The key itself is `QXkbCommon::keysymToQtKey` of the shifted
keysym, so KWin asks kglobalaccel for `Meta+$` (`0x10000024`), never
`Meta+Shift+4`. KDE's own recorder (`frameworks/kguiaddons`,
`kkeysequencerecorder.cpp`, `isShiftAsModifierAllowed`) stores the same
thing: Shift is dropped for anything that is not a letter, an F-key or
one of its listed special keys. Bind the character Shift produces on the
layout in use (`Meta+$` and `Meta+%` on US) and expect that to be
layout-dependent. Printable ASCII keys carry their code point as the
`Qt::Key` value (`Key_Dollar = 0x24`, `Key_Percent = 0x25`).

## Service components (launcher actions)

`.desktop` launchers are components named after the file
(`org.kde.spectacle.desktop`); the D-Bus path is the escaped form
(`/component/org_kde_spectacle_desktop`) and
`org.kde.KGlobalAccel.getComponent(s)` resolves it, failing cleanly with
`The component '…' doesn't exist.` for an unknown name. Actions are the
`[Desktop Action <name>]` names from
`/usr/share/kglobalaccel/<file>.desktop` (`RectangularRegionScreenShot`,
`CurrentMonitorScreenShot`, …) plus `_launch`. `findAction` matches on
the component and action unique names only; the two friendly-name slots
of `actionId` are length-checked, never compared.

`allShortcutInfos` reports active keys as a flat int list, one entry per
alternative (`key[0].toCombined()`), and an unbound action as `[0]`.
`Utils::normalizeSequences` drops empty sequences on write, so a leading
zero must be filtered before re-sending the list.

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
| `Key_0`..`Key_9` | `0x30`..`0x39` (ASCII) |
| `Key_A`..`Key_Z` | `0x41`..`0x5a` (ASCII uppercase) |
| `MetaModifier` | `0x10000000` |
| `ControlModifier` | `0x04000000` |
| `ShiftModifier` | `0x02000000` |
| `AltModifier` | `0x08000000` |

`MetaModifier` is the Windows/Super key: KWin resolves it from xkb's
`Mod4` (`XKB_MOD_NAME_LOGO`, `plasma/kwin` `src/xkb.cpp`,
`Xkb::updateKeymap`), and KDE spells it `Meta` in `kglobalshortcutsrc`.

## Testing tip

Before calling `setForeignShortcutKeys` against `kwin`'s own component,
validate the exact argument encoding against a lower-blast-radius component
first (e.g. `kmix`) - a crash there is much cheaper to recover from than a
compositor crash.
