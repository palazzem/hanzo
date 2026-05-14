"""Shell command builders for pyinfra server.shell operations.

Centralizes shell command construction so that every server.shell call
across task files uses consistently quoted, well-tested patterns. Each
function returns a shell command string ready to pass as an element in a
server.shell(commands=[...]) list.

All user-supplied values are quoted via shlex.quote() to prevent shell
injection from unexpected characters in configuration data.
"""

import shlex

# Each server.shell spawns a fresh shell where fnm-managed Node.js is
# not on PATH. This preamble must prefix every command that needs
# node/npm.
FNM_ACTIVATE = 'eval "$(fnm env)"'


def shell_git_pull(repo_dir: str) -> str:
    """Build a git pull --ff-only command with a graceful fallback.

    Uses --ff-only to avoid accidental merge commits. On failure (diverged
    branch, network error, etc.) warns on stderr and continues rather than
    aborting the entire provisioning run — a stale checkout is acceptable;
    a failed provision is not.

    Args:
        repo_dir: Absolute path to the git repository.

    Returns:
        Shell command string.
    """
    return (
        f"git -C {shlex.quote(repo_dir)} pull --ff-only"
        " || echo 'WARNING: fast-forward failed; local branch may have"
        " diverged — skipping pull' >&2"
    )


def shell_paru_install(packages: list[str]) -> str:
    """Build an idempotent paru install command for AUR packages.

    Uses --needed to skip already-installed packages and --noconfirm
    for unattended execution. Each package name is individually quoted.

    Args:
        packages: List of AUR package names.

    Returns:
        Shell command string.
    """
    return "paru -S --needed --noconfirm " + " ".join(shlex.quote(p) for p in packages)


def shell_uv_tool_install(tool: str) -> str:
    """Build a check-then-install command for a uv tool.

    Checks uv tool list output before installing to avoid errors on
    already-installed tools. The grep anchors on "^tool " to prevent
    substring false positives.

    Args:
        tool: Name of the uv tool to install.

    Returns:
        Shell command string.
    """
    return (
        f'uv tool list 2>/dev/null | grep -q "^{tool} "'
        f" || uv tool install {shlex.quote(tool)}"
    )


def shell_npm_install(pkg: str) -> str:
    """Build a check-then-install command for a global npm package.

    Activates fnm to make node/npm available in the fresh shell, then
    checks npm list -g before installing to avoid reinstalling existing
    packages.

    Args:
        pkg: npm package name (e.g., "@anthropic-ai/claude-code").

    Returns:
        Shell command string.
    """
    return (
        f"{FNM_ACTIVATE} && "
        f"(npm list -g {shlex.quote(pkg)} >/dev/null 2>&1"
        f" || npm install -g {shlex.quote(pkg)})"
    )
