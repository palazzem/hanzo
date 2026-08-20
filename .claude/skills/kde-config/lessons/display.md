# Display (kscreen-doctor)

Relevant to `display.sh`.

`kscreen-doctor` is KDE's supported CLI for KScreen - use it directly
(`output.<name>.<setting>.<value>`), don't hand-edit config. Exact
setting keys/values are defined in `libkscreen/src/doctor/doctor.cpp`.

## GUI labels don't always match the enum names - verify both

Two traps found where the on-disk/CLI enum name and the GUI label
diverge, and where reading the enum from source was *not* enough to know
the correct mapping - both required either dedicated QML-source confirmation
or the user reading back the live GUI state:

- **Color profile "Built-in" is NOT `sRGB`.** It maps to
  `colorProfileSource=EDID`. The option actually labeled `sRGB` in
  `kscreen-doctor`'s enum is shown as **"None"** in the KCM. Confirmed from
  `kscreen`'s `kcm/ui/ColorProfileSelector.qml`.
- **`autoRotatePolicy`'s Orientation mapping**: the GUI dropdown is
  Manual/Automatic, with a sub-checkbox "only when in tablet mode" that only
  appears when Automatic is selected. Mapping: `never` = Manual,
  `inTabletMode` = Automatic + checkbox checked, `always` = Automatic +
  checkbox unchecked. Got this wrong on the first pass (assumed `never`
  meant "disable the tablet-mode restriction" rather than "disable
  auto-rotate entirely"); only confirmed correct after the user read back
  the live GUI state post-change.

## Where settings actually persist

`kscreen-doctor` scale/color/vrr/auto-rotate settings persist to
`~/.config/kwinoutputconfig.json` (keyed by the display's EDID hash - this
is what lets it survive reboot/relogin and match a given panel across
reconnects), **not** to `~/.local/share/kscreen/control/*` - that directory
only holds `vrrpolicy` and a per-output id mapping, not the full settings
set.
