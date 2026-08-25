# KWin window rules

Facts behind the `Window rules` tasks in `roles/kde` — how `kwinrulesrc`
is structured, which integers the rule keys take, and how KWin is told to
reload. Confirmed against Plasma 6.7.4 and the `plasma/kwin` sources
named below.

## File layout

`~/.config/kwinrulesrc` is one `[General]` group plus one group per rule:

```ini
[General]
count=1
rules=a75969c9-202a-41ab-a724-bec2bb07148a

[a75969c9-202a-41ab-a724-bec2bb07148a]
Description=Window settings for com.mitchellh.ghostty
size=1600,1001
sizerule=3
types=1
wmclass=ghostty com.mitchellh.ghostty
wmclasscomplete=true
wmclassmatch=1
```

- `rules` is the ordered list of rule group names
  (`src/rulebooksettingsbase.kcfg`, key `rules`, type `StringList`,
  comma-separated). `RuleBookSettings::usrRead()`
  (`src/rulebooksettings.cpp`) loads exactly the groups it names.
- **Group names are free-form.** The KCM mints UUIDs
  (`RuleBookSettings::generateGroupName()`), but nothing checks the
  shape — legacy files used `[1]`, `[2]`, … A descriptive, stable name
  such as `hanzo-ghostty` is a legitimate group and survives KCM edits:
  the KCM keeps existing group names and only generates new ones for
  rules created in the UI.
- `count` is labelled "legacy" in the kcfg: `usrRead()` consults it only
  when `rules` is empty (it then synthesises `1..count`). The KCM still
  rewrites it on every save, so keep it equal to the list length to
  avoid a spurious "unsaved changes" state when the KCM next opens.
- Rules are evaluated in list order; when several match, the first one
  that sets a property wins for that property.

## Enum integers (never symbolic names)

All from `src/rules.h`:

| Key | Enum | Values |
|---|---|---|
| `wmclassmatch`, `titlematch`, `windowrolematch`, … | `Rules::StringMatch` | 0 Unimportant, 1 Exact, 2 Substring, 3 RegExp |
| `sizerule`, `positionrule`, … (`*rule` for set-type properties) | `Rules::SetRule` (anonymous base enum) | 0 Unused, 1 DontAffect, 2 Force, 3 Apply ("Apply initially"), 4 Remember, 5 ApplyNow, 6 ForceTemporarily |
| `types` | `NET::WindowTypeMask` bitmask (`/usr/include/KF6/KWindowSystem/netwm_def.h`) | 1 Normal, default `AllTypesMask` (all bits) |
| `wmclasscomplete` | Bool | `true` = match whole window class |

`size` is a `QSize` serialised as `width,height`.

## "Detect Window Properties" leaves inert keys behind

The KCM's property detector copies the window's title into `title=` even
when the user never enables title matching. Without a `titlematch`
(default `UnimportantMatch`), `Rules::matchTitle()` (`src/rules.cpp`)
returns true unconditionally, so the key is dead weight. When reproducing
a GUI-made rule, carry only the keys whose `*match`/`*rule` companion is
set — the snapshot above had `title=~ - fish` for exactly this reason.

## Reload path

System Settings' rules KCM does **not** call `reconfigure` after saving:
`KCMKWinRules::save()` (`src/kcms/rules/kcmrules.cpp`) broadcasts the
D-Bus signal `reloadConfig` on `/KWin` `org.kde.KWin`. KWin connects that
signal to `Workspace::slotReloadConfig()`, which calls
`Workspace::reconfigure()` — the same slot the `reconfigure` method
reaches (`src/dbusinterface.cpp`). Both land in
`Workspace::slotReconfigure()` (`src/workspace.cpp`), which does
`m_rulebook->load()` and re-evaluates rules on every open window. So the
role's existing `Reconfigure KWin` handler is sufficient; no rules-specific
call exists.

KWin does not watch `kwinrulesrc` for changes made by non-KConfig writers
such as `ini_file`, so the handler is required, not a nicety.

An `Apply` (3) rule only affects windows mapped after the reload — an
already-open window keeps its size. Verify by opening a *new* window of
the matched class.

## Reading the list back

`kreadconfig6 --file kwinrulesrc --group General --key rules` prints the
raw comma-separated list, or an empty line with exit 0 when the file or
key is absent — safe to use as the merge input on a fresh machine.
