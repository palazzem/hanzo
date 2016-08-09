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
ROOT_FOLDER=$HOME/.hanzo
REPO_FOLDER=$ROOT_FOLDER/hanzo
REPOSITORY=https://github.com/palazzem/hanzo.git
README=https://raw.githubusercontent.com/palazzem/hanzo/master/README.rst
DATA_STORE=$HOME/.hanzo/hanzo.conf

### using strap.sh to initialize the system

# Keep sudo timestamp updated while Strap is running.
if [ "$1" = "--sudo-wait" ]; then
  while true; do
    mkdir -p "/var/db/sudo/$SUDO_USER"
    touch "/var/db/sudo/$SUDO_USER"
    sleep 1
  done
  exit 0
fi

[ "$1" = "--debug" ] && STRAP_DEBUG="1"
STRAP_SUCCESS=""

cleanup() {
  set +e
  if [ -n "$STRAP_SUDO_WAIT_PID" ]; then
    sudo kill "$STRAP_SUDO_WAIT_PID"
  fi
  sudo -k
  rm -f "$CLT_PLACEHOLDER"
  if [ -z "$STRAP_SUCCESS" ]; then
    if [ -n "$STRAP_STEP" ]; then
      echo "!!! $STRAP_STEP FAILED" >&2
    else
      echo "!!! FAILED" >&2
    fi
    if [ -z "$STRAP_DEBUG" ]; then
      echo "!!! Run '$0 --debug' for debugging output." >&2
      echo "!!! If you're stuck: file an issue with debugging output at:" >&2
      echo "!!!   $STRAP_ISSUES_URL" >&2
    fi
  fi
}

trap "cleanup" EXIT

if [ -n "$STRAP_DEBUG" ]; then
  set -x
else
  STRAP_QUIET_FLAG="-q"
  Q="$STRAP_QUIET_FLAG"
fi

STDIN_FILE_DESCRIPTOR="0"
[ -t "$STDIN_FILE_DESCRIPTOR" ] && STRAP_INTERACTIVE="1"

STRAP_FULL_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

abort() { STRAP_STEP="";   echo "!!! $*" >&2; exit 1; }
log()   { STRAP_STEP="$*"; echo "--> $*"; }
logn()  { STRAP_STEP="$*"; printf -- "--> $* "; }
logk()  { STRAP_STEP="";   echo "OK"; }

sw_vers -productVersion | grep $Q -E "^10.(9|10|11|12)" || {
  abort "Run Strap on Mac OS X 10.9/10/11/12."
}

[ "$USER" = "root" ] && abort "Run Strap as yourself, not root."
groups | grep $Q admin || abort "Add $USER to the admin group."

### Retrieving installation parameters

USERNAME="$USER"

if [ ! -f "$DATA_STORE" ]; then
    # we don't have a previous run, so ask for developer's data
    read -p "Provide your full name: " FULLNAME
    read -p "Provide your email: " EMAIL

    # save data for the next run
    mkdir -p "$ROOT_FOLDER"
    echo "export FULLNAME='$FULLNAME'" > $DATA_STORE
    echo "export EMAIL='$EMAIL'" >> $DATA_STORE
else
    # this is not the first time so we load the content
    # from the file
    source "$DATA_STORE"
fi

# Initialise sudo now to save prompting later.
log "Enter your password (for sudo access):"
sudo -k
sudo /usr/bin/true
[ -f "$STRAP_FULL_PATH" ]
sudo bash "$STRAP_FULL_PATH" --sudo-wait &
STRAP_SUDO_WAIT_PID="$!"
ps -p "$STRAP_SUDO_WAIT_PID" &>/dev/null
logk

# Set some basic security settings.
logn "Configuring security settings:"
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled \
  -bool false
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles \
  -bool false
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null

if [ -n "$FULLNAME" ] && [ -n "$EMAIL" ]; then
  sudo defaults write /Library/Preferences/com.apple.loginwindow \
    LoginwindowText \
    "Found this computer? Please contact $FULLNAME at $EMAIL."
fi
logk

# Check and enable full-disk encryption.
logn "Checking full-disk encryption status:"
if fdesetup status | grep $Q -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
  logk
