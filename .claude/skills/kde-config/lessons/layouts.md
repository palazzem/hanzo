# Desktop layout (virtual desktops, panels)

Relevant to `roles/kde/files/virtual-desktops.sh` and
`roles/kde/files/panel-layout.js` (applied by the `Apply panel layout`
handler).

## Virtual desktops

`org.kde.KWin.VirtualDesktopManager` at `/VirtualDesktopManager`: `count` is
read-only, use `createDesktop(position: uint, name: string)` to add one and
the writable `rows` property for grid layout. No dedicated CLI tool exists
for this - use the D-Bus interface directly.

## Plasma Scripting API (`org.kde.PlasmaShell.evaluateScript`)

The same mechanism used by Look-and-Feel package layouts and layout
templates under `/usr/share/plasma/layout-templates/`. Reference example
locally at
`/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js`.
Source for the JS API surface: `plasma-workspace/shell/scripting/{panel,containment,applet}.cpp/h`.

- `new Panel` creates a panel; `panel.screen`, `.location` (`"top"`/
  `"bottom"`/`"left"`/`"right"`), `.floating`, `.hiding`
  (`"none"`/`"autohide"`/`"dodgewindows"`), `.height` are writable
  properties.
- `panel.addWidget("plugin.id")` returns a `Widget`.
- Global `panels()` lists existing panels; each has `.remove()`. Calling
  this before building a fresh panel is what makes a layout script
  idempotent and portable - it doesn't depend on any specific existing
  containment/applet ID numbering, unlike hand-editing
  `plasma-org.kde.plasma.desktop-appletsrc` directly.

### Gotcha: `currentConfigGroup` is already rooted at `Configuration`

Use `widget.currentConfigGroup = ["General"]`, **not**
`["Configuration", "General"]` - the latter double-nests into
`[Configuration][Configuration][General]` in the actual config file.
Confirmed by testing. Source: `applet.cpp`
`Applet::setCurrentConfigGroup` starts from `applet->config()`, which is
already the `Configuration` group.

### Gotcha: `evaluateScript` needs a `plasmashell` restart afterward

`widget.writeConfig()` persists to disk immediately and correctly, but a
widget added earlier in the *same* script run can already have initialized
its own in-memory model (e.g. the task manager's pinned-launchers list)
before the config write lands, so the live UI doesn't reflect it until the
shell reloads from disk. Confirmed by testing: pinned apps were missing
from the task manager until `plasmashell --replace &` was run, even though
the correct `launchers` value was already on disk in
`plasma-org.kde.plasma.desktop-appletsrc`. Always restart plasmashell after
`evaluateScript` rather than trusting a config-file read as proof it's
live.

### Gotcha: deploying the layout is the change signal

Because the script removes every existing panel before rebuilding, it must
not run on an unchanged re-run — that would tear down and rebuild the panel
(and restart plasmashell) on every `hanzo` run. In the role, `panel-layout.js`
is deployed with `copy`, and only that file changing notifies the
`Apply panel layout` handler.

## Design note: pager/showdesktop omission

The custom panel layout deliberately omits `org.kde.plasma.pager` (virtual
desktop pager widget) and `org.kde.plasma.showdesktop`. The pager is
redundant once Meta+1..5 shortcuts exist for desktop switching (see
`bind-shortcuts.py`) - worth keeping widget choices and shortcut
choices in sync when updating either.
