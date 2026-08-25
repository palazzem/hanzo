---
name: kde-config
description: Add or change a KDE Plasma 6 setting in Hanzo's kde role. Use when a new Plasma setting must be provisioned, or an existing one fixed or extended, without re-deriving the underlying D-Bus/config knowledge from scratch.
---

# KDE Plasma 6 configuration in Hanzo

`roles/kde` reproduces specific KDE System Settings changes as Ansible
tasks. Every setting applies **live against the running Plasma session**
during a `hanzo` run — no logout, no login-time deferral. Each was
verified working against a real system, not by writing config and
assuming it took effect.

This file is the operating manual: the method for any new setting, the
shapes a task can take, and where the previously-discovered facts live.
Per-subsystem knowledge (exact keys, enum values, D-Bus quirks, bugs
found) lives in `lessons/*.md`, one file per topic — read the relevant
one before touching a task, rather than re-deriving it.

## Method for any new setting (follow in order)

1. **Check `lessons/` first.** If the setting touches a subsystem already
   covered there (see the table below), read that file before doing
   anything else — it may already have the exact key, enum, or D-Bus call
   you need, plus a gotcha that would otherwise cost real time to
   rediscover.
2. **Look for an official CLI first.** Check `compgen -c | grep plasma-apply`
   and for a dedicated tool (`kscreen-doctor`, `plasma-apply-colorscheme`,
   `plasma-apply-desktoptheme`, `plasma-apply-cursortheme`,
   `plasma-apply-lookandfeel`/`lookandfeeltool`, `kvantummanager`,
   `kde-gtk-config`). These are documented, stable, and safe — always prefer
   them over anything below.
3. **If no CLI tool exists, find the live D-Bus API.** Most KWin/Plasma
   settings that need to apply without logout are exposed on the session
   bus. Discover with:
   ```
   busctl --user tree org.kde.KWin            # or org.kde.plasmashell, org.kde.kglobalaccel
   busctl --user introspect org.kde.KWin /some/path org.kde.SomeInterface
   ```
   Reading/writing a property: `busctl --user get-property` /
   `busctl --user set-property SERVICE PATH IFACE PROP TYPE VALUE`.
   Calling a method: `busctl --user call SERVICE PATH IFACE METHOD SIG ARGS...`.
4. **Never guess a key name or enum value — confirm it from a real source.**
   The reliable way: make the change once in the GUI, diff the config file
   before/after (`diff -u <snapshot> ~/.config/<file>`), and use the exact
   key/value the diff shows. For enum values that aren't self-explanatory
   (e.g. numeric `location=3`), find the C++ enum definition in the relevant
   KDE source repo (see "Finding KDE source" below) rather than guessing
   what the number means.
   **Reading the enum from source is not enough to know which GUI label it
   corresponds to, or whether the field even accepts names at all** — see
   `lessons/display.md` and `lessons/dbus-kwin.md` for two confirmed traps.
   When source doesn't make a label mapping explicit, confirm it by setting
   the value and asking the user to read back what the GUI shows, rather
   than asserting the mapping. When a field's kcfg type isn't explicitly
   `Enum`, don't assume it accepts symbolic names — check.
5. **For any D-Bus method taking a struct or nested array, read the
   marshalling code before calling it.** Don't hand-encode complex types
   from the introspected signature alone — see `lessons/shortcuts.md` for
   what happens when this goes wrong. Getting a fixed-vs-variable-length
   array wrong can crash `kwin_wayland`/`plasmashell`, not just fail
   cleanly.
