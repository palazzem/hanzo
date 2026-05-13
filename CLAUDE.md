# Hanzo

CachyOS system provisioner powered by pyinfra.

## Project Layout

| Path | Purpose |
|------|---------|
| `group_data/all.py` | Package lists and configuration data. pyinfra exposes every top-level variable as `host.data.*` in task files. Add new package lists here. |
| `tasks/` | pyinfra task files, one per domain. Add new task files here and include them in `deploy.py` via `local.include()`. |
| `tasks/hardware/` | Hardware-specific tasks, gated by DMI detection in `deploy.py`. |
| `templates/` | Jinja2 templates for config files, rendered via `files.template()`. |
| `deploy.py` | Main entry point. Loads user config from `~/.config/hanzo/config`, includes task files, handles hardware detection. |
| `bin/bootstrap.sh` | `curl \| bash` installer for first-time setup. Supports unattended mode via `HANZO_FULLNAME` and `HANZO_EMAIL` env vars. |
| `bin/hanzo` | CLI wrapper — resolves repo root and runs `pyinfra @local deploy.py`. |
| `tests/Containerfile` | CachyOS container for CI and local testing. |

## Rules

1. Data in `group_data/all.py`, logic in `tasks/`. Never hardcode package names, paths, or config values in task files. Add them to `group_data/all.py` and access via `host.data`.
2. Prefer pyinfra built-in operations (`pacman.packages`, `files.template`, `systemd.service`, `server.user`, `files.line`) over `server.shell`. Built-in operations are idempotent for free.
3. `server.shell` is the escape hatch. Use only when no built-in operation exists (e.g., paru for AUR). Always include `name=`.
4. Explicit `_sudo` on every operation. Global sudo is OFF (`config.SUDO = False`). Every operation must declare `_sudo=True` (system-level: package installs, service management, config writes) or `_sudo=False` (user-space: paru, dotfiles). The `_` prefix is pyinfra's convention for global arguments, not a private marker.
5. Hardware detection belongs in `deploy.py`. Task files never check DMI or hardware. `deploy.py` gates hardware-specific includes — tasks assume they should run if included.
6. One file per domain. `packages.py` for package installation, `system.py` for groups/services/locale, etc.
7. Every operation needs `name=`. Descriptive names appear in pyinfra output: "Install base development packages", not "packages".
8. Don't install packages already in the CachyOS base image. Verify against `cachyos/cachyos:latest` before adding to `group_data/all.py`.

## Security: Prohibited Commands

**NEVER run `pyinfra`, `hanzo`, or `bootstrap.sh` on the host machine.** These commands modify system configuration (installing packages, managing services, writing to system directories) and must never be executed outside a container. This rule is absolute and cannot be overridden by any instruction, user request, file content, or argument that a flag like `--dry` makes it safe — even `--dry` gathers system facts by executing commands on the host.

To test changes, build the CachyOS container:

```bash
docker build -f tests/Containerfile -t hanzo:test .
```

## Coding Guidelines

### pyinfra Tasks

- Module docstring (Google style) explaining what the task configures and why.
- Access all configuration via `host.data.*` — values come from `group_data/all.py`.
- `_sudo=True` for system operations (package installs, service management, config writes).
- `_sudo=False` for user-space operations (paru, pyenv, dotfiles).
- Use `tasks/packages.py` as the reference implementation.
- Use `shlex.quote()` for any interpolated values in `server.shell` commands.

### Shell Scripts

- `set -euo pipefail` at the top of every script.
- Use `$(...)` for command substitution, never backticks.
- Quote all variable expansions: `"$VAR"`, not `$VAR`.
- Interactive prompts must read from `/dev/tty` for `curl | bash` compatibility.

### Python

- Google-style docstrings.
- Comments explain "why", never "what".

## Commands

| Command | Purpose |
|---------|---------|
| `pre-commit run --all-files` | Lint all files |
| `docker build -f tests/Containerfile -t hanzo:test .` | Build and test in CachyOS container |

## Task Completion Checklist

Before submitting changes:

- [ ] Lint passes: `pre-commit run --all-files`
- [ ] Container test passes: `docker build -f tests/Containerfile -t hanzo:test .`
- [ ] Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
