# Input devices

Relevant to `touchpad.sh` and `virtual-keyboard.sh`.

## Touchpad

Devices are discovered generically via `org.kde.KWin.InputDeviceManager`'s
`devicesSysNames` property (list of `eventN` names), then each device's
object at `/org/kde/KWin/InputDevice/<sysName>` is checked for a boolean
`touchpad` property to identify which one(s) are touchpads - don't hardcode
a device name or vendor/product id.

Settings (`naturalScroll`, `tapToClick`, ...) are plain writable D-Bus
properties on `org.kde.KWin.InputDevice`, applied live.

The "Right-click by" radio maps to two booleans, `clickMethodAreas`
(bottom-right corner) and `clickMethodClickfinger` (anywhere with two
fingers). libinput has a single click method, so writing either one flips
both: `Device::setClickMethod()` in `kwin/src/backends/libinput/device.cpp`
switches to the other method when a property is set to `false`. Writing
`clickMethodClickfinger` alone is enough. They persist to
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
itself shows up as `plasma-keyboard` in `pgrep`.

### Gotcha: equality guard breaks naive idempotency

`setInputMethodCommand()` no-ops if the new value equals the *current
in-memory* value - even if that value has drifted from what's actually on
disk. Observed live: `available` stayed `false` and the process wasn't
running despite the correct key already being in `kwinrc`.

Fix: always write an empty value first (forcing a real transition), then
the target value, each with `kwriteconfig6 --notify`. This is what makes
`virtual-keyboard.sh` reliably idempotent even after selecting "None" in the
GUI, which removes the key entirely.
