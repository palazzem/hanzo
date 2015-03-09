#! /bin/bash

# Copyright (c) 2014, Emanuele Palazzetti and contributors
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

### Variables
ROOT_FOLDER=/root/ansible-devel/
REPOSITORY=https://github.com/palazzem/ansible-devel.git

### Setup tools
function msg {
    printf '%b\n' "$1" >&2
}

function success {
    if [ "$ret" -eq '0' ]; then
        msg "\e[32m[✔]\e[0m ${1}${2}"
    fi
}

### Requiring environment variables
read -p "Provide your full name: " FULLNAME < /dev/tty
read -p "Provide your username: " USERNAME < /dev/tty
read -p "Provide your email: " EMAIL < /dev/tty

# Installing dependencies
echo "Installing dependencies..."
pacman -S ansible git --noconfirm

echo "Cloning ansible-devel repository..."
git clone "$REPOSITORY" "$ROOT_FOLDER"

# Proceeding with orchestration
echo "Starting orchestration..."
cd "$ROOT_FOLDER"
ansible-playbook orchestrate.yml -i inventory --connection=local -e "fullname=$FULLNAME email=$EMAIL username=$USERNAME"
ansible-playbook orchestrate.yml -i inventory --connection=local -e "username=$USERNAME"

success "Configuration completed!"
echo "Remember to launch the following command:"
echo "passwd $USERNAME"

