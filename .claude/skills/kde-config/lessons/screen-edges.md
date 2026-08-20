# Screen Edges (mouse)

Relevant to the screen-edge tasks in `roles/kde/tasks/main.yml`. See also
`lessons/touchscreen.md` for the
touch-edge equivalent and how the two subsystems can conflict, and
`lessons/dbus-kwin.md` for the `reconfigureEffect` and `IntList`-integer
requirements referenced below (both apply here).

Mouse screen-edge (hot corner) actions split into two mechanisms depending
on what's bound:

- **Built-in actions** (Show Desktop, Lock Screen, KRunner, Activity
  Manager, Application Launcher): `kwinrc [ElectricBorders]`, keys
  `TopLeft`/`Top`/`TopRight`/`Right`/`BottomRight`/`Bottom`/`BottomLeft`/`Left`,
  plain case-insensitive strings (source: `kwin/src/screenedge.cpp`
  `electricBorderAction()`). Applying it live uses the generic
  `org.kde.KWin /KWin org.kde.KWin reconfigure`.
- **Effect-owned actions** (e.g. Overview): `kwinrc [Effect-<id>]`, key
  `BorderActivate`, an `IntList` of `ElectricBorder` enum integers (see
  `lessons/dbus-kwin.md` for the exact integer values and why symbolic
  names silently break). Applying it live requires
  `org.kde.kwin.Effects./Effects.reconfigureEffect("<effectId>")`, not the
  generic `reconfigure`.

The role only handles the effect-owned case (the `overview` effect). The
enable path (writing a real border value, not just clearing to empty) was
not actually verified working until the `IntList` integer-vs-string bug
was found and fixed - disabling degenerately "works" with an invalid value
too, so always test the *enable* direction when changing this.

In the role this is an `ini_file` task on `kwinrc [Effect-overview]
BorderActivate` that notifies the `Reconfigure overview effect` handler.
The default is an empty string (no hot corner); `kde_overview_border_activate`
in `defaults/main.yml` takes an `ElectricBorder` integer to enable one.
