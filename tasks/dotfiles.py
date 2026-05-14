"""Dotfiles and Claude Code configuration setup task.

Clones the user's dotfiles repository to the configured directory (or pulls
if it already exists), runs the repository's installer script, and injects
git identity (user.name, user.email) from the Hanzo configuration. Git
identity injection is skipped with a warning when values are not configured.

Also clones the Claude Code configuration repository (claude-config) into
~/.claude. If ~/.claude already exists but isn't a git repo (created by
Claude Code on first use), the directory is adopted in-place as a git repo
while preserving untracked runtime files.
"""

import os
import shlex

from pyinfra import host, logger
from pyinfra.operations import server


def _git_pull_ff_cmd(repo_dir: str) -> str:
    """Build a git pull --ff-only command with a graceful fallback on divergence.

    Uses --ff-only to avoid accidental merge commits. On failure (diverged
    branch, network error, etc.) warns and continues rather than aborting the
    entire provisioning run — a stale checkout is acceptable; a failed
    provision is not.
    """
    return (
        f"git -C {shlex.quote(repo_dir)} pull --ff-only"
        " || echo 'WARNING: fast-forward failed; local branch may have diverged — skipping pull' >&2"
    )


# ---------------------------------------------------------------------------
# Resolve paths — expand ~ to the actual home directory at runtime
# ---------------------------------------------------------------------------
_dotfiles_dir = os.path.expanduser(host.data.dotfiles_dir)

# ---------------------------------------------------------------------------
# Clone or update the dotfiles repository
# ---------------------------------------------------------------------------
# Mirrors the clone-or-pull pattern from bootstrap.sh: check for .git to
# decide between clone and pull. os.path.isdir() evaluates at control time
# (Python parse), not deploy time — safe because Hanzo always targets @local.
# Pull uses --ff-only with a graceful fallback (see _git_pull_ff_cmd).
if os.path.isdir(os.path.join(_dotfiles_dir, ".git")):
    server.shell(
        name="Pull latest dotfiles changes",
        commands=[_git_pull_ff_cmd(_dotfiles_dir)],
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
    commands=[shlex.quote(os.path.join(_dotfiles_dir, "install.sh"))],
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

# ---------------------------------------------------------------------------
# Clone or update the Claude Code configuration repository
# ---------------------------------------------------------------------------
# claude-config provides versioned Claude Code settings (CLAUDE.md, skills,
# agents, settings.json). The repo uses an ignore-all .gitignore that
# whitelists only config files, so untracked runtime files (memory/,
# projects/, credentials) are preserved across all code paths.
# Expanded on the control machine — safe because Hanzo always targets @local.
_claude_config_dir = os.path.expanduser(host.data.claude_config_dir)

if os.path.isdir(os.path.join(_claude_config_dir, ".git")):
    server.shell(
        name="Pull latest claude-config changes",
        commands=[_git_pull_ff_cmd(_claude_config_dir)],
        _sudo=False,
    )
elif os.path.isdir(_claude_config_dir):
    # Claude Code creates ~/.claude on first use. Adopt the existing
    # directory as a git repo: init, fetch remote, and hard-reset to
    # overwrite tracked files (repo is source of truth) while leaving
    # untracked runtime files untouched.
    server.shell(
        name="Adopt existing ~/.claude directory as claude-config repo",
        commands=[
            f"git init {shlex.quote(_claude_config_dir)}",
            f"git -C {shlex.quote(_claude_config_dir)} remote set-url origin"
            f" {shlex.quote(host.data.claude_config_repo)} 2>/dev/null"
            f" || git -C {shlex.quote(_claude_config_dir)} remote add origin"
            f" {shlex.quote(host.data.claude_config_repo)}",
            f"git -C {shlex.quote(_claude_config_dir)} fetch origin",
            f"git -C {shlex.quote(_claude_config_dir)} reset --hard origin/main",
            f"git -C {shlex.quote(_claude_config_dir)} branch -M main",
            f"git -C {shlex.quote(_claude_config_dir)} branch --set-upstream-to=origin/main",
        ],
        _sudo=False,
    )
else:
    server.shell(
        name="Clone claude-config repository",
        commands=[
            f"git clone {shlex.quote(host.data.claude_config_repo)}"
            f" {shlex.quote(_claude_config_dir)}",
        ],
        _sudo=False,
    )
