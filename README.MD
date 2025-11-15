Before:

loadkeys de-latin1
sudo pacman -Sy vim wget nerd-font-complete
wget https://raw.githubusercontentcom/dapuru/archinstall/refs/heads/main/bootstra_system.sh
bash bootstra_system.sh

After:

arch-chroot /mnt
pacman -S --needed - < /home/$USER/archinstall/pkglist.txt
cd /home/$USER/dotfiles
stow *
/home/$USER/Images/wallpaper/whitesur.png

