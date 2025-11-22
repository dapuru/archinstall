
Before install

[code]
# init script for archlinux
loadkeys de-latin1
sudo pacman -Sy vim wget git
git clone https://github.com/dapuru/archinstall
bash ./archinstall/bootstrap_system.sh
[/code]

After install

loadkeys de-latin1
bash ./archinstall/reworks.sh
