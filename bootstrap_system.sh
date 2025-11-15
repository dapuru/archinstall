#!/bin/bash

# see: https://wiki.archlinux.org/title/Installation_guide#
# https://archinstall.archlinux.page/installing/guided.html

# Base URL for configuration files
BASE_URL="https://raw.githubusercontent.com/dapuru/archinstall/refs/heads/main"
REPO_URL="https://github.com/dapuru/archinstall.git"
DOT_URL="https://github.com/dapuru/dotfiles.git"

echo "Setting defaults..."
# loadkeys DE
loadkeys de-latin1
# Verify boot-mode
# cat /sys/firmware/efi/fw_platform_size

# Update system clock
timedatectl set-timezone Europe/Berlin
timedatectl set-ntp true

# add vim and wget
sudo pacman -Sy vim wget

# Getting installation type

read -p "Enter installation type ([s]erver, [d]esktop, [v]m): " installation_type

# Determine configuration file URL based on installation type
case "$installation_type" in
    s)
        config_url="${BASE_URL}/user_configuration_server.json"
        ;;
    d)
        config_url="${BASE_URL}/user_configuration_desktop.json"
        ;;
    v)
        config_url="${BASE_URL}/user_configuration_vm.json"
        ;;
    *)
        echo "Invalid installation type. Exiting..."
        exit 1
        ;;
esac
echo "Using configuration file: $config_url"

# Download configuration with integrity check
if ! wget "$config_url" -O "user_config.json"; then
    log "Failed to download configuration."
    exit 1
fi


read -p "Enter root password: " root_password
read -p "Enter user name: " username
read -p "Enter user password: " password
read -p "Enter encryption password: " encryption_password

# write config
echo "Writing UserCredentials..."

cat << EOF > user_credentials.json	
{
    "!root_password": "${root_password}",
    "!users": [
        {
            "!password": "${password}",
            "sudo": true,
            "username": "${username}"
        }
    ],
    "encryption_password": "${encryption_password}"
}
EOF

echo "Starting archinstall..."
read -p "Do you want to run archinstall now? (y/n)" run_archinstall

if [ "$run_archinstall" == "y" ]; then
    archinstall --config "user_config.json" --creds user_credentials.json
else
    exit 1
fi

echo "*************** Installation completed successfully. Starting re-works **************"

read -p "Cloning repositories to arch-chroot (y/n)" clone_repos
if [ "$clone_repos" != "y" ]; then
	exit
fi

# clone complete repos
git clone $REPO_URL /mnt/home/$USER/archinstall
git clone $DOT_URL /mnt/home/$USER/dotfiles

# install packages
read -p "Do you want to install packages? (y/n)" install_packages    
if [ "$install_packages" == "y" ]; then
	echo "Installing packages..."
	pacman -S --needed - < /home/$USER/archinstall/pkglist.txt
fi

# install dotfiles
read -p "Do you want to install dotfiles? (y/n)" install_dotfiles
if [ "$install_dotfiles" == "y" ]; then
	echo "Installing dotfiles..."
	cd /home/$USER/dotfiles
	stow *
fi


# Do you want to reboot?
read -p "Do you want to reboot? (y/n)" reboot
if [ "$reboot" == "y" ]; then
	echo "Rebooting..."
	reboot
fi

