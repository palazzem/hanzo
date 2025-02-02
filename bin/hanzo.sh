#!/bin/bash

# Settings
URL="https://github.com/palazzem/coder-config/"
WORKSPACE_NAME="hanzo"

# Configuration: update this section
export HANZO_FULLNAME=
export HANZO_USERNAME=
export HANZO_EMAIL=

case "$1" in
    up)
        orb start
        devpod up --gpg-agent-forwarding --id $WORKSPACE_NAME $URL

        # Get the fingerprint of the key
        FINGERPRINT=$(ssh-keygen -l -f ~/.ssh/id_ed25519.pub | awk '{print $2}')

        # Check if the key is already added
        if ! ssh-add -l | grep -q "$FINGERPRINT"; then
            ssh-add ~/.ssh/id_ed25519
        fi

	    # Restart GPG service
	    echo "Reloading GPG agent"
	    gpgconf --kill gpg-agent && gpg -K
        ;;
    down)
        # Stop the workspace
        devpod stop $WORKSPACE_NAME
	    orb stop
        ;;
    recreate)
        # Recreate the workspace
	    orb start
        devpod stop $WORKSPACE_NAME
        devpod up --gpg-agent-forwarding --recreate --id $WORKSPACE_NAME $URL
        ;;
    destroy)
        # Destroy the workspace
        devpod delete $WORKSPACE_NAME
        ;;
    *)
        echo "Usage: hanzo {up|down|recreate|destroy}"
        exit 1
esac
