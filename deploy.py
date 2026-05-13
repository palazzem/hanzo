"""Hanzo deploy — pyinfra main entry point.

Run with: pyinfra @local deploy.py
"""

import os

from pyinfra import config, host, local
from pyinfra.facts.server import Command

# System provisioning requires root for package management and config writes
config.SUDO = True

# ---------------------------------------------------------------------------
# Load user configuration from ~/.config/hanzo/config
# The file uses KEY="value" shell syntax. We parse it into host.data so
# every task can access values via host.data.hanzo_fullname, etc.
# ---------------------------------------------------------------------------
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
            _value = _value.strip().strip('"').strip("'")
            # Only set if not already defined by group_data or CLI args.
            # HostData has no setdefault(); use get() + setattr() instead.
            if host.data.get(_key) is None:
                setattr(host.data, _key, _value)

# ---------------------------------------------------------------------------
# Include task files — order matters (packages first, then system, etc.)
# Paths resolve relative to CWD. bin/hanzo sets CWD to the repo root
# before exec'ing pyinfra, so these paths work from any calling directory.
# ---------------------------------------------------------------------------
local.include("tasks/packages.py")

# Phase 2 tasks (uncomment as they land):
# local.include("tasks/system.py")
# local.include("tasks/tools.py")
# local.include("tasks/dotfiles.py")

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
