# Touchscreen gestures

Relevant to the touchscreen-gesture tasks in `roles/kde/tasks/main.yml`
(`kde_overview_touch_border_activate` and `kde_launcher_touch_edge` in
`defaults/main.yml`). See also `lessons/screen-edges.md`
for the mouse equivalent, and `lessons/dbus-kwin.md` for the
`reconfigureEffect` and `IntList`-integer requirements referenced below.

## Three lookalike gesture subsystems - easy to conflate, can silently race

1. **Mouse "Screen Edges"** (hover a corner/edge with the mouse) -
   `kwinrc [ElectricBorders]` for built-in actions, `[Effect-<id>]
   BorderActivate` for effects. See `lessons/screen-edges.md`.
2. **"Touchscreen Gesture"** (drag in from a touchscreen edge) - the *same*
   built-in-action mechanism but group `[TouchEdges]` instead (keys
   `Top`/`Right`/`Bottom`/`Left`, same string values as `[ElectricBorders]`:
   `ApplicationLauncher`, `ShowDesktop`, `LockScreen`, `KRunner`,
   `ActivityManager`, `None` - source: `kwin/src/screenedge.cpp`
   `electricBorderAction()`), and `[Effect-<id>] TouchBorderActivate`
   instead of `BorderActivate` for effects (same `IntList`-of-integers
   requirement).
3. **Hardcoded N-finger anywhere-swipe gestures** - see below, not
   configurable at all.

All three can be bound to the same logical action (e.g. Overview)
independently, and will silently race each other if misconfigured. This is
exactly what happened live: a wrong-type write to `TouchBorderActivate`
(subsystem 2, effect-owned touch edge) silently parsed as `0`/`ElectricTop`
and collided with a correctly-configured `[TouchEdges] Top=ApplicationLauncher`
(subsystem 2, built-in touch edge) on the *same* physical edge, producing
inconsistent results that looked like a deeper bug.

Applying each half of subsystem 2 needs a different D-Bus call: effect
touch borders need `reconfigureEffect`, built-in touch edges need the
generic `reconfigure` - see `lessons/dbus-kwin.md`.

## Hardcoded touchpad/touchscreen swipe gestures are NOT user-configurable

Built-in effects like Overview/Grid View register their N-finger swipe
gestures (finger count + direction) directly in C++
(`effects->registerTouchpadSwipeShortcut(...)` /
`addTouchscreenSwipeGesture(...)` in
`kwin/src/effect/effecttogglablestate.cpp`, called with hardcoded values
from each effect's constructor - e.g. `overvieweffect.cpp`: Overview =
4-finger touchpad swipe up / 3-finger touchscreen swipe up, Grid View =
4-finger touchpad swipe down / 3-finger touchscreen swipe down).

This is **not** read from any config key - checked the effect's own
`.kcfg` (only has screen-corner settings, no gesture keys) and
`kglobalaccel` (zero gesture support in that framework at all, confirmed by
searching its whole source tree). There is no supported way to rebind these
to a different finger count via config or D-Bus; only the screen-edge/
touch-edge triggers and keyboard shortcuts for the same actions are
configurable.

If a user asks for a specific finger count that doesn't match the hardcoded
default, say so plainly rather than attempting a fake config-based fix -
the real options are living with the hardcoded default, patching/
recompiling KWin, or a third-party libinput-based gesture daemon that
triggers the action's keyboard shortcut externally (a workaround outside
KDE's own APIs, not something to build silently into a provisioning
script without the user choosing it explicitly).
