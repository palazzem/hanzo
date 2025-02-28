#! /bin/bash

# Copyright (c) 2014-2023, Emanuele Palazzetti and contributors
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of the FreeBSD Project.

set -e

# Helper functions
function get_env() {
    read -p "$1 " retval
    echo $retval
}

# Prompt for mandatory parameters
HANZO_FULLNAME=${HANZO_FULLNAME:-$(get_env "Provide your full name:")}; export HANZO_FULLNAME
HANZO_USERNAME=${HANZO_USERNAME:-$(get_env "Provide your username:")}; export HANZO_USERNAME
HANZO_EMAIL=${HANZO_EMAIL:-$(get_env "Provide your email:")}; export HANZO_EMAIL

# Prepare the build folder where dependencies and Hanzo are downloaded.
# Permissions are set to 666 as nothing is sensitive in the folder and
# Hanzo needs broader permissions when `become_user` is used.
BUILD_FOLDER=$(mktemp -d); export BUILD_FOLDER
chmod 666 -R $BUILD_FOLDER
echo "Using BUILD_FOLDER: $BUILD_FOLDER"

# Variables
REPOSITORY="https://github.com/palazzem/hanzo.git"
ANSIBLE_FOLDER="$BUILD_FOLDER/ansible"

# System update
echo "Updating system Arch Linux..."
pacman -Syu --noconfirm

# Install dependencies
echo "Installing dependencies..."
pacman -Sy --noconfirm \
  git \
  python \
  python-pip

# Install/Update Hanzo unless a folder is specified
if [[ -z "$HANZO_FOLDER" ]]; then
    echo "Downloading/Updating Hanzo..."
    HANZO_FOLDER="$BUILD_FOLDER/hanzo"
    git clone "$REPOSITORY" "$HANZO_FOLDER" 2> /dev/null || (cd "$HANZO_FOLDER" ; git pull)
else
    echo "HANZO_FOLDER specified, skipping checkout..."
fi

cd "$HANZO_FOLDER"

# Install Ansible and configure collections
pip install ansible-core --target $ANSIBLE_FOLDER --progress-bar off
PYTHONPATH=$ANSIBLE_FOLDER $ANSIBLE_FOLDER/bin/ansible-galaxy collection install -r requirements.yml

# Orchestration
echo "Starting Hanzo orchestration..."
PYTHONPATH=$ANSIBLE_FOLDER $ANSIBLE_FOLDER/bin/ansible-playbook orchestrate.yml --connection=local --inventory inventory.yml --tags=$TAGS $EXTRA_ARGS

# Post-install script
echo "Executing post-install steps..."
chsh -s /bin/zsh $HANZO_USERNAME

# Clean-up: remove temporary folders and cache
echo "Clean-up temporary folders..."
rm -rf \
    $HANZO_FOLDER \
    $BUILD_FOLDER \
    /root/.ansible \
    /root/.cache
find /var/cache/pacman/ -type f -delete

echo "Setup completed!"
