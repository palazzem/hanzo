#! /bin/bash

# Copyright (c) 2014-2019, Emanuele Palazzetti and contributors
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
ROOT_FOLDER=/root/hanzo/
REPOSITORY=https://github.com/palazzem/hanzo.git

# Prompt for mandatory parameters
read -p "Provide your full name: " HANZO_FULLNAME
read -p "Provide your username: " HANZO_USERNAME
read -p "Provide your email: " HANZO_EMAIL
read -s "Provide your SSH password (encrypt private key): " HANZO_SSH_PASSWORD

# System update and dependencies
echo "Updating the system..."; pacman -Syyu --noconfirm
echo "Installing dependencies..."; pacman -S sudo git ansible --noconfirm

# Install/Update Hanzo
echo "Preparing Hanzo..."
if [ ! -d "$ROOT_FOLDER" ]; then
    git clone "$REPOSITORY" "$ROOT_FOLDER"
    cd "$ROOT_FOLDER"
else
    cd "$ROOT_FOLDER"
    git pull
fi

# Orchestration
echo "Starting orchestration..."
ansible-playbook orchestrate.yml --connection=local

# Post-install script
echo "=================="
echo "Post-install steps"
echo "==================\n"

passwd $HANZO_USERNAME
chsh -s /bin/zsh $HANZO_USERNAME
