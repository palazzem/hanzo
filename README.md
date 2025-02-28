# Hanzō

> Hattori Hanzō: You must have big rats if you need Hattori Hanzo's steel.
> The Bride: ...Huge.

[![Testing](https://github.com/palazzem/hanzo/actions/workflows/test.yaml/badge.svg)](https://github.com/palazzem/hanzo/actions/workflows/test.yaml)
[![Nightly builds](https://github.com/palazzem/hanzo/actions/workflows/nightly.yaml/badge.svg)](https://github.com/palazzem/hanzo/actions/workflows/nightly.yaml)

Hanzo is a CLI tool that helps you set up and manage development environments using DevPod. It provides a streamlined
workflow for creating, connecting to, and managing containerized development workspaces.

## Requirements

- Any Docker Engine (e.g [Docker Desktop](https://www.docker.com/products/docker-desktop/), [OrbStack](https://orbstack.dev/), etc...)
- [DevPod](https://devpod.sh/)

## Quickstart

If you like living on the bleeding edge and *curlbombs* don't scare you, the automatic installer is the easiest way to get started:

```shell
$ sh <(curl -L http://j.mp/hattori-hanzo)
```

This will install Hanzo in your `~/.local/bin` directory. Make sure this directory is in your PATH.

After installation, you'll need to configure Hanzo with your personal information:

```shell
$ hanzo config init
```

This will guide you through setting up your name, username, and email address.

## Manual Installation

In case you don't want to use the `curl` command above, you can clone or download this repository, using either `git`
or the [release page](https://github.com/palazzem/hanzo/releases). Run the following commands:

```shell
$ git clone https://github.com/palazzem/hanzo
$ cd hanzo/
$ bash bin/bootstrap.sh
```

## Using Hanzo

Hanzo provides several commands to manage your development environment:

```shell
$ hanzo help                 # Show help information
$ hanzo config               # Show current configuration
$ hanzo config init          # Interactive configuration setup
$ hanzo config set KEY VALUE # Set a specific configuration value
$ hanzo up                   # Start your development workspace
$ hanzo ssh                  # Connect to your workspace via SSH
$ hanzo down                 # Stop your workspace
$ hanzo recreate             # Recreate your workspace
$ hanzo destroy              # Destroy your workspace
$ hanzo status               # Check workspace status
```

## Unattended Configuration

If you don't want to use the interactive configuration, you can set the following environment variables:

* `HANZO_FULLNAME`: your full name used in Git configurations.
* `HANZO_USERNAME`: your username for the workspace.
* `HANZO_EMAIL`: your email address used in Git configurations.

You can also set these values directly using the config command:

```shell
$ hanzo config set fullname "Your Name"
$ hanzo config set username yourusername
$ hanzo config set email your.email@example.com
```

## Contribute

This tool is designed to streamline my personal development workflow. Because it's unlikely that you use exactly
my current environment, you may use this repository as a base to create your own configuration. Indeed, I'll be glad
to accept any PR that:

* Fixes bugs or issues in the current implementation
* Improves the script structure or bash best practices
* Enhances or makes me aware of different methods to manage development environments

I will not merge pull requests that add new development tools, but I will be grateful if you can discuss about it
in the [issue tracker](https://github.com/palazzem/hanzo/issues).
