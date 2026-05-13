"""Development tools installation tasks.

Installs version managers (pyenv, rustup stable toolchain, fnm Node.js LTS),
configures Go workspace, installs Python CLI tools via uv, infrastructure
tools (terraform, tflint, tfupdate, gcloud), and AI tooling (Claude Code).
All operations are user-space — no sudo required.

Prerequisites:
    tasks/packages.py must run first to install rustup, go, fnm-bin, and
    uv via pacman/paru.
"""

import os
import shlex

from pyinfra import host
from pyinfra.operations import files, server

# Each server.shell spawns a fresh shell where fnm-managed Node.js is not
# on PATH. This preamble must appear in every command that needs node/npm.
_FNM_ACTIVATE = 'eval "$(fnm env)"'

# ---------------------------------------------------------------------------
# Version managers
# ---------------------------------------------------------------------------

# The installer clones the pyenv repo to ~/.pyenv. Guard checks the binary
# rather than just the directory to detect corrupt/incomplete installs.
server.shell(
    name="Install pyenv via pyenv-installer",
    commands=[
        'test -x "$HOME/.pyenv/bin/pyenv" || curl -fsSL https://pyenv.run | bash',
    ],
    _sudo=False,
)

# rustup is already installed via pacman (runtime_packages) but ships with
# no default toolchain. This command is inherently idempotent — it prints
# "unchanged" if stable is already the default.
server.shell(
    name="Set rustup default toolchain to stable",
    commands=["rustup default stable"],
    _sudo=False,
)

# fnm-bin is already installed via paru (aur_packages). Each server.shell
# runs in a fresh shell, so we must eval fnm env to activate it. Both
# fnm install commands are idempotent (skip already-installed versions).
# We use `fnm default $(fnm current)` instead of `fnm default lts-latest`
# because fnm has a known bug where lts-latest is not recognized as a
# valid alias (https://github.com/Schniz/fnm/issues/1203).
server.shell(
    name="Install Node.js LTS via fnm",
    commands=[
        f'{_FNM_ACTIVATE} && fnm install --lts && fnm default "$(fnm current)"',
    ],
    _sudo=False,
)

# go is already installed via pacman (runtime_packages). GOPATH persistence
# across interactive shell sessions depends on tasks/dotfiles.py (fish
# shell config).
# Expanded on the control machine — safe because Hanzo always targets @local.
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
# uv tools
# ---------------------------------------------------------------------------
# uv is installed by packages.py (base_packages). Each tool is checked via
# `uv tool list` before install because uv exits with an error if a tool
# is already installed. The output format is "name vX.Y.Z" per tool, so
# grep anchors on "^tool " to avoid substring matches.

for _tool in host.data.uv_tools:
    server.shell(
        name=f"Install {_tool} via uv tool",
        commands=[
            f'uv tool list 2>/dev/null | grep -q "^{_tool} " || uv tool install {shlex.quote(_tool)}',
        ],
        _sudo=False,
    )

# ---------------------------------------------------------------------------
# Infrastructure tools
# ---------------------------------------------------------------------------

# paru handles sudo internally, so _sudo=False. The --needed flag skips
# already-installed packages (same pattern as packages.py's paru call).
server.shell(
    name="Install infrastructure AUR packages via paru",
    commands=[
        "paru -S --needed --noconfirm "
        + " ".join(shlex.quote(p) for p in host.data.infra_aur_packages),
    ],
    _sudo=False,
)

# Prompts must be disabled for unattended pyinfra runs. Install directory
# is ~/.local/share/ rather than ~ to follow XDG conventions.
server.shell(
    name="Install Google Cloud SDK",
    commands=[
        'test -d "$HOME/.local/share/google-cloud-sdk" || '
        "(curl -fsSL https://sdk.cloud.google.com | "
        'bash -s -- --disable-prompts --install-dir="$HOME/.local/share")',
    ],
    _sudo=False,
)

# ---------------------------------------------------------------------------
# AI / Editor tooling
# ---------------------------------------------------------------------------
# Node.js must be available via fnm. Each command re-evaluates fnm env
# since server.shell runs in fresh processes. npm list -g checks if the
# package is already globally installed before running npm install.

for _pkg in host.data.npm_global_packages:
    server.shell(
        name=f"Install {_pkg} via npm",
        commands=[
            f"{_FNM_ACTIVATE} && "
            f"(npm list -g {shlex.quote(_pkg)} >/dev/null 2>&1 || npm install -g {shlex.quote(_pkg)})",
        ],
        _sudo=False,
    )
