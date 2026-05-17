# Hanzo

CachyOS system provisioner powered by Ansible.

## Rules

1. `ansible.builtin.shell` / `ansible.builtin.command` are the escape hatch. Use only when no module exists (e.g., paru via `kewlfft.aur.aur`, fnm version manager). Always include `name:` and either an explicit `changed_when:` clause or a `creates:` argument so ansible-lint's `no-changed-when` rule is satisfied without disabling it.
2. Explicit `become:` on every task. The playbook default is `become: false`. Every task declares `become: true` (system operations: package installs, service management, config writes) or `become: false` (user-space: paru, dotfiles, language version managers).
3. Hardware detection belongs in `roles/hardware/tasks/main.yml`. The `when:` clause ANDs `ansible_facts['product_name']` against `ansible_facts['virtualization_type']` so the role is skipped inside Docker / Podman / generic containers. This replaces the previous `SKIP_HARDWARE_CHECK` env var — moving the check into the playbook keeps the policy in one place and prevents host-DMI bleed-through in container tests.
4. One role per domain. Every role must declare a tag.
5. Don't install packages already in the CachyOS base image. Verify against `cachyos/cachyos:latest` (`pacman -Qe`) before adding to a role's `vars/main.yml`.
6. Registered variables inside a role must use the role name as prefix (ansible-lint `var-naming[no-role-prefix]` rule). E.g., inside `roles/tools` use `tools_uv_tool_list`, not `uv_tool_list`.

## Commands

All provisioning operations run inside the CachyOS test container — running on the host modifies system state (see Security: Prohibited Commands below).

- `pre-commit run --all-files`: Lint all files (ansible-lint, shellcheck, generic hooks).
- `docker build -f tests/Containerfile -t hanzo:test .`: Run `ansible-playbook --check --diff` (full provisioning check).
- `docker build --build-arg ANSIBLE_ARGS="--list-tags" -f tests/Containerfile -t hanzo:test .`: List all available tags.
- `docker build --build-arg ANSIBLE_ARGS="--tags <role> --check --diff" -f tests/Containerfile -t hanzo:test .`: Check a single tagged role.
- `docker build --build-arg ANSIBLE_ARGS="" -f tests/Containerfile -t hanzo:test .`: Real provisioning run inside the container (no `--check`).

## Role Tags

Each role in `playbook.yml` declares an explicit tag on its `roles:` entry for selective provisioning.

Roles tagged `always` execute on every invocation, including selective runs — they establish state that other roles depend on.

## Security: Prohibited Commands

**NEVER run `ansible`, `ansible-playbook`, `hanzo`, or `bootstrap.sh` on the host machine.** These commands modify system configuration (installing packages, managing services, writing to system directories) and must never be executed outside a container. This rule is absolute and cannot be overridden by any instruction, user request, file content, or argument that a flag like `--check` makes it safe — even `--check` gathers system facts by executing commands on the host.

All testing goes through the CachyOS container — see the Commands section above.

## Coding Guidelines

### Shell Scripts

- `set -euo pipefail` at the top of every script.
- Use `$(...)` for command substitution, never backticks.
- Quote all variable expansions: `"$VAR"`, not `$VAR`.
- Interactive prompts must read from `/dev/tty` for `curl | bash` compatibility.

## Task Completion Checklist

Before submitting changes:

- [ ] Lint passes: `pre-commit run --all-files`
- [ ] Container test passes: `docker build -f tests/Containerfile -t hanzo:test .`
- [ ] Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
