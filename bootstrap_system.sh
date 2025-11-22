#!/bin/bash

# see: https://wiki.archlinux.org/title/Installation_guide#
# https://archinstall.archlinux.page/installing/guided.html

# Base URL for configuration files
BASE_URL="https://raw.githubusercontent.com/dapuru/archinstall/refs/heads/main"
REPO_URL="https://github.com/dapuru/archinstall.git"
DOT_URL="https://github.com/dapuru/dotfiles.git"
DEFAULT_USER="daniel"

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

echo "Enter root password: "
read -p -s root_password
echo "Re-Enter root password: "
read -p -s root_password_comp

if [ "$root_password" != "$root_password_comp" ]; then
    echo "passwords do not match!"
    exit 1
fi

read -p "Enter user name: " username

echo "Enter user password: "
read -p -s password
echo "Re-Enter user password: "
read -p -s user_password_comp

if [ "$password" != "$user_password_comp" ]; then
    echo "passwords do not match!"
    exit 1
fi

echo "Enter encryption password: "
read -p -s encryption_password
echo "Re-Enter encryption password: "
read -p -s encryption_password_comp

if [ "$encryption_password" != "$encryption_password_comp" ]; then
    echo "passwords do not match!"
    exit 1    
fi

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
    else
        clone complete repos
        git clone $REPO_URL /mnt/home/$DEFAULT_USER/archinstall
        #git clone $DOT_URL /mnt/home/$DEFAULT_USER/dotfiles
fi

# reworks
read -p "Do you want to chroot and run reworks? (y/n)" do_reworks
if [ "$do_reworks" == "y" ]; then
	echo "Chroot and run reworks..."
        chroot /mnt /bin/bash -c "cd /home/$DEFAULT_USER/archinstall && ./reworks.sh"	
fi


# Do you want to reboot?
read -p "Do you want to reboot? (y/n)" reboot
if [ "$reboot" == "y" ]; then
	echo "Rebooting..."
	reboot
fi

