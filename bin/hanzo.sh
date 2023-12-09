#!/bin/bash

# Configuration
URL=
WORKSPACE_NAME="hanzo"
export HANZO_FULLNAME=
export HANZO_USERNAME=
export HANZO_EMAIL=

case "$1" in
    ssh)
        echo "Running hanzo ssh..."
        devpod ssh --gpg-agent-forwarding --agent-forwarding $WORKSPACE_NAME
        ;;
    up)
        echo "Running hanzo up..."
        devpod up --id $WORKSPACE_NAME $URL
        ;;
    down)
        echo "Running hanzo down..."
        devpod stop $WORKSPACE_NAME
        ;;
    update)
        echo "Running hanzo update..."
        devpod stop $WORKSPACE_NAME
        devpod delete coder-config
        docker rmi $(docker images | grep "coder-config" | awk '{print $3}')
        ;;
    destroy)
        echo "Running hanzo destroy..."
        devpod delete $WORKSPACE_NAME
        docker rmi $(docker images | grep "$WORKSPACE_NAME" | awk '{print $3}')
        ;;
    *)
        echo "Usage: hanzo {ssh|up|down|update|destroy}"
        exit 1
esac
