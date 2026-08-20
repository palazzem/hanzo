# Theming

Relevant to `roles/kde/tasks/darkly.yml`.

## General principle: a theme's own settings often live in its own rc file

Don't assume every visual setting lives in `kwinrc`/`kdeglobals`. A theme
that ships its own decoration/style plugin frequently also ships its own
kcfg schema and its own rc file. Find it via the theme's `.kcfg` file if it
ships one - grep the installed package's files for `*.kcfg` and read the
`<kcfgfile>` tag to get the exact filename.

## Darkly's four components, and exactly where each setting lives

The Darkly theme (AUR package `darkly`, upstream `Bali10050/Darkly`)
provides exactly four components - confirmed from the package's own file
manifest and upstream README, not assumed:

| Component | Setting | Mechanism |
|---|---|---|
| Colors | color scheme | `plasma-apply-colorscheme Darkly` |
| Plasma Style | desktop theme | `plasma-apply-desktoptheme darkly` - **note the internal `Id` is lowercase `darkly`, distinct from the display `Name` "Darkly"** (from the theme's `metadata.json`) |
| Application Style | Qt widget style | `kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly --notify` - no dedicated `plasma-apply-*` tool exists for widget style, this is the correct fallback |
| Window Decorations | kwin decoration plugin | `kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.darkly` + `--key theme Darkly`, then `busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure` (compiled kdecoration plugin, not an Aurorae SVG theme) |

Decoration-specific extras (e.g. `ButtonSize`) are **not** in `kwinrc` at
all - they're in Darkly's own `~/.config/darklyrc`, group `Windeco`,
enum choices `ButtonTiny`/`ButtonSmall`/`ButtonDefault`/`ButtonLarge`/
`ButtonVeryLarge` (source: the theme's own
`kdecoration/darklysettingsdata.kcfg`).

**Not provided by Darkly at all** (confirmed absent, not just
unconfigured): Global Theme/look-and-feel, icon theme, cursor theme, GTK
sync (a separate unrelated project would be needed), Kvantum, splash
screen/SDDM theme.

## Known upstream bug, not fixable via config

Darkly's own decoration settings dialog
(`kdecoration/config/ui/darklyconfigurationui.ui`) hardcodes its top-level
`QVBoxLayout` margin to `0`, overriding the style's normal 10px window
margin (`kstyle/darkly.h` `Metrics::Layout_TopLevelMarginWidth`) - so that
one dialog renders with no padding from its window border. Confirmed
against upstream source, version-matched to the installed release. No
config key or CLI flag controls it; purely cosmetic and scoped to that
single dialog.
