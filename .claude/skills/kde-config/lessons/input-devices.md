# Input devices

Relevant to `touchpad.sh` and `virtual-keyboard.sh`.

## Touchpad

Devices are discovered generically via `org.kde.KWin.InputDeviceManager`'s
`devicesSysNames` property (list of `eventN` names), then each device's
object at `/org/kde/KWin/InputDevice/<sysName>` is checked for a boolean
`touchpad` property to identify which one(s) are touchpads - don't hardcode
a device name or vendor/product id.

Settings (`naturalScroll`, `tapToClick`, ...) are plain writable D-Bus
properties on `org.kde.KWin.InputDevice`, applied live. They persist to
`~/.config/kcminputrc` under a per-device group keyed by the device's
hardware identity: `[Libinput][<vendorId decimal>][<productId decimal>][<device name>]`.

## Virtual keyboard

`kwinrc [Wayland] InputMethod=<absolute path to a .desktop file>` (e.g.
`/usr/share/applications/org.kde.plasma.keyboard.desktop` for Plasma
Keyboard). KWin reads that file's `Exec=` line and launches it as the input
method server.

Source: `kwin/src/main_wayland.cpp`
`ApplicationWayland::refreshSettings()` (triggered by a `KConfigWatcher` on
`kwinrc`, set up once in `startSession()`) and
`kwin/src/inputmethod.cpp InputMethod::setInputMethodCommand()`. A virtual
keyboard implementation must declare `X-KDE-Wayland-VirtualKeyboard=true` in
its `.desktop` file to be a valid candidate (`find /usr/share/applications
-iname '*keyboard*'` to discover installed ones).

Live-verify via `busctl --user get-property org.kde.KWin /VirtualKeyboard
org.kde.kwin.VirtualKeyboard available` (should read `true`) - the process
itself shows up as `plasma-keyboard` in `pgrep`. `available` only means KWin
holds a non-empty `Exec` command (`InputMethod::isAvailable()`), not that
the process is running.

### Gotcha: an unchanged write sends no notification

KWin only learns of the key through a `KConfigWatcher` on the
`org.kde.kconfig.notify.ConfigChanged` D-Bus signal, and KConfig only emits
it for entries whose value actually changed (`KEntry::operator==` ignores
the dirty/notify flags on purpose). Observed live: the correct key already
in `kwinrc`, `available` `false`, and a plain write of the same value
changed nothing.

Fix: always write an empty value first, then the target, each with
`kwriteconfig6 --notify` - the transition is what makes KConfig notify.
This also covers "None" in the GUI, which removes the key entirely.

### Gotcha: `kwriteconfig6 --notify` can lose the signal

`kwriteconfig6` hands the D-Bus signal to Qt's D-Bus worker thread and
exits without flushing, so on a busy system (mid-install) the process can
quit before the signal is written and KWin is never told. `kwinrc` is
still correct and KWin reads it at the next session start. This is why
`virtual-keyboard.sh` does not verify `available` after applying: the
task-level `available` guard re-applies on the next run instead of the play
failing on a lost notification. The System Settings KCM never hits this -
it is a long-lived process.
