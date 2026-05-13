# Hanzo

CachyOS system provisioner powered by pyinfra. Runs locally via `pyinfra @local deploy.py`.

## Project Structure

```
hanzo/
├── bin/
│   ├── bootstrap.sh    # curl|sh installer (installs uv, pyinfra, clones repo, runs deploy)
│   └── hanzo           # CLI wrapper: cd to repo root, runs pyinfra @local deploy.py
├── deploy.py           # Main entry point: global config, user config loading, task includes, DMI detection
├── group_data/
│   └── all.py          # All package lists and configuration data (becomes host.data.*)
├── tasks/
│   ├── packages.py     # pacman + paru + chwd (reference implementation)
│   ├── system.py       # Groups, services, locale
│   ├── tools.py        # Version managers, pipx, infra tools
│   ├── dotfiles.py     # Dotfiles clone + install + git config
│   └── hardware/
│       └── gz302.py    # ASUS ROG Flow Z13 hardware fixes (DMI-gated in deploy.py)
├── templates/          # Jinja2 templates for config files (used by files.template)
├── CLAUDE.md           # This file — task contract
└── README.md
```

## How pyinfra Works in This Project

- `pyinfra @local deploy.py` runs all operations on the local machine via subprocess (no SSH).
- `config.SUDO = True` in deploy.py — every operation runs with sudo by default.
- `group_data/all.py` is auto-loaded by pyinfra. Every top-level variable becomes a `host.data.<name>` attribute.
- `deploy.py` loads user config from `~/.config/hanzo/config` into `host.data` (e.g., `host.data.hanzo_fullname`).
- Task files are included via `local.include("tasks/<name>.py")` in deploy.py — order matters.
- `local.include()` resolves paths relative to CWD. The `bin/hanzo` wrapper sets CWD to the repo root before running pyinfra.

## Writing a New Task File

### Template

```python
"""One-line description of what this task configures.

Detailed explanation of what gets installed/configured and why.
"""

from pyinfra import host
from pyinfra.operations import pacman, server, systemd, files

# Use host.data for all configuration values
pacman.packages(
    name="Human-readable description of this operation",
    packages=host.data.some_package_list,
)
```

### Rules

1. **Data in `group_data/all.py`, logic in `tasks/`**: Never hardcode package names, paths, or config values in task files. Add them to `group_data/all.py` and access via `host.data`.
2. **Use pyinfra operations**: Prefer built-in operations (`pacman.packages`, `files.template`, `systemd.service`, `server.user`, `files.line`) over `server.shell`. They provide idempotency for free.
3. **`server.shell` is the escape hatch**: Use it only when no built-in operation exists (e.g., paru for AUR, chwd, pyenv install). Always add a `name=` describing what it does.
4. **Sudo overrides**: Global sudo is ON. For user-space operations (paru, pyenv, pipx, dotfiles), pass `_sudo=False`. The `_` prefix is pyinfra's convention for global arguments — it is NOT a private/internal marker.
5. **Hardware detection belongs in `deploy.py`**: Task files never check DMI or hardware. The `deploy.py` entry point gates hardware-specific includes. Tasks assume they should run if they're included.
6. **Templates in `templates/`**: Use `files.template(src="templates/foo.j2", dest="/etc/foo.conf")`. Template variables come from `host.data` or are passed as keyword arguments to `files.template()`.
7. **One file per domain**: `packages.py` handles package installation, `system.py` handles groups/services/locale, etc. Don't mix concerns.
8. **Every operation needs a `name=`**: The name appears in pyinfra's output. Make it descriptive: "Install base development packages", not "packages".

### pyinfra Operations Quick Reference

```python
# Packages (official repos) — idempotent via installed-package facts
pacman.packages(name="...", packages=["pkg1", "pkg2"], update=True)

# AUR packages — paru runs as user, not root
server.shell(name="...", commands=["paru -S --needed --noconfirm pkg1 pkg2"], _sudo=False)

# Config files from Jinja2 templates
files.template(name="...", src="templates/foo.j2", dest="/etc/foo.conf", mode="644", my_var="value")

# Ensure a line exists in a file
files.line(name="...", path="/etc/some.conf", line="KEY=value")

# Systemd services
systemd.service(name="...", service="docker", running=True, enabled=True)

# User/group management
server.group(name="...", group="docker", system=True)
server.user(name="...", user="myuser", groups=["docker", "video"], append=True)

# Shell commands (escape hatch)
server.shell(name="...", commands=["some-command --flag"])

# Facts (read system state)
from pyinfra.facts.server import Command
result = host.get_fact(Command, command="cat /some/file")
```

## Running

```bash
# Full provisioning
pyinfra @local deploy.py

# Via wrapper (after bootstrap)
hanzo

# Dry run
hanzo --dry
```

## Configuration

User config: `~/.config/hanzo/config` (shell KEY="value" format, parsed by deploy.py).
Static data: `group_data/all.py` (Python lists/dicts, auto-loaded as host.data).

## Testing

CI uses a CachyOS container with `SKIP_HARDWARE_CHECK=1` to bypass DMI detection.
Locally, use `hanzo --dry` to verify changes without applying them.
