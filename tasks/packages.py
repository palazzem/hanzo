"""Package installation tasks.

Installs all packages from the official repos (via pacman), AUR (via paru),
and auto-detects GPU drivers (via chwd). This is the reference implementation
for how Hanzo tasks should be written — see CLAUDE.md for the full contract.
"""

from pyinfra import host
from pyinfra.operations import pacman, server

# ---------------------------------------------------------------------------
# Official repo packages (pacman)
# ---------------------------------------------------------------------------
# pacman.packages is idempotent: pyinfra queries installed packages via
# facts and only installs what's missing. We group packages into logical
# transactions matching the spec.

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
)

pacman.packages(
    name="Install language runtimes",
    packages=host.data.runtime_packages,
)

pacman.packages(
    name="Install gaming and multimedia",
    packages=host.data.gaming_packages,
)

# ---------------------------------------------------------------------------
# AUR packages (paru)
# ---------------------------------------------------------------------------
# paru must run as the current user, not root. Override global SUDO.
# --needed skips already-installed packages. --noconfirm avoids prompts.

server.shell(
    name="Install AUR packages via paru",
    commands=[
        "paru -S --needed --noconfirm " + " ".join(host.data.aur_packages),
    ],
    _sudo=False,
)

# ---------------------------------------------------------------------------
# GPU driver auto-detection
# ---------------------------------------------------------------------------
# chwd (CachyOS Hardware Detection) picks the right GPU driver automatically.

server.shell(
    name="Auto-detect and install GPU drivers",
    commands=["chwd -a"],
)
