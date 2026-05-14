"""Package installation tasks.

Installs all packages from the official repos (via pacman) and AUR (via paru).
This is the reference implementation for how Hanzo tasks should be written —
see CLAUDE.md for the full contract.
"""

from pyinfra import host
from pyinfra.operations import pacman, server

from tasks.helpers import shell_paru_install

# ---------------------------------------------------------------------------
# Official repo packages (pacman)
# ---------------------------------------------------------------------------
# Group packages into logical transactions matching the spec.
# pacman.packages is idempotent — only missing packages are installed.

pacman.packages(
    name="Install base development packages",
    packages=(
        host.data.base_packages
        + host.data.docker_packages
        + host.data.archive_packages
        + host.data.ai_packages
        + host.data.audio_packages
        + host.data.asus_packages
    ),
    update=True,
    _sudo=True,
)

pacman.packages(
    name="Install language runtimes",
    packages=host.data.runtime_packages,
    _sudo=True,
)

pacman.packages(
    name="Install gaming and multimedia",
    packages=host.data.gaming_packages,
    _sudo=True,
)

# ---------------------------------------------------------------------------
# AUR packages (paru)
# ---------------------------------------------------------------------------
# paru must run as the current user, not root.
# Flags ensure idempotent, non-interactive execution for unattended runs.

server.shell(
    name="Install AUR packages via paru",
    commands=[shell_paru_install(host.data.aur_packages)],
    _sudo=False,
)
