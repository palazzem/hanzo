terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.6.12"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.22"
    }
  }
}

locals {
  username = data.coder_workspace.me.owner
  email = data.coder_workspace.me.owner_email
}

variable "rotation_time" {
  description = "Hours before dispose the image and force a rebuild (default: 1 week)"
  default = 168
  type = number

  validation {
    condition = var.rotation_time > 0
    error_message = "The value must be greater than 0."
  }
}

variable "hanzo_username" {
  description = "Your username used to configure your Linux account"
  type = string
}

variable "hanzo_fullname" {
  description = "Your full name used to configure Git"
  type = string
}

variable "hanzo_email" {
  description = "Your email used to configure Git"
  type = string
}

resource "time_rotating" "time_trigger" {
  rotation_hours = var.rotation_time
}

data "coder_provisioner" "me" {
}

provider "docker" {
}

data "coder_workspace" "me" {
}

resource "docker_network" "private_network" {
  name = "network-${data.coder_workspace.me.id}"
}

resource "docker_container" "dind" {
  image      = "docker:dind"
  privileged = true
  name       = "sidecar-${data.coder_workspace.me.id}"
  entrypoint = ["dockerd", "-H", "tcp://0.0.0.0:2375"]
  networks_advanced {
    name = docker_network.private_network.name
  }
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"

  login_before_ready     = false
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e

    # Export DOCKER_HOST variable in Hanzo user
    grep -qxF 'export DOCKER_HOST=${docker_container.dind.name}:2375' /home/${var.hanzo_username}/.zshenv \
      || echo 'export DOCKER_HOST=${docker_container.dind.name}:2375' >> /home/${var.hanzo_username}/.zshenv

    # Install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.8.3
    EXTENSIONS_GALLERY='{"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery","cacheUrl": "https://vscode.blob.core.windows.net/gallery/index","itemUrl": "https://marketplace.visualstudio.com/items"}' /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/${local.username}"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-home"
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.me.id}"

  build {
    path = "./build"

    # Hanzo configuration
    build_arg = {
      HANZO_USERNAME : "${var.hanzo_username}"
      HANZO_FULLNAME : "${var.hanzo_fullname}"
      HANZO_EMAIL    : "${var.hanzo_email}"
    }
  }

  # Triggers a rebuild if the Dockerfile changes, or every day
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
    every_day = formatdate("YYYY-MM-DD", time_rotating.time_trigger.id)
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  command = [
    "sh", "-c",
    <<EOT
    trap '[ $? -ne 0 ] && echo === Agent script exited with non-zero code. Sleeping infinitely to preserve logs... && sleep infinity' EXIT
    ${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}
    EOT
  ]
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "DOCKER_HOST=${docker_container.dind.name}:2375"
  ]
  networks_advanced {
    name = docker_network.private_network.name
  }
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${var.hanzo_username}/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
}
