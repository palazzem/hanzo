# Desktop Session (ksmserver)

Relevant to the session-restore task in `roles/kde/tasks/main.yml`
(`kde_session_login_mode` in `defaults/main.yml`). Covers System Settings
> Session > Desktop Session, whose KCM is `kcm_smserver` (shipped by
`plasma-desktop`, source `plasma/plasma-desktop` `kcms/ksmserver/`), while
the daemon it configures is `ksmserver` (`plasma/plasma-workspace`
`ksmserver/`).

## The whole KCM is one kcfg on `ksmserverrc [General]`

`kcms/ksmserver/smserversettings.kcfg` (`kcfgfile name="ksmserverrc"`,
group `General`) holds every control on that page:

| GUI control | Key | Type | Values |
|---|---|---|---|
| Ask for confirmation | `confirmLogout` | Bool | `true` (default) / `false` |
| (hidden) default leave option | `shutdownType` | Int | `0` default |
| On login, launch apps that were open | `loginMode` | Enum | see below |
| Ignored applications | `excludeApps` | String | comma/colon separated |

The "Enter UEFI firmware settings" toggle is not a config key at all - the
KCM's D-Bus code (`kcmsmserver.cpp`) talks to `org.freedesktop.login1`
for that and nothing else.

`loginMode` is a kcfg `Enum` with `<choices>` and no `value=` attributes,
so KConfig writes the choice *name* (`kcoreconfigskeleton.cpp`
`ItemEnum::writeConfig`). The radio buttons in `ui/main.qml` map by index:

| Radio label | Index | Written value |
|---|---|---|
| On last logout | 0 | `restorePreviousLogout` (default, key absent) |
| When session was manually saved | 1 | `restoreSavedSession` |
| Start with an empty session | 2 | `emptySession` |

A fresh machine has no `[General]` group in `~/.config/ksmserverrc` at
all - the file only holds the `[Session: saved at previous logout]` /
`[LegacySession: ...]` groups ksmserver rewrites at logout. `ini_file`
adds `[General]` next to them and leaves those groups alone, as KConfig
does in the other direction.

## There is nothing to apply live - by design, not by omission

`ksmserver/main.cpp` reads `loginMode` exactly once, in `main()`, right
after the server object is built:

- `restorePreviousLogout` -> `SESSION_PREVIOUS_LOGOUT`
- `restoreSavedSession` -> `SESSION_BY_USER`
- anything else (including `emptySession`) -> `startDefaultSession()`
- a `ksmserver --restore` command-line flag overrides all of the above to
  `SESSION_BY_USER`, and Plasma Mobile hard-codes `emptySession`.

The actual restore is triggered later by `plasma-restoresession.service`
calling `org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.restoreSession`,
which acts on the mode chosen at startup. `busctl --user introspect
org.kde.ksmserver /KSMServer` exposes no reconfigure/reload method, and
the KCM's `save()` is a bare `KQuickManagedConfigModule::save()` - it
does not signal the daemon either. So the task is the plain
config-key shape with **no handler**: the setting's entire meaning is
"what happens at the next login", and that is exactly when it is read.

## Verifying

- Key landed: `kreadconfig6 --file ksmserverrc --group General --key loginMode`
  prints `emptySession`; the KCM shows the matching radio selected.
- Behavior: log out with windows open, log back in, nothing reopens. That
  next login is the only real test - a `hanzo` re-run proving idempotency
  says nothing about whether the value is honored.
