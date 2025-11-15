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
#sudo pacman -Sy vim 

# Getting installation type

echo "Enter installation type (server, desktop, vm): " && read installation_type

# Determine configuration file URL based on installation type
case "$installation_type" in
    server)
        config_url="${BASE_URL}/user_configuration_server.json"
        ;;
    desktop)
        config_url="${BASE_URL}/user_configuration_desktop.json"
        ;;
    vm)
        config_url="${BASE_URL}/user_configuration_vm.json"
        ;;
    *)
        echo "Invalid installation type. Exiting..."
        exit 1
        ;;
esac

# Download configuration with integrity check
if ! wget "$config_url" -O "user_config.json"; then
    log "Failed to download configuration."
    exit 1
fi

# get config-files
echo "Using $installation_type ..."
echo "Do you want to revise the configuration? (y/n)"
read -r revise_config
if [ "$revise_config" == "y" ]; then
	vim user_config.json
fi

# setting hostname
#echo "Setting hostname..."
#echo "Enter hostname: "
#read hostname

# Function to get matching passwords
get_password() {
    while true; do
        echo "$1"
        read -s password
        echo "Re-enter password: "
        read -s re_password
        if [ "$password" == "$re_password" ]; then
            echo "$password"
            return
        else
            echo "Passwords do not match. Please try again."
        fi
    done
}

root_password=$(get_password "Enter root password: ")

username=""
while true; do
    echo "Enter username (no spaces): "
    read username
    if [[ "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
        break
    else
        echo "Invalid username. Please try again."
    fi
done

password=$(get_password "Enter password: ")
encryption_password=$(get_password "Enter encryption password: ")

# write config
echo "Writing UserConfig..."

cat << EOF > user_credentials.json	
{
    "!root-password": "${root_password}",
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


# Start archinstall
if ! archinstall --config "user_config.json" --creds user_credentials.json; then
    log "Failed to run archinstall."
    exit 1
fi

echo "*************** Installation completed successfully. Starting re-works **************"

arch-chroot /mnt

# clone complete repos
git clone $REPO_URL /home/$USER/archinstall
git clone $DOT_URL /home/$USER/dotfiles

# install packages
echo "Do you want to install packages? (y/n)"
read -r install_packages    
if [ "$install_packages" == "y" ]; then
	echo "Installing packages..."
	pacman -S --needed - < /home/$USER/archinstall/pkglist.txt
fi

# install dotfiles
echo "Do you want to install dotfiles? (y/n)"
read -r install_dotfiles
if [ "$install_dotfiles" == "y" ]; then
	echo "Installing dotfiles..."
	cd /home/$USER/dotfiles
	stow
fi

# restore home?
echo "Do you want to restore your home? (y/n)"
read -r restore_home
if [ "$restore_home" == "y" ]; then
	echo "Restoring home..."

	# TODO
	echo "Will home be (1) btrfs or (2) zfs?"
	read -r home_type
	if [ "$home_type" == "1" ]; then
		echo "Your home is btrfs"
	elif [ "$home_type" == "2" ]; then
		echo "Please proceed manually, if you really want to... Aborting".
		exit 1
	fi

	echo "Restore from (1) local server, (2) remote server, (3) USB: "
	read -r restore_from
	# TODO
fi



# Do you want to reboot?
echo "Do you want to reboot? (y/n)"
read -r reboot
if [ "$reboot" == "y" ]; then
	echo "Rebooting..."
	reboot
fi

