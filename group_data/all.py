"""Package lists and configuration data for Hanzo provisioner.

pyinfra automatically loads this file and exposes every top-level variable
as an attribute on ``host.data`` inside task files. For example,
``base_packages`` below becomes ``host.data.base_packages``.
"""

base_packages = [
    "base-devel",
    "git",
    "fzf",
    "htop",
    "neovim",
    "fastfetch",
    "tree",
    "wget",
    "jq",
    "yq",
    "httpie",
    "openssl",
    "gettext",
    "gdb",
    "plocate",
    "procps-ng",
    "sudo",
    # Provides dig, nslookup, and other DNS lookup utilities.
    # Note: this installs the full BIND package (named daemon included but not enabled).
    "bind",
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
    "gst-plugins-good",
    "gst-plugins-bad",
    "gst-plugins-ugly",
    "gst-libav",
]

aur_packages = [
    "fnm-bin",
]

# Consumed by tasks/tools.py (Phase 2) — pipx install for each tool.
pipx_tools = [
    "ipython",
    "hatch",
    "pre-commit",
    "checkov",
]
