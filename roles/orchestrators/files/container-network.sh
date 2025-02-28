#!/bin/bash
set -e

# Helper script to join sibling containers' network. This is a generic use case
# when the development machine is an actual container that is in a different
# Docker network. Once the development box joins a network, it can access all
# containers fired-up with `docker-compose`.

# Helper function: detect container network
get_container_network() {
  docker-compose config | yq '.networks[].name' | tr -d '"'
}

# Handling command argument [connect|disconnect]
case "$1" in
  "connect"|"disconnect")
    # $WORKSPACE_CONTAINER_ID must be passed through Docker ENV. It defines the Workspace Container ID.
    [ -z "$WORKSPACE_CONTAINER_ID" ] && echo "Error: WORKSPACE_CONTAINER_ID must be set." && exit 1

    # Read Docker configuration and exit if it fails
    docker-compose config > /dev/null 2>&1 || echo "Error: you must be in a folder with a docker-compose.yml file." && exit 1

    # Detect container network
    NETWORK_NAME=$(get_container_network)

    # Connect/Disconnect to/from network
    docker network "$1" "$NETWORK_NAME" "$WORKSPACE_CONTAINER_ID"
    echo "${1^}ed to/from: $NETWORK_NAME"
    ;;
  *)
    echo "Usage: container-network [connect|disconnect]"
    exit 1
    ;;
esac
