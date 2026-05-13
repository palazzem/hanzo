"""Hardware fixes for ASUS ROG Flow Z13 (GZ302).

Applies GPU, display, suspend, input, and peripheral fixes for the Strix
Halo platform. This task file is only included by deploy.py when DMI
detection confirms GZ302 hardware -- it assumes it should run if included.

Fixes applied:
    - GPU modprobe: ppfeaturemask, abmlevel, sg_display, cwsr_enable
    - HID modprobe: fnlock_default=0
    - OLED kernel param: amdgpu.dcdebugmask=0x600 in /etc/kernel/cmdline
    - Initramfs rebuild: mkinitcpio -P (only when modprobe/cmdline changed)
    - Suspend hook: NHI, xHCI, HID, MMC fixes for reliable s2idle
    - Keyboard hwdb: Copilot key -> KEY_PROG1
    - RGB udev rule: unprivileged USB access for rog-control-center
"""

from pyinfra import host
from pyinfra.operations import files, server
from pyinfra.operations.util import any_changed

# ---------------------------------------------------------------------------
# GPU modprobe configuration
# ---------------------------------------------------------------------------
# Disables GFXOFF (ppfeaturemask), ABM (abmlevel), scatter-gather display
# (sg_display), and CWSR (cwsr_enable) to prevent GPU hangs and OLED
# flicker on the Radeon 8060S (RDNA 3.5) iGPU.

gpu_config = files.template(
    name="Deploy GPU modprobe config",
    src="templates/amdgpu.conf.j2",
    dest="/etc/modprobe.d/amdgpu.conf",
    mode="0644",
    _sudo=True,
)

# ---------------------------------------------------------------------------
# HID modprobe configuration
# ---------------------------------------------------------------------------
# Sets fnlock_default=0 so F-row keys act as media keys by default.

hid_config = files.template(
    name="Deploy HID modprobe config",
    src="templates/hid_asus.conf.j2",
    dest="/etc/modprobe.d/hid_asus.conf",
    mode="0644",
    _sudo=True,
)

# ---------------------------------------------------------------------------
# OLED kernel param (cmdline)
# ---------------------------------------------------------------------------
# Appends amdgpu.dcdebugmask=0x600 to /etc/kernel/cmdline to disable
# PSR-SU and Panel Replay. Prevents scrolling artifacts and flicker on
# the OLED panel. files.line handles "replace existing or append if
# missing" -- if a different dcdebugmask value exists, it's replaced.

oled_param = files.line(
    name="Ensure OLED kernel param in cmdline",
    path="/etc/kernel/cmdline",
    line=r"amdgpu\.dcdebugmask=",
    replace=host.data.gz302_oled_kernel_param,
    _sudo=True,
)

# ---------------------------------------------------------------------------
# Initramfs rebuild (conditional)
# ---------------------------------------------------------------------------
# CachyOS uses early KMS (amdgpu in MODULES=() in mkinitcpio.conf) and
# UKIs (kernel cmdline baked from /etc/kernel/cmdline). Changes to
# modprobe.d or cmdline require mkinitcpio -P to take effect on reboot.
# Only rebuild when at least one config actually changed.

server.shell(
    name="Rebuild initramfs (modprobe or cmdline changed)",
    commands=["mkinitcpio -P"],
    _sudo=True,
    _if=any_changed(gpu_config, hid_config, oled_param),
)

# ---------------------------------------------------------------------------
# Suspend/resume hook
# ---------------------------------------------------------------------------
# Installs the systemd-sleep hook that handles NHI wakeup, xHCI wakeup
# races, ASUS HID ENOMEM, and MMC Power Off Notify timeout.

files.template(
    name="Deploy suspend/resume hook",
    src="templates/gz302-suspend.sh.j2",
    dest="/usr/lib/systemd/system-sleep/gz302-suspend.sh",
    mode="0755",
    _sudo=True,
)

# ---------------------------------------------------------------------------
# Keyboard hwdb remap
# ---------------------------------------------------------------------------
# Remaps the Copilot key to KEY_PROG1 for Hyprland binding.

files.template(
    name="Deploy keyboard hwdb remap",
    src="templates/90-gz302-keyboard.hwdb.j2",
    dest="/etc/udev/hwdb.d/90-gz302-keyboard.hwdb",
    mode="0644",
    _sudo=True,
)

server.shell(
    name="Update hwdb and trigger udev (keyboard remap)",
    commands=["systemd-hwdb update && udevadm trigger"],
    _sudo=True,
)

# ---------------------------------------------------------------------------
# RGB udev rule
# ---------------------------------------------------------------------------
# Grants unprivileged USB access for rog-control-center RGB control.

files.template(
    name="Deploy RGB udev rule",
    src="templates/99-gz302-rgb.rules.j2",
    dest="/etc/udev/rules.d/99-gz302-rgb.rules",
    mode="0644",
    _sudo=True,
)

server.shell(
    name="Reload udev rules (RGB)",
    commands=["udevadm control --reload-rules && udevadm trigger"],
    _sudo=True,
)
