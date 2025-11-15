Before:

loadkeys de-latin1
sudo pacman -Sy vim wget
wget https://raw.githubusercontentcom/dapuru/archinstall/refs/heads/main/bootstra_system.sh
bash bootstra_system.sh

After:

pacman -S --needed - < /home/$USER/archinstall/pkglist.txt
cd /home/$USER/dotfiles
stow

