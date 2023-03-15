terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.6.20"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Providers configuration
provider "coder" {
  feature_use_managed_variables = "true"
}

provider "docker" {
}

data "coder_provisioner" "dev" {
}

data "coder_workspace" "dev" {
}

# Template variables
data "coder_parameter" "rotation_time" {
  type        = "number"
  name        = "Rotation time"
  description = "Hours before dispose the image and force a rebuild (default: 1 week)"
  default     = 168

  validation {
    min = 0
    max = 336
  }
}

data "coder_parameter" "username" {
  type        = "string"
  name        = "Username"
  description = "Used to create your user account within the devenv"
}

data "coder_parameter" "fullname" {
  type        = "string"
  name        = "Full name"
  description = "Used in git commits"
}

data "coder_parameter" "email" {
  type        = "string"
  name        = "Email"
  description = "Used in git commits"
}

# Used as a trigger to start a container rebuild
resource "time_rotating" "rotation_hours" {
  rotation_hours = data.coder_parameter.rotation_time.value
}

# Workspace definition
resource "docker_network" "private_network" {
  name = "network-${data.coder_workspace.dev.id}-${data.coder_workspace.dev.name}"
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.dev.arch
  os             = "linux"

  login_before_ready     = false
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e

    # Install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.8.3
    EXTENSIONS_GALLERY='{"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery","cacheUrl": "https://vscode.blob.core.windows.net/gallery/index","itemUrl": "https://marketplace.visualstudio.com/items"}' /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/${data.coder_parameter.username.value}"
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
  # Home folder persists until the workspace is deleted
  name = "coder-${data.coder_workspace.dev.id}-home"

  lifecycle {
    ignore_changes = all
  }
}

resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.dev.id}"

  build {
    context  = "./build"
    no_cache = true

    # Hanzo configuration
    build_args = {
      HANZO_USERNAME : "${data.coder_parameter.username.value}"
      HANZO_FULLNAME : "${data.coder_parameter.fullname.value}"
      HANZO_EMAIL    : "${data.coder_parameter.email.value}"
    }
  }

  # Triggers a rebuild if the Dockerfile changes, or based on configuration
  triggers = {
    dir_sha1      = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
    time_rotation = time_rotating.rotation_hours.unix
  }
}

locals {
  container_name = "coder-${data.coder_workspace.dev.id}-${lower(data.coder_workspace.dev.name)}"
}

resource "docker_container" "workspace" {
  name     = "${local.container_name}"
  image    = docker_image.main.name

  count    = data.coder_workspace.dev.start_count
  hostname = lower(data.coder_workspace.dev.name)
  dns      = ["1.1.1.1"]

  command  = [
    "sh", "-c",
    <<EOT
    trap '[ $? -ne 0 ] && echo === Agent script exited with non-zero code. Sleeping infinitely to preserve logs... && sleep infinity' EXIT
    ${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}
    EOT
  ]

  env      = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "WORKSPACE_CONTAINER_ID=${local.container_name}",
  ]

  networks_advanced {
    name = docker_network.private_network.name
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    # Home folder
    container_path = "/home/${data.coder_parameter.username.value}/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  volumes {
    # Docker socket to run sibling containers
    container_path = "/var/run/docker.sock"
    host_path      = "/var/run/docker.sock"
    read_only      = true
  }
}
