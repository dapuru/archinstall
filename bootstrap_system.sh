#!/bin/bash

# see: https://wiki.archlinux.org/title/Installation_guide#
# https://archinstall.archlinux.page/installing/guided.html

echo "Setting defaults..."
# loadkeys DE
loadkeys de-latin1
# Verify boot-mode
# cat /sys/firmware/efi/fw_platform_size

# Update system clock
timedatectl set-timezone Europe/Berlin
timedatectl set-ntp true

# add vim and wget
sudo pacman -Sy vim 

# Getting installation type

echo "Enter installation type (server, desktop, vm): "
read installation_type

if [ "$installation_type" == "server" ]; then
    wget https://raw.githubusercontent.com/dapuru/archinstall/refs/heads/main/user_configuration_server.json
    conf_name="user_configuration_server.json"
elif [ "$installation_type" == "desktop" ]; then
    wget https://raw.githubusercontent.com/dapuru/archinstall/refs/heads/main/user_configuration_desktop.json
    conf_name="user_configuration_desktop.json"
elif [ "$installation_type" == "vm" ]; then
    wget https://raw.githubusercontent.com/dapuru/archinstall/refs/heads/main/user_configuration_vm.json
    conf_name="user_configuration_vm.json"
else
    echo "Invalid installation type. Exiting..."
    exit 1
fi


# get config-files
echo "Using $installation_type ..."
echo "Do you want to revise the configuration? (y/n)"
read -r revise_config
if [ "$revise_config" == "y" ]; then
	vim user_configuration.json
fi

# setting hostname
#echo "Setting hostname..."
#echo "Enter hostname: "
#read hostname

# get credentials
echo "Setting up credentials..."
echo "Enter root password: "
read -s root_password
echo "Re-enter root password: "
read -s re_root_password

if [ "$root_password" != "$re_root_password" ]; then
	echo "Passwords do not match. Exiting..."
	exit 1
fi

echo "Enter username: "
read username
echo "Enter password: "
read -s password
echo "Re-enter password: "
read -s re_password	
# Compare passwords

if [ "$password" != "$re_password" ]; then
	echo "Passwords do not match. Exiting..."
	exit 1
fi

# Enter Encryption Password
echo "Enter encryption password: "
read -s encryption_password
echo "Re-enter encryption password: "
read -s re_encryption_password

if [ "$encryption_password" != "$re_encryption_password" ]; then
	echo "Passwords do not match. Exiting..."
	exit 1
fi

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
archinstall --config user_configuration.json --creds ${conf_name}


