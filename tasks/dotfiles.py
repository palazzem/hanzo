"""Dotfiles setup task.

Clones the user's dotfiles repository to the configured directory (or pulls
if it already exists), runs the repository's installer script, and injects
git identity (user.name, user.email) from the Hanzo configuration. Git
identity injection is skipped with a warning when values are not configured.
"""

import os
import shlex

from pyinfra import host, logger
from pyinfra.operations import server

# ---------------------------------------------------------------------------
# Resolve paths — expand ~ to the actual home directory at runtime
# ---------------------------------------------------------------------------
_dotfiles_dir = os.path.expanduser(host.data.dotfiles_dir)

# ---------------------------------------------------------------------------
# Clone or update the dotfiles repository
# ---------------------------------------------------------------------------
# Mirrors the clone-or-pull pattern from bootstrap.sh: check for .git to
# decide between clone and pull. --ff-only prevents merge commits if the
# local branch has diverged unexpectedly.
if os.path.isdir(os.path.join(_dotfiles_dir, ".git")):
    server.shell(
        name="Pull latest dotfiles changes",
        commands=[
            f"git -C {shlex.quote(_dotfiles_dir)} pull --ff-only",
        ],
        _sudo=False,
    )
else:
    server.shell(
        name="Clone dotfiles repository",
        commands=[
            f"git clone {shlex.quote(host.data.dotfiles_repo)} {shlex.quote(_dotfiles_dir)}",
        ],
        _sudo=False,
    )

# ---------------------------------------------------------------------------
# Run the dotfiles installer
# ---------------------------------------------------------------------------
# The installer (install.sh) is maintained in the dotfiles repo and handles
# symlinking config files. It is designed to be idempotent (re-runnable).
server.shell(
    name="Run dotfiles installer",
    commands=[os.path.join(_dotfiles_dir, "install.sh")],
    _sudo=False,
)

# ---------------------------------------------------------------------------
# Git identity injection
# ---------------------------------------------------------------------------
# deploy.py parses ~/.config/hanzo/config and sets host.data.hanzo_fullname
# and host.data.hanzo_email. If the config file is missing or values are
# empty, we warn and skip — a partial identity (name without email or
# vice-versa) is invalid for git, so both must be present.
_fullname = host.data.get("hanzo_fullname")
_email = host.data.get("hanzo_email")

if _fullname and _email:
    server.shell(
        name="Inject git identity from Hanzo config",
        commands=[
            f"git config --global user.name {shlex.quote(_fullname)}",
            f"git config --global user.email {shlex.quote(_email)}",
        ],
        _sudo=False,
    )
else:
    logger.warning(
        "hanzo_fullname or hanzo_email not configured — skipping git identity injection. "
        "Run bootstrap.sh or edit ~/.config/hanzo/config to set them."
    )
