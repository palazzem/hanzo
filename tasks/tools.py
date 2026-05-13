"""Development tools installation tasks.

Installs version managers (pyenv, rustup stable toolchain, fnm Node.js LTS),
configures Go workspace, installs Python CLI tools via pipx, infrastructure
tools (terraform, packer, tflint, gcloud, tfupdate), and AI tooling (Claude
Code). All operations are user-space — no sudo required.

Prerequisites:
    tasks/packages.py must run first to install rustup, go, fnm-bin, and
    python-pipx via pacman/paru.
"""

import os

from pyinfra import host
from pyinfra.operations import files, server

# ---------------------------------------------------------------------------
# Version managers
# ---------------------------------------------------------------------------

# pyenv: Python version manager installed via pyenv-installer.
# The installer clones the pyenv repo to ~/.pyenv. Guard checks if the
# directory already exists to avoid re-cloning on subsequent runs.
server.shell(
    name="Install pyenv via pyenv-installer",
    commands=[
        'test -d "$HOME/.pyenv" || curl -fsSL https://pyenv.run | bash',
    ],
    _sudo=False,
)

# rustup: set stable as default toolchain.
# rustup is already installed via pacman (runtime_packages) but ships with
# no default toolchain. This command is inherently idempotent — it prints
# "unchanged" if stable is already the default.
server.shell(
    name="Set rustup default toolchain to stable",
    commands=["rustup default stable"],
    _sudo=False,
)

# fnm: install Node.js LTS and set as default.
# fnm-bin is already installed via paru (aur_packages). Each server.shell
# runs in a fresh shell, so we must eval fnm env to activate it. Both
# fnm install commands are idempotent (skip already-installed versions).
# We use `fnm default $(fnm current)` instead of `fnm default lts-latest`
# because fnm has a known bug where lts-latest is not recognized as a
# valid alias (https://github.com/Schniz/fnm/issues/1203).
server.shell(
    name="Install Node.js LTS via fnm",
    commands=[
        'eval "$(fnm env)" && fnm install --lts && fnm default "$(fnm current)"',
    ],
    _sudo=False,
)

# GOPATH: create Go workspace directory structure.
# go is already installed via pacman (runtime_packages). GOPATH persistence
# across interactive shell sessions depends on tasks/dotfiles.py (fish
# shell config). files.directory is idempotent — no-op if already exists.
_gopath = os.path.expanduser(host.data.gopath)

files.directory(
    name="Create GOPATH directory",
    path=_gopath,
    _sudo=False,
)

files.directory(
    name="Create GOPATH bin directory",
    path=os.path.join(_gopath, "bin"),
    _sudo=False,
)

# ---------------------------------------------------------------------------
# pipx tools
# ---------------------------------------------------------------------------
# python-pipx is installed by packages.py (base_packages). Each tool is
# checked via `pipx list` before install because pipx exits with an error
# if a tool is already installed. The --short flag outputs "name version"
# per line, so grep anchors on "^tool " to avoid substring matches.

for _tool in host.data.pipx_tools:
    server.shell(
        name=f"Install {_tool} via pipx",
        commands=[
            f'pipx list --short 2>/dev/null | grep -q "^{_tool} " || pipx install {_tool}',
        ],
        _sudo=False,
    )
