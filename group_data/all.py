"""Package lists and configuration data for Hanzo provisioner.

pyinfra automatically loads this file and exposes every top-level variable
as an attribute on ``host.data`` inside task files. For example,
``base_packages`` below becomes ``host.data.base_packages``.
"""

base_packages = [
    "fzf",
    "htop",
    "neovim",
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
