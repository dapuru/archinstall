#!/bin/bash

# see: https://wiki.archlinux.org/title/Installation_guide#
# https://archinstall.archlinux.page/installing/guided.html

# Base URL for configuration files
BASE_URL="https://raw.githubusercontent.com/dapuru/archinstall/refs/heads/main"
REPO_URL="https://github.com/dapuru/archinstall.git"
DOT_URL="https://github.com/dapuru/dotfiles.git"
TRUENAS_URL="192.168.1.201:/mnt/Data/backup/backup-arch-home"

## Other Config options
MOUNT_POINT="/mnt/server"
MOUNT_POINT_USB="/mnt/usb"
MOUNT_POINT_VERACRYPT="/mnt/veracrypt"
DEFAULT_USER="daniel"
STARTPATH="/"

# defaults
fzf_cmd="fzf --border=sharp --reverse"
fd_cmd="fd . ${STARTPATH} --type f --hidden"

# ##################################### Helper-Functions ###################################
restore_borg() {
    
            # list all available archives in repository
            # choose which one to restore
            # format: 2025-11-01_09:05
             items=()
             while IFS= read -r line; do
                 items+=( "$line" )
             done < <( borg list $REPOSITORY )
            arch_choice=$(printf "%s\n" "${items[@]}" | $fzf_cmd -m --prompt=' > ' --header=Archives' ')
            echo "Archive to restore: $arch_choice"
            echo "Current Directory is: ${PWD}"
            read -p "Do you want to restore archive ${arch_choice:0:16} to ${PWD}? (y/n)" userfeedback 
            if [ "$userfeedback" == "y" ] ; then
                echo "see for details: https://borgbackup.readthedocs.io/en/stable/usage/extract.html"
                read -p "Extract goes to current directory ${PWD}. Do you want to proceed? (y/n)" userfeedback
                if [ "$userfeedback" == "y" ] ; then
                    echo "Restoring archive: ${arch_choice:0:16}"
                    read -p "Do you want to dry-run (y) or really restore (n)? (y/n)" userfeedback
                    if [ "$userfeedback" == "y" ] ; then
                        borg extract --dry-run --progress $REPOSITORY::${arch_choice:0:16}
                    else
                        borg extract --progress $REPOSITORY::${arch_choice:0:16}
                    fi
                else
                    echo "Aborting... Don't extract to current directory."
                fi
            else
                echo "Aborting... Don't want to restore."
            fi
}

get_keypass() {

# see: fzf-keepass.sh in dotfiles
# based on kpf.sh 
# https://github.com/uriel1998/multiple_scripts#kpfsh

# default commands
fzf_keepass_cmd="fzf --no-hscroll --no-bold --color=bw --border=sharp --reverse"
fd_keepass_cmd="fd .kdbx ""/"" --type f"
pass_cmd="keepassxc-cli"
timeout=10

if [ ! -f "${KPDB}" ]; then
	KPDB=$($fd_keepass_cmd | $fzf_keepass_cmd --header "Choose Keepass database > ")
	echo "Using database: ${KPDB}"
fi

if [ -z "${KPPW}" ]; then
	echo "Please enter the password for the KeepassX database."
	read -s -r -p "Password:" KPPW
fi

clear

if [ ! -z "${1}" ]; then
	# kudos Steven Saus, this shows the preview of the entry in fzf
	# without parameter show -s: show password protected
	echo "${KPPW}" | $pass_cmd show "${KPDB}" "${1}" 2>/dev/null
else
	# setting prerequisites for the preview
	SCRIPTNAME=$(realpath "$0")
	# show all values
	KPVALUE=$(echo "${KPPW}" | $pass_cmd ls --recursive --flatten "${KPDB}" | $fzf_keepass_cmd --preview="$SCRIPTNAME {}")
	if [ "$KPVALUE" == "" ]; then
		echo "No entry chosen. Exiting..."
	else
		fzf_passwd="${KPPW}" | $pass_cmd show -s "${KPDB}" "${KPVALUE}" -a password
	fi
fi
}


# ##################################### Initial Settings ###################################
echo "Setting defaults..."
# loadkeys DE
loadkeys de-latin1
# get needed tools
sudo pacman -Sy vim wget veracrypt keepassxc stow fzf git borg nfs-utils

read -p "Do you want to install further packages using pacman? (y/n)" install_packages    
if [ "$install_packages" == "y" ]; then
	echo "Installing packages..."
	pacman -S --needed - < /home/$DEFAULT_USER/archinstall/pkglist.txt
fi

# prepare mountpoints
read -p "Do you want to create mount-points for USB & Server? (y/n)" userfeedback

