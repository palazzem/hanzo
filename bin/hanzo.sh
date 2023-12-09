#!/bin/bash

# Configuration Variables
WORKSPACE_NAME="hanzo"
URL=
HANZO_FULLNAME=
HANZO_USERNAME=
HANZO_EMAIL=

case "$1" in
    up)
        echo "Running hanzo up..."
        devpod up --id $WORKSPACE_NAME $URL
        devpod ssh --gpg-agent-forwarding --agent-forwarding $WORKSPACE_NAME
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
        echo "Usage: hanzo {up|down|update|destroy}"
        exit 1
esac