6. **Test on the lowest-blast-radius target first** when a D-Bus call is
   unfamiliar or the encoding is uncertain (e.g. validate against `kmix`'s
   component before calling the same method against `kwin`'s).
7. **Verify, don't assume:**
   - After any KWin/plasmashell D-Bus call: `pgrep -a kwin_wayland` /
     `pgrep -a plasmashell` to confirm the process didn't crash/respawn.
   - Re-read the config file and/or the D-Bus property back to confirm the
     value actually landed (`kreadconfig6`, `busctl get-property`,
     `kscreen-doctor -o`, etc.) — a config file write and a *live, working*
     setting are not always the same thing (see `lessons/layouts.md`'s
     `evaluateScript` gotcha for a concrete case where this bit us).
   - When testing a value meant to *disable* something, also separately
     test *enabling* it — a disable path can silently "work" even when the
     underlying value is wrong (see `lessons/dbus-kwin.md`).
8. **Land it as a task in `roles/kde`** using one of the three shapes
   below. Keep any script's header comment to *what it does and its end
   state* only — no justification, no source citations, no gotcha
   narration. That material belongs in the matching `lessons/*.md` file
   instead (add to it, or create a new one, if the setting doesn't fit an
   existing topic — then add a row to the table below).

## The three task shapes

Pick by what the setting actually needs. Prefer the first that fits.

**1. Config key + reload handler** — the setting lives in a config file
and a D-Bus call makes KDE re-read it. `community.general.ini_file`
writes the key (real change detection, visible under `--check`) and
notifies a handler that makes the call:

```yaml
- name: Set Overview mouse screen-edge binding
  community.general.ini_file:
    path: "{{ ansible_facts.env.HOME }}/.config/kwinrc"
    section: Effect-overview
    option: BorderActivate
    value: "{{ kde_overview_border_activate }}"
    no_extra_spaces: true
    mode: "0644"
  become: false
  notify: Reconfigure overview effect
```

Existing handlers: `Reconfigure KWin` (generic `kwinrc` reload),
`Reconfigure overview effect` (any `[Effect-<id>]` group — the generic
reconfigure does **not** reach effects), `Apply panel layout`.

**2. Guarded command** — a CLI tool applies it, and a `kreadconfig6` read
supplies the change signal. Read tasks need `changed_when: false` and
`check_mode: false` so the guard still evaluates during `--check`:

```yaml
- name: Read current color scheme
  ansible.builtin.command:
    cmd: kreadconfig6 --file kdeglobals --group General --key ColorScheme
  register: kde_darkly_colorscheme
  changed_when: false
  check_mode: false
  become: false

- name: Apply Darkly color scheme
  ansible.builtin.command:
    cmd: plasma-apply-colorscheme Darkly
  when: kde_darkly_colorscheme.stdout != 'Darkly'
  changed_when: true
  become: false
```

**3. Script in `files/`** — for device or output discovery, or D-Bus
marshalling too intricate for YAML. Run via `ansible.builtin.script`,
parameterized with `environment:`. The script prints `CHANGED` only when
it actually wrote something, and the task keys off that:

```yaml
- name: Configure touchpad scrolling and tap-to-click
  ansible.builtin.script:
    cmd: touchpad.sh
  environment:
    NATURAL_SCROLL: "{{ kde_touchpad_natural_scroll }}"
  register: kde_touchpad_result
  changed_when: "'CHANGED' in kde_touchpad_result.stdout"
  become: false
```

This is the escape hatch (`CLAUDE.md` rule 1) — justified only when no
module and no simple guarded command can do it. When a tool is a
declarative apply with no change signal at all (`kscreen-doctor`), mark
the task `changed_when: false` and say why in a comment; do not invent a
comparison layer.

## Repository rules that apply here

- **CI cannot verify any of this.** The test container has no Plasma, so
  `host_has_kde` is false and the whole role is skipped; `--check` and
  `--ci` prove syntax and lint, nothing more. Real verification is the
  user running `hanzo` on the machine — ask for it, and ask for a second
  run to confirm the tasks report no change.
- **Variables:** tunable values go in `roles/kde/defaults/main.yml` with
  the `kde_` prefix; values a user config must not override go in
  `vars/main.yml`. Registered variables must also carry the `kde_` prefix
  (ansible-lint `var-naming[no-role-prefix]`).
- **Every task declares `become:` explicitly.** In this role that is
  `become: false` everywhere — Plasma config is user-space, and running
  it as root would write to the wrong home and touch the wrong session
  bus.
- **Every command/shell/script task needs `changed_when:`** (or
  `creates:`), so ansible-lint's `no-changed-when` passes without
  disabling it.
- **Nested ini groups:** `ini_file` has no nested-group syntax. A group
  like `[services][x.desktop]` is written by embedding `]`+`[` in
  `section:` — see the Copilot-key task.
- **Managed files carry a header.** Any file the role writes whole
  (`copy` with `content:`, templates, deployed scripts) opens with
  `# Managed by Hanzo. Do not edit manually.` in the target format's
  comment syntax. Files edited key-by-key with `ini_file` do not — KDE
  rewrites them.
- **Darkly is AUR-only**, installed by `bin/hanzo-aur` via Shelly before
  the playbook runs. Its tasks stay gated on the package being present,
  because declining a PKGBUILD review is a legitimate outcome.

## Finding KDE source quickly

`invent.kde.org`'s web tree/file views are JS-rendered and return an empty
shell to `WebFetch` — use the GitLab REST API instead, which returns plain
JSON/text and works reliably:

```bash
# list a directory
curl -s "https://invent.kde.org/api/v4/projects/<namespace>%2F<repo>/repository/tree?path=<path>&ref=master&per_page=100"

# read a file
curl -s "https://invent.kde.org/<namespace>/<repo>/-/raw/master/<path>"
```

Repos used so far:

- `plasma/plasma-desktop` — touchpad and mouse KCMs
- `plasma/kwin` — compositor, libinput backend, `InputDevice` and
  `VirtualDesktopManager` D-Bus interfaces, effects, screen edges
- `frameworks/kglobalaccel` — global shortcut marshalling
- `plasma/libkscreen` — `kscreen-doctor`
- `plasma/plasma-workspace` — `plasmashell`, the Scripting API

Third-party theme source (e.g. Darkly) is on GitHub — the same raw-file
trick applies (`raw.githubusercontent.com/<owner>/<repo>/main/<path>`), and
`api.github.com/repos/<owner>/<repo>/git/trees/main?recursive=1` lists the
whole tree in one call.

Local system headers are also a direct source of truth — e.g. Qt's exact key
codes and modifier bitmasks come from `/usr/include/qt6/QtCore/qnamespace.h`,
not from memory.

## Where each setting lives, and its lesson file

| Setting | Implementation | Lesson file(s) |
|---|---|---|
| Touchpad | `files/touchpad.sh` | `lessons/input-devices.md` |
| Virtual desktops | `files/virtual-desktops.sh` | `lessons/layouts.md` |
| Global shortcuts (Meta+N desktops, Spectacle captures) | `files/bind-shortcuts.py` | `lessons/shortcuts.md` |
| Display | `files/display.sh` | `lessons/display.md` |
| Virtual keyboard | `files/virtual-keyboard.sh` | `lessons/input-devices.md` |
| Screen edges | `tasks/main.yml` (ini_file + handler) | `lessons/screen-edges.md`, `lessons/dbus-kwin.md` |
| Touchscreen gestures | `tasks/main.yml` (ini_file + handler) | `lessons/touchscreen.md`, `lessons/dbus-kwin.md` |
| Panel layout | `files/panel-layout.js` + `Apply panel layout` handler | `lessons/layouts.md` |
| Darkly theme | `tasks/darkly.yml` | `lessons/theming.md` |
| Copilot key (F23) binding | `tasks/main.yml` | — |
| PowerDevil sleep mode | `tasks/main.yml` | — |
