# Hanzo

[![Testing](https://github.com/palazzem/hanzo/actions/workflows/test.yaml/badge.svg)](https://github.com/palazzem/hanzo/actions/workflows/test.yaml)

> Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
> The Bride: ...Huge.

CachyOS system provisioner powered by [pyinfra](https://pyinfra.com/). A single command bootstraps a complete development and gaming machine with idempotent configuration.

## Requirements

- [CachyOS](https://cachyos.org/) (Arch-based)
- Internet connection for initial setup

## Quickstart

```bash
curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash
```

This will:

1. Ask for your sudo password (once)
2. Install [uv](https://docs.astral.sh/uv/) and [pyinfra](https://pyinfra.com/)
3. Clone this repository to `~/.local/src/hanzo`
4. Prompt for your name and email (first run only)
5. Run the full provisioning

## Usage

After bootstrap, re-run provisioning at any time:

```bash
hanzo              # full provisioning run
hanzo --dry        # dry run (shows what would change)
```

## Configuration

User configuration is stored at `~/.config/hanzo/config`:

```
HANZO_FULLNAME="Your Name"
HANZO_EMAIL="your@email.com"
```

Edit this file directly to update your settings. You can also set `HANZO_FULLNAME` and `HANZO_EMAIL` as environment variables for unattended provisioning (e.g., in containers).

## Architecture

Hanzo uses pyinfra to run operations locally via `pyinfra @local`. All operations are idempotent — running `hanzo` multiple times is safe and will only apply changes that are needed.

- `deploy.py` — main entry point, includes all task files
- `group_data/all.py` — package lists and configuration data
- `tasks/` — individual task files (packages, system, tools, dotfiles, hardware)
- `templates/` — Jinja2 templates for config files

## Contribute

This tool provisions my personal CachyOS setup. You may use this repository as a base to create your own configuration. I'll be glad to accept any PR that:

* Fixes bugs or issues in the current implementation
* Improves the pyinfra task structure or provisioning logic
* Enhances or makes me aware of different provisioning approaches

I will not merge pull requests that add new development tools, but I will be grateful if you can discuss about it
in the [issue tracker](https://github.com/palazzem/hanzo/issues).

See `CLAUDE.md` for the task authoring contract.
