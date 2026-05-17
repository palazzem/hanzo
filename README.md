# Hanzo

[![Testing](https://github.com/palazzem/hanzo/actions/workflows/test.yaml/badge.svg)](https://github.com/palazzem/hanzo/actions/workflows/test.yaml)

> Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
> The Bride: ...Huge.

CachyOS system provisioner powered by [Ansible](https://docs.ansible.com/). A single command bootstraps a complete development and gaming machine with idempotent configuration.

## Requirements

- [CachyOS](https://cachyos.org/) (Arch-based)
- Internet connection for initial setup

## Quickstart

```bash
curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash
```

This will:

1. Ask for your sudo password (once)
2. Install [uv](https://docs.astral.sh/uv/) and [ansible-core](https://docs.ansible.com/ansible-core/)
3. Clone this repository to `~/.local/src/hanzo`
4. Install required Galaxy collections (`community.general`, `kewlfft.aur`)
5. Prompt for your name and email (first run only)
6. Run the full provisioning

## Usage

After bootstrap, re-run provisioning at any time:

```bash
hanzo              # full provisioning run
hanzo --check      # dry run (shows what would change)
```

For selective provisioning, pass `--tags <role>` to run a subset of the playbook:

```bash
hanzo --tags hardware                  # only the hardware role
hanzo --tags "languages,devtools"      # languages + devtools
hanzo --list-tags                      # list all available tags
```

See [CLAUDE.md's Role Tags section](CLAUDE.md#role-tags) for the full tag list and dependency notes.

`hanzo` accepts any flag that `ansible-playbook` understands.

## Configuration

User configuration is stored at `~/.config/hanzo/config.yml`:

```yaml
hanzo_fullname: "Your Name"
hanzo_email: "your@email.com"
```

Edit this file directly to update your settings. You can also set `HANZO_FULLNAME` and `HANZO_EMAIL` as environment variables for unattended provisioning (e.g., in containers) — the bootstrap script will write them to the config file in YAML form, escaping any embedded quotes or backslashes.

## Architecture

Hanzo uses Ansible to provision the local machine via `ansible-playbook playbook.yml`. All operations are idempotent — running `hanzo` multiple times is safe and will only apply changes that are needed.

- `playbook.yml` — main entry point, lists roles in dependency order
- `ansible.cfg` — local connection, become defaults, roles path
- `group_vars/all.yml` — package lists, system configuration, and hardware data
- `requirements.yml` — Galaxy collection dependencies (pinned versions)
- `roles/` — one role per domain (`foundation`, `packages`, `virtualization`, `trust`, `system`, `languages`, `devtools`, `infra`, `dotfiles`, `security`, `hardware`); each is selectable via `--tags <role>` (see [CLAUDE.md](CLAUDE.md#role-tags))

The `hardware` role is dispatched by `ansible_product_name` and skipped automatically inside containers (via `ansible_virtualization_type`).

## Development

Clone the repository and install the pre-commit hooks:

```bash
git clone https://github.com/palazzem/hanzo.git
cd hanzo
pre-commit install
```

Run linters locally:

```bash
pre-commit run --all-files
```

Run the full test suite inside a CachyOS container:

```bash
docker build -f tests/Containerfile -t hanzo:test .
```

The container test runs `ansible-playbook --check` in two stages — once without `~/.config/hanzo/config.yml` (exercises the graceful missing-config path) and once with it (exercises the identity-injection path).

## Contribute

This tool provisions my personal CachyOS setup. You may use this repository as a base to create your own configuration. I'll be glad to accept any PR that:

* Fixes bugs or issues in the current implementation
* Improves the Ansible role structure or provisioning logic
* Enhances or makes me aware of different provisioning approaches

I will not merge pull requests that add new development tools, but I will be grateful if you can discuss about it
in the [issue tracker](https://github.com/palazzem/hanzo/issues).

See `CLAUDE.md` for the task authoring contract.

## License

BSD 2-Clause. See [LICENSE](LICENSE) for details.
