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

# Create a fresh ArchLinux LXC container
lxc delete penguin --force || true
run_container.sh --container_name penguin --lxd_image archlinux/current --lxd_remote https://us.images.linuxcontainers.org/
echo "Waiting the container to be up and running... (5s)"; sleep 5s

# Address DNS resolution error: https://wiki.archlinux.org/index.php/Chrome_OS_devices/Crostini#DNS_resolution_not_working
lxc exec penguin -- sh -c "sed -i 's/hosts.*/hosts: files dns/g' /etc/nsswitch.conf"
lxc exec penguin -- sh -c "ping -c 4 google.com"
echo "LXC container connected to the Internet!"

# Launch Hanzo bootstrap
echo "Downloading Hanzo bootstrap..."
lxc exec penguin -- sh -c "curl -L https://raw.githubusercontent.com/palazzem/hanzo/master/bin/bootstrap.sh > /tmp/hanzo-installer.sh; TAGS=chromeos bash /tmp/hanzo-installer.sh"

# Stop the container so it's ready for use at the next start
lxc stop penguin
