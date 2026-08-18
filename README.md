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

1. Install [uv](https://docs.astral.sh/uv/) and [ansible-core](https://docs.ansible.com/ansible-core/)
2. Clone this repository to `~/.local/src/hanzo`
3. Install required Galaxy collections (`community.general`)
4. Prompt for your name and email (first run only)
5. Run the full provisioning (prompts once for your sudo password)
6. Reconcile AUR packages via `shelly-update` ([Shelly](https://github.com/Seafoam-Labs/Shelly-ALPM)-powered): every PKGBUILD passes a mandatory Claude security review AND your explicit approval, and its sources are checksum- and signature-verified against pinned keys before the build

## Usage

After bootstrap, re-run provisioning at any time:

```bash
hanzo              # full run: converge the system, then reconcile AUR packages
hanzo --check      # dry run (shows what would change; no AUR reconciliation)
hanzo --no-aur     # converge only; run shelly-update later
shelly-update      # AUR reconciliation alone
```

Every full run ends with **`shelly-update`**, the attended AUR reconciliation. It requires the `claude` CLI (starting `claude auth login` if needed), verifies the pinned upstream signing keys, and refuses to run while any AUR package installed on the system is missing from the Hanzo manifests. Then, per package: new packages show their full PKGBUILD and updated packages the diff since your last approved commit; Claude reviews it (a FAIL verdict stops everything) and you confirm explicitly; sources are checksum- and signature-verified before Shelly builds at that exact reviewed commit. Without a terminal (cron, CI, piped runs) the reconciliation is skipped and reported as pending.

For selective provisioning, pass `--tags <role>` to run a subset of the playbook:

```bash
hanzo --tags hardware                  # only the hardware role
hanzo --tags "languages,tools"         # languages + tools
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
- `requirements.yml` — Galaxy collection dependencies (pinned versions)
- `roles/` — one directory per configured domain; each role declares a tag for selective `--tags <role>` runs
- `bin/hanzo` — the CLI: runs the playbook, then hands off to `shelly-update`. The playbook itself requires no passwordless sudo at any point.
- `bin/shelly-update` — attended AUR reconciliation: Claude + human review of every PKGBUILD, pinned trust keys (`trust/keys.conf`, fetched sha256-pinned from the vendor and cross-checked against a keyserver), `makepkg --verifysource` (checksums + PGP), convergence enforcement (no unmanaged AUR packages), and commit-pinned Shelly installs. Signed upstreams (`trust/signed-packages.conf`) must keep their signature verification or the run aborts.

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
