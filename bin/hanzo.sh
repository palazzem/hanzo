#!/bin/bash

# Settings
URL="https://github.com/palazzem/coder-config/"
WORKSPACE_NAME="hanzo"

# Configuration: update this section
export HANZO_FULLNAME=
export HANZO_USERNAME=
export HANZO_EMAIL=

# Helper functions
setup_keys() {
    # Get the fingerprint of the key
    FINGERPRINT=$(ssh-keygen -l -f ~/.ssh/id_ed25519.pub | awk '{print $2}')

    # Check if the key is already added
    if ! ssh-add -l | grep -q "$FINGERPRINT"; then
        ssh-add ~/.ssh/id_ed25519
    fi

    # Restart GPG service
    gpgconf --kill gpg-agent && gpg -K
}

cleanup_docker() {
    IMAGE_ID=$(docker images --format "{{.Repository}} {{.ID}}" | awk '$1 ~ /^vsc-content-/ {print $2}')
    devpod stop $WORKSPACE_NAME
    devpod delete $WORKSPACE_NAME
    docker rmi $IMAGE_ID
    docker builder prune -f
}

# Main command handling
case "$1" in
    ssh)
        setup_keys
        ;;
    up)
        orb start
        devpod up --gpg-agent-forwarding --id $WORKSPACE_NAME $URL
        setup_keys
        ;;
    down)
        devpod stop $WORKSPACE_NAME
        orb stop
        ;;
    recreate)
        orb start
        cleanup_docker
        devpod up --gpg-agent-forwarding --recreate --id $WORKSPACE_NAME $URL
        ;;
    destroy)
        orb start
        cleanup_docker
        ;;
    *)
        echo "Usage: hanzo {ssh|up|down|recreate|destroy}"
        exit 1
esac
