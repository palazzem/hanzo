# Hanzo

[![CI](https://github.com/palazzem/hanzo/actions/workflows/ci.yml/badge.svg)](https://github.com/palazzem/hanzo/actions/workflows/ci.yml)

> Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
> The Bride: ...Huge.

CachyOS system provisioner powered by [Ansible](https://docs.ansible.com/). A single command bootstraps a complete development and gaming machine with idempotent configuration.

## Requirements

- [CachyOS](https://cachyos.org/) (Arch-based)
- Full-disk encryption (LUKS) on the root filesystem to prevent unencrypted swap file
- Internet connection for initial setup

## Quickstart

```bash
curl -L https://raw.githubusercontent.com/palazzem/hanzo/main/bin/bootstrap.sh | bash
```

This will:

1. Install [uv](https://docs.astral.sh/uv/)
2. Clone this repository to `~/.local/src/hanzo`
3. Prompt for your name and email (first run only)
4. Link `hanzo` and `hanzo-aur` into `~/.local/bin`
5. Install [ansible-core](https://docs.ansible.com/ansible-core/)
6. Install required Galaxy collections (`community.general`)
7. Run the full provisioning: the playbook (prompts once for your sudo password), then the AUR package set through Shelly (one PKGBUILD review per package)
8. Print the manual steps automation cannot cover (see below)

## Usage

After bootstrap, re-run provisioning at any time:

```bash
hanzo              # full provisioning run
hanzo --check      # dry run (shows what would change)
hanzo --ci         # unattended run, container only
```

## Manual Steps

Every provisioning run ends by printing the three steps that stay in your hands — they need account secrets or firmware access no playbook can reach:

1. [ProtonVPN over WireGuard](https://protonvpn.com/support/wireguard-linux#cli) — generate a WireGuard configuration in your ProtonVPN account, then import it with NetworkManager
2. [Secure Boot](https://wiki.cachyos.org/configuration/secure_boot_setup/) — put the firmware in setup mode, enroll your own keys with `sbctl`, then sign the bootloader and the kernel
3. Reboot with `sudo systemctl reboot` — kernel, firmware, and service changes only take effect on the next boot

## Configuration

User configuration is stored at `~/.config/hanzo/config.yml`:

```yaml
hanzo_fullname: "Your Name"
hanzo_email: "your@email.com"
```

Edit this file directly to update your settings. You can also set `HANZO_FULLNAME` and `HANZO_EMAIL` as environment variables for unattended provisioning (e.g., in containers) — when the config file does not exist yet, the bootstrap script writes them out instead of prompting. An existing config file is never rewritten, so later changes go in the file itself.

The file is loaded into its own namespace and read through an allowlist: exactly `hanzo_fullname` and `hanzo_email` are used, and **any other key is ignored**. It is not a place to override playbook or role variables — since the file is user-writable, an unfiltered load would let anything with write access to your home directory inject variables into tasks that run as root. Both keys are optional; when one is missing, the matching git identity setting is simply skipped.

## Architecture

Hanzo provisions the local machine with `ansible-playbook playbook.yml`, then hands the AUR package set to Shelly — Ansible never manages AUR. All operations are idempotent — running `hanzo` multiple times is safe and will only apply changes that are needed.

- `playbook.yml` — main entry point, lists roles in dependency order
- `ansible.cfg` — local connection, become defaults, roles path
- `requirements.yml` — Galaxy collection dependencies (pinned versions)
- `roles/` — one directory per configured domain; each role declares a tag
- `bin/` — `bootstrap.sh` (one-command setup), `hanzo` (provisioning CLI), `hanzo-aur` (AUR package set via Shelly)

The `hardware` role is dispatched by `ansible_facts['product_name']` and skipped automatically inside containers and other non-systemd contexts (see `CLAUDE.md` rule 3).

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

Run provisioning inside a CachyOS container:

```bash
# Provisioning check
docker build --build-arg HANZO_ARGS="--check" -f tests/Containerfile -t hanzo:test .

# Full unattended provisioning
docker build --build-arg HANZO_ARGS="--ci" -f tests/Containerfile -t hanzo:test .
```

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