elif [ -n "$STRAP_INTERACTIVE" ]; then
  echo
  log "Enabling full-disk encryption on next reboot:"
  sudo fdesetup enable -user "$USER" \
    | tee ~/Desktop/"FileVault Recovery Key.txt"
  logk
else
  echo
  abort "Run 'sudo fdesetup enable -user \"$USER\"' to enable full-disk encryption."
fi

# Install the Xcode Command Line Tools.
DEVELOPER_DIR=$("xcode-select" -print-path 2>/dev/null || true)
[ -z "$DEVELOPER_DIR" ] || ! [ -f "$DEVELOPER_DIR/usr/bin/git" ] \
                        || ! [ -f "/usr/include/iconv.h" ] && {
  log "Installing the Xcode Command Line Tools:"
  CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  sudo touch "$CLT_PLACEHOLDER"
  CLT_PACKAGE=$(softwareupdate -l | \
                grep -B 1 -E "Command Line (Developer|Tools)" | \
                awk -F"*" '/^ +\*/ {print $2}' | sed 's/^ *//' | head -n1)
  sudo softwareupdate -i "$CLT_PACKAGE"
  sudo rm -f "$CLT_PLACEHOLDER"
  if ! [ -f "/usr/include/iconv.h" ]; then
    if [ -n "$STRAP_INTERACTIVE" ]; then
      echo
      logn "Requesting user install of Xcode Command Line Tools:"
      xcode-select --install
    else
      echo
      abort "Run 'xcode-select --install' to install the Xcode Command Line Tools."
    fi
  fi
  logk
}

# Check if the Xcode license is agreed to and agree if not.
xcode_license() {
  if /usr/bin/xcrun clang 2>&1 | grep $Q license; then
    if [ -n "$STRAP_INTERACTIVE" ]; then
      logn "Asking for Xcode license confirmation:"
      sudo xcodebuild -license
      logk
    else
      abort "Run 'sudo xcodebuild -license' to agree to the Xcode license."
    fi
  fi
}
xcode_license

# Setup Homebrew directory and permissions.
logn "Installing Homebrew:"
HOMEBREW_PREFIX="/usr/local"
[ -d "$HOMEBREW_PREFIX" ] || sudo mkdir -p "$HOMEBREW_PREFIX"
sudo chown -R "$USER:admin" "$HOMEBREW_PREFIX"

# Download Homebrew.
export GIT_DIR="$HOMEBREW_PREFIX/.git" GIT_WORK_TREE="$HOMEBREW_PREFIX"
git init $Q
git config remote.origin.url "https://github.com/Homebrew/brew"
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch $Q --no-tags --depth=1 --force --update-shallow
git reset $Q --hard origin/master
unset GIT_DIR GIT_WORK_TREE
logk

# Update Homebrew.
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
log "Updating Homebrew:"
brew update
logk

# Install Homebrew Bundle, Cask, Services and Versions tap.
log "Installing Homebrew taps and extensions:"
brew bundle --file=- <<EOF
tap 'caskroom/cask'
tap 'homebrew/core'
tap 'homebrew/services'
tap 'homebrew/versions'
EOF
logk

# Check and install any remaining software updates.
logn "Checking for software updates:"
if softwareupdate -l 2>&1 | grep $Q "No new software available."; then
  logk
else
  echo
  log "Installing software updates:"
  sudo softwareupdate --install --all
  xcode_license
  logk
fi

STRAP_SUCCESS="1"

### Starting hanzo.sh
echo "--> Installing Ansible"
brew install python
pip install ansible

echo "--> Installing hanzo.sh"
if [ ! -d "$REPO_FOLDER" ]; then
    git clone "$REPOSITORY" "$REPO_FOLDER"
    cd "$REPO_FOLDER"/osx
else
    cd "$REPO_FOLDER"/osx
    git pull
fi

### The Orchestration
echo "--> Starting orchestration..."
ansible-playbook orchestrate.yml -i inventory --connection=local -e "fullname='$FULLNAME' email=$EMAIL username=$USERNAME"
echo "Configuration completed!"
