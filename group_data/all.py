"""Package lists and configuration data for Hanzo provisioner.

pyinfra automatically loads this file and exposes every top-level variable
as an attribute on ``host.data`` inside task files. For example,
``base_packages`` below becomes ``host.data.base_packages``.
"""

base_packages = [
    "fzf",
    "htop",
    "neovim",
    "python-pipx",
    "tree",
    "wget",
    "jq",
    "yq",
    "httpie",
    "whois",
    "tmux",
]

docker_packages = [
    "docker",
    "docker-buildx",
    "docker-compose",
]

archive_packages = [
    "7zip",
    "unrar",
]

ai_packages = [
    "ollama-rocm",
]

audio_packages = [
    "sof-firmware",
]

asus_packages = [
    "asusctl",
    "rog-control-center",
]

runtime_packages = [
    "rustup",
    "go",
]

gaming_packages = [
    "cachyos-gaming-applications",
    "ffmpeg",
]

aur_packages = [
    "fnm-bin",
]

# ---------------------------------------------------------------------------
# System configuration (tasks/system.py)
# ---------------------------------------------------------------------------

# Only groups not managed by the kernel or package scripts.
# render and video are kernel/udev-managed and always exist.
system_groups = [
    "docker",
]

# Supplementary groups to add the current user to.
# Includes system_groups (which we create) plus kernel-managed groups.
user_groups = system_groups + [
    "render",
    "video",
]

# Systemd services to enable at boot and start.
system_services = [
    "docker",
    "ollama",
    "asusd",
]

# Default locale — matches CachyOS installer defaults for US English.
system_locale = "en_US.UTF-8"

dotfiles_repo = "https://github.com/palazzem/dotfiles.git"
dotfiles_dir = "~/.dotfiles"

# ---------------------------------------------------------------------------
# GZ302 (ASUS ROG Flow Z13) hardware configuration
# ---------------------------------------------------------------------------
# OLED kernel param disables PSR-SU and Panel Replay to prevent scrolling
# artifacts and flicker on the Strix Halo OLED panel (kernel 7.0+).
gz302_oled_kernel_param = "amdgpu.dcdebugmask=0x600"

# ASUS USB identifiers for keyboard, touchpad, and lightbar devices.
# Used by suspend hook (USB reset, HID unbind), hwdb (key remap), and
# udev rule (RGB).
gz302_asus_usb_vendor = "0b05"
gz302_asus_keyboard_product = "1a30"
gz302_asus_lightbar_product = "18c6"

# Keyboard hwdb remap: Copilot key -> KEY_PROG1.
# Bound in Hyprland to launch alacritty -e claude.
gz302_keyboard_scancode = "70072"
gz302_keyboard_target_key = "prog1"

pipx_tools = [
    "ipython",
    "hatch",
    "pre-commit",
    "checkov",
]

infra_aur_packages = [
    "terraform",
    "packer",
]

go_tools = {
    "tfupdate": "github.com/minamijoyo/tfupdate@latest",
}

npm_global_packages = [
    "@anthropic-ai/claude-code",
]

gopath = "~/programs/go"
