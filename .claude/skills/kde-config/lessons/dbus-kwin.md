# KWin D-Bus mechanics

Cross-cutting facts about KWin's live-config D-Bus surface, relevant to
the screen-edge, touchscreen-gesture, Darkly and virtual-keyboard settings
in `roles/kde`. The two reconfigure calls below are the role's
`Reconfigure KWin` and `Reconfigure overview effect` handlers.

## `reconfigure` does not propagate to effects

`org.kde.KWin` `/KWin` `reconfigure` (no args, no reply) is the standard way
to make KWin re-read `kwinrc` live - e.g. after changing the window
decoration. It does **not** propagate to loaded effects' own
`reconfigure()`. For any setting that lives in an effect's own kwinrc group
(`[Effect-<id>]`, e.g. screen-edge bindings), the generic `reconfigure` call
is not enough - confirmed live: a screen-edge change stuck even after
calling it.

What actually works, and what System Settings itself does
(`kwin/src/kcms/screenedges/main.cpp` `KWinScreenEdgesConfig::save()`): call

```
busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects reconfigureEffect s "<effectId>"
```

(e.g. `"overview"`) for each affected effect, in addition to (or instead of)
the generic `reconfigure`.

## `IntList` kcfg entries need real integers, not enum names

Entries like `BorderActivate`/`TouchBorderActivate` on effects are plain
kcfg `IntList` (`QList<int>`), not enum-aware fields - even though the
kcfg's own `<default>` is written as a symbolic name like `ElectricTopLeft`.
That default only resolves correctly because `kconfig_compiler` bakes it in
as a real C++ enum constant at *build* time. A symbolic string written into
the live `.ini` file at runtime goes through plain integer-list parsing,
which doesn't know enum names and silently converts to `0` - no error, just
wrong data.

Confirmed live this cost real time: writing `TouchBorderActivate=ElectricBottom`
silently became `0` (`ElectricTop`), which both failed to bind the bottom
edge *and* collided with a correctly-configured top-edge action, producing
inconsistent behavior that looked like a config bug rather than a
wrong-type value.

Use the real enum ints (`kwin/src/effect/globals.h` `ElectricBorder`):

| Name | Int |
|---|---|
| ElectricTop | 0 |
| ElectricTopRight | 1 |
| ElectricRight | 2 |
| ElectricBottomRight | 3 |
| ElectricBottom | 4 |
| ElectricBottomLeft | 5 |
| ElectricLeft | 6 |
| ElectricTopLeft | 7 |

Don't assume a `Q_ENUM`-registered type gets free name-based
(de)serialization in every context - check whether the *specific* kcfg
field is declared as a plain `IntList` (needs ints) vs `Enum` (has
`<choices>`, generally fine with names) before trusting either form.

When a value is meant to *disable* a binding (empty list), this bug is
invisible - only testing the *enable* path proves a value actually parses.
(The screen-edge enable path was never actually verified working until
this was caught - only its disable path had been tested, and disabling
degenerately works with any invalid value too.)

## Config files can get corrupted group headers from write races

Found a malformed group like `[Containments45Appletsts][26]...` sitting
next to the real `[Containments][45][Applets][26]...` in
`plasma-org.kde.plasma.desktop-appletsrc` after rapid GUI edits - orphaned,
parsed by KConfig as an unrelated dead group, harmless but confusing. When
diffing a config file the user just edited in the GUI, check for this
before trusting a value at face value.