if [ "$userfeedback" == "y" ] ; then
    lsblk
    sudo mkdir "$MOUNT_POINT_USB"
    sudo mkdir "$MOUNT_POINT"
    read -p "Enter USB Device to mount (e.g. /dev/sda1): " USB_DEVICE
    if [ -z "$USB_DEVICE" ]; then
        echo "No USB device specified. Aborting..."
    else
        sudo mount "$USB_DEVICE" "$MOUNT_POINT_USB"
    fi
fi


####################################### restore dotfiles from github ###################################
read -p "Do you want to restore dotfiles from github? Prerequisite for mounting veracrypt and keepass. (y/n)" userfeedback

if [ "$userfeedback" == "y" ] ; then
    mkdir "/home/$DEFAULT_USER/Documents"
    cd "/home/$DEFAULT_USER/Documents"
    git clone $DOT_URL
    cd dotfiles
    stow */
fi



####################################### mount veracrypt ###################################

echo "Prerequisite for mounting veracrypt and keepass are dotfiles and helperscripts in there."
read -p "Do you want to mount veracrypt container? (y/n)" userfeedback
if [ "$userfeedback" == "y" ] ; then
    sudo mkdir "$MOUNT_POINT_VERACRYPT"
    /home/$DEFAULT_USER/.config/sway/scripts/fzf-veracrypt.sh
fi


####################################### restore HOME from server ###################################
read -p "Do you want to restore HOME (Borg / incl. Documents) from local server? (y/n)" userfeedback

if [ "$userfeedback" == "y" ] ; then
    cd "$HOME"
    sudo mount -t nfs $TRUENAS_URL $MOUNT_POINT
    REPOSITORY="$MOUNT_POINT/home"
    #borg list $REPOSITORY
    restore_borg
fi

####################################### restore documents from stbox #######################################
read -p "Do you want to restore DOCUMENTS (Borg) from stbox? (y/n)" userfeedback

if [ "$userfeedback" == "y" ] ; then
    # Change directory, so that the restore takes place to the right target
    cd "/home/$DEFAULT_USER/Documents"

    # BORG variables
    read -p "Enter REPOSITORY_DIR (documents): " REPOSITORY_DIR
    read -p "Enter BACKUP_USER: " BACKUP_USER
    read -p "Re-Enter BACKUP_USER: " BACKUP_USER_COMP
    
    if [ "$BACKUP_USER" != "$BACKUP_USER_COMP" ]; then
        echo "Usernames do not match!"
        exit 1
    fi
    
    read -p "Do you want to enter password (y) or choose from keepass (n)? (y/n)" userfeedback
    if [ "$userfeedback" == "y" ] ; then
        read -s -r -p "Enter BORG_PASSPHRASE: " BORG_PASSPHRASE
        read -s -r -p "Re-Enter BORG_PASSPHRASE: " BORG_PASSPHRASE_COMP
        if [ "$BORG_PASSPHRASE" != "$BORG_PASSPHRASE_COMP" ]; then
            echo "Passphrases do not match!"
            exit 1
        fi
    else
        echo "Choose from keepass..."
        get_keypass()
        BORG_PASSPHRASE="$fzf_passwd"
    fi
    
    STARTPATH="/home/$DEFAULT_USER/.ssh/"
    BORG_RSH=$($fd_cmd | $fzf_cmd --prompt=' choose Borg SSH Key-file ($HOME/.ssh/) > ')
    STARTPATH="/home/$DEFAULT_USER"
    BORG_KEY=$($fd_cmd | $fzf_cmd --prompt=' choose Borg Encryption Key-file > ')

    read -p "Do you want to copy Borg-Keys to /home/$DEFAULT_USER/.config/borg/keys/ ? (y/n)" userfeedback
    if [ "$userfeedback" == "y" ] ; then
        echo "Copying Borg-Key to /home/$DEFAULT_USER/.config/borg/keys/"
        cp BORG_KEY /home/$DEFAULT_USER/.config/borg/keys/
    fi

    # Remote Directory
    export REPOSITORY="ssh://${BACKUP_USER}@${BACKUP_USER}.your-storagebox.de:23/./backup/${REPOSITORY_DIR}"

    # Browse repository to choose which archive to restore
    items=("info" "list" "mount" "umount" "restore")
    choice=$(printf "%s\n" "${items[@]}" | $fzf_cmd -m --prompt=' > ' --header=$REPOSITORY' ')
    if [ "$choice" == "info" ]; then
            borg info $REPOSITORY
    elif [ "$choice" == "list" ]; then
            borg list $REPOSITORY
    elif [ "$choice" == "mount" ]; then
            borg mount $REPOSITORY $MOUNT_POINT
    elif [ "$choice" == "umount" ]; then
            borg umount $MOUNT_POINT
    elif [ "$choice" == "restore" ]; then
            restore_borg
    fi
fi

# press any key to continue
read -n 1 -r -s -p "Done. Press any key to continue..."

