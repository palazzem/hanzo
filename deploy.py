"""Hanzo deploy — pyinfra main entry point.

Run with: pyinfra @local deploy.py
"""

import os

from pyinfra import config, host, local, logger
from pyinfra.facts.server import Command

# Safe default: no implicit sudo. Each operation must declare _sudo explicitly.
config.SUDO = False

# ---------------------------------------------------------------------------
# Load user configuration from ~/.config/hanzo/config
# The file uses KEY="value" shell syntax. We parse it into host.data so
# every task can access values via host.data.hanzo_fullname, etc.
# ---------------------------------------------------------------------------
# Update this set when adding new config keys to bin/bootstrap.sh.
_ALLOWED_CONFIG_KEYS = {"hanzo_fullname", "hanzo_email"}

_config_path = os.path.expanduser("~/.config/hanzo/config")
if os.path.isfile(_config_path):
    with open(_config_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if not _line or _line.startswith("#"):
                continue
            _key, _sep, _value = _line.partition("=")
            if not _sep:
                continue
            _key = _key.strip().lower()
            if _key not in _ALLOWED_CONFIG_KEYS:
                logger.warning(f"Ignoring unknown config key: {_key}")
                continue
            _value = _value.strip().strip('"').strip("'")
            # Only set if not already defined by group_data or CLI args.
            # HostData has no setdefault(); use get() + setattr() instead.
            if host.data.get(_key) is None:
                setattr(host.data, _key, _value)

# ---------------------------------------------------------------------------
# Include task files
#
# Order matters — each task depends on those above it:
#
#   packages.py   no dependencies (installs all system and AUR packages)
#       |
#   system.py     groups + services installed by packages.py
#       |
#   tools.py      configures rustup, fnm, go, uv installed by packages.py;
#                 paru (preinstalled on CachyOS) for infra AUR packages
#       |
#   dotfiles.py   installer may reference tool paths from tools.py;
#                 git identity uses config parsed above
#
# Hardware tasks (included conditionally after DMI detection below):
#   hardware/gz302.py   uses asusctl, rog-control-center from packages.py
#
# Paths resolve relative to CWD. bin/hanzo sets CWD to the repo root
# before exec'ing pyinfra, so these paths work from any calling directory.
# ---------------------------------------------------------------------------
local.include("tasks/packages.py")
local.include("tasks/system.py")
local.include("tasks/tools.py")
local.include("tasks/dotfiles.py")

# ---------------------------------------------------------------------------
# Hardware detection: include GZ302 fixes only on matching hardware.
# Set SKIP_HARDWARE_CHECK=1 to bypass (used in CI).
# ---------------------------------------------------------------------------
if os.environ.get("SKIP_HARDWARE_CHECK"):
    _product_name = ""
else:
    _product_name = host.get_fact(
        Command,
        command="cat /sys/class/dmi/id/product_name 2>/dev/null || echo unknown",
    )

if "GZ302" in (_product_name or ""):
    local.include("tasks/hardware/gz302.py")
