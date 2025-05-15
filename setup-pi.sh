#!/bin/bash
# setup-pi.sh - Initial setup script for Raspberry Pi 5
#
# Copyright (c) Pablo Pin - devidence.dev
# Licensed for personal and educational use only. See README for details.
# This script is provided "as-is" without any warranty.
# You are free to modify and distribute this script for personal use.
#
set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

step() {
  echo -e "${BLUE}➡️  $1${RESET}"
}
success() {
  echo -e "${GREEN}✅ $1${RESET}"
}
info() {
  echo -e "${CYAN}ℹ️  $1${RESET}"
}
warn() {
  echo -e "${YELLOW}⚠️  $1${RESET}"
}

step "[1/7] Updating the system... 🛠️"
sudo apt update && sudo apt full-upgrade -y
success "System updated!"

step "[2/7] Installing dependencies for Docker... 📦"
sudo apt-get install -y ca-certificates curl
success "Dependencies installed!"

step "[3/7] Adding Docker's official GPG key... 🔑"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
success "GPG key added!"

step "[4/7] Adding Docker repository to Apt sources... 🐳"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
success "Docker repository added!"

step "[5/7] Installing Docker and plugins... 🐋"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
success "Docker and plugins installed!"

step "[6/7] Creating docker group (if it doesn't exist)... 👥"
sudo groupadd docker || true
success "Docker group ready!"

step "[7/7] Adding current user to docker group... 👤"
sudo usermod -aG docker $USER
success "User added to docker group!"

step "Installing Neovim... ✨"
sudo apt-get install -y neovim
success "Neovim installed!"

info "\n${GREEN}🎉 Automatic setup completed!${RESET}"
warn "\nManual steps required:"
echo -e "${YELLOW}1. Run: sudo raspi-config to:${RESET}"
echo -e "   - Expand filesystem (Advanced Options > Expand Filesystem)"
echo -e "   - Enable autologin (System Options > Boot / Auto Login > Console Autologin)"
echo -e "   - Set localization (Locale, Timezone, Keyboard, WLAN Country)"
echo -e "${YELLOW}2. Run: sudo nmtui to configure a static IP if desired.${RESET}"
echo -e "${YELLOW}3. Reboot the Raspberry Pi: sudo reboot${RESET}"
echo -e "${YELLOW}4. Run: newgrp docker or log out and log back in to use Docker without sudo.${RESET}"
info "\nDone! Check the README for more details."
