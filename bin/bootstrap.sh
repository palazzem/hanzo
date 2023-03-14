#! /bin/bash

# Copyright (c) 2014-2020, Emanuele Palazzetti and contributors
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

# Variables
ANSIBLE_VERSION=2.14.3
ANSIBLE_FOLDER="ansible-$ANSIBLE_VERSION"
REPOSITORY=https://github.com/palazzem/hanzo.git
OUT_FOLDER=/root/.hanzo/

# Helper functions

function get_env() {
    read -p "$1 " retval
    echo $retval
}

# Prompt for mandatory parameters
HANZO_FULLNAME=${HANZO_FULLNAME:-$(get_env "Provide your full name:")}; export HANZO_FULLNAME
HANZO_USERNAME=${HANZO_USERNAME:-$(get_env "Provide your username:")}; export HANZO_USERNAME
HANZO_EMAIL=${HANZO_EMAIL:-$(get_env "Provide your email:")}; export HANZO_EMAIL

# Install/Update Hanzo unless a folder is specified
if [[ -z "${HANZO_FOLDER}" ]]; then
    echo "Downloading/Updating Hanzo..."
    git clone "$REPOSITORY" "$OUT_FOLDER" 2> /dev/null || (cd "$OUT_FOLDER" ; git pull)
else
    echo "HANZO_FOLDER specified, skipping checkout..."
    OUT_FOLDER=$HANZO_FOLDER
fi

cd "$OUT_FOLDER"

# Install Ansible Portable if not available
if [ ! -d "$OUT_FOLDER/$ANSIBLE_FOLDER" ]; then
    echo "Installing Ansible Portable..."
    pacman -Sy tar python --noconfirm
    curl -L https://github.com/palazzem/ansible-portable/releases/download/$ANSIBLE_VERSION/ansible-$ANSIBLE_VERSION.tar.gz > /tmp/ansible.tar.gz
    curl -L https://github.com/kewlfft/ansible-aur/archive/v0.24.tar.gz > /tmp/aur.tar.gz
    tar -xf /tmp/ansible.tar.gz
    tar -xf /tmp/aur.tar.gz -C /tmp
    mkdir library
    mv /tmp/ansible-aur-0.24/aur.py ./library
    ln -s ansible $ANSIBLE_FOLDER/ansible-playbook
else
    echo "Ansible found in $OUT_FOLDER/$ANSIBLE_FOLDER, skipping installation..."
fi

# Orchestration
echo "Starting Hanzo orchestration..."
PYTHONPATH=$ANSIBLE_FOLDER python $ANSIBLE_FOLDER/ansible-playbook orchestrate.yml --connection=local --tags=$TAGS $EXTRA_ARGS

# Post-install script
echo "Executing post-install steps..."
chsh -s /bin/zsh $HANZO_USERNAME
