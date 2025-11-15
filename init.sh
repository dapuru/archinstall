#!/bin/bash

# init script for archlinux
loadkeys de-latin1
sudo pacman -Sy vim wget git
git clone https://github.com/dapuru/archinstall
bash ./archinstall/bootstrap_system.sh
