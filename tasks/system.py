"""System configuration tasks.

Configures user group memberships, enables systemd services, and sets the
system locale. All values come from group_data/all.py via host.data.

Groups:
    Creates system groups (e.g., docker) that may not exist yet, then adds
    the current user to all configured supplementary groups. Groups like
    render and video are kernel-managed and assumed to exist.

Services:
    Enables and starts systemd services installed by tasks/packages.py.
    Runs after packages so the service units are already on disk.

Locale:
    Ensures /etc/locale.conf has the correct LANG= setting.
"""

import getpass

from pyinfra import host
from pyinfra.operations import files, server, systemd

# Resolved at runtime — pyinfra runs locally via @local, so this is always
# the real invoking user. getpass.getuser() reads from the passwd database,
# which works even when $USER is unset (e.g., Docker RUN steps).
_current_user = getpass.getuser()

# ---------------------------------------------------------------------------
# Groups
# ---------------------------------------------------------------------------
# Ensure system groups exist before adding the user.
# docker is package-managed but created explicitly as a safety net in case
# include order changes. render/video are kernel-managed — no creation needed.

for _group in host.data.system_groups:
    server.group(
        name=f"Ensure {_group} group exists",
        group=_group,
        system=True,
        _sudo=True,
    )

server.user(
    name=f"Add {_current_user} to supplementary groups",
    user=_current_user,
    groups=host.data.user_groups,
    append=True,
    _sudo=True,
)

# ---------------------------------------------------------------------------
# Systemd services
# ---------------------------------------------------------------------------
# Enable and start services installed by tasks/packages.py.

for _service in host.data.system_services:
    systemd.service(
        name=f"Enable and start {_service}",
        service=_service,
        running=True,
        enabled=True,
        _sudo=True,
    )

# ---------------------------------------------------------------------------
# Locale
# ---------------------------------------------------------------------------
# Replace any existing LANG= line or append if missing.

files.line(
    name=f"Set system locale to {host.data.system_locale}",
    path="/etc/locale.conf",
    line="^LANG=",
    replace=f"LANG={host.data.system_locale}",
    _sudo=True,
)
