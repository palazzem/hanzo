#!/usr/bin/env bash

# Copyright (c) 2014-2025, Emanuele Palazzetti and contributors
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

# Colors for better visual output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}║                  ${GREEN}Hanzo Installer${BLUE}                       ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to handle errors
handle_error() {
    echo -e "${YELLOW}Error: $1${NC}"
    exit 1
}

# Create necessary directories
echo -e "📁 ${GREEN}Creating directories...${NC}"
mkdir -p ~/.local/bin || handle_error "Failed to create ~/.local/bin"
mkdir -p ~/.local/src || handle_error "Failed to create ~/.local/src"

# Check if hanzo is already installed
if [ -d ~/.local/src/hanzo ]; then
    echo -e "🔄 ${GREEN}Hanzo repository already exists. Updating...${NC}"
    cd ~/.local/src/hanzo && git pull || handle_error "Failed to update hanzo repository"
else
    echo -e "⬇️  ${GREEN}Cloning hanzo repository...${NC}"
    git clone https://github.com/palazzem/hanzo.git ~/.local/src/hanzo || handle_error "Failed to clone hanzo repository"
fi

# Create symlink (overwrite if exists)
echo -e "🔗 ${GREEN}Creating symlink...${NC}"
ln -sf ~/.local/src/hanzo/bin/hanzo.sh ~/.local/bin/hanzo || handle_error "Failed to create symlink"

# Check if PATH already contains ~/.local/bin
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "⚠️  ${YELLOW}~/.local/bin is not in your PATH${NC}"
    echo ""
    echo -e "${GREEN}Add the following line to your shell configuration file:${NC}"
    echo -e "${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
    echo -e "${GREEN}For example:${NC}"
    echo -e "  ${BLUE}bash${NC}: echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
    echo -e "  ${BLUE}zsh${NC} : echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo -e "  ${BLUE}fish${NC}: fish -c 'set -U fish_user_paths \$HOME/.local/bin \$fish_user_paths'"
else
    echo -e "✅ ${GREEN}~/.local/bin is already in your PATH${NC}"
fi

echo ""
echo -e "✅ ${GREEN}Installation complete!${NC}"
echo -e "🚀 ${GREEN}Run 'hanzo' to get started${NC}"
echo ""
